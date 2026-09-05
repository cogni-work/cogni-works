# Story Arc Registry

## Overview

This registry indexes all available story arcs for the `narrative` skill. Each arc provides a different narrative framework for transforming structured content (research syntheses, analyses, reports) into compelling executive narratives.

## Quick Reference

| # | Arc ID | Elements (Short) | TIPS | Best For | Detection Priority |
|---|--------|-----------------|------|----------|--------------------|
| 1 | `corporate-visions` | Change → Now → You → Pay | - | Market research, B2B, sales | Default fallback |
| 2 | `technology-futures` | Emerging → Converging → Possible → Required | - | Innovation, R&D, tech trends | `content_type: "technology"` |
| 3 | `competitive-intelligence` | Landscape → Shifts → Positioning → Implications | - | Competitive analysis, threats | `content_type: "competitive"` |
| 4 | `strategic-foresight` | Signals → Scenarios → Strategies → Decisions | - | Long-range planning, scenarios | `content_type: "foresight"` |
| 5 | `industry-transformation` | Forces → Friction → Evolution → Leadership | - | Industry analysis, regulation | `content_type: "industry"` |
| 6 | `trend-panorama` | Forces → Impact → Horizons → Foundations | T→I→P→S | Trend-scout output (theme-less), TIPS panoramas | Structural: `trend-scout-output.json` without value model |
| 7 | `theme-thesis` | Change → Now → You → Pay | T→I→P→S | Theme-level investment narratives | `content_type: "theme"` |
| 8 | `jtbd-portfolio` | Jobs → Friction → Portfolio → Invitation | - | Portfolio introductions, capability overviews, pre-sales | `content_type: "jtbd"` |
| 9 | `company-credo` | Mission → Conviction → Credibility → Promise | - | About-Us pages, company introductions, brand identity narratives | `content_type: "company-credo"` or `"about-us"` |
| 10 | `engagement-model` | Principles → Process → Partnership → Outcomes | - | How-We-Work pages, engagement sections of proposals, partner onboarding | `content_type: "engagement-model"` or `"how-we-work"` |
| 11 | `smarter-service` | Forces → Impact → Horizons → Foundations | T→I→P→S | TIPS reports with investment themes (theme-aware sibling of trend-panorama) | Structural: `tips-value-model.json` present |

## Arc Selection Logic

1. **Explicit selection**: Caller specifies `arc_id` directly (highest priority)
2. **Structural detection**: Check for arc-specific file signatures (e.g., `trend-scout-output.json`)
3. **Content type mapping**: Automatic detection based on `content_type` or `research_type` metadata
4. **Content analysis**: Keyword density analysis of input content
5. **Fallback default**: corporate-visions

## Available Story Arcs

### 1. Corporate Visions (Default)

**Arc ID:** `corporate-visions`
**Display Name:** Corporate Visions
**Elements:** Why Change → Why Now → Why You → Why Pay

**Best For:**
- Market research
- Competitive positioning
- Sales enablement
- B2B value propositions

**Detection Signals:**
- `content_type: "generic"` or `"market"`
- Default fallback when no other arc matches

**Section Proportions:**
- Hook: 10%
- Why Change: 27%
- Why Now: 21%
- Why You: 27%
- Why Pay: 15%
- **Default total:** 1,675 words (customizable via `--target-length`)

**Contract:** `corporate-visions/arc-definition.md`

---

### 2. Technology Futures

**Arc ID:** `technology-futures`
**Display Name:** Technology Futures
**Elements:** What's Emerging → What's Converging → What's Possible → What's Required

**Best For:**
- Technology trend research
- Innovation scouting
- R&D strategy
- Capability roadmapping

**Detection Signals:**
- `content_type: "technology"`
- Keywords (>=15% density): "emerging", "innovation", "capability", "technology", "R&D", "breakthrough"

**Section Proportions:**
- Hook: 11%
- What's Emerging: 24%
- What's Converging: 24%
- What's Possible: 24%
- What's Required: 17%
- **Default total:** 1,675 words (customizable via `--target-length`)

**Contract:** `technology-futures/arc-definition.md`

---

### 3. Competitive Intelligence

**Arc ID:** `competitive-intelligence`
**Display Name:** Competitive Intelligence
**Elements:** Landscape → Shifts → Positioning → Implications

