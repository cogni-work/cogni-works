---
id: concept-data-isolation
title: Data isolation between plugins
type: concept
tags: [architecture, data-isolation, bridge-files, frontmatter-contracts]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md
status: stable
---

Each insight-wave plugin owns its data completely. There is no shared database, no global state store, and no registry that plugins write to in common.

## Three sanctioned cross-plugin reading mechanisms

When plugin A needs data from plugin B, it uses one of three mechanisms — never a direct write or shared store:

- **Path references** — plugin A stores a path string pointing into plugin B's directory and reads at runtime.
- **Bridge files** — explicit JSON exports written by one plugin and read by another (e.g. `portfolio-context.json`, `tips-value-model.json`). See [[concept-bridge-files]].
- **YAML frontmatter contracts** — downstream plugins read specific fields like `arc_id`, `theme_path`, `portfolio_path` from upstream files.

## What this buys

Each plugin can be understood, developed, and tested without loading any other plugin's code or data model. A change to cogni-portfolio's entity schema does not break cogni-trends unless the bridge file contract changes — and bridge contracts are versioned explicitly.

The ecosystem scales horizontally: a new plugin can consume cogni-portfolio output by reading `portfolio-context.json` without any change to cogni-portfolio itself.

## In practice

The diagram in [[arch-er-diagram]] shows many arrows but each is read-only. cogni-claims reads source URLs from cogni-research entity files but never writes back. cogni-portfolio's proposition-generator reads trend-bridge enrichments from `portfolio-opportunities.json` but never modifies cogni-trends files. The boundary is the bridge file or frontmatter field — everything on each side is private to the owning plugin.

This principle is one half of why [[concept-progressive-disclosure]] works — without isolation, you couldn't load just the slice of context a phase needs.

**Source**: [docs/architecture/design-philosophy.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md) (see also [er-diagram.md](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md))
