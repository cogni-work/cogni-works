---
id: concept-orchestrator-pattern
title: Orchestrator pattern (cogni-consulting tracks, never produces)
type: concept
tags: [architecture, orchestration, cogni-consulting, phase-gates]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md
status: stable
---

cogni-consulting does not produce content. It tracks engagement state and dispatches to plugins that produce content. This is the central design principle of the orchestration layer.

## The split

cogni-consulting knows:
- Which phase an engagement is in (Discover, Define, Develop, Deliver)
- Which plugins have completed their work
- Which phase transitions are ready
- Where to find the outputs (path references in `consulting-project.json`)

cogni-consulting does not know:
- How to run a research report — that's cogni-research
- How to generate a value model — that's cogni-trends
- How to produce propositions — that's cogni-portfolio

## How dispatch works

When cogni-consulting runs the Discover phase, it instructs the user to invoke `cogni-research:research-report`, `cogni-trends:trend-scout`, and `cogni-portfolio:portfolio-scan`. It stores the output paths. When the Define phase begins, it reads those paths to verify completion and then dispatches to `cogni-claims:claims` for claim verification.

From cogni-consulting's CLAUDE.md: "Orchestrator, not producer — manages engagement state; content work done by existing plugins."

## Warn-not-block phase gates

Most phase gates are advisory. The orchestrator warns that Discover is incomplete but allows the consultant to proceed anyway. The exception is the Develop proposition [[concept-quality-gates]], which blocks by default because downstream deliverables built on unverified propositions carry compounded error.

## Why this works

Path references are stored in `consulting-project.json` as relative paths. The engagement never copies data from other plugins — it only remembers where to find it. This is [[concept-data-isolation]] applied at the orchestration level: cogni-consulting can be reasoned about, tested, and modified without touching any data-layer plugin.

**Source**: [docs/architecture/design-philosophy.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md)
