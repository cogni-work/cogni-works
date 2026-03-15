---
name: research-plan
description: |
  Plan and structure a research project — from initial question to query batches ready for parallel execution.
  This is the FIRST skill in the 4-stage pipeline (research-plan > findings-sources > claims > synthesis).
  Use when the user says "research [topic]", "investigate [subject]", "start research on [topic]",
  "plan research", "create a research plan", "deep dive into [topic]", "analyze [industry/market]",
  "understand [market/technology]", "explore [subject]", "I want to learn about [topic]",
  "what do we know about [topic]", "research strategy for [topic]", "help me research [topic]",
  or wants to do market analysis, competitive analysis, business model validation, industry analysis,
  technology assessment, or portfolio analysis. Also trigger when the user has a broad question they
  want broken into structured research dimensions, or when they want to prepare a systematic
  investigation before gathering evidence. Supports generic, lean-canvas, and b2b-ict-portfolio
  research types.
---

# Research Plan

Transform a research question into a structured, executable plan. Everything downstream — findings, claims, synthesis — depends on the quality of what this skill produces. A well-planned project produces focused dimensions, sharp questions, and optimized search queries that minimize noise and maximize insight coverage.

## Quick Example

**User says:** "Research the impact of AI on pharmaceutical drug discovery"

**Phase 0:** Generic research type, DOK-3 (strategic thinking — requires multi-source synthesis)

**Phase 1 — refined question:** "How are AI/ML techniques (molecular simulation, target identification, clinical trial optimization) changing drug discovery timelines, costs, and success rates for pharmaceutical companies, and what organizational capabilities are needed to capture this value?"

**Phase 2 — 5 MECE dimensions:**
1. AI/ML Techniques & Maturity
2. Drug Discovery Pipeline Impact
3. Organizational & Talent Requirements
4. Regulatory & Ethical Landscape
5. Competitive Dynamics & Market Structure

28 refined PICOT questions across dimensions

**Phase 3:** 28 query batches, ~140 total search configurations ready for parallel execution

## Prerequisites

- A research question or topic from the user
- A workspace directory (detected automatically or specified)

If the workspace is missing, ask the user where to create the project or default to `~/research-projects`.

## Resumption

If working in a project directory that already has files from a previous run, check what exists before re-executing phases:

1. Check `00-initial-question/data/` — if it has files, Phase 0-1 are done.
2. Check `01-research-dimensions/data/` and `02-refined-questions/data/` — if populated, Phase 2 is done.
3. Check `03-query-batches/data/` — if populated and `planning_complete: true` in sprint-log, planning is fully done. Proceed to findings-sources.
4. If `.metadata/sprint-log.json` exists but `planning_complete` is false or missing, resume from the first incomplete phase.

## Workflow

### Phase 0: Project Initialization

Research type determines the entire downstream dimension strategy — getting it wrong means the wrong framework for the whole project.

1. **Detect research type** from user's request. If ambiguous, ask via AskUserQuestion.
   For routing details see `${CLAUDE_PLUGIN_ROOT}/references/research-type-routing.md`.

2. **Determine output language** (en/de): ask user or detect from workspace config. Default to `en` if no preference or config exists.

3. **Initialize project** via `initialize-research-project.sh`.
   For script arguments and output format see [references/script-reference.md](references/script-reference.md).

4. **Verify** the project directory exists with all entity subdirectories before proceeding.

### Phase 1: Question Refinement

This is the highest-leverage phase. A vague question cascades into vague dimensions, noisy findings, and weak claims. Investing time here pays compound dividends through every downstream phase.

1. **Refine the research question** with the user. A good question is:
   - **Specific** — names the domain, population, or technology
   - **Scoped** — has clear temporal, geographic, or domain boundaries
   - **Decomposable** — can break into 2-10 independent dimensions
   - **Answerable** — evidence exists or can be gathered via web search

   For examples and the DOK classification framework see [references/question-quality-guide.md](references/question-quality-guide.md).

2. **Classify DOK level.** Auto-determined for lean-canvas (DOK-2) and b2b-ict-portfolio (DOK-3). Ask the user for generic type. DOK controls dimension count and question depth downstream.

3. **Create initial question entity** via `create-entity.sh --entity-type 00-initial-question`.
   For frontmatter fields see [references/script-reference.md](references/script-reference.md).

4. **Confirm with user** before proceeding. Present a summary using this format:

   ```
   **Research Plan Summary**
   - Research type: <generic|lean-canvas|b2b-ict-portfolio>
   - DOK level: <1-4> (<Recall|Skills|Strategic|Extended>)
   - Language: <en|de>
   - Refined question: "<the refined question>"
   - Expected output: ~<N> dimensions, ~<M> questions, ~<M×5> search queries

   Shall I proceed with dimensional planning?
   ```

