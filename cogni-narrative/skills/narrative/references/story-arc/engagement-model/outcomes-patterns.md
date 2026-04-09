# Outcomes: What-Success-Looks-Like Patterns

## Element Purpose

Close by stating what the buyer will be able to point to after a successful engagement — in outcome terms, not deliverable terms. Outcomes makes the How We Work page feel like a commitment to results rather than a description of activity.

**Word Target:** 22% of target length.

## Source Content Mapping

Extract from:
1. **MEANS themes across propositions** (primary)
   - `propositions/*.json` MEANS field — describes the meaning of outcomes, which is exactly what Outcomes summarises at the engagement-model level.
2. **Cross-cutting outcome patterns**
   - Look for recurring verbs of change across MEANS statements ("shorter cycles", "fewer restarts", "preserved knowledge", "reduced rework").

## Outcome Extraction Patterns

### Pattern 1: The MEANS Theme Aggregation

**When to use:** Multiple propositions independently point to the same class of outcome.

**Structure:**
```markdown
Scan all proposition MEANS fields for recurring themes.
Found themes (each appearing in 4+ propositions):
- "shorter decision cycles" (6 propositions)
- "fewer program restarts" (5 propositions)
- "preserved institutional knowledge" (4 propositions)
   → Outcomes element: 3 themes, each drawn from cross-portfolio evidence.
```

**Why this works:** Cross-cutting outcomes at the engagement-model level must be true regardless of which capability was bought. Aggregation surfaces exactly those.

---

### Pattern 2: The Measurable Outcome

**When to use:** Every outcome theme needs to name a way to observe the change.

**Structure:**
```markdown
Outcome theme: Shorter decision cycles.
How it's observed: We measure the cycle time between "we noticed something" and "we decided what to do about it" at the start and end of every engagement. On typical engagements, this cycle compresses from 3–6 weeks to 3–5 days.
   → Outcome statement: "Regardless of which capability you engage us for, you will see the cycle time between 'we noticed something' and 'we decided what to do about it' compress measurably. We measure this explicitly at the start and end of every engagement."
```

**Why this works:** Measurability makes the outcome verifiable. Unverifiable outcomes ("digital transformation achieved") undo the credibility the rest of the page built.

---

### Pattern 3: The Buyer-Visible Change

**When to use:** Outcomes should describe what the buyer notices, not what the company's dashboard says.

**Structure:**
```markdown
Internal metric: MTTR decreased from 14 hours to 3 hours.
Buyer-visible change: "You will notice that your Monday-morning incident review meeting gets shorter. Fewer incidents from the weekend make it to Monday. The ones that do have already been scoped and have a clear owner."
   → Outcome statement: Uses buyer-visible language, not internal metric language.
```

**Why this works:** Buyers trust outcomes they can observe from their own seat. A KPI on a dashboard is abstract; a shorter meeting is concrete.

---

### Pattern 4: The Cross-Cutting Discipline Check

**When to use:** Verifying that each outcome theme is true across the portfolio, not just for one capability.

**Structure:**
```markdown
Candidate outcome: "40% reduction in unplanned downtime."
Cross-cutting test: Is this true across the entire portfolio? No — it's specific to predictive maintenance.
   → Move to predictive-maintenance capability page. Replace with cross-cutting outcome: "You will see the cycle time between operational anomalies and decisive response compress measurably — regardless of which capability we're running for you."
```

**Why this works:** Cross-cutting discipline keeps the How We Work page honest and avoids duplicating content from capability pages.

## Presentation Structure

### Opening: The Engagement-Level Framing

Start by explicitly naming that Outcomes at this level are cross-cutting:

```markdown
These outcomes are true regardless of which capability you hire us for. Capability-specific outcomes live on the capability pages — this section is about what changes in your organization when we work together, independent of the specific work.
```

### Body: 3 Outcome Themes

```markdown
**Outcome 1: [Buyer-visible change in one short phrase].**
[One short paragraph: what the buyer sees change + how the change is observed + 1 citation if grounded in specific MEANS evidence.]

**Outcome 2: [Buyer-visible change].**
[Paragraph.]

**Outcome 3: [Buyer-visible change].**
[Paragraph.]
```

### Closing: The Soft Close

End with a short paragraph that acknowledges the process is flexible where it should be and firm where it matters, plus one invitation:

```markdown
The process adapts to your size and scope. The principles do not. If you want to see which capabilities ride on top of this engagement model, the Capabilities page is the next stop.
```

## Techniques Checklist

### Outcome Framing (mandatory)

- [ ] **Every outcome describes change the buyer experiences, not activity the company performs**
  - "You will see X change" ✅
  - "We will deliver Y" ❌
  - The test: does the outcome sentence have the buyer as the subject?

### Measurability (mandatory)

- [ ] **Every outcome names a way to observe the change**
  - A meeting gets shorter
  - A report takes less time to produce
  - A dashboard shows a cycle-time number that compressed
  - Unmeasurable outcomes ("increased agility") undo the arc's credibility.

