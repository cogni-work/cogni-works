# Job Landscape: Functional Job Patterns

## Element Purpose

Map the buyer's world into 3-4 **functional jobs** they hire solutions for. Every job is a verb phrase in the buyer's language -- never a product category name.

**Word Target:** 24% of target length

## Source Content Mapping

Extract from:
1. **Customer pain points** (primary source)
   - `customers/{market}.json` pain_points array
   - Each pain point implies a job the buyer needs done
   - Look for recurring themes across multiple pain points

2. **Proposition DOES statements** (secondary source)
   - `propositions/{feature}--{market}.json` does_statement field
   - Each DOES describes what a solution does, which reveals the underlying job
   - Reverse-engineer: "If the solution does X, the buyer's job is to X"

3. **Market description** (context)
   - `markets/{market}.json` description field
   - Industry vocabulary, buyer terminology, sector-specific language

## Job Extraction Patterns

### Pattern 1: Pain Point to Job Reversal

**When to use:** Customer pain points describe obstacles -- reverse them to find the job.

**Structure:**
```markdown
Pain point: "Unplanned downtime causes EUR 4.3M annual losses"
   -> Job: "Reduce unplanned downtime below 2%"

Pain point: "Compliance audits require 6 weeks of manual preparation"
   -> Job: "Pass regulatory audits with less than 1 week preparation"
```

**Why this works:** Pain points are symptoms. Jobs are the desired outcomes. The buyer doesn't want "less pain" -- they want a job done.

---

### Pattern 2: DOES-to-Job Extraction

**When to use:** Proposition DOES statements describe solution outcomes -- abstract to the buyer's job.

**Structure:**
```markdown
DOES: "Detects failure patterns 72 hours before breakdown"
   -> Job: "Know which assets will fail before they fail"

DOES: "Consolidates 12 compliance frameworks into a single dashboard"
   -> Job: "Ensure regulatory compliance across all jurisdictions from one view"
```

**Why this works:** DOES statements are solution-centric. Jobs are buyer-centric. Strip the solution specifics to find the underlying need.

---

### Pattern 3: Category-to-Verb Reframe

**When to use:** Internal product names or categories need translation to buyer language.

**Structure:**
```markdown
Category: "Predictive Maintenance"
   -> Job: "Reduce unplanned downtime below 2%"

Category: "Network Monitoring"
   -> Job: "Monitor network health across 340 endpoints in real-time"

Category: "Compliance Management"
   -> Job: "Ensure regulatory compliance across 12 jurisdictions before Q1 audit"
```

**Why this works:** Product categories describe what the seller built. Jobs describe what the buyer hires. The reframe forces buyer-centric language.

---

### Pattern 4: Buyer Interview Simulation

**When to use:** Available data doesn't clearly reveal jobs -- simulate the buyer's perspective.

**Structure:**
```markdown
Ask: "When you get to work on Monday, what's the first thing you need to get done?"
   -> Not: "Use our platform"
   -> But: "Make sure nothing broke over the weekend"
   -> Job: "Confirm operational continuity after every shift change"
```

**Why this works:** Jobs emerge from the buyer's daily reality, not from product documentation. Simulating the buyer's context reveals jobs that data alone might miss.

---

### Pattern 5: Job Clustering

**When to use:** Multiple pain points or DOES statements point to the same underlying job.

**Structure:**
```markdown
Pain points: "Sensor data in 47 formats", "No unified asset view", "Maintenance teams lack real-time data"
   -> These are all obstacles to one job: "See the health of every asset in real-time from one screen"
```

**Why this works:** Buyers don't think in 47 sub-problems. They think in one job they need done. Clustering reveals the job behind the fragments.

## Presentation Structure

### Opening: The Reframe

Open the Job Landscape with a contrast that shifts the reader's frame from products to jobs:

```markdown
Your portfolio has 6 products. Your buyer has 4 jobs. The products are yours. The jobs are theirs. Everything that follows organizes around the jobs.
```

### Body: 3-4 Jobs

Present each job as a named entry:

```markdown
**Job 1: [Verb phrase]**
[1-2 sentences of context: why this job matters to the buyer, what makes it hard, what "done" looks like]

**Job 2: [Verb phrase]**
[Context]

**Job 3: [Verb phrase]**
[Context]
```

### Closing: Job Landscape Summary

