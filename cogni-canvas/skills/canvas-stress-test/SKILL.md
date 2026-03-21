---
name: canvas-stress-test
description: >-
  Multi-persona stress test of a Lean Canvas from investor, customer,
  technical, and operations perspectives. Use this skill when the user wants
  to pressure-test their canvas, get multi-perspective feedback, simulate
  stakeholder reactions, or challenge their business model assumptions before
  committing resources. Triggers include "stress-test my canvas",
  "what would an investor think", "test my assumptions", "challenge my canvas",
  "would customers actually buy this", "is this buildable", "do the numbers work",
  "stakeholder review of canvas", "poke holes in my business model",
  "canvas stress test", "review canvas from different perspectives",
  or any request for rigorous multi-angle canvas evaluation — even if they
  don't say "stress test" explicitly.
allowed-tools: Read, Write, Edit, Glob, Grep, Task
argument-hint: "<path to canvas file>"
---

# Canvas Stress-Test

Run a Lean Canvas through parallel persona-based evaluation to surface blind spots that a single-perspective review would miss. Each persona reads the canvas and evaluates it against 5 weighted criteria specific to their role, then a synthesis step identifies cross-cutting themes and prioritizes improvements.

This skill is complementary to `canvas-refine` — use canvas-refine for conversational section-by-section critique; use canvas-stress-test when you want a rigorous, structured, multi-perspective assessment.

## Workflow

### Step 1: Load the Canvas

Read the canvas file from the provided path argument.

If no path is provided, search the workspace:
```
Glob: **/*canvas*.md
```

If multiple canvas files exist, ask which one to stress-test.

Verify the file has the expected lean canvas structure (9 numbered sections). If YAML frontmatter is missing, infer section status using the rules in `../../references/canvas-format.md`.

### Step 2: Select Personas

Four built-in personas are available:

| Persona | Perspective | Reference |
|---|---|---|
| **Investor** | Fundability — market, economics, defensibility | `references/personas/investor.md` |
| **Target Customer** | Desirability — problem fit, willingness to pay, switching costs | `references/personas/target-customer.md` |
| **Technical Co-founder** | Buildability — feasibility, architecture, MVP scope | `references/personas/technical-cofounder.md` |
| **Operations & Finance** | Viability — costs, margins, operational scaling | `references/personas/operations-finance.md` |

**Default**: Run all 4 personas. If the user requests a subset (e.g., "just the investor view"), run only those.

**Single-persona mode**: When the user's phrasing implies a single perspective (e.g., "what would an investor think"), run only that persona. In single-persona mode:
- Skip the persona selection confirmation — the user's intent is clear
- In Step 4 (synthesis), omit Cross-Cutting Themes (cross-cutting requires 2+ perspectives)
- Instead, expand the single persona's output: add a "Deeper Analysis" subsection with 2-3 additional observations that go beyond the 5 standard criteria
- The Validation Roadmap and Suggested Next Steps still apply — scope them to the single persona's concerns

**Multi-persona mode**: Present the persona selection to the user before launching:
> "I'll stress-test this canvas from 4 perspectives: Investor, Target Customer, Technical Co-founder, and Operations/Finance. Each will evaluate against 5 criteria. Want all four, or a specific subset?"

### Step 3: Launch Parallel Persona Analysis

Launch one Task agent per selected persona. Each agent reads the canvas file, its persona profile, and the section reference via file paths.

**For each persona, launch a Task with this prompt:**

```
You are a {PERSONA_NAME} evaluating a Lean Canvas. Read the files below, then evaluate the canvas strictly from your perspective.

FILES TO READ (use Read tool):
1. Canvas: {path to canvas file}
2. Your persona profile: {absolute path to references/personas/{persona}.md}
3. Section reference: {absolute path to ../../references/lean-canvas-sections.md}

INSTRUCTIONS:
1. Read all 3 files
2. Adopt the tone described in your persona profile — each persona has a distinct voice
3. Evaluate each of your 5 criteria, assigning PASS / WARN / FAIL
4. For each criterion, provide specific evidence from the canvas (quote or reference the relevant section)
5. Calculate your weighted score: PASS=1.0, WARN=0.5, FAIL=0. Multiply each verdict by criterion weight and sum
6. Generate 3-5 questions that a real {PERSONA_NAME} would ask after reading this canvas
7. Identify the single most important improvement from your perspective
8. List 2-3 key assumptions you'd want validated (brief — the synthesis step will deduplicate and route these)

OUTPUT FORMAT (Markdown):

## {PERSONA_NAME} Evaluation

### Criteria Assessment

| Criterion | Weight | Verdict | Evidence |
|---|---|---|---|
| {criterion 1} | {weight}% | {PASS/WARN/FAIL} | {specific evidence from canvas} |
| ... | ... | ... | ... |

**Score**: {weighted score}/1.0 — {count PASS} pass, {count WARN} warn, {count FAIL} fail

### Top Questions
1. {Question a real stakeholder would ask}
2. ...

### Critical Improvement
{The single most important thing to fix, with specific suggestion}

### Key Assumptions
- {Assumption} — {one-line rationale}
- ...
```

