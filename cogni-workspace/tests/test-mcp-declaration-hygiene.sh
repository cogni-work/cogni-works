#!/usr/bin/env bash
# MCP declaration hygiene guard: no plugin ships an MCP declaration, and the
# invariants that keep the relocated server's tool names stable still hold.
#
# Why this exists. MCP server declarations used to live in per-plugin
# `.mcp.json` files. That shape has two failure modes, and neither one reports
# itself:
#   - A checked-in declaration asserts machine state the repo cannot guarantee.
#     A plugin-level stdio server is spawned at session start, not lazily on
#     first tool call, so on a machine that never installed it the server fails
#     visibly under /mcp — for every user of the plugin, whether or not they
#     ever render a diagram.
#   - Two plugins declaring the SAME server name is worse than redundant. The
#     client disambiguates the collision by plugin-qualifying one side's tool
#     names (mcp__plugin_<plugin>_<server>__*), which silently dead-matches any
#     `mcp__<server>__.*` PreToolUse matcher. A dead hook matcher throws no
#     error and fails no build; the only evidence is the absence of whatever the
#     hook would have done.
# Declarations therefore moved into `cogni-workspace:install-mcp`, which writes
# them to the user's own config on demand. This suite is what keeps that true —
# nothing else in CI inspects `.mcp.json` presence, the registry's server key,
# or a hook matcher string.
#
# Contract under test:
#   - no cogni-*/.mcp.json exists at any plugin root — the only depth a
#     client loads a plugin-level declaration from, so a file nested deeper
#     is out of scope by glob depth rather than by exclusion
#   - mcp-git-registry.json still maps mcp_excalidraw to the desktop key
#     "excalidraw" — MCP tool names derive from that key, so renaming it breaks
#     every mcp__excalidraw__* tool and both hook matchers at once, silently
#   - both cogni-visual and cogni-portfolio still carry the PreToolUse matcher
#     mcp__excalidraw__.* — correct only while no plugin re-declares the server
#   - the two copies of concept-mcp-server-map.md stay byte-identical
#   - each glob-driven arm proved it had something to look at (liveness floor)
#
# The liveness floor is the load-bearing half of A1. "Zero .mcp.json files
# found" is the pass condition AND what a mis-resolved REPO_ROOT produces, so
# without L1 proving the plugin glob matched real directories, A1 would pass
# hardest exactly when the suite is most broken.
#
# Deliberately NOT asserted: which servers the registry contains, or that any
# server is installed. This is a declaration-shape guard, not an install check.
#
# Case-label shape follows test-wiki-tree-parity.sh: "PASS: <id> <label>" /
# "FAIL: <id> <label>", ids letter-prefixed and never bare numerals, and never a
# colon after the id. The cogni-service mutation harness classifies a case GREEN
# only on ^[[:space:]]*(ok|PASS):[[:space:]]+<case> and RED on the matching FAIL:
# form, matching the id as a whole token — so "A1: no plugin ..." would report
# case_not_found instead of a verdict, and the pass() and fail() call sites for
# one case must carry byte-identical label text. Do not restyle these labels and
# do not colour them.
#
# Mutation recipe (verifies A2 is a real assertion, not a vacuous one):
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/references/mcp-git-registry.json \
#     --expr 's/"desktop_config_key": "excalidraw"/"desktop_config_key": "sketchpad"/' \
#     --test 'bash cogni-workspace/tests/test-mcp-declaration-hygiene.sh' \
#     --case A2
# Verdict: guard_verified. The search literal occurs once, and the replacement
# ("sketchpad") does not contain it, so the mutant cannot re-satisfy the pattern
# and stay green. Use the cogni-service harness, NOT the different
# scripts/mutation-check.sh that cogni-consult and cogni-portfolio each ship.
#
# A2 is the case to drive, not A1. Mutating A1's own comparison is vacuous: on a
# clean tree `declarations` is 0, so weakening `-eq 0` to `-ge 0` leaves the case
# green and the harness correctly reports vacuous_guard. A1's negative evidence
# comes from M1 below, which mutates the TREE (adds a .mcp.json) rather than the
# assertion — the only mutation that can distinguish "nothing is declared" from
# "nothing was looked at".

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# MCP_HYGIENE_ROOT is the mutant-root override used by case M1 below. It is
# honoured only when already set, so a normal run always resolves the real tree.
REPO_ROOT="${MCP_HYGIENE_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

