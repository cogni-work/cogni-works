# Friction Map: Obstacle and Cost of Inaction Patterns

## Element Purpose

For each job from the Job Landscape, identify the primary obstacle and quantify the **cost of not solving it**. This is a compressed Why Change -- per-job, not global.

**Word Target:** 21% of target length

## Source Content Mapping

Extract from:
1. **Customer pain points -- detail layer** (primary source)
   - `customers/{market}.json` pain_points array
   - Look for obstacle descriptions, failure modes, workaround costs
   - Each pain point maps to a specific job from Element 1

2. **Competitor analysis** (secondary source)
   - `competitors/{feature}--{market}.json`
   - Current approach weaknesses -- what existing solutions fail to deliver
   - Gaps that create ongoing friction for the buyer

3. **Proposition evidence arrays** (quantification source)
   - `propositions/{feature}--{market}.json` evidence field
   - Cost figures, time losses, risk exposure data
   - Before/after metrics that imply current-state costs

## Per-Job Friction Structure

### Structure Per Job

For each job from Element 1, present friction as:

```markdown
**[Job verb phrase]** is blocked by [primary obstacle].

[Obstacle description: what makes this job hard today, 2-3 sentences]

**Cost of inaction:** [Quantified impact]<sup>[citation]</sup>.
```

### Example (3 Jobs)

```markdown
**Reducing unplanned downtime below 2%** is blocked by fragmented sensor data.

Sensor data arrives in 47 incompatible formats from equipment spanning three decades of procurement. Maintenance teams spend 12 hours per week manually correlating alerts across 4 separate monitoring systems. Current CMMS systems generate 340 false positives per week, training teams to ignore alerts<sup>[1]</sup>.

**Cost of inaction:** Each hour of unplanned downtime costs EUR 180K in lost production. At current failure rates, that's EUR 4.3M annually<sup>[2]</sup>.

---

**Monitoring network health across 340 endpoints in real-time** is blocked by legacy visibility gaps.

The existing monitoring stack covers 60% of endpoints. The remaining 40% -- mostly edge devices and legacy PLCs -- report via batch uploads every 4 hours. In that 4-hour window, 73% of cascading failures originate<sup>[3]</sup>.

**Cost of inaction:** Cascading failures that start in unmonitored endpoints account for EUR 2.1M in annual incident response costs<sup>[4]</sup>.

---

**Ensuring regulatory compliance across 12 jurisdictions** is blocked by manual audit preparation.

Compliance teams spend 6 weeks preparing for each quarterly audit, manually assembling evidence from 8 different systems. Two FTEs work full-time on audit preparation, leaving no capacity for proactive compliance improvement<sup>[5]</sup>.

**Cost of inaction:** Non-compliance fines averaged EUR 420K per incident in 2025, with 3 incidents per year for organizations in this segment<sup>[6]</sup>. Over 3 years: EUR 3.8M in avoidable penalties.
```

## Transformation Patterns

### Pattern 1: Obstacle Stack

**When to use:** Multiple obstacles compound for a single job.

**Structure:**
```markdown
[Job] is blocked by [N] compounding obstacles:
1. [Technical obstacle] -- [what it causes]
2. [Process obstacle] -- [what it prevents]
3. [Data obstacle] -- [what it hides]

Combined cost: [Quantified total]<sup>[citation]</sup>.
```

**Why this works:** Stacking shows the friction is structural, not incidental. Harder to dismiss.

---

### Pattern 2: Current-State Teardown

**When to use:** The buyer has an existing solution that creates its own friction.

**Structure:**
```markdown
The current approach to [job] -- [existing solution] -- creates three friction sources:
- [Friction 1]: [specific metric]<sup>[citation]</sup>
- [Friction 2]: [specific metric]
- [Friction 3]: [specific metric]

The existing solution was designed for [old context]. [Job] now operates in [new context].
```

**Why this works:** Frames the problem as a context mismatch, not a quality complaint. Respects the buyer's past decisions while showing why they no longer fit.

---

### Pattern 3: Cost Cascade

**When to use:** Direct cost leads to indirect costs that multiply.

**Structure:**
```markdown
Direct cost: [Primary metric, e.g., EUR 4.3M in downtime]<sup>[citation]</sup>
   -> Indirect cost 1: [Secondary impact, e.g., EUR 1.2M in overtime labor]
   -> Indirect cost 2: [Tertiary impact, e.g., EUR 800K in expedited parts procurement]
   -> Indirect cost 3: [Reputation/trust impact, e.g., 18% customer churn attributed to reliability]

Total friction cost for this job: [Sum]<sup>[citation]</sup>.
```

**Why this works:** Shows that the visible cost is the tip. Executive attention follows the cascade.

---

