# Phase 4b: Arc-Specific Insight Summary (jtbd-portfolio)

**Arc Framework:** Job Landscape -> Friction Map -> Portfolio Map -> Invitation
**Arc:** `jtbd-portfolio` (Portfolio-native) | **Output:** `insight-summary.md` at project root (target range from `--target-length`, default ~1,675 words)

**Shared steps:** Read [shared-steps.md](shared-steps.md) for entity counting, output template, validation gates, and write instructions.

---

## Arc-Specific Headers

**English:**
- `## Job Landscape: Functional Jobs`
- `## Friction Map: Obstacles and Cost of Inaction`
- `## Portfolio Map: Solutions by Job`
- `## Invitation: Next Step`

**German (if `language: de`):**
- `## Job-Landschaft: Funktionale Aufgaben`
- `## Reibungskarte: Hindernisse und Handlungsdruck`
- `## Portfolio-Zuordnung: Lösungen je Aufgabe`
- `## Einladung: Nächster Schritt`

---

## Step 4.1.1: Load Evidence Entities

This arc is portfolio-native -- it loads portfolio entities, not research entities. Evidence comes from cogni-portfolio data files.

**Load:**
- All propositions from `propositions/` matching `*--{market}.json` (IS/DOES/MEANS statements)
- Customer profiles from `customers/{market}.json` (pain points, buyer personas)
- Market description from `markets/{market}.json` (industry context, dynamics)
- All competitors from `competitors/` matching `*--{market}.json` (current approach weaknesses)
- All solutions from `solutions/` matching `*--{market}.json` (implementation phases, pricing tiers)
- All packages from `packages/` matching `*--{market}.json` (starter tiers, if available)
- Features from `features/` for each proposition's feature slug (IS layer definitions)
- Portfolio manifest from `portfolio.json` (company context, industry)

**After loading, inventory what you have:**
- How many propositions? Which features do they cover?
- How many customer pain points? Do they cluster into distinct job categories?
- How many competitors? What weaknesses emerge?
- Do solutions have entry-level tiers (PoV, pilot, starter)?
- Any gaps -- features without propositions? Propositions without solutions? Flag these now.

---

## Step 4.1.4: Extended Thinking Sub-steps

---

### Sub-step A: Extract Functional Jobs

Before writing, extract jobs from the portfolio data:

1. **Scan customer pain points.** Each pain point implies a job. Group related pain points into job clusters.
2. **Cross-reference with proposition DOES statements.** Each DOES reveals what a solution does, which implies the underlying job.
3. **Phrase as verb phrases.** Convert every job to a verb phrase in buyer language.
4. **Select 3-4 jobs.** Choose the jobs with strongest evidence (most pain points, clearest DOES mapping, best cost data).

**Validation:**
- Every selected job is a verb phrase (starts with a verb)
- No product category names used as jobs
- Each job has at least one proposition that addresses it
- Jobs use buyer language (validate against market description vocabulary)

Map: Job -> Proposition(s) -> Solution(s)

---

### Sub-step B: Map Frictions Per Job

For each job from Sub-step A:

1. **Identify primary obstacle** from customer pain points and competitor weaknesses.
2. **Quantify cost of inaction** from proposition evidence arrays and market data.
3. **Check for forcing functions** -- external pressures that make this friction urgent.

**Validation:**
- Every job has at least one friction with quantified cost
- Cost figures have citations to portfolio entity files
- No generic friction ("digital transformation challenges") -- all friction is job-specific

---

### Sub-step C: Map Solutions 1:1 to Jobs

For each job from Sub-step A:

1. **Select the best-matching proposition** based on DOES alignment with the job.
2. **Extract IS/DOES/MEANS** from the proposition and its feature.
3. **Verify 1:1:** One job, one solution. No duplicates, no orphans.

**Validation:**
- Count(jobs) == Count(solutions mapped)
- Each proposition used exactly once
- Orphaned propositions flagged
- IS is a coherent definition, not a feature list
- DOES uses You-Phrasing with quantified outcomes
- MEANS explains a specific competitive barrier

---

### Sub-step D: Craft Title, Hook, and Elements

**Title:** Frame as an assertion about the buyer's job landscape (e.g., "European Utilities Manage 4,200 Processes But Buy Solutions for 12: Mapping the Job-Solution Gap"). Must signal the JTBD frame and be specific to this market.

**Hook (~10% of target length):**
- One sharp industry observation that creates inevitability (Context Setter)
- Ground with at least 1 citation
- Preview the job landscape without listing jobs
- Pattern: "[Quantified observation] + [Implication that reframes from products to jobs]"

**D1. Job Landscape: Functional Jobs (~24% of target length)**

Write:
- Open with Contrast Structure: products vs. jobs reframe
- Present 3-4 jobs as named verb-phrase entries
- Each job gets 1-2 sentences of context
- Apply Number Plays to quantify job scope where possible
- Close with transition to Friction Map

**D2. Friction Map: Obstacles and Cost of Inaction (~21% of target length)**

Write:
- Per-job friction entries (obstacle + cost of inaction)
- Apply Forcing Functions where external pressures exist
- Apply Compound Impact to stack costs across jobs
- Quantify every friction with citations
- Close with transition to Portfolio Map

**D3. Portfolio Map: Solutions by Job (~27% of target length)**

Write:
- Open with 1:1 mapping statement
- Per-job IS/DOES/MEANS entries
- Apply You-Phrasing in every DOES layer
- Apply Number Plays in every DOES layer
- Verify no feature lists
- Close with transition to Invitation

**D4. Invitation: Next Step (~18% of target length)**

Write:
- Connect to Portfolio Map (the portfolio is mapped, now act)
- Present ONE low-commitment entry point
- Include investment and deliverable
- Close with explicit cogni-sales `/why-change` handoff signal

---

### Sub-step E: Self-Review

1. **Word count:** Within target length range? Hook ~10%, Job Landscape ~24%, Friction Map ~21%, Portfolio Map ~27%, Invitation ~18%?
2. **Arc coherence:** Jobs -> Frictions -> Solutions -> Invitation builds logically? Each element references the previous?
3. **JTBD constraints:**
   - [ ] All jobs are verb phrases? (no product categories)
   - [ ] 1:1 mapping verified? (Count(jobs) == Count(solutions))
   - [ ] No feature lists in Portfolio Map? (IS/DOES/MEANS only)
   - [ ] Cogni-sales handoff in Invitation? (`/why-change` referenced)
   - [ ] Orphaned solutions flagged?
4. **Evidence:** >= 15 citations distributed across elements? Every cost claim cited?
5. **Techniques applied:** Contrast Structure (1+ in Job Landscape), IS-DOES-MEANS (all solutions), You-Phrasing (all DOES layers), Number Plays (3+ instances), Forcing Functions (1+ in Friction Map)?

Now proceed to validation and write steps in [shared-steps.md](shared-steps.md).
