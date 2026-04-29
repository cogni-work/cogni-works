# Report Length Tiers

This reference defines the four length tiers and the budget formula the trend-report orchestrator uses to size theme prose, synthesis, and the executive summary.

## What `target_words` measures

`target_words` is **prose only** — it counts words in:

- the executive summary (`report-header.md`)
- each investment-theme section (`report-investment-theme-{id}.md`)
- bridge paragraphs between themes (`report-bridge-{N}-{N+1}.md`)
- the synthesis section (`report-synthesis.md`)

It deliberately **excludes** the claims registry / sources appendix (`report-claims-registry.md`). The registry is verifiable evidence, always rendered in full regardless of tier, and varies in size with claim count (data-driven, not author-controlled). Counting it would make tier math unstable across projects.

The reviewer in `verify-trend-report` measures prose the same way — by summing word counts of the per-section log files in `.logs/`, never reading the registry into the count.

## Tier table

| Tier | `target_words` (prose) | Per-theme (N=5) | Synthesis | Exec | ≈ Total with full registry | Use case |
|---|---|---|---|---|---|---|
| **standard** *(default)* | 4,000 | 670 | 500 | 150 | ~6,000 | Detailed research report — analog to cogni-research's `detailed` mode |
| **extended** | 5,500 | 950 | 700 | 150 | ~7,500 | Strategic deep dive |
| **comprehensive** | 7,000 | 1,200 | 850 | 150 | ~9,000 | Full-depth analysis |
| **maximum** | 8,000 | 1,300 | 1,200 | 200 | ~10,000 | Current pre-tier behavior — exhaustive |

The "≈ Total" column assumes a typical ~2,000-word claims registry (30–60 claims at ~50–60 words per row). Actual totals vary by claim volume.

## Per-element minimums (theme writer)

The writer agent applies the fixed Why-arc proportions (Hook 8% / WhyChange 25% / WhyNow 20% / WhyYou 30% / WhyPay 17%) to `THEME_TARGET_WORDS`, then clamps each element to its minimum:

| Element | Minimum |
|---|---|
| Hook | 30 |
| Why Change | 80 |
| Why Now | 80 |
| Why You | 100 |
| Why Pay | 90 |
| **Sum** | **380** |

When `THEME_TARGET_WORDS ≥ 380`, proportions dominate. When the budget is tighter (small target × many themes), the minimums dominate and the agent overshoots target slightly — this is intentional. The alternative is dropping arc elements, which would break verify-trend-report's quality gates (≥3 citations per theme, all 4 Why-* elements, specific cost estimates in Why Pay).

## Orchestrator formula

In Phase 0.7 (Compute Budget) the orchestrator runs:

```
exec_words      = clamp(target_words * 0.04, 80, 250)
synthesis_words = clamp(target_words * 0.13, 350, 1300)
remaining       = target_words - exec_words - synthesis_words
per_theme_words = max(380, round(remaining / N))   # N = number of investment themes
```

`per_theme_words` becomes `THEME_TARGET_WORDS` for every dispatched investment-theme-writer agent. `synthesis_words` and `exec_words` are used by the orchestrator-written sections in Phase 2.

The claims registry is NOT in the formula — it is rendered separately in Step 2.5 and is excluded from word accounting.

## Worked examples

**Default (standard, N=5):**
- target_words = 4,000
- exec = clamp(160, 80, 250) = 160
- synthesis = clamp(520, 350, 1300) = 520
- remaining = 4,000 − 160 − 520 = 3,320
- per_theme = max(380, 3,320/5) = 664
- Resulting prose: 160 + 520 + 5 × 664 = 4,000 ✓

**Maximum (N=5):**
- target_words = 8,000
- exec = clamp(320, 80, 250) = 250
- synthesis = clamp(1,040, 350, 1300) = 1,040
- remaining = 8,000 − 250 − 1,040 = 6,710
- per_theme = max(380, 6,710/5) = 1,342
- Resulting prose: 250 + 1,040 + 5 × 1,342 ≈ 8,000 ✓

**Standard with many themes (N=7):**
- target_words = 4,000
- exec = 160, synthesis = 520, remaining = 3,320
- per_theme = max(380, 3,320/7) = 474
- Resulting prose: 160 + 520 + 7 × 474 ≈ 3,998 ✓

**Custom override (target_words=5,000, N=4):**
- exec = clamp(200, 80, 250) = 200
- synthesis = clamp(650, 350, 1300) = 650
- remaining = 5,000 − 200 − 650 = 4,150
- per_theme = max(380, 4,150/4) = 1,038
- Resulting prose: 200 + 650 + 4 × 1,038 ≈ 5,000 ✓

## Override semantics

A user can pass any integer `target_words` (within sensible bounds 2,500 ≤ target_words ≤ 12,000) to bypass tier defaults. The same formula applies. Below 2,500 the per-theme floor dominates and tier choice becomes meaningless; above 12,000 the report stops reading like a strategic narrative.

## Persistence

Tier and target are written to `tips-project.json`:

```json
{
  "report_tier": "standard",
  "report_target_words": 4000
}
```

Re-runs of `trend-report` and downstream `verify-trend-report` read these fields and skip the length question. The trend-scout output metadata also gets updated in Phase 4.1 so verify-trend-report's reviewer can read `report_target_words` from `.metadata/trend-scout-output.json`.

## Why this design

- **Per-theme word budget is the strongest single lever** — themes account for ~57% of prose in the current 10K-word reports.
- **Per-element minimums protect the Corporate Visions arc** — Why Pay can't carry "specific cost estimates and ROI ranges" below ~90 words, so we floor it instead of letting proportions silently break the gate.
- **Always render all themes** — preserves MECE coverage from value-modeler. Skipping themes would surprise users who expected "their" theme.
- **Always include the full claims registry** — verifiable evidence is non-negotiable. Excluding the registry from `target_words` keeps tier math stable across projects with different claim volumes.
- **Mirror cogni-research's API** — named tiers + `target_words` override is a familiar pattern to anyone who's used `research-report`'s `report_type` + `target_words` system.
