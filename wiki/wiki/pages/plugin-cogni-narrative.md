---
id: plugin-cogni-narrative
title: "cogni-narrative (plugin)"
type: entity
tags: [cogni-narrative, plugin, narrative, story-arc, executive-writing]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-narrative/README.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-narrative.md
status: stable
related: [concept-brief-based-rendering]
---

> **Preview** (v0.9.2) — core skills defined but may change.

Story arc engine for the insight-wave ecosystem. Transforms structured research and portfolio output into executive-grade narratives using 10 arc frameworks (Corporate Visions, JTBD Portfolio, Strategic Foresight, Trend Panorama + 6 more) and 8 narrative techniques. Bilingual EN/DE.

## Layer

[[concept-four-layer-architecture|Output layer]]. Sits between cogni-research/cogni-portfolio (compose-time) and cogni-copywriting/cogni-visual/cogni-sales/cogni-marketing (downstream consumers).

## Skills

| Skill | Purpose |
|-------|---------|
| `cogni-narrative:narrative` | Transform structured input into executive narrative using a chosen arc framework |
| `cogni-narrative:narrative-review` | Score a narrative file against story-arc quality gates (0-100, A-F grade) |
| `cogni-narrative:narrative-adapt` | Adapt an existing narrative into derivative formats (executive brief, talking points, one-pager) |

## Arc frameworks (10)

Corporate Visions Why Change, Jobs-to-be-Done Portfolio, Strategic Foresight, Trend Panorama, plus six more. Each arc is a structural template — sequence of sections with required content blocks and recommended techniques.

## Citation bridge

`bridge-citations.py` converts inline citations like `[Source: Publisher](URL)` into per-source markdown files before narrative Phase 1 runs. This makes downstream rendering's cite-back tooling work consistently across the ecosystem.

## Integration

Upstream: cogni-research (research reports), cogni-portfolio (proposition messaging), cogni-trends (trend reports). Downstream: cogni-copywriting (polish), cogni-visual (briefs via [[concept-brief-based-rendering]] using `arc_id` frontmatter), cogni-sales (Why Change pitches), cogni-marketing (content arcs).

The `arc_id` YAML frontmatter field is the contract: cogni-narrative sets it; cogni-copywriting and cogni-visual read it for arc-aware polish and visual theme selection.

**Source**: [cogni-narrative README](https://github.com/cogni-work/insight-wave/blob/main/cogni-narrative/README.md) · [plugin guide](https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-narrative.md)
