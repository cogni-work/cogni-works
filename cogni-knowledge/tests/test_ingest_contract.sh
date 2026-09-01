#!/usr/bin/env bash
# test_ingest_contract.sh — grep-based contract assertions for the v0.0.20
# Phase 4 ingest surface: knowledge-ingest skill, source-ingester agent,
# claim-extractor agent. Plus the #275 (PDF) and #276 (cobrowse_unavailable)
# additions to source-fetcher.md, and the new helpers in _knowledge_lib.py.
#
# Per tests/README.md §"Contract tests": for pure LLM skills, regression
# coverage is SKILL.md / agent-md content invariants. These checks catch
# the most likely failure mode — a path, flag, or step silently disappearing
# from the contract. They do NOT assert LLM behaviour.
#
# Coverage:
#   - knowledge-ingest: reads fetch-manifest.json, dispatches source-ingester
#     via Task, calls cogni-wiki helper scripts directly (backlink_audit.py +
#     wiki_index_update.py — NOT cogni-wiki:wiki-ingest skill dispatch),
#     appends wiki/log.md ingest line, writes ingest-manifest.json schema
#     0.1.0.
#   - source-ingester: reads via fetch-cache.py fetch, dispatches
#     claim-extractor via Task, writes wiki/sources/<slug>.md with type:
#     source frontmatter + pre_extracted_claims, uses atomic_write_text,
#     does NOT WebFetch.
#   - claim-extractor: reads BODY_FILE (cached body), emits excerpt_position,
#     does NOT write files, does NOT create entities.
#   - source-curator: #275 is_pdf_response branch + #278 pdf_pages_read/
#     pdf_truncated + the Read tool — moved here from source-fetcher at
#     v0.0.29 (Option B, #292; the WebFetch body-pull now lives in Phase 4).
#   - source-fetcher: #276 cobrowse_unavailable reason (cobrowse-only after #292).
#   - _knowledge_lib.py: is_pdf_response + atomic_write_text exist.
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- knowledge-ingest SKILL.md -------------------------------------------
INGEST="$PLUGIN_ROOT/skills/knowledge-ingest/SKILL.md"
if [ ! -f "$INGEST" ]; then
  red "FAIL: ingest-contract-00-skills-knowledge-ingest-skill skills/knowledge-ingest/SKILL.md not found"
  exit 1
