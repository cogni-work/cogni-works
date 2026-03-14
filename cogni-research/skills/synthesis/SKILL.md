---
name: synthesis
description: |
  Synthesize research findings into executive narratives using cogni-narrative's story arc frameworks.
  Use after claims completes — when claims exist in 06-claims/ with confidence scores.
  This is the FINAL skill in the 4-stage pipeline (research-plan > findings-sources > claims > synthesis).
  Trigger when user says "synthesize", "create synthesis", "generate narratives from research",
  "tell the story", "write up the findings", "create the research report", "research report",
  "summarize findings", "summarize the research", "generate the report", "write the narrative",
  "finalize the research", "create insight summaries", "resume synthesis", "continue synthesis",
  "pick up where synthesis left off", or wants to move from verified claims to publishable narratives —
  including resuming an interrupted synthesis run.
  Produces per-dimension insight summaries and a cross-dimensional research hub narrative.
---

# Synthesis

This is where evidence becomes insight. Findings, sources, and claims are a structured database — useful for verification but unreadable by stakeholders. Synthesis transforms that database into narratives that executives can act on, analysts can cite, and sales teams can reference. The quality of these narratives determines whether the entire research effort translates into decisions or sits unread. A weak synthesis wastes all the upstream work; a strong one makes every finding and claim count.

## Quick Example

**Input:** 5 dimensions, 140 findings, 45 sources, 62 claims from the claims phase

**Phase 1 — Preparation:** Auto-detected `corporate-visions` arc from generic research type, confirmed with user

**Phase 2 — Per-Dimension:** 5 insight summaries (1,450-1,900 words each) in `synthesis/<dimension-slug>/`, each tracing claims back to scored sources

**Phase 3 — Cross-Dimensional:** 1 `research-hub.md` (~2,000-2,500 words) weaving cross-cutting themes across all dimensions, surfacing contradictions and convergences

**Phase 4 — Finalization:** Sources README, Claims README generated; sprint-log updated with `synthesis_complete: true`

## Prerequisites

1. **Verify project exists**: Confirm the project directory and `.metadata/sprint-log.json` are present. If the path doesn't exist, ask the user for the correct path.

2. **Check claims completed**: Read `.metadata/sprint-log.json` and confirm `claims_complete: true`. If false, tell the user to run `claims` first.

3. **Verify entity directories**: Dimensions in `01-research-dimensions/data/`, findings in `04-findings/data/`, sources in `05-sources/data/`, and claims in `06-claims/data/` must each contain at least one entity.

## Resumption

If a previous synthesis run was interrupted, check the filesystem before re-executing:

1. List subdirectories in `synthesis/` — each dimension that completed has an `insight-summary.md`
2. Check if `synthesis/cross-dimensional/insight-summary.md` exists
3. Read `synthesis_complete` from sprint-log

Resumption logic:
- **FULL_RUN** — `synthesis/` directory empty or absent. Start from Phase 1.
- **RESUME_DIMENSIONS** — some dimension `insight-summary.md` files exist but not all. Skip completed dimensions in Phase 2, resume for the missing ones. Phase 1 (arc selection) can be recovered from sprint-log `arc_id` if previously saved.
- **RESUME_CROSS** — all dimension summaries exist but `cross-dimensional/insight-summary.md` is missing. Skip to Phase 3.
- **COMPLETE** — `synthesis_complete: true` in sprint-log. Inform the user synthesis already finished; offer to re-run if requested.

## Selective Execution

If the user asks to synthesize only specific dimensions (e.g., "just synthesize dimensions 1 and 3"), this is valid but has tradeoffs. Before proceeding:

1. **Warn about narrative coherence**: The cross-dimensional narrative will have gaps — cross-cutting themes may be incomplete, and contradictions between included and excluded dimensions won't surface. Make sure the user understands this.
2. **Get explicit confirmation**: Ask the user to confirm they accept partial synthesis.
3. **Filter dimensions**: In Phase 2, only process requested dimensions. Skip others entirely.
4. **Adjust cross-dimensional output**: In Phase 3, the cross-dimensional narrative should explicitly note which dimensions are included and flag that coverage is intentionally partial.
5. **Record in sprint-log**: `partial_scope: {included_dimensions: [1, 3], excluded_dimensions: [2, 4, 5], reason: "user request"}` so downstream consumers know coverage is intentionally partial.

## Workflow

