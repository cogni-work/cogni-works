#!/usr/bin/env bash
#
# Self-test for the two GitHub Actions `run:` blocks that must clear the
# inherited `-e` before capturing a guard's exit code (issue #1767, follow-up
# to #1766).
#
# Actions runs a `run:` block as `bash -e {0}`, so `-e` is in force before the
# block's first line. `set -uo pipefail` does NOT clear it — only `set +e` does.
# A block that captures a command's output and then reads `$?` therefore aborts
# at the capturing command itself on any non-zero exit, and every diagnostic
# below it is unreachable.
#
# Blocks under test, both extracted PROGRAMMATICALLY from the shipped YAML so
# this suite cannot go green against a workflow that has since changed:
#   .github/workflows/lint.yml            "Discover and run every plugin and repo-root test suite"
#   .github/workflows/cogni-version-bump.yml  "Apply the patch bump"
#
# NOT the standing class-wide guard. This asserts the behaviour of exactly two
# named blocks and never scans other workflows for the pattern — a repo-wide
# guard for the class was considered during #1766's planning and deliberately
# excluded from both #1766 and #1767.
#
# Cases:
#   wfe-01  lint block extracts and its first executable line is `set +e`
#   wfe-02  in the lint block `set +e` precedes both `set -uo pipefail` and the capture
#   wfe-03  lint rc=0 exits 0 and emits no per-suite annotation
#   wfe-04  lint rc=1 EMITS the per-suite `::error file=` annotation  <- the defect path
#   wfe-05  lint rc=2 exits 2 with the annotation loop still reached
#   wfe-06  lint FALSIFIER: `set +e` removed, rc=1, annotation ABSENT
#   wfe-07  bump block extracts and its first executable line is `set +e`
#   wfe-08  bump RC=0 writes count and deferred_failure=0 to $GITHUB_OUTPUT, exits 0
#   wfe-09  bump RC=1 hard skip emits its skip annotation and writes BOTH outputs
#   wfe-10  bump RC=1 with nothing bumped writes count=0 and says nothing to do
#   wfe-11  bump RC=2 errors loudly, exits 1, and writes no count
#   wfe-12  bump passes --dry-run through when DRY_RUN=true
#   wfe-13  bump FALSIFIER: `set +e` removed, RC=1, deferred_failure ABSENT
#   wfe-14  the bump block adds no terminal `exit "$RC"` (it must SUCCEED on RC=1)
#   wfe-15  lint.yml carries at least three exact `set +e` lines and no stale comment
#   wfe-16  the version-touch gate still keeps `set +e` ahead of its capture
#   wfe-17  the retirement-ledger gate still keeps `set +e` ahead of its capture
#
# wfe-04 keys on the ANNOTATION, never on the exit code: the block exits 1 on a
# failing sweep both with and without the fix (with it, via the terminal
# `exit "$rc"`; without it, via the aborting command), so an exit-code assertion
# there could never redden. The annotation is what the fix actually restores.
#
# Every case runs the extracted block under `bash -e` in its OWN mktemp -d, with
# $GITHUB_OUTPUT pointed at a fresh per-case file. Both are load-bearing: the
# blocks write scratch files into the cwd, and the bump block appends to
# "$GITHUB_OUTPUT" under `set -u`, which aborts the shell on an unset variable
# EVEN WITH `set +e` in force — so a shared or unset path would make every bump
# case pass or fail for the wrong reason.
#
# Satisfies the runner's three-property contract: exits non-zero on failure and
# zero otherwise, runs as `bash <path>` with no arguments from any working
# directory, and needs no network or credentials, writing only inside its own
# mktemp -d.
#
# Result-line ids: every emitted PASS:/FAIL: line carries a first-token id
# (wfe-NN), unique per emitted line, followed by a SPACE and never a colon
# abutting it, so `mutation-check.sh --case <id>` addresses exactly one
# assertion.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
LINT_YML="$REPO_ROOT/.github/workflows/lint.yml"
BUMP_YML="$REPO_ROOT/.github/workflows/cogni-version-bump.yml"

