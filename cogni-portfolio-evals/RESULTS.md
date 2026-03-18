# cogni-portfolio Core Messaging Skills — Eval Results

## Evaluation Overview
- **Date**: 2026-03-18
- **Skills tested**: features, propositions, customers, compete
- **Test targets**: T-Systems (regression), Mainova (generalization)
- **Stakeholder reviewers**: T-Systems CMO (internal GTM), Mainova CDO (buyer)
- **Iterations**: 3 (baseline + 2 improvement cycles)

## Final Scores

| Metric | Iter 0 | Iter 1 | Iter 2 |
|--------|--------|--------|--------|
| CMO overall | 3.5 | **4.2** | — |
| CDO overall | 3.6 | 3.8 | **4.0** |
| Structural (propositions batch) | 82.6% | **100%** | — |
| Structural (proposition single) | 85.7% | 100% | **100%** |
| Structural (compete) | 75% | **100%** | — |
| Structural (customers) | 100% | — | — |

## Root Causes Found & Fixed

| Issue | Root Cause | Fix | Impact |
|-------|-----------|-----|--------|
| IS statements too short (45 fails) | proposition-generator.md IS guidance | Enforce 20-35 words, no compression | +17.4% structural |
| Evidence source_url: null | proposition-generator.md web research optional | Made research mandatory, min 2 entries | CMO evidence 2→4 |
| Vendor-centric DOES | proposition-generator.md DOES guidance | Buyer as grammatical subject mandate | CMO sales readiness 4 |
| MEANS no quantification | proposition-generator.md MEANS guidance | Required grounded numbers with sources | CDO credibility +1 |
| Weak differentiation | proposition-generator.md missing differentiator injection | Read portfolio.json differentiators | CMO differentiation 3→4 |
| Trap questions unbounded (9) | compete/SKILL.md no count limit | Added 3-4 bound + quality criteria | 75%→100% structural |
| Missing procurement persona | customers/SKILL.md profile guidance | Expanded to 2-4, veto-holder guidance | CDO decision support |
| IS vendor jargon leaking | proposition-generator.md no jargon filter | Plain-language replacement rules | CDO language 3→4 |
| MEANS ungrounded percentages | proposition-generator.md MEANS guidance | Must cite source or qualify "bis zu" | CDO credibility |
| Repeated talking points | propositions/SKILL.md batch guidance | Added deduplication cross-check | Portfolio coherence |

## Files Modified (source skills only)

1. `agents/proposition-generator.md` — IS, DOES, MEANS, evidence, differentiation, jargon, quantification
2. `skills/compete/SKILL.md` — trap questions section + JSON template
3. `skills/customers/SKILL.md` — profile count + veto-holder guidance
4. `skills/propositions/SKILL.md` — batch deduplication section
