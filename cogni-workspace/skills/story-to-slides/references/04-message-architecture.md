# Message Architecture for Presentations

## Purpose

Define how to transform a narrative's content into slide-level messages using the Pyramid Principle, one-message-per-slide discipline, MECE grouping, consolidation strategies, and logical sequencing. This is the bridge between understanding the story arc (Step 3) and writing slide copy (Step 5).

## Core Principle

> A presentation is a pyramid, not a stream.
> The audience should understand the full argument from the titles alone.

---

## Step 4a: Build the Pyramid Structure

### Level Mapping

| Pyramid Level | Presentation Element | Content |
|---------------|---------------------|---------|
| **Top** | Title slide subtitle | Governing thought — the one thing the audience should remember |
| **Arguments** | Section dividers (if needed) or slide groups | 3-5 MECE argument claims |
| **Evidence** | Individual slides | One message per slide, supported by data/visuals |

### Applying Pyramid to Different Arc Types

| Arc Type | Pyramid Pattern | Typical Arguments |
|----------|----------------|-------------------|
| `why-change` | GT: "[Customer] must [action] to [outcome]" | A1: Crisis/Problem → A2: Urgency → A3: Solution → A4: Investment |
| `problem-solution` | GT: "[Solution] solves [problem] with [result]" | A1: Problem scope → A2: Solution approach → A3: Proof/benefits |
| `journey` | GT: "[Achievement] in [timeframe]" | A1: Starting point → A2: Key milestones → A3: Results/lessons |
| `argument` | GT: "[Recommendation] because [reasons]" | A1: Argument 1 → A2: Argument 2 → A3: Argument 3 |
| `report` | GT: "[Key finding] with [implication]" | A1: Finding 1 → A2: Finding 2 → A3: Recommendations |

### Edge Cases

```text
PROBLEM: Narrative has only 2 clear arguments
  → Check if one argument can be split (e.g., "Solution" → "Capability" + "Proof")
  → If not, 2 arguments is acceptable for short decks (5-7 slides)

PROBLEM: Narrative has 6+ potential arguments
  → Look for arguments that can be merged (e.g., two similar evidence themes)
  → Apply MECE: are any overlapping? Merge overlaps.
  → Target 3-5 arguments for audience retention

PROBLEM: Sections don't clearly map to arguments
  → Return to Step 3c and re-examine section role assignments
  → The issue is usually at the role level, not the pyramid level
```

---

## Step 4b: Extract One Message Per Slide

### The Rule

Every slide must have exactly **ONE message** — a single sentence that captures what the audience should take away. This sentence becomes the slide title (assertion headline).

### Split vs. Combine Decision Logic

Message extraction often requires deciding whether narrative content becomes one slide or multiple. Reason through each decision:

```text
REASON through split/combine decisions:

  QUESTION 1: Does the section contain 2+ INDEPENDENT claims?
    → Independent means: each claim could stand alone as a slide
    → "Revenue grew 23% AND customer satisfaction hit 95%"
      These are independent metrics → SPLIT into two slides
    → "Revenue grew 23% driven by enterprise adoption"
      Growth and driver are one claim → KEEP as one slide

  QUESTION 2: Is the section evidence-heavy for a SINGLE claim?
    → "688 deaths + 2,661 attacks + 42% outdated systems + €2.8M costs"
      All prove ONE claim (crisis) → Evaluate:
        - Are they parallel metrics? → COMBINE into four-quadrants
        - Do they build on each other? → one stat-card, others to notes

  QUESTION 3: Is the section too thin for a standalone slide?
    → A section with one sentence and no supporting data
    → COMBINE with adjacent section that makes the same argument

  QUESTION 4: Does splitting improve the audience's understanding?
    → If the audience needs to absorb each claim separately → SPLIT
    → If claims are stronger presented together → COMBINE
    → Rule of thumb: split when claims serve different arguments,
      combine when claims reinforce the same argument
```

### Message Extraction Templates

For each section role, use these patterns to extract the message:

```text
ROLE → MESSAGE PATTERN:

  hook      → "[Shocking number/statement] — [consequence]"
  problem   → "[Metric] [problem verb] [affected entity]"
  urgency   → "Every [period], [cost/risk accumulates]" or "[Deadline] demands [action]"
  evidence  → "[Data point] proves [claim]" or "[N] of [M] [finding]"
  solution  → "[Solution] [achievement verb] [quantified result]"
  proof     → "[Customer/pilot] achieved [result] in [timeframe]"
  options   → "[N] [strategies/options] from [range]"
  roadmap   → "[Timeline] from [start] to [end] in [N] phases"
  investment → "[Investment] returns [multiplier/savings] in [timeframe]"
  call-to-action → "[Action verb] [specific next step] [this timeframe]"
```

---

## Step 4c: Consolidation

### When to Consolidate

Consolidation is needed when message extraction produces more slides than `max_slides`. This is common — a 20-page narrative easily produces 18-25 potential slide messages, but a deck should rarely exceed 12-15 slides.

