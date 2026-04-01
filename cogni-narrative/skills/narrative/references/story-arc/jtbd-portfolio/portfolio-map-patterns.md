# Portfolio Map: Job-to-Solution IS/DOES/MEANS Patterns

## Element Purpose

Map solutions **1:1 to jobs** from the Job Landscape using IS/DOES/MEANS structure per entry. Each solution is positioned as the thing the buyer hires for a specific functional job.

**Word Target:** 27% of target length

## Source Content Mapping

Extract from:
1. **Propositions** (primary source)
   - `propositions/{feature}--{market}.json` is_statement, does_statement, means_statement
   - Each proposition provides the IS/DOES/MEANS for one solution

2. **Solutions** (supporting)
   - `solutions/{feature}--{market}.json` implementation details
   - Entry tiers, proof-of-value options (used more in Invitation, but context here)

3. **Features** (IS layer source)
   - `features/{feature}.json` description
   - Concrete capability definition for the IS layer

## 1:1 Mapping Discipline

### Before Writing: Verify the Map

Before drafting any Portfolio Map content, verify:

```
Job Landscape jobs:          Portfolio Map solutions:
1. [Job verb phrase 1]   ->  1. [Solution for Job 1]
2. [Job verb phrase 2]   ->  2. [Solution for Job 2]
3. [Job verb phrase 3]   ->  3. [Solution for Job 3]
4. [Job verb phrase 4]   ->  4. [Solution for Job 4] (if 4 jobs)
```

**Validation checks:**
- Count(jobs) == Count(solutions). If not equal, stop and flag.
- Each solution maps to exactly one job. No solution serves two jobs.
- Each job has exactly one solution. No job is served by two solutions.
- If a solution has no matching job, flag as orphaned: `[WARNING: {solution} has no matching job in the Job Landscape]`
- If a job has no matching solution, note the gap: `[GAP: No portfolio solution addresses the job "{verb phrase}"]`

### Orphan Detection

After mapping, scan `propositions/` for any files that were not used:

```
Propositions loaded: 6
Propositions mapped to jobs: 4
Orphaned propositions: 2 (feature-x--market, feature-y--market)
```

Include orphan warnings as a note after the Portfolio Map (not in the main body):

```markdown
> **Portfolio coverage note:** 2 propositions ({feature-x}, {feature-y}) are not mapped to buyer jobs in this narrative. Consider whether these address jobs not included in the current Job Landscape scope, or whether they represent solutions in search of a job.
```

## IS/DOES/MEANS Per Solution

### Structure Per Solution

```markdown
**For the job of [verb phrase from Job Landscape]:**

**IS:** [Concrete definition of what the solution is -- 1-2 sentences, specific not abstract]

**DOES:** [Quantified outcomes with You-Phrasing -- what it does for the buyer in the context of this job. 2-3 outcomes with numbers.]<sup>[citation]</sup>

**MEANS:** [Why competitors struggle to deliver the same job outcome -- the moat, the differentiation, the hard-to-replicate element. 2-3 sentences.]<sup>[citation]</sup>
```

### Example (3 Solutions Mapped to 3 Jobs)

