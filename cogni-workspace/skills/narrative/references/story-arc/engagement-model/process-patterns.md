# Process: How-An-Engagement-Unfolds Patterns

## Element Purpose

Walk the buyer through the typical arc of an engagement as a concrete sequence of things they will see, sign, and receive. Process is the longest element in this arc because it is what the buyer came to the page to read.

**Word Target:** 28% of target length (the longest element — this is the meat of the page).

## Source Content Mapping

Extract from:
1. **Solution phases** (primary)
   - `solutions/*.json` — each solution carries `phases[]`. Aggregate across solutions to find the canonical shape.
2. **Cadence signals** (secondary)
   - Company description and positioning — weekly, sprint-based, shift-aligned.
3. **Artifacts referenced in solution descriptions**
   - Any mention of specific deliverables (data contracts, baselines, runbooks, playbooks) is an artifact the Process element should name.

## Process Extraction Patterns

### Pattern 1: The Canonical Phase Aggregation

**When to use:** The portfolio has multiple solutions with similar phase structures.

**Structure:**
```markdown
Scan: 8 solutions, 6 of them have phases: "Discovery → Data Contract → Instrumented Baseline → Pilot → Rollout → Handover".
Canonical structure: 6 phases (the intersection of the top 4 solutions by relevance tier).
   → Use this canonical structure as the spine of the Process element. Note where specific solutions diverge but do not list per-solution variants.
```

**Why this works:** Buyers want to know what "typical" looks like. Per-solution variation goes on capability pages.

---

### Pattern 2: The Artifact-First Phase

**When to use:** Every phase needs to be anchored in a concrete deliverable.

**Structure:**
```markdown
Phase name: Data Contract
Artifact: Signed data contract document
What happens: Negotiation between business and IT over data ownership, access, freshness, quality.
What buyer sees: Draft contract reviewed in weekly working session; final version signed.
What buyer signs: Data Contract, access-rights matrix.
Time band: 2–4 weeks.
```

**Why this works:** Artifact-first framing removes generic language. "Discovery" means nothing; "a signed data contract" is a thing the buyer can point to.

---

### Pattern 3: The Phase-Level Principle Callout

**When to use:** A Principle from Element 1 is especially visible in one phase — call it out explicitly.

**Structure:**
```markdown
Phase 2: Instrumented Baseline.
Artifact: Baseline dashboard showing current KPIs on the narrow slice of operations we are about to improve.
Connection to Principle 2 (Proof before scale): "This is the phase where 'proof before scale' shows up. You will see the baseline numbers on the dashboard before we commit to any broader rollout. If the numbers do not move in Phase 3, we stop — no excuses, no scope expansion."
```

**Why this works:** Buyers who noticed a Principle they liked see it operationalised in a specific phase. Coherence across elements = trust.

---

### Pattern 4: The Skimmable Phase Card

**When to use:** Process is meant to be scanned, not read. Every phase should be presentable in a skimmable card.

**Structure:**
```markdown
**Phase 2: Instrumented Baseline (3–6 weeks)**

- **What happens:** We deploy lightweight instrumentation on the narrow slice of operations we are about to improve, to establish measurable baseline KPIs.
- **What you see:** A baseline dashboard refreshed daily, surfaced in a weekly working demo.
- **What you sign:** The baseline numbers, signed by your business owner and IT.
- **Traceable principle:** Proof before scale — these baseline numbers are the bar Phase 3 has to clear.
```

**Why this works:** Buyers scan this in 20 seconds and come away with a mental model of the engagement.

## Presentation Structure

### Opening: The Canonical Walkthrough Framing

```markdown
Here is what those principles look like in a typical engagement. The shape is the same whether we are building a predictive maintenance system or a contract-first data layer — what changes is the depth of each phase, not the phases themselves.
```

### Body: 4–6 Phase Cards

Present each phase as a named card with:
- **Phase number and name**
- **Time band** (in parentheses after the name)
- **What happens** — 1–2 sentences of what the work is
- **What you see** — the artifact(s) the buyer will interact with
- **What you sign** — the approvals the phase requires (may be "nothing" for purely observational phases)
- **Traceable principle** (optional but valuable) — which of the Principles from Element 1 is most visible here