fi
assert_grep 'name: knowledge-ingest' "$INGEST" "ingest-contract-01-knowledge-ingest-frontmatter-name knowledge-ingest: frontmatter name"
assert_grep 'fetch-manifest.json' "$INGEST" "ingest-contract-02-reads-fetch-manifest-json knowledge-ingest: reads fetch-manifest.json"
assert_grep 'ingest-manifest.json' "$INGEST" "ingest-contract-03-writes-ingest-manifest-json knowledge-ingest: writes ingest-manifest.json"
assert_grep '"schema_version": "0.1.0"' "$INGEST" "ingest-contract-04-ingest-manifest-schema-0-1-0 knowledge-ingest: ingest-manifest schema 0.1.0"
assert_grep 'Task(source-ingester' "$INGEST" "ingest-contract-05-dispatches-source-ingester-task knowledge-ingest: dispatches source-ingester via Task"
assert_grep 'backlink_audit.py' "$INGEST" "ingest-contract-06-calls-backlink-audit-py knowledge-ingest: calls backlink_audit.py directly (clean-break)"
assert_grep 'wiki_index_update.py' "$INGEST" "ingest-contract-07-calls-wiki-index-update knowledge-ingest: calls wiki_index_update.py directly (clean-break)"
assert_grep 'wiki/log.md' "$INGEST" "ingest-contract-08-appends-wiki-log-md knowledge-ingest: appends to wiki/log.md"
assert_grep 'control-path.py" log' "$INGEST" "ingest-contract-09-resolves-log-path-control knowledge-ingest: resolves the log path via control-path.py (no hardcoded wiki/log.md write target)"
# cogni-wiki is retired: the pre-flight gates on the VENDORED engine only. The
# paired not-grep is the anti-regression half — an external probe must not return.
assert_grep 'scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts' "$INGEST" "ingest-contract-10-probes-vendored-engine knowledge-ingest: pre-flight gates on the vendored wiki-ingest engine"
assert_not_grep 'probe_plugin cogni-wiki' "$INGEST" "ingest-contract-10b-no-external-cogni-wiki-probe knowledge-ingest: carries no external cogni-wiki fallback probe (vendored-only)"
assert_grep 'Task' "$INGEST" "ingest-contract-11-task-listed-allowed-tools knowledge-ingest: Task listed in allowed-tools"
# #302 (Slice 14): Step 4 bumps entries_count by the count of NEWLY-INDEXED
# source pages via config_bump.py --delta <n_new>, gated on the index update's
# action == "inserted" (same lockstep as knowledge-finalize Step 7→8), so
# wiki-health / wiki-resume stop reporting an N-page entries_count_drift. The
# re-run no-op (Step 1.3 skips ingested URLs → n_new == 0 → no bump) must be stated.
assert_grep 'config_bump.py' "$INGEST" "ingest-contract-12-bumps-entries-count-config knowledge-ingest: bumps entries_count via config_bump.py (#302)"
assert_grep 'entries_count' "$INGEST" "ingest-contract-13-references-entries-count knowledge-ingest: references entries_count (#302)"
assert_grep 'knowledge-ingest-postprocess.py' "$INGEST" "ingest-contract-14-entries-count-bump-delegated knowledge-ingest: entries_count bump delegated to the postprocess orchestrator (config_bump --delta now lives in knowledge-ingest-postprocess.py)"
assert_grep 'n_new' "$INGEST" "ingest-contract-15-counts-newly-indexed-pages knowledge-ingest: counts newly-indexed pages in n_new (#302)"
assert_grep '"inserted"' "$INGEST" "ingest-contract-16-gates-bump-action-inserted knowledge-ingest: gates the bump on action == inserted — lockstep invariant (#302)"
assert_grep 'no-op' "$INGEST" "ingest-contract-17-states-re-run-no knowledge-ingest: states the re-run no-op (n_new == 0 → no bump) (#302)"
# Slice 16 (#308/#307): write backlinks via --apply-plan (no longer audit-only),
# and file sources under their sub-question's thematic theme_label category.
assert_grep 'apply-plan' "$INGEST" "ingest-contract-18-writes-backlinks-backlink-audit knowledge-ingest: writes backlinks via backlink_audit.py --apply-plan (#308)"
assert_grep 'targets' "$INGEST" "ingest-contract-19-curates-targets-backlink-plan knowledge-ingest: curates a targets[] backlink plan (#308)"
assert_not_grep 'audit-only' "$INGEST" "ingest-contract-20-no-audit-only-wording knowledge-ingest: no 'audit-only' wording remains (#308)"
assert_not_grep 'No \`--apply-plan\`' "$INGEST" "ingest-contract-21-no-apply-plan-deferral knowledge-ingest: no 'No --apply-plan' deferral wording remains (#308)"
assert_grep 'theme_label' "$INGEST" "ingest-contract-22-index-category-derived-sub knowledge-ingest: index category derived from the sub-question theme_label (#307)"
assert_grep 'sub_question_refs\[0\]' "$INGEST" "ingest-contract-23-joins-sub-question-refs knowledge-ingest: joins on sub_question_refs[0] to pick the theme_label (#307)"
# #593: the same resolved theme_label is also passed to source-ingester as
# THEME_LABEL so the source page's own theme_label: frontmatter stays consistent
# with the ## <theme_label> index heading its bullet files under.
assert_grep 'THEME_LABEL=' "$INGEST" "ingest-contract-24-dispatches-source-ingester-theme knowledge-ingest: dispatches source-ingester with THEME_LABEL (#593)"
# The run-level market (plan.json::market) is threaded to every source-ingester
# as MARKET so each source page carries a market: frontmatter signal for the
# perspectives overlay's Where facet.
assert_grep 'MARKET=' "$INGEST" "ingest-contract-25-dispatches-source-ingester-market knowledge-ingest: dispatches source-ingester with MARKET (Where facet)"
# #409: Step 4.5 sub-step 1 passes --binding to question-store.py (lineage-couple
# question-node accumulation), and sub-step 5 persists the returned theme_bindings[]
# into topic_lineage.covered_themes[] via knowledge-binding.py upsert-themes (the
# single binding writer). Guard the read-side flag, the writer call, and the field.
assert_grep 'question-store.py' "$INGEST" "ingest-contract-26-step-4-5-runs-question knowledge-ingest: Step 4.5 runs question-store.py emit (#407)"
assert_grep '\-\-binding' "$INGEST" "ingest-contract-27-step-4-5-passes-binding knowledge-ingest: Step 4.5 passes --binding to question-store.py for theme lineage (#409)"
assert_grep 'theme_bindings' "$INGEST" "ingest-contract-28-step-4-5-consumes-theme knowledge-ingest: Step 4.5 consumes theme_bindings[] (#409)"
assert_grep 'upsert-themes' "$INGEST" "ingest-contract-29-step-4-5-sub-5 knowledge-ingest: Step 4.5 sub-step 5 calls knowledge-binding.py upsert-themes (#409)"
assert_grep 'covered_themes' "$INGEST" "ingest-contract-30-step-4-5-persists-topic knowledge-ingest: Step 4.5 persists into topic_lineage.covered_themes[] (#409)"
# #410: Step 4.5.1 persists the emit envelope's data.questions[] to
# question-manifest.json as the phase handoff knowledge-finalize Step 4.7 reads to
# forward-link the deposited synthesis to the research-question nodes it answers.
assert_grep 'question-manifest.json' "$INGEST" "ingest-contract-31-step-4-5-1-persists-question knowledge-ingest: Step 4.5.1 persists question-manifest.json handoff (#410)"
assert_not_grep 'category "Sources"' "$INGEST" "ingest-contract-32-knowledge-ingest-no-hard-coded-category-sources-only knowledge-ingest: no hard-coded --category \"Sources\" as the only category (#307; Sources is a fallback now)"
# #411: Step 4.5.3 files each question node under its sub-question's own theme_label
# heading (the same section its answering sources occupy), replacing the additive flat
# "## Research questions" index category from #408 — so the index is anchored on the
# question nodes instead of carrying two parallel groupings of the same themes. The
# category is now derived from theme_label (keyed by sub_question_id) and NO LONGER a
# hard-coded sole --category "Research questions". "Research questions" survives only as
# (a) the legacy-no-theme_label fallback category and (b) the Step 4.5.2 source-page-body
# heading, so do NOT assert the string is wholly absent — assert it is the fallback.
assert_not_grep 'category "Research questions"' "$INGEST" "ingest-contract-33-knowledge-ingest-no-hard-coded-category-research-questions knowledge-ingest: no hard-coded --category \"Research questions\" as the sole question category (#411; theme_label-derived now)"
assert_grep 'own .theme_label. heading' "$INGEST" "ingest-contract-34-step-4-5-3-files-each knowledge-ingest: Step 4.5.3 files each question under its own theme_label heading — question-anchored grouping (#411)"
assert_grep '"Research questions"' "$INGEST" "ingest-contract-35-research-questions-kept-legacy knowledge-ingest: \"Research questions\" kept as the legacy-no-theme_label fallback category (#411)"
# #324: Step 4.2 passes the --max-summary word-boundary clamp backstop (cogni-wiki
# v0.0.47+), and the "≤180 chars" authoring contract that caused the mid-word
# artifact is gone (the summary is authored as one crisp, complete sentence).
assert_grep 'max-summary' "$INGEST" "ingest-contract-36-step-4-2-passes-max knowledge-ingest: Step 4.2 passes --max-summary clamp backstop (#324)"
assert_not_grep '180' "$INGEST" "ingest-contract-37-no-180-chars-authoring knowledge-ingest: no '≤180 chars' authoring contract remains (#324)"
# #387: Step 4.2 sanitizes the authored summary (typographic-substitute guard:
# stray U+2020 dagger / NBSP -> regular space) before the index update.
assert_grep 'sanitize_summary' "$INGEST" "ingest-contract-38-step-4-2-sanitizes-summary knowledge-ingest: Step 4.2 sanitizes the summary before the index update (#387)"
assert_grep 'sanitize_summary' "$INGEST" "ingest-contract-39-summary-sanitized-knowledge-lib knowledge-ingest: summary sanitized via _knowledge_lib.sanitize_summary before --summary (now inside the postprocess orchestrator, #387)"
# #323 (one-wave fan-out): Step 3 dispatches each batch as ONE wave (mirroring the
# knowledge-curate #299 one-wave precedent), and --batch-size is an advisory cap
# raised 8 -> 25 (the proven #311 live wave). Guard the new cadence wording, the
# new default, and the cross-reference; assert_not the dropped per-wave-barrier
# phrasing and the old default so a future edit can't silently reintroduce them.
assert_grep 'one wave' "$INGEST" "ingest-contract-40-step-3-dispatches-each knowledge-ingest: Step 3 dispatches each batch as one wave (#323)"
assert_grep 'default 25' "$INGEST" "ingest-contract-41-batch-size-default-25 knowledge-ingest: --batch-size default is 25 (#323)"
assert_grep 'fan-out-concurrency' "$INGEST" "ingest-contract-42-cross-references-fan-out knowledge-ingest: cross-references references/fan-out-concurrency.md (#323)"
assert_not_grep 'sequential across batches' "$INGEST" "ingest-contract-43-dropped-sequential-across-batches knowledge-ingest: dropped the 'sequential across batches' per-wave-barrier wording (#323)"
assert_not_grep '[Dd]efault 8' "$INGEST" "ingest-contract-44-no-default-8-batch knowledge-ingest: no 'Default 8'/'default 8' --batch-size default remains (#323)"
# #413: Step 3.5 post-wave integrity sweep. The orchestrator persists an
# authoritative per-batch dispatch record (.ingest.dispatch.<NNN>.json), runs
# ingest-integrity.py sweep against it, quarantines cross-contaminated pages,
# and drops them from ingested[] with reason: integrity_mismatch. Guard the
# step, the script call, the quarantine move, and the skip reason — but NOT a
# #NNN ref in the SKILL prose (feedback_no_issue_refs_in_skills).
assert_grep 'Step 3.5' "$INGEST" "ingest-contract-45-names-step-3-5-integrity knowledge-ingest: names the Step 3.5 integrity sweep (#413)"
assert_grep 'ingest-integrity.py' "$INGEST" "ingest-contract-46-calls-ingest-integrity-py knowledge-ingest: calls ingest-integrity.py sweep (#413)"
assert_grep '.ingest.dispatch.' "$INGEST" "ingest-contract-47-persists-authoritative-dispatch-record knowledge-ingest: persists the authoritative dispatch record (#413)"
assert_grep 'quarantine' "$INGEST" "ingest-contract-48-quarantines-contaminated-pages knowledge-ingest: quarantines contaminated pages (#413)"
assert_grep 'integrity_mismatch' "$INGEST" "ingest-contract-49-skip-reason-integrity-mismatch knowledge-ingest: skip reason integrity_mismatch (#413)"
# #413 follow-up: the Step 3.5 sweep input must be keyed by per-source dispatch
# INDEX (contamination-proof), never by agent-returned URL membership in
# ingested[] — a contaminated source that echoes a sibling's URL would otherwise
# filter its own slug out of the sweep and escape detection.
assert_grep 'per-source index' "$INGEST" "ingest-contract-50-step-3-5-keys-sweep knowledge-ingest: Step 3.5 keys the sweep input by per-source index, not agent-returned url (#413)"
# #421: the Step 3.5 sweep must pass --knowledge-root to enable the content_hash
# leg (otherwise the body-only cross-talk variant ships); without this guard a
# future edit could drop the flag and silently disable the leg with CI green.
assert_grep 'knowledge-root' "$INGEST" "ingest-contract-51-step-3-5-sweep-passes knowledge-ingest: Step 3.5 sweep passes --knowledge-root to enable the content_hash leg (#421)"
assert_grep 'content_hash_mismatch' "$INGEST" "ingest-contract-52-documents-content-hash-mismatch knowledge-ingest: documents the content_hash_mismatch reason (#421)"
# #431 approach (b): the Step 4.6 ingest-time contradiction tripwire dispatches
# source-contradictor per qualifying question group and merges the per-group
# fragments via contradiction-ingest-store.py into contradiction-ingest.json.
# Pure observability — never gates ingest, never rolls back a page. Guard the
# step, the agent dispatch, the merge script, the opt-out flag, the artifact,
# and the fail-soft posture — but NOT a #NNN ref in the SKILL prose (breadcrumb guard).
assert_grep 'Step 4.6' "$INGEST" "ingest-contract-53-names-step-4-6-ingest knowledge-ingest: names the Step 4.6 ingest-time contradiction tripwire"
assert_grep 'source-contradictor' "$INGEST" "ingest-contract-54-dispatches-source-contradictor-step knowledge-ingest: dispatches source-contradictor at Step 4.6"
assert_grep 'contradiction-ingest-store.py' "$INGEST" "ingest-contract-55-merges-fragments-contradiction-ingest knowledge-ingest: merges fragments via contradiction-ingest-store.py"
assert_grep 'contradiction-ingest.json' "$INGEST" "ingest-contract-56-writes-canonical-contradiction-ingest knowledge-ingest: writes the canonical contradiction-ingest.json artifact"
assert_grep '\-\-no-contradictor' "$INGEST" "ingest-contract-57-no-contradictor-opts-out knowledge-ingest: --no-contradictor opts out of Step 4.6"
assert_grep 'never rolls back\|never gates ingest\|never gate ingest' "$INGEST" "ingest-contract-58-step-4-6-fail-soft knowledge-ingest: Step 4.6 is fail-soft — never rolls back / never gates ingest"
# The qualify gate must NOT count the always-present question node toward the
# threshold (else it collapses to len(NEW) >= 1 and wastes a no-op dispatch per
# single-new-source group on a first run). Pin the corrected predicate + carve-out.
assert_grep 'len(NEW) ≥ 2' "$INGEST" "ingest-contract-59-step-4-6-qualify-gate knowledge-ingest: Step 4.6 qualify gate requires ≥2 NEW or a prior-run peer (not the always-present node)"
assert_grep 'does \*\*NOT\*\* count toward this threshold\|not count toward' "$INGEST" "ingest-contract-60-step-4-6-excludes-question knowledge-ingest: Step 4.6 excludes the question node from the qualify count"
# Defence-in-depth: confirm the obsolete Skill("cogni-knowledge:source-ingester)
# dispatch is not lingering. Agents go through Task.
assert_not_grep 'Skill("cogni-knowledge:source-ingester' "$INGEST" "ingest-contract-61-no-skill-cogni-knowledge knowledge-ingest: no Skill('cogni-knowledge:source-ingester) — agents go through Task"
# knowledge-ingest allowed-tools must include only what Steps 0-6 actually
# use. Trimmed to Read, Write, Bash, Task at v0.0.20 per #277 review.
INGEST_TOOLS_LINE=$(grep '^allowed-tools:' "$INGEST" || true)
if echo "$INGEST_TOOLS_LINE" | grep -qE 'Glob|Skill'; then
  red "FAIL: ingest-contract-62-allowed-tools-trimmed-no knowledge-ingest: allowed-tools must not include Glob or Skill (unused)"
  red "  got: $INGEST_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: ingest-contract-62-allowed-tools-trimmed-no knowledge-ingest: allowed-tools trimmed (no unused Glob / Skill)"
