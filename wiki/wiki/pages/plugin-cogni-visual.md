---
id: plugin-cogni-visual
title: "cogni-visual (plugin)"
type: entity
tags: [cogni-visual, plugin, visual, presentations, slides, infographics, web, storyboard, briefs]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-visual/README.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-visual.md
status: stable
related: [concept-brief-based-rendering, concept-theme-inheritance, concept-mcp-server-map]
---

> **Preview** (v0.16.20) — core skills defined but may change.

Transform polished narratives and structured data into visual deliverables — presentation briefs, slide decks, scrollable web narratives, poster storyboards, single-page infographics, and visual assets. Supports Excalidraw, Pencil MCP, PPTX, and HTML rendering.

## Layer

[[concept-four-layer-architecture|Output layer]]. Reads themes from cogni-workspace ([[concept-theme-inheritance]]) and consumes briefs as the input contract ([[concept-brief-based-rendering]]).

## Skills (10)

- **Story-to-brief**: `story-to-slides`, `story-to-infographic`, `story-to-storyboard`, `story-to-web` — transform any narrative with a story arc into a brief for the matching renderer
- **Render**: `render-html-slides`, `render-infographic-editorial-workspace`, `enrich-report` (turn a markdown report into themed HTML with Chart.js + inline SVG)
- **Review**: `review-brief` (multi-perspective stakeholder review of any brief type)
- **Workspace variants**: `story-to-slides-workspace`, `story-to-infographic-workspace`

## Brief types

Every render path goes through a brief:

| Brief | Render style | Output |
|-------|--------------|--------|
| `presentation-brief.md` | HTML slides or PPTX | self-contained HTML with speaker notes; document-skills:pptx for PowerPoint |
| `infographic-brief.md` | editorial (Pencil), sketchnote (Excalidraw), whiteboard (Excalidraw) | per-style render agents |
| `storyboard-brief.md` | multi-poster Pencil .pen | poster sequence |
| `web-brief.md` | scrollable web narrative | single-page HTML via Pencil |
| `enrichment-plan.md` | annotation of an existing report | enriched HTML with Chart.js + inline SVG |

## MCP dependencies

Three MCP servers — see [[concept-mcp-server-map]]:
- **excalidraw** — sketchnote and whiteboard infographic styles, concept diagrams, architecture diagrams
- **pencil** — editorial infographic, web narrative, storyboard, hero rendering
- **(plus PPTX via document-skills:pptx and HTML via Chart.js for in-browser rendering)**

## Integration

Upstream: cogni-narrative (narratives with `arc_id`), cogni-copywriting (polished docs), any plugin producing text deliverables (cogni-research, cogni-trends, cogni-portfolio, cogni-marketing, cogni-sales). Downstream: terminal — produces final visual deliverables that humans consume.

**Source**: [cogni-visual README](https://github.com/cogni-work/insight-wave/blob/main/cogni-visual/README.md) · [plugin guide](https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-visual.md)
