# Phase 4b: Arc-Specific Insight Summary (smarter-service)

**Arc Framework:** Forces → Impact → Horizons → Foundations (TIPS: T → I → P → S), theme-aware
**Arc:** `smarter-service` (Tier 4, theme-aware sibling of `trend-panorama`) | **Output:** `insight-summary.md` at project root (target range from `--target-length`, default ~1,675 words for theme-less fallback; theme-aware mode is normally consumed at trend-report scale by cogni-trends)

**Shared steps:** Read [shared-steps.md](shared-steps.md) for entity counting, output template, validation gates, and write instructions.

**Smarter-service additions to shared template:** Add `total_trends`, `horizon_distribution` (act/plan/observe counts), and `theme_count` to YAML frontmatter. If `theme_count > 0`, also add `themes[]` (each: `theme_id`, `name`, `anchor_dimension`).

---

## Mode Selection

This arc operates in two modes; the Phase 4b workflow follows the same first steps in both, then branches at Step 4.1.5.

| Signal | Mode | Behavior |
|--------|------|----------|
| `tips-value-model.json` exists | **Theme-aware** | Macro elements as H2; theme-cases nested as H3 (handled by consumer skill, e.g., cogni-trends/trend-report). cogni-narrative produces only the macro elements + synthesis section. |
| Only `trend-scout-output.json` exists | **Insight-summary fallback** | Single flowing narrative — degrades to trend-panorama-equivalent structure. |

When invoked from cogni-narrative directly without a value model, default to insight-summary fallback.

When invoked by cogni-trends/trend-report with a value model, the consumer owns the orchestration of theme-cases; cogni-narrative is only consulted for the arc definition and macro patterns.

---

## Arc-Specific Headers

**English:**
- `## Forces: External Pressures & Market Signals`
- `## Impact: Value Chain Disruption`
- `## Horizons: Strategic Possibilities`
- `## Foundations: Capability Requirements`
- `## The Capability Imperative` *(synthesis section — theme-aware mode only)*

**German (if `language: de`):**
- `## Kräfte: Externe Einflüsse & Marktsignale`
- `## Wirkung: Wertschöpfungsdynamik`
- `## Horizonte: Strategische Möglichkeiten`
- `## Fundamente: Kompetenzanforderungen`
- `## Der Fähigkeitsimperativ` *(synthesis — theme-aware mode only)*

---

## Step 4.1.1: Load Trend Evidence

Load priority:

1. `tips-value-model.json` from project root or `.metadata/` (if present, switch to theme-aware mode)
2. `trend-scout-output.json` from `.metadata/` or source directory (REQUIRED in either mode)
3. `tips-trend-report.md` from project directory (HIGH VALUE if present)
4. Dimension syntheses from `12-synthesis/data/` (theme-less mode only)
5. Top trend entities from `11-trends/data/` by dimension and horizon (up to 20)

After loading, build the **trend inventory** per dimension (count by horizon, top 3 by score, subcategory distribution, average confidence, key cross-trend themes) — same as trend-panorama.

In **theme-aware mode**, also build the **theme anchoring table**: for each theme in the value model, compute the anchor dimension (highest count of `candidate_ref` per dimension; tiebreak on highest single-candidate composite score). Record any secondary poles (dimensions where the theme has at least 1 candidate but did not win the anchor).

---

## Step 4.1.4: Extended Thinking Sub-steps

### Sub-step A: Build the Trend Inventory

Same as trend-panorama. The cross-dimensional spine identified here drives the hook.

### Sub-step B: Map Trend Clusters to Elements

Same as trend-panorama. In theme-aware mode, also note which themes anchor to each element — the dimension narrative will reference them in its anchor pivot sentence.

### Sub-step C: Generate the Title

Title must reflect the specific industry/topic, not "Smarter Service Trend Report". Patterns:

