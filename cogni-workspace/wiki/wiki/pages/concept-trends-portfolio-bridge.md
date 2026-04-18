---
id: concept-trends-portfolio-bridge
title: Trends ↔ Portfolio bridge (bidirectional integration)
type: concept
tags: [cogni-trends, cogni-portfolio, bridge-files, integration, tips]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md
status: stable
---

The most complex single integration in the ecosystem. cogni-trends and cogni-portfolio exchange three bridge files in two directions to feed each other's analysis.

## Direction one: portfolio → trends

`portfolio-context.json` flows from cogni-portfolio to cogni-trends. It carries the products, features, and markets that the portfolio currently knows about, so that cogni-trends's value-modeler Phase 2 can generate solution templates grounded in real portfolio offerings rather than abstract industry trends.

## Direction two: trends → portfolio

Two bridge files flow back:

- `portfolio-opportunities.json` — ranked growth opportunities the trend analysis identified. cogni-portfolio's `trends-bridge` skill reads this and turns high-ranked opportunities into stub features and propositions.
- `tips-value-model.json` — solution templates, TIPS paths, and BR (Business Relevance) scores for individual trends. cogni-portfolio uses this to enrich existing features with trend-driven evidence.

## Why bidirectional

Each side has knowledge the other lacks. cogni-portfolio knows the existing offerings; cogni-trends knows what's emerging in the market. Bridging both directions lets each analysis ground itself in the other's reality:

- Trend analysis without portfolio context produces abstract solution templates that don't map to anything real.
- Portfolio analysis without trend context misses external pressure on each feature's relevance.

## Loose-coupling discipline

Both sides store path references to the other, never copies. cogni-trends stores `portfolio_ref` paths into cogni-portfolio's directory; cogni-portfolio stores `tips_ref` paths into cogni-trends's. The bridge skill resolves the reference at runtime — see [[concept-data-isolation]].

Each bridge file is a versioned contract — see [[concept-bridge-files]]. Breaking changes need explicit version bumps because the consuming side parses the JSON shape.

## Skills involved

- `cogni-portfolio:trends-bridge` — converts trend opportunities into portfolio stubs
- `cogni-trends:value-modeler` — generates solution templates that read `portfolio-context.json`

**Source**: [insight-wave/CLAUDE.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md) (see also [er-diagram.md](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md))
