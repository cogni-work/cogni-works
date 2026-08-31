#!/usr/bin/env bash
# test_health_contract.sh — grep-based contract assertions for the standalone
# read-only health surface: the knowledge-health skill.
#
# Per tests/README.md §"Contract tests": for pure LLM skills, regression
# coverage is SKILL.md content invariants. These checks catch the most likely
# failure mode — a path, flag, or step silently disappearing from the contract.
# They do NOT assert LLM behaviour.
#
# Coverage:
#   - knowledge-health: runs the vendored health.py (resolved vendored-first via
#     resolve_wiki_scripts) against the bound wiki for a read-only structural
#     verdict; reads the binding via knowledge-binding.py; does NOT dispatch
#     cogni-wiki:wiki-health (clean break — native vendored engine).
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- knowledge-health SKILL.md -------------------------------------------
SRC="$PLUGIN_ROOT/skills/knowledge-health/SKILL.md"
if [ ! -f "$SRC" ]; then
  red "FAIL: khealth-00-skills-knowledge-health-skill skills/knowledge-health/SKILL.md not found"
  exit 1
fi

# Domain-prefixed generic name (the repo convention: 'health' must carry the
# plugin's 'knowledge-' prefix) — the exact-name assert proves it.
assert_grep 'name: knowledge-health' "$SRC" "khealth-01-frontmatter-name-domain-prefixed knowledge-health: frontmatter name (domain-prefixed)"

# Read-only posture — health is a pure audit (no --fix, no wiki writes).
assert_grep 'read-only' "$SRC" "khealth-02-states-read-only-posture knowledge-health: states the read-only posture"

# Binding + wiki-root resolution.
assert_grep 'knowledge-binding.py read' "$SRC" "khealth-03-reads-binding-knowledge-py knowledge-health: reads the binding via knowledge-binding.py"

# Vendored-first engine resolution.
assert_grep 'resolve_wiki_scripts' "$SRC" "khealth-04-resolves-wiki-health-script knowledge-health: resolves the wiki-health script dir via the resolve_wiki_scripts probe"
assert_grep 'scripts/vendor/cogni-wiki/skills/wiki-health/scripts' "$SRC" "khealth-05-names-vendored-first-wiki knowledge-health: names the vendored-first wiki-health path"
# cogni-wiki is retired, so there is no external engine source. The vendored
# path assertion above is the positive half; this is the anti-regression half.
assert_not_grep 'probe_plugin cogni-wiki' "$SRC" "khealth-06-no-external-cogni-wiki-probe knowledge-health: carries no external cogni-wiki fallback probe (vendored-only)"

# Invokes the vendored health engine directly.
assert_grep 'health.py' "$SRC" "khealth-07-names-vendored-health-py knowledge-health: names the vendored health.py engine"
assert_grep 'WIKI_HEALTH_SCRIPTS' "$SRC" "khealth-08-wires-resolve-wiki-scripts knowledge-health: wires resolve_wiki_scripts to the health.py invocation"

# Clean break: the boundary is documented AND there is no concrete dispatch.
assert_grep 'does not dispatch .cogni-wiki:wiki-health' "$SRC" "khealth-09-documents-no-dispatch-vendored knowledge-health: documents the no-dispatch (vendored-native) boundary"
assert_not_grep 'Skill("cogni-wiki:wiki-health' "$SRC" "khealth-10-knowledge-health-does-not-dispatch-cogni-wiki-clean-break knowledge-health: does NOT dispatch cogni-wiki:wiki-health (clean break)"
assert_not_grep 'Skill: cogni-wiki:wiki-health' "$SRC" "khealth-11-knowledge-health-does-not-dispatch-cogni-wiki-clean-break-prose knowledge-health: does NOT dispatch cogni-wiki:wiki-health (clean break, prose form)"

if [ "$errors" -eq 0 ]; then
  green "PASS: khealth-12-knowledge-health-contract knowledge-health contract"
else
  red "FAIL: khealth-12-knowledge-health-contract knowledge-health contract ($errors assertion(s))"
fi
exit "$errors"
