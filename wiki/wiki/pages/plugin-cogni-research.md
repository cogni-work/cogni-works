---
id: plugin-cogni-research
title: "cogni-research (plugin)"
type: entity
tags: [cogni-research, plugin, research, multi-agent, storm, parallel-search, claims-verification]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-research/README.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-research.md
status: stable
related: [concept-multilingual-support, concept-claims-propagation]
---

> **Preview** (v0.7.12) — core skills defined but may change.

Multi-agent research report generator with localized search across 18 European and Anglo markets (DACH, DE, AT, FR, IT, ES, NL, PL, CZ, SK, HU, RO, HR, GR, MK, UK, US, EU). STORM-inspired editorial workflow: parallel section research, claims-verified review loops, and five report types (basic, detailed, deep, outline, resource). Supports web, local, wiki, and hybrid source modes.

## Layer

[[concept-four-layer-architecture|Data layer]]. Produces research artifacts (sub-questions, contexts, sources, claims) consumed by every output-layer plugin.

## Skills

| Skill | Purpose |
|-------|---------|
| `cogni-research:research-setup` | Configure and initialize a research project — interactive menu for report type, tone, citation style, target market |
| `cogni-research:research-report` | Generate a multi-agent research report; modes: basic / detailed / deep / outline / resource |
| `cogni-research:research-resume` | Resume status — show progress, next recommended phase, interrupted runs |
| `cogni-research:verify-report` | Verify claims in a research report against cited sources via cogni-claims |
| `cogni-research:research-report-workspace` | Workspace-installer variant |

## STORM-inspired workflow

Sub-question outline → parallel section researchers (web, local, wiki, or hybrid sources) → context and source entities → writer composes draft with inline citations → reviewer evaluates → revisor incorporates feedback. Quality gates apply throughout — see [[concept-quality-gates]].

## 18-market multilingual support

Per-market authority sources curated in `references/market-sources.json`. Intent-based bilingual search (e.g., DACH project searches both DE and EN sources). Configurable output language. See [[concept-multilingual-support]].

## Source modes

- **web** — WebSearch + WebFetch on per-market authority sources
- **local** — research from local files (PDF, DOCX, TXT, MD, CSV) instead of web
- **wiki** — query existing cogni-wiki instances
- **hybrid** — combine multiple modes

## Integration

Upstream: source corpora (web, local files, cogni-wiki). Downstream: cogni-claims (auto-logged claims via [[concept-claims-propagation]]), cogni-narrative (research → narrative arcs), cogni-trends (research signals feed trend scouting), cogni-consulting (Discover phase reports).

**Source**: [cogni-research README](https://github.com/cogni-work/insight-wave/blob/main/cogni-research/README.md) · [plugin guide](https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-research.md)
