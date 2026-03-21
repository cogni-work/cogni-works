---
name: canvas-refine
description: |
  Critique and improve an existing Lean Canvas section by section.
  This skill should be used when the user mentions "refine my canvas", "improve the canvas",
  "review my lean canvas", "canvas feedback", "strengthen my business model",
  "critique my canvas", "canvas is weak", "update the canvas", "evolve the canvas",
  "version my canvas", "pivot my canvas", "iterate on my canvas", "test assumptions",
  "is my canvas any good", "what's weak in my canvas",
  "challenge my assumptions", "poke holes in my business model", or has an existing
  canvas file they want to make better — even if they don't say "refine" explicitly.
  Also trigger when the user opens or references a lean canvas markdown file and asks
  for feedback, improvements, or simply says "look at this canvas" or "what do you think
  of my canvas". If the user says "pivot" in the context of a business model, use this skill.
allowed-tools: Read, Write, Edit, Glob, Grep
argument-hint: "<path to existing canvas file>"
---

# Refine a Lean Canvas

Critique an existing Lean Canvas and guide the user through improving it. Produces a new version with tracked changes in the evolution log.

## Format

Follow the file format specified in `$CLAUDE_PLUGIN_ROOT/references/canvas-format.md` for structure, frontmatter, and versioning rules.

## Workflow

### 1. Load the Canvas

Read the canvas file. If the user doesn't provide a path, search the workspace for lean canvas files:

```
Glob: **/*canvas*.md
```

If the file lacks YAML frontmatter, infer section status and note that frontmatter will be added on save.

### 2. Assess Current State

Produce a diagnostic overview:

**Section Health**

| Section | Status | Strength | Issue |
|---|---|---|---|
| Problem | filled | specific, measurable | Could add cost-of-inaction |
| Customer Segments | filled | well-segmented | Missing market size estimates |
| UVP | filled | clear | Too long — not a single sentence |
| Key Metrics | unfilled | — | Needs definition |
| ... | ... | ... | ... |

**Coherence Check** — flag misalignments between sections (consult the interdependency table in `$CLAUDE_PLUGIN_ROOT/references/lean-canvas-sections.md`):
- Does the solution address the stated problems?
- Does the UVP speak to the primary segment's pain?
- Do revenue streams match what segments would pay for?
- Are channels realistic for reaching the defined segments?

**Maturity Assessment** — classify the canvas stage:
- **Draft**: Many unfilled or vague sections
- **Hypothesis**: All sections filled, untested
- **Validated**: Some assumptions tested with evidence
- **Evolved**: Multiple versions with data-driven changes

#### Example: Diagnostic Summary

> Your canvas is at **Hypothesis** stage — all 9 sections are filled, but none have been tested yet.
>
> **Strongest sections**: Problem (specific, quantified pain) and Customer Segments (clear beachhead market with budget signal).
>
> **Weakest section**: UVP — it reads like a feature list ("AI-powered automated proposal tool with templates and analytics") rather than a differentiator. Your segments aren't choosing between AI tools; they're choosing between hiring a proposal writer, using a template, or your product.
>
> **Coherence gap**: Your revenue model says "per-seat SaaS" but your customer segment is agencies with 3-5 people — per-seat pricing penalizes small teams, which is your primary segment. Consider per-project or flat-rate pricing.
>
> Want to fix the UVP first, or tackle the pricing misalignment?

Present the diagnostic to the user and ask: refine specific sections, or work through all issues systematically?

### 3. Refine Sections

For each section being refined, apply the quality criteria and guiding questions from `$CLAUDE_PLUGIN_ROOT/references/lean-canvas-sections.md`.

**Refinement approach per section**:

1. **State what's strong** — acknowledge what works before critiquing
2. **Identify the gap** — be specific about what's missing or weak
3. **Suggest concrete improvements** — offer draft text, not just advice
4. **Ask for input** — the user knows their business better than any model
5. **Check ripple effects** — when a section changes, flag dependent sections that may need updating (e.g., changing Problem from "slow reporting" to "inaccurate reporting" means Solution, UVP, and Key Metrics all need review — consult the interdependency table)

**For unfilled sections** ("?" or empty):
- Ask focused questions to elicit content (2-3 questions, not a checklist)
- Offer hypotheses based on other sections ("Given your solution targets X, your key metric might be Y — does that resonate?")

**For draft sections** (vague or incomplete):
- Push for specificity: numbers, names, timelines
- Challenge assumptions: "How do you know customers will pay €15k?"
- Suggest structure: bullets, tiers, layers

**For filled sections** (substantive content):
- Stress-test coherence with other sections
- Check for common pitfalls specific to that section type
- Suggest sharpening, not rewriting

### 4. Track Changes

Every refinement — whether applied to the file or proposed in a report — must include version tracking. This is true even when the user asks for a review without modifying the canvas: propose the version bump and draft the evolution log entry so the user can apply it.

**When writing changes to the canvas file:**

1. Update the section content in the canvas
2. Bump the `version` number in frontmatter
3. Update the `updated` date
4. Update per-section `status` fields
5. Append a new entry to the Canvas Evolution log:

