# Engagement Model Story Arc

## Arc Metadata

**Arc ID:** `engagement-model`
**Display Name:** Engagement Model
**Display Name (German):** Zusammenarbeitsmodell

**Elements (Ordered):**
1. Principles: Principles We Work By
2. Process: How an Engagement Unfolds
3. Partnership: What We Expect From You
4. Outcomes: What Success Looks Like

**Elements (German):**
1. Prinzipien: Unsere Arbeitsprinzipien
2. Prozess: Wie eine Zusammenarbeit verläuft
3. Partnerschaft: Was wir von Ihnen erwarten
4. Ergebnisse: Wie Erfolg aussieht

## Word Proportions

Section lengths are expressed as proportions of the total target length. Default total: 1,400 words (How We Work pages are navigation-oriented — buyers scan them for reassurance, not a read-through). To compute word ranges for a given `--target-length T`: apply +/-15% band to get `[T*0.85, T*1.15]`, then multiply each proportion.

| Element | English Header | German Header | Proportion | Default Range (T=1400) |
|---------|----------------|---------------|-----------|------------------------|
| Hook | *(Working with us)* | *(Zusammenarbeit mit uns)* | 8% | 95-129 |
| Principles | Principles: Principles We Work By | Prinzipien: Unsere Arbeitsprinzipien | 22% | 262-354 |
| Process | Process: How an Engagement Unfolds | Prozess: Wie eine Zusammenarbeit verläuft | 28% | 333-451 |
| Partnership | Partnership: What We Expect From You | Partnerschaft: Was wir von Ihnen erwarten | 20% | 238-322 |
| Outcomes | Outcomes: What Success Looks Like | Ergebnisse: Wie Erfolg aussieht | 22% | 262-354 |

**Proportions sum to 100%.** Default total: 1,400 words (customizable via `--target-length`). Tolerance: +/-10% of computed section midpoint.

## Detection Configuration

### Content Type Mapping

This arc is selected when:
- `content_type: "engagement-model"`
- `content_type: "how-we-work"`

### Content Analysis Keywords

Keywords: "how we work", "engagement model", "working with us", "our process", "delivery model", "partnership", "our approach", "principles", "ways of working"

### Detection Threshold

Keyword density >= 12%

## Use Cases

**Best For:**
- Website "How We Work" / "Our Approach" pages
- The engagement-model section of proposals (when a proposal needs to explain not just what will be delivered but how)
- Partner onboarding pages where a new collaborator needs to understand the company's defaults
- Sections of internal documentation aimed at new hires explaining how the company actually operates

**Typical Input Sources:**
- `solutions/*.json` — implementation phases are the raw material for the Process element
- `portfolio.json` — engagement framing, methodology references
- `customers/*.json` — `buying_criteria` patterns reveal what the company consistently expects from buyers (inputs for Partnership)
- Cross-cutting MEANS themes from `propositions/*.json` — aggregated into outcome themes for the Outcomes element

**Not Suitable For:**
- Capability or product pages (use `corporate-visions` scoped to one capability)
- Portfolio overviews (use `jtbd-portfolio`)
- Deal-specific pitches where the process section needs to be customised per buyer (use cogni-sales `/why-change`)
- Any content whose governing question is "what does this solution do" rather than "how will this work land in my organization"

**Important separation from pricing:** Engagement-model narratives describe process, partnership, and outcomes. They do **not** contain pricing. Pricing belongs on capability pages (where it can be tied to scope) or in proposals (where it is customer-specific). Mixing pricing into the engagement-model page makes the page read as a sales pitch, which is exactly the tone the buyer is looking to avoid when they click "How We Work".

## Element Definitions

### Element 1: Principles (Principles We Work By)

**Purpose:**
Name 3–4 operating principles that shape every engagement regardless of capability or market. Principles are the answer to the buyer's implicit question: "Before we talk about what you do, how do you work?"

**Source Content:**
- Cross-cutting themes from `solutions/*.json` (primary — look for phrases like "proof-first", "phased", "outcome-locked", "contract-first" that appear in multiple solutions)
- `portfolio.json.positioning` — often names the company's methodology
- Related Convictions from any existing `company-credo` arc output — Principles operationalise Convictions at the engagement level

