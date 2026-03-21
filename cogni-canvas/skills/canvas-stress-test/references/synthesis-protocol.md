---
title: Canvas Stress-Test Synthesis Protocol
version: 1.0
---

# Synthesis Protocol

## Purpose

Transform multi-persona canvas feedback into a prioritized, actionable improvement plan. Identify cross-cutting themes across personas, resolve conflicts, and route validated assumptions to the appropriate downstream skills.

## Theme Identification Rules

### Priority Escalation

| Pattern | Priority |
|---------|----------|
| 3+ personas flag same issue | CRITICAL |
| 2 personas flag same issue | HIGH |
| Customer + 1 other on same issue | CRITICAL (customer voice carries extra weight for early-stage canvases) |
| Any persona labels FAIL on ≥20% criterion | CRITICAL |
| Single persona, high-weight criterion (≥25%) | HIGH |
| Single persona, low-weight criterion (≤15%) | OPTIONAL |

### Semantic Matching

Group concerns that target the same underlying canvas weakness, regardless of how each persona frames it:
- "Market too vague" = "Can't estimate TAM" = "Don't know who the customer is" → Canvas Section: Customer Segments
- "Pricing unjustified" = "Wouldn't pay this" = "No unit economics" → Canvas Sections: Revenue Streams + Cost Structure
- "Solution too broad" = "Can't build this in 90 days" = "Feature laundry list" → Canvas Section: Solution
- "No real moat" = "Competitor could replicate in 6 months" = "First mover isn't an advantage" → Canvas Section: Unfair Advantage

### Section Routing

Every synthesized theme must map to one or more of the 9 canvas sections. This makes the output directly actionable — the user knows exactly which section to revise.

| Theme Category | Primary Section | Also Check |
|---|---|---|
| Market/sizing issues | Customer Segments | Revenue Streams |
| Pricing/economics issues | Revenue Streams | Cost Structure |
| Solution scope issues | Solution | Problem, Key Metrics |
| Defensibility issues | Unfair Advantage | Solution |
| Reachability issues | Channels | Customer Segments |
| Feasibility issues | Solution | Cost Structure |
| Viability issues | Cost Structure | Revenue Streams |

## Conflict Resolution

### Common Canvas Conflicts

| Conflict | Resolution |
|----------|------------|
| Customer wants simplicity vs. Investor wants scale | Customer wins at Hypothesis stage; rebalance at Validated stage when market data exists |
| Technical says "too complex to build" vs. Customer says "need all of it" | Scope to MVP that addresses #1 problem for #1 segment; defer the rest |
| Investor wants big market vs. Operations wants focused execution | Both can be right — start with beachhead segment (operations) within a large addressable market (investor) |
| Finance says "price too low" vs. Customer says "wouldn't pay more" | Test willingness to pay; canvas should explicitly state the pricing assumption and how it will be validated |

### Tiebreaker Hierarchy

When personas disagree and no resolution is obvious:

1. **Target Customer perspective** — the canvas exists to serve customers; their reality is ground truth
2. **Investor perspective** — if the market isn't real or the economics don't work, nothing else matters
3. **Technical Co-founder perspective** — if it can't be built, the rest is fiction
4. **Operations/Finance perspective** — viability constraints refine the plan but don't veto it at hypothesis stage

## Recommendation Merging

1. Group recommendations by canvas section (use section routing table)
2. Within each section, assign merged priority (highest from any contributing persona)
3. Combine specific actions into a single actionable recommendation per section
4. Track which personas contributed to each recommendation
5. Distinguish between "fix in canvas" (content improvement) and "validate externally" (needs research/data)

## Assumption Validation Routing

When synthesis identifies assumptions that can't be resolved by improving the canvas text alone, route them to the appropriate downstream skill:

| Assumption Type | Route To | What It Provides |
|---|---|---|
| "Is the market big enough?" | `cogni-portfolio:markets` | TAM/SAM/SOM with web research |
| "Who are the real competitors?" | `cogni-portfolio:compete` | Competitive landscape mapping |
| "Do customers actually have this problem?" | Customer discovery (manual) | Interview evidence |
| "Can we build this?" | Technical spike (manual) | Feasibility proof |
| "Will the pricing work?" | `cogni-portfolio:solutions` | Solution pricing with cost modeling |
| "Is the market well-defined enough for portfolio work?" | `cogni-portfolio:portfolio-canvas` | Entity extraction from canvas |

## Output Structure

The synthesis output is a Markdown report (not JSON) structured as follows:

```markdown
## Stress-Test Summary

**Personas**: [list of personas used]
**Canvas maturity**: [Draft / Hypothesis / Validated / Evolved]
**Overall assessment**: [1-2 sentence verdict]

### Per-Persona Scores

| Persona | Score | Strongest | Weakest |
|---|---|---|---|
| Investor | PASS: 2, WARN: 2, FAIL: 1 | Team-Market Fit | Market Sizing |
| ... | ... | ... | ... |

### Cross-Cutting Themes

#### CRITICAL
- **[Theme name]** (Personas: investor, customer) → Section: [X]
  - [Specific finding and recommended action]

#### HIGH
- ...

#### OPTIONAL
- ...

### Prioritized Questions

The top questions your canvas should be able to answer but currently can't:
1. [Question] — raised by [persona(s)]
2. ...

### Validation Roadmap

Assumptions that need external validation (not just canvas text improvement):
1. [Assumption] → validate with `[skill]`
2. ...

### Suggested Next Steps

Based on canvas maturity and stress-test results:
- [Ordered list of recommended actions]
```
