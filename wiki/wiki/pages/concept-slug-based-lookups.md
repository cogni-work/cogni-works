---
id: concept-slug-based-lookups
title: Slug-based lookups (kebab-case identifiers across plugins)
type: concept
tags: [conventions, slugs, identifiers, cross-plugin]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md
status: stable
---

All cross-plugin references use kebab-case slug identifiers. Slugs are derived from entity names at creation time and remain stable through the entity's lifecycle.

## Examples

```
cloud-monitoring--mid-market-saas-dach    cogni-portfolio proposition (paired entity)
automotive-ai-predictive-maintenance-abc12345  cogni-trends trend
siemens-manufacturing-pitch              cogni-sales pitch
acme-market-entry                        cogni-consult engagement
claim-550e8400-e29b-41d4-a716            cogni-workspace claim (UUID-v4 slug)
```

Slugs serve as both the file name and the cross-plugin identifier. cogni-consult files each deliverable's research under `action-fields/<field-slug>/research/<topic-slug>.md`, addressing the action field and the topic by slug rather than by an internal ID. When cogni-trends exports a bridge file referencing a portfolio feature, it uses the feature slug.

## The double-dash convention

In cogni-portfolio, paired entities (a feature combined with a market) use a double-dash separator: `feature--market`. This distinguishes paired entities from single entities both visually and programmatically. The `cascade-rename.sh` script handles slug renaming across dependent entities when a user renames a feature or market after the fact.

## Why UUIDs for claims

Claim records use UUID-v4 slugs (`claim-550e8400-...`) rather than name-derived slugs because claims have no natural name — their identifier is their identity. See [[concept-claim-lifecycle]].

## Why slugs over numeric IDs

Two reasons:

- **Human-readable in cross-plugin references.** When you read a cogni-consult engagement's `consult-project.json` and see `plugin_refs.knowledge_base: "dach-cloud-expansion"`, you know which knowledge base it binds without opening anything.
- **Stable across reorganization.** Numeric IDs require a registry; slugs are the file system. Moving entities between projects only requires updating path references, not rewriting identifiers.

This pattern combines with [[concept-data-isolation]] to make cross-plugin reads predictable and human-debuggable. See also [[concept-naming-conventions]] for the broader naming rules.

**Source**: [docs/architecture/design-philosophy.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md)
