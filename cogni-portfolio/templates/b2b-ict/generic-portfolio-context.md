# Generic B2B ICT Portfolio Context

A pre-built `portfolio-context.json` representing a typical B2B ICT service provider. Derived from the B2B ICT taxonomy template v3.7.

## Contents

- **7 products** (one per service dimension 1-7)
- **51 features** (one per taxonomy category in dimensions 1-7)
- **51 propositions** (IS/DOES/MEANS per feature, targeting large-enterprise-dach)
- **3 markets** (large-enterprise-dach, mid-market-global, public-sector-dach)
- **No differentiators** (a generic provider has none)

## Purpose

Used by the cogni-trends value-modeler when no company-specific portfolio exists. Provides taxonomy-grounded solution blueprints with real coverage data instead of abstract `coverage: "unknown"` on all building blocks.

## Limitations

- Propositions are generic — they describe typical B2B ICT capabilities, not a specific company's offerings
- No quality assessments — quality-aware ST generation is not available
- Coverage will be high by construction (every taxonomy category has a feature)
- No company-specific differentiators

## Replacing with a Real Portfolio

1. Run `/portfolio-setup` to create a company-specific portfolio
2. Run `/bridge portfolio-to-tips` to export it as `portfolio-context.json`
3. The generic context is overwritten — value-modeler automatically uses the real data
4. Run `/value-model re-anchor` to remap existing Solution Templates against real features
