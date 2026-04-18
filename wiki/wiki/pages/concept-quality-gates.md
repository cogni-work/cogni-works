---
id: concept-quality-gates
title: Three-layer quality gate (structural, quality, stakeholder)
type: concept
tags: [quality, validation, agents, blocking, cogni-portfolio]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md
status: stable
---

Most entity-producing plugins follow a three-layer pipeline that runs before downstream generation is allowed to proceed.

## The three layers

1. **Structural validation** — scripts check JSON schema compliance: required fields present, slugs well-formed, references resolve. Runs in milliseconds, catches mechanical errors before any LLM work begins.
2. **Quality assessment** — LLM-based haiku assessor agents evaluate content dimensions specific to the entity type. For features: mechanism clarity, differentiation, specificity. For propositions: buyer-specificity, differentiation from table stakes, outcome grounding. Each dimension scored; below-threshold scores flag the entity for improvement.
3. **Stakeholder review** — assessor agents simulate three reader perspectives. Feature sets reviewed by a product manager, a strategist, and a pre-sales engineer. Proposition sets reviewed by a buyer, a sales rep, and a marketer. Verdict per perspective: accept/warn/fail.

## Blocking, not advisory

Quality gates block downstream generation by default. Features must pass quality assessment before propositions can be generated. Propositions that fail high-weight criteria in the consulting Develop phase are excluded from Option Synthesis unless the consultant explicitly reinstates them.

The pattern is intentional: it is cheaper to fix a vague feature description now than to regenerate 12 propositions after the problem is discovered downstream.

## Model strategy

Quality assessors run on haiku because the workload is high-volume rubric evaluation across 3-5 dimensions per entity — see [[concept-agent-model-strategy]]. Stakeholder reviewers also run on haiku for the same volume reason.

## Most prominent in cogni-portfolio

cogni-portfolio is the cleanest reference implementation. cogni-trends and cogni-research apply variations. The orchestrator-level decision to *block* vs *warn* is the [[concept-orchestrator-pattern]]'s "warn-not-block" exception — most phase gates are advisory but the Develop proposition gate blocks.

**Source**: [insight-wave/CLAUDE.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md) (see also [design-philosophy.md](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/design-philosophy.md))
