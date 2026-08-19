#!/usr/bin/env bash
# test_distill_contract.sh — grep-based contract assertions for the Phase 4.5
# distillation surface (#336): the knowledge-distill skill + the concept-distiller
# agent. Script behaviour (concept-store.py) is covered by test_concept_store.sh;
# the lifted primitives + claim-dedup by test_knowledge_lib.sh.
#
# Per tests/README.md §"Contract tests": for pure-LLM skills/agents, regression
# coverage is SKILL.md / agent-md content invariants — catches a path/flag/step
# silently disappearing. Does NOT assert LLM behaviour.
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$(dirname "$0")/fixtures/test_helpers.sh"
errors=0

# --- knowledge-distill SKILL.md ----------------------------------------------
SKILL="$PLUGIN_ROOT/skills/knowledge-distill/SKILL.md"
if [ ! -f "$SKILL" ]; then
  red "FAIL: distill-00-skills-knowledge-distill-skill skills/knowledge-distill/SKILL.md not found"
  exit 1
fi
# The verbatim python3 -c bundle-builder subprocesses (Steps 1/2/4.5/6.6a/6.7a)
# were offloaded to a reference file for progressive disclosure. Per-string
# assertions targeting that subprocess code grep $SKILLREF; assertions on the
# imperative body still grep $SKILL.
SKILLREF="$PLUGIN_ROOT/references/distill-bundle-builders.md"
if [ ! -f "$SKILLREF" ]; then
  red "FAIL: distill-01-references-distill-bundle-builders references/distill-bundle-builders.md not found"
  exit 1