### Closing: Handoff to Partnership

```markdown
None of this works unless you bring a few things to the table as well. The next section names them directly.
```

## Techniques Checklist

### Artifact Naming (mandatory)

- [ ] **Every phase names at least one concrete artifact**
  - A signed contract, a dashboard, a runbook, a deployed system — something the buyer will receive.
  - Phases without artifacts are verbs in disguise.

### Time Bands (mandatory)

- [ ] **Every phase has a time band**
  - "2–4 weeks" is better than "a few weeks"
  - "3–6 months" is better than "several months"
  - Ranges protect against overclaim; precision signals honesty.

### Solution Agnosticism (mandatory)

- [ ] **No phase is specific to one solution**
  - If Phase 3 only exists in predictive maintenance, it belongs on the predictive-maintenance capability page.
  - Process at the engagement-model level describes the shape that applies across the portfolio.

### Scannable Cards

- [ ] **Each phase is presentable as a skimmable card**
  - Bullet structure, bold labels, short sentences.
  - Prose walls kill Process elements — buyers bail after the second paragraph.

### Principle Traceability (optional but valuable)

- [ ] **Call out at least one Principle appearing in a specific phase**
  - Creates coherence with Element 1.
  - Rewards buyers who remembered a Principle they liked.

## Quality Checkpoints

### Content Requirements

- [ ] 4–6 phases (aggregated from portfolio solutions)
- [ ] Every phase has an artifact
- [ ] Every phase has a time band
- [ ] No phase is solution-specific
- [ ] At least one phase calls out a traceable Principle

### Structure Requirements

- [ ] Opening canonical walkthrough framing
- [ ] Skimmable phase cards with consistent structure
- [ ] Closing transition to Partnership
- [ ] Word count within proportional range (+/-10%)

## Common Mistakes

### Mistake 1: Generic Phase Names With No Artifacts

**Bad:**
> **Phase 1: Discovery.** We understand your needs.
> **Phase 2: Design.** We design the solution.
> **Phase 3: Delivery.** We build and deliver.
> **Phase 4: Support.** We provide ongoing support.

**Why it fails:** Could describe any services company. No artifacts, no time bands, no specificity.

**Good:**
> **Phase 1: Data Contract (2–4 weeks)**
> - **What happens:** We sit with your IT and business owners and negotiate a contract defining which systems contribute what data, under which access controls, with which freshness SLA.
> - **What you see:** A draft Data Contract document in week 1, reviewed in weekly working sessions, signed by end of phase.
> - **What you sign:** The Data Contract and an access-rights matrix.
> - **Traceable principle:** Contract before code.

---

### Mistake 2: Solution-Specific Phase

**Bad:**
> **Phase 3: Train predictive maintenance model on 6 months of sensor data.**

**Why it fails:** Specific to one solution. Belongs on the predictive-maintenance capability page, not the How We Work page.

**Good:**
> **Phase 3: Instrumented Baseline (3–6 weeks)**
> We deploy lightweight instrumentation on the narrow slice of operations we are about to improve, to establish measurable baseline KPIs before we change anything. This phase applies whether the eventual work is predictive maintenance, contract-first data layers, or anything else in our portfolio.

## Language Variations

### German Adjustments

```markdown
**Phase 2: Instrumentierte Baseline (3–6 Wochen)**

- **Was passiert:** Wir instrumentieren den schmalen Operationsausschnitt, den wir verbessern werden, mit leichtgewichtigen Messungen, um messbare Baseline-KPIs zu etablieren — bevor wir irgendetwas ändern.
- **Was Sie sehen:** Ein Baseline-Dashboard, das täglich aktualisiert und im wöchentlichen Demo präsentiert wird.
- **Was Sie unterschreiben:** Die Baseline-Zahlen, unterschrieben von Ihrem Fachverantwortlichen und der IT.
- **Verbundenes Prinzip:** Beweis vor Skalierung — diese Baseline-Zahlen sind die Messlatte für Phase 3.
```

## Related Patterns

- See `principles-patterns.md` for the principles Process makes visible
- See `partnership-patterns.md` for what the buyer needs to contribute to Process
- See `outcomes-patterns.md` for what Process produces