**Best For:**
- Competitive analysis
- Market positioning
- Threat assessment
- Strategic differentiation

**Detection Signals:**
- `content_type: "competitive"`
- Keywords (>=12% density): "competitor", "market share", "positioning", "differentiation", "threat", "rivalry"

**Section Proportions:**
- Hook: 10%
- Landscape: 24%
- Shifts: 21%
- Positioning: 27%
- Implications: 18%
- **Default total:** 1,675 words (customizable via `--target-length`)

**Contract:** `competitive-intelligence/arc-definition.md`

---

### 4. Strategic Foresight

**Arc ID:** `strategic-foresight`
**Display Name:** Strategic Foresight
**Elements:** Signals → Scenarios → Strategies → Decisions

**Best For:**
- Long-range planning
- Scenario analysis
- Uncertainty navigation
- Strategic options generation

**Detection Signals:**
- `content_type: "foresight"` or `"scenarios"`
- Keywords (>=10% density): "scenario", "future", "signal", "uncertainty", "planning", "foresight"

**Section Proportions:**
- Hook: 10%
- Signals: 21%
- Scenarios: 27%
- Strategies: 24%
- Decisions: 18%
- **Default total:** 1,675 words (customizable via `--target-length`)

**Contract:** `strategic-foresight/arc-definition.md`

---

### 5. Industry Transformation

**Arc ID:** `industry-transformation`
**Display Name:** Industry Transformation
**Elements:** Forces → Friction → Evolution → Leadership

**Best For:**
- Industry analysis
- Sector transformation
- Regulatory impact
- Structural change analysis

**Detection Signals:**
- `content_type: "industry"`
- Keywords (>=12% density): "regulatory", "sector", "structural", "industry", "transformation", "policy"

**Section Proportions:**
- Hook: 10%
- Forces: 24%
- Friction: 21%
- Evolution: 27%
- Leadership: 18%
- **Default total:** 1,675 words (customizable via `--target-length`)

**Contract:** `industry-transformation/arc-definition.md`

---

### 6. Trend Panorama

**Arc ID:** `trend-panorama`
**Display Name:** Trend Panorama
**Elements:** Forces → Impact → Horizons → Foundations (TIPS: T → I → P → S)

**Best For:**
- Trend-scout output summarization (52 trend candidates)
- TIPS trend report narratives
- Multi-horizon trend landscape overviews
- Industry-specific trend panoramas

**Detection Signals:**
- `content_type: "trend"` or `"trends"` or `"tips"`
- `research_type: "smarter-service"` (trend-scout output)
- `synthesis_format: "TIPS"` in source metadata
- Structural: presence of `trend-scout-output.json` or `tips-trend-report.md`
- Keywords (>=12% density): "trend", "horizon", "act", "plan", "observe", "TIPS", "signal intensity", "dimension"

**TIPS Dimension Mapping:**
- Forces = T (Externe Effekte): economy, regulation, society
- Impact = I (Digitale Wertetreiber): CX, products, processes
- Horizons = P (Neue Horizonte): strategy, leadership, governance
- Foundations = S (Digitales Fundament): culture, workforce, technology

**Horizon Cascade:** Each element applies Act → Plan → Observe progression internally.

**Section Proportions:**
- Hook: 10%
- Forces: 24%
- Impact: 24%
- Horizons: 24%
- Foundations: 18%
- **Default total:** 1,675 words (customizable via `--target-length`)

**Contract:** `trend-panorama/arc-definition.md`

---

### 7. Theme Thesis

**Arc ID:** `theme-thesis`
**Display Name:** Theme Thesis
**Elements:** Why Change → Why Now → Why You → Why Pay (Corporate Visions adapted for themes)

**Best For:**
- Individual theme sections within TIPS trend reports
- Investment thesis narratives with portfolio-backed solutions
- Theme-level persuasion with IS-DOES-MEANS Power Positions
- CxO-level theme justification

**Detection Signals:**
- `content_type: "theme"` or `"investment-theme"`
- Structural: presence of `value_chains[]` with `candidate_ref` and `solution_templates[]`
- Keywords (>=15% density): "theme", "investment thesis", "value chain", "solution template", "strategic question"