fi

# --- source-ingester agent -----------------------------------------------
INGESTER="$PLUGIN_ROOT/agents/source-ingester.md"
if [ ! -f "$INGESTER" ]; then
  red "FAIL: ingest-contract-63-agents-source-ingester-md agents/source-ingester.md not found"
  exit 1
fi
assert_grep 'name: source-ingester' "$INGESTER" "ingest-contract-64-source-ingester-frontmatter-name source-ingester: frontmatter name"
assert_grep 'fetch-cache.py fetch' "$INGESTER" "ingest-contract-65-reads-fetch-cache-py source-ingester: reads via fetch-cache.py fetch"
assert_grep 'Task(claim-extractor' "$INGESTER" "ingest-contract-66-dispatches-claim-extractor-task source-ingester: dispatches claim-extractor via Task"
assert_grep 'wiki/sources/' "$INGESTER" "ingest-contract-67-writes-wiki-sources-slug source-ingester: writes wiki/sources/<slug>.md (PAGE_TYPE=source default)"
assert_grep 'type: source' "$INGESTER" "ingest-contract-68-emits-type-source-frontmatter source-ingester: emits type: source frontmatter (PAGE_TYPE=source default)"
# #533: the additive PAGE_TYPE param routes other page types (interview →
# wiki/interviews/) while keeping PAGE_TYPE=source byte-identical to the research
# path — contract-lock it so the parametrization can't silently regress (the
# type: source / wiki/sources/ literals above are the preserved source default).
assert_grep 'PAGE_TYPE' "$INGESTER" "ingest-contract-69-gained-additive-page-type source-ingester: gained the additive PAGE_TYPE param (default source)"
assert_grep 'wiki/interviews/' "$INGESTER" "ingest-contract-70-page-type-interview-routes source-ingester: PAGE_TYPE=interview routes to wiki/interviews/"
assert_grep 'pre_extracted_claims' "$INGESTER" "ingest-contract-71-populates-pre-extracted-claims source-ingester: populates pre_extracted_claims frontmatter"
# #593: frontmatter-resident theme membership — the source page carries its own
# theme_label: (from the additive THEME_LABEL param) so sub_index.py groups it by
# its own page, not a root portal bullet (the curated-root membership signal).
assert_grep 'THEME_LABEL' "$INGESTER" "ingest-contract-72-gained-additive-theme-label source-ingester: gained the additive THEME_LABEL param (#593)"
assert_grep 'theme_label:' "$INGESTER" "ingest-contract-73-emits-theme-label-frontmatter source-ingester: emits theme_label: frontmatter from THEME_LABEL (#593)"
# Geography sibling of theme_label: — the source page carries its own market:
# (from the additive MARKET param, the run-level plan.json::market) so the
# perspectives overlay's Where facet can group it by market.
assert_grep 'MARKET' "$INGESTER" "ingest-contract-74-gained-additive-market-param source-ingester: gained the additive MARKET param (Where facet)"
assert_grep 'market:' "$INGESTER" "ingest-contract-75-emits-market-frontmatter-where source-ingester: emits market: frontmatter from MARKET (Where facet)"

