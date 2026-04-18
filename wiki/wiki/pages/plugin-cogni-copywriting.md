---
id: plugin-cogni-copywriting
title: "cogni-copywriting (plugin)"
type: entity
tags: [cogni-copywriting, plugin, copywriting, polishing, messaging-frameworks, readability]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-copywriting/README.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-copywriting.md
status: stable
---

> **Preview** (v0.2.2) — core skills defined but may change.

Professional copywriting toolkit providing document polishing with messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB, Inverted Pyramid), stakeholder review via parallel persona Q&A, readability optimization, and sales enhancement (Power Positions).

## Layer

[[concept-four-layer-architecture|Output layer]]. Polishes documents that other plugins compose; modifies documents in place; has no persistent entities of its own.

## Skills

| Skill | Purpose |
|-------|---------|
| `cogni-copywriting:copywriter` | Polish, rewrite, or create business documents (memos, briefs, reports, proposals, one-pagers, blogs) using McKinsey Pyramid Principle and other frameworks |
| `cogni-copywriting:copy-reader` | Review a document through parallel stakeholder persona Q&A simulation, then synthesize feedback |
| `cogni-copywriting:copy-json` | Adapter that polishes text fields inside JSON files by extracting them, polishing via copywriter, writing back |
| `cogni-copywriting:audit-copywriter` | Audit copywriting's arc-preservation references against cogni-narrative's upstream arc definitions |

## Arc-aware polishing

When a document carries `arc_id` frontmatter set by cogni-narrative, copywriting reads the arc definition and preserves the arc's structural sections during polish — it can sharpen language inside a section but won't collapse Why Change → Why Now → Why You → Why Pay into a generic flow. The `audit-copywriter` skill catches drift between cogni-narrative's arc definitions and copywriting's references.

## Power Positions

Sales enhancement pattern: identify and strengthen the few sentences in a document that carry the actual persuasion weight (the "power positions" — opening, closing, headline of each section). Used by cogni-sales for pitch polish.

## Integration

Upstream: cogni-narrative (composed narratives with `arc_id`), any plugin producing prose deliverables. Downstream: cogni-visual (polished prose flows into brief preparation), cogni-sales, cogni-marketing.

**Source**: [cogni-copywriting README](https://github.com/cogni-work/insight-wave/blob/main/cogni-copywriting/README.md) · [plugin guide](https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-copywriting.md)