**TIPS Candidate Mapping (cross-dimensional, not 1:1):**
- Why Change = T-candidates (unconsidered need) + I-candidates (impact)
- Why Now = Act-horizon candidates from any dimension (forcing functions)
- Why You = Solution Templates (IS) + P-candidates (DOES) + S-candidates (MEANS)
- Why Pay = I-candidates (disruption cost) + S-candidates (capability gap cost)

**Section Proportions:**
- Hook: 8%
- Why Change: 25%
- Why Now: 20%
- Why You: 30%
- Why Pay: 17%
- **Target:** Variable (600-1200 words based on theme complexity)

**Contract:** `theme-thesis/arc-definition.md`

---

### 8. JTBD Portfolio

**Arc ID:** `jtbd-portfolio`
**Display Name:** JTBD Portfolio
**Elements:** Job Landscape → Friction Map → Portfolio Map → Invitation

**Best For:**
- Portfolio introductions (presenting a solution portfolio to new prospects)
- Capability overviews (executive briefings on what the company solves)
- Pre-sales positioning (framing the portfolio before deal-specific tailoring)
- B2B portfolio narratives organized by buyer jobs, not product features

**Description:**
A 5-stage B2B portfolio narrative structured around Jobs-to-be-Done. Organises a solution portfolio by the functional jobs the buyer hires solutions for, rather than by product features. Suitable for portfolio introductions, capability overviews, and pre-sales positioning.

**Detection Signals:**
- `content_type: "jtbd"`
- Keywords (>=12% density): "jobs-to-be-done", "functional job", "jtbd", "job landscape", "hire", "portfolio map", "capability overview", "pre-sales positioning"

**JTBD-Specific Constraints:**
- Jobs must be verb phrases, not product category names
- Strict 1:1 job-to-solution mapping; orphaned solutions flagged
- No feature lists -- IS/DOES/MEANS only per solution
- Invitation stage explicitly signals cogni-sales handoff

**Section Proportions:**
- Hook (Context Setter): 10%
- Job Landscape: 24%
- Friction Map: 21%
- Portfolio Map: 27%
- Invitation: 18%
- **Default total:** 1,675 words (customizable via `--target-length`)

**Contract:** `jtbd-portfolio/arc-definition.md`

---

### 9. Company Credo

**Arc ID:** `company-credo`
**Display Name:** Company Credo
**Elements:** Mission → Conviction → Credibility → Promise

**Best For:**
- Website "About Us" pages (primary use)
- Company introductions at the start of proposals and sales decks
- Investor and partner relationship pages where the buyer is choosing the company before any specific offering
- Brand identity documents that need to read as a narrative, not a brochure

**Description:**
A 4-element B2B narrative that answers the buyer's first unasked question: "Why does this company exist, and why should I believe it?" Mission states the belief that drives the company; Conviction names 3–4 non-negotiable judgment calls; Credibility provides the receipts; Promise closes with a forward commitment in You-voice.

**Detection Signals:**
- `content_type: "company-credo"` or `"about-us"`
- Keywords (>=12% density): "about us", "our mission", "why we exist", "what we believe", "our story", "company values", "our credo", "who we are", "why us"

**Company-Credo-Specific Constraints:**
- Mission must be first-person plural ("we")
- Each Conviction must pass the disagreement test (a named competitor could plausibly disagree)
- Each Conviction must pair belief with buyer-visible consequence
- Every quantitative Credibility claim must be cited
- Named customers in Credibility only with explicit `disclosure_permission: true`
- Promise MUST NOT commit to anything in `announce`-mode products
- Every Promise item must use You-Phrasing
- Final invitation is a single link, not a menu

**Section Proportions:**
- Hook (Founding lens): 10%
- Mission: 24%
- Conviction: 22%
- Credibility: 26%
- Promise: 18%
- **Default total:** 1,400 words (customizable via `--target-length`)

**Contract:** `company-credo/arc-definition.md`

---

### 10. Engagement Model

**Arc ID:** `engagement-model`
**Display Name:** Engagement Model
**Elements:** Principles → Process → Partnership → Outcomes

**Best For:**
- Website "How We Work" / "Our Approach" pages (primary use)
- The engagement-model section of proposals (explaining how the work will land, not what will be delivered)
- Partner onboarding pages
- Internal documentation for new hires explaining company defaults

**Description:**
A 4-element B2B narrative that answers "how will this work land in my organization?" Principles name 3–4 operating disciplines; Process walks the canonical 4–6 phases with artifacts and time bands; Partnership names what the buyer must bring; Outcomes summarizes cross-cutting results the buyer can observe.

