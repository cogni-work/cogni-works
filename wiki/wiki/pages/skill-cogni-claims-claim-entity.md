---
id: skill-cogni-claims-claim-entity
title: "cogni-claims:claim-entity (skill)"
type: entity
tags: [cogni-claims, claims, verification, skill, data-model, contract, multilingual]
created: 2026-04-17
updated: 2026-04-20
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-claims/skills/claim-entity/SKILL.md
status: stable
related: [plugin-cogni-claims, skill-cogni-claims-claims, concept-claim-lifecycle, concept-claims-propagation, agent-cogni-claims-claim-verifier, agent-cogni-claims-source-inspector]
---

> The shared data contract inside [[plugin-cogni-claims]] — three record types, five deviation types, four severity levels, one workspace layout. Any plugin submitting or consuming claims reads this first.

`claim-entity` is the cross-plugin API contract for claim verification. It does not orchestrate or run verification (that's `[[skill-cogni-claims-claims]]`) — it defines the structures every submitting plugin must produce and every consuming plugin can rely on. Skills in [[plugin-cogni-research]], [[plugin-cogni-portfolio]], [[plugin-cogni-trends]], and [[plugin-cogni-consulting]] all conform to this schema when they submit sourced assertions for verification.

## Key takeaways

- **Three record types compose the lifecycle.** `ClaimRecord` (a verifiable statement + its state), `DeviationRecord` (one discrepancy between claim and source), `ResolutionRecord` (the user's decision on a deviated claim). See [[concept-claim-lifecycle]] for how they chain together.
- **Five deviation types.** `misquotation`, `unsupported_conclusion`, `selective_omission`, `data_staleness`, `source_contradiction`. These are the only categories verifier agents emit — downstream consumers can key off the type without string-matching explanations.
- **Four severity levels.** `low` (minor imprecision), `medium` (could mislead), `high` (significant misrepresentation), `critical` (complete contradiction or fabrication). Dashboards and routing logic use severity to prioritize.
- **Five resolution actions.** `corrected`, `disputed`, `alternative_source`, `discarded`, `accepted_override`. The user picks one per deviated claim — there is no default.
- **Epistemic humility is load-bearing.** `DeviationRecord.explanation` must use hedged language ("the claim appears to overstate", "the source suggests a different figure"). Never "the claim is wrong". The rule exists because LLM-based deviation detection can be wrong, and definitive language would train users to stop reviewing findings. See [[concept-claims-propagation]] on why this flows into entity-file correction cascades.
- **Workspace layout is fixed.** `{working_dir}/cogni-claims/claims.json` (registry), `sources/{hash}.json` (per-URL source cache), `history/{id}.json` (audit trail per claim). Any consumer reading this layout can build tooling on top without depending on `[[skill-cogni-claims-claims]]` internals.

## Status lifecycle

```
unverified ──> verified           (no deviations)
unverified ──> deviated           (deviations detected)
unverified ──> source_unavailable (source unreachable)
deviated   ──> resolved           (user resolves all deviations)
any status ──> re-verify          (returns to verified/deviated/source_unavailable)
```

The `entity_ref` and `propagated_at` fields on a `ClaimRecord` are the hook that lets corrections cascade back to the originating entity files (see [[concept-claims-propagation]]).

## Design principles

Five constraints exist because claim verification involves LLM judgment, which can be wrong:

1. **User confirmation for all resolutions** — auto-resolving risks silently accepting bad corrections.
2. **Findings are assessments, not facts** — hedged explanations keep the user skeptical.
3. **Conservative over aggressive** — a false positive erodes trust more than a missed flag.
4. **Always include `source_excerpt`** — without the evidence, the user cannot evaluate a finding.
5. **Unverifiable is not verified** — `source_unavailable` correctly communicates the gap; defaulting to `verified` would be dishonest.

## Cross-plugin integration

| Plugin | Direction | How it uses this contract |
|--------|-----------|---------------------------|
| [[plugin-cogni-research]] | submits | `verify-report` extracts claims from draft → submits |
| [[plugin-cogni-portfolio]] | submits | `portfolio-verify` submits claims from web-sourced entities; reads `entity_ref` to propagate corrections |
| [[plugin-cogni-trends]] | submits | `trend-report` submits post-generation |
| [[plugin-cogni-consulting]] | submits | `consulting-deliver` runs final verification before deliverables |
| [[skill-cogni-claims-claims]] | orchestrates | Consumes this contract for submit/verify/resolve operations |

## References in the source

- `references/schema.md` — full JSON schema, field tables, batch submission format
- `references/workspace-conventions.md` — directory structure, file formats, caching rules
- `examples/claim-lifecycle.json` — end-to-end example of a claim progressing through all three record types

## Sources

- [SKILL.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/cogni-claims/skills/claim-entity/SKILL.md)
