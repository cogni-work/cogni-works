---
id: concept-four-layer-architecture
title: Architectural groups (horizontal workspace, orchestration, data, output)
type: concept
tags: [architecture, layers, dependencies]
created: 2026-04-17
updated: 2026-08-13
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md
status: stable
---

The ecosystem (see [[ecosystem-overview]]) splits along one line: cogni-workspace is **horizontal** infrastructure, and the business plugins are **vertical**, each keeping its own project lifecycle. A capability that owns a full `setup → resume → dashboard` arc is a vertical business plugin; a capability that owns none of that arc is horizontal infrastructure. The vertical plugins are grouped below by the role they play — that grouping is descriptive, not a dependency ordering.

```
horizontal   cogni-workspace
─────────────────────────────────────────────────────────────────
vertical     Orchestration   cogni-consult
             Data            cogni-portfolio  cogni-trends
                             cogni-knowledge  cogni-claims
             Output          cogni-narrative  cogni-copywriting
                             cogni-visual     cogni-sales
                             cogni-marketing  cogni-website
```

## The groups

- **Horizontal** (cogni-workspace) — shared infrastructure: themes, environment variables, Obsidian vault configuration, MCP server installation. Every plugin that produces visual HTML output reads theme files from cogni-workspace. No plugin writes to cogni-workspace except through `pick-theme` and `manage-workspace`.
- **Data** — each plugin owns a specialized knowledge domain. cogni-portfolio (products, markets, propositions, competitors). cogni-trends (TIPS paths, solution templates, catalogs). cogni-knowledge (sub-questions, contexts, sources, claims). cogni-claims (verification state across all sourced assertions).
- **Output** — cogni-narrative, cogni-copywriting, cogni-visual, cogni-sales, cogni-marketing, cogni-website. Transforms data-group content into deliverables (narratives, polished docs, slides/HTML/infographics, sales pitches, marketing campaigns, customer websites). Consumes but does not produce data-group entities.
- **Orchestration** (cogni-consult) — manages engagement state. Dispatches to data and output plugins at phase-appropriate moments without producing content itself. See [[concept-orchestrator-pattern]].

## Why these groups

Substitutability is the point: a data-group plugin can be rebuilt without touching output plugins (they read entities; they don't depend on internal implementation), and output plugins can be added or replaced without touching data plugins. cogni-help and cogni-docs are cross-cutting utilities (help, documentation) that read from every plugin and are read by none.

The grouping combines with [[concept-data-isolation]] (plugins don't share writes) and [[concept-progressive-disclosure]] (each phase loads only its slice) to make the ecosystem horizontally extensible.

## Plugins outside the groups

- **cogni-help** — utility, reads every plugin's skills/agents (read-only), is read by none.
- **cogni-docs** — utility, generates documentation by reading every plugin's structure. Maintainer-side and not one of the 13 marketplace plugins; it ships separately.

These are tools that consume the model rather than participate in it.

**Source**: [docs/architecture/er-diagram.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md)