**Detection Signals:**
- `content_type: "engagement-model"` or `"how-we-work"`
- Keywords (>=12% density): "how we work", "engagement model", "working with us", "our process", "delivery model", "partnership", "our approach", "principles", "ways of working"

**Engagement-Model-Specific Constraints:**
- Every Principle must be operational (observable in week 1), not a value
- Every Process phase must name at least one artifact and one time band
- No Process phase may be specific to one solution (solution-specific phases belong on capability pages)
- Every Partnership expectation must name a concrete thing (a person, data source, approval, or timebox)
- Every Partnership expectation must state a consequence if missing
- Every Outcome must describe buyer-visible change, not company activity
- Every Outcome must be cross-cutting (true across most of the portfolio)
- Pricing, ROI numbers, and per-capability metrics are FORBIDDEN in this arc (they belong on capability pages or proposals)

**Section Proportions:**
- Hook (Working with us): 8%
- Principles: 22%
- Process: 28%
- Partnership: 20%
- Outcomes: 22%
- **Default total:** 1,400 words (customizable via `--target-length`)

**Contract:** `engagement-model/arc-definition.md`

---

### 11. Smarter Service

**Arc ID:** `smarter-service`
**Display Name:** Smarter Service
**Elements:** Forces → Impact → Horizons → Foundations (TIPS: T → I → P → S, theme-aware)

**Best For:**
- TIPS trend reports built on top of a value model with investment themes (primary)
- CxO-level reports where investment themes need a coherent macro spine
- Strategic foresight briefings with cross-dimensional theme anchoring
- Multi-theme transformation roadmaps grounded in dimensional forces

**Description:**
A theme-aware sibling of `trend-panorama`. Same four elements and same TIPS dimension mapping, but each macro element doubles as an H2 section that nests one or more investment-theme cases (H3) anchored to that dimension. The arc adds a Foundations-anchored synthesis section ("The Capability Imperative") that aggregates capability requirements across themes. Selected over `trend-panorama` whenever `tips-value-model.json` is present in the project.

**Detection Signals:**
- Structural (highest confidence): `tips-value-model.json` present in source directory or `.metadata/`
- `content_type: "smarter-service"` or `"investment-theme-report"`
- `research_type: "smarter-service-themed"`
- Keywords (≥12% density): "investment theme", "Handlungsfeld", "value chain", "solution template", "Smarter Service", "Trendradar"

**Smarter-Service-Specific Constraints:**
- Each investment theme appears exactly once in main flow — anchored to its dominant TIPS pole, not duplicated across elements
- Anchoring rule deterministic: dominant `candidate_ref` count, tiebreaker = highest single-candidate composite score
- Secondary poles get one-line callouts, not full sub-sections
- Theme-cases must NOT restate macro Forces/Impact/Horizons/Foundations context — that lives in dimension narratives once
- Synthesis section "The Capability Imperative" is required in theme-aware mode and aggregates across themes (not per-theme summary)

**TIPS Candidate Mapping:**
- Forces (T): Externe Effekte — economy, regulation, society
- Impact (I): Digitale Wertetreiber — CX, products, processes
- Horizons (P): Neue Horizonte — strategy, leadership, governance
- Foundations (S): Digitales Fundament — culture, workforce, technology
- Theme anchoring: each theme's dominant pole determines the macro section it nests under

**Section Proportions (theme-aware mode, with N themes):**
- Executive Summary: 10%
- Forces (dimension narrative + nested theme-cases): 22%
- Impact (dimension narrative + nested theme-cases): 22%
- Horizons (dimension narrative + nested theme-cases): 22%
- Foundations (dimension narrative + nested theme-cases): 16%
- Synthesis ("The Capability Imperative"): 8%
- **Default total:** scales with cogni-trends length tiers (4,000–8,000 prose words)

**Section Proportions (insight-summary fallback, no themes):**
- Hook: 10% / Forces: 24% / Impact: 24% / Horizons: 24% / Foundations: 18%
- Default total: 1,675 words (degrades to trend-panorama-equivalent structure)

**Contract:** `smarter-service/arc-definition.md`

---

## Arc Detection Algorithm

### Step 1: Explicit Selection