**Transformation Approach:**
1. Scan solution descriptions for recurring delivery patterns. A phrase that appears in 3+ solutions is a principle candidate.
2. Phrase each principle as a short headline + one-paragraph explanation of how it shows up in the work.
3. Each principle must be operational — it must name something the company does differently, not something it values.

**Key Techniques:**
- Operational framing: "We always X" / "We never Y" — never "we value X".
- Contrast Structure: name what the principle replaces ("Instead of monthly status reports, we run weekly demos").
- Traceability: link each principle to where it shows up in the Process element below.

**Constraints:**
- 3–4 principles total (fewer feels thin; more feels like a values wall).
- Principles must be operational, not values.
- Each principle must be observable in Process (a buyer reading Process should see the principle in action).

**Pattern Reference:** `principles-patterns.md`

---

### Element 2: Process (How an Engagement Unfolds)

**Purpose:**
Walk the buyer through the typical arc of an engagement — not as a generic "phase 1, phase 2, phase 3" timeline, but as a concrete sequence of things the buyer will see, sign, and receive. Process is the longest element in this arc because it is what the buyer came to the page to read.

**Source Content:**
- `solutions/*.json` phases — aggregate the phases used across solutions, deduplicating where phase names overlap
- Implementation patterns: read all solution entities and find the recurring phase structure (e.g., "Discovery / Data Contract / Pilot / Rollout")
- Cadence signals from the company description (weekly, sprint-based, shift-aligned)

**Transformation Approach:**
1. Identify the 4–6 canonical phases that recur across the portfolio's solutions. If solutions disagree, flag it and use the most common structure.
2. For each phase, name:
   - **What happens** (the work being done)
   - **What the buyer sees** (deliverables, demos, reports)
   - **What the buyer signs** (contracts, data agreements, approvals)
   - **How long it typically takes** (ranges are fine; avoid false precision)
3. Present phases as a sequence that can be skimmed — headings, not dense paragraphs.

**Key Techniques:**
- Artifact naming: every phase references a specific artifact the buyer will receive.
- Cadence specificity: "weekly working demo" > "regular updates".
- Time bands: "2–4 weeks" > "a few weeks".

**Constraints:**
- 4–6 phases (fewer undersells rigor; more overwhelms).
- Every phase names at least one concrete artifact.
- Every phase has a time band.
- Phases must be solution-agnostic — they describe *how* the company works, not what a specific solution delivers. If a phase is specific to one solution, it belongs on that solution's capability page.

**Pattern Reference:** `process-patterns.md`

---

### Element 3: Partnership (What We Expect From You)

**Purpose:**
Name — plainly — what the buyer needs to bring to the engagement for it to work. This is the element that most companies skip, which is why including it reads as unusually honest. Partnership is the reciprocal of Promise: Promise commits the company, Partnership commits the buyer.

**Source Content:**
- `customers/*.json` `buying_criteria` patterns (primary — recurring buying criteria across personas reveal what the company expects)
- Solution readiness requirements from `solutions/*.json` (input data, approvals, access rights)
- Common friction points from past engagements (from portfolio context if available)

**Transformation Approach:**
1. Extract 3–4 expectations that apply to most engagements (not all — be honest about what is engagement-specific).
2. For each expectation, state:
   - **What the company needs from the buyer** (access, input, approvals, decisions)
   - **Why it matters** (what happens to the engagement if it is missing)
3. Frame as constructive rather than defensive — Partnership is a contract, not a complaint.

**Key Techniques:**
- You-Phrasing: "You will need to…" / "Sie werden benötigen…"
- Consequence framing: "If this isn't available, we pause the engagement rather than work around it" — this reads as discipline, not obstruction.
- Reciprocal framing: tie each expectation to something the company commits in return.

**Constraints:**
- 3–4 expectations (fewer feels dishonest — every engagement needs buyer input; more feels like a laundry list).
- Each expectation names a concrete thing (a person, a data source, an approval authority, a timebox).
- Partnership must not read as a list of reasons the engagement could fail. It is a list of inputs the engagement needs.

**Pattern Reference:** `partnership-patterns.md`

---

### Element 4: Outcomes (What Success Looks Like)

