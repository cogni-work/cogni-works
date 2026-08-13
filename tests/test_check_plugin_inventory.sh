#!/usr/bin/env bash
# test_check_plugin_inventory.sh — self-test for the plugin-inventory guard.
#
# The guard asserts a bijection between marketplace plugins[] and the top-level
# directories holding .claude-plugin/plugin.json. Cases:
#   1. Consistent fixture (2 entries, 2 directories) -> exit 0.
#   2. Entry whose source points nowhere -> exit 1, code source-missing.
#   3. Directory with a manifest and no entry -> exit 1, code plugin-unlisted.
#      This is the direction no other guard in the repo covers; a suite that
#      passes without asserting it has no teeth.
#   4. Enumeration safety: a stale manifest under .claude/worktrees/** must NOT
#      register, or the guard would fail every clean tree that has a worktree.
#   5. Malformed marketplace -> exit 2 (script error), distinct from violations.
#   6. Real repo at branch head -> exit 0.
#
# bash 3.2 + stdlib python3 only. No arguments, no network.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-plugin-inventory.py"

# Plain text on purpose — result lines are machine-read; tooling anchors a
# literal PASS:/FAIL: prefix. Emit unconditionally, never probe the environment.
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

assert_json() {  # assert_json <label> <json> <python-asserts>
  set +e
  printf '%s' "$2" | python3 -c "$3"
  local _code=$?
  set -e
  check "$1" "$_code"
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# make_plugin <fixture-root> <name>
make_plugin() {
  mkdir -p "$1/$2/.claude-plugin"
  printf '{\n  "name": "%s",\n  "version": "0.0.1"\n}\n' "$2" > "$1/$2/.claude-plugin/plugin.json"
}

# make_marketplace <fixture-root> <name>...
make_marketplace() {
  local root="$1"; shift
  mkdir -p "$root/.claude-plugin"
  {
    printf '{\n  "name": "fixture",\n  "plugins": [\n'
    local first=1
    for n in "$@"; do
      [ $first -eq 1 ] || printf ',\n'
      first=0
      printf '    {"name": "%s", "source": "./%s", "version": "0.0.1"}' "$n" "$n"
    done
    printf '\n  ]\n}\n'
  } > "$root/.claude-plugin/marketplace.json"
}

run_guard() {  # run_guard <root> -> sets OUT, CODE
  set +e
  OUT=$("$GUARD" --root "$1" 2>/dev/null)
  CODE=$?
  set -e
}

# ---------------------------------------------------------------- case 1
CONSISTENT="$WORK/consistent"
make_plugin "$CONSISTENT" cogni-alpha
make_plugin "$CONSISTENT" cogni-beta
make_marketplace "$CONSISTENT" cogni-alpha cogni-beta
run_guard "$CONSISTENT"
check "consistent inventory exits 0" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "consistent inventory reports zero violations" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
assert d['data']['marketplace_plugins']==2, d['data']
assert d['data']['plugin_directories']==2, d['data']
"

# ---------------------------------------------------------------- case 2
NODIR="$WORK/entry-without-dir"
make_plugin "$NODIR" cogni-alpha
make_marketplace "$NODIR" cogni-alpha cogni-ghost
run_guard "$NODIR"
check "marketplace entry with no directory exits non-zero" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "entry with no directory reports source-missing naming the plugin" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
v=[x for x in d['data']['violations'] if x['code']=='source-missing']
assert len(v)==1, d['data']['violations']
assert v[0]['plugin']=='cogni-ghost', v
"

# ---------------------------------------------------------------- case 3
# The uncovered direction: a plugin directory no marketplace entry names.
UNLISTED="$WORK/dir-without-entry"
make_plugin "$UNLISTED" cogni-alpha
make_plugin "$UNLISTED" cogni-orphan
make_marketplace "$UNLISTED" cogni-alpha
run_guard "$UNLISTED"
check "unlisted plugin directory exits non-zero" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "unlisted directory reports plugin-unlisted naming the directory" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
v=[x for x in d['data']['violations'] if x['code']=='plugin-unlisted']
assert len(v)==1, d['data']['violations']
assert v[0]['plugin']=='cogni-orphan', v
"

# ---------------------------------------------------------------- case 4
# A stale manifest inside .claude/worktrees/** is not a top-level plugin.
NESTED="$WORK/nested-manifest"
make_plugin "$NESTED" cogni-alpha
make_marketplace "$NESTED" cogni-alpha
mkdir -p "$NESTED/.claude/worktrees/wt-1/cogni-stale/.claude-plugin"
printf '{"name":"cogni-stale","version":"9.9.9"}\n' \
  > "$NESTED/.claude/worktrees/wt-1/cogni-stale/.claude-plugin/plugin.json"
run_guard "$NESTED"
check "stale manifest under .claude/worktrees is ignored" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "nested manifest does not register as a plugin directory" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['plugin_directories']==1, d['data']
"

# ---------------------------------------------------------------- case 5
BROKEN="$WORK/broken-marketplace"
make_plugin "$BROKEN" cogni-alpha
mkdir -p "$BROKEN/.claude-plugin"
printf '{ not json\n' > "$BROKEN/.claude-plugin/marketplace.json"
run_guard "$BROKEN"
check "malformed marketplace exits 2, not 1" "$([ "$CODE" -eq 2 ] && echo 0 || echo 1)"
assert_json "malformed marketplace reports the error in the envelope" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
assert d['error'], d
"

# ---------------------------------------------------------------- case 6
run_guard "$REPO_ROOT"
check "real repo inventory is consistent" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "real repo: marketplace count equals directory count" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['marketplace_plugins']==d['data']['plugin_directories'], d['data']
"

echo
if [ "$FAILED" -eq 0 ]; then
  green "All plugin-inventory guard tests passed."
else
  red "Some plugin-inventory guard tests FAILED."
fi
exit "$FAILED"
