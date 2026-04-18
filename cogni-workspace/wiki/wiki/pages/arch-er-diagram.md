---
id: arch-er-diagram
title: Entity relationships and cross-plugin data flow (architecture)
type: summary
tags: [architecture, entities, data-flow, bridge-files]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md
status: stable
---

The cross-plugin entity model and how data flows between plugins. Every arrow is a read-only reference resolved at runtime — never a live connection or shared write path.

## Four architectural layers

Plugins in higher layers depend on lower layers, not the reverse. See [[concept-four-layer-architecture]] for the full mapping.

- **Orchestration** — cogni-consulting (engagement state, phase dispatch)
- **Foundation** — cogni-workspace (themes, env vars, vault config)
- **Data** — cogni-portfolio, cogni-trends, cogni-research, cogni-claims (each owns a knowledge domain)
- **Output** — cogni-narrative, cogni-copywriting, cogni-visual, cogni-sales, cogni-marketing (transform data-layer content into deliverables)

## Entity types per plugin

Each data-layer plugin owns a specialized domain with its own persistent entities:

- cogni-portfolio: Product, Feature, Market, Proposition, Solution, Package, Competitor, Customer (JSON in project dir)
- cogni-trends: TipsProject, TrendCandidate, TrendReport, InvestmentTheme, SolutionTemplate, Catalog (JSON + YAML)
- cogni-research: SubQuestion, Context, Source, ReportClaim (markdown with YAML frontmatter, Obsidian-browsable)
- cogni-claims: ClaimRecord, DeviationRecord, ResolutionRecord (JSON in `cogni-claims/`)
- cogni-narrative, cogni-visual, cogni-marketing, cogni-sales, cogni-consulting, cogni-workspace also have their own entity types

cogni-copywriting deliberately has no persistent entities — it modifies documents in place and detects `arc_id` frontmatter for arc-aware polishing.

## Bridge files

Bridge files are explicit JSON exports written by one plugin and read by another according to a versioned contract — see [[concept-bridge-files]]. Key examples: `portfolio-context.json` (cogni-portfolio → cogni-trends, products and features for trend mapping), `portfolio-opportunities.json` (cogni-trends → cogni-portfolio, ranked growth opportunities), `tips-value-model.json` (cogni-trends → cogni-portfolio, solution templates and TIPS paths for trends-bridge import), `claims.json` (any plugin → cogni-claims, sourced assertions for verification).

The bidirectional bridge between cogni-portfolio and cogni-trends is the most complex single integration in the ecosystem.

## YAML frontmatter contracts

Lighter than bridge files: a downstream plugin reads specific frontmatter fields from upstream files. `arc_id` (cogni-narrative → cogni-copywriting/cogni-visual), `theme_path` (cogni-workspace → cogni-visual — see [[concept-theme-inheritance]]), `portfolio_path` (cogni-portfolio → cogni-consulting), `arc_type` (cogni-visual internal mapping for rendering agents).

## Data isolation in practice

The diagram shows many arrows but each is read-only. cogni-claims reads source URLs from cogni-research entity files but never writes back. cogni-portfolio's proposition-generator reads trend-bridge enrichments from `portfolio-opportunities.json` but never modifies cogni-trends files. The boundary is the bridge file or frontmatter field — everything on each side is private to the owning plugin. See [[concept-data-isolation]].

## Claim lifecycle

Claims flow from data-layer plugins into cogni-claims through a three-state lifecycle (`unverified → verified` or `unverified → deviated → resolved`). cogni-claims owns verification logic but never generates claims itself — that boundary is enforced by design. Full detail in [[concept-claim-lifecycle]].

**Source**: [docs/architecture/er-diagram.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md)