Summarize the jobs as a set and transition to Friction Map:

```markdown
These [N] jobs define where [buyer type] spend their operational attention. Each one carries friction that the next section maps.
```

## Techniques Checklist

### Contrast Structure

- [ ] **Reframe from products to jobs**
  - "Your portfolio has N products. Your buyer has N jobs."
  - "Buyers don't evaluate features. They hire solutions for jobs."
  - Creates the JTBD frame that governs the rest of the narrative

### Verb-Phrase Discipline

- [ ] **Every job starts with a verb**
  - "Reduce...", "Monitor...", "Ensure...", "Know...", "Detect..."
  - Never a noun phrase: "Maintenance", "Monitoring", "Compliance"
  - Test: can the buyer say "I need to [job]"? If yes, it's a valid job.

### Buyer Language Validation

- [ ] **Jobs use words the buyer uses**
  - "Unplanned downtime" (buyer says this)
  - Not "mean time between failures" (engineer says this)
  - "Pass the audit" (buyer says this)
  - Not "achieve regulatory compliance maturity level 4" (consultant says this)

### Number Plays

- [ ] **Quantify jobs where possible**
  - "Reduce downtime below 2%" (specific target)
  - "Monitor 340 endpoints" (specific scope)
  - "Across 12 jurisdictions" (specific breadth)
  - Quantification makes jobs concrete, not aspirational

## Quality Checkpoints

### Content Requirements

- [ ] 3-4 distinct functional jobs identified
- [ ] Every job is a verb phrase
- [ ] No product category names used as jobs
- [ ] Jobs use buyer language, not seller language
- [ ] Each job has 1-2 sentences of context
- [ ] At least 2 citations to customer/market data

### Structure Requirements

- [ ] Opening contrast reframes from products to jobs
- [ ] Jobs presented as named entries (Job 1, Job 2, etc.)
- [ ] Closing summarizes job landscape
- [ ] Word count within proportional range (+/-10%)
- [ ] Smooth transition from Hook
- [ ] Smooth transition to Friction Map

## Common Mistakes

### Mistake 1: Product Categories as Jobs

**Bad:**
> **Job 1: Predictive Maintenance**
> Our predictive maintenance solution helps organizations reduce downtime.

**Why it fails:** "Predictive Maintenance" is a product category, not a job. The buyer doesn't wake up thinking "I need predictive maintenance."

**Good:**
> **Job 1: Reduce unplanned downtime below 2%**
> Plant managers at European utilities lose an average of 340 hours annually to unplanned equipment failures<sup>[1]</sup>. The job isn't "buy maintenance software" -- it's "know which assets will fail before they fail, and schedule repairs in the next shift window."

**Why it works:** Starts with verb, describes measurable outcome, uses buyer language.

---

### Mistake 2: Too Abstract

**Bad:**
> **Job 1: Optimize operations**

**Why it fails:** Every solution claims to "optimize operations." This job is too vague to map to a specific solution.

**Good:**
> **Job 1: Reduce unplanned downtime below 2%**

**Why it works:** Specific, measurable, maps to one solution.

---

### Mistake 3: Seller Perspective

**Bad:**
> **Job 1: Leverage AI-powered analytics to drive operational excellence**

**Why it fails:** No buyer talks like this. This is marketing copy, not a job description.

**Good:**
> **Job 1: Know which assets will fail before they fail**

**Why it works:** A plant manager would actually say this sentence.

## Language Variations

### German Adjustments

**Verb-phrase construction:**
German verb phrases may use infinitive constructions or "Um...zu" patterns:

```markdown
**Aufgabe 1: Ungeplante Ausfallzeiten unter 2% senken**
Anlagenbetreiber europäischer Versorger verlieren durchschnittlich 340 Stunden jährlich durch ungeplante Geräteausfälle<sup>[1]</sup>. Die Aufgabe lautet nicht "Wartungssoftware kaufen", sondern "wissen, welche Anlagen ausfallen werden, bevor sie ausfallen."
```

**Buyer language validation:**
German B2B buyers use different registers. Validate against industry publications (VDI, BDEW, Bitkom) rather than academic German.

## Related Patterns

- See `friction-map-patterns.md` for per-job obstacle mapping
- See `portfolio-map-patterns.md` for 1:1 job-to-solution mapping
- See `invitation-patterns.md` for entry point construction
