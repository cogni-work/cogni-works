#!/usr/bin/env bash
# test_run_plugin_tests.sh — self-test for the plugin test-suite runner.
#
# The runner discovers `tests/*.sh` and `*/tests/*.sh` and gates the CI
# sweep on each suite's exit status. Cases:
#   1. All-passing fixture tree -> exit 0, JSON reports every suite passed.
#   2. One failing suite -> exit 1, the failing path named in failed_suites.
#   3. A suite that outlives --timeout -> reported timed_out, exit 1.
#   4. A suite parked under an _archive/ tree -> not discovered.
#   5. A sourced-only helper under tests/fixtures/ -> not discovered. This
#      guards the non-recursive-glob contract: such a file defines functions for
#      a sibling to source and breaks if executed directly.
#   6. A suite lacking the executable bit but carrying a shebang -> still runs,
#      since the runner invokes `bash <path>` rather than executing it.
#   7. Real tree -> discovery is non-empty and admits no _archive/fixtures path.
#      Deliberately NOT an exact suite count: plugins add suites routinely, and
#      a hardcoded total would turn every such addition into a false failure
#      here. Structure is the invariant; the number is not.
#   8. An empty root -> zero discovery is a FAILURE, not a vacuous pass: exit 1
#      and success:false. This is the assertion that keeps the runner from
#      reporting green if the globs ever stop matching — the same silent-zero
#      class the CI job was written to end.
#
# Only case 7 touches the real tree, and it is --list only, so this suite never
# recurses into the full sweep.
#
# bash 3.2 + stdlib python3 only.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
RUNNER="$REPO_ROOT/scripts/run-plugin-tests.py"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

FAILED=0
check() {  # check <label> <condition-exit-code>
  if [ "$2" -eq 0 ]; then
    green "PASS: $1"
  else
    red "FAIL: $1"
    FAILED=1
  fi
}

