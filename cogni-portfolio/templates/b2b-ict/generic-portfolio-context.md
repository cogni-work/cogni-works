# Generic B2B ICT Portfolio Context

A pre-built `portfolio-context.json` representing a typical B2B ICT service provider. Derived from the B2B ICT taxonomy template v3.7.

## Contents

- **7 products** (one per service dimension 1-7)
- **51 features** (one per taxonomy category in dimensions 1-7, with IS-layer descriptions and taxonomy mappings)
- **No pre-baked propositions** — DOES/MEANS are generated dynamically by the value-modeler based on each project's research context (industry, subsector, research topic)
- **No markets** — the target market comes from the trend-scout project, not from this template
- **No differentiators** (a generic provider has none)
- **`proposition_mode: "dynamic"`** — signals Phase 2 to generate propositions at runtime

## Purpose

Used by the cogni-trends value-modeler when no company-specific portfolio exists. Provides taxonomy-grounded feature definitions for solution blueprint composition, with coverage data instead of abstract `coverage: "unknown"` on all building blocks. The value-modeler generates DOES/MEANS dynamically using the project's industry context, investment themes, and feature IS descriptions.

## Limitations

- Features are generic — they describe typical B2B ICT capabilities, not a specific company's offerings
- No quality assessments — quality-aware ST generation is not available
- Coverage will be high by construction (every taxonomy category has a feature)
- No company-specific differentiators

## Replacing with a Real Portfolio

1. Run `/portfolio-setup` to create a company-specific portfolio
2. Run `/bridge portfolio-to-tips` to export it as `portfolio-context.json`
3. The generic context is overwritten — value-modeler automatically uses the real data
4. Run `/value-model re-anchor` to remap existing Solution Templates against real features