**Why the default limit is 15:** Audience attention declines measurably after 15-20 minutes of continuous presentation. At roughly 90-120 seconds per slide, 15 slides fills a 20-25 minute slot. Longer decks either rush through slides (undermining comprehension) or run over time (losing the audience). The `max_slides` parameter reflects this attention window — it is a presentation design constraint, not an arbitrary formatting rule.

### Consolidation Priority Order

Apply in this order (least destructive first, most aggressive last):

```text
Priority 1: MERGE parallel evidence
  WHAT: Multiple statistics about the same argument → one combined slide
  WHEN: 2+ slides present parallel data points for one argument
  HOW: Combine into four-quadrants (4 stats) or stat-card (2-3 stats)
  EXAMPLE: 4 separate crisis stats → one four-quadrants slide
  REASONING: Parallel data is STRONGER presented together. Merging
    actually IMPROVES the slide, not weakens it.

Priority 2: MERGE argument + evidence
  WHAT: An argument slide followed by its evidence slide → one slide
  WHEN: The argument claim and its proof can fit in one layout
  HOW: Use assertion headline (claim) + body (evidence)
  EXAMPLE: "Costs are rising" + "€2.8M in emergency operations" → single stat-card
  REASONING: The audience doesn't need the claim and proof on separate slides
    when the proof IS the claim.

Priority 3: PROMOTE to speaker notes
  WHAT: Detail that supports a slide but isn't essential for visual display
  WHEN: A slide has more context than fits visually
  HOW: Move supporting detail to Speaker-Notes "WHAT YOU NEED TO KNOW" section
  EXAMPLE: Methodology details, secondary citations, background context
  REASONING: The detail is preserved (presenter can reference it) but doesn't
    consume a slide. Best of both worlds.

Priority 4: CUT redundant proof
  WHAT: When multiple slides prove the same point, keep the strongest
  WHEN: Two or more slides make equivalent claims with different data
  HOW: Keep the slide with the best data (Tier 1 > Tier 2 > Tier 3)
  EXAMPLE: 3 case studies → keep the one with best numbers, note others in speaker notes
  REASONING: One strong proof point beats three moderate ones. Redundancy
    doesn't persuade — it fatigues.

Priority 5: CUT background context
  WHAT: Information the audience already knows or that sets up without advancing
  WHEN: Slides exist purely to "orient" rather than argue
  HOW: Remove entirely or merge key points into adjacent slide
  EXAMPLE: Industry overview for industry experts
  REASONING: Expert audiences resent being told what they already know.
    Background slides waste the attention budget.

Priority 6: COMPRESS closing
  WHAT: Merge multiple ending slides into fewer
  WHEN: "Next steps" + "timeline" + "call to action" are separate slides
  HOW: Combine into one closing-slide + one roadmap slide maximum
  EXAMPLE: Timeline → 4 steps instead of 6, next steps → merged into CTA
  REASONING: The ending should be sharp and actionable, not drawn out.
```

### Consolidation Decision Process

```text
REASON through each consolidation decision:

  FOR each candidate pair/group to consolidate:

    1. What ARGUMENT do these slides serve?
       → Same argument: safe to merge (evidence reinforces)
       → Different arguments: DO NOT merge (loses pyramid structure)

    2. Does merging STRENGTHEN or WEAKEN the message?
       → Parallel stats combined into quadrant: STRENGTHENS
       → Two case studies merged: WEAKENS (lose specificity)
       → Argument + proof into one slide: NEUTRAL to STRONG

    3. What does the audience LOSE if this slide disappears?
       → A unique data point not available elsewhere: HIGH LOSS → protect
       → A repetition of a point made elsewhere: LOW LOSS → cut
       → Context that helps understanding: MEDIUM LOSS → promote to notes

    4. Is this in the PROTECTED list?
       → If yes: DO NOT consolidate, find another candidate
```

### Audience-Aware Consolidation (Rich Mode)

When the Audience Model is Rich mode (from Step 2.5), consolidation decisions factor in the primary decision-maker's priorities:

```text
IF Audience Model mode == rich:
  1. IDENTIFY slides whose message aligns with primary_decision_maker.top_priority
     → These slides are added to the PROTECTED list
     → They may still be MERGED (Priority 1-2) but never CUT (Priority 4-5)

  2. WHEN choosing between two candidates to cut:
     → Prefer cutting the slide LESS aligned with primary decision-maker's priorities
     → This ensures the deck stays relevant to the person who approves the deal

IF Audience Model mode == lean:
  → Standard consolidation (no change from current behavior)
```

### What to NEVER Cut

```text
PROTECTED CONTENT (never remove during consolidation):
  - The governing thought (pyramid apex)
  - The strongest statistic in EACH argument (at least one hero number per argument)
  - The call to action (final slide)
  - Power Position slides (IS-DOES-MEANS) — these are pre-optimized
  - Solution overview slide (why-change arc — orients audience before Power Positions; uses `solution` role)
  - Any slide with confidence > 0.9 from layout mapping
  - The FIRST evidence slide for each argument (need at least 1 proof per claim)
  - Slides aligned with primary decision-maker's top priority (Rich mode only — from Audience Model)
```