### Pattern 4: Friction-to-Forcing-Function Bridge

**When to use:** An external pressure turns existing friction into urgent risk.

**Structure:**
```markdown
[Job] friction has been tolerable -- until now.

[Forcing function: regulation, market shift, competitor move] changes the equation:
- Before [event]: [friction cost was X, manageable]
- After [event]: [friction cost becomes Y, unacceptable]
- Deadline: [specific date or quarter]<sup>[citation]</sup>
```

**Why this works:** Converts chronic friction into acute urgency. The forcing function creates a decision deadline.

## Techniques Checklist

### Forcing Functions

- [ ] **At least one external pressure per job (where data supports it)**
  - Regulatory deadline
  - Competitor capability launch
  - Customer expectation shift
  - Technology obsolescence date
  - Link to specific timeline

### Compound Impact

- [ ] **Stack cost dimensions per job**
  - Direct cost (revenue loss, penalties)
  - Indirect cost (labor, workarounds)
  - Opportunity cost (what could be done instead)
  - Risk cost (probability x impact)

### Before/After Contrast

- [ ] **Show what changes when friction is resolved**
  - "Today: 12 hours/week manual correlation. After: real-time unified view."
  - "Current: 340 false positives/week. Target: <10 actionable alerts/week."
  - Makes the gap visceral

### Quantification

- [ ] **Every friction has a number**
  - EUR/USD cost per incident
  - Hours lost per week/month/year
  - Percentage of capacity consumed
  - Number of incidents, failures, or workarounds
  - Citation for every quantitative claim

## Quality Checkpoints

### Content Requirements

- [ ] Every job from Element 1 has a corresponding friction entry
- [ ] Each friction includes a quantified cost of inaction
- [ ] Frictions reference jobs by their verb phrases
- [ ] At least 5 citations across all friction entries
- [ ] Cost figures are specific (not "significant" or "substantial")

### Structure Requirements

- [ ] Per-job structure maintained (not a single global friction narrative)
- [ ] Each friction entry has: obstacle description + cost of inaction
- [ ] Word count within proportional range (+/-10%)
- [ ] Smooth transition from Job Landscape
- [ ] Smooth transition to Portfolio Map

### Coherence Requirements

- [ ] Friction entries create urgency that Portfolio Map resolves
- [ ] Cost of inaction figures are credible (cited, not fabricated)
- [ ] Obstacles are structural (not trivially solvable without the portfolio)

## Common Mistakes

### Mistake 1: Global Friction Instead of Per-Job

**Bad:**
> Organizations face significant digital transformation challenges including legacy systems, skill gaps, and regulatory complexity.

**Why it fails:** Not linked to specific jobs. Generic, not actionable.

**Good:**
> **Reducing unplanned downtime below 2%** is blocked by fragmented sensor data. 47 incompatible formats from equipment spanning three decades<sup>[1]</sup>.

**Why it works:** Friction is specific to one job. The reader knows exactly what's broken.

---

### Mistake 2: No Cost Quantification

**Bad:**
> This creates operational challenges and increases risk.

**Why it fails:** "Challenges" and "risk" without numbers are ignorable.

**Good:**
> Cost of inaction: EUR 4.3M annually in unplanned downtime at current failure rates<sup>[2]</sup>.

**Why it works:** A specific EUR figure demands attention.

---

### Mistake 3: Blaming the Buyer

**Bad:**
> Organizations have failed to modernize their monitoring infrastructure.

**Why it fails:** Accusatory tone. Buyers disengage.

**Good:**
> The existing monitoring stack was designed for 120 endpoints. The network has grown to 340. The 40% gap in visibility is where 73% of cascading failures originate<sup>[3]</sup>.

**Why it works:** Frames the problem as context evolution, not buyer failure.

## Language Variations

### German Adjustments

**Directness in cost statements:**
German business communication expects precise cost statements:

```markdown
**Ungeplante Ausfallzeiten unter 2% senken** wird durch fragmentierte Sensordaten blockiert.

Sensordaten kommen in 47 inkompatiblen Formaten an. Wartungsteams verbringen 12 Stunden pro Woche mit manueller Korrelation. Das aktuelle CMMS erzeugt 340 Fehlalarme pro Woche<sup>[1]</sup>.

**Kosten der Untätigkeit:** Jede Stunde ungeplanter Ausfallzeit kostet EUR 180K Produktionsverlust. Bei aktueller Ausfallrate: EUR 4,3M jährlich<sup>[2]</sup>.
```

## Related Patterns

- See `job-landscape-patterns.md` for job extraction (upstream)
- See `portfolio-map-patterns.md` for solutions that resolve these frictions (downstream)
- See `invitation-patterns.md` for entry point after friction is established
