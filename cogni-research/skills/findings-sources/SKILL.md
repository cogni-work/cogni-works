---
name: findings-sources
description: |
  Execute parallel web research and extract enriched sources from findings.
  Use after research-plan completes — when query batches are ready in 03-query-batches/.
  Trigger when user says "run research", "gather findings", "search for evidence",
  "execute the research plan", "find sources", "start web research", "resume research",
  "continue the research", "pick up where we left off", or wants to move from planning
  to actual research execution — including resuming an interrupted run.
  Produces findings (04) and enriched sources (05).
  After completion, run claims for claim extraction and verification.
---

# Findings & Sources

This is where the plan becomes evidence. Findings quality directly determines claim strength and synthesis credibility downstream — weak findings cascade into unsupported claims and hollow narratives. Parallel execution across dimensions maximizes coverage, while source enrichment creates the provenance chain that makes every claim traceable back to a real, scored publisher.

## Quick Example

**Input:** 5 dimensions, 28 refined questions, 28 query batches from research-plan

**Phase 1 — Findings:** ~140 findings across 5 dimensions (avg 5 per question), each with quality scores and source URLs, stored in `04-findings/data/`

**Phase 2 — Sources:** ~45 deduplicated source entities in `05-sources/data/`, each with publisher profile, reliability score, and APA citation. The compression (140 findings → 45 sources) comes from URL deduplication — multiple findings often cite the same source.

## Prerequisites

1. **Verify project exists**: Confirm the project directory and `.metadata/sprint-log.json` are present. If the path doesn't exist, ask the user for the correct path.

2. **Check planning completed**: Read `.metadata/sprint-log.json` and confirm `planning_complete: true`. If false, tell the user to run `research-plan` first.

3. **Verify data directories**: Query batches in `03-query-batches/data/` and dimensions in `01-research-dimensions/data/` must exist with at least one entity each.

## Resumption

