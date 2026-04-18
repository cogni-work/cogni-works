---
id: concept-progressive-disclosure
title: Progressive disclosure (load reference material at the step that needs it)
type: concept
tags: [architecture, context-management, skills, agents]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md
status: stable
---

Skills and agents load reference material only at the step that needs it, never all at startup. This is the load-bearing pattern that lets long pipelines run without exhausting the context window.

## Where it shows up

cogni-visual, cogni-portfolio, cogni-research, and cogni-consulting apply this consistently. cogni-visual's CLAUDE.md states it directly: "Reference files are read only at the step that needs them, not all at once."

A typical research-report pipeline:

- Phase 0: read project config, check workspace state
- Phase 1: load sub-question templates (not yet the writer's tone guide)
- Phase 3: load the writer's style reference only when writing begins
- Phase 4: load the reviewer's checklist only when reviewing begins

## At the entity level

cogni-portfolio's `portfolio.json` is a lightweight manifest with entity counts and status flags. The full entity content lives in subdirectories and is loaded only when a skill actively works on that entity type. Browsing portfolio status costs almost nothing; deep research on a single feature loads only that feature's files.

## At the agent level

Agents receive compact task instructions and load reference materials themselves at their first step, rather than receiving the full skill context pre-loaded. This is one reason the [[concept-orchestrator-pattern]] works — orchestrating skills don't have to swell their own context to dispatch a worker.

## Why it depends on data isolation

[[concept-data-isolation]] is the prerequisite. If plugins shared a global store, "load only what this phase needs" wouldn't be a meaningful unit — you'd have to reason about everything that could change.

**Source**: [docs/architecture/design-philosophy.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md)
