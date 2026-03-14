---
name: claims
description: |
  Extract verified claims from research findings with three-layer confidence scoring.
  Use after findings-sources completes — when findings exist in 04-findings/ and sources in 05-sources/.
  This is the THIRD skill in the 4-stage pipeline (research-plan > findings-sources > claims > synthesis).
  Trigger when user says "extract claims", "verify findings", "fact-check", "create claims",
  "run claim extraction", "verify the research", "resume claims", "continue claim extraction",
  "pick up where claims left off", or wants to move from raw findings to verified assertions —
  including resuming an interrupted claims run.
  Produces claims (06) with evidence confidence, claim quality, and optional source verification.
  After completion, run synthesis for narrative generation.
---

# Claims

This is where findings become verifiable assertions. Findings and sources are a raw evidence base — rich but uncurated. Claims extraction decomposes each finding into atomic, self-contained statements and scores them on evidence strength and linguistic quality. This is the bridge between raw research and publishable narrative: synthesis can only cite what claims have verified. Weak claims cascade into unsupported narratives and erode stakeholder trust; strong claims give synthesis a foundation of scored, traceable assertions that make every finding count.

## Quick Example

**Input:** 5 dimensions, 140 findings, 45 sources from the findings-sources phase

**Phase 1 — Extraction:** 62 atomic claims across 5 dimensions, each with evidence confidence and claim quality scores, stored in `06-claims/data/`. Average composite confidence: 0.78

**Phase 2 — Verification:** 48 claims verified via cogni-claims (source URLs confirmed), 8 flagged for deviation, 6 skipped (source unavailable). Average final_confidence: 0.76

**Phase 3 — Finalization:** Claims README generated in `06-claims/`; sprint-log updated with `claims_complete: true`

## Prerequisites

1. **Verify project exists**: Confirm the project directory and `.metadata/sprint-log.json` are present. If the path doesn't exist, ask the user for the correct path.

2. **Check findings-sources completed**: Read `.metadata/sprint-log.json` and confirm `discovery_complete: true`. If false, tell the user to run `findings-sources` first.

3. **Verify entity directories**: Findings in `04-findings/data/` and sources in `05-sources/data/` must each contain at least one entity.

## Resumption

If a previous run was interrupted, check state before re-executing:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/scan-resumption-state.sh --phase 7 --project-path <path> --json
```

The script returns a JSON recommendation:
- **FULL_RUN** — no prior progress. Start from Phase 1 step 1.
- **RESUME** — some findings already have claims extracted. The response includes `pending_finding_ids` and `pending_finding_paths` arrays identifying findings that still need claim extraction. Use these to filter partition execution — only process findings in `pending_finding_paths`.
- **COMPLETE** — all findings have claims. Skip to Phase 2 (source verification) or Phase 3 (finalization) depending on whether verification has run.

For script arguments and output format, see [references/script-reference.md](references/script-reference.md).

## Selective Execution

If the user asks to extract claims for only specific dimensions (e.g., "just run claims on dimensions 1 and 3"), this is valid but has tradeoffs. Before proceeding:

1. **Warn about claim coverage gaps**: Skipping dimensions means claims exist only for included dimensions — synthesis will have unverified assertions from excluded dimensions, weakening the narrative evidence chain. Make sure the user understands this.
2. **Get explicit confirmation**: Ask the user to confirm they accept partial claim coverage.
3. **Filter findings**: When partitioning findings, include only those with dimension tags matching the requested dimensions (check `tags` array in finding frontmatter for `dimension/{slug}` entries).
4. **Skip reconciliation for excluded dimensions**: These were intentionally skipped, not failed.
5. **Record in sprint-log**: `partial_scope: {included_dimensions: [1, 3], excluded_dimensions: [2, 4, 5], reason: "user request"}` so synthesis knows claim coverage is intentionally partial.

## Workflow

### Phase 1: Claim Extraction (Parallel)

Partitioning by finding count keeps extraction batches balanced — each claim-extractor agent processes a roughly equal slice of findings independently. Parallel execution maximizes throughput: a project with 140 findings typically completes in 3-5 minutes with 5-10 parallel agents. No cross-agent coordination is needed because each claim traces to a single finding.

1. **Check resumption state**: Always run the resumption scan (see Resumption section above) before starting work — even on a seemingly fresh run. This prevents accidentally re-processing findings from a prior interrupted attempt.

2. **Partition findings**: Run `${CLAUDE_PLUGIN_ROOT}/scripts/partition-entities.sh` to split findings across claim-extractor agents. Target: 1 agent per ~15 findings (3-10 agents typical). For script arguments, see [references/script-reference.md](references/script-reference.md).

3. **Invoke claim-extractor agents** in parallel via Task tool (one per partition):
   ```
   Agent: claim-extractor
   Args: --project-path <path> --partition-index <n> --total-partitions <total>
   ```
   Each agent extracts atomic claims from its partition of findings, scoring evidence confidence and claim quality per claim. Claims are created in `06-claims/data/` via `create-entity.sh`.

   For the full scoring model (evidence confidence factors, claim quality dimensions, composite calculation), see `${CLAUDE_PLUGIN_ROOT}/references/claim-assurance.md`.

4. **Report progress**: After all partitions complete, report: total claims created, average composite confidence, flagged-for-review count.

5. **Verify coverage**: Minimum 5 claims with valid confidence scores. If fewer, check finding quality — findings may lack extractable factual assertions. Ask the user whether to proceed or re-run findings-sources with adjusted queries.

### Phase 2: Source Verification (Optional)

Source verification is the third layer of assurance — it checks whether source URLs actually support the claims extracted from them. This catches language strengthening, selective omission, and data staleness that escaped extraction. Without it, claims carry two-layer assurance (evidence confidence + claim quality); with it, they reach research-grade verification.

1. **Check cogni-claims availability**: If cogni-claims plugin is not available, set `source_verification: skipped` for all claims and skip to Phase 3. Inform the user that claims will carry two-layer assurance only.

2. **Identify verifiable claims**: Claims with `source_refs` linking to sources that have HTTP/HTTPS URLs in their frontmatter.

3. **Submit to cogni-claims**: Batch submit claims with their source URLs for verification.

4. **Record submission**: Save reference in `.metadata/claim-submission.json`.

5. **Update claim entities** with verification results:
   - `source_verification`: verified | deviated | source_unavailable | skipped
   - `deviation_count`, `deviation_max_severity`
   - `final_confidence`: confidence_score x verification_modifier

   Verification modifiers:
   | Status | Modifier |
   |---|---|
   | verified | 1.0 |
   | deviated (low) | 0.9 |
   | deviated (medium) | 0.7 |
   | deviated (high) | 0.4 |
   | deviated (critical) | 0.1 |
   | source_unavailable | 0.8 |

   For the full deviation taxonomy and YAML output format, see `${CLAUDE_PLUGIN_ROOT}/references/claim-assurance.md`.

### Phase 3: Finalization

Finalization creates the claim inventory that synthesis uses to select and cite claims. The claims README provides the at-a-glance confidence distribution that lets synthesis decide which claims are narrative-grade (high confidence for executive reports, medium for supporting evidence, low for flagged-with-caveat).

For script arguments and output formats, see [references/script-reference.md](references/script-reference.md).

1. **Generate claims README**: Read the project language from `.metadata/sprint-log.json`, then run:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-claims-readme.sh --project-path <path> --language <code> --json
   ```