**Purpose:**
Close by stating what the buyer will be able to point to after a successful engagement — in outcome terms, not deliverable terms. Outcomes is the section that makes the How We Work page feel like a commitment to results rather than a description of activity.

**Source Content:**
- Aggregated MEANS themes from `propositions/*.json` (primary — MEANS describes the meaning of outcomes, which is what Outcomes summarises)
- Cross-cutting outcome patterns from solutions

**Transformation Approach:**
1. Aggregate the MEANS layer across all propositions. Identify 3 outcome themes that recur (e.g., "shorter decision cycles", "reduced rework", "preserved institutional knowledge").
2. For each outcome theme, state:
   - **What the buyer will see change** (in buyer language, not internal metrics)
   - **How that change is visible** (what measurement or artifact proves it)
3. Do NOT list per-capability outcomes — those belong on capability pages. Outcomes at the engagement-model level are cross-cutting.

**Key Techniques:**
- Outcome framing: "You will see X change" — not "We will deliver Y".
- Measurability: every outcome theme names a way to observe the change.
- Cross-cutting discipline: outcomes must be true regardless of which capability was bought.

**Constraints:**
- 3 outcome themes (keep it tight — Outcomes is a summary, not a catalog).
- Each is cross-cutting (true for most engagements).
- No per-capability outcomes (those belong on capability pages).
- No pricing, no ROI numbers — keep those on capability or proposal pages.

**Pattern Reference:** `outcomes-patterns.md`

## Narrative Flow

### Hook Construction (Working With Us)

**Approach:**
Open with one observation about what the buyer typically fears about engagements — and preview that the company works differently in exactly that way. The Hook reframes the page from "how we work" (which can sound procedural) to "what working with us actually feels like" (which promises a different experience).

**Pattern:**
```markdown
[One fear or friction buyers typically bring to engagements] + [Preview of how the company handles that differently]

Example:
"The thing most buyers want to know about a services engagement isn't which phases we run — it's how often the program will surprise them. We built our entire way of working around making the surprises small and early."
```

**Word Target:** 8% of target length (the shortest Hook across all arcs — the buyer wants to get to Process quickly).

---

### Element Transitions

**Hook → Principles:**
- Hook previews that the company works differently; Principles name exactly how.
- **Transition pattern:** "Here are the four principles that shape how every engagement runs."

**Principles → Process:**
- Principles state what the company does differently; Process shows those principles in action.
- **Transition pattern:** "Here is what those principles look like in a typical engagement."

**Process → Partnership:**
- Process is what the company does; Partnership is what the buyer needs to do for it to work.
- **Transition pattern:** "None of this works unless you bring a few things to the table as well."

**Partnership → Outcomes:**
- Partnership is the input; Outcomes is the result.
- **Transition pattern:** "If we both hold up our side of that, here is what you will be able to point to at the end."

---

### Closing Pattern

**Final Sentence:**
A soft reassurance that the process is flexible where it matters and firm where it matters, plus one invitation to a more specific next page (usually Capabilities or a persona page).

**Examples:**
- "The process adapts to your size and scope. The principles do not. If you want to see which capabilities ride on top of this engagement model, the Capabilities page is the next stop."
- "Dieses Modell skaliert mit Ihrer Größe. Die Prinzipien tun das nicht. Wenn Sie sehen möchten, welche Capabilities auf diesem Modell aufsetzen, ist die Capabilities-Seite der nächste Schritt."

## Citation Requirements

### Citation Density

**Target:** 5–10 total citations across the narrative (lower than most arcs — Engagement Model is primarily descriptive, not evidential).
**Ratio:** Approximately 1 citation per 150–200 words.

### Citation Distribution

**Hook:** 0–1 citations (optional).
**Principles:** 1–2 citations (anywhere a principle is grounded in a specific portfolio artifact or past engagement).
**Process:** 2–4 citations (where phase durations or artifacts reference solution data).
**Partnership:** 1–2 citations (where an expectation traces back to a documented buying criterion).
**Outcomes:** 1–2 citations (where an outcome theme references a specific MEANS statement).

## Quality Gates

### Arc Completeness

