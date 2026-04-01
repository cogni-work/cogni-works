# Invitation: Entry Point and Handoff Patterns

## Element Purpose

Provide **one clear, low-commitment entry point** and explicitly signal handoff to cogni-sales for deal-specific tailoring. The Invitation closes the narrative by making the first step easy and the next step visible.

**Word Target:** 18% of target length

## Source Content Mapping

Extract from:
1. **Solutions -- entry tiers** (primary source)
   - `solutions/{feature}--{market}.json` implementation_phases or pricing_tiers
   - Look for: proof-of-value, pilot, starter, assessment tiers
   - Identify the lowest-cost, lowest-commitment option

2. **Packages -- starter tier** (secondary source)
   - `packages/{product}--{market}.json` tiers array
   - Look for: the entry-level package that bundles the minimum viable offering

3. **Portfolio context** (framing)
   - `portfolio.json` company context
   - Company name, engagement model, typical entry points

## Entry Point Selection

### Selection Criteria

Choose the entry point that:
1. **Lowest commitment:** Shortest duration, smallest investment, least organizational change
2. **Highest proof:** Delivers measurable results on one job from the Job Landscape
3. **Natural escalation:** Success on this entry point logically leads to broader engagement
4. **Exists in the data:** Must reference an actual solution tier or package, not a fabricated option

### Entry Point Types (in order of preference)

1. **Proof of Value (PoV):** 2-6 week engagement focused on one job, measurable outcome
2. **Pilot:** 1-3 month limited deployment with success criteria
3. **Assessment:** 1-2 week diagnostic that quantifies the friction for one job
4. **Starter Package:** Entry-level bundle with defined scope and investment

### What NOT to Present

- A menu of options ("Choose from Basic, Pro, or Enterprise")
- A pricing table
- A comprehensive engagement proposal
- Multiple CTAs competing for attention

## Invitation Structure

### Single Entry Point Pattern

```markdown
## Invitation: Next Step

[1-2 sentences connecting the portfolio map to action]

**Start with [entry point name]:** [What it is, duration, scope -- 2-3 sentences]

**Investment:** [Amount or range, if available in data]

**Deliverable:** [What the buyer gets -- measured outcome on one job]

[Cogni-sales handoff signal -- 1-2 sentences]
```

### Example

```markdown
## Invitation: Next Step

The portfolio maps 1:1 to your four highest-friction jobs. The fastest path to value starts with the one that costs you most.

**Start with a 4-week Proof of Value on your highest-friction job.** We deploy the sensor-fusion platform on one production line, ingest your specific data formats, and measure the before/after on unplanned downtime. No infrastructure changes. No enterprise license. One line, four weeks, one number<sup>[1]</sup>.

**Investment:** EUR 35K for the 4-week engagement.

**Deliverable:** Measured downtime reduction on one production line -- your business case for the remaining three jobs.

For deal-specific tailoring with a named customer, engage cogni-sales `/why-change` to build the full Why Change pitch with customer-specific research, competitive intelligence, and buyer-persona adaptation.
```

## Transformation Patterns

### Pattern 1: Highest-Friction-First

**When to use:** When the Friction Map established clear cost-of-inaction rankings across jobs.

**Structure:**
```markdown
The Friction Map showed [Job X] costs [EUR Y annually]. Start there.

[Entry point] focuses on [Job X]: [scope, duration, deliverable].

Investment: [Amount]. Deliverable: [Measured friction reduction on one job].
```

**Why this works:** Connects directly to the highest-urgency friction. The buyer already knows this job is expensive.

---

### Pattern 2: Proof-Before-Portfolio

**When to use:** When the full portfolio engagement requires significant commitment.

**Structure:**
```markdown
Before committing to the full portfolio, prove value on one job.

[Entry point]: [Scope limited to one job]. [Duration]. [Measured outcome].

Success on this job builds the internal business case for jobs 2, 3, and 4.
```

**Why this works:** Reduces buyer risk. One job proven is worth more than four jobs promised.

---

### Pattern 3: Assessment-to-Engagement

**When to use:** When the buyer needs to understand their own friction before committing to a solution.

**Structure:**
```markdown
You know the jobs. Do you know the exact friction cost?

[Assessment entry point]: [Duration] diagnostic across [scope]. Deliverable: quantified friction map with investment-grade cost data for each job.

This assessment becomes the foundation for a portfolio engagement -- or for validating that your current approach is already sufficient.
```

**Why this works:** Non-threatening entry. Positions the provider as honest (willing to validate that current state might be sufficient).

## Cogni-Sales Handoff Signal

### Why the Handoff Matters

This arc produces a **reusable portfolio narrative** -- it presents the portfolio at market level, not deal level. When the buyer moves from interest to evaluation, they need:
- Customer-specific research
- Named-account competitive intelligence
- Buyer-persona adaptation
- Deal-specific pricing and packaging

These are cogni-sales capabilities. The Invitation must explicitly signal this transition.

### Handoff Patterns

**Pattern A: Direct reference**
```markdown
For deal-specific tailoring with a named customer, engage cogni-sales `/why-change` to build the full Why Change pitch.
```