### Cross-Cutting Discipline (mandatory)

- [ ] **Every outcome is true for most engagements**
  - If an outcome is only true for one capability, it belongs on that capability's page.
  - Cross-cutting outcomes come from MEANS themes that recur across the portfolio.

### No Pricing / No ROI Numbers

- [ ] **Outcomes do not contain pricing or ROI numbers**
  - Those belong on capability pages (where scope is defined) or proposals (where the customer is specific).
  - Keeping Outcomes clean of numbers keeps the How We Work page from reading as a sales pitch.

### Number of Outcomes

- [ ] **Exactly 3 outcome themes**
  - Fewer feels thin; more turns Outcomes into a catalog.
  - Three is the rhetorical sweet spot for a closing element.

## Quality Checkpoints

### Content Requirements

- [ ] 3 outcome themes
- [ ] Each outcome describes buyer-visible change
- [ ] Each outcome names a way to observe the change
- [ ] Each outcome is cross-cutting (true for most engagements)
- [ ] No pricing, no ROI numbers, no per-capability metrics
- [ ] Aggregated from MEANS themes, not invented

### Structure Requirements

- [ ] Opening engagement-level framing sentence
- [ ] 3 named outcome themes
- [ ] Closing soft close with single invitation
- [ ] Word count within proportional range (+/-10%)

## Common Mistakes

### Mistake 1: Per-Capability Outcome

**Bad:**
> **Outcome 1:** Your predictive maintenance system will reduce unplanned downtime by 40%.

**Why it fails:** Capability-specific. Belongs on the predictive-maintenance page, not the How We Work page. Also mixes in a number that looks like an ROI promise.

**Good:**
> **Outcome 1: Shorter cycles between "we noticed something" and "we decided what to do about it."**
> Regardless of which capability you engage us for, you will see the cycle time between operational anomalies and decisive response compress measurably. We measure this explicitly at the start and end of every engagement — the number usually comes in below 5 business days by week 12.

---

### Mistake 2: Unmeasurable Outcome

**Bad:**
> **Outcome 2:** Increased organizational agility.

**Why it fails:** Unmeasurable. The buyer cannot verify it. Reads as marketing filler.

**Good:**
> **Outcome 2: Fewer program restarts at month 12.**
> The standard pattern in services engagements is this: month 3 looks good, month 6 is slow, month 12 is a hard reset because the data contracts nobody negotiated in month 0 have finally broken the program. Our engagements don't do this — not because of magic, but because Phase 1 is the reset the other programs are eventually forced into.

---

### Mistake 3: Outcome That Sneaks In Pricing

**Bad:**
> **Outcome 3:** An average 3x ROI within 18 months.

**Why it fails:** ROI numbers belong in proposals (customer-specific) or capability pages (scope-specific). At the engagement-model level, they read as sales.

**Good:**
> **Outcome 3: Preserved institutional knowledge.**
> At the end of an engagement, you own the data contracts, the runbooks, the deployment pipeline, and the measured baselines. If we disappear tomorrow, the program keeps running — and the next team you hire (us or anyone else) starts from a documented state, not a reverse-engineering exercise.

## Language Variations

### German Adjustments

```markdown
**Ergebnis 1: Kürzere Zyklen zwischen "wir haben etwas bemerkt" und "wir haben entschieden, was zu tun ist".**
Unabhängig davon, für welche Capability Sie uns beauftragen, werden Sie sehen, wie sich die Zykluszeit zwischen operativen Anomalien und entscheidender Reaktion messbar verkürzt. Wir messen das zu Beginn und am Ende jedes Engagements explizit — in der Regel liegt die Zahl bis Woche 12 unter fünf Arbeitstagen.

**Ergebnis 2: Weniger Programm-Neustarts in Monat 12.**
Das Standard-Muster in Dienstleistungsprojekten ist: Monat 3 sieht gut aus, Monat 6 wird langsam, Monat 12 ist ein harter Neustart, weil die Datenverträge, die in Monat 0 niemand verhandelt hat, endlich das Programm gebrochen haben. Unsere Engagements tun das nicht — nicht durch Magie, sondern weil Phase 1 der Neustart ist, zu dem andere Programme später gezwungen sind.

**Ergebnis 3: Bewahrtes Wissen.**
Am Ende eines Engagements besitzen Sie die Datenverträge, die Runbooks, die Deployment-Pipeline und die gemessenen Baselines. Wenn wir morgen verschwinden, läuft das Programm weiter — und das nächste Team, das Sie einstellen (wir oder jemand anderes), beginnt in einem dokumentierten Zustand.
```

## Related Patterns

- See `principles-patterns.md` for the principles whose practice produces these outcomes
- See `process-patterns.md` for the phases in which the outcomes take shape
- See `partnership-patterns.md` for the buyer contributions that make the outcomes possible
