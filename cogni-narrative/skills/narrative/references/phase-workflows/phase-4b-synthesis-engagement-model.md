# Phase 4b: Arc-Specific Insight Summary (engagement-model)

**Arc Framework:** Principles -> Process -> Partnership -> Outcomes
**Arc:** `engagement-model` (Portfolio-native) | **Output:** `insight-summary.md` at project root (target range from `--target-length`, default ~1,400 words)

**Shared steps:** Read [shared-steps.md](shared-steps.md) for entity counting, output template, validation gates, and write instructions.

---

## Arc-Specific Headers

**English:**
- `## Principles: Principles We Work By`
- `## Process: How an Engagement Unfolds`
- `## Partnership: What We Expect From You`
- `## Outcomes: What Success Looks Like`

**German (if `language: de`):**
- `## Prinzipien: Unsere Arbeitsprinzipien`
- `## Prozess: Wie eine Zusammenarbeit verläuft`
- `## Partnerschaft: Was wir von Ihnen erwarten`
- `## Ergebnisse: Wie Erfolg aussieht`

---

## Step 4.1.1: Load Evidence Entities

This arc is portfolio-native and answers "how will this work land in my organization?" — it loads engagement-shaping entities.

**Load:**
- All solutions from `solutions/*.json` (primary — phases, artifacts, cadence patterns)
- All propositions from `propositions/*.json` (for MEANS themes used in Outcomes)
- All customers from `customers/*.json` (for buying_criteria patterns used in Partnership)
- Portfolio manifest from `portfolio.json` (for engagement framing, methodology names)
- Existing `company-credo` arc output (if present — for Principle-Conviction traceability)

**After loading, inventory what you have:**
- Across the portfolio's solutions, what is the canonical phase structure? Do most solutions share 4–6 phases, or is there wide variation?
- Which delivery phrases recur across 3+ solutions? ("proof-first", "phased", "contract-first", etc.) — these are Principle candidates.
- Which buying criteria recur across 3+ customer profiles? — these are Partnership candidates.
- Which MEANS themes recur across 4+ propositions? — these are Outcome candidates.
- Is there a published methodology name in `portfolio.json.positioning`? — this is a ready-made Principle anchor.

---

## Step 4.1.4: Extended Thinking Sub-steps

---

### Sub-step A: Extract Principles

Before writing, find the operating principles:

1. **Scan solution descriptions for recurring delivery phrases.** A phrase appearing in 3+ solutions is a principle candidate.
2. **Identify any named methodology** from `portfolio.json.positioning` or cross-cutting MEANS themes.
3. **Cross-reference with `company-credo` Convictions if available.** Principles often operationalise Convictions — the traceability is valuable.
4. **Select 3–4 principles.** Each must be operational (observable in week 1 of an engagement), not a value.

**Validation:**
- Every principle is operational, not aspirational
- Each principle has a contrast (what it replaces in the industry default)
- Each principle is traceable to the Process element below
- No generic corporate values ("customer-centric", "quality-first")

---

### Sub-step B: Aggregate the Canonical Process

For the Process element:

1. **Extract all `phases[]` arrays** from loaded solutions.
2. **Identify the canonical shape.** Which phases appear in 4+ solutions? That intersection is the canonical Process.
3. **For each canonical phase, extract:**
   - What happens (the work)
   - What artifact(s) are produced
   - What approval(s) are required
   - Typical time band
4. **Verify solution agnosticism.** Drop any phase specific to one solution — those belong on capability pages.
5. **Map each phase to a traceable Principle from Sub-step A** where possible.

**Validation:**
- 4–6 canonical phases
- Every phase has an artifact
- Every phase has a time band (range, not false precision)
- No phase is solution-specific
- At least one phase calls out a traceable Principle

---

### Sub-step C: Extract Partnership Expectations

For the Partnership element:

