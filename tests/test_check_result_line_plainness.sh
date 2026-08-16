#!/usr/bin/env bash
# test_check_result_line_plainness.sh — suite for the result-line plainness guard.
#
# Case labels are `<id> <description>` — an id token followed by a SPACE, never
# a colon abutting the id. A mutation harness matches
# `^[[:space:]]*FAIL:[[:space:]]+<case>([[:space:]]|$)` whole-token, so
# `--case A1` matches `FAIL: A1 arm A ...` while `--case 'A1:'` would match
# neither the red nor the green line and report case_not_found instead of a
# verdict.
#
# SELF-SCAN: this file sits inside the population the guard scans, so it never
# spells the escape literal contiguously. The pattern is assembled at run time
# from a lone backslash, and every dirty fixture is written through an UNQUOTED
# heredoc so the expansion lands in the fixture rather than in this source. A
# skip marker would be the wrong fix, and the guard ships none to reach for.
#
# ZERO DISCOVERY IS RED: the guard treats an empty sweep as a failure, so every
# fixture tree whose case asserts exit 0 or 1 must also contain at least one
# in-scope suite. Without that, a tree meant to prove an exclusion would exit 2
# and the case would silently be grading the empty-sweep path instead.
#
# bash 3.2 + python3 stdlib only.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-result-line-plainness.py"

red()   { printf '%s\n' "$1"; }
green() { printf '%s\n' "$1"; }

FAILED=0

check() {  # check <label> <condition-exit-code>
  if [ "$2" -eq 0 ]; then
    green "PASS: $1"
  else
    red "FAIL: $1"
    FAILED=1
  fi
}

