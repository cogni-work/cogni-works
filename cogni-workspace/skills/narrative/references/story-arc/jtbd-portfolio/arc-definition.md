# JTBD Portfolio Story Arc

## Arc Metadata

**Arc ID:** `jtbd-portfolio`
**Display Name:** JTBD Portfolio
**Display Name (German):** JTBD-Portfolio

**Elements (Ordered):**
1. Job Landscape: Functional Jobs
2. Friction Map: Obstacles and Cost of Inaction
3. Portfolio Map: Solutions by Job
4. Invitation: Next Step

**Elements (German):**
1. Job-Landschaft: Funktionale Aufgaben
2. Reibungskarte: Hindernisse und Handlungsdruck
3. Portfolio-Zuordnung: Lösungen je Aufgabe
4. Einladung: Nächster Schritt

## Word Proportions

Section lengths are expressed as proportions of the total target length. This keeps the arc's rhetorical balance intact regardless of narrative length. To compute word ranges for a given `--target-length T`: apply +/-15% band to get `[T*0.85, T*1.15]`, then multiply each proportion.

| Element | English Header | German Header | Proportion | Default Range (T=1675) |
|---------|----------------|---------------|-----------|------------------------|
| Hook | *(Context Setter)* | *(Kontextrahmen)* | 10% | 143-193 |
| Job Landscape | Job Landscape: Functional Jobs | Job-Landschaft: Funktionale Aufgaben | 24% | 342-462 |
| Friction Map | Friction Map: Obstacles and Cost of Inaction | Reibungskarte: Hindernisse und Handlungsdruck | 21% | 299-404 |
| Portfolio Map | Portfolio Map: Solutions by Job | Portfolio-Zuordnung: Lösungen je Aufgabe | 27% | 384-519 |
| Invitation | Invitation: Next Step | Einladung: Nächster Schritt | 18% | 256-347 |

**Proportions sum to 100%.** Default total: 1,675 words (customizable via `--target-length`). Tolerance: +/-10% of computed section midpoint.

## Detection Configuration

### Content Type Mapping

This arc is selected when:
- `content_type: "jtbd"`

### Content Analysis Keywords

Keywords: "jobs-to-be-done", "functional job", "jtbd", "job landscape", "hire", "portfolio map", "capability overview", "pre-sales positioning"

### Detection Threshold

Keyword density >= 12%

## Use Cases

**Best For:**
- Portfolio introductions (presenting a solution portfolio to new prospects)
- Capability overviews (executive briefings on what the company solves)
- Pre-sales positioning (framing the portfolio before deal-specific tailoring)
- B2B portfolio narratives where the buyer thinks in outcomes, not features

**Typical Input Sources:**
- cogni-portfolio entity files (propositions, customers, markets, solutions, competitors)
- Portfolio-communicate pitch use case with `--arc-id jtbd-portfolio`

**Not Suitable For:**
- Deal-specific sales pitches (use cogni-sales /why-change instead)
- Feature-centric product documentation (use portfolio-communicate customer-narrative)
- Research-driven narratives without portfolio data (use corporate-visions or other research arcs)

## Element Definitions

### Element 1: Job Landscape (Functional Jobs)

**Purpose:**
Map the buyer's world into 3-4 functional jobs they hire solutions for. Jobs are phrased as verb phrases in the buyer's language -- never as product category names or internal feature labels.

**Source Content:**
- `customers/{market}.json` pain_points (primary -- each pain point implies a job the buyer needs done)
- `propositions/{feature}--{market}.json` DOES statements (secondary -- each DOES describes what a solution does for the buyer, which reveals the underlying job)
- `markets/{market}.json` description (context -- industry vocabulary)

**Transformation Approach:**
1. Extract 3-4 distinct functional jobs from customer pain points
2. Phrase each as a verb phrase: "Monitor network health in real-time", "Reduce unplanned downtime below 2%", "Ensure regulatory compliance across 12 jurisdictions"
3. Frame jobs from the buyer's perspective, not the seller's
4. Use Contrast Structure to reframe from product categories to jobs

**Key Techniques:**
- Contrast Structure: "Your portfolio has 6 products. Your buyer has 4 jobs."
- Verb-phrase framing (mandatory -- this is the JTBD core discipline)
- Buyer-language validation: each job must use words the buyer would use, not internal product names