- "{Industry}: {Number} Themes for {Specific Strategic Move}"
- "{Sector} {Year}: Where Smarter Services Differentiate"
- "{Industry} Smarter Services: {Number} Bets, {Number} Foundations"

### Sub-step D: Write the Hook Paragraph

Hook accomplishes:
1. **Establish panoramic scale** — total trend count across dimensions
2. **Create urgency** — Act-horizon trend concentration
3. **Reveal cross-dimensional insight** — narrative spine
4. **Signal the macro arc** — Forces → Impact → Horizons → Foundations
5. **(Theme-aware mode only)** Hint at the investment themes that follow — without naming them. Pattern: "[N] strategic investment themes anchor in these dimensions; together they define a [time-window] decision."

### Sub-step E: Synthesize Each Arc Element

Branch by mode:

**Insight-summary mode:** follow trend-panorama's Sub-step E verbatim. Each element written as flowing prose with horizon cascade, no theme-cases.

**Theme-aware mode:** write each element's **dimension narrative** only (the consumer skill handles theme-case dispatch). Each dimension narrative:
1. Opens with the explicit cross-element bridge ("These external forces translate into..." / "Disruption creates openings..." / etc.)
2. Cascades by horizon (Act → Plan → Observe)
3. Synthesizes — does not list individual trends
4. Closes with an **anchor pivot sentence** naming the themes anchored to this element. Pattern: "[N] of the report's investment themes anchor here: [Theme A] responds to [specific force]; [Theme B] capitalizes on [specific opening]."

The anchor pivot sentence is the **only** place theme names appear in the dimension narrative. Theme content lives entirely in theme-cases (downstream).

### Sub-step E2 (theme-aware mode only): Write the Synthesis Section

After all four dimension narratives, write the **"Capability Imperative"** synthesis section (~8% of target). Structure documented in `../story-arc/smarter-service/foundations-patterns.md` ("Synthesis section: 'The Capability Imperative'").

Key requirements:
- Aggregates capability requirements across themes (does not summarize individual themes)
- Identifies *shared* foundations that unlock multiple themes ("invest once, unlock many")
- Closes with a unified capability roadmap (3–4 calendar-anchored bullets)
- Foundations-anchored — culture/workforce/technology dependency sequencing visible

### Sub-step F: Self-Review

1. **TIPS coherence:** Forces → Impact → Horizons → Foundations tells a connected story?
2. **Horizon cascade consistency:** Each dimension narrative follows Act → Plan → Observe?
3. **Synthesis quality:** Trends synthesized, not listed (same as trend-panorama).
4. **Theme discipline (theme-aware mode):**
   - Each theme appears exactly once in the dimension narratives' anchor pivots — no duplication
   - Anchor pivot sentences are ≤2 sentences each
   - Dimension narratives don't restate theme-case content
5. **Synthesis section (theme-aware mode):**
   - Aggregates across themes — does not re-summarize them
   - Closes with calendar-anchored capability roadmap
6. **Word count:** Within target ranges.

**Common failure modes:**
- **Theme-aware mode**: dimension narrative slips into theme-case writing (describing solution templates, citing P-candidates by name) — these belong in theme-cases, not dimension narratives.
- **Insight-summary mode**: same failure modes as trend-panorama (over-listing, force/impact blur, mechanical horizon cascade).

**Arc-specific validation additions** (beyond shared-steps.md gates):
- TIPS dimensions correctly mapped (T→Forces, I→Impact, P→Horizons, S→Foundations)
- Horizon cascade present in each dimension narrative
- Trend synthesis (not listing): ≤18 individually named trends in theme-less mode; ≤8 in theme-aware mode (themes carry the specifics)
- Frontmatter includes `total_trends`, `horizon_distribution`, and `theme_count`
- (Theme-aware mode) `themes[]` frontmatter array populated with anchoring metadata
- (Theme-aware mode) Each anchor pivot sentence references the named theme

Now proceed to validation and write steps in [shared-steps.md](shared-steps.md).
