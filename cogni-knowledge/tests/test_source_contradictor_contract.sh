#!/usr/bin/env bash
# test_source_contradictor_contract.sh — Phase 4 (source-contradictor agent)
# content-invariant contract assertions.
#
# Mirrors tests/test_contradictor_contract.sh's shape: a single agent.md grep
# block that catches a Phase 1 step or invariant silently disappearing. Never
# asserts LLM scoring behavior — that is the live-verification surface.
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- source-contradictor agent file --------------------------------------
SC="$PLUGIN_ROOT/agents/source-contradictor.md"
if [ ! -f "$SC" ]; then
  red "FAIL: source-contradictor-00-agents-source-contradictor-md agents/source-contradictor.md not found"
  exit 1
fi

# Frontmatter shape — name + model + tool list mirror wiki-contradictor.md exactly.
assert_grep 'name: source-contradictor' "$SC" "source-contradictor-01-frontmatter-name source-contradictor: frontmatter name"
assert_grep 'model: sonnet' "$SC" "source-contradictor-02-frontmatter-model-sonnet source-contradictor: frontmatter model: sonnet"
assert_grep 'tools: \["Read", "Write", "Glob", "Grep"\]' "$SC" "source-contradictor-03-tools-read-write-glob source-contradictor: tools = Read/Write/Glob/Grep (no Task, no Bash)"

# Single-pass + no shell — guards against drift into a re-fetching or
# orchestrating shape that breaks the zero-network premise.
SC_TOOLS_LINE=$(grep '^tools:' "$SC" || true)
if echo "$SC_TOOLS_LINE" | grep -q 'Task'; then
  red "FAIL: source-contradictor-04-tools-list-omits-task source-contradictor: tools list must NOT include Task (single-pass)"
  errors=$((errors + 1))
else
  green "PASS: source-contradictor-04-tools-list-omits-task source-contradictor: tools list omits Task (single-pass)"
fi
if echo "$SC_TOOLS_LINE" | grep -q 'Bash'; then
  red "FAIL: source-contradictor-05-tools-list-omits-bash source-contradictor: tools list must NOT include Bash (no shell)"
  errors=$((errors + 1))
else
  green "PASS: source-contradictor-05-tools-list-omits-bash source-contradictor: tools list omits Bash (no shell)"
fi

# kind vocabulary — only contradiction + unknown.
assert_grep '`contradiction`' "$SC" "source-contradictor-06-documents-kind-contradiction source-contradictor: documents kind=contradiction"
assert_grep '`unknown`' "$SC" "source-contradictor-07-documents-kind-unknown source-contradictor: documents kind=unknown"
# Severity vocabulary — three levels, all referenced.
assert_grep '`high`' "$SC" "source-contradictor-08-documents-severity-high source-contradictor: documents severity=high"
assert_grep '`medium`' "$SC" "source-contradictor-09-documents-severity-medium source-contradictor: documents severity=medium"
assert_grep '`low`' "$SC" "source-contradictor-10-documents-severity-low source-contradictor: documents severity=low"

# Schema literal — the contract version-pin.
assert_grep '"schema_version": "0.1.0"' "$SC" "source-contradictor-11-documents-schema-version-0-1-0 source-contradictor: documents schema_version 0.1.0 literal"

# Pure-observability posture — the agent's defining contract.
assert_grep 'Pure observability\|pure observability' "$SC" "source-contradictor-12-documents-pure-observability-posture source-contradictor: documents the pure-observability posture"

# Claim-vs-claim surface: resolves all three claim families across the six dirs.
assert_grep 'pre_extracted_claims' "$SC" "source-contradictor-13-parses-pre-extracted-claims source-contradictor: parses pre_extracted_claims (NEW source claims)"
assert_grep 'distilled_claims' "$SC" "source-contradictor-14-parses-distilled-claims-peer source-contradictor: parses distilled_claims (distilled peer)"
assert_grep 'answer_claims' "$SC" "source-contradictor-15-parses-answer-claims-question source-contradictor: parses answer_claims (question-node peer)"
assert_grep 'concepts,entities\|concepts/\|entities/' "$SC" "source-contradictor-16-resolves-two-distilled-dirs source-contradictor: resolves the two distilled dirs"
assert_grep 'wiki/questions/' "$SC" "source-contradictor-17-resolves-wiki-questions-probe source-contradictor: resolves wiki/questions/ in the probe"
assert_grep 'wiki/sources/' "$SC" "source-contradictor-18-resolves-wiki-sources-probe source-contradictor: resolves wiki/sources/ in the probe"

# New-vs-new AND new-vs-peer comparison must both be documented.
assert_grep 'NEW-vs-NEW\|new-vs-new\|other NEW' "$SC" "source-contradictor-19-documents-new-vs-comparison source-contradictor: documents new-vs-new comparison"
assert_grep 'PEER\|peer' "$SC" "source-contradictor-20-documents-peer-comparison source-contradictor: documents peer comparison"

# No sentence-splitting (the structural difference from wiki-contradictor).
assert_grep 'No sentence-splitting\|no sentence-splitting\|not split claims into sentences\|split claims into sentences' "$SC" "source-contradictor-21-states-no-sentence-splitting source-contradictor: states no sentence-splitting (claim-vs-claim)"

