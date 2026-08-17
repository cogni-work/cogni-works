#!/bin/bash
# Atomically append a claim to cogni-claims/claims.json with file locking.
# Usage: append-claim.sh <project-dir> <claim-json>
# The claim-json argument is a single JSON object (the claim to append).
# Creates cogni-claims/ directory and claims.json if they don't exist.
# Uses mkdir-based locking (portable across macOS and Linux) to prevent
# race conditions when agents run in parallel.
# Env: APPEND_CLAIM_MAX_WAIT — lock-acquire ceiling in 0.1s ticks. Unset means
# the production default of 30 ticks (3s); tests set a small value so they can
# drive the timeout path in fractions of a second.
# Exit codes: 0 = success, 1 = error
#
# Output (single JSON object):
#   {"success": true,  "data": {...}, "error": null}   stdout, on success
#   {"success": false, "data": null,  "error": "..."}  stderr, on any failure (exit 1)
#
set -euo pipefail

PROJECT_DIR="${1:-}"
CLAIM_JSON="${2:-}"

if [ -z "$PROJECT_DIR" ] || [ -z "$CLAIM_JSON" ]; then
  echo '{"success": false, "data": null, "error": "Usage: append-claim.sh <project-dir> <claim-json>"}' >&2
  exit 1
fi

CLAIMS_DIR="$PROJECT_DIR/cogni-claims"
CLAIMS_FILE="$CLAIMS_DIR/claims.json"
LOCK_DIR="$CLAIMS_DIR/.claims.lock"

# Ensure directory structure exists
mkdir -p "$CLAIMS_DIR/sources" "$CLAIMS_DIR/history"

# Acquire lock using mkdir (atomic on all POSIX systems)
MAX_WAIT="${APPEND_CLAIM_MAX_WAIT:-30}"
# Floor on numeric shape: a malformed override would otherwise make the -ge
# comparison below a hard error mid-loop. Regex unquoted on purpose — a quoted
# right-hand side matches literally on bash 3.2, which this repo still targets.
# The `||` form keeps a non-match from tripping `set -e`.
[[ "$MAX_WAIT" =~ ^[1-9][0-9]*$ ]] || MAX_WAIT=30
# Derive the diagnostic's number from the ceiling rather than restating it, so
# the message can never claim a wait the loop no longer honours.
TIMEOUT_LABEL="$(( MAX_WAIT / 10 )).$(( MAX_WAIT % 10 ))"
TIMEOUT_LABEL="${TIMEOUT_LABEL%.0}"
WAITED=0
while ! mkdir "$LOCK_DIR" 2>/dev/null; do
  sleep 0.1
  WAITED=$((WAITED + 1))
  if [ "$WAITED" -ge "$MAX_WAIT" ]; then
    # Stale lock detection: remove lock older than 60 seconds
    if [ -d "$LOCK_DIR" ]; then
      # GNU form first: on GNU coreutils `-f` means --file-system, so `stat -f %m`
      # yields no mtime yet still exits 0, and the `||` never falls through. BSD
      # has no `-c`, so it errors cleanly and does fall through — only this
      # direction works on both.
      #
      # Resolve the reading into a variable before any arithmetic. A bad
      # substitution nested directly inside $(( )) is a hard bash error, and the
      # damage is worse than an abort: on every bash tested (3.2.57 through
      # 5.3.9) the error abandons the loop body AND the loop, so the script resumes
      # after `done` and appends the claim having never held the lock — and the
      # EXIT trap below then removes a live peer's lock directory it never owned.
      #
      # Floor on numeric SHAPE, not emptiness — the failure mode is a successful
      # *wrong* answer, which an emptiness test structurally cannot catch.
      lock_mtime=$(stat -c %Y "$LOCK_DIR" 2>/dev/null || stat -f %m "$LOCK_DIR" 2>/dev/null || echo 0)
      [[ "$lock_mtime" =~ ^[0-9]+$ ]] || lock_mtime=0
      now=$(date +%s)
      lock_age=$(( now - lock_mtime ))
      if [ "$lock_age" -gt 60 ]; then
        rmdir "$LOCK_DIR" 2>/dev/null || true
        continue
      fi
    fi
    echo "{\"success\": false, \"data\": null, \"error\": \"Could not acquire lock on claims.json after ${TIMEOUT_LABEL}s\"}" >&2
    exit 1
  fi
done

# Ensure lock is released on exit
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

# Initialize claims.json if missing
if [ ! -f "$CLAIMS_FILE" ]; then
  echo '{"claims": []}' > "$CLAIMS_FILE"
fi

# Append claim using python3 for safe JSON manipulation
python3 -c "
import json, sys

claims_file = sys.argv[1]
claim_json = sys.argv[2]

try:
    with open(claims_file, 'r') as f:
        data = json.load(f)

    claim = json.loads(claim_json)
    data['claims'].append(claim)

    with open(claims_file, 'w') as f:
        json.dump(data, f, indent=2)
except (OSError, ValueError) as exc:
    sys.stderr.write(json.dumps({'success': False, 'data': None, 'error': str(exc)}) + '\n')
    sys.exit(1)

print(json.dumps({'success': True, 'data': {'status': 'appended', 'claim_id': claim.get('id', 'unknown'), 'total': len(data['claims'])}, 'error': None}))
" "$CLAIMS_FILE" "$CLAIM_JSON"
