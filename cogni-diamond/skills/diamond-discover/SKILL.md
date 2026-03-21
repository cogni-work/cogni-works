---
name: diamond-discover
description: |
  Execute the Discover phase of a Double Diamond engagement — diverge to build a rich
  understanding of the problem landscape. Dispatches to cogni-gpt-researcher, cogni-tips,
  and cogni-portfolio for structured research, trend scouting, and competitive analysis.
  Use whenever the user mentions "start discovery", "discover phase", "research the landscape",
  "explore the problem", "diverge", "build understanding", or wants to begin the first
  diamond phase — even if they don't say "discover" explicitly.
---

# Diamond Discover — Diverge to Understand

Build a rich, multi-perspective understanding of the problem landscape. This is the first phase of Diamond 1 — the goal is to cast a wide net before converging on a problem statement in the Define phase.

## Core Concept

Discover is about breadth, not depth. The consultant and client often arrive with assumptions about what the problem is. This phase deliberately widens the lens — through desk research, trend analysis, competitive mapping, stakeholder input, and data audits — to surface insights that challenge or enrich those initial assumptions.

The key principle: **diverge before converging**. Premature closure is the enemy of good consulting. Discover builds the evidence base that Define will synthesize.

## Prerequisites

- An active diamond engagement (diamond-project.json exists). If not, suggest `diamond-setup`.
- Read the engagement's vision class and scope from diamond-project.json — they determine which methods are most relevant.

## Workflow

### 1. Load Engagement Context

Read diamond-project.json. Extract: engagement name, vision class, desired outcome, scope, constraints, industry, language.

Update phase state to in-progress:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" discover in-progress
```

### 2. Propose Discovery Methods

Read `$CLAUDE_PLUGIN_ROOT/references/vision-classes.md` for the vision class's recommended Discover methods. Also read any method files referenced.

Present the proposed discovery plan, typically 3-5 activities:

**Plugin-powered methods** (automated via cogni-work ecosystem):

| Method | Plugin | What It Produces |
|---|---|---|
| Desk research | cogni-gpt-researcher | Research report with cited sources |
| Industry trend scan | cogni-tips | 60 trend candidates across 4 dimensions × 3 horizons |
| Competitive baseline | cogni-portfolio | Competitor landscape and market segmentation |

**Guided methods** (interactive prompts with consultant):

| Method | What It Produces |
|---|---|
| Stakeholder mapping | Influence/interest matrix, interview agenda |
| Data audit | Available data inventory, quality assessment, gaps |
| Customer journey analysis | As-is journey map with pain points |

Ask: "Which methods do you want to use for Discovery? I recommend all plugin-powered methods plus [1-2 guided methods based on vision class]. You can add, remove, or reorder."

### 3. Execute Plugin Methods

For each confirmed plugin method, dispatch to the appropriate plugin:

**Desk Research (cogni-gpt-researcher)**:
- Frame the research topic from the engagement's desired outcome and scope
- Suggest report type: `detailed` for most vision classes, `deep` for digital-transformation or innovation-portfolio
- Recommend market setting matching the engagement scope
- After research completes, store the project path in `plugin_refs.research_project`
- Copy or symlink the research output summary to `discover/research/`

**Industry Trend Scan (cogni-tips)**:
- Frame the industry from the engagement context
- Dispatch `trend-scout` with the industry and language settings
- After scouting completes, store the project path in `plugin_refs.tips_project`
- Copy or symlink the trend summary to `discover/trends/`

**Competitive Baseline (cogni-portfolio)**:
- If a portfolio project doesn't exist yet, run `portfolio-setup` with the client context
- Then dispatch `portfolio-scan` or `compete` depending on scope
- Store the project path in `plugin_refs.portfolio_project`
- Copy or symlink competitive summary to `discover/competitive/`

Between each plugin dispatch, check with the consultant: "Research complete. Review before moving to trend analysis?"

### 4. Execute Guided Methods

For each confirmed guided method, read the method file from `$CLAUDE_PLUGIN_ROOT/references/methods/` and walk the consultant through it interactively.

**Stakeholder Mapping** (`references/methods/stakeholder-mapping.md`):
- Guide the consultant through identifying stakeholders
- Build an influence/interest matrix together
- Draft interview questions aligned to the engagement vision
- Save outputs to `discover/stakeholder-map.md`

**Data Audit** (`references/methods/data-audit.md`):
- Inventory available data sources with the consultant
- Assess quality, recency, and relevance
- Identify critical gaps
- Save outputs to `discover/data-audit.md`

### 5. Synthesize Discovery

After all methods complete, produce a discovery synthesis:

1. Read all outputs in `discover/` (research summary, trend candidates, competitive data, stakeholder map, data audit)
2. Identify 5-10 key themes that emerge across sources
3. Note surprises — findings that challenge initial assumptions
4. Flag tensions — contradictions or trade-offs between sources
5. Write `discover/synthesis.md` capturing themes, surprises, and tensions

Present the synthesis to the consultant for review and refinement.

### 6. Log Methods and Transition

Update the method log:

```bash
# For each method used, append to .metadata/method-log.json
```

Update `diamond-project.json` with any new `plugin_refs`.

Ask the consultant: "Discovery phase complete. The synthesis surfaces [N] key themes. Ready to converge in the Define phase, or do you want to explore any theme further?"

If ready to converge, mark Discover complete and suggest `diamond-define`:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" discover complete
```

## Method Adaptation

The methods above are recommendations, not requirements. Based on the vision class and emerging findings:

- **strategic-options** → emphasize competitive baseline and trend scan
- **business-case** → emphasize desk research and data audit
- **gtm-roadmap** → emphasize competitive baseline and customer journey
- **cost-optimization** → emphasize data audit and stakeholder mapping
- **digital-transformation** → emphasize all sources (wide divergence needed)
- **innovation-portfolio** → emphasize trend scan (deep mode) and stakeholder mapping
- **market-entry** → emphasize desk research (market-specific) and competitive baseline

## Important Notes

- Never auto-advance to Define without consultant confirmation
- Keep plugin dispatch sequential by default (research → trends → competitive) to allow findings from each to inform the next
- If a plugin method fails or produces thin results, note the gap and continue — the Define phase can work with incomplete information
- Update diamond-project.json after each significant step
- **Communication Language**: Use the engagement's language setting for all interactions