fi
assert_grep 'name: knowledge-distill' "$SKILL" "distill-02-knowledge-distill-frontmatter-name knowledge-distill: frontmatter name"
assert_grep 'Phase 4.5' "$SKILL" "distill-03-announces-phase-4-5 knowledge-distill: announces Phase 4.5"
assert_grep 'ingest .* distill .* compose' "$SKILL" "distill-04-placed-between-ingest-compose knowledge-distill: placed between ingest and compose"
assert_grep 'fail-soft' "$SKILL" "distill-05-fail-soft-posture-optional knowledge-distill: fail-soft posture (optional, never blocks compose)"
assert_grep 'ingest-manifest.json' "$SKILL" "distill-06-reads-ingest-manifest-json knowledge-distill: reads ingest-manifest.json"
assert_grep 'parse_pre_extracted_claims' "$SKILL" "distill-07-builds-claim-bundle-source knowledge-distill: builds claim bundle from source pages"
assert_grep 'Task(concept-distiller' "$SKILL" "distill-08-dispatches-concept-distiller-task knowledge-distill: dispatches concept-distiller via Task"
assert_grep 'concept-store.py merge' "$SKILL" "distill-09-knowledge-distill-calls-concept-store-py-merge knowledge-distill: calls concept-store.py merge"
assert_grep 'wiki-scripts-dir' "$SKILL" "distill-10-threads-wiki-scripts-dir knowledge-distill: threads --wiki-scripts-dir (for _wiki_lock import)"
assert_grep 'resolve_wiki_scripts' "$SKILL" "distill-11-resolves-cogni-wiki-scripts knowledge-distill: resolves cogni-wiki scripts (shared helper)"
assert_grep 'backlink_audit.py' "$SKILL" "distill-12-forms-edges-backlink-audit knowledge-distill: forms edges via backlink_audit.py --apply-plan"
assert_grep 'apply-plan' "$SKILL" "distill-13-curated-backlink-apply-plan knowledge-distill: curated backlink apply-plan (LLM-curated targets)"
assert_grep 'wiki_index_update.py' "$SKILL" "distill-14-files-pages-concepts-entities knowledge-distill: files pages under Concepts/Entities"
assert_grep 'max-summary 240' "$SKILL" "distill-15-max-summary-240-backstop knowledge-distill: --max-summary 240 backstop (#324 posture)"
assert_grep 'sanitize_summary' "$SKILL" "distill-16-sanitizes-summary-before-index knowledge-distill: sanitizes the summary before the index update (#387)"
assert_grep 'config_bump.py' "$SKILL" "distill-17-entries-count-lockstep-bump knowledge-distill: entries_count lockstep bump"
assert_grep 'action == "inserted"' "$SKILL" "distill-18-counts-only-inserted-rows knowledge-distill: counts only inserted rows (n_new lockstep, #302 posture)"
assert_grep 'distill | project=' "$SKILL" "distill-19-appends-distill-log-line knowledge-distill: appends a distill log line"
assert_grep 'claims_deduped_total' "$SKILL" "distill-20-surfaces-claim-dedup-ratio knowledge-distill: surfaces the claim-dedup ratio"
assert_grep 'bundle_hash' "$SKILL" "distill-21-resume-no-op-bundle knowledge-distill: resume no-op via bundle hash"
assert_grep 'Concepts' "$SKILL" "distill-22-concepts-index-category knowledge-distill: Concepts index category"
assert_grep 'Entities' "$SKILL" "distill-23-entities-index-category knowledge-distill: Entities index category"
# #340 observable title→slug tripwire — Step-9 warning surfaces near_existing_*.
assert_grep 'near_existing_total' "$SKILL" "distill-24-reads-near-existing-total knowledge-distill: reads near_existing_total from merge output (#340)"
assert_grep 'near_existing_slugs' "$SKILL" "distill-25-reads-near-existing-slugs knowledge-distill: reads near_existing_slugs[] from merge output (#340)"
assert_grep 'concepts created near an existing slug' "$SKILL" "distill-26-step-9-surfaces-title knowledge-distill: Step 9 surfaces the title→slug tripwire warning"
assert_grep 'observability' "$SKILL" "distill-27-documents-tripwire-pure-observability knowledge-distill: documents the tripwire as pure observability (no auto-merge)"
# Must NOT run the FULL conformance gate (finalize Step 10.5 owns --fix=all + health.py once).
assert_not_grep 'health.py asserts' "$SKILL" "distill-28-does-not-run-full knowledge-distill: does NOT run the full conformance gate itself"
# DOES run the bounded reverse_link_missing de-orphan gate inline so a standalone distill leaves a clean base.
assert_grep 'fix=reverse_link_missing' "$SKILL" "distill-29-runs-bounded-reverse-link knowledge-distill: runs the bounded reverse_link_missing de-orphan gate inline (Step 7.2)"
assert_grep 'Task' "$SKILL" "distill-30-task-allowed-tools knowledge-distill: Task in allowed-tools"
# #341 Step 6.7 — re-narrate the ## Summary of updated pages from merged claims.
assert_grep 'Task(concept-summary-narrator' "$SKILL" "distill-31-dispatches-concept-summary-narrator knowledge-distill: dispatches concept-summary-narrator via Task (#341)"
assert_grep 'concept-store.py renarrate' "$SKILL" "distill-32-knowledge-distill-calls-concept-store-py-renarrate knowledge-distill: calls concept-store.py renarrate (#341)"
assert_grep 'no-renarrate' "$SKILL" "distill-33-documents-no-renarrate-opt knowledge-distill: documents the --no-renarrate opt-out (#341)"
assert_grep 'updated_slugs' "$SKILL" "distill-34-step-6-7-keys-updated knowledge-distill: Step 6.7 keys on updated_slugs (created pages keep distiller summary)"
assert_grep 'RENARRATE_BUNDLE_PATH' "$SKILL" "distill-35-threads-renarrate-bundle-path knowledge-distill: threads the renarrate bundle path"
assert_grep 'summaries re-narrated\|Summaries re-narrated' "$SKILL" "distill-36-step-9-surfaces-re knowledge-distill: Step 9 surfaces the re-narration tally"
assert_grep 'extract_machine_block' "$SKILLREF" "distill-37-step-6-7-reads-summary knowledge-distill: Step 6.7 reads the SUMMARY block via the shared helper"
# #345 Step 6.6 — cross-lingual DE↔EN claim merge (default-on, fail-soft, auto-skip).
assert_grep 'Task(cross-lingual-claim-merger' "$SKILL" "distill-38-dispatches-cross-lingual-claim knowledge-distill: dispatches cross-lingual-claim-merger via Task (#345)"
assert_grep 'concept-store.py xlingual-candidates' "$SKILL" "distill-39-generates-candidates-xlingual knowledge-distill: generates candidates via xlingual-candidates (#345)"
assert_grep 'concept-store.py crossmerge' "$SKILL" "distill-40-applies-unions-concept-store knowledge-distill: applies unions via concept-store.py crossmerge (#345)"
assert_grep 'no-crosslingual' "$SKILL" "distill-41-documents-no-crosslingual-opt knowledge-distill: documents the --no-crosslingual opt-out (#345)"
assert_grep 'CANDIDATES_PATH' "$SKILL" "distill-42-threads-candidates-bundle-path knowledge-distill: threads the candidates bundle path (#345)"
assert_grep 'auto-skip' "$SKILL" "distill-43-step-6-6-auto-skips knowledge-distill: Step 6.6 auto-skips on single-language bases (#345)"
assert_grep 'merged_slugs' "$SKILL" "distill-44-folds-crossmerge-merged-slugs knowledge-distill: folds crossmerge merged_slugs into updated_slugs (#345)"
# #432 answer-claim synthesis for question nodes (default-on, fail-soft); the two distillers
# now ride one Step 5 fan-out wave and the answer-merge serializes at Step 6.1 (#957).
assert_grep 'Step 6.1' "$SKILL" "distill-45-documents-step-6-1-answer knowledge-distill: documents the Step 6.1 answer-claim merge (serialized after concept merge) (#432, #957)"
assert_grep 'Fan-out wave' "$SKILL" "distill-46-step-5-dispatches-concept knowledge-distill: Step 5 dispatches concept-distiller + answer-distiller in one fan-out wave (#957)"
assert_grep 'Task(answer-distiller' "$SKILL" "distill-47-dispatches-answer-distiller-task knowledge-distill: dispatches answer-distiller via Task (#432)"
assert_grep 'question-store.py answer-merge' "$SKILL" "distill-48-calls-question-store-py knowledge-distill: calls question-store.py answer-merge (#432)"
assert_grep 'ANSWER_BUNDLE_PATH' "$SKILL" "distill-49-threads-answer-bundle-path knowledge-distill: threads the answer bundle path (#432)"
assert_grep 'sources_answering' "$SKILL" "distill-50-step-4-5-bundle-reads knowledge-distill: Step 4.5 bundle reads sources_answering (#432)"
assert_grep 'split_frontmatter' "$SKILL" "distill-51-step-4-5-reuses-split knowledge-distill: Step 4.5 reuses split_frontmatter for the inline list (#432)"
assert_grep 'Question nodes answered' "$SKILL" "distill-52-step-9-surfaces-answered knowledge-distill: Step 9 surfaces the answered-questions tally (#432)"