```markdown
### Version N — [Title summarizing the change]
**Date**: YYYY-MM-DD
**Key Insight**: What prompted this revision
**Changes**: What changed and why
```

6. Update Key Assumptions to Validate if new assumptions emerged
7. Update Next Iterations based on current state

**When producing a report without modifying the file:**

Still include a "Proposed Changes" section with:
- The version bump (e.g., "v1 → v2")
- A draft evolution log entry the user can paste in
- Updated status fields for any sections that would change (e.g., "filled → draft" if a weakness was surfaced)

### 5. Save and Summarize

Write the updated canvas file. Present a change summary:

| Section | Before | After | Change |
|---|---|---|---|
| UVP | draft | filled | Shortened to single sentence, segment-specific variants added |
| Key Metrics | unfilled | draft | Added 3 initial metrics |
| ... | ... | ... | ... |

**Version**: v1 -> v2
**Key insight**: [What drove this iteration]

Suggest next steps based on current maturity:

- **Draft → Hypothesis**: "N sections still unfilled — fill them next"
- **Hypothesis → Validated**: Present the validation pathway below to help the user test their riskiest assumptions with the right tools
- **Validated → Evolved**: "Consider refining based on: [market feedback, stress-test findings, competitive shifts]"

#### Validation Pathway (Hypothesis → Validated)

When a canvas reaches Hypothesis maturity (all sections filled, nothing tested), the next step is validating the riskiest assumptions. Route each assumption type to the appropriate downstream skill:

| Assumption Type | Validate With | What It Provides |
|---|---|---|
| Market size claims | `cogni-portfolio:markets` | TAM/SAM/SOM sizing with web research |
| Competitive landscape | `cogni-portfolio:compete` | Competitor mapping, positioning, battle cards |
| Segment definition | `cogni-portfolio:portfolio-canvas` → `markets` | Extract market entities from canvas, then validate segmentation |
| Pricing assumptions | `cogni-portfolio:solutions` | Solution pricing with cost modeling |
| Multi-perspective critique | `cogni-canvas:canvas-stress-test` | 4-persona parallel stress test (investor, customer, technical, operations) |

**Suggested sequence**: Start with `cogni-canvas:canvas-stress-test` to identify which assumptions are weakest across perspectives, then use the targeted portfolio skills to validate the highest-risk ones with real data.

## Refinement Modes

Detect the mode from the user's request and follow the appropriate structure. The mode determines which workflow steps to use — not every mode needs a full diagnostic.

- **Full review** (default): Run the full workflow — Section Health table, Coherence Check, Maturity Assessment, section-by-section refinement. Use when the user says "review my canvas", "refine my canvas", or gives no specific focus.
- **Section focus**: Skip the Section Health table. Start with a brief maturity assessment (one sentence establishing canvas stage and what's filled vs. unfilled) for context, then jump straight to the requested section(s), applying the refinement approach from Step 3. Still include a brief coherence check against adjacent sections and flag ripple effects. Use when the user names specific sections ("refine my UVP", "help me fill in Solution and Channels").
- **Coherence pass**: Skip the Section Health table and section-by-section refinement. Focus exclusively on cross-section alignment using the interdependency table. Output a list of misalignments with severity (CRITICAL/HIGH/MODERATE/LOW), affected sections, and fix recommendations. Use when the user says "check coherence", "are my sections aligned", "consistency check".
- **Assumption audit**: Skip the Section Health table entirely — do not include it. The primary structure is an assumptions inventory, not a diagnostic. Extract every implicit assumption, tag each with its source section, assign a risk level (CRITICAL/HIGH/MODERATE/LOW), and include a testability assessment with a concrete validation method. Follow with a coherence check (misalignments often reveal hidden assumptions). Use when the user says "assumption audit", "test assumptions", "challenge my assumptions", "what am I assuming".

The key distinction: full review leads with section-by-section quality assessment, while assumption audit and coherence pass lead with cross-cutting analysis. Mixing modes (e.g., putting a Section Health table in an assumption audit) dilutes the focus the user asked for.

**Coherence pass example**: "Your Problem says 'agencies waste time on proposals' but your Channels section lists 'LinkedIn ads targeting enterprise procurement teams.' If your customer is small agencies, LinkedIn ads targeting enterprise buyers won't reach them. Either the channel or the segment needs to change."

**Assumption audit example**: "Your canvas contains at least 3 untested assumptions: (1) agencies spend 60-80 hrs/month on proposals — have you validated this? (2) they'd pay €99/month — based on what anchor? (3) 'word of mouth' as primary channel — do agency owners actually recommend tools to each other? I'd prioritize #1 since the entire value prop rests on it."

## Important Notes

- Read the existing canvas before suggesting changes — skipping this and guessing at content undermines trust immediately, since the user knows what they wrote and will notice if you get it wrong
- Present suggestions as options, not mandates — the user owns the business model
- Track every change in the evolution log — canvas history is valuable
- A section downgraded from "filled" to "draft" is fine if it surfaces a real weakness
- Preserve all evolution log entries — the history of *why* the canvas changed is often more valuable than the current version. Teams revisit evolution logs when pivoting to understand which assumptions failed and why
- When the user disagrees with a critique, respect their judgment and note the reasoning in the evolution log