### Consolidation Log

Track what was merged or cut for transparency:

```text
Consolidation Applied: Yes
  - Merged: Slides 3-4 (crisis stats) → four-quadrants layout [Priority 1]
  - Promoted to notes: Research methodology (Section 2) [Priority 3]
  - Cut: Background industry overview (redundant for audience) [Priority 5]
  - Compressed: Timeline 6→4 steps, next steps merged into CTA [Priority 6]
  - Original message count: 18 → Final slide count: 12
  - Protected: Governing thought, hero stats (688, €2.8M, 97%), CTA, 3 Power Positions
```

---

## Step 4d: MECE Verification and Sequencing

### MECE Gate

Before sequencing, verify the slide set against the two MECE conditions. Both are
gates on this deck, not an explanation of MECE:

```text
MUTUALLY EXCLUSIVE: no two slide messages make the same claim.
  → FIX if violated: merge the pair, or re-extract one against a different
    argument from Step 4a.

COLLECTIVELY EXHAUSTIVE: the arguments from Step 4a are each supported, and
together they establish the governing thought with no gap.
  → FIX if violated: an argument with no supporting slide is either
    unsupported evidence in the narrative (cut the argument) or a section
    that was consolidated away in Step 4c (restore it).
```

---

## Slide Sequencing

After MECE verification, arrange slides in the optimal order for the detected arc type.

### Flow Templates by Arc Type

**Why Change:**
```text
Title → Problem → Urgency → Solution Overview → Power Positions (×N) → Investment → CTA
```

**Problem-Solution:**
```text
Title → Problem → Scale/Impact → Solution → Benefits → Proof → CTA
```

**Journey:**
```text
Title → Starting Point → Milestone 1 → Milestone 2 → Current State → Lessons → Next
```

**Argument:**
```text
Title → Thesis → Arg1 + Evidence → Arg2 + Evidence → Arg3 + Evidence → Conclusion → CTA
```

**Report:**
```text
Title → Executive Summary → Finding 1 → Finding 2 → Finding 3 → Recommendations → Next Steps
```

### Sequencing Rules

```text
RULE 1: Problem before solution
  → The audience must feel the pain before hearing the cure
  → WHY: A solution presented before the problem feels like a sales pitch.
    A solution presented after the problem feels like a rescue.
  → FIX if violated: Move all problem/urgency slides before the first
    solution slide.

RULE 2: Evidence close to its claim
  → Don't separate a statistic from the argument it supports
  → WHY: If 3 slides pass between a claim and its proof, the audience
    forgets the claim. Evidence is only powerful when adjacent to its claim.
  → FIX if violated: Reorder so each argument is immediately followed
    by its evidence.

RULE 3: Build tension, then release
  → Problem/urgency slides build tension
  → Solution/proof slides release it
  → WHY: The audience's emotional state must peak at the problem and
    resolve at the solution. If proof comes before solution, confidence
    is built for nothing. If urgency comes after solution, it undermines
    the answer already given.
  → FIX if violated: Reorder so tension builds (problem → urgency →
    evidence), then releases (solution → proof → CTA).

RULE 4: Strongest evidence first within each argument
  → Lead with the most impactful data point
  → WHY: Attention declines slide by slide. Put the best number first
    while attention is highest. Weaker evidence after strong evidence
    feels like a graceful wind-down, not a letdown.
  → FIX if violated: Reorder evidence slides within each argument by
    impact strength (Tier 1 before Tier 2).

RULE 5: End with action, not information
  → The last slide should drive behavior, not present data
  → WHY: The audience's final impression determines whether they act.
    Ending with data makes them think. Ending with a CTA makes them move.
  → FIX if violated: Ensure the closing-slide is ALWAYS last.
    If "next steps" precedes the CTA, merge them.
```

---

## Message Quality Checklist

Before finalizing slide messages, verify each one passes the quality gate:

```text
PER-SLIDE CHECK:
  □ Is it ONE sentence? (not two claims joined by "and" — if "and" joins
    independent claims, SPLIT the slide)
  □ Does it contain a verb? (active voice: "reduces", "enables",
    not "reduction of" — passive headlines lose 40% of impact)
  □ Does it include a number or specific claim? (where data exists —
    "23% growth" not "significant growth")
  □ Is it an assertion, not a topic? ("Revenue Grew 23%" not "Revenue Overview"
    — topic labels communicate nothing)
  □ Does it connect to the governing thought? (if removed, would the
    governing thought lose support?)
  □ Would the audience understand it without seeing the slide body?
    (the headline alone must carry the message)
  □ Is it under 60 characters? (fits on one title line without wrapping)
```

```text
FULL DECK CHECK (read ALL messages in sequence):
  □ Do the titles tell the complete story? (read only titles — is the
    argument clear without any slide body?)
  □ Are they MECE? (no two say the same thing, together they cover
    the full argument without gaps)
  □ Does the sequence follow the arc? (problem before solution,
    evidence after claim, CTA at end)
  □ Is there a clear call to action in the final message?
  □ Does the emotional arc work? (tension builds, peaks, then resolves)
```
