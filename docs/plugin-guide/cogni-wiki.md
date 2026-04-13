# cogni-wiki

**Plugin guide** — for canonical positioning see the [cogni-wiki README](../../cogni-wiki/README.md).

---

## Overview

cogni-wiki turns source documents into a persistent, interlinked markdown wiki that Claude maintains across sessions. Instead of re-discovering the same information every query through embedding similarity (the RAG approach), cogni-wiki has Claude compile sources once at ingestion — writing structured summaries, cross-referencing related pages via `[[wikilinks]]`, and flagging contradictions. Every future query reads pre-synthesized articles directly rather than re-deriving answers from scratch.

The plugin implements [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f): knowledge compounds with every ingest, answers trace to readable markdown files, and the wiki is fully portable — plain files, plain backlinks, plain Unix tools.

---

## Key Concepts

| Term | What it means in practice |
|------|--------------------------|
| **Wiki** | A directory of interlinked markdown pages with YAML frontmatter, maintained by Claude and readable by humans |
| **Ingest** | The act of reading a source document, writing a structured wiki page from it, and weaving it into existing knowledge via backlinks |
| **`[[wikilink]]`** | A bidirectional reference between wiki pages — audited after every ingest to keep the knowledge graph connected |
| **SCHEMA.md** | The contract file shipped inside every wiki — defines conventions, frontmatter fields, and linking rules so the wiki is self-describing |
| **Compile-time knowledge** | Karpathy's core insight: synthesize once at ingest, not per query. The wiki gets denser over time instead of re-discovering the same ground |
| **Page type** | Classification of a wiki page: `concept`, `entity`, `summary`, `decision`, `learning`, or `note` |
| **Lint** | A health audit that checks for broken wikilinks, orphan pages, stale dates, missing frontmatter, and contradictions between pages |

---

## Getting Started

Bootstrap a new wiki and ingest your first source:

```
/cogni-wiki:wiki-setup
```

The setup skill asks for a wiki name (e.g., "AI Safety Research") and creates the directory layout:

```
cogni-wiki/ai-safety-research/
├── SCHEMA.md              Conventions and linking rules
├── raw/                   Drop your source documents here
├── wiki/
│   ├── index.md           One-line summary per page
│   ├── log.md             Append-only operation log
│   ├── overview.md        Evolving synthesis
│   └── pages/             Your wiki pages live here
└── .cogni-wiki/config.json
```

Drop a PDF, article, or paper into `raw/`, then:

```
/cogni-wiki:wiki-ingest
```

Claude reads the source, writes a structured summary page with YAML frontmatter, updates the index, and runs a backlink audit to connect the new page to existing knowledge. After 5-10 ingests, run `/cogni-wiki:wiki-lint` to catch any health issues.

---

## Capabilities

### wiki-setup — Bootstrap a new wiki

Run `wiki-setup` to create a fresh wiki at a directory you choose. The skill creates the full layout (raw/, wiki/pages/, assets/, .cogni-wiki/) and seeds the contract files — SCHEMA.md, index.md, log.md, and overview.md. After setup, the wiki is immediately ready to receive sources.

**Example:**
> "Set up a wiki for my AI safety research"

### wiki-ingest — Add sources to the wiki

Run `wiki-ingest` after dropping a source document (PDF, URL, pasted text, transcript) into `raw/`. Claude reads the source, surfaces key takeaways, writes a summary page with YAML frontmatter (id, title, type, tags, sources), updates `wiki/index.md`, appends to `wiki/log.md`, and runs a backlink audit to weave the new page into existing knowledge.

**Example:**
> "Ingest this paper into the wiki"

### wiki-query — Ask questions from the wiki

Run `wiki-query` to ask a question that Claude answers by reading the wiki — never from model memory. The skill consults `wiki/index.md` to find relevant pages, reads them, and synthesizes an answer with `[[wikilink]]` citations. If the wiki doesn't contain the answer, Claude says so rather than hallucinating. Optionally, the answer itself can be filed as a new wiki page so the knowledge compounds.

**Example:**
> "What does my wiki say about constitutional AI?"

### wiki-lint — Audit wiki health

Run `wiki-lint` after every 5-10 ingests as a maintenance pass. The audit checks for broken `[[wikilinks]]`, orphan pages with no inbound links, stale dates, missing frontmatter fields, contradictions between pages, tag typos, and sources that no longer exist in `raw/`. Results are written to a severity-tiered lint report at `wiki/pages/lint-YYYY-MM-DD.md`.

**Example:**
> "Is my wiki healthy?"

### wiki-update — Revise existing pages

Run `wiki-update` when knowledge has changed and a page needs correction. The skill shows you the planned diff before writing (diff-before-write discipline), requires a source citation for every new claim, and sweeps related pages for now-stale statements that the update contradicts. This is the wiki equivalent of `git diff` + manual inspection before commit.

**Example:**
> "Update the constitutional-ai page with findings from this new paper"

### wiki-resume — Status and next action

Run `wiki-resume` to see where you left off — entry count, days since last lint, recent log activity, stale drafts, and a recommended next action. Use this when returning to a wiki after a break.

**Example:**
> "Where was I with my wiki?"

### wiki-dashboard — Visual HTML overview

Run `wiki-dashboard` to generate a self-contained HTML file with pages by type, a tag cloud, a backlink graph, recent activity, and size/age histograms. The file has no external CDN calls — safe to open offline or share with collaborators.

