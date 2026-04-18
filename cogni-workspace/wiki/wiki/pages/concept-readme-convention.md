---
id: concept-readme-convention
title: README convention (16-section IS/DOES/MEANS structure)
type: concept
tags: [readme, conventions, is-does-means, fab, cogni-docs]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md
status: stable
---

Every plugin README follows the same 16-section IS/DOES/MEANS structure. This consistency lets cogni-docs auto-generate the structural sections while preserving the hand-written messaging sections.

## The 16 sections

| # | Section | Category |
|---|---------|----------|
| 1 | Title + maturity callout + first paragraph | mixed (callout auto-generated, pitch hand-written) |
| 2 | Why this exists | hand-written (problem table) |
| 3 | What it is | hand-written (IS expanded) |
| 4 | What it does | auto-generated (from SKILL.md) |
| 5 | What it means for you | hand-written (MEANS) |
| 6-7 | Installation, Quick start | auto-generated |
| 8-10 | Try it, Data model, How it works | hand-written |
| 11-13 | Components, Architecture, Dependencies | auto-generated |
| 14 | Custom development | hand-written |
| 15-16 | License, Built-by footer | auto-generated |

## IS/DOES/MEANS

The pattern comes from the FAB (Features-Advantages-Benefits) sales framework, restructured for technical audiences:

- **IS** (section 3, "What it is") — the noun. What kind of thing this plugin is.
- **DOES** (section 4, "What it does") — the verb. What the plugin enables — derived from SKILL.md descriptions.
- **MEANS** (section 5, "What it means for you") — the value. Why this matters to a specific reader role.

This same structure powers cogni-portfolio's proposition messaging — see [[concept-data-model-patterns]].

## Auto-generated vs hand-written

Auto-generated sections are produced by cogni-docs:
- `doc-generate` writes sections 4, 11-13 from plugin metadata (skills, agents, plugin.json, .mcp.json)
- `doc-sync` aligns descriptions across plugin.json, marketplace.json, and README first paragraph
- `doc-power` strengthens IS/DOES/MEANS messaging
- `doc-audit` detects drift between sections and source of truth

Hand-written sections (2, 3, 5, 8-10, 14) carry intent that automation can't generate from code. cogni-docs flags drift but never overwrites them.

## Maturity callout

Each pre-1.0 and archived plugin has a maturity callout blockquote after the H1 title, e.g. `> **Preview** (v0.x) — core skills defined but may change.` `doc-generate` injects this automatically based on `plugin.json` version. `doc-audit` Check 13 enforces consistency between version and callout. See [[concept-plugin-maturity-model]].

**Source**: [insight-wave/CLAUDE.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md)
