#!/usr/bin/env bash
# Mutation harness for cogni-portfolio (AC: scripts/mutation-check.sh).
#
# Runs each feature's mutation falsifier in turn and asserts the targeted test
# goes RED against the mutant — proving the detection actually has teeth. Exit 0
# iff EVERY mutation is caught; non-zero if any mutation survives.
#
#   1. commercial-consolidation gate (#1230): flip the "commercial structure
#      shared?" check in project-status.sh to a constant false; expect
#      test_hybrid_consolidates to go RED.
#   2. solution-candidate register: remove the Solutions-block mapping in
#      register-solution-candidates.py; expect test_ingest_registers_candidates
#      to go RED.
#
# Kept under scripts/ (NOT tests/) deliberately: run-plugin-tests.py auto-discovers
# tests/*.sh and would run this as a normal suite; this is a manual meta-check that
# deliberately drives failing sub-runs.
#
# Usage: bash cogni-portfolio/scripts/mutation-check.sh   (no args, no network)

set -u

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"

overall=0

# --- Mutation 1: commercial-consolidation gate -----------------------------
# Reverts the "commercial structure shared?" check in project-status.sh to a
# constant false, then asserts test_hybrid_consolidates goes RED against the
# mutant. Returns 0 when the mutation is caught, non-zero otherwise.
mutation_commercial_consolidation() {
  local test="$PLUGIN_DIR/tests/test-commercial-consolidation.sh"
  for f in "$SCRIPTS_DIR/project-status.sh" "$test"; do
    [ -f "$f" ] || { echo "FAIL: missing $f" >&2; return 1; }
  done

  local tmp; tmp="$(mktemp -d)"
  # Copy the whole scripts/ dir so the mutant still finds its sibling scripts.
  cp -R "$SCRIPTS_DIR" "$tmp/scripts"
  local mutated="$tmp/scripts/project-status.sh"

  if ! python3 - "$mutated" <<'PY'
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
    echo "FAIL: commercial-consolidation mutation could not be applied" >&2
    rm -rf "$tmp"; return 1
  fi

  local rc=0
  if PROJECT_STATUS_SCRIPT="$mutated" bash "$test" test_hybrid_consolidates >/dev/null 2>&1; then
    echo "FALSIFIER: mutation survived — test_hybrid_consolidates still passed with the shared check disabled" >&2
    rc=1
  else
    echo "OK: mutation caught — test_hybrid_consolidates went red with the shared check disabled"
  fi
  rm -rf "$tmp"
  return "$rc"
}

# --- Mutation 2: solution-candidate register -------------------------------
# Excises the Solutions-block mapping (between the AC6-MUTATION-TARGET markers)
# in register-solution-candidates.py, then asserts test_ingest_registers_candidates
# goes RED. The source is always restored. Returns 0 when caught, non-zero otherwise.
mutation_solution_candidates() {
  local target="$SCRIPTS_DIR/register-solution-candidates.py"
  local suite="$PLUGIN_DIR/tests/test-solution-candidates.sh"
  local test_name="test_ingest_registers_candidates"
  for f in "$target" "$suite"; do
    [ -f "$f" ] || { echo "FAIL: missing $f" >&2; return 1; }
  done

  # Baseline: the target test must be GREEN before we mutate, or a later red
  # tells us nothing.
  if ! bash "$suite" "$test_name" >/dev/null 2>&1; then
    echo "FAIL: baseline $test_name is already red before mutation" >&2
    return 1
  fi

  local backup; backup="$(mktemp)"
  cp "$target" "$backup"

  if ! python3 - "$target" <<'PY'
import re, sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()
mutated, n = re.subn(
    r"^[ \t]*# >>> AC6-MUTATION-TARGET:.*?^[ \t]*# <<< AC6-MUTATION-TARGET[ \t]*\n",
    "",
    src,
    count=1,
    flags=re.DOTALL | re.MULTILINE,
)
if n != 1:
    sys.stderr.write("AC6-MUTATION-TARGET markers not found — cannot mutate.\n")
    sys.exit(4)
open(path, "w", encoding="utf-8").write(mutated)
PY
  then
    echo "FAIL: solution-candidate mutation could not be applied" >&2
    cp "$backup" "$target"; rm -f "$backup"; return 1
  fi

  local rc=0
  if bash "$suite" "$test_name" >/dev/null 2>&1; then
    echo "FALSIFIER: mutation survived — $test_name stayed GREEN with the Solutions-block mapping removed" >&2
    rc=1
  else
    echo "OK: mutation caught — $test_name goes red when the Solutions-block mapping is removed"
  fi
  cp "$backup" "$target"; rm -f "$backup"   # always restore
  return "$rc"
}

mutation_commercial_consolidation || overall=1
mutation_solution_candidates || overall=1

if [ "$overall" -eq 0 ]; then
  echo "All mutations caught."
else
  echo "One or more mutations survived." >&2
fi
exit "$overall"