```markdown
**For the job of reducing unplanned downtime below 2%:**

**IS:** A sensor-fusion platform that ingests 47 industrial data formats into a unified asset health model, using physics-informed ML to separate signal from noise.

**DOES:** You detect failure patterns 72 hours before breakdown, reducing unplanned downtime by 63%<sup>[1]</sup>. Your maintenance teams schedule interventions in the next available shift window, not the next emergency. Mean time to repair drops from 4.2 hours to 45 minutes<sup>[2]</sup>.

**MEANS:** The 47-format ingestion layer took 18 months of industrial protocol engineering. Competitors offering predictive maintenance can read 8-12 formats. The remaining 35 formats represent the long tail where 60% of failure signals originate<sup>[3]</sup>.

---

**For the job of monitoring network health across 340 endpoints in real-time:**

**IS:** An edge-native monitoring agent that runs on legacy PLCs, modern IoT gateways, and everything in between -- no hardware replacement required.

**DOES:** You see every endpoint in real-time from one dashboard. Alert fatigue drops from 340 false positives/week to fewer than 10 actionable alerts<sup>[4]</sup>. Your NOC team recovers 18 hours per week previously spent triaging noise.

**MEANS:** Edge-native deployment on legacy PLCs requires firmware-level integration that took 24 months of embedded systems work across 12 PLC manufacturers<sup>[5]</sup>. Cloud-only competitors require hardware upgrades -- a EUR 2.4M replacement cost your buyer won't authorize.

---

**For the job of ensuring regulatory compliance across 12 jurisdictions:**

**IS:** A compliance orchestration engine that maps regulatory requirements across jurisdictions to operational controls, auto-generating audit evidence packages.

**DOES:** You prepare for quarterly audits in 3 days instead of 6 weeks<sup>[6]</sup>. Your compliance team shifts from evidence assembly to proactive risk management. Audit findings drop by 74% year-over-year.

**MEANS:** The jurisdiction-mapping knowledge base covers 12 regulatory frameworks with 2,400+ control mappings maintained by a dedicated regulatory team<sup>[7]</sup>. Building this from scratch requires 2+ years of regulatory analyst effort per jurisdiction.
```

## Transformation Patterns

### Pattern 1: Job-First Framing

**When to use:** Always. Every solution entry opens with the job it serves.

**Structure:**
```markdown
**For the job of [verb phrase]:**
[IS/DOES/MEANS]
```

**Why this works:** Anchors the reader in the buyer's need before introducing the solution. The solution is the answer, not the topic.

---

### Pattern 2: Friction-to-Solution Bridge

**When to use:** When the Friction Map established a specific obstacle for this job.

**Structure:**
```markdown
**For the job of [verb phrase]:**

The Friction Map showed [specific obstacle]. [Solution IS] was built to dissolve that friction.

**IS:** [Definition]
**DOES:** [Outcomes that directly address the friction metrics]
**MEANS:** [Why the obstacle remains for competitors]
```

**Why this works:** Creates narrative continuity from Friction Map to Portfolio Map. The reader sees friction -> resolution.

---

### Pattern 3: DOES Layer Number Plays

**When to use:** Always in the DOES layer. Quantify every outcome.

**Variants:**
- **Before/after:** "From 4.2 hours to 45 minutes" (97% reduction implicit)
- **Ratio framing:** "63% reduction in unplanned downtime"
- **Comparative anchoring:** "340 false positives/week to fewer than 10 actionable alerts"
- **Time recovery:** "18 hours per week recovered"
- **Compound:** "63% fewer incidents x EUR 180K per incident = EUR 4.9M annual savings"

---

### Pattern 4: MEANS Layer Moat Types

**When to use:** In every MEANS layer. Explain why competitors can't easily deliver the same job outcome.

**Moat types:**
- **Time moat:** "18 months of industrial protocol engineering"
- **Knowledge moat:** "2,400+ control mappings maintained by regulatory analysts"
- **Embedded moat:** "Firmware-level integration across 12 PLC manufacturers"
- **Network moat:** "Data from 340 customer deployments trains the model"
- **Cost moat:** "Competitors require EUR 2.4M hardware replacement"

## Techniques Checklist

### IS-DOES-MEANS Structure

- [ ] **Every solution uses all three layers**
  - IS: Concrete definition (not abstract, not a feature list)
  - DOES: Quantified outcomes with You-Phrasing
  - MEANS: Specific competitive barrier
  - No exceptions. If a solution can't fill all three layers, it's not ready.

### You-Phrasing in DOES

- [ ] **DOES layer addresses the buyer directly**
  - "You detect...", "You see...", "You prepare..."
  - "Your teams recover...", "Your NOC team gains..."
  - Never: "The solution provides...", "Organizations achieve..."

### Number Plays in DOES

- [ ] **Every DOES outcome is quantified**
  - Percentages, time savings, cost reductions, ratio improvements
  - At least 2 quantified outcomes per solution
  - At least 1 citation per solution's DOES layer

