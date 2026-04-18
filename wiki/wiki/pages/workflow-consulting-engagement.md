---
id: workflow-consulting-engagement
title: "Workflow: Consulting Engagement (Double Diamond)"
type: summary
tags: [workflow, consulting, double-diamond, cross-plugin, orchestration]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/consulting-engagement.md
status: stable
related: [plugin-cogni-consulting, concept-orchestrator-pattern]
---

The full Double Diamond pipeline orchestrated by [[plugin-cogni-consulting]].

## Pipeline

```
cogni-consulting orchestrates:
  Discover  → cogni-research + cogni-trends + cogni-portfolio (scan)
  Define    → cogni-claims (verification) + cogni-portfolio (entity confirmation)
  Develop   → cogni-trends (value-modeler) + cogni-portfolio (propositions, solutions)
  Deliver   → cogni-visual (export) + cogni-sales (final pitch package)
```

## Duration

Days to weeks depending on engagement scope.

## End deliverable

A full consulting deliverable package — slide deck, proposal document, supporting materials, and the engagement record (`consulting-project.json` with phase trail).

## How it works

[[plugin-cogni-consulting]] never produces content itself — it tracks engagement state in `consulting-project.json` and dispatches to the right plugin at each phase boundary. See [[concept-orchestrator-pattern]].

The four phases follow the Double Diamond shape (diverge → converge → diverge → converge):

- **Discover** dispatches [[plugin-cogni-research]] for research reports, [[plugin-cogni-trends]] for trend scouting, [[plugin-cogni-portfolio]] for portfolio scan. Output: rich problem context.
- **Define** verifies sourced assertions via [[plugin-cogni-claims]] ([[concept-claims-propagation]]), then converges to a problem statement. Lean Canvas authoring lives here.
- **Develop** generates solution options via [[plugin-cogni-trends]] value-modeler and [[plugin-cogni-portfolio]] propositions/solutions. The Develop proposition gate is the one [[concept-quality-gates]] that blocks (warn-not-block elsewhere).
- **Deliver** exports the chosen direction as PPTX/DOCX/XLSX/themed HTML via [[plugin-cogni-visual]] and packages a final pitch via [[plugin-cogni-sales]].

## Re-entry

`cogni-consulting:consulting-resume` is the primary re-entry point — it shows current phase, completed work, and recommends the next dispatch.

**Source**: [docs/workflows/consulting-engagement.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/consulting-engagement.md)
