---
id: concept-naming-conventions
title: Naming conventions (skills, agents, slugs, scripts)
type: concept
tags: [conventions, naming, skills, agents, slugs, scripts]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/plugin-anatomy.md
  - https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md
status: stable
---

Names in insight-wave follow tiered patterns. Consistency is enforced by `cogni-workspace/scripts/check-skill-names.sh` — run before submitting a PR.

## Skill names

| Tier | When to use | Pattern | Examples |
|------|-------------|---------|----------|
| A — Domain-unique | Only one plugin would ever own this word | bare name | `propositions`, `customers`, `compete` |
| B — Generic verb/noun | Multiple plugins could have this skill | `{domain}-{verb}` | `portfolio-scan`, `trends-catalog`, `copy-reader` |
| C — Cross-plugin | Skill spans two domains | descriptive compound | `trends-bridge` |

Order is always `domain-verb`, never `verb-domain` — this groups skills alphabetically by plugin domain in the skill list.

**Generic words that always require a prefix**: `setup`, `scan`, `ingest`, `export`, `dashboard`, `verify`, `bridge`, `catalog`, `reader`, `config`, `status`, `analyze`, `resume`. The check script blocks PRs that use these bare.

## Agent names

Role-based patterns:

- **Worker agents**: `{role}-{task}` — `section-researcher`, `claim-verifier`
- **Orchestrator-wrapper agents**: `{output-type}` — `storyboard`, `web`
- **Assessment agents**: `{entity}-{task}-assessor` — `proposition-quality-assessor`, `feature-review-assessor`

The orchestrator-wrapper pattern reflects [[concept-orchestrator-pattern]] — the agent's name is the output, not the action.

## File slugs

All entity slugs use kebab-case derived from the entity or concept name. No underscores, no camelCase, no spaces. cogni-portfolio's double-dash convention (`feature--market`) marks paired entities. cogni-claims uses UUID-v4 slugs because claims have no natural name. See [[concept-slug-based-lookups]] for the broader convention.

## Script names

Script names describe the operation in imperative form: `create-entity.sh`, `project-status.sh`, `cascade-rename.sh`. All scripts return JSON — see [[concept-script-output-format]] — and are stdlib-only.

## Why these rules exist

The tiered skill naming prevents collisions in the global skill namespace and makes skill discovery deterministic (scripts can list "all cogni-portfolio skills" by prefix). The agent naming convention encodes responsibility: reading the name tells you whether you're looking at a worker, orchestrator-wrapper, or assessor without opening the file.

**Source**: [docs/architecture/plugin-anatomy.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/plugin-anatomy.md) (validated by [check-skill-names.sh](https://github.com/cogni-work/insight-wave/blob/main/cogni-workspace/scripts/check-skill-names.sh))
