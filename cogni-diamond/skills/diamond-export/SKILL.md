---
name: diamond-export
description: |
  Generate the final deliverable package for a Double Diamond engagement. Produces formatted
  outputs (PPTX, DOCX, XLSX, Excalidraw) by dispatching to cogni-visual and document-skills.
  Use whenever the user mentions "generate deliverables", "export engagement", "create the deck",
  "produce the report", "final package", "export diamond", or wants to produce the engagement
  outputs — even if they don't say "export" explicitly.
---

# Diamond Export — Generate Deliverables

Produce the final deliverable package by dispatching to cogni-visual and document-skills plugins. This skill reads all engagement outputs and generates formatted deliverables matched to the engagement vision.

## Core Concept

Every diamond engagement promises specific deliverables (defined during setup). Export assembles the raw phase outputs into polished, client-ready formats. It acts as a dispatcher — not a renderer — delegating format-specific work to the ecosystem's visual and document plugins.

## Prerequisites

- Deliver phase should be complete (or substantially complete)
- Engagement deliverables list defined in diamond-project.json

## Workflow

### 1. Load Context

Read diamond-project.json. Extract the deliverables list from `vision.deliverables`.

### 2. Map Deliverables to Sources

For each deliverable, identify the source content and rendering plugin:

| Deliverable | Source | Renderer |
|---|---|---|
| Strategic Options Brief | `deliver/option-scoring.md` + `develop/options/` | document-skills:docx or document-skills:pptx |
| Business Case | `deliver/business-case.md` | document-skills:xlsx (financials) + document-skills:docx (narrative) |
| Decision Board | `develop/options/option-synthesis.md` + `deliver/option-scoring.md` | Excalidraw (via cogni-visual) |
| Executive Summary | `deliver/executive-summary.md` | document-skills:pptx (one-pager) |
| Action Roadmap | `deliver/roadmap.md` | document-skills:pptx or document-skills:xlsx |
| TIPS Landscape | plugin_refs.tips_project output | cogni-tips:tips-dashboard or Excalidraw |
| Portfolio Snapshot | plugin_refs.portfolio_project output | cogni-portfolio:portfolio-dashboard |
| Claim Verification Log | `deliver/claims-verification.md` | document-skills:xlsx or markdown |

### 3. Generate Each Deliverable

For each deliverable in the list:

1. Read the source content
2. Dispatch to the appropriate renderer
3. Save output to `output/` directory with descriptive filename
4. Note success/failure

Between deliverables, check with the consultant if they want to review before continuing.

**Theme support**: If a cogni-workspace theme is active, pass the theme to visual/document plugins for consistent branding across all deliverables.

### 4. Assemble Package Index

Create `output/README.md` as an index of all generated deliverables:

```markdown
# [Engagement Name] — Deliverable Package

**Client**: [client name]
**Vision**: [vision class]
**Date**: [date]

## Deliverables

| # | Deliverable | Format | File |
|---|---|---|---|
| 1 | Executive Summary | PPTX | executive-summary.pptx |
| 2 | Strategic Options Brief | DOCX | strategic-options-brief.docx |
| ...
```

### 5. Present Summary

> **Deliverable package generated.**
> - N deliverables produced in `output/`
> - [list files with formats]
>
> Review the package and let me know if any deliverable needs refinement.

## Important Notes

- If a source file is missing, skip the deliverable and note the gap
- Prefer the theme from the workspace if available
- Large deliverables (detailed PPTX decks) may need the consultant to provide additional guidance on structure
- The package index is always generated as markdown, regardless of other format choices