REGISTRY_REL="cogni-workspace/references/mcp-git-registry.json"
WIKI_PAGE_REL="wiki/wiki/pages/concept-mcp-server-map.md"
BUNDLED_PAGE_REL="cogni-workspace/wiki/wiki/pages/concept-mcp-server-map.md"
MATCHER='mcp__excalidraw__.*'

PASSED=0
FAILED=0
pass() { printf '%s\n' "PASS: $1"; PASSED=$((PASSED + 1)); }
fail() { printf '%s\n' "FAIL: $1"; FAILED=$((FAILED + 1)); }

# A missing root is a broken suite, never a clean one.
if [ ! -f "$REPO_ROOT/.claude-plugin/marketplace.json" ]; then
  fail "L0 repo root resolves to a tree with .claude-plugin/marketplace.json"
  printf '%s\n' "  resolved REPO_ROOT=$REPO_ROOT"
  printf '%s\n' "$PASSED passed, $FAILED failed"
  exit 1
fi
pass "L0 repo root resolves to a tree with .claude-plugin/marketplace.json"

# --- liveness floor -------------------------------------------------------
# Each glob-driven arm below proves its scan surface exists before its absence
# check is allowed to mean anything.

plugin_dirs=0
for dir in "$REPO_ROOT"/cogni-*; do
  [ -d "$dir" ] && plugin_dirs=$((plugin_dirs + 1))
done
if [ "$plugin_dirs" -ge 2 ]; then
  pass "L1 plugin directory glob is live"
else
  fail "L1 plugin directory glob is live"
  printf '%s\n' "  matched $plugin_dirs cogni-* directories under $REPO_ROOT, expected at least 2"
fi

# One parse feeds both L2 and A2 — two copies of this heredoc drifted apart in
# review (different guards, different redirections) before they were merged.
registry_read="$(python3 -c '
import json, sys
try:
    reg = json.load(open(sys.argv[1]))
except Exception:
    print(-1); print(""); sys.exit(0)
servers = reg.get("servers", {})
print(len(servers))
print(servers.get("mcp_excalidraw", {}).get("desktop_config_key", ""))
' "$REPO_ROOT/$REGISTRY_REL" 2>/dev/null)"
registry_servers="$(printf '%s\n' "$registry_read" | sed -n '1p')"
desktop_key="$(printf '%s\n' "$registry_read" | sed -n '2p')"
[ -n "$registry_servers" ] || registry_servers=-1

if [ "$registry_servers" -ge 1 ]; then
  pass "L2 registry parsed at least one server"
else
  fail "L2 registry parsed at least one server"
  printf '%s\n' "  $REGISTRY_REL yielded $registry_servers servers"
fi

matcher_files="$(grep -rl -- "$MATCHER" "$REPO_ROOT"/cogni-*/hooks/hooks.json 2>/dev/null | wc -l | tr -d ' ')"
if [ "$matcher_files" -eq 2 ]; then
  pass "L3 exactly two hooks.json carry the excalidraw matcher"
else
  fail "L3 exactly two hooks.json carry the excalidraw matcher"
  printf '%s\n' "  found $matcher_files, expected 2 — the scan surface moved"
fi

# --- A1: no plugin ships an MCP declaration -------------------------------

declarations=0
for f in "$REPO_ROOT"/cogni-*/.mcp.json; do
  [ -f "$f" ] && declarations=$((declarations + 1))
done
if [ "$declarations" -eq 0 ]; then
  pass "A1 no plugin ships a .mcp.json"
else
  fail "A1 no plugin ships a .mcp.json"
  for f in "$REPO_ROOT"/cogni-*/.mcp.json; do
    [ -f "$f" ] && printf '%s\n' "  found ${f#$REPO_ROOT/}"
  done
  printf '%s\n' "  declarations move into cogni-workspace:install-mcp, written to user config on demand"
fi

# --- A2: the registry key MCP tool names derive from ----------------------

