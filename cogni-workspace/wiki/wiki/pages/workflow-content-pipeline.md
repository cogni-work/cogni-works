---
id: workflow-content-pipeline
title: "Workflow: Content Pipeline (marketing → narrative → copywriting → visual)"
type: summary
tags: [workflow, content-pipeline, marketing, narrative, copywriting, visual]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/content-pipeline.md
status: stable
related: [plugin-cogni-marketing, plugin-cogni-narrative, plugin-cogni-copywriting, plugin-cogni-visual]
---

The end-to-end content production pipeline — from strategy to channel-ready deliverables.

## Pipeline

```
cogni-marketing (setup + content generation)
   ↓ raw content pieces
cogni-narrative (story arc shaping, long-form only)
   ↓ narrative with arc_id
cogni-copywriting (polish, arc-aware)
   ↓ polished prose
cogni-visual (slides / web rendering, brief-driven)
```

## Duration

2–6 hours for a complete content batch, depending on format count and polish depth.

## End deliverable

A multi-channel marketing content package — polished articles, battle cards, email nurtures, and optionally a slide deck or web narrative.

## How it works

[[plugin-cogni-marketing]] generates content per the market × GTM-path × content-type matrix. Long-form pieces (whitepapers, thought-leadership articles, keynote outlines) flow into [[plugin-cogni-narrative]] for arc shaping — the `arc_id` set here drives downstream polish and visual treatment.

Short-form content (LinkedIn posts, carousels, battle cards) skips narrative and goes straight to [[plugin-cogni-copywriting]] for polish.

[[plugin-cogni-copywriting]] applies messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB, Inverted Pyramid) per content type. When `arc_id` is present, polish preserves arc structure (the Why Change → Why Now → Why You → Why Pay sequence in a Corporate Visions narrative stays intact).

Optional final hop: [[plugin-cogni-visual]] turns polished long-form into slide decks (`story-to-slides`) or web narratives (`story-to-web`) for distribution channels that need visual treatment. See [[concept-brief-based-rendering]].

## Why this order

Each step adds value the previous can't: marketing knows the strategic positioning, narrative knows arc structure, copywriting knows messaging frameworks and polish, visual knows rendering. Bypassing a step works for the simple case but produces visibly weaker output for sophisticated channels.

**Source**: [docs/workflows/content-pipeline.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/content-pipeline.md)
