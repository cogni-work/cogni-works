---
id: concept-brief-based-rendering
title: Brief-based rendering (separate content spec from rendering)
type: concept
tags: [cogni-visual, briefs, rendering, separation-of-concerns]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md
status: stable
---

cogni-visual separates content specification from rendering. Between the compose/polish phase and the render phase, cogni-visual inserts a **brief**: a structured Markdown file with YAML frontmatter that describes *what* to render without describing *how*.

## The pipeline

```
cogni-narrative → cogni-copywriting → cogni-visual
(compose)         (polish)            (visualize)
```

A brief sits between cogni-copywriting's output and cogni-visual's rendering agents.

## What a brief specifies vs hides

A presentation brief lists slides with headlines, body copy, and CTA proposals. It does **not** specify colors, fonts, layout coordinates, or element types.

An infographic brief lists content blocks with block types, headlines, and data points. It does **not** specify element composition or spatial relationships — those decisions belong to the rendering agents.

cogni-visual's CLAUDE.md: "Briefs are YAML frontmatter + Markdown. Frontmatter holds metadata (type, version, theme, arc_type, arc_id, confidence_score). Body holds the content specification."

## Two practical benefits

1. **Briefs are reviewable and editable independently of rendering.** A user can run `story-to-slides` to produce a brief, adjust the headline on slide 3, and then render without re-running the content pipeline.

2. **Rendering agents can evolve independently.** When rendering pipelines upgrade (new chart types, new sketchnote conventions, new export formats), existing briefs remain valid because brief formats make no assumptions about rendering technique.

## Brief types in cogni-visual

- `presentation-brief.md` — slides
- `infographic-brief.md` — single-page visual summary
- `storyboard-brief.md` — multi-poster sequence
- `web-brief.md` — scrollable web narrative
- `enrichment-plan.md` — annotation of an existing markdown report

Each brief is consumed by a different render agent (`render-html-slides`, `render-infographic-pencil`/`-sketchnote`/`-whiteboard`, `storyboard`, `web`, `enrich-report`).

## Why this matters across the ecosystem

Brief-based rendering is the cleanest example of [[concept-data-isolation]] inside a single plugin. The brief is the contract; everything before it is content; everything after it is presentation. The same principle could be applied to other rendering domains.

**Source**: [docs/architecture/design-philosophy.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md)