REAL_PYTHON3="$(command -v python3)"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Plain, uncoloured result lines — unconditionally. A result line must start
# with the literal PASS:/FAIL: so a mutation harness can classify it with
# `^[[:space:]]*FAIL:[[:space:]]+`; an escape sequence before the label defeats
# that match. Deciding by `[ -t 1 ]` would make parsability depend on whether
# the suite ran under a pty.
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

# ---------------------------------------------------------------------------
# Programmatic block extraction from the shipped YAML.
#
# stdlib only: PyYAML is not available in this repo and nothing imports it
# (see scripts/check-workflow-yaml.py). Keyed on the `- name:` line and the
# following `run: |`, collecting the block-scalar body and dedenting it.
#
# The dedent must be exact. The lint block ends a heredoc with a plain <<'PY'
# terminator, which only closes when dedenting lands `PY` at column 0.
# ---------------------------------------------------------------------------
extract_block() {  # extract_block <yaml-path> <step-name> <out-path>
  "$REAL_PYTHON3" - "$1" "$2" "$3" <<'PY'
import io, sys

path, step_name, out = sys.argv[1], sys.argv[2], sys.argv[3]
lines = io.open(path, encoding="utf-8").read().split("\n")

start = None
for i, line in enumerate(lines):
    if line.strip() == "- name: " + step_name:
        start = i
        break
if start is None:
    sys.stderr.write("step not found: %s\n" % step_name)
    sys.exit(3)

run_at = None
for i in range(start + 1, len(lines)):
    stripped = lines[i].strip()
    if stripped == "run: |":
        run_at = i
        break
    # a new step began before any run: — the named step has no block scalar
    if stripped.startswith("- name:"):
        break
if run_at is None:
    sys.stderr.write("no 'run: |' for step: %s\n" % step_name)
    sys.exit(3)

body_indent = len(lines[run_at]) - len(lines[run_at].lstrip(" ")) + 2
body = []
for line in lines[run_at + 1:]:
    if line.strip() == "":
        body.append("")
        continue
    indent = len(line) - len(line.lstrip(" "))
    if indent < body_indent:
        break
    body.append(line[body_indent:])

while body and body[-1] == "":
    body.pop()

io.open(out, "w", encoding="utf-8").write("\n".join(body) + "\n")
PY
}

# Strip the `set +e` line — the falsifier mutation, applied to an extracted copy.
strip_set_plus_e() {  # strip_set_plus_e <in> <out>
  grep -v '^set +e$' "$1" > "$2"
}

# ---------------------------------------------------------------------------
# A PATH-shimmed `python3` that stubs the two guard scripts on argv[1] and
# delegates every other invocation (`-`, `-c`) to the real interpreter, so the
# blocks' own annotation heredocs and COUNT expression genuinely execute.
# ---------------------------------------------------------------------------
make_python_shim() {  # make_python_shim <bindir>
  mkdir -p "$1"
  cat > "$1/python3" <<SHIM
#!/usr/bin/env bash
case "\${1:-}" in
  *run-plugin-tests.py|*apply-version-bump.py)
    printf '%s\n' "\$@" > "\$STUB_ARGV_FILE"
    cat "\$STUB_STDOUT_FILE"
    if [ -n "\${STUB_STDERR_FILE:-}" ] && [ -f "\$STUB_STDERR_FILE" ]; then
      cat "\$STUB_STDERR_FILE" >&2
    fi
    exit "\$STUB_RC"
    ;;
  *)
    exec "$REAL_PYTHON3" "\$@"
    ;;
esac
SHIM
  chmod +x "$1/python3"
}

