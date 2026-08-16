# Foundations: Capability Requirements — Patterns (smarter-service)

## Element Purpose

Synthesize S-dimension (Digitales Fundament) trends into a narrative of required capabilities — without which the Horizons remain theoretical. In theme-aware mode, Foundations is also the **synthesis anchor**: the closing "Capability Imperative" section ties cross-theme capability requirements together and is rhetorically the report's strongest move.

**TIPS Dimension:** S — Solutions (Digitales Fundament)
**Word target (theme-aware mode):** ~12.5% dimension narrative + nested theme-case budget. Synthesis section adds another 8%.
**Word target (insight-summary mode):** 18% (same as trend-panorama).

Shared subcategory mechanics live in `../trend-panorama/foundations-patterns.md`.

## Source Content Mapping

- Trend entities with `dimension: "digitales-fundament"` from enrichment JSON
- S-section of `tips-trend-report.md` if available
- Solution templates from `tips-value-model.json` (capability-side)
- Themes anchored to Foundations

## Theme-Aware Foundations Pattern

### Macro Foundations narrative (dimension narrative)

The Foundations dimension narrative names the capabilities required to capture the Horizons. It must:

1. **Open with an explicit Horizons→Foundations bridge.** Pattern: *"The opportunities outlined above do not capture themselves. [N] capability requirements — across culture, workforce, and technology — define the build sequence."*
2. **Sequence dependencies, don't list capabilities.** Culture enables workforce, workforce enables technology. Show the build order; reverse order fails.
3. **Quantify readiness gaps** where evidence exists.
4. **End with anchor pivot** — name themes anchored to Foundations and the capability bet each makes.

### Anchored theme-cases (H3, slim 3-beat)

Foundations theme-cases name specific capability bets — talent programs, platform investments, cultural change initiatives. The Move beat names the bet; the Cost-of-Inaction quantifies the gap cost.

### Synthesis section: "The Capability Imperative" (special)

Smarter Service has a Foundations-anchored synthesis section. It is **not** a Foundations theme-case — it is the report's closing move, written separately by the orchestrator after all four macro sections are composed.

**Synthesis structure (~8% of total target):**

```markdown
## {SYNTHESIS_HEADING_SMARTER_SERVICE}    <!-- "The Capability Imperative" / "Der Fähigkeitsimperativ" -->

[Opening: 2 sentences — the synthesis frame. Pattern: "Identifying trends is necessary but insufficient. These [N] investment themes share [M] foundation requirements. Without them, opportunities remain theoretical."]

[Body: 200–350 words]

- Aggregate the strongest evidence across themes
- Identify shared foundations (culture, workforce, technology) that unlock multiple themes — invest once, unlock many
- Sequence the build order: culture → workforce → technology → outcome
- Combined cost of inaction across themes; combined proactive investment

### Unified Capability Roadmap

1. **{Calendar timeframe — e.g., "Q3 2026"}**: {Cross-theme action; names which themes it enables}
2. **{Calendar timeframe}**: {Cross-theme action}
3. **{Calendar timeframe}**: {Cross-theme action}
4. **{Calendar timeframe}**: {Cross-theme action}

[Closing: 1–2 sentences — the decisive close. Pattern: "The trend panorama shows what's changing; the investment themes show where to bet; the capability imperative shows what to build first."]
```

The synthesis section closes the report; no further themes follow.

## Insight-Summary Foundations Pattern (theme-less fallback)

See `../trend-panorama/foundations-patterns.md`. The synthesis section above is not produced in insight-summary mode — instead, the Foundations element closes with the urgency-to-action close (per trend-panorama).

## Subcategory Coverage

- **Culture (kultur)**: psychological safety for AI, decision-rights culture, learning culture
- **Workforce (mitarbeitende)**: reskilling at scale, AI fluency, hybrid work norms
- **Technology (technologie)**: data foundations, MLOps, security architecture

Cover all 3 in the dimension narrative — Foundations is where breadth matters most. The build sequence is the rhetorical move.

## Citation Requirements

**Theme-aware mode:** 3–5 citations in dimension narrative; synthesis section adds 2–3 (cross-theme aggregates).

**Insight-summary mode:** 3–5 citations (same as trend-panorama Foundations).

## Quality Gates

- [ ] Horizons→Foundations bridge present
- [ ] All 3 subcategories covered (culture, workforce, technology)
- [ ] Build sequence visible (culture → workforce → technology), not flat list
- [ ] Synthesis section "The Capability Imperative" present (theme-aware mode)
- [ ] Synthesis closes with unified capability roadmap (3–4 calendar-anchored bullets)

## Common Pitfalls

✗ **Capabilities listed as flat menu.** "Invest in culture, workforce, and technology."
✓ **Sequenced dependencies.** "Culture transformation enables workforce upskilling; workforce upskilling enables technology deployment. Reverse order fails — technology without trained operators produces 60% lower utilization."

✗ **Synthesis section repeats theme-case content.** Pulls in solution templates already named in earlier theme-cases.
✓ **Synthesis section aggregates across themes.** Names *shared* foundations (culture, workforce, tech) that unlock multiple themes — the "invest once, unlock many" move.

## See Also

- `arc-definition.md` — Smarter Service arc metadata
- `../trend-panorama/foundations-patterns.md` — Shared subcategory mechanics
- `cogni-trends/skills/trend-report/references/report-arc-frames.md` — Synthesis frame for smarter-service (consumer-side wrapper)