# Zero-network invariant — verbatim, so a drift toward re-fetch is loud.
assert_grep 'never fetch\|It never fetches' "$SC" "source-contradictor-22-explicitly-states-never-fetches source-contradictor: explicitly states it never fetches (zero-network invariant)"

# "What this agent does NOT do" block — at least 8 NOT invariants.
assert_grep '## What this agent does NOT do' "$SC" "source-contradictor-23-source-contradictor-what-agent-does-not-do-section source-contradictor: has 'What this agent does NOT do' section"
NOT_COUNT=$(awk '/^## What this agent does NOT do$/{f=1; next} /^## /{f=0} f && /^- Does NOT/' "$SC" | wc -l)
if [ "$NOT_COUNT" -ge 8 ]; then
  green "PASS: source-contradictor-24-source-contradictor-what-agent-does-not-do-section-invariants-8 source-contradictor: 'What this agent does NOT do' section has $NOT_COUNT invariants (≥ 8 required)"
else
  red "FAIL: source-contradictor-24-source-contradictor-what-agent-does-not-do-section-invariants-8 source-contradictor: 'What this agent does NOT do' section has only $NOT_COUNT invariants (≥ 8 required)"
  errors=$((errors + 1))
fi

# Conservative-bias discipline — steer toward 'low' on doubt.
assert_grep 'conservative\|Conservative' "$SC" "source-contradictor-25-documents-conservative-scoring-bias source-contradictor: documents conservative scoring bias"
# Cap on unknown.
assert_grep 'Cap.*unknown\|cap.*unknown' "$SC" "source-contradictor-26-caps-unknown-3-group source-contradictor: caps unknown at 3 per group"

# Severity-gated counts payload.
assert_grep '"high"' "$SC" "source-contradictor-27-documents-high-counts-payload source-contradictor: documents high in counts payload"
assert_grep '"medium"' "$SC" "source-contradictor-28-documents-medium-counts-payload source-contradictor: documents medium in counts payload"

# Failure envelopes — both must exist so the orchestrator's fail-soft path
# has something to read.
assert_grep 'group_unreadable' "$SC" "source-contradictor-29-documents-group-unreadable-failure source-contradictor: documents group_unreadable failure envelope"
assert_grep 'write_failed' "$SC" "source-contradictor-30-documents-write-failed-failure source-contradictor: documents write_failed failure envelope"

# Pure-observability: never gates ingest / never rolls back.
assert_grep 'never gates ingest\|never gate ingest\|gate ingest\|roll back\|rolls back\|rolling back' "$SC" "source-contradictor-31-documents-never-gates-ingest source-contradictor: documents it never gates ingest / never rolls back"

# Defence-in-depth: no cogni-wiki / cogni-research / cogni-workspace claim SKILL dispatch.
assert_not_grep 'Skill("cogni-research:' "$SC" "source-contradictor-32-no-skill-cogni-research source-contradictor: no Skill('cogni-research:') dispatch (clean break)"
assert_not_grep 'Skill("cogni-workspace:claim' "$SC" "source-contradictor-33-no-skill-cogni-workspace source-contradictor: no Skill('cogni-workspace:claim') dispatch (clean break)"
assert_not_grep 'Skill("cogni-wiki:' "$SC" "source-contradictor-34-no-skill-cogni-wiki source-contradictor: no Skill('cogni-wiki:') dispatch (clean break)"
# Positive control, per tests/README.md: the absence assertions above also pass on a
# gutted file, so pair them with the mechanism that replaced the dispatch. The colon
# form is deliberate — the maintainer comment block's mention is the non-colon
# "::pre_extracted_claims;", so this literal matches body prose only.
assert_grep 'pre_extracted_claims:' "$SC" "source-contradictor-35-claims-engine-replacement-present source-contradictor: claims-engine replacement present — scores NEW vs PEER claims from on-disk pre_extracted_claims: frontmatter (zero-network)"

# Recency survivor annotation (the resolution{} producer contract, #874).
assert_grep 'resolution' "$SC" "source-contradictor-36-documents-resolution-annotation source-contradictor: documents the resolution annotation"
assert_grep 'survivor_claim_id' "$SC" "source-contradictor-37-documents-resolution-survivor-claim source-contradictor: documents resolution.survivor_claim_id"
assert_grep '"recency"' "$SC" "source-contradictor-38-documents-recency-strategy-literal source-contradictor: documents the recency strategy literal"
assert_grep 'rationale' "$SC" "source-contradictor-39-documents-resolution-rationale source-contradictor: documents resolution.rationale"
# Survivor = later-timestamped side; null on absent/equal timestamps.
assert_grep 'later' "$SC" "source-contradictor-40-survivor-later-timestamped-side source-contradictor: survivor is the later-timestamped side"
assert_grep 'absent or equal\|absent.*equal' "$SC" "source-contradictor-41-survivor-claim-id-null source-contradictor: survivor_claim_id null when timestamps absent or equal"
# Phase 0 now captures the recency timestamps (they must NOT be ignored anymore).
assert_grep 'recency timestamp' "$SC" "source-contradictor-42-phase-0-captures-claim source-contradictor: Phase 0 captures the per-claim recency timestamp"
# Annotation-only — never changes scoring / reconciles / modifies a page.
assert_grep 'annotation-only' "$SC" "source-contradictor-43-resolution-annotation-only source-contradictor: resolution is annotation-only"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
