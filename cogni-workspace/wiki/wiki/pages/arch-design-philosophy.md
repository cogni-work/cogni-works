---
id: arch-design-philosophy
title: Design philosophy (architecture)
type: summary
tags: [architecture, design-principles, philosophy]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md
status: stable
---

The architectural principles that recur across insight-wave plugins. Reading these once makes every plugin's source easier to follow because the same six patterns keep appearing.

## The six principles

- **[[concept-data-isolation]]** — each plugin owns its data completely; cross-plugin reads happen through path references, bridge files, or YAML frontmatter contracts. No shared database, no global registry.
- **[[concept-progressive-disclosure]]** — skills and agents load reference material only at the step that needs it, never all at startup. Keeps the context window survivable for long pipelines.
- **[[concept-slug-based-lookups]]** — every cross-plugin reference uses kebab-case slugs derived at creation time. Slugs are both file names and identifiers. cogni-portfolio's double-dash convention (`feature--market`) marks paired entities.
- **[[concept-brief-based-rendering]]** — cogni-visual splits content specification (briefs) from rendering. Briefs travel as YAML-frontmatter markdown; rendering agents are swapped without invalidating briefs.
- **[[concept-quality-gates]]** — entity-producing plugins gate on three layers (structural validation, quality assessment, stakeholder review) before downstream generation runs.
- **[[concept-orchestrator-pattern]]** — cogni-consulting tracks engagement state and dispatches; it does not produce content. Most phase gates are advisory; the Develop proposition gate is the deliberate exception.

## Why these principles work together

Data isolation gives each plugin a clean local context to test against. Progressive disclosure keeps that context loadable. Slug-based lookups make cross-plugin references stable across renames and reorganization. Brief-based rendering decouples evolution of content pipelines from rendering pipelines. Quality gates push detection of bad upstream work to the cheapest possible point. The orchestrator pattern keeps cogni-consulting from becoming a god-object that knows every other plugin's internals.

The combination is what makes the ecosystem horizontally scalable: a new plugin can consume cogni-portfolio output by reading `portfolio-context.json` without any change to cogni-portfolio.

**Source**: [docs/architecture/design-philosophy.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md)
