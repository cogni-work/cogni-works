---
id: concept-bridge-files
title: Bridge files (versioned JSON exports between plugins)
type: concept
tags: [bridge-files, integration, contracts, versioning, json]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md
status: stable
---

Bridge files are explicit JSON exports written by one plugin and read by another according to a versioned contract. They are the second of the three sanctioned cross-plugin reading mechanisms (along with path references and YAML frontmatter contracts) — see [[concept-data-isolation]].

## The full bridge file table

| Bridge File | Written by | Read by | What it carries |
|------------|-----------|--------|-----------------|
| `portfolio-context.json` | cogni-portfolio | cogni-trends | Products, features, markets for trend-to-portfolio mapping |
| `portfolio-opportunities.json` | cogni-trends | cogni-portfolio | Ranked growth opportunities from trend analysis |
| `tips-value-model.json` | cogni-trends | cogni-portfolio | Solution templates, TIPS paths, BR scores for trends-bridge import |
| `claims.json` | various | cogni-claims | Claim records with source URLs submitted for verification |
| `consulting-project.json` | cogni-consulting | (internal) | Engagement config, phase state, plugin path references |
| `canvas-{slug}.md` | cogni-consulting | cogni-portfolio | Lean Canvas sections for entity extraction |

## Why bridges, not direct imports

A bridge file has three properties that direct cross-plugin imports lack:

- **Versioned contract** — the JSON shape is part of the contract. Breaking changes need a deliberate version bump.
- **Snapshot semantics** — the consuming plugin reads the snapshot it has, not whatever the producing plugin currently has in memory. Removes timing concerns.
- **Auditable** — the bridge file is a real file you can inspect, diff, and check into a project for reproducibility.

## When to use a bridge file vs frontmatter contract

Use a frontmatter field for a single-value reference (a path, an arc_id, a theme path). Use a bridge file when the data is structured and multi-record (a list of opportunities, a set of solution templates, a claim queue).

The biggest example is the bidirectional integration documented in [[concept-trends-portfolio-bridge]] — three bridge files in two directions.

**Source**: [docs/architecture/er-diagram.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md) (see also [design-philosophy.md](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md))
