# Forces: External Pressures & Market Signals — Patterns (smarter-service)

## Element Purpose

Synthesize T-dimension (Externe Effekte) trends into a narrative of converging external forces that *frame* the Smarter Service report. In theme-aware mode, the Forces dimension narrative establishes the macro story once; anchored theme-cases (H3) localize that story to specific strategic bets without repeating the macro framing.

**TIPS Dimension:** T — Trends (Externe Effekte)
**Word target (theme-aware mode):** ~12.5% of total target for the dimension narrative; remaining Forces budget split across nested theme-cases.
**Word target (insight-summary mode):** 24% of total target — same as trend-panorama.

This file documents the patterns that are **specific to smarter-service**. Shared mechanics (subcategory clustering, horizon cascade, citation density) are documented in `../trend-panorama/forces-patterns.md` and apply here too.

## Source Content Mapping

Same as trend-panorama: filter trend entities with `dimension: "externe-effekte"` from `trend-scout-output.json` or enrichment JSON; consult `tips-trend-report.md` T-section if available; cross-reference `tips-value-model.json` to identify which themes are anchored to Forces.

**Theme-aware additions:**
- Read `tips-value-model.json` to find investment themes whose dominant `candidate_ref` pole is `externe-effekte`. These themes will be nested under Forces as H3 cases.
- For each anchored theme, identify the specific T-candidates the theme cites — these become the bridge points from dimension narrative to theme-case.

## Theme-Aware Forces Pattern

### Macro Forces narrative (the dimension narrative — written by `trend-report-composer`)

The dimension narrative establishes the cross-theme Forces story. It must:

1. **Lead with the dominant external force across the entire landscape** — not just for one theme. Highest-confidence Act-horizon trend, ideally a regulatory deadline or quantified market shift.
2. **Cluster forces by subcategory** (economy / regulation / society) and show how they reinforce or counteract each other.
3. **Cascade by horizon** — Act forces lead, Plan forces bridge, Observe forces close (per-element ratio ~40/35/25 of words).
4. **End with a one-paragraph "anchor pivot"** that introduces the nested theme-cases without restating their content. Pattern: *"These external forces anchor [N] of the report's investment themes. [Theme A] responds to [specific force]; [Theme B] capitalizes on [specific force]."* This sentence is the only place where theme names appear in the dimension narrative.

### Anchored theme-cases (H3 — written by `trend-report-investment-theme-writer` in slim mode)

Theme-cases nested under Forces follow the slim 3-beat micro-arc — Stake / Move / Cost-of-Inaction — described in `cogni-trends/skills/trend-report/references/phase-2-strategic-themes.md`. The Stake beat is the only place where the theme references the macro Forces narrative; it uses one sentence to anchor and pivots immediately to theme-specific framing.

**Stake pattern (theme-case opener, ~80 words):**
```markdown
[Macro reference, 1 sentence — quotes the dimension narrative's framing]. For [theme domain] specifically, [theme-specific reframe]. [Theme-specific quantification: what's at stake for this theme that's NOT covered by the macro Forces narrative]. [Forcing function — theme-specific deadline, contract, or window].
```

**Anti-pattern:** Stake beats that re-establish the macro Forces story. If two theme-cases anchored to Forces both lead with "EU AI Act compliance," the first one owns the framing; the second references it without restating.

## Insight-Summary Forces Pattern (theme-less fallback)

When `tips-value-model.json` is absent, smarter-service degrades to trend-panorama-equivalent Forces — see `../trend-panorama/forces-patterns.md` for the full Act/Plan/Observe word breakdown and example prose.

## Subcategory Coverage

Same as trend-panorama:

- **Economy (wirtschaft)**: cost shocks, capital cycles, labor markets
- **Regulation (regulierung)**: deadlines, compliance mandates, sanctions
- **Society (gesellschaft)**: workforce expectations, customer behavior, ESG pressure

Aim to cover at least 2 of the 3 subcategories in the dimension narrative; the third can appear in a single anchored theme-case.

## Citation Requirements

**Theme-aware mode:** 4–6 citations in the dimension narrative; theme-cases follow their own citation rules. Avoid citing the same source twice between dimension narrative and theme-case Stake — the theme-case's reference sentence is sufficient.

**Insight-summary mode:** 5–8 citations (same as trend-panorama Forces).

## Quality Gates

- [ ] Dimension narrative establishes Forces story once; theme-cases do not re-establish it
- [ ] Anchor pivot paragraph introduces nested themes without restating their content
- [ ] Subcategory coverage: at least 2 of 3 (economy, regulation, society) in dimension narrative
- [ ] Horizon cascade present (Act → Plan → Observe)
- [ ] Each anchored theme-case Stake beat is ≤90 words and references the dimension narrative once

## Common Pitfalls

✗ **Dimension narrative repeats theme-case content.** The dimension narrative names a theme but then describes that theme's Move beat — duplicating the theme-case body.
✓ **Dimension narrative names themes only in the anchor pivot sentence.** It establishes the macro force; theme-cases describe the response.

✗ **Theme-case Stake beats restate macro forces.** Two themes anchored to Forces both lead with the same regulatory framing.
✓ **First theme-case owns the framing; second references it via the dimension narrative.** Pattern: "Building on the regulatory landscape established above, [Theme B's specific localization]."

## See Also

- `arc-definition.md` — Smarter Service arc metadata and theme anchoring rule
- `../trend-panorama/forces-patterns.md` — Shared subcategory clustering and horizon cascade mechanics
- `cogni-trends/skills/trend-report/references/phase-2-strategic-themes.md` — Theme-case dispatch contract
