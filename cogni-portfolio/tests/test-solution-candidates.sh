#!/usr/bin/env bash
# Regression suite for cogni-portfolio/scripts/register-solution-candidates.py —
# the Lean-Canvas Solutions-block -> solution-candidate register.
#
# Fixtures are heredoc'd inline — no committed JSON blobs to maintain. Each test
# builds a minimal portfolio project in a temp directory, runs the register
# script, and asserts on the register file / script envelope.
#
# Named acceptance tests (each is one shell function):
#   test_ingest_registers_candidates       filled Solutions block -> >=2 candidates
#   test_candidate_status_marker           every candidate status in {candidate,draft}, none finished
#   test_empty_solutions_block_noop        absent/empty block -> 0 candidates, exit 0, no register
#   test_reingest_idempotent               double ingest -> same count, no duplicates
#   test_candidates_resolvable_by_solutions each candidate resolves to a seeded product
#
# Usage:
#   bash cogni-portfolio/tests/test-solution-candidates.sh              # run all
#   bash cogni-portfolio/tests/test-solution-candidates.sh <test_name>  # run one
# Exits non-zero on any assertion failure (so scripts/run-plugin-tests.py and
# scripts/mutation-check.sh can read the exit status).

# `set -u` only — `set -e` would abort on the first failing assertion and defeat
# the per-test failure counter.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/register-solution-candidates.py"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: register-solution-candidates.py not found at $SCRIPT" >&2
  exit 1
fi

failures=0

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT
_mk() { local d="$TMPROOT/$1"; rm -rf "$d"; mkdir -p "$d"; echo "$d"; }

fail() { echo "  FAIL: $1" >&2; failures=$((failures + 1)); }
pass() { echo "  ok: $1"; }

# candidate_count <register-file> — prints the number of candidates, 0 if absent.
candidate_count() {
  local f="$1"
  [ -f "$f" ] || { echo 0; return; }
  python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(len(d.get("candidates",[])))' "$f" 2>/dev/null || echo 0
}

# ---- fixtures --------------------------------------------------------------

# seed_project <dir> — a minimal project with two products the candidates resolve to.
seed_project() {
  local dir="$1"
  mkdir -p "$dir/products" "$dir/research"
  printf '{"slug":"cloud-monitoring","name":"Cloud Monitoring"}\n' > "$dir/products/cloud-monitoring.json"
  printf '{"slug":"managed-onboarding","name":"Managed Onboarding"}\n' > "$dir/products/managed-onboarding.json"
}

# filled canvas (JSON) — a top-level solutions block with two entries whose names
# match the seeded products. JSON is used deliberately so test_ingest exercises
# the AC6-MUTATION-TARGET mapping in _find_solutions_in_obj.
write_filled_canvas() {
  cat > "$1" <<'CANVAS'
{"problem": "manual ops", "solutions": ["Cloud Monitoring", "Managed Onboarding"]}
CANVAS
}

# ---- tests -----------------------------------------------------------------

test_ingest_registers_candidates() {
  local tmp; tmp="$(_mk "${FUNCNAME[0]}")"
  seed_project "$tmp"
  write_filled_canvas "$tmp/canvas.json"
  python3 "$SCRIPT" --project "$tmp" --canvas "$tmp/canvas.json" >/dev/null 2>&1
  local reg="$tmp/research/solution-candidates.json"
  local n; n="$(candidate_count "$reg")"
  # RED when the Solutions block yields 0 candidates and the layer stays empty.
  if [ "$n" -ge 2 ]; then pass "registers >=2 candidates (got $n)"; else
    fail "expected >=2 candidates from a filled Solutions block, got $n"; fi
}

test_candidate_status_marker() {
  local tmp; tmp="$(_mk "${FUNCNAME[0]}")"
  seed_project "$tmp"
  write_filled_canvas "$tmp/canvas.json"
  python3 "$SCRIPT" --project "$tmp" --canvas "$tmp/canvas.json" >/dev/null 2>&1
  local reg="$tmp/research/solution-candidates.json"
  # Every candidate must carry status in {candidate,draft} and no finished-solution
  # marker (e.g. shared_solution_ref / solution_type).
  local bad
  bad="$(python3 - "$reg" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
bad=0
for c in d.get("candidates",[]):
    if c.get("status") not in ("candidate","draft"): bad+=1
    if "shared_solution_ref" in c or "solution_type" in c: bad+=1
print(bad)
PY
)"
  if [ "$bad" = "0" ]; then pass "all candidates carry a draft/candidate status, none finished"; else
    fail "$bad candidate(s) missing a {candidate,draft} status or carrying a finished marker"; fi
}

