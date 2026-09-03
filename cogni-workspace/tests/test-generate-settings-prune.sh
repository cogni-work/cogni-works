#!/usr/bin/env bash
# Regression test for the update-mode env-key prune in
# scripts/generate-settings.sh.
#
# Contract under test: an --update run removes the env keys the script itself
# generated for plugins absent from the current plugin set, and removes nothing
# else. A key outside that generated namespace survives with its value
# byte-identical, the three unconditional workspace keys survive regardless of
# the plugin list, and the non-"env" top-level keys of settings.local.json are
# untouched.
#
# The discriminator is the derived generated namespace, never a list of retired
# plugin names, so these cases stay meaningful for the next plugin removed.
#
# Case labels use a letter-prefixed two-character id with no colon after the id,
# matching the convention test-mcp-declaration-hygiene.sh documents: the
# mutation harness matches --case as a whole token, so no id may be a prefix of
# another.
#
# stdlib-only: bash + python3, no pip deps, no network, per the repo-wide script
# convention.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
GEN="$WS_ROOT/scripts/generate-settings.sh"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

# A missing script is a broken suite, never a clean one: without this floor
# every later assertion would pass vacuously against a file that never ran.
if [ ! -f "$GEN" ]; then
  fail "L1 generate-settings.sh located at $GEN"
  echo
  echo "1 test(s) failed."
  exit 1
fi

# seed_ws <dir> — a workspace carrying stale generated keys, a live-plugin key,
# a pathless-plugin key, a user key, and non-env top-level keys.
seed_ws() {
  mkdir -p "$1/.claude"
  cat > "$1/.claude/settings.local.json" <<'JSON'
{
  "env": {
    "COGNI_VISUAL_ROOT": "/gone/cogni-visual",
    "COGNI_VISUAL_PLUGIN": "/gone/cogni-visual/plugin",
    "PLUGIN_LEGACY_ROOT": "/gone/legacy",
    "PLUGIN_LEGACY_PLUGIN": "/gone/legacy/plugin",
    "COGNI_TRENDS_ROOT": "/stale/cogni-trends",
    "COGNI_KNOWLEDGE_PLUGIN": "/kept/knowledge/plugin",
    "COGNI_WORKSPACE_PLUGIN": "/kept/workspace/plugin",
    "MY_OWN_VAR": "keep-me-exactly"
  },
  "permissions": { "allow": ["Bash"] },
  "hooks": { "marker": 1 },
  "outputStyle": "custom"
}
JSON
}

PLUGINS='[{"name":"cogni-trends","path":"/p/cogni-trends"},{"name":"cogni-knowledge"}]'

# assert_py <label> <workspace-dir> <python expr over `env`, `doc`, True to pass>
assert_py() {
  local label="$1" ws="$2" expr="$3" out
  out=$(WS="$ws" EXPR="$expr" python3 - <<'PY' 2>/dev/null
import json, os, sys
doc = json.load(open(os.path.join(os.environ["WS"], ".claude", "settings.local.json")))
env = doc.get("env", {})
sys.stdout.write("1" if eval(os.environ["EXPR"]) else "0")
PY
) || out=""
  if [ "$out" = "1" ]; then pass "$label"; else fail "$label"; fi
}

# ---------------------------------------------------------------- main run
WS="$TMPROOT/main"
seed_ws "$WS"
STDOUT_MAIN="$TMPROOT/main.out"
if bash "$GEN" --target "$WS" --plugins "$PLUGINS" --update > "$STDOUT_MAIN" 2>/dev/null; then
  pass "L1 baseline update run succeeded"
else
  fail "L1 baseline update run succeeded"
fi

assert_py "P1 retired plugin ROOT key pruned" "$WS" \
  '"COGNI_VISUAL_ROOT" not in env'
assert_py "P2 retired plugin PLUGIN twin pruned" "$WS" \
  '"COGNI_VISUAL_PLUGIN" not in env'
assert_py "P3 non-cogni PLUGIN_ namespace pair pruned" "$WS" \
  '"PLUGIN_LEGACY_ROOT" not in env and "PLUGIN_LEGACY_PLUGIN" not in env'
assert_py "P4 user key outside the namespace preserved with its value" "$WS" \
  'env.get("MY_OWN_VAR") == "keep-me-exactly"'
assert_py "P5 live plugin ROOT key refreshed to the computed path" "$WS" \
  'env.get("COGNI_TRENDS_ROOT", "").endswith("/cogni-trends") and not env.get("COGNI_TRENDS_ROOT", "").startswith("/stale")'
assert_py "P7 non-env top-level keys survive unchanged" "$WS" \
  'doc.get("permissions") == {"allow": ["Bash"]} and doc.get("hooks") == {"marker": 1} and doc.get("outputStyle") == "custom"'
assert_py "Q4 installed-but-pathless plugin keeps its PLUGIN key" "$WS" \
  'env.get("COGNI_KNOWLEDGE_PLUGIN") == "/kept/knowledge/plugin"'

# P8 — .workspace-env.sh is regenerated from env, so it inherits the prune.
if [ -f "$WS/.workspace-env.sh" ] \
   && ! grep -q 'COGNI_VISUAL_ROOT' "$WS/.workspace-env.sh" \
   && grep -q 'MY_OWN_VAR' "$WS/.workspace-env.sh"; then
  pass "P8 regenerated shell exports drop the pruned key and keep the user key"
else
  fail "P8 regenerated shell exports drop the pruned key and keep the user key"
fi