1. **Scan customer buying criteria for recurring patterns.** A criterion appearing in 3+ customer profiles is a Partnership candidate.
2. **Scan solution readiness requirements.** Explicit prerequisites (data access, approvals, decision authority) are Partnership candidates.
3. **Select 3–4 expectations.** Each must name a concrete thing (a person, a data source, an approval authority, a timebox).
4. **Pair each expectation with a consequence** ("if this isn't available, we pause the engagement rather than work around it").
5. **Offer reciprocity where possible** ("we provide a one-page technical scope to accelerate that review").

**Validation:**
- 3–4 expectations
- Each names a concrete thing (not "executive buy-in")
- Each has a consequence if missing
- Each uses You-Phrasing
- Tone is constructive, not defensive

---

### Sub-step D: Aggregate Cross-Cutting Outcomes

For the Outcomes element:

1. **Scan MEANS fields across all propositions.** Identify recurring themes — phrases that appear in 4+ MEANS statements.
2. **Select 3 cross-cutting themes.** Each must be true across most of the portfolio, not specific to one capability.
3. **For each theme, name the buyer-visible change** (not the internal metric) and how the change is observed.
4. **Verify no pricing, no ROI numbers, no per-capability metrics.** Those belong elsewhere.

**Validation:**
- Exactly 3 outcome themes
- Each describes buyer-visible change (not company activity)
- Each names a way to observe the change
- Each is cross-cutting (true for most engagements)
- No pricing or ROI numbers

---

### Sub-step E: Craft Title, Hook, and Elements

**Title:** Frame as a description of how the company works, not a generic "Our Approach" header. Must preview a distinctive working style (e.g., "Weekly Demos, Signed Contracts, Owned Outcomes: How We Actually Work").

**Hook (~8% of target length — the shortest Hook across all arcs):**
- One observation about what buyers typically fear about services engagements
- Preview that the company handles that fear differently
- Pattern: "[Buyer fear or friction] + [Preview of how the company handles it]"

**D1. Principles (~22% of target length)**

Write:
- Opening transition from Hook
- 3–4 named principles
- Each: headline + paragraph with operational framing + contrast to industry default
- At least one principle grounded in portfolio evidence with a citation
- Close with transition to Process

**D2. Process (~28% of target length — the longest element)**

Write:
- Opening canonical walkthrough framing
- 4–6 phase cards with consistent skimmable structure:
  - Phase number + name + time band
  - What happens / What you see / What you sign
  - Traceable principle (optional)
- Every phase has an artifact and a time band
- No phase is solution-specific
- Close with transition to Partnership

**D3. Partnership (~20% of target length)**

Write:
- Opening reciprocity framing — name that Partnership is the reciprocal of Promise
- 3–4 You-Phrased expectations with consequences
- Each expectation names a concrete thing
- Offer reciprocity where possible
- Close with transition to Outcomes

**D4. Outcomes (~22% of target length)**

Write:
- Opening engagement-level framing — name that outcomes here are cross-cutting
- 3 outcome themes
- Each describes buyer-visible change + how it's observed
- No pricing, no ROI numbers, no per-capability metrics
- Close with soft close + single invitation to a specific next page (Capabilities or persona page)

---

### Sub-step F: Self-Review

1. **Word count:** Within target length range? Hook ~8%, Principles ~22%, Process ~28%, Partnership ~20%, Outcomes ~22%?
2. **Arc coherence:** Principles → Process → Partnership → Outcomes builds a single description? Each element references the previous?
3. **Engagement-Model constraints:**
   - [ ] Every Principle is operational, not aspirational?
   - [ ] Every Process phase has an artifact and a time band?
   - [ ] No Process phase is solution-specific?
   - [ ] Every Partnership expectation names a concrete thing?
   - [ ] Every Partnership expectation has a consequence if missing?
   - [ ] Every Outcome describes buyer-visible change?
   - [ ] Every Outcome is cross-cutting?
   - [ ] No pricing, no ROI numbers anywhere in the arc?
4. **Evidence:** 5–10 total citations? Concentrated in Process (2–4) and Principles (1–2)?
5. **Techniques applied:** Operational framing (Principles), artifact naming (Process), You-Phrasing (Partnership), outcome framing (Outcomes)?

Now proceed to validation and write steps in [shared-steps.md](shared-steps.md).