# Run an extracted block under `bash -e`, mirroring Actions' `bash -e {0}`.
# Each invocation gets a fresh cwd and a fresh $GITHUB_OUTPUT.
run_block() {  # run_block <block> <case-dir> <stub-rc> <stub-stdout> [stub-stderr]
  local block="$1" dir="$2" rc=0
  mkdir -p "$dir/bin"
  make_python_shim "$dir/bin"
  : > "$dir/github_output"
  : > "$dir/stub_argv"
  (
    cd "$dir"
    export PATH="$dir/bin:$PATH"
    export GITHUB_OUTPUT="$dir/github_output"
    export STUB_RC="$3"
    export STUB_STDOUT_FILE="$4"
    export STUB_STDERR_FILE="${5:-}"
    export STUB_ARGV_FILE="$dir/stub_argv"
    bash -e "$block"
  ) > "$dir/stdout" 2> "$dir/stderr" || rc=$?
  printf '%s' "$rc" > "$dir/exit"
}

mkdir -p "$WORK/blocks"
LINT_BLOCK="$WORK/blocks/lint.sh"
BUMP_BLOCK="$WORK/blocks/bump.sh"
extract_block "$LINT_YML" "Discover and run every plugin and repo-root test suite" "$LINT_BLOCK"
extract_block "$BUMP_YML" "Apply the patch bump" "$BUMP_BLOCK"

LINT_FALSIFIER="$WORK/blocks/lint_falsifier.sh"
BUMP_FALSIFIER="$WORK/blocks/bump_falsifier.sh"
strip_set_plus_e "$LINT_BLOCK" "$LINT_FALSIFIER"
strip_set_plus_e "$BUMP_BLOCK" "$BUMP_FALSIFIER"

first_exec_line() {  # first non-blank, non-comment line of an extracted block
  grep -vE '^[[:space:]]*(#|$)' "$1" | head -1
}

# First 1-based line CONTAINING the fragment, skipping comment lines.
#
# Skipping comments is load-bearing, not tidiness. Every one of these blocks
# carries a rationale comment that spells `set +e` and `rc=$?` in prose, so a
# plain substring match resolves to the comment instead of the statement — and
# whether that is harmless depends only on whether the comment happens to sit
# above or below the code, which is exactly what an ordering assertion must not
# depend on. A version of this helper without the comment filter reported the
# retirement-ledger gate as correctly ordered while `set +e` sat two lines BELOW
# its capture.
code_line_of() {  # code_line_of <file> <fixed-string> -> 1-based line number, or empty
  awk -v needle="$2" '
    index($0, needle) > 0 {
      line = $0
      sub(/^[[:space:]]*/, "", line)
      if (substr(line, 1, 1) != "#") { print NR; exit }
    }' "$1"
}

# --- Fixtures ---------------------------------------------------------------
FIX="$WORK/fixtures"; mkdir -p "$FIX"

# run-plugin-tests.py envelopes
printf '%s\n' '{"success": true, "data": {"failed_suites": []}, "error": null}'          > "$FIX/tests_pass.json"
printf '%s\n' '{"success": false, "data": {"failed_suites": ["tests/test_alpha.sh"]}, "error": "1 suite failed"}' > "$FIX/tests_fail.json"
printf '%s\n' '{"success": false, "data": {"failed_suites": []}, "error": "--root is not a directory"}'          > "$FIX/tests_root_err.json"

# apply-version-bump.py envelopes
printf '%s\n' '{"success": true, "data": {"bumped": ["cogni-alpha"], "skipped": [], "paths_to_stage": ["cogni-alpha/.claude-plugin/plugin.json"]}, "error": null}' > "$FIX/bump_clean.json"
printf '%s\n' '{"success": false, "data": {"bumped": ["cogni-alpha"], "skipped": [{"severity": "error", "plugin": "cogni-beta", "reason": "mirror drift in two places"}], "paths_to_stage": []}, "error": "hard skip"}' > "$FIX/bump_hardskip.json"
printf '%s\n' '{"success": false, "data": {"bumped": [], "skipped": [{"severity": "error", "plugin": "cogni-beta", "reason": "mirror drift in two places"}], "paths_to_stage": []}, "error": "hard skip"}' > "$FIX/bump_hardskip_none.json"
printf '%s\n' '{"success": false, "data": {"bumped": [], "skipped": [], "paths_to_stage": []}, "error": "verification error"}' > "$FIX/bump_error.json"
printf '%s\n' 'apply-version-bump: verification error' > "$FIX/bump_error.err"