**Example:**
> "Show me the wiki as a dashboard"

---

## Integration Points

### Upstream — no plugin dependencies

cogni-wiki is standalone in v0.0.x. Sources come from the user (documents dropped in `raw/`, URLs, pasted text), not from other plugins.

### Downstream — future integration contracts

These integrations are deferred to post-MVP but documented in the plugin's CLAUDE.md:

| Plugin | Planned integration |
|--------|-------------------|
| cogni-research | Research reports deposit verified findings as wiki pages |
| cogni-narrative | Narrative skill reads wiki pages as structured input |
| cogni-consulting | Engagement knowledge (interviews, decisions, constraints) persists beyond the engagement |
| cogni-claims | Wiki claim extraction and verification via cogni-claims |

---

## Common Workflows

### Workflow 1: Build a knowledge base from a paper collection

**Goal:** Compile 10-20 papers on a topic into a queryable, cross-referenced wiki.

**Steps:**
1. Run `/cogni-wiki:wiki-setup` — name the wiki after your research domain
2. Drop all papers into `raw/`
3. Run `/cogni-wiki:wiki-ingest` for each paper — Claude summarizes, cross-links, and indexes
4. After every 5-10 ingests, run `/cogni-wiki:wiki-lint` to catch orphan pages and contradictions
5. Query freely: "What are the main approaches to constitutional AI?" — answers come from the wiki, not model memory

**Result:** A dense, interlinked knowledge base where every answer traces to a readable markdown file.

### Workflow 2: Maintain a living knowledge base across sessions

**Goal:** Keep a wiki growing over weeks or months as you encounter new sources.

**Steps:**
1. Start each session with `/cogni-wiki:wiki-resume` to see status and recommended next action
2. Drop new sources into `raw/` and ingest them
3. When a page is outdated, run `/cogni-wiki:wiki-update --page <slug>` — review the diff, cite the new source
4. Periodically run `/cogni-wiki:wiki-dashboard` for a visual overview of growth and connectivity

**Result:** A knowledge base that compounds over time — each session leaves it denser than before.

### Workflow 3: Quick-reference lookup during other work

**Goal:** Use your wiki as a reference while working in another plugin.

**Steps:**
1. While working in cogni-research, cogni-consulting, or any other context, ask a question naturally: "What does my wiki say about X?"
2. wiki-query reads the wiki, synthesizes an answer with `[[wikilink]]` citations
3. If the wiki is silent on the topic, Claude says so — you know the gap exists

**Result:** Grounded answers from your own compiled knowledge, not from model training data.

---

## Data Model

Wiki pages are plain markdown with YAML frontmatter:

```yaml
---
id: constitutional-ai
title: Constitutional AI
type: concept
tags: [llms, safety, alignment]
created: 2026-04-12
updated: 2026-04-12
sources: [../raw/bai-et-al-2022.pdf]
---

Constitutional AI (CAI) is a method for training AI systems to be
helpful, harmless, and honest using a set of principles...

## Related
- [[rlhf]] — CAI builds on RLHF but replaces human feedback with...
- [[ai-safety-overview]] — broader context for alignment approaches
```

The wiki's metadata lives in `.cogni-wiki/config.json`:

```json
{
  "name": "AI Safety Research",
  "slug": "ai-safety-research",
  "created": "2026-04-12",
  "entries_count": 23,
  "last_lint": "2026-04-12"
}
```

---

## Relationship to Claude Code Auto-Memory

Claude Code has its own memory system at `~/.claude/projects/.../memory/` — that layer is Claude's learning about *you* (feedback, preferences, session-spanning patterns). cogni-wiki is the complementary primitive: *your* learning about *your domain* — explicitly curated, portable across projects, queryable. Different intent, no duplication.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| "No wiki found" when running any wiki skill | No `.cogni-wiki/config.json` in the current directory or its parents | Run `/cogni-wiki:wiki-setup` first, or `cd` into the wiki directory |
| wiki-query answers from model memory instead of the wiki | The query didn't match any index entries | Check `wiki/index.md` for coverage gaps; ingest more sources on the topic |
| Broken `[[wikilinks]]` reported by lint | A page was renamed or deleted without updating references | Run `/cogni-wiki:wiki-update` on the pages that contain the broken links |
| wiki-ingest creates a page but no backlinks appear | The new page's topic doesn't overlap with existing pages | This is expected for the first few ingests — backlink density grows as the wiki gets denser |
| Dashboard HTML won't open | Browser blocking local file access | Open the HTML file directly from Finder/Explorer, or serve it with `python3 -m http.server` |

---

## Extending This Plugin

cogni-wiki is open-source under AGPL-3.0. The most useful contribution areas are:

- **New page types** — the current taxonomy covers concept, entity, summary, decision, learning, and note. Domain-specific types (e.g., `experiment`, `protocol`, `glossary-entry`) would help specialized wikis.
- **Cross-plugin integration** — the planned cogni-research and cogni-claims integrations are documented but not yet implemented. Contributions that connect wiki ingestion to the research or claims pipeline are high-value.
- **Lint rules** — new health checks (e.g., detecting circular wikilink chains, flagging pages with no sources, or checking citation freshness) expand the quality audit.

See [CONTRIBUTING.md](../../cogni-wiki/CONTRIBUTING.md) for guidelines and the [plugin development guide](../contributing/plugin-development.md) for the plugin standard.