**Constraints:**
- Jobs MUST be verb phrases (e.g., "Reduce unplanned downtime"), NEVER product category names (e.g., "Predictive Maintenance")
- Each job must appear in at least one proposition's DOES domain
- 3-4 jobs total (fewer than 3 is too thin; more than 4 loses focus)

**Pattern Reference:** `job-landscape-patterns.md`

---

### Element 2: Friction Map (Obstacles and Cost of Inaction)

**Purpose:**
For each job from Element 1, identify the current obstacle and quantify the cost of not solving it. This is a compressed Why Change -- per-job, not global.

**Source Content:**
- `customers/{market}.json` pain_points (detail layer -- obstacle descriptions)
- `competitors/{feature}--{market}.json` (current approach weaknesses -- what existing solutions fail to deliver)
- `propositions/{feature}--{market}.json` evidence arrays (cost quantification)

**Transformation Approach:**
Per job from Element 1:
1. Identify the primary obstacle (why the job is hard or unsolved today)
2. Quantify the cost of the obstacle persisting (revenue loss, time waste, risk exposure)
3. Stack obstacles to show compound friction across the job landscape

**Key Techniques:**
- Forcing Functions: external pressures that make each friction urgent
- Compound Impact: stack per-job costs to show total friction cost
- Before/after contrast per job

**Constraints:**
- Every job from Element 1 must have a corresponding friction entry
- Each friction must include quantified cost of inaction (not just qualitative description)
- Frictions must reference the job by its verb phrase (maintaining the JTBD frame)

**Pattern Reference:** `friction-map-patterns.md`

---

### Element 3: Portfolio Map (Solutions by Job)

**Purpose:**
Map solutions 1:1 to jobs from Element 1 using IS/DOES/MEANS structure per entry. This is the portfolio showcase -- each solution is positioned as the thing the buyer hires for a specific job.

**Source Content:**
- `propositions/{feature}--{market}.json` IS/DOES/MEANS statements (primary)
- `solutions/{feature}--{market}.json` implementation details (supporting)
- `features/{feature}.json` descriptions (IS layer source)

**Transformation Approach:**
For each job from Element 1:
1. Identify the matching solution (1:1 mapping, strict)
2. Present using IS/DOES/MEANS:
   - **IS:** What the solution concretely is (from proposition IS + feature description)
   - **DOES:** What it does for the buyer in the context of this job (You-Phrasing, quantified)
   - **MEANS:** Why competitors struggle to deliver the same job outcome (moat/differentiation)

**Key Techniques:**
- IS-DOES-MEANS structure (mandatory per solution)
- You-Phrasing in DOES layer ("You reduce...", "Your teams gain...")
- Number Plays in DOES (quantified outcomes)

**Constraints:**
- STRICT 1:1 mapping: each job gets exactly one solution, each solution maps to exactly one job
- If a solution has no matching job, flag it as orphaned in a warning note
- If a job has no matching solution, note the gap explicitly
- NO feature lists -- IS/DOES/MEANS only. If you find yourself listing features, stop and reframe as a single IS statement
- Count(jobs) == Count(solutions mapped). Verify this before writing.

**Pattern Reference:** `portfolio-map-patterns.md`

---

### Element 4: Invitation (Next Step)

**Purpose:**
Provide one clear, low-commitment entry point and explicitly signal handoff to cogni-sales for deal-specific tailoring.

**Source Content:**
- `solutions/{feature}--{market}.json` entry tiers (proof-of-value, pilot options)
- `packages/{product}--{market}.json` starter tier (if packages exist)

**Transformation Approach:**
1. Identify the lowest-commitment entry point from solutions or packages
2. Frame it as a single next step (not a menu of options)
3. Include explicit cogni-sales handoff signal

**Key Techniques:**
- You-Phrasing: direct address for the call to action
- Single-option framing: one clear step, not a catalog

**Constraints:**
- ONE entry point only -- not a list of options or a pricing menu
- Must explicitly signal cogni-sales handoff: reference `/why-change` for deal-specific tailoring when a named customer is involved
- Invitation is about starting a conversation, not closing a deal

**Pattern Reference:** `invitation-patterns.md`

## Narrative Flow

### Hook Construction (Context Setter)

**Approach:**
Open with one sharp industry observation that creates a sense of inevitability -- the buyer's world is changing in a way that makes the jobs in this portfolio urgent.

