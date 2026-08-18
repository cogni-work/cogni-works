#!/usr/bin/env bash
# Suite for scripts/check-mcp-tool-grant.py — the repo-scope MCP agent-grant guard.
#
# What is being pinned, and why each case earns its place:
#
#   * All THREE `tools:` frontmatter forms parse as granting. This is the
#     load-bearing one. 15 agents declare tools as a YAML block list, and 6 of
#     the 7 agents that carry a real body call site are among them — so a
#     reader that only looks at the `tools:` LINE reports those 6 as false
#     offenders and the guard is red on an otherwise-clean tree. B1 fails
#     first if that regresses.
#   * Disclaiming prose never fires. Agents elsewhere in the tree say "no
#     Excalidraw MCP" while granting something else entirely; P1 pins the
#     shape and P2 pins it against a byte copy of a real disclaiming agent, so
#     the case cannot pass by agreeing with a fixture nobody ships.
#   * The namespace token class admits hyphens. `mcp__claude-in-chrome__navigate`
#     is real, and an [A-Za-z0-9_]-only class matches none of it — the guard
#     would go blind to two agents and a whole namespace with every case still
#     green. H1 is the case that reds on that.
#   * `desktop_config_key` drives key -> namespace mapping as data. R2 uses a
#     registry key that shares no prefix with its namespace, so an
#     implementation that strips `mcp_` resolves nothing and R2 reds.
#   * Zero discovery is a failure. Z1/Z2 keep an absence result meaning
#     "looked and found nothing wrong" rather than "looked at nothing".
#
# Liveness floors are INEQUALITIES pinned strictly below the values the real
# tree carries today, so a new agent never turns the suite red, while a
# collapsed scan population still does.
#
# Every assertion below is on an exit status, on a numeric shape, or on JSON
# this repo's own guard emits. None reads the wording of a foreign tool's
# diagnostic: bash and the GNU tools gettext-localize their messages, so a grep
# for an English fragment passes vacuously on a non-English host.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-mcp-tool-grant.py"
REGISTRY_REL="cogni-workspace/references/mcp-git-registry.json"

failures=0
red()   { printf '%s\n' "$1"; }
green() { printf '%s\n' "$1"; }

OUT="$(mktemp)"
REPO_OUT="$(mktemp)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK" "$OUT" "$REPO_OUT"' EXIT

CODE=0
run_guard() {  # run_guard <root>
  set +e
  python3 "$GUARD" --root "$1" > "$OUT" 2>/dev/null
  CODE=$?
  set -e
}

check_eq() {  # check_eq <label> <expected> <actual>
  if [ "$2" = "$3" ]; then
    green "PASS: $1"
  else
    red "FAIL: $1 (expected $2, got $3)"
    failures=$((failures + 1))
  fi
}

# py_assert <label> <python body over d/s/v> [json-file, default $OUT]
#
# stderr is deliberately NOT suppressed: every assertion below carries a
# diagnostic operand whose only job is to print when it trips, and swallowing
# it would leave a red case in CI showing a label and nothing else.
py_assert() {
  set +e
  python3 - "${3:-$OUT}" <<PYEOF
import json, sys
d = json.load(open(sys.argv[1]))
s = d.get("data", {}).get("summary", {})
v = d.get("data", {}).get("violations", [])
o = d.get("data", {}).get("observations", [])
$2
PYEOF
  rc=$?
  set -e
  if [ "$rc" -eq 0 ]; then
    green "PASS: $1"
  else
    red "FAIL: $1"
    failures=$((failures + 1))
  fi
}

# --- fixture helpers -------------------------------------------------------

# write_registry <root> <key> <namespace> <required_by-json-array>
write_registry() {
  mkdir -p "$1/$(dirname "$REGISTRY_REL")"
  cat > "$1/$REGISTRY_REL" <<REGEOF
{
  "version": "1.0.0",
  "servers": {
    "$2": {
      "name": "$2",
      "desktop_config_key": "$3",
      "required_by": $4
    }
  }
}
REGEOF
}

