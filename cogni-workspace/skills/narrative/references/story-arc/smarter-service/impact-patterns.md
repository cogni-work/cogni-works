# Impact: Value Chain Disruption — Patterns (smarter-service)

## Element Purpose

Synthesize I-dimension (Digitale Wertetreiber) trends into a narrative of how external forces translate into measurable disruption inside the value chain. In theme-aware mode, the Impact dimension narrative shows the cascade Forces→Impact once; anchored theme-cases describe specific bets that ride or defend against that disruption.

**TIPS Dimension:** I — Implications (Digitale Wertetreiber)
**Word target (theme-aware mode):** ~12.5% dimension narrative + nested theme-case budget.
**Word target (insight-summary mode):** 24% (same as trend-panorama).

Shared subcategory mechanics live in `../trend-panorama/impact-patterns.md`. This file documents only what's specific to smarter-service.

## Source Content Mapping

Same as trend-panorama plus theme awareness:

- Trend entities with `dimension: "digitale-wertetreiber"` from enrichment JSON
- I-section of `tips-trend-report.md` if available
- `tips-value-model.json` — identify themes whose dominant pole is `digitale-wertetreiber`

**Theme-aware additions:** for each anchored theme, identify which I-candidates the theme references. These become the bridge points from dimension narrative to theme-case.

## Theme-Aware Impact Pattern

### Macro Impact narrative (dimension narrative)

The dimension narrative shows how the Forces translate into value-chain disruption *across* themes. It must:

1. **Open with an explicit Forces→Impact bridge** — one sentence referencing the dimension narrative above. Pattern: *"The regulatory and economic forces established above translate into measurable disruption across [N] value-chain segments."*
2. **Cluster disruptions by subcategory** (customer experience / products & services / business processes) with the cascade between them visible (CX changes drive product evolution which forces process redesign).
3. **Cascade by horizon** — Act disruptions (already happening), Plan disruptions (emerging), Observe disruptions (potential).
4. **End with anchor pivot** — name the themes anchored to Impact and what value-chain shift each addresses, in one sentence.

### Anchored theme-cases (H3, slim 3-beat micro-arc)

Theme-cases anchored to Impact follow the same Stake / Move / Cost-of-Inaction structure as Forces theme-cases. The Move beat is the load-bearing one for Impact — it's where the theme's specific value-chain bet is described, drawing on solution templates and the theme's I-candidates.

**Move pattern (theme-case middle, ~250 words at extended tier):**
```markdown
[Solution Template 1: IS — what it is]. [Solution Template 1: DOES — quantified outcome from P-candidates]. [Solution Template 1: MEANS — durable advantage from S-candidates].

[Bridge sentence to Solution Template 2 if multiple templates]. [Solution Template 2: IS / DOES / MEANS].

[Closing sentence: how this Move captures the disruption named in the macro Impact narrative.]
```

The Move beat is flowing prose — no IS/DOES/MEANS labels visible in the output. Solution-template citations live here.

## Insight-Summary Impact Pattern (theme-less fallback)

See `../trend-panorama/impact-patterns.md` for full word breakdown and example prose. The Forces→Impact bridge requirement applies in both modes.

## Subcategory Coverage

Same as trend-panorama:

- **Customer Experience (customer-experience)**: friction reduction, personalization, service models
- **Products & Services (produkte-services)**: smart products, servitization, outcome pricing
- **Business Processes (geschaeftsprozesse)**: automation, decision intelligence, supply-chain orchestration

Aim for 2 of 3 in the dimension narrative; the remaining one in a theme-case.

## Citation Requirements

**Theme-aware mode:** 4–6 citations in the dimension narrative; theme-cases own their solution-template citations.

**Insight-summary mode:** 4–7 citations (same as trend-panorama Impact).

## Quality Gates

- [ ] Forces→Impact bridge present in the first paragraph of dimension narrative
- [ ] Subcategory coverage: at least 2 of 3 (CX, products, processes)
- [ ] Horizon cascade present (Act → Plan → Observe)
- [ ] Anchored theme-cases use Move beat as primary content; solution templates cited
- [ ] No theme-case re-establishes the macro disruption narrative

## Common Pitfalls

✗ **Move beat restates the macro disruption.** The theme-case spends 80 words explaining the value-chain shift before getting to its solution templates.
✓ **Move beat opens with the bet, not the context.** The macro narrative already established the disruption; the Move beat names what to do about it.

✗ **Solution-template name-dropping without IS/DOES/MEANS substance.** "Theme A includes solution template X." with no quantified DOES.
✓ **Solution templates carry their full IS/DOES/MEANS in the Move beat.** Quantified outcome (DOES) and durable advantage (MEANS) are non-negotiable.

## See Also

- `arc-definition.md` — Smarter Service arc metadata
- `../trend-panorama/impact-patterns.md` — Shared subcategory and cascade mechanics
- `cogni-trends/references/data-model.md` — Solution template schema