if [ "$desktop_key" = "excalidraw" ]; then
  pass "A2 registry maps mcp_excalidraw to desktop key excalidraw"
else
  fail "A2 registry maps mcp_excalidraw to desktop key excalidraw"
  printf '%s\n' "  got '$desktop_key' — tool names derive from this key, so a rename breaks every mcp__excalidraw__* tool"
fi

# --- A3: both PreToolUse matchers survive ---------------------------------

missing_matcher=""
for plugin in cogni-visual cogni-portfolio; do
  hooks="$REPO_ROOT/$plugin/hooks/hooks.json"
  if [ ! -f "$hooks" ] || ! grep -q -- "$MATCHER" "$hooks" 2>/dev/null; then
    missing_matcher="$missing_matcher $plugin"
  fi
done
if [ -z "$missing_matcher" ]; then
  pass "A3 both excalidraw hook matchers survive"
else
  fail "A3 both excalidraw hook matchers survive"
  printf '%s\n' "  missing or unmatched in:$missing_matcher"
  printf '%s\n' "  the matcher is correct only while no plugin re-declares the server"
fi

# --- D1: the two wiki copies stay byte-identical --------------------------
# No other suite covers this page: test-wiki-tree-parity.sh deliberately does
# not assert tree equality, and test-layering-claim-reconciled.sh pins a
# four-page allowlist this page is not on.

if [ -f "$REPO_ROOT/$WIKI_PAGE_REL" ] && [ -f "$REPO_ROOT/$BUNDLED_PAGE_REL" ]; then
  if cmp -s "$REPO_ROOT/$WIKI_PAGE_REL" "$REPO_ROOT/$BUNDLED_PAGE_REL"; then
    pass "D1 concept-mcp-server-map.md byte-identical across wiki trees"
  else
    fail "D1 concept-mcp-server-map.md byte-identical across wiki trees"
    printf '%s\n' "  $WIKI_PAGE_REL and $BUNDLED_PAGE_REL diverged"
  fi
else
  fail "D1 concept-mcp-server-map.md byte-identical across wiki trees"
  printf '%s\n' "  one or both copies are missing"
fi

# --- M1: executed negative case for A1 ------------------------------------
# Proves A1 can actually go red. Runs only on a real invocation, never inside
# the mutant child, so it cannot recurse.

if [ -z "${MCP_HYGIENE_ROOT:-}" ]; then
  mutant="$(mktemp -d)"
  trap 'rm -rf "$mutant"' EXIT

  # One list drives both the mkdir and the cp, so a fixture added to the mutant
  # cannot arrive without its parent directory.
  for rel in ".claude-plugin/marketplace.json" \
             "$REGISTRY_REL" \
             "cogni-visual/hooks/hooks.json" \
             "cogni-portfolio/hooks/hooks.json" \
             "$WIKI_PAGE_REL" \
             "$BUNDLED_PAGE_REL"; do
    mkdir -p "$mutant/$(dirname "$rel")"
    cp "$REPO_ROOT/$rel" "$mutant/$rel"
  done
  # The mutation: reintroduce exactly what this suite forbids.
  printf '%s\n' '{"mcpServers": {"excalidraw": {"command": "bash", "args": ["-c", "start.sh"]}}}' \
    > "$mutant/cogni-visual/.mcp.json"

  mutant_out="$(MCP_HYGIENE_ROOT="$mutant" bash "$SCRIPT_DIR/$(basename "$0")" 2>&1)"
  mutant_rc=$?

  if [ "$mutant_rc" -ne 0 ] && printf '%s\n' "$mutant_out" | grep -q '^FAIL: A1 no plugin ships a \.mcp\.json$'; then
    pass "M1 mutant .mcp.json turns A1 red"
  else
    fail "M1 mutant .mcp.json turns A1 red"
    printf '%s\n' "  mutant run exit=$mutant_rc; expected a 'FAIL: A1 ...' line and a non-zero exit"
    printf '%s\n' "$mutant_out" | sed 's/^/    /'
  fi
fi

printf '%s\n' "$PASSED passed, $FAILED failed"
[ "$FAILED" -eq 0 ] || exit 1