2. **Aggregate metrics**: Total claims, average confidence, verification coverage percentage, flagged-for-review count.

3. **Update sprint-log**: Set `claims_complete: true` and `updated_at` to current ISO 8601 timestamp. For selective execution, also record `partial_scope`. See [references/script-reference.md](references/script-reference.md) for the full list of sprint-log fields written by claims.

4. **Report to user**: Claim count, average confidence, verification status (verified/deviated/skipped/unavailable breakdown), flagged count, and that the next step is running `synthesis`.

## Output Structure

```
<project>/
├── 06-claims/
│   ├── data/
│   │   ├── claim-{slug-1}.md       # Atomic claim with confidence scores
│   │   ├── claim-{slug-2}.md
│   │   └── ...
│   └── README.md                   # Claim inventory (generated)
└── .metadata/
    ├── sprint-log.json             # claims_complete: true
    ├── claim-extractor-stats.json  # Extraction statistics per partition
    └── claim-submission.json       # cogni-claims submission record (if verified)
```

## Error Recovery

| Scenario | What to Do |
|----------|------------|
| Project path does not exist | Ask the user for the correct path. Do not guess or create a new project. |
| Findings-sources not yet complete | Tell the user to run `findings-sources` first. Do not proceed with claims. |
| claim-extractor returns `{"ok": false}` | Check `.logs/claim-extractor/` for the partition index. Re-invoke for that partition only. |
| Partition produces zero claims from non-empty findings | Check finding quality — findings may lack extractable assertions. Log and continue; do not fail the run. |
| cogni-claims plugin not available | Set `source_verification: skipped` for all claims. Proceed with two-layer assurance only. Inform the user. |
| cogni-claims verification times out | Record `source_verification: skipped` for timed-out claims. Note in sprint-log. Proceed with finalization. |
| Resumption detected as RESUME | Skip completed findings. The scan script identifies exactly which findings are pending via `pending_finding_paths`. |
| `generate-claims-readme.sh` fails | Check script output JSON for error details. Verify `06-claims/data/` is not empty. Re-run the script. |

## Completion

Claims is complete when:
- Sprint-log shows `claims_complete: true`
- At least 5 claims exist in `06-claims/data/` with valid confidence scores
- Claims README generated in `06-claims/`
- All in-scope findings have been processed (all findings for full runs; only included dimensions for selective execution)

After claims completes, run the `synthesis` skill for narrative generation via cogni-narrative story arc frameworks.