If the caller provides `arc_id` directly, use it without detection.

### Step 2: Structural Detection (trend-panorama / smarter-service)

Before content-type mapping, check for structural signals that uniquely identify TIPS reports. The presence of `tips-value-model.json` is the deciding signal between the theme-less (`trend-panorama`) and theme-aware (`smarter-service`) variants.

```javascript
// Step 2a: theme-aware TIPS report — value model present means themes exist
if (fileExists("tips-value-model.json") || fileExists(".metadata/tips-value-model.json")) {
  detected_arc = "smarter-service"
  detection_reason = "structural: tips-value-model.json detected (theme-aware TIPS report)"
}

// Step 2b: theme-less TIPS panorama — trend-scout output without a value model
else if (fileExists(".metadata/trend-scout-output.json") || fileExists("trend-scout-output.json")) {
  detected_arc = "trend-panorama"
  detection_reason = "structural: trend-scout-output.json detected (theme-less TIPS panorama)"
}
else if (fileExists("tips-trend-report.md")) {
  // Existing report with H2 investment-theme sections strongly implies value model;
  // fall back to trend-panorama only if value model was deleted post-generation.
  detected_arc = "trend-panorama"
  detection_reason = "structural: tips-trend-report.md detected (no value model — fallback)"
}
```

### Step 3: Content Type Mapping

```javascript
const arcMap = {
  "trend": "trend-panorama",
  "trends": "trend-panorama",
  "tips": "trend-panorama",
  "smarter-service": "smarter-service",
  "investment-theme-report": "smarter-service",
  "theme": "theme-thesis",
  "investment-theme": "theme-thesis",
  "technology": "technology-futures",
  "competitive": "competitive-intelligence",
  "foresight": "strategic-foresight",
  "scenarios": "strategic-foresight",
  "industry": "industry-transformation",
  "jtbd": "jtbd-portfolio",
  "company-credo": "company-credo",
  "about-us": "company-credo",
  "engagement-model": "engagement-model",
  "how-we-work": "engagement-model",
  "market": "corporate-visions",
  "generic": "corporate-visions"
}

// Also check research_type field — note: theme-aware variant takes precedence
// when a value model exists (Step 2 already handled the structural signal).
if (research_type === "smarter-service-themed") {
  detected_arc = "smarter-service"
  detection_reason = `research_type="smarter-service-themed"`
}
else if (research_type === "smarter-service") {
  detected_arc = "trend-panorama"
  detection_reason = `research_type="smarter-service" (theme-less)`
}

if (content_type in arcMap) {
  detected_arc = arcMap[content_type]
  detection_reason = `content_type="${content_type}"`
}
```

### Step 4: Content Analysis (if no content_type match)

Analyze the input content for keyword density:

```javascript
keyword_sets = {
  "trend-panorama": ["trend", "horizon", "act", "plan", "observe", "TIPS", "signal intensity", "dimension"],
  "smarter-service": ["investment theme", "Handlungsfeld", "value chain", "solution template", "Smarter Service", "Trendradar", "Externe Effekte", "Digitale Wertetreiber", "Neue Horizonte", "Digitales Fundament"],
  "theme-thesis": ["theme", "investment thesis", "value chain", "solution template", "strategic question", "candidate_ref", "chain_score"],
  "technology-futures": ["emerging", "innovation", "capability", "technology", "R&D", "breakthrough"],
  "competitive-intelligence": ["competitor", "market share", "positioning", "differentiation", "threat", "rivalry"],
  "strategic-foresight": ["scenario", "future", "signal", "uncertainty", "planning", "foresight"],
  "industry-transformation": ["regulatory", "sector", "structural", "industry", "transformation", "policy"],
  "jtbd-portfolio": ["jobs-to-be-done", "functional job", "jtbd", "job landscape", "hire", "portfolio map", "capability overview", "pre-sales positioning"],
  "company-credo": ["about us", "our mission", "why we exist", "what we believe", "our story", "company values", "our credo", "who we are", "why us"],
  "engagement-model": ["how we work", "engagement model", "working with us", "our process", "delivery model", "partnership", "our approach", "principles", "ways of working"]
}

thresholds = {
  "trend-panorama": 0.12,
  "smarter-service": 0.12,
  "theme-thesis": 0.15,
  "technology-futures": 0.15,
  "competitive-intelligence": 0.12,
  "strategic-foresight": 0.10,
  "industry-transformation": 0.12,
  "jtbd-portfolio": 0.12,
  "company-credo": 0.12,
  "engagement-model": 0.12
}
```