# Optional author / publication-date metadata in the Phase-3 page template.
# Bound to the QUOTED TEMPLATE PLACEHOLDERS (fixed-string), not the bare key, so
# reverting the template edit reddens these even though the rules bullets below
# also spell the key names in prose.
assert_grep_f 'author: "<AUTHOR>"' "$INGESTER" "ingest-contract-121-template-emits-optional-author source-ingester: Phase-3 template emits the OPTIONAL author: key"
assert_grep_f 'published_date: "<PUBLISHED_DATE>"' "$INGESTER" "ingest-contract-122-template-emits-optional-published-date source-ingester: Phase-3 template emits the OPTIONAL published_date: key"
assert_grep 'Emit `author:` only when' "$INGESTER" "ingest-contract-123-rules-mark-author-optional source-ingester: YAML frontmatter rules mark author: optional (drop the line otherwise)"
assert_grep 'Emit `published_date:` only when' "$INGESTER" "ingest-contract-124-rules-mark-published-date-optional source-ingester: YAML frontmatter rules mark published_date: optional (drop the line otherwise)"
assert_grep 'atomic_write_text' "$INGESTER" "ingest-contract-76-writes-knowledge-lib-atomic source-ingester: writes via _knowledge_lib.atomic_write_text"
# #421: the Phase-3 pre-write guard threads CONTENT_HASH so the in-agent leg
# mirrors the orchestrator sweep — guard it so the agent leg can't be silently dropped.
assert_grep 'CONTENT_HASH' "$INGESTER" "ingest-contract-77-phase-3-guard-threads source-ingester: Phase 3 guard threads CONTENT_HASH for the content_hash leg (#421)"
# Slice 16 (#308): id: must be UNQUOTED (quoted form trips wiki-health id_mismatch),
# and source pages default to a non-empty tags list.
assert_grep 'UNQUOTED' "$INGESTER" "ingest-contract-78-emits-id-unquoted-308 source-ingester: emits id: unquoted (#308 — quoted id trips health id_mismatch)"
assert_grep 'tags: \[source\]' "$INGESTER" "ingest-contract-79-default-tags-source source-ingester: default tags: [source] (#308)"
assert_not_grep 'tags: \[\]' "$INGESTER" "ingest-contract-80-no-empty-tags-remains source-ingester: no empty tags: [] remains (#308)"
# #324: the summary field is semantic (one self-contained sentence), no char count.
assert_grep 'self-contained sentence' "$INGESTER" "ingest-contract-81-summary-authored-one-self source-ingester: summary authored as one self-contained sentence (#324)"
assert_not_grep '180' "$INGESTER" "ingest-contract-82-no-character-count-contract source-ingester: no character-count contract remains in the summary field (#324)"
# #387: the summary field documents the regular-space authoring guard + names the
# orchestrator-side sanitize_summary normalization (no stray U+2020 dagger / NBSP).
assert_grep 'regular space' "$INGESTER" "ingest-contract-83-summary-contract-requires-regular source-ingester: summary contract requires regular spaces (#387)"
assert_grep 'sanitize_summary' "$INGESTER" "ingest-contract-84-names-orchestrator-s-sanitize source-ingester: names the orchestrator's sanitize_summary normalization (#387)"
# #413: Phase 3 pre-write integrity assertion — the wrapper asserts the composed
# page's id/sources match the dispatched SLUG/URL (the ground truth) and exits 3
# on mismatch, writing nothing; the agent then emits integrity_mismatch.
assert_grep 'integrity' "$INGESTER" "ingest-contract-85-documents-pre-write-integrity source-ingester: documents the pre-write integrity assertion (#413)"
assert_grep 'sys.exit(3)' "$INGESTER" "ingest-contract-86-pre-write-guard-exits source-ingester: pre-write guard exits 3 on mismatch, writes nothing (#413)"
assert_grep 'integrity_mismatch' "$INGESTER" "ingest-contract-87-emits-skip-reason-integrity source-ingester: emits skip reason integrity_mismatch (#413)"
# Frontmatter tools must not include WebFetch (re-fetch is forbidden in Phase 4).
INGESTER_TOOLS_LINE=$(grep '^tools:' "$INGESTER" || true)
if ! echo "$INGESTER_TOOLS_LINE" | grep -q WebFetch; then
  green "PASS: ingest-contract-88-frontmatter-tools-does-not source-ingester: frontmatter tools: does NOT include WebFetch (Phase 3's job)"
