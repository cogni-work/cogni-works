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
# Stale-sweep budget. A lock we have failed to remove this many times is not
# going to become removable: the directory is non-empty, or a peer keeps
# re-taking it inside the same tick. Without a bound the sweep below `continue`s
# forever and the timeout diagnostic becomes unreachable, because WAITED only
# ever climbs -- so once the ceiling test is true it stays true on every later
# pass. The budget is what lets the loop fall through to that diagnostic instead
# of spinning at 10Hz over a lock it cannot clear.
MAX_SWEEPS=3
SWEEPS=0
# Empty means "the working stat form is not resolved yet". Resolution is
# deliberately lazy -- deferred to the first stale-block entry rather than done
# ahead of the loop -- because an uncontended acquire never enters the loop body
# at all, so probing up front would add a fork to every one of those to save
# forks on the rare contended path. The lock directory also need not exist yet
# at this point; it is created only by the loop's own mkdir below.
STAT_MTIME=""
# Read the lock's mtime into lock_mtime, resolving the working stat form on first
# use and reusing it thereafter. This lives in a function rather than inline so
# the acquire loop's body carries no stat invocation of its own: the loop asks
# for a reading, and which form produces it is this function's business.
#
# GNU form first: on GNU coreutils `-f` means --file-system, so `stat -f %m`
# yields no mtime yet still exits 0, and a fallback chain would never fall
# through. BSD has no `-c`, so it errors cleanly and does fall through — only
# this direction works on both. The candidate list is therefore ordered, not
# arbitrary, and reversing it is what the ordering mutation arm exists to catch.
#
# The winner is memoized in STAT_MTIME, so only the first entry pays the failing
# probe; every later entry costs a single exec. `$stat_form` and `$STAT_MTIME`
# expand UNQUOTED on purpose — each holds a command plus its flags and has to
# word-split into three words. Both are set from this file's own literals and the
# format specifiers carry no glob character, so the split is safe.
#
# The sentinel for "no form worked" is the `false` builtin, which keeps the
# memoized path fork-free and lets the read's tail absorb its non-zero status.
# Every path assigns lock_mtime — a failing substitution still assigns the empty
# string — which is what keeps `set -u` off the shape floor at the call site, and
# the assignment-as-condition form is what keeps a failing probe from tripping
# `set -e`. The function itself always returns 0 for the same reason.
#
# Both probe calls keep their stderr redirect, so a real BSD host's complaint
# about the GNU flag never reaches the caller's stderr.
read_lock_mtime() {
  if [ -z "$STAT_MTIME" ]; then
    STAT_MTIME=false
    for stat_form in "stat -c %Y" "stat -f %m"; do
      if lock_mtime=$($stat_form "$LOCK_DIR" 2>/dev/null); then
        STAT_MTIME="$stat_form"
        return 0
      fi
    done
    return 0
  fi
  lock_mtime=$($STAT_MTIME "$LOCK_DIR" 2>/dev/null || echo 0)
}
while ! mkdir "$LOCK_DIR" 2>/dev/null; do
  sleep 0.1
  WAITED=$((WAITED + 1))
  if [ "$WAITED" -ge "$MAX_WAIT" ]; then
    # Stale lock detection: remove lock older than 60 seconds
    if [ -d "$LOCK_DIR" ]; then
      # Resolve the reading into a variable before any arithmetic. A bad
      # substitution nested directly inside $(( )) is a hard bash error, and the
      # damage is worse than an abort: on every bash tested (3.2.57 through
      # 5.3.9) the error abandons the loop body AND the loop, so the script resumes
      # after `done` and appends the claim having never held the lock — and the
      # EXIT trap below then removes a live peer's lock directory it never owned.
      #
      # Floor on numeric SHAPE, not emptiness — the failure mode is a successful
      # *wrong* answer, which an emptiness test structurally cannot catch.
      read_lock_mtime
      [[ "$lock_mtime" =~ ^[0-9]+$ ]] || lock_mtime=0
      now=$(date +%s)
      lock_age=$(( now - lock_mtime ))
      if [ "$lock_age" -gt 60 ] && [ "$SWEEPS" -lt "$MAX_SWEEPS" ]; then
        SWEEPS=$((SWEEPS + 1))
        rmdir "$LOCK_DIR" 2>/dev/null || true
        continue
      fi
    fi
    echo "{\"error\": \"Could not acquire lock on claims.json after ${TIMEOUT_LABEL}s\"}" >&2
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
