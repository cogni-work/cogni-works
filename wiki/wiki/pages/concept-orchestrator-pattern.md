---
id: concept-orchestrator-pattern
title: Orchestrator pattern (cogni-consult tracks, never produces)
type: concept
tags: [architecture, orchestration, cogni-consult, action-fields]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md
status: stable
---

cogni-consult does not produce content. It tracks engagement state and dispatches to plugins that produce content. This is the central design principle of the orchestration layer.

## The split

cogni-consult knows:
- Which action fields the engagement's key question decomposes into (3–6, derived at scoping)
- Which deliverable inside a field is next, and which design-thinking stage it has reached
- Which deliverables have landed
- Where to find the outputs (path references in `consult-project.json`)

cogni-consult does not know:
- How to run research — that's the bound cogni-knowledge base
- How to generate a value model — that's cogni-trends
- How to produce propositions — that's cogni-portfolio

## How dispatch works

Work is organized by **action field**, not by a global phase. Scoping derives 3–6 action fields from the key question, every deliverable lives inside exactly one field, and progress is tracked per deliverable rather than per engagement-wide stage. There are no phase folders and no fixed Discover/Define/Develop/Deliver sequence.

Each deliverable runs its own design-thinking loop — empathize → define → ideate → prototype → test — and dispatches outward at the points where it needs content it does not own. Research is the clearest case: one cogni-knowledge base is bound to the engagement at setup (`plugin_refs.knowledge_base`), every deliverable's research runs through that base, and the syntheses land under `action-fields/<field-slug>/research/<topic-slug>.md`. Because the same base is reused, research compounds across deliverables instead of being re-fetched for each one.

From cogni-consult's CLAUDE.md: "Orchestrator, not producer — manages engagement state; content work dispatches to existing plugins."

## Gates are advisory, with one deliberate exception

The design-thinking loop's own quality gates are advisory — structural validation, the acting-persona challenge and the framework-adherence review all report rather than block, so an auto-walk never deadlocks. See [[concept-quality-gates]].

The exception is the **personas gate**. Stakeholder personas are seeded from the engagement scope before the first design-thinking deliverable can start, and that seed is a gate rather than a suggestion: a not-yet-started deliverable is hard-blocked until it is satisfied. It clears when a persona carries `source: scope-seeded`, or when the `personas/.gate-waiver` marker records an explicit decision that no external stakeholder is worth modelling — the two setup-default advisors do not satisfy it. The reason this one blocks where the others warn is the reason quality gates exist at all: a deliverable built with no stakeholder to answer to carries compounded error downstream.

## Why this works

Path references are stored in `consult-project.json` as relative paths. The engagement never copies data from other plugins — it only remembers where to find it. This is [[concept-data-isolation]] applied at the orchestration level: cogni-consult can be reasoned about, tested, and modified without touching any data-layer plugin.

**Source**: [docs/architecture/design-philosophy.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md)
