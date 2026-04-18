---
id: workflow-research-to-report
title: "Workflow: Research to Report (wiki → research → claims → copywriting → visual)"
type: summary
tags: [workflow, research, report, claims, polish, visual]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/research-to-report.md
status: stable
related: [plugin-cogni-research, plugin-cogni-claims, plugin-cogni-wiki, plugin-cogni-visual]
---

Produce a verified, polished research report as a themed visual deliverable.

## Pipeline

```
cogni-wiki                              (optional knowledge-base source mode)
   ↓ wiki context
cogni-research:research-report          (multi-agent STORM-inspired editorial workflow)
   ↓ report.md
cogni-claims:claims                     (verify cited sources, flag deviations)
   ↓ verified report.md
cogni-copywriting:copywriter            (polish prose)
   ↓ polished report.md
cogni-visual:enrich-report              (themed HTML with Chart.js + inline SVG)
   ↓
themed HTML report + optional one-page infographic
```

## Duration

10 min – 4 hours depending on research depth, claims volume, and visual enrichment.

## End deliverable

A verified, polished research report as themed HTML with data visualizations — plus an optional one-page infographic.

## How it works

[[plugin-cogni-research]] runs the report. Mode choice drives depth:

- **basic** — fast single-pass synthesis
- **detailed** — multi-section with outline; parallel section researchers
- **deep** — recursive tree exploration; multi-query internal search per branch
- **outline** — structure only
- **resource** — collect sources without writing

Source mode flexibility: web (default), local files (PDF, DOCX, TXT, MD, CSV), wiki ([[plugin-cogni-wiki]] instances), or hybrid. The wiki source mode is what enables grounded answers from compiled knowledge instead of re-discovering each time.

[[plugin-cogni-claims]] then verifies every citation in the draft. Each ReportClaim entity becomes a `claim` record (see [[concept-claims-propagation]]). The reviewer reads claim verdicts and the revisor incorporates them — this is the "review loop" that distinguishes cogni-research from a one-pass writer.

[[plugin-cogni-copywriting]] polishes the verified draft. [[plugin-cogni-visual]] `enrich-report` turns it into themed HTML with embedded Chart.js charts and inline SVG concept diagrams. Optional `story-to-infographic` produces a one-page summary version.

## Multilingual

cogni-research supports 18 markets ([[concept-multilingual-support]]) with per-market authority sources and bilingual search.

**Source**: [docs/workflows/research-to-report.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/research-to-report.md)