### Phase 2: Dimensional Planning

Dimensions partition the research topic into independent, non-overlapping areas. MECE (Mutually Exclusive, Collectively Exhaustive) dimensions ensure complete coverage without redundant search work — overlapping dimensions waste agent time searching for the same information twice, while gaps create blind spots in the final synthesis.

1. **Route by research type:**
   - **generic / lean-canvas:** Invoke dimension-planner agent via Task tool with: project path, research_type, DOK level, initial question path.
   - **b2b-ict-portfolio:** Uses pre-defined portfolio dimensions from the cogni-portfolio plugin. If cogni-portfolio is not installed, fall back to generic with DOK-3 and inform the user.

2. **Verify output against DOK bounds:**

   | DOK | Dimensions | Questions/Dim (min) | Total Questions |
   |-----|-----------|---------------------|-----------------|
   | 1   | 2-3       | 4                   | 8-12            |
   | 2   | 3-4       | 5                   | 15-20           |
   | 3   | 5-7       | 5                   | 25-35           |
   | 4   | 8-10      | 5                   | 40-50           |

   Check: dimension count is within DOK range, each dimension has at least the minimum questions, total question count is within DOK range. If any check fails, re-run dimension-planner with adjusted guidance.

3. **Present dimensions to user** for review. If the user rejects them:
   - Ask which dimensions to add, remove, or rename
   - Explain your rationale for proposed dimensions (coverage argument)
   - Re-run dimension-planner with adjusted guidance if needed

### Phase 3: Batch Creation

Each refined question becomes one self-contained query batch, enabling findings-sources to execute them in parallel across independent agents.

1. **Create batches** — choose the approach based on DOK level:

   **DOK-1 (fast path):** For simple retrieval research (8-12 questions), create batches inline instead of spawning the batch-creator agent. For each question, generate 3-4 short keyword queries (general + market + industry profiles) and create the batch entity via `create-entity.sh --entity-type 03-query-batches`. This avoids the agent startup overhead that dominates when question count is low — users asking "just the facts" expect fast results.

   **DOK 2-4 (full path):** Invoke batch-creator agent via Task tool with: project path, list of refined questions. The agent creates one query batch per refined question in `03-query-batches/data/`, each containing 4-7 optimized search configurations with adaptive profile selection.

2. **Verify output:**
   - Batch count equals refined question count exactly (no missing, no orphans)
   - Each batch contains 3-7 search configurations (3-4 for DOK-1, 4-7 for DOK 2+)
   - Each batch has valid query strings (non-empty, no placeholder text)

3. **Mark planning complete** by updating the sprint-log:

   ```bash
   cd <project-path>
   jq '.planning_complete = true | .updated_at = (now | todate)' .metadata/sprint-log.json > .metadata/sprint-log.tmp && mv .metadata/sprint-log.tmp .metadata/sprint-log.json
   ```

4. **Report to user** with a structured completion summary:

   ```
   **Research Planning Complete**
   - Refined question: "<the refined question>"
   - Dimensions: <N> (<list of dimension names>)
   - Questions: <M> across <N> dimensions
   - Query batches: <M> batches, <total configs> search configurations
   - Sample questions:
     1. "<first question from first dimension>"
     2. "<first question from middle dimension>"
     3. "<first question from last dimension>"

   Next step: run `findings-sources` to execute parallel web search.
   ```

## Error Recovery

| Scenario | What to Do |
|----------|------------|
| dimension-planner returns < 2 dimensions | Re-examine the question — consider broadening scope or raising DOK level. Re-run dimension-planner. |
| Dimension/question count outside DOK bounds | Adjust DOK level or re-run dimension-planner with explicit count guidance. |
| User rejects dimensions | Ask which to add/remove/rename. Provide coverage rationale. Re-run with adjusted guidance. |
| batch-creator fails for some questions | Check `.logs/batch-creator/` for details. Re-run for failed questions only. |
| Project init script fails | Verify `CLAUDE_PLUGIN_ROOT` is set and directory is writable. |
| b2b-ict-portfolio without cogni-portfolio | Fall back to generic with DOK-3. Inform user that full portfolio taxonomy requires the cogni-portfolio plugin. |

## Completion

Planning is complete when:
- Sprint-log shows `planning_complete: true`
- All refined questions have corresponding query batches in `03-query-batches/data/`

After research-plan completes, run the `findings-sources` skill to execute parallel web search and source extraction.