# write_agent <root> <plugin> <name> <tools-block> <body>
write_agent() {
  mkdir -p "$1/$2/agents"
  {
    printf '%s\n' "---"
    printf '%s\n' "name: $3"
    printf '%s\n' "description: fixture agent"
    printf '%s\n' "$4"
    printf '%s\n' "---"
    printf '%s\n' ""
    printf '%s\n' "$5"
  } > "$1/$2/agents/$3.md"
}

# new_root <name> -> echoes path. Ships the standard one-server demo registry,
# so a case only calls write_registry when it needs a DIFFERENT vocabulary —
# which keeps the baseline from drifting between cases meant to share it.
new_root() {
  local r="$WORK/$1"
  mkdir -p "$r"
  write_registry "$r" "mcp_demo" "demo" '["plug"]'
  printf '%s' "$r"
}

# --- A: the real tree ------------------------------------------------------

# Scanned once and cached: the fixtures below all live under $WORK, so the real
# tree cannot change mid-suite. Later real-tree assertions read $REPO_OUT
# explicitly rather than depending on which run_guard happened to run last.
run_guard "$REPO_ROOT"
cp "$OUT" "$REPO_OUT"
check_eq "A1 the repository as it stands is clean" "0" "$CODE"
py_assert "A2 the clean result is not vacuous" "
assert s['agents_discovered'] > 0, s
assert s['total'] == 0, v
"

R="$(new_root offender)"
write_agent "$R" "plug" "ungranted" 'tools: [Read, Write]' \
  'Call mcp__demo__do_thing to render.'
run_guard "$R"
check_eq "A3 an ungranted body call site is reported" "1" "$CODE"
py_assert "A4 the violation names file, arm and namespace" "
assert s['by_arm'].get('body_call_site_ungranted') == 1, s
f = v[0]
assert f['file'].endswith('ungranted.md'), f
assert f['arm'] == 'body_call_site_ungranted', f
assert f['namespace'] == 'demo', f
"

# --- B: all three tools: forms ---------------------------------------------

R="$(new_root form_block)"
write_agent "$R" "plug" "blocklist" 'tools:
  - Read
  - mcp__demo__do_thing' \
  'Call mcp__demo__do_thing to render.'
run_guard "$R"
check_eq "B1 a YAML block-list grant is parsed as granting" "0" "$CODE"
py_assert "B1a the block form was actually counted" "
assert s['tools_form_counts']['block'] == 1, s
"

R="$(new_root form_bracket)"
write_agent "$R" "plug" "bracketed" 'tools: ["Read", "mcp__demo__do_thing"]' \
  'Call mcp__demo__do_thing to render.'
run_guard "$R"
check_eq "B2 a bracketed-array grant is parsed as granting" "0" "$CODE"
py_assert "B2a the bracketed form was actually counted" "
assert s['tools_form_counts']['bracketed'] == 1, s
"

R="$(new_root form_comma)"
write_agent "$R" "plug" "commalist" 'tools: Read, Write, mcp__demo__do_thing' \
  'Call mcp__demo__do_thing to render.'
run_guard "$R"
check_eq "B3 a bare comma-list grant is parsed as granting" "0" "$CODE"
py_assert "B3a the comma form was actually counted" "
assert s['tools_form_counts']['comma'] == 1, s
"

# A block list written flush-left under `tools:` is valid YAML and the host
# accepts it. If the item anchor demanded indentation the grant would read as
# absent, the agent would drop out of the required_by arm, and the body call
# site below would be reported as a FALSE offender — the guard's own
# invisible-absence class, one level down. Nothing in the tree is written this
# way today, which is exactly why it needs a fixture.
R="$(new_root form_block_flush)"
write_agent "$R" "plug" "flushlist" 'tools:
- Read
- mcp__demo__do_thing' \
  'Call mcp__demo__do_thing to render.'
run_guard "$R"
check_eq "B5 a flush-left block-list grant is parsed as granting" "0" "$CODE"
py_assert "B5a the flush-left grant was seen, not silently dropped" "
assert s['grant_tokens'] >= 1, s
assert s['tools_form_counts']['block'] == 1, s
"