# Argument order matches tests/test_check_workflow_yaml.sh's check_eq, so an
# assertion copied between the two repo-root suites cannot silently print its
# expected and actual the wrong way round. Delegates rather than repeating the
# emit format, which in this suite of all places must live in exactly one spot.
check_eq() {  # check_eq <label> <expected> <actual>
  if [ "$2" = "$3" ]; then
    check "$1" 0
  else
    check "$1 (expected $2, got $3)" 1
  fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

OUT="$WORK/out.json"
CODE=0

run_guard() {  # run_guard <root>
  set +e
  python3 "$GUARD" --root "$1" > "$OUT" 2>/dev/null
  CODE=$?
  set -e
}

# Label first, matching check/check_eq here and assert_json in the sibling
# suites. stderr is deliberately NOT suppressed: every assertion below carries a
# diagnostic operand whose only job is to print on failure, and swallowing it
# would leave a red case in CI with a label and nothing else. A traceback cannot
# be mistaken for a result line — none of its lines begin with PASS: or FAIL:.
py_assert() {  # py_assert <label> <python-body, single-quoted strings only>
  set +e
  OUT_PATH="$OUT" python3 -c "
import json, os, sys
d = json.load(open(os.environ['OUT_PATH']))
s = d['data']['summary'] if d.get('data') else {}
$2
"
  rc=$?
  set -e
  check "$1" "$rc"
}

# The escape pattern, assembled so this file's own source stays clean.
BSL='\'
ESC="${BSL}033"

mk_clean_suite() {  # mk_clean_suite <abs-path>
  mkdir -p "$(dirname "$1")"
  cat > "$1" <<'CLEAN'
#!/usr/bin/env bash
red()   { printf '%s\n' "$1"; }
green() { printf '%s\n' "$1"; }
green "PASS: clean probe"
CLEAN
}

mk_dirty_callsite() {  # mk_dirty_callsite <abs-path> — escape on a NON-definition line
  mkdir -p "$(dirname "$1")"
  cat > "$1" <<DIRTY
#!/usr/bin/env bash
printf '${ESC}[32mPASS: inline probe${ESC}[0m\n'
DIRTY
}

mk_dirty_emitter() {  # mk_dirty_emitter <abs-path> — coloured definition, CLEAN call sites
  mkdir -p "$(dirname "$1")"
  cat > "$1" <<DIRTY
#!/usr/bin/env bash
red() { printf '${ESC}[31m%s${ESC}[0m\n' "\$1"; }
red "FAIL: label line carrying no escape at all"
DIRTY
}

# --- A1 / A2: arm A fires alone on a call-site escape ------------------------
mk_clean_suite  "$WORK/a1/tests/test_clean.sh"
mk_dirty_callsite "$WORK/a1/tests/test_dirty.sh"
run_guard "$WORK/a1"
check_eq "A1 arm A flags an escape on a non-definition line" "1" "$CODE"
py_assert "A2 the finding names file, line and arm, and only arm A fired" "
assert s['by_arm'] == {'escape_literal': 2}, s['by_arm']
v = d['data']['violations'][0]
assert v['file'] == 'tests/test_dirty.sh', v['file']
assert v['line'] == 2, v['line']
assert v['arm'] == 'escape_literal', v['arm']
"

# --- B1 / B2: arm B fires alone on a coloured emitter definition -------------
# The call-site label lines here are clean, which is the whole point: this is
# the copy-an-emitter-into-a-new-suite regression, and a check keyed on a
# single source line carrying both the escape and the label would miss it.
mk_clean_suite "$WORK/b1/tests/test_clean.sh"
mk_dirty_emitter "$WORK/b1/tests/test_dirty.sh"
run_guard "$WORK/b1"
check_eq "B1 arm B flags a coloured emitter whose call sites are clean" "1" "$CODE"
py_assert "B2 arm A skipped the definition line, so the arms are disjoint" "
assert s['total'] == 1, s['total']
assert s['by_arm'] == {'emitter_not_plain': 1}, s['by_arm']
assert d['data']['violations'][0]['line'] == 2
"

# --- S1: both globs and both naming shapes are discovered -------------------
mk_dirty_callsite "$WORK/s1/tests/test-foo.sh"
mk_dirty_callsite "$WORK/s1/tests/test_foo.sh"
mk_dirty_callsite "$WORK/s1/cogni-demo/tests/test-bar.sh"
mk_dirty_callsite "$WORK/s1/cogni-demo/tests/test_bar.sh"
run_guard "$WORK/s1"
py_assert "S1 both globs and both hyphen and underscore namings are discovered" "
assert s['files_discovered'] == 4, s['files_discovered']
assert s['files_affected'] == 4, s['files_affected']
"

# --- S2: a suite one segment deeper is out of reach by construction ---------
# FIXTURE PATH, not a coded exclusion: the guard names no directory. The clean
# in-scope sibling is required — without it the tree discovers nothing and this
# case would exit 2, grading the empty-sweep path under S2's label.
mk_dirty_callsite "$WORK/s2/cogni-knowledge/_archive/tests/test_read_project_config_bare.sh"
mk_clean_suite    "$WORK/s2/cogni-knowledge/tests/test_in_scope.sh"
run_guard "$WORK/s2"
check_eq "S2 a suite one path segment deeper is not discovered" "0" "$CODE"
py_assert "S2b the deeper carrier contributes no finding and no discovery" "
assert s['files_discovered'] == 1, s['files_discovered']
assert s['total'] == 0, s['total']
"

# --- Z1: zero discovery is red, never a silent clean zero -------------------
mkdir -p "$WORK/z1"
run_guard "$WORK/z1"
check_eq "Z1 an empty tree is a discovery failure" "2" "$CODE"
py_assert "Z1b the empty sweep reports success false with an error" "
assert d['success'] is False
assert d['error']
"

# --- C1: the known false-positive shapes stay clean ------------------------
mkdir -p "$WORK/c1/tests"
cat > "$WORK/c1/tests/test_hazards.sh" <<HAZ
#!/usr/bin/env bash
red()   { printf '%s\n' "\$1"; }
green() { printf '%s\n' "\$1"; }
# A result line must start with the literal PASS: / FAIL: so a harness can match it.
EXPECTED='PASS: probe-green'
out=\$(printf '%s\n' "PASS")
case "\$out" in PASS) green "PASS: case arm" ;; "FAIL "*) red "FAIL: case arm" ;; esac
printf '%s\n' "\$mutant_out" | grep '^FAIL: S2 ' || true
B='${BSL}'
PAT="\${B}033"
HAZ
run_guard "$WORK/c1"
check_eq "C1 prose, expected-value literals, case arms and re-read greps stay clean" "0" "$CODE"
py_assert "C1b including a pattern assembled at run time from a lone backslash" "
assert s['total'] == 0, s['total']
"

# --- R1 / L1 / L2: the real tree, and the per-arm liveness floors -----------
# The floors are inequalities on purpose. An exact count would turn every
# future suite into a false failure, which is why the runner's own real-tree
# case asserts a lower bound rather than a fixed total.
run_guard "$REPO_ROOT"
check_eq "R1 the repository as it stands is clean" "0" "$CODE"
py_assert "L1 arm A liveness floor holds, so discovery is still reaching suites" "
assert s['files_scanned'] >= 80, s['files_scanned']
"
py_assert "L2 arm B liveness floor holds, so it is still matching definition lines" "
assert s['definitions_inspected'] >= 40, s['definitions_inspected']
"

echo ""
if [ "$FAILED" -eq 0 ]; then
  green "All result-line plainness guard tests passed."
  exit 0
else
  red "Some result-line plainness guard tests failed."
  exit 1
fi
