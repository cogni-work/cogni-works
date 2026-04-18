---
id: workflow-portfolio-to-pitch
title: "Workflow: Portfolio to Pitch (portfolio → sales → visual)"
type: summary
tags: [workflow, sales, pitch, why-change, portfolio]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/portfolio-to-pitch.md
status: stable
related: [plugin-cogni-portfolio, plugin-cogni-sales, plugin-cogni-visual]
---

Generate a deal-specific or segment-reusable sales pitch from existing portfolio data.

## Pipeline

```
cogni-portfolio                            (Feature × Market propositions, customers, competitors)
   ↓ portfolio entities
cogni-sales:why-change                     (Corporate Visions arc composition)
   ↓ sales-presentation.md + sales-proposal.md
cogni-visual:story-to-slides → render-html-slides   (slide rendering)
   ↓
PPTX deck + proposal document
```

## Duration

3–6 hours for a complete deal-specific pitch deck.

## End deliverable

A customer-tailored sales presentation in PPTX format, with a supporting proposal document.

## How it works

Pre-requisite: [[plugin-cogni-portfolio]] has populated the relevant Feature × Market intersection (proposition with IS/DOES/MEANS, customer profile for the buyer, competitive analysis against likely alternatives). See [[concept-data-model-patterns]] for the FxM join.

[[plugin-cogni-sales]] composes the pitch using the Corporate Visions Why Change arc:

- **Why Change** — surface the buyer's status quo cost (loss aversion)
- **Why Now** — sharpen urgency with timing-specific evidence
- **Why You** — differentiate against the buyer's likely alternatives (pulled from cogni-portfolio's competitive analysis)
- **Why Pay** — justify investment with quantified business case (pulled from cogni-portfolio's solution pricing tiers)

Output: `sales-presentation.md` (slide narrative) and `sales-proposal.md` (long-form). Both pass through [[plugin-cogni-copywriting]] for Power Positions polish before final rendering.

Final hop through [[plugin-cogni-visual]] turns the slide narrative into a brief and renders to HTML slides or PPTX. See [[concept-brief-based-rendering]].

## Two pitch modes

- **Deal-specific** — for a named account; `why-change` researches the customer's specific decision makers and current state
- **Segment-reusable** — for a market segment; reusable across many accounts in the same Feature × Market

**Source**: [docs/workflows/portfolio-to-pitch.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/portfolio-to-pitch.md)
