---
name: diamond-develop
description: |
  Execute the Develop phase of a Double Diamond engagement — diverge to generate and explore
  solution options. Dispatches to cogni-tips value-modeler and cogni-portfolio for proposition
  modeling, and guides scenario planning and option development.
  Use whenever the user mentions "generate options", "develop solutions", "explore alternatives",
  "option generation", "scenario planning", "develop phase", "solution space",
  or wants to create and evaluate solution options — even if they don't say "develop" explicitly.
---

# Diamond Develop — Diverge to Create Options

Generate and explore solution options that address the problem statement from Define. This is the first phase of Diamond 2 — the goal is to create a rich option space before converging on the best path in Deliver.

## Core Concept

Develop is the creative engine of the engagement. With a clear problem statement and HMW questions from Define, this phase generates multiple possible solutions — not just the obvious one. Good consulting surfaces options the client hadn't considered, challenges "we've always done it this way" thinking, and creates genuine strategic choices.

The key principle: **generate before evaluating**. Premature evaluation kills creativity. Develop creates the option space; Deliver evaluates it.

## Prerequisites

- Define phase should be complete (problem statement and HMW questions exist)
- Read `define/problem-statement.md` and `define/hmw-questions.md` as the brief for this phase

## Workflow

### 1. Load Context

Read diamond-project.json, `define/problem-statement.md`, and `define/hmw-questions.md`.

Update phase state:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" develop in-progress
```

### 2. Propose Develop Methods

Read `$CLAUDE_PLUGIN_ROOT/references/vision-classes.md` for the vision class's recommended Develop methods.

**Plugin-powered methods**:

| Method | Plugin | What It Produces |
|---|---|---|
| Value modeling | cogni-tips | TIPS paths from trends to solutions, ranked by business relevance |
| Proposition modeling | cogni-portfolio | IS/DOES/MEANS messaging for Feature × Market pairs |
| Solution design | cogni-portfolio | Implementation phases and pricing tiers |

**Guided methods**:

| Method | What It Produces | Reference |
|---|---|---|
| Scenario planning | 2-4 future scenarios with implications | `references/methods/scenario-planning.md` |
| Opportunity scoring | Scored option matrix with criteria | `references/methods/opportunity-scoring.md` |

Ask: "Which methods do you want for option generation? I recommend [2-3 based on vision class]. You can adjust."

### 3. Value Modeling (cogni-tips)

If the engagement has a tips project from Discovery (check `plugin_refs.tips_project`):

1. Dispatch `cogni-tips:value-modeler` on the existing trend candidates
2. The value modeler translates trend candidates into TIPS paths (Trend → Implication → Possibility → Solution)
3. Solutions are ranked by business relevance score
4. Store value model outputs in `develop/options/tips-solutions.md`

If no tips project exists, offer to run `trend-scout` first or skip this method.

### 4. Proposition Modeling (cogni-portfolio)

If the engagement has a portfolio project (check `plugin_refs.portfolio_project`):

1. Ensure features and markets are defined (from Discovery competitive baseline)
2. Dispatch `cogni-portfolio:propositions` for Feature × Market pairs
3. Each proposition generates IS (what it is), DOES (what advantage it creates), MEANS (what benefit the buyer gets)
4. Optionally dispatch `cogni-portfolio:solutions` for implementation phasing
5. Store proposition summaries in `develop/propositions/`

If no portfolio exists, offer to set one up or skip.

### 5. Scenario Planning (Guided)

Read `$CLAUDE_PLUGIN_ROOT/references/methods/scenario-planning.md` and guide the consultant:

1. Identify 2 critical uncertainties from the problem statement
2. Create a 2×2 matrix using these uncertainties as axes
3. Name and describe 4 resulting scenarios
4. For each scenario, assess: implications for the client, required capabilities, risk profile
5. Map existing options from value modeling against scenarios

Save to `develop/scenarios/scenario-matrix.md`.

### 6. Option Synthesis

After all methods complete, synthesize the options:

1. Consolidate solutions from TIPS value modeling, portfolio propositions, and scenario analysis
2. Group into 3-7 distinct strategic options
3. For each option, capture:
   - **Name**: Short, descriptive label
   - **Description**: What this option entails
   - **Source**: Which method surfaced it (TIPS, portfolio, scenario)
   - **Alignment**: Which HMW question(s) it addresses
   - **Key assumptions**: What must be true for this to work
4. Present the option space to the consultant for review

Save to `develop/options/option-synthesis.md`.

Do NOT evaluate or rank options here — that's Deliver's job. Present them as equals.

### 7. Log and Transition

Update method log and decision log.

Present the Develop summary:

> **Develop phase complete.**
> - TIPS solutions generated: N (top 3: ...)
> - Propositions modeled: N Feature × Market pairs
> - Scenarios mapped: 4 (2×2 matrix)
> - Strategic options synthesized: N
>
> Ready to move to Deliver? The final phase will evaluate options, verify claims, build the business case, and generate deliverables.

Mark Develop complete:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" develop complete
```

## Method Adaptation by Vision Class

- **strategic-options** → all methods, emphasis on option diversity
- **business-case** → proposition modeling + scenario planning (fewer options, deeper financial modeling in Deliver)
- **gtm-roadmap** → proposition modeling + opportunity scoring (channel/segment focus)
- **cost-optimization** → opportunity scoring (cost reduction levers) + scenario planning (implementation risk)
- **digital-transformation** → all methods (wide option space needed for transformation)
- **innovation-portfolio** → value modeling emphasis (TIPS horizons map to innovation portfolio)
- **market-entry** → scenario planning (market uncertainty) + proposition modeling (value fit)

## Important Notes

- Resist the temptation to evaluate during generation — keep divergent
- If only 1-2 options emerge, the divergence was insufficient — probe for alternatives
- Scenario planning is particularly valuable for high-uncertainty vision classes
- Record why certain options were generated (the reasoning, not just the option)
- Cross-reference: if a TIPS solution and a portfolio proposition point to the same thing, note the convergence — it's a signal of robustness
