# Why You: Portfolio Capability Patterns (Theme Thesis)

## Element Purpose

Convert the theme's solution templates and strategic possibilities into **strategic capabilities** — backed by the value-modeler portfolio, these create lasting value and are difficult to replicate. Write for the customer, not for an internal sales team — explain what the capability does for them and why it's a durable investment.

**Word Target:** 30% of theme section target (largest element — this is the portfolio showcase)

## Source Content Mapping

Extract from theme data:

1. **Solution Templates** (primary) — `SOLUTION_TEMPLATES[]` from orchestrator
   - Each ST has `name`, `category`, `enabler_type`
   - These become the **IS layer** of strategic capabilities
   - If empty: construct strategic capabilities from P-candidates directly

2. **P-candidates** (Neue Horizonte) — `chain.possibilities[]` for each value chain
   - Strategic opportunities with quantified outcomes
   - `opportunities_md` from enriched-trends: the DOES layer evidence
   - How these capabilities change the organization's performance

3. **S-candidates** (Digitales Fundament) — `chain.foundation_requirements[]`
   - Capability prerequisites that take time to build
   - `evidence_md` from enriched-trends: the MEANS layer evidence
   - Why these capabilities create barriers to replication

4. **Claims** — filtered by P-candidate and S-candidate claims_refs
   - Quantitative outcomes for DOES layer
   - Capability gap costs for MEANS layer

## IS-DOES-MEANS as Invisible Scaffolding

The IS-DOES-MEANS logic guides what content to include, but must NEVER appear as visible labels in the output. No "Was es ist:", no "Was es für Sie leistet:", no "Warum das ein nachhaltiger Vorteil ist:". Write flowing prose instead.

### How to apply (invisibly)

For each solution template (1-3 capabilities per theme), write 2-3 paragraphs of continuous prose under a bold capability name heading:

1. **Open with a concrete definition** (IS logic) — Source: ST `name` + `category` + P-candidate context. An executive should know what this is in 20 seconds. 1-2 sentences.

2. **Flow into quantified outcomes** (DOES logic) — Source: P-candidates `opportunities_md` + claims. Use You-Phrasing ("Sie reduzieren...", "Ihre ... erreicht...") and Number Plays (ratios, before/after). 2-3 quantified outcomes with citations.

3. **Close with durability** (MEANS logic) — Source: S-candidates `evidence_md` + foundation requirements. Why this is a long-term investment: time, domain expertise, organizational maturity needed. Specific timeframe for capability building.

### Example (flowing prose, no labels)

```markdown
**Smart Grid Digital Twin & Prädiktive Wartung**

Ein Echtzeit-Virtualabbild Ihrer gesamten Netzinfrastruktur, das physische
Sensordaten mit KI-Analytik verbindet. Sie senken Wartungskosten um 18–25% und
reduzieren ungeplante Ausfallzeiten um 30–50%<sup>[1]</sup>. Ihre
Netzoperationszentrale wird zur datengesteuerten Kommandozentrale — KI-Systeme
erkennen Ausfälle bis zu 72 Stunden im Voraus<sup>[2]</sup>. Ein akkurater
Digital Twin entsteht nicht über Nacht: 12–18 Monate Sensorkalibrierung und
domänenspezifische Modellierung machen dies zu einer Investition, die sich mit
jedem Datenzyklus verstärkt.
```

Note: no "Was es ist:", no "Was es für Sie leistet:", no labeled sections — just prose that naturally flows from definition → outcomes → durability.

## strategic capability When No Solution Templates

If `SOLUTION_TEMPLATES` is empty, construct strategic capabilities from P-candidates:

1. Group P-candidates by strategic opportunity type
2. Use the P-candidate's `name` as the IS basis
3. Use `opportunities_md` for DOES
4. Use S-candidates for MEANS (same as with STs)

## Solution Templates Table

If `SOLUTION_TEMPLATES` is non-empty, include inline after strategic capability prose:

```markdown
| # | Solution | Category | Enabler Type |
|---|----------|----------|-------------|
| 1 | {st.name} | {st.category} | {st.enabler_type} |
```

Brief description of each ST and how it addresses the theme's strategic question. 1-2 sentences per ST.

## Quality Checkpoints

- [ ] 1-3 capabilities described (from STs or P-candidates)
- [ ] Each opens with a concrete definition (executive understands in 20 seconds)
- [ ] You-Phrasing for outcomes ("Sie reduzieren...", "Ihre ... erreicht...")
- [ ] 2-3 quantified outcomes with citations per capability
- [ ] Durability argument with specific timeframe
- [ ] S-candidate evidence for why this is a long-term investment
- [ ] NO visible IS/DOES/MEANS labels — flowing prose only
- [ ] Solution templates table included after prose (if STs available)
- [ ] Word count within proportional range (+/-10% tolerance)
- [ ] Smooth transitions from Why Now and to Why Pay

## Common Mistakes

❌ **Labeled template:** "**Was es ist:** ... **Was es für Sie leistet:** ... **Warum das ein nachhaltiger Vorteil ist:** ..."
✓ **Flowing prose:** "Ein Echtzeit-Virtualabbild Ihrer Netzinfrastruktur, das Sensordaten mit KI-Analytik verbindet. Sie senken Wartungskosten um 18–25%<sup>[1]</sup>. Ein akkurater Digital Twin entsteht nicht über Nacht: 12–18 Monate Kalibrierung machen dies zu einer Investition, die sich mit jedem Datenzyklus verstärkt."

❌ **Feature list:** "The portfolio includes: Digital Twin Platform, Predictive Maintenance Suite, Customer Portal."
✓ **Capability narrative:** Each gets its own bold heading and 2-3 paragraphs of prose.

❌ **Weak durability:** "This is a difficult capability to build."
✓ **Specific:** "12–18 Monate Sensorkalibrierung und domänenspezifische Modellierung — Technologie-Einkauf ist schnell, Kalibrierungswissen ist langsam."

## Language Variations

### German Style

```markdown
**Digitale Zwillingsplattform**

Echtzeit-Virtualabbild der Netzinfrastruktur, das OT-Sensordaten mit IT-Analysen
integriert und prädiktive Wartung wie Lastoptimierung in einem System ermöglicht.
Sie reduzieren ungeplante Ausfälle um 34% und verlängern die Anlagenlebensdauer
um 12 Jahre<sup>[1]</sup>. Ihre Netzplanung basiert auf Echtzeit-Zustandsdaten
statt auf Kalenderintervallen — Resultat: 23% niedrigere Wartungskosten bei
2,3x höherer Prognosegüte<sup>[2]</sup>. Präzise digitale Zwillinge erfordern
18 Monate Sensorkalibrierung und Domänenmodell-Training<sup>[3]</sup>.
Technologie-Kauf ist schnell. Kalibrierungswissen ist langsam. Wer heute
beginnt, hat 2027 ein Asset, dessen Wert sich mit jedem Datenzyklus verstärkt.
```

## Related Patterns

- See `why-change-patterns.md` for the unconsidered need these positions address
- See `why-now-patterns.md` for the urgency that demands these capabilities
- See `why-pay-patterns.md` for the cost of NOT building these positions
