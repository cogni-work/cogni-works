---
id: plugin-cogni-consulting
title: "cogni-consulting (plugin)"
type: entity
tags: [cogni-consulting, plugin, consulting, double-diamond, orchestrator, phase-gates, strategy]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-consulting/README.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-consulting.md
status: stable
related: [concept-orchestrator-pattern, concept-quality-gates]
---

> **Incubating** (v0.0.10) — skills may change or be removed at any time.

Double Diamond consulting orchestrator. Guides engagements through Discover, Define, Develop, Deliver phases by dispatching to insight-wave plugins (research, trends, portfolio, claims) at the right moment. Vision-first, method-aware, phase-gated. Includes Lean Canvas authoring and lightweight how-might-we engagements for bounded challenges.

## Layer

[[concept-four-layer-architecture|Orchestration layer]]. Tracks engagement state and dispatches; never produces content itself — see [[concept-orchestrator-pattern]].

## Skills

| Skill | Purpose |
|-------|---------|
| `cogni-consulting:consulting-setup` | Initialize a Double Diamond engagement with vision framing |
| `cogni-consulting:consulting-discover` | Discover phase — diverge to build problem understanding (dispatches to research, trends, portfolio scan) |
| `cogni-consulting:consulting-define` | Define phase — converge to clear problem statement (verifies via cogni-claims, runs affinity mapping) |
| `cogni-consulting:consulting-define-workspace` | Workspace-installer variant of define |
| `cogni-consulting:consulting-develop` | Develop phase — diverge on solution options (dispatches to value-modeler, propositions) |
| `cogni-consulting:consulting-deliver` | Deliver phase — converge on validated outcomes (final claims verification, business case) |
| `cogni-consulting:consulting-export` | Generate final deliverable package (PPTX, DOCX, XLSX, themed HTML via cogni-visual) |
| `cogni-consulting:consulting-resume` | Resume status — primary re-entry point across sessions |

## The four phases

```
Discover  → Define  →  Develop  → Deliver
(diverge)   (converge)  (diverge)   (converge)
```

Diamond shape — diverge to expand options, converge to commit. Each phase has an entry condition (previous phase complete) and an exit condition (deliverables in hand). Phase gates are mostly advisory — see warn-not-block in [[concept-orchestrator-pattern]] — except the Develop proposition [[concept-quality-gates]] which blocks because downstream deliverables built on unverified propositions carry compounded error.

## What it stores

`consulting-project.json` — engagement config, phase state, plugin path references. Plus Lean Canvas markdown files and per-phase notes. Path references are stored as relative paths; the engagement never copies data from other plugins.

## Integration

Dispatches to: cogni-research (Discover reports), cogni-trends (trend scouting + value modeling), cogni-portfolio (scan, propositions, deliverables), cogni-claims (verification at Define and Deliver gates), cogni-narrative (final arc composition), cogni-visual (export rendering).

**Source**: [cogni-consulting README](https://github.com/cogni-work/insight-wave/blob/main/cogni-consulting/README.md) · [plugin guide](https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-consulting.md)