### No Feature Lists

- [ ] **Portfolio Map contains zero feature lists**
  - IS is one coherent definition, not a bullet list of capabilities
  - DOES is outcomes, not features
  - If you catch yourself writing "includes:", "features:", or bullet-listing capabilities, STOP and reframe

### 1:1 Mapping Verified

- [ ] **Count(jobs) == Count(solutions mapped)**
  - Explicit check before writing
  - Orphan warnings for unmapped solutions
  - Gap notes for unmapped jobs

## Quality Checkpoints

### Content Requirements

- [ ] Each solution uses full IS/DOES/MEANS structure
- [ ] Each solution opens with "For the job of [verb phrase]"
- [ ] DOES layer uses You-Phrasing throughout
- [ ] DOES layer has at least 2 quantified outcomes per solution
- [ ] MEANS layer explains a specific competitive barrier
- [ ] At least 4 citations across all solutions

### Structure Requirements

- [ ] 1:1 job-to-solution mapping verified
- [ ] No orphaned solutions in the main body (warnings in notes if any)
- [ ] No feature lists anywhere in the element
- [ ] Word count within proportional range (+/-10%)
- [ ] Smooth transition from Friction Map
- [ ] Smooth transition to Invitation

## Common Mistakes

### Mistake 1: Feature Lists

**Bad:**
> Our solution includes: real-time monitoring, predictive analytics, automated alerting, customizable dashboards, API integrations, and 24/7 support.

**Why it fails:** This is a feature list. The buyer doesn't know what any of this does for their specific job.

**Good:**
> **IS:** A sensor-fusion platform that ingests 47 data formats into a unified asset health model.
> **DOES:** You detect failure patterns 72 hours before breakdown<sup>[1]</sup>. Mean time to repair drops from 4.2 hours to 45 minutes.
> **MEANS:** The 47-format ingestion layer took 18 months of protocol engineering.

**Why it works:** IS defines what it is (one thing), DOES quantifies outcomes, MEANS explains the moat.

---

### Mistake 2: Solution Without Job Anchor

**Bad:**
> **Our Predictive Maintenance Platform**
> IS: An AI-powered platform for predictive maintenance...

**Why it fails:** Not anchored to a job. Reader doesn't know which buyer need this addresses.

**Good:**
> **For the job of reducing unplanned downtime below 2%:**
> **IS:** A sensor-fusion platform that...

**Why it works:** Opens with the job, positions the solution as the hire.

---

### Mistake 3: Broken 1:1 Mapping

**Bad:** 4 jobs in Job Landscape, but only 2 solutions in Portfolio Map. Two jobs have no solution.

**Why it fails:** Promise made in Job Landscape is broken. Reader notices the gap.

**Good:** 4 jobs, 4 solutions. If only 2 solutions exist, Job Landscape should only present 2 jobs.

## Language Variations

### German Adjustments

```markdown
**Für die Aufgabe: Ungeplante Ausfallzeiten unter 2% senken**

**Was es ist:** Eine Sensor-Fusions-Plattform, die 47 industrielle Datenformate in ein einheitliches Asset-Health-Modell einliest.

**Was es für Sie leistet:** Sie erkennen Ausfallmuster 72 Stunden vor dem Ausfall<sup>[1]</sup>. Ihre Wartungsteams planen Eingriffe im nächsten verfügbaren Schichtfenster. Mittlere Reparaturzeit sinkt von 4,2 Stunden auf 45 Minuten<sup>[2]</sup>.

**Warum Wettbewerber das nicht kopieren können:** Die 47-Format-Ingestion erforderte 18 Monate industrielle Protokoll-Entwicklung<sup>[3]</sup>. Wettbewerber lesen 8-12 Formate. Die restlichen 35 Formate erzeugen 60% der Ausfallsignale.
```

## Related Patterns

- See `job-landscape-patterns.md` for job extraction (upstream -- jobs must match)
- See `friction-map-patterns.md` for obstacles these solutions resolve
- See `invitation-patterns.md` for entry point after portfolio is presented