- [ ] All 4 elements present (Principles, Process, Partnership, Outcomes)
- [ ] Hook present (within hook proportion of target)
- [ ] Word counts within computed proportional ranges (+/-10% tolerance)
- [ ] Smooth transitions between elements

### Engagement-Model Constraints

- [ ] **Operational Principles:** Every Principle is an operation ("we always X"), not a value ("we value X")
- [ ] **Concrete Process:** Every Process phase names at least one artifact and one time band
- [ ] **Solution-agnostic Process:** No phase is specific to one solution
- [ ] **Reciprocal Partnership:** Every Partnership expectation is tied to a consequence for the engagement
- [ ] **Cross-cutting Outcomes:** Every Outcome theme is true across most of the portfolio
- [ ] **No pricing:** Neither Principles, Process, Partnership, nor Outcomes contain pricing numbers
- [ ] **No per-capability content:** Nothing in this arc is specific to one solution — it all describes how the company works

### Narrative Coherence

- [ ] Hook → Principles → Process → Partnership → Outcomes builds a single description
- [ ] Principles appear visibly inside Process (the Principles-Process connection must be traceable)
- [ ] Partnership is reciprocal to Promise (if a `company-credo` arc output exists alongside)
- [ ] Outcomes are cross-cutting, not per-capability

## Common Pitfalls

### Principles Pitfalls

**Values instead of operations:**

:x: **Bad:**
> **Principle 1: Customer-Centric Delivery**
> We put our customers at the center of every engagement.

**Why it fails:** Not operational — no buyer can tell what this looks like in practice.

:white_check_mark: **Good:**
> **Principle 1: Weekly working demos, no status reports.**
> Every engagement we run delivers a working demo every Friday, starting in week 1. We do not produce monthly status reports. If you need an executive update, you can watch the recorded demo from that week — it carries more signal and takes less time.

### Process Pitfalls

**Generic phase names with no artifacts:**

:x: **Bad:**
> **Phase 1: Discovery.** We understand your needs.
> **Phase 2: Design.** We design the solution.
> **Phase 3: Delivery.** We deliver.
> **Phase 4: Support.** We provide ongoing support.

**Why it fails:** No artifacts, no time bands, no specificity. Could describe any services company on earth.

:white_check_mark: **Good:**
> **Phase 1: Data Contract (2–4 weeks).**
> What happens: We sit with your IT and business owners and negotiate a contract defining which systems contribute what data, under which access controls, with which freshness SLA.
> What you see: A signed Data Contract document, version-controlled in your repo.
> What you sign: The Data Contract and an access-rights matrix.
>
> **Phase 2: Instrumented Baseline (3–6 weeks).**
> ...

### Partnership Pitfalls

**Laundry list of reasons engagements fail:**

:x: **Bad:**
> We require committed sponsors, dedicated resources, clean data, clear objectives, executive buy-in, change management capacity, and timely decisions.

**Why it fails:** Reads as defensive. The buyer sees seven reasons the engagement could fail before it starts.

:white_check_mark: **Good:**
> **You will need one decision-maker with data authority.** Someone in your organization needs to be able to approve data contracts across the business units we're instrumenting. If that person doesn't exist yet, our first phase is helping you appoint them — we don't try to work around this.

### Outcomes Pitfalls

**Per-capability outcomes:**

:x: **Bad:**
> **Outcome 1:** Your predictive maintenance system will reduce downtime by 40%.

**Why it fails:** This is a capability-specific outcome. It belongs on the predictive-maintenance capability page, not the How We Work page.

:white_check_mark: **Good:**
> **Outcome 1: Shorter decision cycles.**
> Regardless of which capability you engage us for, you will see the cycle time between "we noticed something" and "we decided what to do about it" compress measurably. We measure this explicitly at the start and end of every engagement.

## Version History

- **v1.0.0:** Initial Engagement Model arc definition — built for the customer-narrative How We Work page scope in portfolio-communicate.

## See Also

- `../arc-registry.md` — Master index of all story arcs
- `principles-patterns.md` — Operational principle extraction patterns
- `process-patterns.md` — Phase aggregation and artifact-naming patterns
- `partnership-patterns.md` — Reciprocal expectation patterns
- `outcomes-patterns.md` — Cross-cutting outcome aggregation patterns
