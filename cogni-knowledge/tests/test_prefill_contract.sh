#!/usr/bin/env bash
# test_prefill_contract.sh — grep-based contract assertions for the standalone
# foundation-seeding surface: the knowledge-prefill skill.
#
# Per tests/README.md §"Contract tests": for pure LLM skills, regression
# coverage is SKILL.md content invariants. These checks catch the most likely
# failure mode — a path, flag, or step silently disappearing from the contract.
# They do NOT assert LLM behaviour.
#
# Coverage:
#   - knowledge-prefill: runs the vendored prefill_foundations.py (resolved
#     vendored-first via resolve_wiki_scripts) against the bound wiki to seed
#     foundation: true concept pages; exposes --filter / --list / --dry-run;
#     reads the binding via knowledge-binding.py; documents the
#     --skip-prefill-prompt opt-in rationale; does NOT dispatch
#     cogni-wiki:wiki-prefill (vendored-native clean break).
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- knowledge-prefill SKILL.md ------------------------------------------
SRC="$PLUGIN_ROOT/skills/knowledge-prefill/SKILL.md"
if [ ! -f "$SRC" ]; then
  red "FAIL: prefill-00-skills-knowledge-prefill-skill skills/knowledge-prefill/SKILL.md not found"
  exit 1
fi

# Domain-prefixed generic name (the repo convention: 'prefill' must carry the
# plugin's 'knowledge-' prefix) — the exact-name assert proves it.
assert_grep 'name: knowledge-prefill' "$SRC" "prefill-01-frontmatter-name-domain-prefixed knowledge-prefill: frontmatter name (domain-prefixed)"

# Binding + wiki-root resolution.
assert_grep 'knowledge-binding.py read' "$SRC" "prefill-02-reads-binding-knowledge-py knowledge-prefill: reads the binding via knowledge-binding.py"

# Vendored-first engine resolution.
assert_grep 'resolve_wiki_scripts' "$SRC" "prefill-03-resolves-wiki-prefill-script knowledge-prefill: resolves the wiki-prefill script dir via the resolve_wiki_scripts probe"
assert_grep 'scripts/vendor/cogni-wiki/skills/wiki-prefill/scripts' "$SRC" "prefill-04-names-vendored-first-wiki knowledge-prefill: names the vendored-first wiki-prefill path"
# cogni-wiki is retired, so there is no external engine source. The vendored
# path assertion above is the positive half; this is the anti-regression half.
assert_not_grep 'probe_plugin cogni-wiki' "$SRC" "prefill-05-no-external-cogni-wiki-probe knowledge-prefill: carries no external cogni-wiki fallback probe (vendored-only)"

# Invokes the vendored prefill engine and exposes its CLI surface.
assert_grep 'prefill_foundations.py' "$SRC" "prefill-06-names-vendored-prefill-foundations knowledge-prefill: names the vendored prefill_foundations.py engine"
assert_grep 'WIKI_PREFILL_SCRIPTS' "$SRC" "prefill-07-wires-resolve-wiki-scripts knowledge-prefill: wires resolve_wiki_scripts to the prefill_foundations.py invocation"
assert_grep '\-\-filter' "$SRC" "prefill-08-exposes-filter-set knowledge-prefill: exposes the --filter set"
assert_grep '\-\-list' "$SRC" "prefill-09-exposes-list-mode knowledge-prefill: exposes the --list mode"
assert_grep '\-\-dry-run' "$SRC" "prefill-10-exposes-dry-run-mode knowledge-prefill: exposes the --dry-run mode"

# Documents the deliberate opt-in posture (knowledge-setup skips foundations).
assert_grep 'skip.*prefill' "$SRC" "prefill-11-documents-skip-prefill-prompt knowledge-prefill: documents the --skip-prefill-prompt opt-in rationale"

# Clean break: the boundary is documented AND there is no concrete dispatch.
assert_grep 'does not dispatch .cogni-wiki:wiki-prefill' "$SRC" "prefill-12-documents-no-dispatch-vendored knowledge-prefill: documents the no-dispatch (vendored-native) boundary"
assert_not_grep 'Skill("cogni-wiki:wiki-prefill' "$SRC" "prefill-13-knowledge-prefill-does-not-dispatch-cogni-wiki-clean-break knowledge-prefill: does NOT dispatch cogni-wiki:wiki-prefill (clean break)"
assert_not_grep 'Skill: cogni-wiki:wiki-prefill' "$SRC" "prefill-14-knowledge-prefill-does-not-dispatch-cogni-wiki-clean-break-prose knowledge-prefill: does NOT dispatch cogni-wiki:wiki-prefill (clean break, prose form)"

if [ "$errors" -eq 0 ]; then
  green "PASS: prefill-15-knowledge-prefill-contract knowledge-prefill contract"
else
  red "FAIL: prefill-15-knowledge-prefill-contract knowledge-prefill contract ($errors assertion(s))"
fi
exit "$errors"
