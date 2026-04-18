---
id: workflow-trends-to-solutions
title: "Workflow: Trends to Solutions (trends → portfolio → visual)"
type: summary
tags: [workflow, trends, solutions, portfolio, tips, value-modeler]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/trends-to-solutions.md
status: stable
related: [plugin-cogni-trends, plugin-cogni-portfolio, plugin-cogni-visual, concept-trends-portfolio-bridge]
---

Turn scouted trends into ranked solution blueprints with visual deliverables.

## Pipeline

```
cogni-trends:trend-scout                  (60 scored candidates per dimension)
   ↓ scored candidates
cogni-trends:value-modeler                (TIPS network + investment themes + solution templates)
   ↓ tips-value-model.json
cogni-portfolio:trends-bridge             (import templates as portfolio features)
   ↓ portfolio features + propositions
cogni-visual:story-to-slides | enrich-report   (visual deliverables)
   ↓
slide deck or enriched HTML report
```

## Duration

4–8 hours for a complete trends-to-solutions analysis.

## End deliverable

Ranked solution blueprints with visual deliverables (slide deck or enriched HTML report).

## How it works

[[plugin-cogni-trends]] runs `trend-scout` to surface 60 scored trend candidates across the 4 Smarter Service Trendradar dimensions. Candidates are sourced strictly from web research — no padding from LLM training knowledge. The trend-candidate-reviewer applies stakeholder review ([[concept-quality-gates]]) before promotion.

`value-modeler` then takes agreed candidates and builds the TIPS network: **T**rends → **I**mplications → **P**ossibilities → **S**olutions. Solution templates are ranked by Business Relevance (BR) score and bundled into investment themes (Handlungsfelder).

The bridge to [[plugin-cogni-portfolio]] is the most complex single integration in the ecosystem — see [[concept-trends-portfolio-bridge]]. `tips-value-model.json` flows from cogni-trends to cogni-portfolio; `portfolio-context.json` flows back. cogni-portfolio's `trends-bridge` skill imports solution templates as portfolio features and stubs the matching FxM propositions.

[[plugin-cogni-visual]] renders deliverables — `story-to-slides` for a CxO presentation, `enrich-report` for a themed HTML report with Chart.js visualizations of the TIPS network and BR scoring.

## Where TIPS comes from

The TIPS framework comes with cogni-trends — Trends, Implications, Possibilities, Solutions — and is the canonical structure for investment theme reports. See [[plugin-cogni-trends]] for framework details.

**Source**: [docs/workflows/trends-to-solutions.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/trends-to-solutions.md)