### Step 5: Fallback Default

```javascript
if (!detected_arc) {
  detected_arc = "corporate-visions"
  detection_reason = "default (no specific signals detected)"
}
```

## Arc Directory Structure

Each arc is one contract file:

```
story-arc/{arc-id}/
└── arc-definition.md          # v2 contract: Intent, Selection, Headings, Composition, Elements, Validation, See Also
```

A contract carries `contract: 2` in its frontmatter and the seven `##` sections in that order; `## Elements` holds exactly four `### N.` sections, each with Purpose, Evidence sought, Argument move, Techniques, Hard rules and Failure modes. `cogni-workspace/tests/test-arc-contract-shape.sh` enforces the shape for every arc directory it finds; its `UNMIGRATED` ratchet is empty and can only stay so — an arc directory carrying anything other than a `contract: 2` file turns the suite red.

## Interactive Selection Format

The confirmation is a **shortlist, not a menu**. The user has no basis to ratify a single detected arc, and the full registry is a catalogue rather than a recommendation, so Phase 2 presents the 2-3 arcs that would produce materially different but defensible narratives from this evidence and this decision purpose. Every candidate carries the same four facts, and exactly one is marked Recommended:

```
Detected: {arc_display_name} ({detection_reason})

Which arc should this narrative follow?

1. {Recommended arc} — Recommended: {one sentence keyed to the decision purpose}
   Elements: {element1} → {element2} → {element3} → {element4}
   Governing question: {from the arc's declarative block}
   Fit: {one reason this evidence suits this arc}

2. {Alternative arc}
   Elements: {element1} → {element2} → {element3} → {element4}
   Governing question: {…}
   Fit: {one reason — and what it would make of this evidence that the Recommended arc would not}

[3. {second alternative, only when defensible}]
```

Rules: 2-3 candidates, never padded to three when only two fit; when only one arc is defensible, say so and ask for confirmation of that one; the full arc list appears only when the user asks for it. Under `--interactive false` the top-ranked candidate is taken with its `detection_reason` recorded and no prompt is shown.

## Extension Guidelines

### Adding New Arcs

1. Choose a unique `arc_id` (lowercase, hyphens, descriptive)
2. Create `story-arc/{arc-id}/arc-definition.md` on the v2 contract shape — copy a migrated contract such as `corporate-visions/arc-definition.md` and replace every section
3. Add the arc to this registry (quick-reference table, detailed section, and detection algorithm: `content_type` mapping in Step 3, keyword set and threshold in Step 4, structural detection in Step 2 if the arc has a unique file signature)
4. Add the arc's EN/DE `##` headers to `language-templates.md` byte-equal to the contract's `## Headings`
5. Add a column to the application matrix in `narrative-techniques/techniques-overview.md`
6. Add a mapping row and an element block to `cogni-workspace/libraries/arc-taxonomy.md` (short names are the pre-colon segments of the contract's headings)
7. Run `bash cogni-workspace/tests/test-arc-contract-shape.sh` and `bash cogni-workspace/tests/test-arc-taxonomy-sync.sh` — both enumerate the arc directories at run time, so the new arc is checked with no test edit

### Quality Standards for New Arcs

**Structural:**
- Section proportions must sum to 100%. Default total: 1,675 words (customizable via `--target-length`)
- EXACTLY 4 elements (consistent with all arcs)
- Each element has distinct purpose (no overlap)
- Clear detection signals (content_type + keywords + optional structural)

**Content:**
- The contract's `## Elements` carries, per element, Purpose, Evidence sought (content-map keys, never a fixed directory layout), Argument move, Techniques (names linked to `techniques-overview.md`, never re-taught), Hard rules and Failure modes
- `## Validation` carries only assertions specific to the arc; every universal gate lives in `../validation.md`

**Localization:**
- German headings for all four elements, with real umlauts (no ASCII fallbacks anywhere in the contract)

**Cross-references:**
- Technique application matrix updated in `techniques-overview.md`
- Arc registry quick reference table and detailed section updated
- `cogni-workspace/libraries/arc-taxonomy.md` mapping row and element block added