# --- answer-distiller agent (#432) -------------------------------------------
ADIST="$PLUGIN_ROOT/agents/answer-distiller.md"
if [ ! -f "$ADIST" ]; then
  red "FAIL: distill-53-agents-answer-distiller-md agents/answer-distiller.md not found"
  exit 1
fi
assert_grep 'name: answer-distiller' "$ADIST" "distill-54-answer-distiller-frontmatter-name answer-distiller: frontmatter name"
assert_grep 'model: sonnet' "$ADIST" "distill-55-answer-distiller-model-sonnet answer-distiller: model sonnet"
assert_grep 'ANSWER_BUNDLE_PATH' "$ADIST" "distill-56-reads-question-claim-bundle answer-distiller: reads the per-question claim bundle"
assert_grep 'RECORDS_OUTPUT_PATH' "$ADIST" "distill-57-answer-distiller-writes-raw-text-records answer-distiller: writes raw-text records"
assert_grep 'question:' "$ADIST" "distill-58-emits-question-blocks answer-distiller: emits - question: blocks"
assert_grep 'answer_claim:' "$ADIST" "distill-59-repeatable-answer-claim-lines answer-distiller: repeatable answer_claim: lines"
assert_grep 'raw text' "$ADIST" "distill-60-answer-distiller-writes-raw-text-never answer-distiller: writes raw text, never JSON/YAML (#325 discipline)"
assert_grep 'question-store.py' "$ADIST" "distill-61-defers-dedup-serialization-question answer-distiller: defers dedup/serialization to question-store.py"
assert_grep 'tools: \["Read", "Write"\]' "$ADIST" "distill-62-answer-distiller-tools-read answer-distiller: tools Read + Write only"