test_empty_solutions_block_noop() {
  local tmp; tmp="$(_mk "${FUNCNAME[0]}")"
  seed_project "$tmp"
  # A canvas whose Solutions block is empty.
  cat > "$tmp/canvas.json" <<'CANVAS'
{"problem": "manual ops", "solutions": []}
CANVAS
  python3 "$SCRIPT" --project "$tmp" --canvas "$tmp/canvas.json" >/dev/null 2>&1
  local rc=$?
  local reg="$tmp/research/solution-candidates.json"
  local n; n="$(candidate_count "$reg")"
  if [ "$rc" -eq 0 ] && [ "$n" -eq 0 ]; then pass "empty block is a no-op (exit 0, 0 candidates)"; else
    fail "empty block expected exit 0 + 0 candidates, got exit=$rc candidates=$n"; fi
  # A missing canvas file must also be a clean no-op.
  python3 "$SCRIPT" --project "$tmp" --canvas "$tmp/does-not-exist.json" >/dev/null 2>&1
  if [ $? -eq 0 ]; then pass "missing canvas file is a no-op (exit 0)"; else
    fail "missing canvas file expected exit 0"; fi
}

test_reingest_idempotent() {
  local tmp; tmp="$(_mk "${FUNCNAME[0]}")"
  seed_project "$tmp"
  write_filled_canvas "$tmp/canvas.json"
  python3 "$SCRIPT" --project "$tmp" --canvas "$tmp/canvas.json" >/dev/null 2>&1
  local reg="$tmp/research/solution-candidates.json"
  local first; first="$(candidate_count "$reg")"
  python3 "$SCRIPT" --project "$tmp" --canvas "$tmp/canvas.json" >/dev/null 2>&1
  local second; second="$(candidate_count "$reg")"
  if [ "$first" = "$second" ] && [ "$first" -ge 2 ]; then pass "re-ingest is idempotent ($first == $second)"; else
    fail "re-ingest changed the candidate count: first=$first second=$second (expected equal, >=2)"; fi
}

test_candidates_resolvable_by_solutions() {
  local tmp; tmp="$(_mk "${FUNCNAME[0]}")"
  seed_project "$tmp"   # pre-seeds the products the candidates resolve against
  write_filled_canvas "$tmp/canvas.json"
  python3 "$SCRIPT" --project "$tmp" --canvas "$tmp/canvas.json" >/dev/null 2>&1
  local reg="$tmp/research/solution-candidates.json"
  # Every candidate must resolve to a seeded product slug (non-null product_ref
  # pointing at a real products/*.json).
  local unresolved
  unresolved="$(python3 - "$reg" "$tmp" <<'PY'
import json,os,sys
reg,proj=sys.argv[1],sys.argv[2]
d=json.load(open(reg))
bad=0
for c in d.get("candidates",[]):
    ref=c.get("product_ref")
    if not ref or not os.path.isfile(os.path.join(proj,"products",ref+".json")):
        bad+=1
print(bad)
PY
)"
  if [ "$unresolved" = "0" ]; then pass "every candidate resolves to a seeded product"; else
    fail "$unresolved candidate(s) did not resolve to a seeded product"; fi
}

ALL_TESTS="test_ingest_registers_candidates test_candidate_status_marker test_empty_solutions_block_noop test_reingest_idempotent test_candidates_resolvable_by_solutions"

run_one() {
  echo "== $1 =="
  "$1"
}

if [ "$#" -ge 1 ]; then
  # Run a single named test (used by mutation-check.sh).
  case " $ALL_TESTS " in
    *" $1 "*) run_one "$1" ;;
    *) echo "FAIL: unknown test '$1'" >&2; exit 2 ;;
  esac
else
  for t in $ALL_TESTS; do run_one "$t"; done
fi

if [ "$failures" -eq 0 ]; then
  echo "All solution-candidate tests passed."
  exit 0
else
  echo "$failures assertion(s) failed." >&2
  exit 1
fi