**Agent configuration:**
- Model: use a fast model (haiku or sonnet) for parallel efficiency
- Tools: Read (to access the canvas file if needed)
- Launch all persona agents in the same turn for parallel execution

### Step 4: Synthesize Results

Once all persona agents return, synthesize their findings using the protocol in `references/synthesis-protocol.md`.

**Process:**

1. **Collect all persona results** into a combined view
2. **Identify cross-cutting themes** using semantic matching — group concerns that target the same underlying canvas weakness regardless of how each persona frames it
3. **Apply priority escalation** — 3+ personas on same issue → CRITICAL; 2 personas → HIGH; customer + any other → CRITICAL
4. **Route themes to canvas sections** — every finding must map to one or more of the 9 sections so the user knows exactly what to revise
5. **Resolve conflicts** using the tiebreaker hierarchy (customer > investor > technical > operations)
6. **Merge recommendations** by section, keeping the highest priority from any contributing persona
7. **Separate "fix in canvas" from "validate externally"** — some issues are text improvements; others need real-world data

### Step 4b: Wild-Card Risks

After synthesizing persona findings, step back and identify 2-3 risks that fall **outside** the persona criteria but would matter to the canvas author. These are things the structured evaluation might miss because no persona's criteria explicitly cover them.

Examples of wild-card risks:
- Licensing or regulatory risks (e.g., AGPL deterring enterprise buyers)
- Adoption barriers from the product's UX or technical interface (e.g., CLI tools for non-developer users)
- Concentration risks (e.g., breadth vs. depth when resources are limited)
- Ecosystem or platform dependencies not captured by any single persona
- Market timing risks (too early, too late, regulatory shifts)

Include these as a brief "Wild-Card Risks" section in the report, after Cross-Cutting Themes. Each risk should be 1-2 sentences with a concrete suggestion.

### Step 5: Present the Report

Output the stress-test report using the structure defined in `references/synthesis-protocol.md` (Output Structure section).

The report includes:
- Per-persona score tables with weighted scores (PASS/WARN/FAIL per criterion + weighted score out of 1.0)
- Cross-cutting themes ranked by priority (CRITICAL → HIGH → OPTIONAL, max 3 per level)
- Wild-card risks (2-3 risks outside persona criteria)
- Prioritized questions the canvas should be able to answer but can't
- Validation roadmap mapping deduplicated assumptions to downstream skills
- Suggested next steps based on canvas maturity

**Keep the report actionable.** Every finding should either:
- Point to a specific canvas section to improve, with a concrete suggestion, OR
- Point to a downstream skill for external validation (e.g., `cogni-portfolio:markets` for market sizing)

### Step 6: Apply Improvements (Optional)

If the user wants to apply improvements based on the stress-test:

1. Confirm which recommendations to apply (present as checklist, not mandates)
2. Edit the canvas sections as confirmed
3. Bump the `version` number in frontmatter
4. Update `updated` date
5. Update per-section `status` fields if warranted
6. Append an evolution log entry:

```markdown
### Version N — Stress-Test Refinement
**Date**: {today}
**Key Insight**: Multi-persona stress test revealed {summary of top finding}
**Changes**: {what changed and why, noting which persona perspectives drove each change}
**Personas consulted**: {list}
```

7. Update Key Assumptions to Validate with any newly surfaced assumptions
8. Save the updated canvas

## Important Notes

- The stress-test is deliberately structured and parallel — it trades the conversational back-and-forth of canvas-refine for breadth of perspective. For deep dive on a specific section, use `canvas-refine` instead.
- Persona evaluations should be honest, even if harsh. A canvas with multiple FAIL ratings is getting valuable signal — it means the hypothesis needs work before resources are committed.
- The target-customer persona is the most important for early-stage canvases. If a canvas passes the customer test but fails the investor test, it may still be worth pursuing. The reverse is rarely true.
- Don't fabricate market data or competitive intelligence during the stress test. If a persona identifies a gap (e.g., "market size is unknown"), the right response is to flag it for validation via `cogni-portfolio:markets`, not to invent numbers.
- For canvases at Draft maturity (many unfilled sections), the stress test will produce mostly FAIL results. This is expected and useful — it shows the user exactly which sections need attention first. Consider suggesting `canvas-refine` to fill gaps before running another stress test.
