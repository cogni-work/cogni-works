#!/usr/bin/env bash
#
# Self-test for scripts/check-workflow-yaml.py.
#
# Cases:
#   WY1   the real tree scans clean
#   WY2   an unquoted plain-scalar colon-space is flagged with file and line
#   WY3   the same value, quoted, is accepted
#   WY4   a block-scalar body is skipped, and the dedented line is re-processed
#   WY5   an empty workflows directory is a discovery failure
#   WY6   a root with no .github directory is a discovery failure too
#   WY7   a workflow that declares no jobs is flagged, both arms
#   WY8   .yaml files are discovered, not only .yml
#   WY9   an undecodable file yields the error envelope and exit 2
#   WY10  a comment carrying a colon-space is not flagged
#
# Satisfies the runner's three-property contract: it exits non-zero on failure
# and zero otherwise, runs as `bash <path>` with no arguments from any working
# directory, and needs no network or credentials, writing only inside its own
# mktemp -d.
#
# Self-reference limitation, restated here because this is one of the three
# surfaces hosting the check: this suite runs inside lint.yml's test-suite job,
# so it cannot catch lint.yml itself failing to load — that job would not run
# either. That direction is covered by the separate workflow-guard.yml job, and
# the two together leave only a simultaneous break of both files uncovered.
#
# Fixtures always drive the real guard through --root rather than a vendored
# copy of its logic, so the suite cannot keep passing against a frozen snapshot
# while the guard itself drifts.
#
# Result-line ids: every emitted PASS:/FAIL: line carries a first-token id
# (WY<n><letter>), unique PER EMITTED LINE rather than per logical case, so
# `mutation-check.sh --case <id>` addresses exactly one assertion. The id is
# followed by a SPACE, never a colon abutting it — the harness matches the
# case whole-token, so a colon-abutting id returns case_not_found. A new
# assertion takes the next free id rather than renumbering its neighbours.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-workflow-yaml.py"

# Plain, uncoloured result lines — unconditionally, matching the harness-parsable
# suites elsewhere in the repo. A result line must start with the literal `PASS:` /
# `FAIL:` so a mutation harness can classify it with `^[[:space:]]*FAIL:[[:space:]]+`;
# an ANSI escape sequence precedes the label and defeats that match. Deciding by
# `[ -t 1 ]` instead would make parsability environment-dependent — run the suite
# under a pty and the colour, and the failure, come back.
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

