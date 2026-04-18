---
id: plugin-cogni-wiki
title: "cogni-wiki (plugin)"
type: entity
tags: [cogni-wiki, plugin, wiki, knowledge-base, rag-alternative, karpathy, compounding-knowledge]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-wiki/README.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-wiki.md
status: stable
---

> **Incubating** (v0.0.4) — skills may change or be removed at any time.

A better RAG for personal and small-team knowledge work. Claude maintains a persistent, interlinked markdown wiki that compiles sources once at ingest — no embeddings, no vector store, no re-discovery per query. Answers come from the wiki (not memory), contradictions are surfaced at ingest (not missed at retrieval), and knowledge compounds instead of starting from zero. Based on Andrej Karpathy's LLM Wiki pattern.

## Layer

Cross-cutting utility (Platform & Quality tier). The engine that this very wiki you're reading runs on.

## Skills

| Skill | Purpose |
|-------|---------|
| `cogni-wiki:wiki-setup` | Bootstrap a new wiki at a user-chosen directory |
| `cogni-wiki:wiki-ingest` | Ingest a source document (file, URL, pasted text) — write a page, update index, run backlink audit |
| `cogni-wiki:wiki-query` | Answer a question by reading the wiki — never from memory |
| `cogni-wiki:wiki-update` | Revise an existing page when knowledge has changed; diff-before-write discipline |
| `cogni-wiki:wiki-lint` | Audit for broken wikilinks (double-bracket references with no matching page), orphan pages, stale dates, missing frontmatter |
| `cogni-wiki:wiki-resume` | Show status, activity, and recommended next action |
| `cogni-wiki:wiki-dashboard` | Generate a self-contained HTML dashboard — pages by type, tag cloud, backlink graph, recent activity |

## The pattern

Three layers: **raw sources** (`raw/`, immutable), **the wiki** (`wiki/`, LLM-maintained markdown with YAML frontmatter and double-bracket wikilinks), **the schema** (`SCHEMA.md`, the contract — copied into every wiki at setup time so the wiki is self-describing even if the plugin is uninstalled).

Five page types: `concept`, `entity`, `summary`, `decision`, `learning`, `note`. Every page has `id` (matches filename), `title`, `type`, `created`, `updated`, optional `tags`, `sources`, `related`, `status`.

## Why over RAG

RAG rediscovers the same information every query. A wiki **accumulates** — each ingest distills raw material into reusable form; each query reinforces or extends that form. After N ingests the wiki is a dense, structured artifact that costs pennies to read end-to-end. Strongest evidence: combined wiki+RAG outperforms either alone.

## Honest scope

Sweet spot is bounded knowledge bases under ~50K–100K tokens of compiled content. RAG remains the right choice for large-scale corpora (100K+ documents), rapidly changing data, strict source-level attribution, multi-domain enterprise with RBAC.

## How insight-wave uses it

cogni-workspace bundles this wiki at `cogni-workspace/wiki/`. Users query it via `cogni-workspace:ask`. cogni-research can read wiki instances as a source mode. Future: cogni-help could consult the wiki as its first lookup.

**Source**: [cogni-wiki README](https://github.com/cogni-work/insight-wave/blob/main/cogni-wiki/README.md) · [plugin guide](https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-wiki.md)
