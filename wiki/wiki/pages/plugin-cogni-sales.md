---
id: plugin-cogni-sales
title: "cogni-sales (plugin)"
type: entity
tags: [cogni-sales, plugin, sales, pitch, why-change, corporate-visions, b2b, bilingual]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-sales/README.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-sales.md
status: stable
---

> **Preview** (v0.4.1) — core skills defined but may change.

B2B sales pitch generation using Corporate Visions Why Change methodology. Creates sales presentations and proposals for named customers (deal-specific) or market segments (reusable). Builds on cogni-portfolio data with optional TIPS strategic enrichment. Bilingual DE/EN.

## Layer

[[concept-four-layer-architecture|Output layer]]. Reads cogni-portfolio entities and produces customer-facing pitches.

## Skills

| Skill | Purpose |
|-------|---------|
| `cogni-sales:why-change` | Create a Why Change sales pitch for a named customer (deal) or a reusable segment pitch for a market |

## Why Change methodology

The Corporate Visions arc structures every pitch as **Why Change → Why Now → Why You → Why Pay**:

- **Why Change** — surface the buyer's status quo cost (loss aversion as a buying motivator)
- **Why Now** — sharpen urgency with timing-specific evidence
- **Why You** — differentiate against the buyer's likely alternatives
- **Why Pay** — justify investment with quantified business case

The arc is implemented as a structural template in cogni-narrative; cogni-sales dispatches narrative composition and then renders to slide + proposal deliverables.

## Two pitch types

- **Customer-specific (deal pitch)** — for a named account; researches the customer's specific context, decision makers, and current state
- **Segment-reusable (segment pitch)** — for a market segment; reusable across many accounts in the same Feature × Market combination

## Outputs

`sales-presentation.md` (slide narrative) and `sales-proposal.md` (long-form proposal). Both pass through cogni-copywriting for Power Positions polish before final rendering.

## Integration

Upstream: cogni-portfolio (Feature × Market propositions, customer profiles, competitor analysis), cogni-trends (optional TIPS enrichment for Why Now urgency). Downstream: cogni-narrative (Why Change arc composition), cogni-copywriting (polish), cogni-visual (slide rendering), cogni-claims (auto-logged sourced claims in pitches).

**Source**: [cogni-sales README](https://github.com/cogni-work/insight-wave/blob/main/cogni-sales/README.md) · [plugin guide](https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-sales.md)