# --- concept-distiller agent -------------------------------------------------
AGENT="$PLUGIN_ROOT/agents/concept-distiller.md"
if [ ! -f "$AGENT" ]; then
  red "FAIL: distill-63-agents-concept-distiller-md agents/concept-distiller.md not found"
  exit 1
fi
assert_grep 'name: concept-distiller' "$AGENT" "distill-64-concept-distiller-frontmatter-name concept-distiller: frontmatter name"
assert_grep 'model: sonnet' "$AGENT" "distill-65-concept-distiller-model-sonnet concept-distiller: model sonnet"
assert_grep 'CLAIM_BUNDLE_PATH' "$AGENT" "distill-66-reads-claim-bundle concept-distiller: reads the claim bundle"
assert_grep 'SLUG_INDEX_PATH' "$AGENT" "distill-67-reads-existing-slug-index concept-distiller: reads the existing-slug index"
assert_grep 'RECORDS_OUTPUT_PATH' "$AGENT" "distill-68-concept-distiller-writes-raw-text-records concept-distiller: writes raw-text records"
assert_grep 'concept' "$AGENT" "distill-69-proposes-concept-pages concept-distiller: proposes concept pages"
assert_grep 'entity' "$AGENT" "distill-70-proposes-entity-pages concept-distiller: proposes entity pages"
assert_grep 'person' "$AGENT" "distill-71-proposes-person-pages concept-distiller: proposes person pages"
assert_grep 'conservative' "$AGENT" "distill-72-conservative-concept-vs-entity concept-distiller: conservative concept-vs-entity selection rule"
# #600 — instance-free disambiguator + abstract-domain-concept directive so a
# named instance is never mis-typed as a concept and the concept layer is not
# starved on an entity-heavy corpus.
assert_grep 'instance-free' "$AGENT" "distill-73-concept-titles-must-instance concept-distiller: concept titles must be instance-free (#600)"
assert_grep 'never .concept\|never a .concept\|not a concept\|NOT. a concept' "$AGENT" "distill-74-named-instance-never-concept concept-distiller: a named instance is never a concept (#600)"
assert_grep 'entity-heavy\|domain concept' "$AGENT" "distill-75-surface-abstract-domain-concepts concept-distiller: surface abstract domain concepts even on an entity-heavy corpus (#600)"
# Pure-proposal invariants — the #325 + claim-dedup discipline.
assert_grep 'never compute slugs\|never computes slugs\|do not compute slugs\|does NOT compute slugs\|never compute' "$AGENT" "distill-76-never-computes-slugs concept-distiller: never computes slugs"
assert_grep 'raw text' "$AGENT" "distill-77-concept-distiller-writes-raw-text-never concept-distiller: writes raw text, never JSON/YAML (#325)"
assert_grep 'concept-store.py' "$AGENT" "distill-78-defers-dedup-serialization-concept concept-distiller: defers dedup/serialization to concept-store.py"
# Tools: Read + Write only (no Bash, no Task, no WebFetch/WebSearch) — the exact
# tools-list line is the guard (the prose legitimately says "does NOT WebSearch").
assert_grep 'tools: \["Read", "Write"\]' "$AGENT" "distill-79-concept-distiller-tools-read concept-distiller: tools Read + Write only"

# --- concept-summary-narrator agent (#341) -----------------------------------
NARRATOR="$PLUGIN_ROOT/agents/concept-summary-narrator.md"
if [ ! -f "$NARRATOR" ]; then
  red "FAIL: distill-80-agents-concept-summary-narrator agents/concept-summary-narrator.md not found"
  exit 1