**Pattern:**
```markdown
[Quantified industry observation] + [Implication that reframes buyer's priorities]

Example:
"European utilities manage 4,200 discrete operational processes. They buy solutions for 12 of them. The gap between operational complexity and solution coverage defines the next wave of B2B procurement -- buyers are hiring for jobs, not evaluating features."
```

**Source:** Most compelling data point from market description or customer pain points

**Word Target:** 10% of target length

---

### Element Transitions

**Hook -> Job Landscape:**
- Hook establishes the industry context
- Job Landscape maps the buyer's functional priorities
- **Transition pattern:** "Your buyers organize their world around [N] functional jobs."

**Job Landscape -> Friction Map:**
- Job Landscape names what buyers need done
- Friction Map shows what stands in the way
- **Transition pattern:** "Each job carries friction that compounds into measurable cost."

**Friction Map -> Portfolio Map:**
- Friction Map quantifies the problem per job
- Portfolio Map presents the solution per job
- **Transition pattern:** "Your portfolio maps 1:1 to these jobs."

**Portfolio Map -> Invitation:**
- Portfolio Map shows the full solution landscape
- Invitation provides one clear entry point
- **Transition pattern:** "Start with [lowest-commitment option]."

---

### Closing Pattern

**Final Sentence:**
Explicit cogni-sales handoff signal.

**Examples:**
- "For deal-specific tailoring with a named customer, engage cogni-sales /why-change to build the full pitch."
- "This portfolio overview sets the stage. The next step: a tailored Why Change narrative for your specific buyer."
- "Start with [entry point]. When you have a named prospect, /why-change builds the deal-specific case."

## Citation Requirements

### Citation Density

**Target:** 15-25 total citations across the narrative (scale proportionally for longer targets)
**Ratio:** Approximately 1 citation per 60-100 words

### Citation Distribution

**Job Landscape:** 3-5 citations (customer pain points, market data)
**Friction Map:** 5-8 citations (highest density -- every cost claim needs evidence)
**Portfolio Map:** 4-7 citations (proposition evidence arrays, feature data)
**Invitation:** 1-2 citations (solution/package entry tier data)

### Citation Format

```markdown
Claim text<sup>[N](propositions/feature--market.json)</sup>
```

**Required Citations:**
- Every quantitative claim (MUST)
- Cost of inaction figures (MUST)
- IS/DOES/MEANS outcomes in Portfolio Map (MUST)
- Job definitions (Should have supporting evidence)

## Quality Gates

### Arc Completeness

- [ ] All 4 elements present (Job Landscape, Friction Map, Portfolio Map, Invitation)
- [ ] Hook present (within hook proportion of target)
- [ ] Word counts within computed proportional ranges (+/-10% tolerance)
- [ ] Smooth transitions between elements
- [ ] Each element serves distinct purpose (no overlap)

### JTBD-Specific Constraints

- [ ] **Verb-phrase jobs:** Every job in Job Landscape is a verb phrase, not a product category name
- [ ] **1:1 mapping:** Count(jobs) == Count(solutions in Portfolio Map). No orphans, no gaps.
- [ ] **No feature lists:** Portfolio Map uses IS/DOES/MEANS per solution, not bullet-point feature lists
- [ ] **Cogni-sales handoff:** Invitation explicitly signals `/why-change` for deal-specific tailoring
- [ ] **Buyer language:** Job descriptions use buyer vocabulary, not internal product terminology

### JTBD Techniques Applied

- [ ] **Job Landscape:** Contrast Structure used (products vs. jobs reframe)
- [ ] **Job Landscape:** 3-4 jobs as verb phrases
- [ ] **Friction Map:** Per-job obstacles with quantified cost of inaction
- [ ] **Friction Map:** Forcing Functions or Compound Impact applied
- [ ] **Portfolio Map:** IS-DOES-MEANS structure for each solution
- [ ] **Portfolio Map:** You-Phrasing in DOES layer
- [ ] **Portfolio Map:** Number Plays in DOES layer
- [ ] **Invitation:** Single low-commitment entry point (not a menu)
- [ ] **Invitation:** Explicit cogni-sales handoff

### Evidence Quality

- [ ] Every cost-of-inaction claim has citation
- [ ] Citations point to portfolio entity files
- [ ] Quantitative data used throughout
- [ ] Number Plays applied (ratios, before/after, compound calculations)
- [ ] Citation density: 15-25 total citations

