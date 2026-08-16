# Horizons: Strategic Possibilities — Patterns (smarter-service)

## Element Purpose

Synthesize P-dimension (Neue Horizonte) trends into a narrative of strategic possibilities — the openings that disruption creates. In theme-aware mode, the Horizons dimension narrative reframes "disruption" as "opportunity" once across the landscape; anchored theme-cases name specific bets within those windows.

**TIPS Dimension:** P — Possibilities (Neue Horizonte)
**Word target (theme-aware mode):** ~12.5% dimension narrative + nested theme-case budget.
**Word target (insight-summary mode):** 24% (same as trend-panorama).

Shared subcategory mechanics live in `../trend-panorama/horizons-patterns.md`.

## Source Content Mapping

- Trend entities with `dimension: "neue-horizonte"` from enrichment JSON
- P-section of `tips-trend-report.md` if available
- `tips-value-model.json` — themes anchored to Horizons; solution templates that address P-candidates

## Theme-Aware Horizons Pattern

### Macro Horizons narrative (dimension narrative)

The Horizons dimension narrative is the rhetorical pivot of the report — disruption becomes opportunity. It must:

1. **Open with an explicit Impact→Horizons bridge.** Pattern: *"The disruption mapped above does not stop at the value chain — it opens [N] strategic windows. The question shifts from 'how to defend' to 'where to position.'"*
2. **Cluster opportunities by subcategory** (strategy / leadership / governance) and quantify the windows (deadlines, first-mover months, competitive lead time).
3. **Cascade by horizon** — Act opportunities (seize now, smaller windows), Plan opportunities (build toward, larger payoff), Observe opportunities (position for, optionality).
4. **End with anchor pivot** — name themes anchored to Horizons and the strategic position each represents.

### Anchored theme-cases (H3, slim 3-beat)

Theme-cases anchored to Horizons emphasize strategic positioning. The Move beat names the specific market/operating-model bet; the Cost-of-Inaction beat quantifies the closing window.

**Cost-of-Inaction pattern (theme-case close, ~120 words at extended tier):**
```markdown
The 3-year cost of inaction on this theme compounds across [number] dimensions. [Cost dimension 1: regulatory or contract loss — €X over T years]. [Cost dimension 2: talent premium or churn — €Y]. [Cost dimension 3: opportunity cost from delayed positioning — €Z].

Proactive investment: €[A] M over [N] months. Cost of inaction: €[B] M over three years. The ratio is [B/A]x — and the window closes [date or event].
```

The ratio is the rhetorical close. Generic ratios ("acting costs less than waiting") fail the gate; the ratio must be a specific number with a specific window.

## Insight-Summary Horizons Pattern (theme-less fallback)

See `../trend-panorama/horizons-patterns.md` for the theme-less Act/Plan/Observe word breakdown.

## Subcategory Coverage

- **Strategy (strategie)**: market positioning, business-model pivots, M&A windows
- **Leadership (fuehrung)**: executive accountability shifts, decision rights, talent strategy
- **Governance (steuerung)**: board oversight, risk frameworks, ESG governance

Cover at least 2 in the dimension narrative.

## Citation Requirements

**Theme-aware mode:** 4–6 citations in dimension narrative; theme-cases cite their own opportunity sizing and ratios.

**Insight-summary mode:** 4–6 citations (same as trend-panorama Horizons).

## Quality Gates

- [ ] Impact→Horizons bridge present in dimension narrative opening
- [ ] Each anchored theme-case Cost-of-Inaction closes with a specific ratio (e.g., "3.4x") tied to a specific window (date or event)
- [ ] Opportunity windows quantified (months, market share, contract size)
- [ ] No theme-case omits the ratio; "cost of inaction is high" is insufficient

## Common Pitfalls

✗ **Generic opportunity language.** "Organizations should leverage AI." with no window, no positioning specifics.
✓ **Specific opportunity windows.** "An 18-month window before autonomous baggage handling reaches mainstream creates first-mover advantage worth 40% operational cost reduction for early adopters."

✗ **Cost-of-Inaction ratio without a window.** "Inaction costs 3x more than action."
✓ **Ratio anchored to a window.** "3.4x over three years; the window closes at the EU AI Act enforcement deadline (August 2026)."

## See Also

- `arc-definition.md` — Smarter Service arc metadata
- `../trend-panorama/horizons-patterns.md` — Shared subcategory and cascade mechanics
- `cogni-trends/skills/trend-report/references/phase-2-strategic-themes.md` — Cost-of-Inaction calculation conventions
