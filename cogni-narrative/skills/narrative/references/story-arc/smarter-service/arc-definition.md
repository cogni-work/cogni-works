# Smarter Service Story Arc

## Arc Metadata

**Arc ID:** `smarter-service`
**Display Name:** Smarter Service
**Display Name (German):** Smarter Service

**Elements (Ordered):**
1. Forces: External Pressures & Market Signals
2. Impact: Value Chain Disruption
3. Horizons: Strategic Possibilities
4. Foundations: Capability Requirements

**Elements (German):**
1. Kräfte: Externe Einflüsse & Marktsignale
2. Wirkung: Wertschöpfungsdynamik
3. Horizonte: Strategische Möglichkeiten
4. Fundamente: Kompetenzanforderungen

## Why This Arc Exists (vs. trend-panorama)

`smarter-service` and `trend-panorama` share the same four elements and the same TIPS dimension mapping. They differ in **what they wrap**:

- **`trend-panorama`** is a *theme-less* arc — it summarizes a trend landscape (e.g., 52 trend-scout candidates) into a single flowing narrative. Best for insight summaries, executive trend briefings without a value-model.
- **`smarter-service`** is a *theme-aware* arc — each macro element doubles as an H2 section that nests one or more investment-theme cases (H3) anchored to that dimension. Best for CxO trend reports built on top of a `tips-value-model.json`.

Choosing between them: if `tips-value-model.json` exists in the project, prefer `smarter-service`. If only `trend-scout-output.json` exists, use `trend-panorama`.

The arc is named after the **Smarter Service Trendradar** (Steimel, 2023) — the four-dimension foresight framework that structures the entire cogni-trends plugin. The arc makes the framework load-bearing in the narrative, not just in the research.

## TIPS Dimension Mapping

| Element | TIPS Letter | Dimension Slug | Dimension Name (EN) | Dimension Name (DE) |
|---------|-------------|----------------|---------------------|---------------------|
| Forces | **T** | `externe-effekte` | External Effects | Externe Effekte |
| Impact | **I** | `digitale-wertetreiber` | Digital Value Drivers | Digitale Wertetreiber |
| Horizons | **P** | `neue-horizonte` | New Horizons | Neue Horizonte |
| Foundations | **S** | `digitales-fundament` | Digital Foundation | Digitales Fundament |

### Theme Anchoring (the theme-aware twist)