check_eq() {  # check_eq <label> <expected> <actual>
  check "$1" "$([ "$2" = "$3" ] && echo 0 || echo 1)"
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

# --- WY1: the real tree scans clean ------------------------------------------
# False-positive immunity against every workflow file actually in the repo,
# each of which legitimately carries a colon-space inside quoted values, block
# bodies or comments.

set +e
OUT1=$(python3 "$GUARD" 2>/dev/null)
CODE1=$?
set -e
check_eq "WY1a real tree scans clean (exit 0)" 0 "$CODE1"
assert_json "WY1b real tree reports success with no violations" "$OUT1" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d
assert d['data']['summary']['files_scanned']>=3, d
"

# --- WY2: the defect shape is flagged ----------------------------------------
# The exact shape that took every gate job in one file offline. This is the case (WY2a)
# the mutation recipe pins.

mkdir -p "$WORK/red/.github/workflows"
cat > "$WORK/red/.github/workflows/broken.yml" <<'EOF'
name: Broken
on:
  workflow_dispatch:
jobs:
  demo:
    runs-on: ubuntu-latest
    steps:
      - name: Assert zero retired-plugin dispatches in live surfaces (set: scripts/x.json)
        run: echo hi
EOF

set +e
OUT2=$(python3 "$GUARD" --root "$WORK/red" 2>/dev/null)
CODE2=$?
set -e
check_eq "WY2a unquoted plain-scalar colon-space exits 1" 1 "$CODE2"
assert_json "WY2b violation names the file, the 1-based line and the kind" "$OUT2" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
v=[x for x in d['data']['violations'] if x['kind']=='plain_scalar_colon_space']
assert len(v)==1, d
assert v[0]['file']=='.github/workflows/broken.yml', v
assert v[0]['line']==8, v
assert v[0]['context'], v
"

# --- WY3: the quoted form is accepted ----------------------------------------
# Without this the guard would be unsatisfiable — there would be no way to write
# the step name at all.

mkdir -p "$WORK/quoted/.github/workflows"
cat > "$WORK/quoted/.github/workflows/ok.yml" <<'EOF'
name: Quoted
on:
  workflow_dispatch:
jobs:
  demo:
    runs-on: ubuntu-latest
    steps:
      - name: "Assert zero retired-plugin dispatches in live surfaces (set: scripts/x.json)"
        run: echo hi
EOF

set +e
python3 "$GUARD" --root "$WORK/quoted" >/dev/null 2>&1
CODE3=$?
set -e
check_eq "WY3a quoted value is accepted (exit 0)" 0 "$CODE3"

# --- WY4: block-scalar body skipped, dedented line re-processed ---------------
# Modelled on the live shape at .github/workflows/cla.yml — an `if: |` opener at
# column 4, its body at column 6, and `steps:` dedenting back to column 4. The
# body carries two colon-spaces on one line, which must NOT be flagged; a real
# violation sits after the dedent, which MUST be. A state machine that never
# exits its block would miss the second and fail this case.

mkdir -p "$WORK/dedent/.github/workflows"
cat > "$WORK/dedent/.github/workflows/dedent.yml" <<'EOF'
name: Dedent
on:
  workflow_dispatch:
jobs:
  demo:
    runs-on: ubuntu-latest
    if: |
      github.event.comment.body == 'recheck'
      || github.event_name == 'pull_request_target'
    steps:
      - name: Runs after the dedent (set: scripts/x.json)
        run: |
          echo "PR opener: $X"
          python3 -c 'print("%s: %s, %s: %s" % (a,b,c,d))'
EOF

set +e
OUT4=$(python3 "$GUARD" --root "$WORK/dedent" 2>/dev/null)
CODE4=$?
set -e
check_eq "WY4a block body skipped and dedented line re-processed (exit 1)" 1 "$CODE4"
assert_json "WY4b flags only the line after the dedent, never the block body" "$OUT4" "
import json,sys
d=json.load(sys.stdin)
v=[x for x in d['data']['violations'] if x['kind']=='plain_scalar_colon_space']
assert len(v)==1, v
assert v[0]['line']==11, v
"

# --- WY5: an empty workflows directory is a discovery failure -----------------
# A guard that finds nothing and reports green is worse than no guard, because
# it reads as evidence.

mkdir -p "$WORK/empty/.github/workflows"

set +e
OUT5=$(python3 "$GUARD" --root "$WORK/empty" 2>/dev/null)
CODE5=$?
set -e
check_eq "WY5a empty workflows directory exits 1" 1 "$CODE5"
assert_json "WY5b empty directory reports success:false and a non-empty error" "$OUT5" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
assert d['data']['scanned']==[], d
assert d['error'], 'a discovery failure must carry an explanatory error string'
"

# --- WY6: a missing .github directory fails identically -----------------------
# A different code path from WY5 (a missing directory rather than an empty
# listing), and neither may report a vacuous pass.

mkdir -p "$WORK/nogithub"

set +e
OUT6=$(python3 "$GUARD" --root "$WORK/nogithub" 2>/dev/null)
CODE6=$?
set -e
check_eq "WY6a missing .github directory exits 1" 1 "$CODE6"
assert_json "WY6b missing directory reports success:false and a non-empty error" "$OUT6" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
assert d['data']['scanned']==[], d
assert d['error'], 'a missing directory must carry an explanatory error string'
"

# --- WY7: a workflow declaring no jobs is flagged, both arms ------------------
# A file that parses but declares no jobs posts no checks either — the same
# user-visible outcome as a load failure. `line` points at the jobs key when it
# is present but childless, and is null when the key is absent, rather than a
# fabricated line 1 pointing at something unrelated.

mkdir -p "$WORK/jobless/.github/workflows"
cat > "$WORK/jobless/.github/workflows/childless.yml" <<'EOF'
name: Childless
on:
  workflow_dispatch:
jobs:
EOF
cat > "$WORK/jobless/.github/workflows/absent.yml" <<'EOF'
name: Absent
on:
  workflow_dispatch:
EOF

set +e
OUT7=$(python3 "$GUARD" --root "$WORK/jobless" 2>/dev/null)
CODE7=$?
set -e
check_eq "WY7a jobless workflows exit 1" 1 "$CODE7"
assert_json "WY7b childless jobs reports its line, absent jobs reports null" "$OUT7" "
import json,sys
d=json.load(sys.stdin)
v={x['file']: x for x in d['data']['violations'] if x['kind']=='no_jobs'}
assert len(v)==2, v
assert v['.github/workflows/childless.yml']['line']==4, v
assert v['.github/workflows/absent.yml']['line'] is None, v
"

# --- WY8: .yaml is discovered, not only .yml ---------------------------------
# A guard blind to one of the two extensions GitHub honours would leave half the
# surface unguarded.

mkdir -p "$WORK/ext/.github/workflows"
cat > "$WORK/ext/.github/workflows/broken.yaml" <<'EOF'
name: Yaml Extension
on:
  workflow_dispatch:
jobs:
  demo:
    runs-on: ubuntu-latest
    steps:
      - name: Broken on a yaml extension (set: scripts/x.json)
        run: echo hi
EOF
printf 'notes, not a workflow\n' > "$WORK/ext/.github/workflows/README.txt"

set +e
OUT8=$(python3 "$GUARD" --root "$WORK/ext" 2>/dev/null)
CODE8=$?
set -e
check_eq "WY8a .yaml extension is discovered and scanned (exit 1)" 1 "$CODE8"
assert_json "WY8b the .yaml file is scanned and the .txt is not" "$OUT8" "
import json,sys
d=json.load(sys.stdin)
assert d['data']['scanned']==['.github/workflows/broken.yaml'], d['data']['scanned']
"

# --- WY9: an undecodable file yields the error envelope, not a traceback ------

mkdir -p "$WORK/binary/.github/workflows"
printf 'name: Binary\n\xff\xfe not utf-8 \xff\n' > "$WORK/binary/.github/workflows/bad.yml"

set +e
OUT9=$(python3 "$GUARD" --root "$WORK/binary" 2>"$WORK/stderr9")
CODE9=$?
set -e
check_eq "WY9a undecodable file exits 2" 2 "$CODE9"
assert_json "WY9b error envelope carries empty data and a non-empty error" "$OUT9" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
assert d['data']=={}, d
assert d['error'], d
"
set +e
grep -q 'Traceback' "$WORK/stderr9"
GREP9=$?
set -e
check "WY9c no traceback reaches stderr" "$([ "$GREP9" -ne 0 ] && echo 0 || echo 1)"

# --- WY10: a comment carrying a colon-space is not flagged --------------------
# The live shape in .github/workflows/lint.yml, which WY1 already depends on.
# Asserting it directly means a comment-stripping regression fails with a
# legible label instead of only reddening the real-tree case.

mkdir -p "$WORK/comment/.github/workflows"
cat > "$WORK/comment/.github/workflows/commented.yml" <<'EOF'
name: Commented
on:
  workflow_dispatch:
jobs:
  demo:
    runs-on: ubuntu-latest
    steps:
      # Keep this name free of ": " — an unquoted YAML plain scalar containing a
      # colon-space makes the whole workflow unparseable.
      - name: Checkout
        run: echo hi  # trailing note: still only a comment
EOF

set +e
python3 "$GUARD" --root "$WORK/comment" >/dev/null 2>&1
CODE10=$?
set -e
check_eq "WY10a comments carrying a colon-space are not flagged (exit 0)" 0 "$CODE10"

echo ""
if [ "$FAILED" -eq 0 ]; then
  green "All workflow-YAML guard tests passed."
  exit 0
else
  red "Some workflow-YAML guard tests failed."
  exit 1
fi