else
  red "FAIL: ingest-contract-88-frontmatter-tools-does-not source-ingester: frontmatter tools: must not include WebFetch"
  red "  got: $INGESTER_TOOLS_LINE"
  errors=$((errors + 1))
fi

# --- claim-extractor agent -----------------------------------------------
CLAIM_EXTRACTOR="$PLUGIN_ROOT/agents/claim-extractor.md"
if [ ! -f "$CLAIM_EXTRACTOR" ]; then
  red "FAIL: ingest-contract-89-agents-claim-extractor-md agents/claim-extractor.md not found"
  exit 1
fi
assert_grep 'name: claim-extractor' "$CLAIM_EXTRACTOR" "ingest-contract-90-claim-extractor-frontmatter-name claim-extractor: frontmatter name"
assert_grep 'Forked from cogni-research/agents/claim-extractor.md' "$CLAIM_EXTRACTOR" "ingest-contract-91-declares-fork-lineage claim-extractor: declares fork lineage"
assert_grep 'excerpt_position' "$CLAIM_EXTRACTOR" "ingest-contract-92-emits-excerpt-position claim-extractor: emits excerpt_position"
assert_grep 'BODY_FILE' "$CLAIM_EXTRACTOR" "ingest-contract-93-input-body-file-cached claim-extractor: input is BODY_FILE (cached body), not draft"
assert_grep 'sub_question_refs' "$CLAIM_EXTRACTOR" "ingest-contract-94-carries-sub-question-refs claim-extractor: carries sub_question_refs"
# Negative assertion: must NOT create entities (no cogni-research side-effects).
assert_not_grep 'scripts/create-entity.sh' "$CLAIM_EXTRACTOR" "ingest-contract-95-does-not-call-create claim-extractor: does NOT call create-entity.sh (clean-break from cogni-research's Phase 3)"
assert_not_grep '02-sources/data' "$CLAIM_EXTRACTOR" "ingest-contract-96-does-not-touch-cogni claim-extractor: does NOT touch cogni-research's 02-sources/data"
# Frontmatter tools: no Write (the ingester writes the page), no WebFetch.
EXTRACTOR_TOOLS_LINE=$(grep '^tools:' "$CLAIM_EXTRACTOR" || true)
if echo "$EXTRACTOR_TOOLS_LINE" | grep -qE 'Write|WebFetch'; then
  red "FAIL: ingest-contract-97-frontmatter-tools-read-only claim-extractor: frontmatter tools: must not include Write or WebFetch"
  red "  got: $EXTRACTOR_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: ingest-contract-97-frontmatter-tools-read-only claim-extractor: frontmatter tools: read-only (no Write, no WebFetch)"