### Phase 1: Preparation

Arc selection shapes the entire narrative structure — choosing the wrong arc produces a technically correct but strategically misaligned story. A competitive analysis framed through a technology-futures arc buries the positioning insights that matter most. Getting this right means the difference between a report stakeholders act on and one they file.

1. **Locate project**: Use project-picker if not specified by the user.
2. **Load dimensions**: Read all dimension entities from `01-research-dimensions/data/`.
3. **Load research metadata**: Read `.metadata/sprint-log.json` for `research_type`, `research_question`, `project_language`.
4. **Determine arc**: Auto-detect from `research_type` or ask the user.
   For arc recommendations by research type, see [references/arc-selection-guide.md](references/arc-selection-guide.md).
5. **Confirm arc with user** via AskUserQuestion: "Which narrative arc should we use for synthesis?" Present the auto-detected recommendation and alternatives.
6. **Save preparation state**: Record `arc_id` in sprint-log so resumption can recover the selection.

### Phase 2: Per-Dimension Narratives (Parallel)

Each dimension gets its own focused narrative because synthesis quality degrades when an LLM tries to weave too many threads simultaneously. Per-dimension narratives let cogni-narrative concentrate on one coherent story at a time, producing tighter prose with better source attribution. The compression from ~30 claims to ~1,700 words forces prioritization — only the strongest, best-sourced claims survive into the narrative.

For each dimension (parallel execution via Task tool):

1. **Gather dimension content**: Trace the entity reference chain to collect all evidence for this dimension.

   The chain works like this: dimension → questions → findings → claims/sources. Specifically:
   - Read refined questions from `02-refined-questions/data/` where `dimension_ref` wikilinks to this dimension
   - Read findings from `04-findings/data/` where `question_ref` wikilinks to one of those questions
   - Read claims from `06-claims/data/` where `finding_refs` array contains wikilinks to those findings
   - Read sources from `05-sources/data/` where `finding_refs` array contains wikilinks to those findings

2. **Prepare content directory**: Write `<project>/synthesis/<dimension-slug>/content.md` — the structured input that cogni-narrative's narrative-writer expects.

   Example `content.md`:
   ```markdown
   # Dimension: AI/ML Techniques & Maturity

   AI and machine learning approaches used in drug discovery, including their current
   maturity levels and adoption rates across the pharmaceutical industry.

   ## Key Findings

   ### Finding: Deep learning outperforms traditional docking in hit identification
   AI-driven virtual screening identifies viable drug candidates 4-10x faster than
   traditional high-throughput screening methods, with higher hit rates in early stages.

   ### Finding: AlphaFold has transformed structure-based drug design
   Protein structure prediction accuracy has reached experimental levels, reducing
   the need for costly X-ray crystallography in early-stage target validation.

   ## Top Claims (by confidence)

   1. **[0.92]** AI-driven virtual screening reduces hit identification time by 60-75%
      compared to traditional HTS methods. *Source: Nature Reviews Drug Discovery (tier-1)*
   2. **[0.88]** AlphaFold2 predictions match experimental structures within 1.5Å RMSD
      for 95% of human proteome targets. *Source: Science (tier-1)*
   3. **[0.85]** Pharmaceutical companies using ML in lead optimization report 30-40%
      reduction in preclinical failure rates. *Source: McKinsey & Company (tier-2)*

   ## Source Attribution

   | Publisher | Reliability | Findings Supported |
   |-----------|------------|-------------------|
   | Nature Reviews Drug Discovery | tier-1 | 4 |
   | Science | tier-1 | 2 |
   | McKinsey & Company | tier-2 | 3 |
   ```

3. **Invoke cogni-narrative**: Delegate to `cogni-narrative:narrative-writer` agent:
   ```
   --source-path <project>/synthesis/<dimension-slug>/
   --arc-id <selected-arc>
   --language <project-language>
   --output-path <project>/synthesis/<dimension-slug>/insight-summary.md
   --research-question "<dimension description>"
   ```

4. **Validate output**: Confirm `insight-summary.md` was created with valid frontmatter and is within the expected word count range (1,450-1,900 words).

5. **Save dimension state**: After each dimension completes, record it in sprint-log `completed_dimensions` array so resumption knows which are done.

### Phase 3: Cross-Dimensional Narrative