fi
assert_grep 'name: concept-summary-narrator' "$NARRATOR" "distill-81-concept-summary-narrator-frontmatter concept-summary-narrator: frontmatter name"
assert_grep 'model: haiku' "$NARRATOR" "distill-82-concept-summary-narrator-model concept-summary-narrator: model haiku"
assert_grep 'RENARRATE_BUNDLE_PATH' "$NARRATOR" "distill-83-reads-slug-bundle concept-summary-narrator: reads the per-slug bundle"
assert_grep 'RECORDS_OUTPUT_PATH' "$NARRATOR" "distill-84-concept-summary-narrator-writes-raw-text-records concept-summary-narrator: writes raw-text records"
assert_grep 'OUTPUT_LANGUAGE' "$NARRATOR" "distill-85-re-narrates-output-language concept-summary-narrator: re-narrates in OUTPUT_LANGUAGE"
assert_grep '<<<SUMMARY' "$NARRATOR" "distill-86-sentinel-fenced-records-idiom concept-summary-narrator: sentinel-fenced records idiom"
assert_grep 'raw text' "$NARRATOR" "distill-87-concept-summary-narrator-writes-raw-text-never-json concept-summary-narrator: writes raw text, never JSON/YAML (#325)"
# Summary-only discipline + scope guard (a contradiction pass stays out of scope).
assert_grep 'only the summary\|only the SUMMARY\|touch .*only\|Summary-only\|summary-only' "$NARRATOR" "distill-88-touches-only-summary-block concept-summary-narrator: touches only the summary block"
assert_grep 'contradiction pass' "$NARRATOR" "distill-89-names-contradiction-pass-out concept-summary-narrator: names a contradiction pass as out-of-scope"
assert_grep 'tools: \["Read", "Write"\]' "$NARRATOR" "distill-90-concept-summary-narrator-tools concept-summary-narrator: tools Read + Write only"

# --- cross-lingual-claim-merger agent (#345) ---------------------------------
MERGER="$PLUGIN_ROOT/agents/cross-lingual-claim-merger.md"
if [ ! -f "$MERGER" ]; then
  red "FAIL: distill-91-agents-cross-lingual-claim agents/cross-lingual-claim-merger.md not found"
  exit 1
fi
assert_grep 'name: cross-lingual-claim-merger' "$MERGER" "distill-92-cross-lingual-claim-merger-frontmatter-name cross-lingual-claim-merger: frontmatter name"
assert_grep 'model: haiku' "$MERGER" "distill-93-cross-lingual-claim-merger-model-haiku cross-lingual-claim-merger: model haiku"
assert_grep 'CANDIDATES_PATH' "$MERGER" "distill-94-reads-candidate-pairs-bundle cross-lingual-claim-merger: reads the candidate pairs bundle"
assert_grep 'RECORDS_OUTPUT_PATH' "$MERGER" "distill-95-cross-lingual-claim-merger-writes-raw-text-records cross-lingual-claim-merger: writes raw-text records"
assert_grep 'merge: ' "$MERGER" "distill-96-documents-merge-record-idiom cross-lingual-claim-merger: documents the merge: record idiom"
assert_grep 'raw text' "$MERGER" "distill-97-cross-lingual-claim-merger-writes-raw-text-never cross-lingual-claim-merger: writes raw text, never JSON/YAML (#325)"
# Scope-bound + fail-safe discipline — the load-bearing invariants of approach (a).
assert_grep 'only CONFIRM\|only confirm\|may only CONFIRM\|may only confirm' "$MERGER" "distill-98-may-only-confirm-script cross-lingual-claim-merger: may only confirm script-flagged pairs (never invents a merge)"
assert_grep 'crossmerge' "$MERGER" "distill-99-defers-union-concept-store cross-lingual-claim-merger: defers the union to concept-store.py crossmerge"
assert_grep 'same.*language\|two languages\|cross-lingual' "$MERGER" "distill-100-judges-same-fact-two cross-lingual-claim-merger: judges same-fact-two-languages only"
assert_grep 'tools: \["Read", "Write"\]' "$MERGER" "distill-101-cross-lingual-claim-merger-tools-read cross-lingual-claim-merger: tools Read + Write only"

if [ "$errors" -eq 0 ]; then
  green ""
  green "knowledge-distill + concept-distiller + concept-summary-narrator + cross-lingual-claim-merger contract: all pass."
  exit 0
else
  red "knowledge-distill + concept-distiller + concept-summary-narrator + cross-lingual-claim-merger contract: $errors failure(s)."
  exit 1
fi