# The bracketed form may wrap across lines. No agent in the tree does this
# today, so without this fixture the parser's continuation loop never executes
# and could rot unnoticed.
R="$(new_root form_bracket_wrapped)"
write_agent "$R" "plug" "wrapped" 'tools: ["Read",
  "mcp__demo__do_thing"]' \
  'Call mcp__demo__do_thing to render.'
run_guard "$R"
check_eq "B6 a bracketed grant wrapped across lines is parsed as granting" "0" "$CODE"
py_assert "B6a the wrapped grant was seen, not truncated at the first line" "
assert s['grant_tokens'] >= 1, s
assert s['tools_form_counts']['bracketed'] == 1, s
"

# Floors are >= 1, not the counts the tree happens to carry today: pinning the
# stylistic distribution of frontmatter would red the suite the moment anyone
# normalized agents toward one form. That every form PARSES is pinned
# deterministically by B1/B2/B3 against fixtures; this only asserts the real
# tree still exercises each branch at all.
py_assert "B4 every tools: form is still exercised by the real tree" "
c = s['tools_form_counts']
assert c['bracketed'] >= 1, c
assert c['comma'] >= 1, c
assert c['block'] >= 1, c
" "$REPO_OUT"

# --- H: hyphenated namespaces ----------------------------------------------

R="$(new_root hyphen_ok)"
write_registry "$R" "mcp_chrome" "claude-in-chrome" '["plug"]'
write_agent "$R" "plug" "hyphenated" \
  'tools: ["Read", "mcp__claude-in-chrome__navigate"]' \
  'Drive the page with mcp__claude-in-chrome__navigate.'
run_guard "$R"
check_eq "H1 a hyphenated namespace round-trips grant and call site" "0" "$CODE"

R="$(new_root hyphen_bad)"
write_registry "$R" "mcp_chrome" "claude-in-chrome" '["plug"]'
write_agent "$R" "plug" "hyphenated" 'tools: ["Read"]' \
  'Drive the page with mcp__claude-in-chrome__navigate.'
run_guard "$R"
check_eq "H2 a hyphenated namespace call with no grant is reported" "1" "$CODE"
py_assert "H2a the hyphenated namespace survives into the finding" "
assert v[0]['namespace'] == 'claude-in-chrome', v[0]
"

# --- P: disclaiming prose ---------------------------------------------------

R="$(new_root disclaim)"
write_registry "$R" "mcp_excalidraw" "excalidraw" '["plug"]'
write_agent "$R" "plug" "svgonly" 'tools:
  - Read
  - Write' \
  'You craft the SVG directly using clean geometric primitives — no Excalidraw
MCP, no hand-drawn wobble, no external tools. Use it without Excalidraw MCP.'
run_guard "$R"
check_eq "P1 disclaiming prose never fires" "0" "$CODE"

# A byte copy of a real disclaiming agent, so the case cannot pass by agreeing
# with a fixture nobody ships. It disclaims the REGISTERED namespace excalidraw
# in body prose while granting a different namespace via the block-list form,
# so it discriminates on the prose arm and the block-list arm at once.
R="$(new_root disclaim_real)"
write_registry "$R" "mcp_excalidraw" "excalidraw" '["cogni-visual"]'
mkdir -p "$R/cogni-visual/agents"
cp "$REPO_ROOT/cogni-visual/agents/concept-diagram-svg.md" \
   "$R/cogni-visual/agents/concept-diagram-svg.md"
run_guard "$R"
check_eq "P2 a real disclaiming agent contributes no violation" "0" "$CODE"
py_assert "P2a the real disclaimer was actually scanned" "
assert s['agents_discovered'] == 1, s
assert s['tools_form_counts']['block'] == 1, s
"

# --- R: the registry required_by arm ---------------------------------------

R="$(new_root reqby_missing)"
write_registry "$R" "mcp_demo" "demo" '["someone-else"]'
write_agent "$R" "plug" "granter" 'tools: ["mcp__demo__do_thing"]' \
  'Body text with no call site.'
run_guard "$R"
check_eq "R1 a granting plugin absent from required_by is reported" "1" "$CODE"
py_assert "R1a the finding is on the required_by arm" "
assert s['by_arm'].get('required_by_missing_plugin') == 1, s
"

