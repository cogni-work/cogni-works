#!/bin/bash
# Atomically append a claim to cogni-claims/claims.json with file locking.
# Usage: append-claim.sh <project-dir> <claim-json>
# The claim-json argument is a single JSON object (the claim to append).
# Creates cogni-claims/ directory and claims.json if they don't exist.
# Uses mkdir-based locking (portable across macOS and Linux) to prevent
# race conditions when agents run in parallel.
# Env: APPEND_CLAIM_MAX_WAIT overrides the lock-acquire ceiling in 0.1s units
#   (default 30 = 3s); a non-positive or non-integer value falls back to 30.
# Exit codes: 0 = success, 1 = error
set -euo pipefail

PROJECT_DIR="${1:-}"
CLAIM_JSON="${2:-}"

if [ -z "$PROJECT_DIR" ] || [ -z "$CLAIM_JSON" ]; then
  echo '{"error": "Usage: append-claim.sh <project-dir> <claim-json>"}' >&2
  exit 1
fi

CLAIMS_DIR="$PROJECT_DIR/cogni-claims"
CLAIMS_FILE="$CLAIMS_DIR/claims.json"
LOCK_DIR="$CLAIMS_DIR/.claims.lock"

# Ensure directory structure exists
mkdir -p "$CLAIMS_DIR/sources" "$CLAIMS_DIR/history"

# Acquire lock using mkdir (atomic on all POSIX systems)
#
# MAX_WAIT counts 0.1s poll iterations, so the default 30 is a 3s ceiling. The
# override exists for tests: both cases of the lock suite exist to DRIVE this
# loop to its ceiling, so the wait length is incidental to what they pin, and at
# the default they burn ~3s each for nothing. Callers that set no override keep
# the 3s ceiling exactly.
#
# Floor on numeric SHAPE, as the stale-lock reading below does — but NOT with the
# same pattern, and the divergence is load-bearing. The leading [1-9] also
# excludes leading zeros: `08` or `030` would pass a bare ^[0-9]+$ and then make
# the division below a hard bash abort ("value too great for base"), because
# arithmetic expansion reads a leading zero as octal. Do not harmonise the two
# patterns. Zero is excluded too, and that is deliberate rather than incidental:
# the loop sleeps BEFORE its first -ge check, so 0 and 1 both mean "one 0.1s
# poll" — 0 buys no fail-immediately semantics that 1 does not already give, and
# it would render a misleading "after 0s" for a path that did in fact wait.
# Admitting only positive integers is also what guarantees the -ge test below can
# never error, so the loop always terminates.
MAX_WAIT="${APPEND_CLAIM_MAX_WAIT:-30}"
[[ "$MAX_WAIT" =~ ^[1-9][0-9]*$ ]] || MAX_WAIT=30

# Derive the timeout label from the ceiling rather than restating it, and do it
# HERE — at top level, outside the loop. The old message restated a fixed three
# seconds, which was correct only because 30 x 0.1s equals that; under an override
# the script would have kept claiming 3s while actually waiting a tenth of that,
# and the suite's grep would have stayed green on a message that had become
# wrong. Placement matters as much as derivation: an arithmetic abort inside the
# acquire loop is the exact failure the comment further down documents — it
# abandons the loop, resumes after `done`, and appends the claim having never
# held the lock. At top level the same abort is a clean exit before any lock is
# taken and before the release trap is installed.
#
# Use the assignment form for the arithmetic, never a bare (( ... )) command: a
# bare arithmetic command evaluating to 0 returns status 1, and the default
# ceiling makes the remainder exactly 0, so under `set -e` that aborts on bash
# 5.x while passing on 3.2 — a version-divergent failure on the DEFAULT path.
WAIT_WHOLE=$(( MAX_WAIT / 10 ))
WAIT_TENTHS=$(( MAX_WAIT % 10 ))
if [ "$WAIT_TENTHS" -eq 0 ]; then
  WAIT_LABEL="${WAIT_WHOLE}s"
else
  WAIT_LABEL="${WAIT_WHOLE}.${WAIT_TENTHS}s"
fi

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
    echo "{\"error\": \"Could not acquire lock on claims.json after ${WAIT_LABEL}\"}" >&2
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

with open(claims_file, 'r') as f:
    data = json.load(f)

claim = json.loads(claim_json)
data['claims'].append(claim)

with open(claims_file, 'w') as f:
    json.dump(data, f, indent=2)

print(json.dumps({'status': 'appended', 'claim_id': claim.get('id', 'unknown'), 'total': len(data['claims'])}))
" "$CLAIMS_FILE" "$CLAIM_JSON"