# P9 — the reported count must equal what was actually written.
if COUNT_OUT="$STDOUT_MAIN" WSDIR="$WS" python3 - <<'PY' >/dev/null 2>&1
import json, os, sys
reported = json.load(open(os.environ["COUNT_OUT"]))["data"]["env_vars_count"]
actual = len(json.load(open(os.path.join(os.environ["WSDIR"], ".claude", "settings.local.json")))["env"])
sys.exit(0 if reported == actual else 1)
PY
then pass "P9 reported env_vars_count equals the written env size"
else fail "P9 reported env_vars_count equals the written env size"
fi

# ------------------------------------------------- P6 self-collision case
# An update run whose plugin list omits cogni-workspace must still keep the
# three keys the script sets unconditionally. COGNI_WORKSPACE_ROOT wears the
# generated shape, so a shape-only rule would delete the workspace's own root
# pointer here.
WS6="$TMPROOT/collide"
seed_ws "$WS6"
bash "$GEN" --target "$WS6" --plugins '[{"name":"cogni-trends","path":"/p/cogni-trends"}]' --update >/dev/null 2>&1
assert_py "P6 unconditional workspace keys survive a run omitting cogni-workspace" "$WS6" \
  'all(k in env for k in ("PROJECT_AGENTS_OPS_ROOT", "COGNI_WORKSPACE_ROOT", "COGNI_WORKSPACE_PYTHON_VENV"))'

# ------------------------------------------- Q6 workspace _PLUGIN survives
# COGNI_WORKSPACE_PLUGIN is not assigned unconditionally the way
# COGNI_WORKSPACE_ROOT is - it is written only when the plugin entry carries a
# path - so an --update omitting cogni-workspace would prune it under a
# stem-only rule while its sibling ROOT key survived. A vertical plugin's
# overlay reads this key to reach the canonical user-facing output register, so
# the prune degrades that register in a workspace where cogni-workspace is
# still installed. The main run's plugin list omits cogni-workspace, so this
# asserts against it directly.
assert_py "Q6 the workspace _PLUGIN key survives a run omitting cogni-workspace" "$WS" \
  'env.get("COGNI_WORKSPACE_PLUGIN") == "/kept/workspace/plugin"'

# ------------------------------------------------------------ Q1 init mode
# Without --update the prune must be unreachable: the document is replaced, so
# no prior key survives at all.
WS1="$TMPROOT/init"
seed_ws "$WS1"
bash "$GEN" --target "$WS1" --plugins "$PLUGINS" >/dev/null 2>&1
assert_py "Q1 init mode replaces the document, so no prior key survives" "$WS1" \
  '"MY_OWN_VAR" not in env and "COGNI_VISUAL_ROOT" not in env'

# ------------------------------------------------- Q2 malformed prior file
# Assert BY SHAPE only — exit status and stream emptiness. The diagnostic comes
# from python3, whose wording is localized, so grepping it would pass vacuously
# on a non-English host.
WS2="$TMPROOT/malformed"
mkdir -p "$WS2/.claude"
printf '%s' '{ this is not json' > "$WS2/.claude/settings.local.json"
Q2_OUT="$TMPROOT/q2.out"; Q2_ERR="$TMPROOT/q2.err"
if bash "$GEN" --target "$WS2" --plugins "$PLUGINS" --update > "$Q2_OUT" 2> "$Q2_ERR"; then
  q2_rc=0
else
  q2_rc=1
fi
if [ "$q2_rc" -ne 0 ] && [ -s "$Q2_ERR" ] && ! grep -q 'success' "$Q2_OUT"; then
  pass "Q2 malformed prior settings aborts non-zero with no success envelope"
else
  fail "Q2 malformed prior settings aborts non-zero with no success envelope"
fi

# ------------------------------------------- Q3 installed_plugins overwrite
# Already correct on the base tree — locked here against regression.
if WSDIR="$WS" python3 - <<'PY' >/dev/null 2>&1
import json, os, sys
cfg = json.load(open(os.path.join(os.environ["WSDIR"], ".workspace-config.json")))
sys.exit(0 if sorted(cfg["installed_plugins"]) == ["cogni-knowledge", "cogni-trends"] else 1)
PY
then pass "Q3 installed_plugins equals the current plugin set exactly"
else fail "Q3 installed_plugins equals the current plugin set exactly"
fi

# ----------------------------------------------------------- Q5 idempotency
# A second consecutive --update must leave the env object identical. Only env
# is compared: .workspace-config.json's updated_at legitimately changes.
ENV_BEFORE="$TMPROOT/env-before.json"; ENV_AFTER="$TMPROOT/env-after.json"
WSDIR="$WS" OUT="$ENV_BEFORE" python3 - <<'PY' 2>/dev/null
import json, os
env = json.load(open(os.path.join(os.environ["WSDIR"], ".claude", "settings.local.json")))["env"]
json.dump(env, open(os.environ["OUT"], "w"), sort_keys=True)
PY
bash "$GEN" --target "$WS" --plugins "$PLUGINS" --update >/dev/null 2>&1
WSDIR="$WS" OUT="$ENV_AFTER" python3 - <<'PY' 2>/dev/null
import json, os
env = json.load(open(os.path.join(os.environ["WSDIR"], ".claude", "settings.local.json")))["env"]
json.dump(env, open(os.environ["OUT"], "w"), sort_keys=True)
PY
if cmp -s "$ENV_BEFORE" "$ENV_AFTER"; then
  pass "Q5 a second consecutive update leaves the env object identical"
else
  fail "Q5 a second consecutive update leaves the env object identical"
fi

echo
if [ "$failures" -eq 0 ]; then
  echo "All generate-settings prune tests passed."
  exit 0
else
  echo "$failures test(s) failed."
  exit 1
fi
