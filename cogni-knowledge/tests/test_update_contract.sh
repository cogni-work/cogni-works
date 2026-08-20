#!/usr/bin/env bash
# test_update_contract.sh — grep-based contract assertions for the standalone
# single-page curation surface: the knowledge-update skill.
#
# Per tests/README.md §"Contract tests": for pure LLM skills, regression
# coverage is SKILL.md content invariants. These checks catch the most likely
# failure mode — a path, flag, or step silently disappearing from the contract.
# They do NOT assert LLM behaviour.
#
# Coverage:
#   - knowledge-update: pure-LLM single-page curation (standalone analog of
#     cogni-wiki:wiki-update), resolved against the bound wiki via the binding;
#     Edit-driven (never Write) so unchanged bytes are preserved; enforces
#     diff-before-write + per-claim citation discipline + the foundation guard;
#     runs the related-sweep; handles the retire/retype reasons; reads the
#     binding via knowledge-binding.py; does NOT dispatch cogni-wiki:wiki-update
#     (clean break).
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- knowledge-update SKILL.md -------------------------------------------
SRC="$PLUGIN_ROOT/skills/knowledge-update/SKILL.md"
if [ ! -f "$SRC" ]; then
  red "FAIL: update-00-skills-knowledge-update-skill skills/knowledge-update/SKILL.md not found"
  exit 1
fi

# Domain-prefixed generic name (the repo convention: 'update' must carry the
# plugin's 'knowledge-' prefix) — the exact-name assert proves it.
assert_grep 'name: knowledge-update' "$SRC" "update-01-frontmatter-name-domain-prefixed knowledge-update: frontmatter name (domain-prefixed)"

# Edit + Write tools are required for the diff-before-write curation path.
assert_grep 'allowed-tools:.*Edit' "$SRC" "update-02-edit-allowed-tools-diff knowledge-update: Edit in allowed-tools (diff-before-write, preserve bytes)"
assert_grep 'allowed-tools:.*Write' "$SRC" "update-03-write-allowed-tools knowledge-update: Write in allowed-tools"

# Binding + wiki-root resolution (vs cogni-wiki:wiki-update's cwd-walk).
assert_grep 'knowledge-binding.py read' "$SRC" "update-04-reads-binding-knowledge-py knowledge-update: reads the binding via knowledge-binding.py"

# Core curation discipline.
assert_grep 'diff-before-write' "$SRC" "update-05-documents-diff-before-write knowledge-update: documents the diff-before-write discipline"
assert_grep 'Edit. tool' "$SRC" "update-06-uses-edit-tool-not knowledge-update: uses the Edit tool (not Write) to preserve unchanged bytes"
assert_grep 'itation' "$SRC" "update-07-states-citation-discipline knowledge-update: states the citation discipline"
assert_grep '\-\-reason' "$SRC" "update-08-exposes-reason-parameter knowledge-update: exposes the --reason parameter"
assert_grep 'foundation: true' "$SRC" "update-09-documents-foundation-guard knowledge-update: documents the foundation guard"
assert_grep 'related.sweep' "$SRC" "update-10-documents-related-sweep knowledge-update: documents the related-sweep"

# Clean break: the boundary is documented AND there is no concrete dispatch.
assert_grep 'does not dispatch .cogni-wiki:wiki-update' "$SRC" "update-11-documents-no-dispatch-native knowledge-update: documents the no-dispatch (native curation) boundary"
assert_not_grep 'Skill("cogni-wiki:wiki-update' "$SRC" "update-12-knowledge-update-does-not-dispatch-cogni-wiki-clean-break knowledge-update: does NOT dispatch cogni-wiki:wiki-update (clean break)"
assert_not_grep 'Skill: cogni-wiki:wiki-update' "$SRC" "update-13-knowledge-update-does-not-dispatch-cogni-wiki-clean-break-prose knowledge-update: does NOT dispatch cogni-wiki:wiki-update (clean break, prose form)"

if [ "$errors" -eq 0 ]; then
  green "PASS: update-14-knowledge-update-contract knowledge-update contract"
else
  red "FAIL: update-14-knowledge-update-contract knowledge-update contract ($errors assertion(s))"
fi
exit "$errors"
