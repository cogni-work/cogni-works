#!/usr/bin/env bash
# Mutation harness for the #1230 commercial-consolidation gate (AC: scripts/mutation-check.sh).
#
# Reverts the "commercial structure shared?" check in project-status.sh to a
# constant false, then asserts test_hybrid_consolidates goes RED against the
# mutant — proving the detection gate actually has teeth. Exit 0 iff the mutation
# is caught (the test failed); non-zero if the mutation survived.
#
# Kept under scripts/ (NOT tests/) deliberately: run-plugin-tests.py auto-discovers
# tests/*.sh and would run this as a normal suite; this is a manual meta-check that
# deliberately drives a failing sub-run.
#
# Usage: bash cogni-portfolio/scripts/mutation-check.sh   (no args, no network)

set -u

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
TEST="$PLUGIN_DIR/tests/test-commercial-consolidation.sh"

for f in "$SCRIPTS_DIR/project-status.sh" "$TEST"; do
  [ -f "$f" ] || { echo "FAIL: missing $f" >&2; exit 1; }
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Copy the whole scripts/ dir so the mutant still finds its sibling scripts.
cp -R "$SCRIPTS_DIR" "$TMP/scripts"
MUTATED="$TMP/scripts/project-status.sh"

# Flip the single commercial-structure detection line to a constant false.
if ! python3 - "$MUTATED" <<'PY'
import re, sys
path = sys.argv[1]
src = open(path).read()
new, n = re.subn(
    r'shared = rm in SHARED_MODELS.*',
    'shared = False  # MUTATED by mutation-check.sh',
    src, count=1)
if n != 1:
    sys.stderr.write("could not locate the commercial-structure check to mutate\n")
    sys.exit(3)
open(path, 'w').write(new)
PY
then
  echo "FAIL: mutation could not be applied" >&2
  exit 1
fi

# Run only the hybrid consolidation assertion against the mutant.
if PROJECT_STATUS_SCRIPT="$MUTATED" bash "$TEST" test_hybrid_consolidates >/dev/null 2>&1; then
  echo "FAIL: mutation survived — test_hybrid_consolidates still passed with the shared check disabled" >&2
  exit 1
fi

echo "OK: mutation caught — test_hybrid_consolidates went red with the shared check disabled"
exit 0