fi

# --- source-curator PDF branch (#275, #278) — moved here from source-fetcher
# at v0.0.29 (Option B, #292): the WebFetch body-pull + PDF Read-loop moved
# into the curator's Phase 4, so the PDF contract now lives on source-curator.
CURATOR="$PLUGIN_ROOT/agents/source-curator.md"
if [ ! -f "$CURATOR" ]; then
  red "FAIL: ingest-contract-98-agents-source-curator-md agents/source-curator.md not found"
  exit 1
fi
assert_grep 'is_pdf_response' "$CURATOR" "ingest-contract-99-uses-pdf-response-helper source-curator: uses is_pdf_response helper (#275, moved in #292)"
assert_grep 'pdf_extraction_failed' "$CURATOR" "ingest-contract-100-closed-vocab-includes-pdf source-curator: closed vocab includes pdf_extraction_failed (#275)"
assert_grep 'pdf_truncated' "$CURATOR" "ingest-contract-101-documents-pdf-truncated-200 source-curator: documents pdf_truncated for the 200-page hard-cap case (#278)"
assert_grep 'pdf_pages_read' "$CURATOR" "ingest-contract-102-records-pdf-pages-read source-curator: records pdf_pages_read in the candidate fetch sub-object (#278)"
# #458/#583: the saved-but-unrenderable PDF case keeps its own honest,
# operator-actionable reason — but it is now reserved for genuinely image-only
# PDFs: before recording it, the curator tries the optional pure-Python text-layer
# fallback (pdf-extract.py / optional pypdf), and only falls through when that also fails.
assert_grep 'pdf_render_unavailable' "$CURATOR" "ingest-contract-103-pdf-branch-records-render source-curator: PDF branch records pdf_render_unavailable when the Read tool can't render a saved file (#458)"
assert_grep 'pdf-extract.py\|pdf_text_extracted\|text-layer fallback' "$CURATOR" "ingest-contract-104-pdf-branch-tries-optional source-curator: PDF branch tries the optional pypdf text-layer fallback before pdf_render_unavailable (#583)"
# Regression guard for the #277 review-blocker, now on the curator: the PDF
# branch instructs `Read pages: "1-20"` the saved binary; the Read tool MUST
# be in the frontmatter tools list or the PDF rail fails at runtime.
CURATOR_TOOLS_LINE=$(grep '^tools:' "$CURATOR" || true)
if echo "$CURATOR_TOOLS_LINE" | grep -q '"Read"'; then
  green "PASS: ingest-contract-105-frontmatter-tools-includes-read source-curator: frontmatter tools: includes Read (required by the moved PDF branch)"