### Narrative Coherence

- [ ] Hook creates industry inevitability that leads to Job Landscape
- [ ] Job Landscape names jobs that Friction Map addresses
- [ ] Friction Map creates urgency that Portfolio Map resolves
- [ ] Portfolio Map solutions map 1:1 to Job Landscape jobs
- [ ] Invitation provides clear next step after Portfolio Map

## Common Pitfalls

### Job Landscape Pitfalls

**Product categories instead of jobs:**

:x: **Bad:** "Predictive Maintenance, Network Monitoring, Compliance Management"

These are product category labels. Buyers don't wake up thinking "I need Predictive Maintenance."

:white_check_mark: **Good:** "Reduce unplanned downtime below 2%", "Monitor network health across 340 endpoints in real-time", "Ensure regulatory compliance across 12 jurisdictions before Q1 audit"

These are verb phrases describing what the buyer needs done. They start with a verb and describe a measurable outcome.

---

**Too many jobs:**

:x: **Bad:** 7 jobs covering every product in the portfolio

:white_check_mark: **Good:** 3-4 jobs that represent the buyer's core priorities. Fewer jobs = sharper focus.

---

**Seller language instead of buyer language:**

:x: **Bad:** "Leverage our AI-powered analytics platform to optimize operational workflows"

:white_check_mark: **Good:** "Know which assets will fail before they fail -- and schedule maintenance in the next shift window"

### Friction Map Pitfalls

**Generic friction without per-job linkage:**

:x: **Bad:** "Organizations face digital transformation challenges."

:white_check_mark: **Good:** "Reducing unplanned downtime below 2% is blocked by three obstacles: sensor data arrives in 47 incompatible formats, maintenance teams lack real-time dashboards, and current CMMS systems flag 340 false positives per week."

---

**Missing cost quantification:**

:x: **Bad:** "This causes significant operational disruption."

:white_check_mark: **Good:** "Each hour of unplanned downtime costs EUR 180K in lost production. At current failure rates, that's EUR 4.3M annually."

### Portfolio Map Pitfalls

**Feature lists instead of IS/DOES/MEANS:**

:x: **Bad:**
> Our solution includes: real-time monitoring, predictive analytics, automated alerting, customizable dashboards, API integrations, and 24/7 support.

:white_check_mark: **Good:**
> **IS:** A sensor-fusion platform that ingests 47 data formats into a unified asset health model.
>
> **DOES:** You detect failure patterns 72 hours before breakdown, reducing unplanned downtime by 63%. Your maintenance teams schedule interventions in the next available shift window, not the next emergency.
>
> **MEANS:** The 47-format ingestion layer took 18 months of industrial protocol engineering. Competitors offering monitoring can read 8-12 formats. The remaining 35 formats represent the long tail where 60% of failure signals originate.

---

**Broken 1:1 mapping:**

:x: **Bad:** 4 jobs in Job Landscape but 6 solutions in Portfolio Map (two solutions don't map to any job)

:white_check_mark: **Good:** 4 jobs, 4 solutions, each solution explicitly introduced as "For the job of [verb phrase]..."

### Invitation Pitfalls

**Menu of options:**

:x: **Bad:** "Choose from: Basic (EUR 50K), Professional (EUR 150K), or Enterprise (EUR 500K)."

:white_check_mark: **Good:** "Start with a 4-week Proof of Value on your highest-friction job. Investment: EUR 35K. Deliverable: measured friction reduction on one job before committing to the portfolio."

---

**Missing cogni-sales handoff:**

:x: **Bad:** "Contact sales for more information."

:white_check_mark: **Good:** "For deal-specific tailoring with a named customer, engage /why-change to build the full Why Change pitch with customer-specific research and competitive intelligence."

## Version History

- **v1.0.0:** Initial JTBD Portfolio arc definition

## See Also

- `../arc-registry.md` - Master index of all story arcs
- `job-landscape-patterns.md` - Functional job extraction and verb-phrase patterns
- `friction-map-patterns.md` - Per-job obstacle and cost of inaction patterns
- `portfolio-map-patterns.md` - 1:1 job-to-solution IS/DOES/MEANS patterns
- `invitation-patterns.md` - Low-commitment entry point and cogni-sales handoff patterns