# === lint.yml block =========================================================

check "wfe-01 lint block extracts and opens with set +e" \
  "$([ "$(first_exec_line "$LINT_BLOCK")" = "set +e" ] && echo 0 || echo 1)"

L_PLUS=$(code_line_of "$LINT_BLOCK" 'set +e')
L_PIPE=$(code_line_of "$LINT_BLOCK" 'set -uo pipefail')
L_CAP=$(code_line_of "$LINT_BLOCK" 'python3 scripts/run-plugin-tests.py > plugin-tests.json')
check "wfe-02 lint set +e precedes set -uo pipefail and the capture" \
  "$([ -n "$L_PLUS" ] && [ -n "$L_PIPE" ] && [ -n "$L_CAP" ] && [ "$L_PLUS" -lt "$L_PIPE" ] && [ "$L_PLUS" -lt "$L_CAP" ] && echo 0 || echo 1)"

D="$WORK/c03"; run_block "$LINT_BLOCK" "$D" 0 "$FIX/tests_pass.json"
check "wfe-03 lint rc=0 exits 0 with no per-suite annotation" \
  "$([ "$(cat "$D/exit")" = "0" ] && ! grep -q '::error file=' "$D/stdout" && echo 0 || echo 1)"

D="$WORK/c04"; run_block "$LINT_BLOCK" "$D" 1 "$FIX/tests_fail.json"
check "wfe-04 lint rc=1 emits the per-suite annotation and exits 1" \
  "$(grep -q '::error file=tests/test_alpha.sh::test suite failed: tests/test_alpha.sh' "$D/stdout" && [ "$(cat "$D/exit")" = "1" ] && echo 0 || echo 1)"

D="$WORK/c05"; run_block "$LINT_BLOCK" "$D" 2 "$FIX/tests_root_err.json"
check "wfe-05 lint rc=2 exits 2 with the annotation loop reached and no traceback" \
  "$([ "$(cat "$D/exit")" = "2" ] && ! grep -q 'Traceback' "$D/stderr" && echo 0 || echo 1)"

D="$WORK/c06"; run_block "$LINT_FALSIFIER" "$D" 1 "$FIX/tests_fail.json"
check "wfe-06 lint falsifier without set +e loses the annotation" \
  "$(! grep -q '::error file=' "$D/stdout" && echo 0 || echo 1)"

# === cogni-version-bump.yml block ===========================================

check "wfe-07 bump block extracts and opens with set +e" \
  "$([ "$(first_exec_line "$BUMP_BLOCK")" = "set +e" ] && echo 0 || echo 1)"

D="$WORK/c08"; run_block "$BUMP_BLOCK" "$D" 0 "$FIX/bump_clean.json"
check "wfe-08 bump RC=0 writes count=1 and deferred_failure=0 and exits 0" \
  "$(grep -qx 'count=1' "$D/github_output" && grep -qx 'deferred_failure=0' "$D/github_output" && [ "$(cat "$D/exit")" = "0" ] && echo 0 || echo 1)"

D="$WORK/c09"; run_block "$BUMP_BLOCK" "$D" 1 "$FIX/bump_hardskip.json"
check "wfe-09 bump RC=1 hard skip annotates and writes both outputs, exiting 0" \
  "$(grep -q '::error::version-bump skipped cogni-beta: mirror drift in two places' "$D/stdout" && grep -qx 'count=1' "$D/github_output" && grep -qx 'deferred_failure=1' "$D/github_output" && [ "$(cat "$D/exit")" = "0" ] && echo 0 || echo 1)"