else
  red "FAIL: ingest-contract-105-frontmatter-tools-includes-read source-curator: frontmatter tools: must include Read for the PDF branch"
  red "  got: $CURATOR_TOOLS_LINE"
  errors=$((errors + 1))
fi

# --- source-fetcher (#276) — cobrowse-only after #292 --------------------
FETCHER="$PLUGIN_ROOT/agents/source-fetcher.md"
assert_grep 'cobrowse_unavailable' "$FETCHER" "ingest-contract-106-closed-vocab-includes-cobrowse source-fetcher: closed vocab includes cobrowse_unavailable (#276)"

# --- _knowledge_lib.py new helpers ---------------------------------------
LIB="$PLUGIN_ROOT/scripts/_knowledge_lib.py"
assert_grep 'def is_pdf_response' "$LIB" "ingest-contract-107-defines-pdf-response _knowledge_lib: defines is_pdf_response"
assert_grep 'def atomic_write_text' "$LIB" "ingest-contract-108-defines-atomic-write-text _knowledge_lib: defines atomic_write_text"
assert_grep 'def slugify' "$LIB" "ingest-contract-109-defines-slugify-lifted-inline _knowledge_lib: defines slugify (lifted from inline SKILL prose)"
assert_grep 'def sanitize_summary' "$LIB" "ingest-contract-110-defines-sanitize-summary-387 _knowledge_lib: defines sanitize_summary (#387 index-one-liner guard)"
# #413: the frontmatter id+sources extractor is shared by ingest-integrity.py
# (sweep) and source-ingester's Phase 3 pre-write assertion — one impl, no drift.
assert_grep 'def extract_page_id_and_url' "$LIB" "ingest-contract-111-defines-extract-page-id _knowledge_lib: defines extract_page_id_and_url shared by sweep + agent (#413)"
assert_grep 'def extract_page_content_hash' "$LIB" "ingest-contract-112-defines-extract-page-content _knowledge_lib: defines extract_page_content_hash shared by sweep + Phase-3 guard (#421)"

# --- fetch-cache.py VALID_REASONS constant -------------------------------
FETCH_CACHE="$PLUGIN_ROOT/scripts/fetch-cache.py"
assert_grep 'VALID_REASONS' "$FETCH_CACHE" "ingest-contract-113-valid-reasons-constant-closes fetch-cache: VALID_REASONS constant (closes the vocabulary at the script boundary)"
assert_grep 'pdf_extraction_failed' "$FETCH_CACHE" "ingest-contract-114-fetch-cache-valid-reasons-includes-pdf-extraction-failed fetch-cache: VALID_REASONS includes pdf_extraction_failed (#275)"
assert_grep 'pdf_render_unavailable' "$FETCH_CACHE" "ingest-contract-115-fetch-cache-valid-reasons-includes-pdf-render-unavailable fetch-cache: VALID_REASONS includes pdf_render_unavailable (#458)"
assert_grep 'cobrowse_unavailable' "$FETCH_CACHE" "ingest-contract-116-valid-reasons-includes-cobrowse fetch-cache: VALID_REASONS includes cobrowse_unavailable (#276)"