# The registry key shares no prefix with its namespace, so an implementation
# that derived the namespace by stripping 'mcp_' would resolve nothing, treat
# the grant as unregistered, and exit 0 — this case reds on that.
R="$(new_root key_as_data)"
write_registry "$R" "zz_totally_unrelated" "demo" '["someone-else"]'
write_agent "$R" "plug" "granter" 'tools: ["mcp__demo__do_thing"]' \
  'Body text with no call site.'
run_guard "$R"
check_eq "R2 desktop_config_key drives the mapping, not the key spelling" "1" "$CODE"
py_assert "R2a the grant resolved to the registry entry" "
assert s['skipped_unregistered'] == 0, s
assert s['by_arm'].get('required_by_missing_plugin') == 1, s
"

R="$(new_root unregistered)"
write_agent "$R" "plug" "other" 'tools: ["mcp__somethingelse__go"]' \
  'Body text with no call site.'
run_guard "$R"
check_eq "R3 a grant outside the registry is skipped, not reported" "0" "$CODE"
py_assert "R3a the skip was counted rather than silently dropped" "
assert s['skipped_unregistered'] == 1, s
"

R="$(new_root no_tools)"
mkdir -p "$R/plug/agents"
{
  printf '%s\n' "---"
  printf '%s\n' "name: notools"
  printf '%s\n' "---"
  printf '%s\n' ""
  printf '%s\n' "Call mcp__demo__do_thing freely."
} > "$R/plug/agents/notools.md"
run_guard "$R"
check_eq "R4 an agent with no tools: key inherits unrestricted tools" "0" "$CODE"
py_assert "R4a the inheritance skip was counted" "
assert s['skipped_no_tools'] == 1, s
"

py_assert "R5 the real tree's required_by arm is clean over a live vocabulary" "
assert s['by_arm'].get('required_by_missing_plugin', 0) == 0, s
assert s['registered_namespaces'] >= 2, s
" "$REPO_OUT"

# The observations channel is non-failing by design (the arm asserts every
# GRANTING plugin is listed, not the converse), which is precisely why it needs
# a case: an output surface nothing asserts on can rot to garbage while every
# other case stays green.
R="$(new_root listed_no_grant)"
write_registry "$R" "mcp_demo" "demo" '["plug", "ghost"]'
write_agent "$R" "plug" "granter" 'tools: ["mcp__demo__do_thing"]' \
  'Body text with no call site.'
run_guard "$R"
check_eq "R6 a plugin listed in required_by that grants nothing is not a violation" "0" "$CODE"
py_assert "R6a it is reported as a non-failing observation instead" "
assert s['total'] == 0, v
names = [(x['plugin'], x['namespace'], x['kind']) for x in o]
assert ('ghost', 'demo', 'listed_without_grant') in names, names
assert ('plug', 'demo', 'listed_without_grant') not in names, names
"

# --- Z: zero discovery is a failure ----------------------------------------

R="$(new_root empty)"
run_guard "$R"
check_eq "Z1 a tree with no agents is an error, not a clean zero" "2" "$CODE"
py_assert "Z1a the error is reported, not swallowed" "
assert d['success'] is False, d
assert d['error'], d
"

R="$(new_root no_registry)"
rm -f "$R/$REGISTRY_REL"   # new_root ships one; this case is about its absence
write_agent "$R" "plug" "any" 'tools: ["Read"]' 'Body text.'
run_guard "$R"
check_eq "Z2 an unreadable registry is an error, not a skipped arm" "2" "$CODE"

# --- L: liveness floors on the real tree -----------------------------------

py_assert "L1 the scan population is still reaching agent files" "
assert s['agents_discovered'] >= 100, s['agents_discovered']
assert sum(s['tools_form_counts'].values()) >= 90, s['tools_form_counts']
" "$REPO_OUT"
py_assert "L2 grants and body call sites are still being extracted" "
assert s['grant_tokens'] >= 100, s['grant_tokens']
assert s['body_call_sites'] >= 15, s['body_call_sites']
" "$REPO_OUT"

printf '%s\n' "$failures failed"
[ "$failures" -eq 0 ] || exit 1