D="$WORK/c10"; run_block "$BUMP_BLOCK" "$D" 1 "$FIX/bump_hardskip_none.json"
check "wfe-10 bump RC=1 with nothing bumped writes count=0 and reports nothing to do" \
  "$(grep -qx 'count=0' "$D/github_output" && grep -qx 'deferred_failure=1' "$D/github_output" && grep -q 'no touched plugin to bump' "$D/stdout" && [ "$(cat "$D/exit")" = "0" ] && echo 0 || echo 1)"

D="$WORK/c11"; run_block "$BUMP_BLOCK" "$D" 2 "$FIX/bump_error.json" "$FIX/bump_error.err"
check "wfe-11 bump RC=2 errors loudly, exits 1, and writes no count" \
  "$(grep -q '::error::apply-version-bump.py errored' "$D/stdout" && [ "$(cat "$D/exit")" = "1" ] && ! grep -q '^count=' "$D/github_output" && echo 0 || echo 1)"

# A prefix assignment exports DRY_RUN for the duration of the call only, so
# wfe-13 below still sees it unset.
D="$WORK/c12"; DRY_RUN=true run_block "$BUMP_BLOCK" "$D" 0 "$FIX/bump_clean.json"
check "wfe-12 bump forwards --dry-run when DRY_RUN is true and still exits 0" \
  "$(grep -qx -- '--dry-run' "$D/stub_argv" && [ "$(cat "$D/exit")" = "0" ] && echo 0 || echo 1)"

D="$WORK/c13"; run_block "$BUMP_FALSIFIER" "$D" 1 "$FIX/bump_hardskip.json"
check "wfe-13 bump falsifier without set +e never writes deferred_failure" \
  "$(! grep -q '^deferred_failure=' "$D/github_output" && [ "$(cat "$D/exit")" != "0" ] && echo 0 || echo 1)"

check "wfe-14 bump block adds no terminal exit of RC" \
  "$(! grep -qE '^[[:space:]]*exit[[:space:]]+"?\$(RC|\{RC\})"?[[:space:]]*$' "$BUMP_BLOCK" && echo 0 || echo 1)"

SET_PLUS_E_COUNT=$(grep -c '^          set +e$' "$LINT_YML" || true)
STALE_COMMENT=$(grep -c 'the runner.s exit code is the result we report on' "$LINT_YML" || true)
# The count is a FLOOR, not an equality. A future block in this class is fixed by
# adding a fourth `set +e`, and an equality here would redden on that correct work.
check "wfe-15 lint.yml carries at least three exact set +e lines and no stale comment" \
  "$([ "$SET_PLUS_E_COUNT" -ge 3 ] && [ "$STALE_COMMENT" = "0" ] && echo 0 || echo 1)"

# The count above catches a DELETION but not a REORDERING: `set +e` moved below the
# capture reproduces this very defect while the count still reads three. The two
# lint.yml blocks this PR does not otherwise touch therefore get the same ordering
# assertion the fixed blocks get, structurally rather than by counting lines.
guard_ordering() {  # guard_ordering <case-id> <step-name> <capture-fragment>
  local blk="$WORK/blocks/$1.sh" plus pipe cap
  extract_block "$LINT_YML" "$2" "$blk"
  plus=$(code_line_of "$blk" 'set +e')
  pipe=$(code_line_of "$blk" 'set -uo pipefail')
  cap=$(code_line_of "$blk" "$3")
  check "$1 $2 keeps set +e ahead of its capture" \
    "$([ -n "$plus" ] && [ -n "$pipe" ] && [ -n "$cap" ] && [ "$plus" -lt "$pipe" ] && [ "$plus" -lt "$cap" ] && echo 0 || echo 1)"
}

guard_ordering "wfe-16" "Assert no plugin version was touched on this branch" 'rc=$?'
guard_ordering "wfe-17" "Assert every deleted skill's trigger phrases are accounted for" 'rc=$?'

exit "$FAILED"