The cross-dimensional narrative is the crown deliverable. It weaves per-dimension insights into a single coherent story that answers the original research question. This is where contradictions between dimensions surface and where the highest-value cross-cutting themes emerge — patterns no single dimension could reveal on its own.

1. **Gather all dimension narratives**: Read each `synthesis/<dimension-slug>/insight-summary.md`.

2. **Prepare cross-dimensional content**: Write summary at `<project>/synthesis/cross-dimensional/content.md`.
   Include:
   - Research question (from sprint-log)
   - All dimension narrative summaries (opening paragraphs)
   - Cross-cutting themes (claims that appear across multiple dimensions)
   - Overall confidence statistics (average `final_confidence` across all claims)

3. **Invoke cogni-narrative**: Delegate to `cogni-narrative:narrative-writer` agent:
   ```
   --source-path <project>/synthesis/cross-dimensional/
   --arc-id <selected-arc>
   --language <project-language>
   --output-path <project>/research-hub.md
   --research-question "<original research question>"
   ```

4. **Quality review**: Invoke `cogni-narrative:narrative-reviewer` on `research-hub.md`. Check for: coherence across dimensions, source attribution coverage, balanced representation of all dimensions, and that the original research question is clearly addressed.

### Phase 4: Finalization

Finalization creates the provenance artifacts that make the research auditable. Without the source and claims READMEs, the narrative stands alone without a clear evidence trail — stakeholders can read the story but cannot verify it.

For script arguments and output formats, see [references/script-reference.md](references/script-reference.md).

1. **Generate sources README**: Read the project language from `.metadata/sprint-log.json`, then run:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-sources-readme.sh --project-path <path> --language <code> --json
   ```

2. **Generate claims README**: Run:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-claims-readme.sh --project-path <path> --language <code> --json
   ```

3. **Update sprint-log**: Set `synthesis_complete: true`, record `arc_id`, `dimension_count`, and `updated_at` to current ISO 8601 timestamp. For selective execution, also record `partial_scope`. See [references/script-reference.md](references/script-reference.md) for the full list of sprint-log fields written by synthesis.

4. **Report to user**: Total dimensions synthesized, word counts per narrative, arc used, and overall confidence statistics.

## Output Structure

```
<project>/
├── synthesis/
│   ├── <dimension-1-slug>/
│   │   ├── content.md          # Prepared input for cogni-narrative
│   │   └── insight-summary.md  # Dimension narrative (1,450-1,900 words)
│   ├── <dimension-2-slug>/
│   │   ├── content.md
│   │   └── insight-summary.md
│   └── cross-dimensional/
│       ├── content.md
│       └── insight-summary.md
├── research-hub.md             # Cross-dimensional narrative (copy of cross-dimensional/insight-summary.md)
├── 05-sources/README.md        # Source inventory
└── 06-claims/README.md         # Claim inventory
```

## Error Recovery

| Scenario | What to Do |
|----------|------------|
| Project path does not exist | Ask the user for the correct path. Do not guess or create a new project. |
| Claims not yet complete | Tell the user to run `claims` first. Do not proceed with synthesis. |
| cogni-narrative agent fails for a dimension | Check `.logs/narrative-writer/` for the dimension slug. Re-invoke for that dimension only. |
| Cross-dimensional narrative fails | Verify all dimension `insight-summary.md` files exist. If any are missing, re-run Phase 2 for those dimensions first. |
| Arc not recognized by cogni-narrative | Fall back to `corporate-visions` (default arc). Inform the user. |
| Dimension has zero claims | Generate the dimension narrative from findings only. Note reduced confidence in the narrative frontmatter. |
| Resumption detected | Scan `synthesis/` directory for existing `insight-summary.md` files. Skip completed dimensions. |
| `generate-sources-readme.sh` or `generate-claims-readme.sh` fails | Check script output JSON for error details. Verify entity directories are not empty. Re-run the script. |

## Completion

Synthesis is complete when:
- Sprint-log shows `synthesis_complete: true`
- Every in-scope dimension has an `insight-summary.md` in `synthesis/<dimension-slug>/`
- `research-hub.md` exists in the project root
- Sources README generated in `05-sources/`
- Claims README generated in `06-claims/`

After synthesis completes, the research pipeline is finished. Derivative formats (executive briefs, talking points, one-pagers) are available via `cogni-narrative:narrative-adapt` — run it on any `insight-summary.md` or `research-hub.md` produced by this skill. For data export, use the `research-data-export` skill.