# Behavioural check: is_pdf_response + atomic_write_text actually work.
OUT=$(python3 - "$PLUGIN_ROOT/scripts" <<'PY'
import importlib.util
import sys
import tempfile
from pathlib import Path

scripts = Path(sys.argv[1])
spec = importlib.util.spec_from_file_location("_knowledge_lib", scripts / "_knowledge_lib.py")
kl = importlib.util.module_from_spec(spec)
sys.modules["_knowledge_lib"] = kl
spec.loader.exec_module(kl)


def check(tag, fn):
    try:
        fn()
        print(f"{tag}: OK")
    except AssertionError as exc:
        print(f"{tag}: FAIL {exc}")


def test_is_pdf_response():
    # Content-Type signal
    assert kl.is_pdf_response("application/pdf", "https://example.org/foo")
    assert kl.is_pdf_response("application/pdf; charset=binary", "https://example.org/foo")
    assert kl.is_pdf_response("APPLICATION/PDF", "https://example.org/foo")
    # URL suffix signal
    assert kl.is_pdf_response(None, "https://arxiv.org/pdf/2401.12345.pdf")
    assert kl.is_pdf_response("text/plain", "https://example.org/foo.PDF")
    # Negatives
    assert not kl.is_pdf_response("text/html", "https://example.org/foo")
    assert not kl.is_pdf_response(None, "https://example.org/foo.html")
    assert not kl.is_pdf_response(None, "")


def test_atomic_write_text():
    with tempfile.TemporaryDirectory() as td:
        target = Path(td) / "sub" / "page.md"
        text = "---\nid: foo\n---\n# Hello\n"
        returned = kl.atomic_write_text(target, text)
        assert returned == target, (returned, target)
        assert target.read_text(encoding="utf-8") == text, target.read_text(encoding="utf-8")
        # No .tmp debris
        leftover = [p.name for p in target.parent.iterdir() if p.name.endswith(".tmp")]
        assert leftover == [], leftover


def test_slugify():
    # Happy paths
    assert kl.slugify("Article 6 — High-risk AI") == "article-6-high-risk-ai", kl.slugify("Article 6 — High-risk AI")
    assert kl.slugify("EU AI Act, GPAI Code of Practice") == "eu-ai-act-gpai-code-of-practice"
    assert kl.slugify("  Lots   of  spaces  ") == "lots-of-spaces"
    # Length cap, strip trailing dash after cap
    long_in = "a" * 200
    assert kl.slugify(long_in, max_len=20) == "a" * 20
    capped = kl.slugify("aa" + ("-" * 10) + "b" * 100, max_len=15)
    assert capped == capped.rstrip("-") and len(capped) <= 15, capped
    # Edge cases: empty / non-alnum → empty (caller applies hash fallback)
    assert kl.slugify("") == ""
    assert kl.slugify("---") == ""
    assert kl.slugify("!@#$%^&*") == ""


def test_sanitize_summary():
    # The exact #387 case: U+2020 DAGGER where a space belongs (\u00a730, Dezember2025).
    # \u escapes keep the substitute codepoints unambiguous in ASCII source.
    raw = (
        "\u2026 die 10 verpflichtenden Mindestma\u00dfnahmen nach "
        "\u00a7\u202030 BSIG, die seit Dezember\u20202025 ohne "
        "\u00dcbergangsfrist \u2026"
    )
    out = kl.sanitize_summary(raw)
    # Every targeted substitute codepoint is gone.
    for cp in ("\u2020", "\u2021", "\u00a0", "\u202f", "\u2009"):
        assert cp not in out, (hex(ord(cp)), repr(out))
    assert "\u00a7 30 BSIG" in out, repr(out)   # \u00a7 30, single regular space
    assert "Dezember 2025" in out, repr(out)
    # Exotic spaces (NBSP / NNBSP / THIN SPACE) collapse to a single regular space.
    assert kl.sanitize_summary("Artikel\u00a09\u202fund\u2009Absatz 2") == "Artikel 9 und Absatz 2"
    # NOT slugify - accents / non-ASCII letters preserved verbatim, no transliteration.
    assert kl.sanitize_summary("Mindestma\u00dfnahmen f\u00fcr \u00dcbergangsfrist") == "Mindestma\u00dfnahmen f\u00fcr \u00dcbergangsfrist"
    # Falsy passthrough (callers surface a bad value rather than coalescing to "").
    assert kl.sanitize_summary("") == ""
    assert kl.sanitize_summary(None) is None


check("is_pdf_response", test_is_pdf_response)
check("atomic_write_text", test_atomic_write_text)
check("slugify", test_slugify)
check("sanitize_summary", test_sanitize_summary)
PY
)

errors_before=$errors

grade() {
  local tag="$1" description="$2"
  local line
  line=$(printf '%s\n' "$OUT" | grep "^${tag}:" || true)
  case "$line" in
    "${tag}: OK")     green "PASS: $description" ;;
    "${tag}: FAIL "*) red   "FAIL: $description"; red "  ${line#${tag}: FAIL }"; errors=$((errors + 1)) ;;
    *)                red   "FAIL: $description (no result line — python crashed?)"
                      red   "  output: $OUT"; errors=$((errors + 1)) ;;
  esac
}

grade is_pdf_response   "ingest-contract-117-pdf-response-content-type is_pdf_response — Content-Type and .pdf suffix detection"
grade atomic_write_text "ingest-contract-118-atomic-write-text-round atomic_write_text round-trips text and leaves no .tmp debris"
grade slugify           "ingest-contract-119-slugify-lower-kebab-dash slugify — lower-kebab, dash-collapse, length cap, empty-on-non-alnum"
grade sanitize_summary  "ingest-contract-120-sanitize-summary-u-2020 sanitize_summary — U+2020 dagger / NBSP -> regular space, accents preserved (#387)"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