Each investment theme from `tips-value-model.json` is anchored to **one macro element** (the dimension where the theme's evidence is strongest), not duplicated across elements. The deterministic anchoring rule is enforced by the consuming skill (cogni-trends/trend-report):

1. **Anchor pole** = TIPS dimension with the highest count of `candidate_ref` entries for that theme in the value model.
2. **Tiebreaker** = highest single-candidate composite score.
3. **Secondary poles** = one-line callouts in the relevant other macro sections (e.g., "→ See also Theme 2 in Foundations for the talent dependency"), not duplicate sub-sections.

This guarantees each theme appears exactly once in the report's main flow, and the macro arc (Forces → Impact → Horizons → Foundations) carries through cleanly.

### Horizon Cascade (Within Each Element)

Same as trend-panorama. Each element synthesizes trends across three planning horizons:

| Horizon | Timeframe | Signal Intensity | Narrative Role |
|---------|-----------|-----------------|----------------|
| **Act** | 0–2 years | Levels 4–5 | Lead with urgency — what demands immediate response |
| **Plan** | 2–5 years | Levels 2–4 | Bridge to preparation — what to build capability for |
| **Observe** | 5+ years | Levels 1–2 | Close with foresight — what weak signals to monitor |

## Word Proportions

Smarter Service is normally consumed at trend-report scale (4,000–8,000 words across length tiers), not at insight-summary scale. The arc therefore exposes two proportion sets:

### A. Theme-aware (default for cogni-trends/trend-report)

When the consuming skill nests theme-cases under each macro section:

| Section | Proportion | Notes |
|---------|-----------|-------|
| Executive Summary | 10% | Cross-dimensional macro panorama |
| Forces (incl. anchored theme-cases) | 22% | Dimension narrative ~12.5% + nested theme-cases share remaining 9.5% |
| Impact (incl. anchored theme-cases) | 22% | Same split |
| Horizons (incl. anchored theme-cases) | 22% | Same split |
| Foundations (incl. anchored theme-cases) | 16% | Slightly smaller; foundations carry less theme weight |
| Synthesis ("The Capability Imperative") | 8% | Cross-theme close on Foundations |

Per-dimension narrative floor: 250 words. Per theme-case floor: 290 words (Stake 80 / Move 130 / Cost-of-Inaction 80, soft minimums). Length tiers (standard/extended/comprehensive/maximum) scale these targets — see `cogni-trends/skills/trend-report/references/report-length-tiers.md`.

### B. Insight-summary (fallback for theme-less use)

When `tips-value-model.json` is absent and the arc is consumed as an insight summary:

| Element | Proportion | Default Range (T=1675) |
|---------|-----------|------------------------|
| Hook | 10% | 143–193 |
| Forces | 24% | 342–462 |
| Impact | 24% | 342–462 |
| Horizons | 24% | 342–462 |
| Foundations | 18% | 256–347 |

This degrades to trend-panorama-equivalent structure — the arc remains valid even without themes.

## Detection Configuration

### Research Type Mapping

Selected when:
- `research_type: "smarter-service-themed"` (explicit signal that themes are present)
- `content_type: "smarter-service"` or `"investment-theme-report"`
- `synthesis_format: "TIPS-themed"` in source metadata

### Structural Detection (highest confidence)

Strongest auto-detection signal — triggers `smarter-service` over `trend-panorama`:

- Presence of `tips-value-model.json` in source directory or `.metadata/`
- Presence of `tips-trend-report.md` with H2 investment-theme sections
- YAML frontmatter with `arc_id: "smarter-service"` (explicit override)

If only `trend-scout-output.json` exists (no value model), fall back to `trend-panorama`.

### Content Analysis Keywords

Threshold: ≥12% keyword density.

**Keywords:** "investment theme", "Handlungsfeld", "value chain", "solution template", "strategic question", "Smarter Service", "Trendradar", "Externe Effekte", "Digitale Wertetreiber", "Neue Horizonte", "Digitales Fundament"

### Use Cases

**Best For:**
- CxO-level TIPS trend reports with investment themes (primary)
- Strategic foresight briefings where investment bets cluster across dimensions
- Multi-theme transformation roadmaps anchored in dimension forces
- Board-level reports where themes need a coherent macro spine

**Typical Research Types:**
- Smarter Service trend scouting + value modeling pipeline
- TIPS-formatted trend analysis with strategic theme synthesis
- Capability roadmaps grounded in dimensional forces

## Element Definitions

### Element 1: Forces (External Pressures & Market Signals)

**Purpose:**
Synthesize the T-dimension (Externe Effekte) into a narrative of external forces that reshape the operating landscape *across* themes. The dimension narrative establishes the macro Forces story; anchored theme-cases (when present) localize that story to specific strategic bets.

**TIPS Dimension:** T — Trends (Externe Effekte)
**Subcategories:** wirtschaft (Economy), regulierung (Regulation), gesellschaft (Society)

**Source Content:**
- All trend entities with `dimension: "externe-effekte"` from `trend-scout-output.json` or enrichment JSON
- T-section of `tips-trend-report.md` if available
- Cross-dimensional executive summary
- Theme value chains anchored to Forces (when present)

**Transformation Approach:**
1. **Establish the macro force narrative first.** What three or four external forces dominate this landscape? Group by subcategory, lead with the highest-confidence Act-horizon force.
2. **Anchor theme-cases (when themes exist).** Briefly introduce each anchored theme-case as a *localized response* to the macro forces — but defer the persuasion (Why-* style) to the theme-case body, which is written separately.
3. **Show force interactions.** Where does economic pressure amplify regulatory urgency? Where does societal expectation drag faster than regulation?

**Key Techniques:**
- PSB (Problem/Solution/Benefit) for reframing forces as unconsidered needs
- Forcing Functions for Act-horizon regulatory or market deadlines
- Contrast Structure for tensions between subcategory forces
- Number Plays for trend scores, signal intensities, and quantitative evidence

**Pattern Reference:** `forces-patterns.md`

---

### Element 2: Impact (Value Chain Disruption)

**Purpose:**
Synthesize the I-dimension (Digitale Wertetreiber) into a narrative of how external forces translate into measurable disruption inside the value chain. The dimension narrative shows the cascade Forces→Impact; anchored theme-cases show how specific strategic bets either ride the disruption or defend against it.

**TIPS Dimension:** I — Implications (Digitale Wertetreiber)
**Subcategories:** customer-experience, produkte-services (Products & Services), geschaeftsprozesse (Business Processes)

**Source Content:**
- All trend entities with `dimension: "digitale-wertetreiber"`
- I-section of `tips-trend-report.md` if available
- Theme value chains anchored to Impact (when present)

**Transformation Approach:**
1. **Map force-to-impact chain.** Connect Forces element insights to value-chain disruption — make the causal chain explicit, not implied.
2. **Cascade by horizon.** Act impacts (disruption already underway), Plan impacts (emerging value shifts), Observe impacts (potential future disruptions).
3. **Anchor theme-cases (when themes exist).** Each anchored theme-case becomes a value-chain investment story — "this theme captures the Impact we just established."

**Key Techniques:**
- Contrast Structure for before/after value-chain comparisons
- Compound Impact for stacking disruption across CX/products/processes
- Number Plays for quantified value-chain metrics
- Forcing Functions for Act-horizon disruptions demanding immediate response

**Pattern Reference:** `impact-patterns.md`

---

### Element 3: Horizons (Strategic Possibilities)

**Purpose:**
Synthesize the P-dimension (Neue Horizonte) into a narrative of strategic possibilities — the openings that disruption creates. The dimension narrative reframes "disruption" as "opportunity"; anchored theme-cases (when present) name specific strategic bets within those windows.

**TIPS Dimension:** P — Possibilities (Neue Horizonte)
**Subcategories:** strategie (Strategy), fuehrung (Leadership), steuerung (Governance)

**Source Content:**
- All trend entities with `dimension: "neue-horizonte"`
- P-section of `tips-trend-report.md` if available
- Theme value chains anchored to Horizons (when present)

**Transformation Approach:**
1. **Connect impact-to-opportunity.** Show how the value-chain disruption (Element 2) creates strategic openings — first-mover windows, defensive moats, business-model pivots.
2. **Cascade by horizon.** Act opportunities (seize now), Plan opportunities (build toward), Observe opportunities (position for).
3. **Anchor theme-cases (when themes exist).** Each anchored theme-case becomes a strategic-bet story — "this theme captures the Horizon opportunity we just established."

**Key Techniques:**
- You-Phrasing for direct reader engagement with opportunities
- IS-DOES-MEANS for articulating strategic positions
- Number Plays for opportunity sizing and timing
- Contrast Structure for conventional vs. emerging strategic approaches

**Pattern Reference:** `horizons-patterns.md`

---

### Element 4: Foundations (Capability Requirements)

**Purpose:**
Synthesize the S-dimension (Digitales Fundament) into a narrative of required capabilities — the foundations without which the Horizons remain theoretical. The dimension narrative shows the capability roadmap; anchored theme-cases (when present) name specific capability bets and their dependency order.

**TIPS Dimension:** S — Solutions (Digitales Fundament)
**Subcategories:** kultur (Culture), mitarbeitende (Workforce), technologie (Technology)

**Source Content:**
- All trend entities with `dimension: "digitales-fundament"`
- S-section of `tips-trend-report.md` if available
- Solution templates from `tips-value-model.json` (when themes exist)
- Theme value chains anchored to Foundations (when present)

**Transformation Approach:**
1. **Connect opportunities-to-requirements.** Which capabilities enable the Horizons of Element 3? Which are shared foundations vs. theme-specific?
2. **Sequence dependencies.** Culture enables workforce, workforce enables technology — show the build order, don't list capabilities as a flat menu.
3. **Anchor theme-cases (when themes exist).** Each anchored theme-case becomes a capability investment story.

**Key Techniques:**
- IS-DOES-MEANS for defining each capability requirement
- Compound Impact for cost of capability gaps (stacked across culture, workforce, tech)
- Forcing Functions for capability deadlines driven by Act-horizon requirements
- You-Phrasing for actionable capability building recommendations

**Pattern Reference:** `foundations-patterns.md`

## Narrative Flow

### Hook Construction

Open with a cross-dimensional insight that reveals the SCALE and URGENCY of the trend landscape, then signal that themes follow in nested form.

**Pattern:**
```markdown
[Industry/sector] faces [number] converging forces across [N] Smarter Service dimensions—from [T-dimension insight] through [I-dimension insight] to [P-dimension insight], demanding [S-dimension implication]. [Quantified urgency from Act-horizon trends]. [Number] strategic investment themes anchor in these dimensions; together they define a [time-window] decision.
```

### Element Transitions

**Hook → Forces:** "The trend landscape begins with external forces reshaping [industry/sector]."

**Forces → Impact:** "These external forces translate into measurable disruption across the value chain."

**Impact → Horizons:** "Disruption creates openings. The strategic question shifts from 'how to defend' to 'where to position.'"

**Horizons → Foundations:** "Capturing these opportunities requires specific capabilities across culture, workforce, and technology."

In theme-aware reports the bridges between H2 macro sections still carry the arc; theme-cases nested within sections do **not** receive bridge paragraphs (they're scoped to their macro element by design).

### Closing Pattern

The synthesis section ("The Capability Imperative" / "Der Fähigkeitsimperativ") closes by aggregating capability requirements across themes. It is intentionally Foundations-anchored — the arc's rhetorical move is "trends without foundations are strategic theatre."

**Closing examples:**
- "Identifying trends is necessary but insufficient. These [N] investment themes share [M] foundation requirements. Without them, opportunities remain theoretical."
- "The trend panorama shows what's changing; the investment themes show where to bet; the capability imperative shows what to build first."

## Citation Requirements

### Citation Density

**Theme-aware mode:** Lower per-dimension density (theme-cases carry their own citations). Target: 4–6 citations per dimension narrative; theme-cases follow their micro-arc citation rules separately.

**Insight-summary mode:** Same as trend-panorama — 15–25 total citations.

### Citation Format

```markdown
Claim text<sup>[N](source-file.md)</sup>
```

**Required Citations:**
- Every Act-horizon trend claim (MUST)
- Every quantitative claim with a number, percent, or deadline (MUST)
- Cross-dimensional pattern claims (Should have)

## Quality Gates

### Arc Completeness

- [ ] All 4 elements present (Forces, Impact, Horizons, Foundations)
- [ ] Hook present (within hook proportion of target)
- [ ] Word counts within computed proportional ranges (±10% tolerance)
- [ ] Smooth transitions between macro elements
- [ ] Each element maps to exactly one TIPS dimension

### TIPS Framework Adherence

- [ ] **Forces** covers Externe Effekte dimension
- [ ] **Impact** covers Digitale Wertetreiber dimension
- [ ] **Horizons** covers Neue Horizonte dimension
- [ ] **Foundations** covers Digitales Fundament dimension

### Theme-Aware Discipline (theme-aware mode only)

- [ ] Each investment theme appears exactly once in main flow (no duplication across macro sections)
- [ ] Anchoring is deterministic (dominant `candidate_ref` pole + composite-score tiebreaker)
- [ ] Secondary poles use one-line callouts, not full sub-sections
- [ ] Theme-cases do **not** restate macro Forces/Impact/Horizons/Foundations context — that lives in dimension narratives once

### Horizon Cascade Applied

- [ ] Each dimension narrative contains Act → Plan → Observe progression
- [ ] Act-horizon evidence leads with urgency (immediate actions)
- [ ] Plan-horizon evidence bridges to preparation (capability building)
- [ ] Observe-horizon evidence closes with foresight (weak signals to monitor)

### Narrative Coherence

- [ ] Hook showcases the panoramic cross-dimensional landscape
- [ ] Forces establishes external pressures that drive remaining elements
- [ ] Impact shows how forces translate to value-chain disruption
- [ ] Horizons reframes disruption as strategic opportunity
- [ ] Foundations specifies capabilities needed to capture opportunities
- [ ] Synthesis aggregates on Foundations (the capability imperative)

## Common Pitfalls

### Theme-aware Pitfalls (specific to this arc)

✗ **Macro-context restatement in theme-cases:** Each theme repeating the Forces story.
✓ **Macro context lives once.** Themes reference the dimension narrative ("As Forces established for the regulatory landscape...") and pivot to theme specifics.

✗ **Cross-dimensional theme duplication:** Same theme appearing in two macro sections because it spans two dimensions.
✓ **Anchor + callout.** Each theme appears in exactly one macro section; secondary dimensions get a one-line callout.

✗ **Bridges between theme-cases inside a macro section:** Treating nested theme-cases like sequenced H2s.
✓ **No nested bridges.** Theme-cases under one macro element are siblings, not a sequence; the macro element's framing is the connective tissue.

### Generic Pitfalls (shared with trend-panorama)

See `../trend-panorama/arc-definition.md#common-pitfalls` for trend-listing, force/impact blur, vague capability recommendations, and missing horizon cascade — these apply equally here.

## Language Variations

### German Adjustments

**TIPS terminology:** Keep "TIPS" English. Translate dimension names: "Externe Effekte", "Digitale Wertetreiber", "Neue Horizonte", "Digitales Fundament". Keep horizon labels English: "Act", "Plan", "Observe".

**Synthesis heading:** "The Capability Imperative" → "Der Fähigkeitsimperativ".

**Element headings:**
- "Kräfte: Externe Einflüsse & Marktsignale"
- "Wirkung: Wertschöpfungsdynamik"
- "Horizonte: Strategische Möglichkeiten"
- "Fundamente: Kompetenzanforderungen"

**Number formatting:** German decimal comma ("3,2x"), German thousand separator ("2.400 Stunden"), quarter format unchanged ("Q2 2026").

## Version History

- **v1.0.0:** Initial Smarter Service arc — theme-aware sibling of `trend-panorama`. Adds investment-theme nesting under macro elements, deterministic anchoring rule, and a Foundations-anchored synthesis ("The Capability Imperative").

## See Also

- `../arc-registry.md` — Master index of all story arcs
- `../trend-panorama/arc-definition.md` — Theme-less sibling arc with shared element vocabulary
- `forces-patterns.md` — External pressure synthesis patterns (T-dimension)
- `impact-patterns.md` — Value chain disruption patterns (I-dimension)
- `horizons-patterns.md` — Strategic possibility patterns (P-dimension)
- `foundations-patterns.md` — Capability requirement patterns (S-dimension)
- `cogni-trends/skills/trend-report/references/phase-2-strategic-themes.md` — Theme-anchoring rule and slim 3-beat theme-case template (consumer-side)