If a previous run was interrupted, check state before re-executing:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/scan-resumption-state.sh --phase 3 --project-path <path> --json
```

The script returns a JSON recommendation:
- **FULL_RUN** — no prior progress. Start from Phase 1 step 1.
- **RESUME** — some questions already have findings. The response includes a `pending_questions` array with entity IDs that still need processing. Use this list to filter the execution batches from `discover-questions-by-dimension.sh` — only invoke findings-creator for questions in `pending_questions`.
- **COMPLETE** — all questions have findings. Skip to Phase 2 (source extraction).

For script arguments and output format see [references/script-reference.md](references/script-reference.md).

## Selective Execution

If the user asks to run only specific dimensions (e.g., "just dimensions 1 and 3"), this is valid but has tradeoffs. Before proceeding:

1. **Warn about coverage gaps**: Skipping dimensions breaks MECE coverage. Downstream claims and synthesis will only reflect the included dimensions — this creates blind spots, not just missing data. Make sure the user understands this.
2. **Get explicit confirmation**: Ask the user to confirm they accept partial coverage before starting.
3. **Filter execution batches**: Run `discover-questions-by-dimension.sh` to get the full map, then filter `question_paths` to only include questions from the requested dimensions (match on `dimension_number` in the output).
4. **Skip reconciliation for excluded dimensions**: Do not retry questions from excluded dimensions — they were intentionally skipped, not failed.
5. **Adjust completion criteria**: Mark sprint-log `discovery_complete: true` but also record `partial_scope: {included_dimensions: [1, 3], excluded_dimensions: [2, 4, 5], reason: "user request"}` so downstream skills know the coverage is intentionally partial.

## Workflow

### Phase 1: Findings Creation (Parallel)

Batching by dimension keeps search context coherent — an agent researching "AI/ML Techniques" benefits from domain focus rather than context-switching between unrelated dimensions. Parallelism within each batch maximizes throughput. A project with 28 questions typically completes in 2-3 sequential batches of 15-20 questions each.

1. **Check resumption state**: Always run the resumption scan (see Resumption section above) before starting work — even on a seemingly fresh run. This prevents accidentally re-processing questions from a prior interrupted attempt.

2. **Discover execution batches**: Run `${CLAUDE_PLUGIN_ROOT}/scripts/discover-questions-by-dimension.sh --project-path <path> --json` to group questions by dimension into execution batches. If resuming, filter batches to only include `pending_questions` from the scan result.

3. **Execute batch loop** (sequential batches, parallel agents within):

   **Agent selection:** Check `.metadata/sprint-log.json` for `deep_exploration`. When `deep_exploration: true`, invoke `findings-creator-deep` agents instead of `findings-creator` for each question. The deep agent performs recursive tree exploration within each question's scope, producing the same finding entities (04-findings/) — all downstream steps (reconciliation, source extraction) work unchanged. When `deep_exploration` is false or absent, use `findings-creator` as normal.

   For each execution batch, invoke `findings-creator` agents in parallel via Task tool (one per question):
   ```
   Agent: findings-creator
   Args: --project-path <path> --question-path <question-file.md> --batch-ref <batch-entity-id>
   ```
   Each agent handles web search, LLM knowledge extraction, and quality scoring independently. If the project has a `document-store/` directory, agents automatically invoke `findings-creator-file` for local PDFs — no special configuration needed.

4. **Report progress**: After each batch completes, tell the user: batch N/M done, X findings created so far, any questions with zero results.

5. **Reconciliation**: After all batches complete:
   - Count findings per dimension
   - Identify questions with zero findings
   - Retry those questions in a single reconciliation batch
   - If reconciliation still finds >3 questions with zero findings, pause and ask the user whether to accept the gaps or adjust query strategy

6. **Verify coverage**: Every refined question should have at least 1 finding. Log coverage stats to sprint-log `phase_findings_coverage`.

### Phase 2: Source Extraction (Sequential)

Source extraction creates the provenance chain. Every claim in the downstream synthesis traces back through findings to enriched sources with publisher reliability scores. Without this step, claims are unverifiable assertions.

Source-creator runs sequentially (not per-question) because it deduplicates across all findings — parallel execution would create duplicate source entities.

1. **Invoke `source-creator` agent** via Task tool with `--project-path <path>`. The agent scans all findings, deduplicates by URL, creates enriched source entities with publisher profiles and APA citations, and links sources back to findings via wikilinks.

2. **Verify output**: The `verify-source-creator-output` hook fires automatically after the agent completes. If it detects hallucinated output (e.g., agent claims sources created but directory is empty), it auto-recovers by re-executing source creation via script. No manual intervention needed.

3. **Generate sources README**: Read the project language from `.metadata/project-config.json` (`language` field, defaults to "en"), then run `${CLAUDE_PLUGIN_ROOT}/scripts/generate-sources-readme.sh --project-path <path> --language <code> --json`

4. **Mark complete**: Read `.metadata/sprint-log.json`, set `discovery_complete: true` and `updated_at` to current ISO 8601 timestamp, write back via `${CLAUDE_PLUGIN_ROOT}/scripts/save-phase-state.sh` or direct JSON edit (sprint-log is metadata, not an entity — Write/Edit is allowed).

5. **Report to user**: Total findings, total sources, deduplication ratio, coverage summary.

## Error Recovery

| Scenario | What to Do |
|----------|------------|
| Project path does not exist | Ask the user for the correct path. Do not guess or create a new project. |
| findings-creator returns `{"ok": false}` | Check `.logs/findings-creator/` for the question ID. Re-invoke for that question only. |
| Batch completes with < 50% questions producing findings | Pause. Ask the user if topic scope is too narrow or queries need adjustment. Consider re-running research-plan. |
| source-creator times out or produces no output | The `verify-source-creator-output` hook auto-recovers. If it fails twice, check `.metadata/entity-index.json` for corruption. |
| Reconciliation finds zero-finding questions | Re-run findings-creator for those questions. If still zero after retry, accept gap and note in sprint-log. |
| Hook `repair-missing-batches` fires | Automatic — creates minimal batch entities from findings metadata. No action needed. |
| Resumption detected as RESUME | Skip completed questions. The scan script identifies exactly which are pending. |

## Completion

Findings-sources is complete when:
- Sprint-log shows `discovery_complete: true`
- Every in-scope refined question has at least 1 finding in `04-findings/data/` (all questions for full runs; only included dimensions for selective execution)
- Sources README generated in `05-sources/`

After completion, run the `claims` skill for claim extraction and three-layer verification.