**Pattern B: Capability bridge**
```markdown
This portfolio overview sets the stage. When you have a named prospect, `/why-change` builds the customer-specific narrative with web research, competitive positioning, and buyer-persona adaptation.
```

**Pattern C: Process signal**
```markdown
Next in the pipeline: `/why-change` transforms this portfolio overview into a deal-specific pitch. Input: customer name and context. Output: a tailored Why Change presentation with four research-backed phases.
```

### Handoff Rules

- Handoff signal MUST appear in every Invitation element
- Reference `/why-change` explicitly (not just "contact sales" or "talk to your rep")
- Frame the handoff as a capability upgrade, not a limitation of the current narrative
- Position cogni-sales as adding customer-specific depth, not replacing the portfolio overview

## Techniques Checklist

### You-Phrasing

- [ ] **Direct address throughout**
  - "Start with your highest-friction job"
  - "Your business case for the remaining three jobs"
  - "You know the jobs. Do you know the exact friction cost?"

### Single-Option Discipline

- [ ] **One entry point, not a menu**
  - One named option with scope, duration, investment, deliverable
  - No "alternatively..." or "you could also..."
  - No pricing tables

### Cogni-Sales Handoff

- [ ] **Explicit `/why-change` reference**
  - Mentioned by name
  - Positioned as capability upgrade
  - Framed as next step for named customers

### Evidence Grounding

- [ ] **Entry point references actual data**
  - Investment figure from solution/package data
  - Duration from implementation phases
  - Deliverable from solution outcomes
  - At least 1 citation

## Quality Checkpoints

### Content Requirements

- [ ] One clear entry point identified (not a menu)
- [ ] Entry point has: name, scope, duration, investment, deliverable
- [ ] Entry point references actual solution/package data
- [ ] Cogni-sales handoff signal present with `/why-change` reference
- [ ] At least 1 citation to solution or package data

### Structure Requirements

- [ ] Opens with connection to Portfolio Map
- [ ] Single entry point presented
- [ ] Investment and deliverable clearly stated
- [ ] Handoff signal at end
- [ ] Word count within proportional range (+/-10%)
- [ ] Smooth transition from Portfolio Map

### Tone Requirements

- [ ] Invitation, not hard sell
- [ ] Low-commitment framing ("prove value on one job", "before committing")
- [ ] Honest positioning (willing to validate current state is sufficient)
- [ ] Forward momentum (clear next step, not open-ended)

## Common Mistakes

### Mistake 1: Menu of Options

**Bad:**
> Choose from three engagement levels:
> - Basic: EUR 50K, 4 weeks
> - Professional: EUR 150K, 3 months
> - Enterprise: EUR 500K, 12 months

**Why it fails:** Decision paralysis. The buyer leaves to "think about it."

**Good:**
> Start with a 4-week Proof of Value. EUR 35K. One production line. One measured outcome.

**Why it works:** One option. Clear scope. Low commitment.

---

### Mistake 2: Missing Handoff

**Bad:**
> Contact our sales team for more information.

**Why it fails:** Generic. No connection to the ecosystem. Doesn't leverage cogni-sales capabilities.

**Good:**
> For deal-specific tailoring with a named customer, engage `/why-change` to build the full pitch.

**Why it works:** Specific tool reference. Positions the handoff as a capability, not a sales call.

---

### Mistake 3: Feature Dump in the Invitation

**Bad:**
> Our platform includes 24/7 support, dedicated CSM, quarterly business reviews, SLA guarantees, and custom integrations.

**Why it fails:** Feature list in the closing. Breaks the JTBD frame at the worst moment.

**Good:**
> Deliverable: Measured downtime reduction on one production line -- your business case for the remaining three jobs.

**Why it works:** Outcome-focused. Connects back to the Job Landscape.

## Language Variations

### German Adjustments

```markdown
## Einladung: Nächster Schritt

Das Portfolio adressiert Ihre vier dringendsten Aufgaben. Der schnellste Weg zum Nachweis: starten Sie mit der teuersten.

**Starten Sie mit einem 4-Wochen Proof of Value an Ihrer kritischsten Aufgabe.** Wir deployen die Sensor-Fusions-Plattform auf einer Produktionslinie, integrieren Ihre spezifischen Datenformate und messen die Vorher/Nachher-Ausfallzeiten<sup>[1]</sup>.

**Investition:** EUR 35K für das 4-Wochen-Engagement.

**Ergebnis:** Gemessene Ausfallzeitreduktion auf einer Linie -- Ihr Business Case für die restlichen drei Aufgaben.

Für kundenspezifische Anpassung mit einem benannten Prospect: `/why-change` erstellt den vollständigen Why-Change-Pitch mit kundenspezifischer Recherche und Wettbewerbsanalyse.
```

## Related Patterns

- See `job-landscape-patterns.md` for jobs this entry point should address
- See `friction-map-patterns.md` for friction data that justifies the entry point
- See `portfolio-map-patterns.md` for the solutions the entry point previews
