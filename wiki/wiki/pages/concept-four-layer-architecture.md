---
id: concept-four-layer-architecture
title: Four architectural layers (orchestration, foundation, data, output)
type: concept
tags: [architecture, layers, dependencies]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md
status: stable
---

The ecosystem (see [[ecosystem-overview]]) organizes into four layers. Plugins in higher layers depend on lower layers, but never the reverse.

```
Orchestration   cogni-consulting
                     |
Foundation      cogni-workspace
                     |
Data            cogni-portfolio  cogni-trends  cogni-research  cogni-claims
                     |
Output          cogni-narrative  cogni-copywriting  cogni-visual
                cogni-sales      cogni-marketing
```

## The layers

- **Foundation** (cogni-workspace) — shared infrastructure: themes, environment variables, Obsidian vault configuration, MCP server installation. Every plugin that produces visual HTML output reads theme files from cogni-workspace. No plugin writes to cogni-workspace except through `pick-theme` and `manage-workspace`.
- **Data** — each plugin owns a specialized knowledge domain. cogni-portfolio (products, markets, propositions, competitors). cogni-trends (TIPS paths, solution templates, catalogs). cogni-research (sub-questions, contexts, sources, claims). cogni-claims (verification state across all sourced assertions).
- **Output** — transforms data-layer content into deliverables (narratives, polished docs, slides/HTML/infographics, sales pitches, marketing campaigns). Consumes but does not produce data-layer entities.
- **Orchestration** (cogni-consulting) — manages engagement state. Dispatches to data and output layers at phase-appropriate moments without producing content itself. See [[concept-orchestrator-pattern]].

## Why this layering

The dependency direction is the contract: a data-layer plugin can be rebuilt without touching output plugins (they read entities; they don't depend on internal implementation). Output plugins can be added or replaced without touching data plugins. cogni-help and cogni-docs cut across layers as utility plugins (help, documentation) that depend on everything but are depended on by nothing.

This layering combines with [[concept-data-isolation]] (each layer's plugins don't share writes) and [[concept-progressive-disclosure]] (each phase loads only its slice) to make the ecosystem horizontally extensible.

## Plugins not in the four layers

- **cogni-help** — utility, depends on everything via knowledge of skills/agents (read-only), is depended on by nothing.
- **cogni-docs** — utility, generates documentation by reading every plugin's structure.
- **cogni-wiki** — utility, ships this knowledge base.

These don't violate the layering — they're tools that consume the four-layer model rather than participate in it.

**Source**: [docs/architecture/er-diagram.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md)
