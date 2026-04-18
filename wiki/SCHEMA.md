# SCHEMA — insight-wave

_Created: 2026-04-17_

This file is the contract for how this wiki is structured. It lives inside the wiki (not inside the plugin) so the wiki remains self-describing even if cogni-wiki is uninstalled or replaced.

## Directory layout

```
<wiki-root>/
├── SCHEMA.md                 This file — conventions and contract
├── raw/                      Immutable source documents (papers, URLs, transcripts, images, data)
├── assets/                   Attachments referenced from pages (screenshots, figures, exports)
├── wiki/
│   ├── index.md              One-line summary catalog of every page
│   ├── log.md                Append-only operation log
│   ├── overview.md           Evolving "state of the wiki" synthesis
│   └── pages/                Flat directory of slug-named markdown pages
└── .cogni-wiki/
    └── config.json           Plugin metadata
```

## Page frontmatter

Every file in `wiki/pages/` begins with YAML frontmatter:

```yaml
---
id: <slug>                       # Must match filename without .md
title: <human-readable title>
type: concept | entity | summary | decision | learning | note
tags: [tag1, tag2]
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources:                         # Optional — relative paths or URLs
  - ../raw/paper-xyz.pdf
  - https://example.com/article
---
```

### Types

- **concept** — an idea, framework, or model
- **entity** — a person, organization, product, or place
- **summary** — a condensed version of a raw source
- **decision** — a choice made and the reasoning behind it
- **learning** — a generalized takeaway
- **note** — a loose observation that hasn't crystallized into a concept yet

## Linking

- Use `[[page-slug]]` for links to other wiki pages
- Use standard markdown links for external URLs and raw sources: `[label](../raw/file.pdf)`
- Every `[[link]]` should be backed by an actual file in `wiki/pages/`; the `wiki-lint` skill reports broken links

## Log format

Append only. Format:

```
## [YYYY-MM-DD] {ingest|query|lint|update|setup} | one-line note
```

Never rewrite or reorder log entries.

## Index format

`wiki/index.md` lists every page as:

```
- [[page-slug]] — one-sentence summary
```

Grouped under `##` category headings. The `wiki-ingest` skill maintains this file.

## Golden rules

1. **Claude writes the wiki; the user curates the raw sources.**
2. **Every query reads the wiki — never answers from memory.**
3. **Diff before write** — page updates show the planned change before modifying a file.
4. **Citations required** — any new claim in a page links to a source in `raw/` or an external URL.
5. **Append-only log** — operations are recorded, never rewritten.

## insight-wave-specific conventions

This wiki is **vendor-curated and read-only by intent**. End users should not run `wiki-ingest`, `wiki-update`, or file `wiki-query` learnings back to this wiki — it ships bundled with the cogni-workspace plugin and is refreshed in lockstep with plugin updates. Users who want their own personal knowledge base should run `cogni-wiki:wiki-setup` to create a separate wiki.

### Source pointers, not file paths

Pages reference upstream insight-wave source files via **skill identifier + GitHub URL**, not relative paths. This keeps links stable across the three locations the wiki may live in (`insight-wave/wiki/` for repo clones, `cogni-workspace/wiki/` pre-publish, `~/.claude/plugins/.../cogni-workspace/wiki/` post-install).

Convention for skill pages:

```
**Source**: `cogni-portfolio:propositions`
([SKILL.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/cogni-portfolio/skills/propositions/SKILL.md))
```

For non-skill sources (CLAUDE.md, docs/, references/), use the GitHub blob URL alone — no file path.

### Thin pages by design

Skill, agent, and plugin pages stay **thin (~50–150 words body)**: name, type, 1-paragraph description (lifted from frontmatter, not re-synthesized), key inputs/outputs, `[[wikilinks]]` to related concept and plugin pages, and the source pointer above. Pages **must not duplicate** SKILL.md content — they describe what it is and point to it.

Anchor pages (architecture, workflows, cross-cutting concepts) may be more synthesis-heavy, but cap below ~5,000 words so a single page never dominates the query budget.
