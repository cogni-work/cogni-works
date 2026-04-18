---
id: concept-plugin-maturity-model
title: Plugin maturity model (version-derived stability contract)
type: concept
tags: [versioning, maturity, semver, marketplace, plugin-json, marketplace-json]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md
status: stable
---

Plugin maturity is hard-derived from the version — there is no manual maturity field in `plugin.json`. The version itself is the stability contract.

## The five stages

| Stage | Version Range | User Expectation |
|-------|--------------|-----------------|
| **Incubating** | `0.0.x` | Skills may change or be removed at any time |
| **Preview** | `0.x.x` (x≥1) | Core skills defined but may change. Feedback welcome |
| **Released** | `1.x.x` | Stable API. Breaking changes only at major bumps |
| **Established** | `2.x.x+` | Proven, deep ecosystem integration |
| **Archived** | Any + `"archived": true` | Security patches only |

Full reference: `cogni-docs/references/maturity-model.md`.

## Bump discipline

The patch version bumps after **any** change to skills, agents, or structure. Plugin versions live in `.claude-plugin/plugin.json` and **must** be mirrored to `.claude-plugin/marketplace.json` for Claude Desktop's update detection — bumping one without the other ships an invisible update.

Marketplace sync is driven by git commit hash, but Desktop reads the marketplace.json version field for its update prompt.

## Maturity boundary crossings

Two boundaries are stability contracts:

- **0.x → 1.0.0** — Preview to Released. Stable API commitment. Breaking changes from this point require a major bump.
- **1.x → 2.0.0** — Released to Established. Signal that the plugin has proven itself in production and ecosystem-deep integration.

Both crossings need intentional review — they are promises to the user about future change discipline.

## README maturity callout

Each pre-1.0 and archived plugin carries a maturity callout blockquote after the H1 title in the README:

```markdown
> **Preview** (v0.x) — core skills defined but may change.
```

`cogni-docs:doc-generate` injects this automatically based on `plugin.json` version. `cogni-docs:doc-audit` Check 13 enforces consistency between version and callout. See [[concept-readme-convention]].

## Why version-derived rather than declared

Two reasons:

- **No drift possible.** A manual maturity field could fall out of sync with the version. Deriving from the version makes it a single source of truth.
- **Forces honest versioning.** Bumping to 1.0.0 means committing to API stability — not just changing a label. The version itself is the discipline.

**Source**: [insight-wave/CLAUDE.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md)