assert_json() {  # assert_json <label> <json> <python-asserts>
  set +e
  printf '%s' "$2" | python3 -c "$3"
  local _code=$?
  set -e
  check "$1" "$_code"
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# make_suite <path> <exit-code> [--no-exec]
make_suite() {
  mkdir -p "$(dirname "$1")"
  printf '#!/usr/bin/env bash\nexit %s\n' "$2" > "$1"
  if [ "${3:-}" != "--no-exec" ]; then chmod +x "$1"; fi
}

# ---------------------------------------------------------------------------
# Case 1 — an all-passing fixture tree exits 0.
# ---------------------------------------------------------------------------
FIX1="$WORK/pass"
make_suite "$FIX1/tests/test_root.sh" 0
make_suite "$FIX1/cogni-alpha/tests/test_alpha.sh" 0
make_suite "$FIX1/cogni-beta/tests/test_beta.sh" 0

set +e
OUT1="$(python3 "$RUNNER" --root "$FIX1" 2>/dev/null)"
CODE1=$?
set -e
check "all-passing tree exits 0" "$([ "$CODE1" -eq 0 ] && echo 0 || echo 1)"
assert_json "all-passing tree reports 3 passed, 0 failed" "$OUT1" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['total']==3, d['data']
assert d['data']['passed']==3, d['data']
assert d['data']['failed']==0, d['data']
"

# ---------------------------------------------------------------------------
# Case 2 — one failing suite fails the sweep and is named.
# ---------------------------------------------------------------------------
FIX2="$WORK/fail"
make_suite "$FIX2/cogni-alpha/tests/test_ok.sh" 0
make_suite "$FIX2/cogni-alpha/tests/test_broken.sh" 1

set +e
OUT2="$(python3 "$RUNNER" --root "$FIX2" 2>/dev/null)"
CODE2=$?
set -e
check "failing suite exits 1" "$([ "$CODE2" -eq 1 ] && echo 0 || echo 1)"
assert_json "failing suite is named in failed_suites" "$OUT2" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
assert d['data']['failed']==1, d['data']
assert d['data']['failed_suites']==['cogni-alpha/tests/test_broken.sh'], d['data']
"

# ---------------------------------------------------------------------------
# Case 3 — a suite that outlives --timeout is reported as timed out.
# ---------------------------------------------------------------------------
FIX3="$WORK/slow"
mkdir -p "$FIX3/cogni-alpha/tests"
# `exec` deliberately: bash replaces itself, so killing the timed-out process
# closes the stdout pipe immediately. Without it bash forks, the orphaned sleep
# holds the inherited pipe open, and the post-kill read blocks the full 10s on
# every CI run.
printf '#!/usr/bin/env bash\nexec sleep 10\n' > "$FIX3/cogni-alpha/tests/test_slow.sh"
chmod +x "$FIX3/cogni-alpha/tests/test_slow.sh"

set +e
OUT3="$(python3 "$RUNNER" --root "$FIX3" --timeout 1 2>/dev/null)"
CODE3=$?
set -e
check "timed-out suite exits 1" "$([ "$CODE3" -eq 1 ] && echo 0 || echo 1)"
assert_json "timed-out suite is flagged timed_out" "$OUT3" "
import json,sys
d=json.load(sys.stdin)
assert d['data']['failed']==1, d['data']
assert d['data']['suites'][0]['timed_out'] is True, d['data']['suites']
"

# ---------------------------------------------------------------------------
# Case 4 — a suite under an _archive/ tree is not discovered.
# Case 5 — a sourced-only helper under tests/fixtures/ is not discovered.
# Case 6 — a non-executable suite with a shebang still runs.
# ---------------------------------------------------------------------------
FIX4="$WORK/exclusions"
make_suite "$FIX4/cogni-alpha/tests/test_live.sh" 0 --no-exec
make_suite "$FIX4/cogni-alpha/_archive/tests/test_dead.sh" 1
mkdir -p "$FIX4/cogni-alpha/tests/fixtures"
# No shebang, defines a function only: sourced by siblings, never executed.
printf 'helper_fn() { :; }\n' > "$FIX4/cogni-alpha/tests/fixtures/test_helpers.sh"

set +e
LIST4="$(python3 "$RUNNER" --root "$FIX4" --list 2>/dev/null)"
set -e
assert_json "_archive and fixtures paths are not discovered" "$LIST4" "
import json,sys
d=json.load(sys.stdin)['data']
assert d['suites']==['cogni-alpha/tests/test_live.sh'], d['suites']
"

set +e
OUT4="$(python3 "$RUNNER" --root "$FIX4" 2>/dev/null)"
CODE4=$?
set -e
check "non-executable suite with a shebang still runs and passes" \
  "$([ "$CODE4" -eq 0 ] && echo 0 || echo 1)"
assert_json "only the live suite ran" "$OUT4" "
import json,sys
d=json.load(sys.stdin)['data']
assert d['total']==1, d
assert d['passed']==1, d
"

# ---------------------------------------------------------------------------
# Case 7 — real tree: discovery is non-empty and structurally clean.
# ---------------------------------------------------------------------------
set +e
LIST7="$(python3 "$RUNNER" --root "$REPO_ROOT" --list 2>/dev/null)"
CODE7=$?
set -e
check "real-tree --list exits 0" "$([ "$CODE7" -eq 0 ] && echo 0 || echo 1)"
assert_json "real tree discovers suites, none under _archive or fixtures" "$LIST7" "
import json,sys
d=json.load(sys.stdin)['data']
assert d['total'] > 0, 'discovery found nothing — the globs stopped matching'
bad=[s for s in d['suites'] if '_archive' in s.split('/') or 'fixtures' in s.split('/')]
assert not bad, bad
roots={s.split('/')[0] for s in d['suites']}
assert 'tests' in roots, 'the four repo-root guard suites must be discovered too'
assert any(r.startswith('cogni-') for r in roots), roots
"

# ---------------------------------------------------------------------------
# Case 8 — an empty root discovers nothing, which must fail rather than pass.
# ---------------------------------------------------------------------------
FIX8="$WORK/empty"
mkdir -p "$FIX8"

set +e
OUT8="$(python3 "$RUNNER" --root "$FIX8" 2>/dev/null)"
CODE8=$?
set -e
check "empty root exits 1 rather than reporting a vacuous pass" \
  "$([ "$CODE8" -eq 1 ] && echo 0 || echo 1)"
assert_json "empty root reports success:false, total 0, and a non-empty error" "$OUT8" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
assert d['data']['total']==0, d
assert d['data']['suites']==[], d
assert d['error'], 'a discovery failure must carry an explanatory error string'
"

echo ""
if [ "$FAILED" -eq 0 ]; then
  green "All run-plugin-tests runner tests passed."
  exit 0
else
  red "Some run-plugin-tests runner tests failed."
  exit 1
fi
