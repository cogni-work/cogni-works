# Phase 0: Initialize & Load

## Objective

Load the trend-scout output, validate prerequisites, and discover optional integrations.

## Steps

### Step 1: Discover Project

Search the workspace for TIPS projects:

1. Look for `cogni-trends/*/tips-project.json` files
2. If multiple projects exist, list them and ask the user which one to model
3. If only one exists, confirm with the user

### Step 2: Load Trend-Scout Output

Read `.metadata/trend-scout-output.json` from the selected project.

**Validation gates:**
- `execution.workflow_state` must be `"agreed"` — the user must have completed candidate selection
- `tips_candidates.total` must be >= 20 (minimum viable set for relationship building)
- `tips_candidates.items` must contain candidates from at least 3 of the 4 dimensions

If validation fails, tell the user what's missing and suggest running `trend-scout` first.

**Extract portfolio link from trend-scout:**

Also read `tips-project.json` from the project directory and check for `portfolio_source`:

```json
{
  "portfolio_source": {
    "portfolio_slug": "acme-corp",
    "market_slug": "mid-market-saas-dach"
  }
}
```

If present, store `PORTFOLIO_SOURCE_SLUG` and `PORTFOLIO_MARKET_SLUG`. This link was
established when the user chose a portfolio market during trend-scout initialization —
it tells us exactly which portfolio project and market to connect to, avoiding a blind scan.

### Step 3: Discover Industry Catalog (Optional)

Search for a matching industry catalog:

1. Read `industry.primary` and `industry.subsector` from the project config
2. Check for `cogni-trends/catalogs/{primary}/{subsector}/catalog.json`
3. If found, read it and report:
   - "Found {industry}/{subsector} catalog with {stats summary}. Catalog data will inform relationship building and solution generation."
   - Store catalog path for use in Phases 1 and 2
4. If not found: "No industry catalog found. You can create one later with `/trends-catalog init` to accumulate knowledge across pursuits."

### Step 4: Discover Portfolio

**When trend-scout linked a portfolio** (`PORTFOLIO_SOURCE_SLUG` set from Step 2):

Use the link directly — look for `*/{PORTFOLIO_SOURCE_SLUG}/portfolio.json` in the workspace.
This is the portfolio the user explicitly chose during trend-scout, so skip the generic scan.

1. Locate the portfolio by matching `PORTFOLIO_SOURCE_SLUG` against portfolio project directories
2. Read `portfolio.json` and catalog products, features, markets, propositions, solutions
3. Report: "This project is linked to portfolio '{PORTFOLIO_SOURCE_SLUG}' (market: '{PORTFOLIO_MARKET_SLUG}') — established during trend-scout. Found X products and Y features."

**When no trend-scout link exists** (fallback to generic discovery):

Search the workspace for a cogni-portfolio project:

1. Look for `portfolio/portfolio.json` or `*/portfolio.json`
2. If found, read it and catalog:
   - Products and their features
   - Any existing markets, propositions, solutions
3. Report to the user: "Found portfolio with X products and Y features. I'll map Solution Templates to these where relevant."
4. If not found: "No portfolio found. Solution Templates will be standalone — you can connect them to a portfolio later."

### Step 4b: Check Portfolio Context & Recommend Bridge

After discovering the portfolio project (by either method), check for `portfolio-context.json`
in the TIPS project directory (written by `/bridge portfolio-to-tips` or copied from generic template):

**0. If found with `is_generic_template` = `true`:**
   - This is a generic portfolio context from the taxonomy template, not a real company portfolio.
   - Skip staleness check (`extracted_at` is null — this is static template data)
   - Skip bridge refresh recommendation
   - Count products, features, and propositions for the summary
   - Report: "Using generic B2B ICT portfolio context (template-based, {N} products,
     {M} features with taxonomy mappings). Portfolio-anchored ST generation is available —
     Phase 2 will match features to investment themes using IS descriptions and generate
     DOES/MEANS propositions dynamically for your research context. Quality-aware generation
     is not available (no quality assessments on generic propositions)."
   - Set `portfolio_generic: true` in output metadata
   - Proceed to Step 5

1. If found with `schema_version` = `"3.1"`:
   - Count products, features, propositions, and markets
   - Count markets where `market_relevance` is `direct` or `industry`
   - Count propositions with `quality_assessment` and report quality summary
   - Count propositions with `variant_count > 0`
   - Count `differentiators[]` entries (v3.1 addition) — report: "D provider differentiators available for trend-report portfolio close"
   - Report: "Found portfolio context (v3.1) with N products, M features, P propositions
     across K markets (R relevant to this TIPS industry). Q propositions have quality
     assessments, V have existing variants, D differentiators. Portfolio-anchored ST
     generation is available — Phase 2 will start from your products as delivery anchors."
   - Check `extracted_at` against portfolio file modification dates; if portfolio files are
     newer, recommend: "Portfolio has changed since the last bridge export. Run
     `/bridge portfolio-to-tips` to refresh the context before we continue."
   - Offer: "Refresh portfolio context now" vs "Continue with existing context"
1b. If found with `schema_version` = `"3.0"`:
   - Same as v3.1 checks, but `differentiators[]` will be absent
   - Report: "Found portfolio context (v3.0) — consider re-running `/bridge portfolio-to-tips`
     to upgrade to v3.1 for provider differentiators in trend-report portfolio close."
2. If found with `schema_version` = `"2.0"`:
   - Count products, features, propositions, and markets
   - Count markets where `market_relevance` is `direct` or `industry`
   - Report: "Found portfolio context (v2.0) with N products, M features, P propositions
     across K markets (R relevant to this TIPS industry). Portfolio-grounded ST generation
     is available. Consider re-running `/bridge portfolio-to-tips` to upgrade to v3.0 for
     quality-aware generation."
   - Check `extracted_at` against portfolio file modification dates; if portfolio files are
     newer, recommend refreshing as above.
3. **If portfolio was discovered but portfolio-context.json is missing or v1.0:**
   - This is the most important case to handle well. The user has a portfolio but hasn't
     bridged it yet, which means Phase 2 will generate abstract Solution Templates instead
     of grounding them in actual products.
   - Present to the user:

     "Your TIPS project is connected to portfolio '{slug}'. To get the most out of value
     modeling, I recommend running `/bridge portfolio-to-tips` first — this exports your
     product features, propositions, and solution data so I can ground Solution Templates
     in what you actually sell. Without it, I'll generate abstract solutions that you'd
     need to manually map to your products later."

   - Offer:
     - "Run `/bridge portfolio-to-tips` now" — guide the user to invoke the bridge skill,
       then resume value-modeler from Step 4b
     - "Continue without portfolio grounding" — proceed with abstract ST generation

4. **If no portfolio was discovered at all:**

   Before reporting, check if a generic portfolio context is available:

   1. Read `industry.primary` from `tips-project.json`
   2. Map industry to taxonomy type using these keywords:
      - ICT, IT Services, IT-Services, Managed Services, Cloud Infrastructure, Systems Integration,
        IT Consulting, Telecommunications, Digital Services → `b2b-ict`
      - (Future taxonomy types can be added here)
   3. Look for `$COGNI_PORTFOLIO_ROOT/templates/{taxonomy-type}/generic-portfolio-context.json`
      (where `$COGNI_PORTFOLIO_ROOT` is the cogni-portfolio plugin directory)
   4. If a generic portfolio context is found, present this choice:

      "No company portfolio found in your workspace. However, a **generic B2B ICT portfolio**
      is available based on the B2B ICT taxonomy (7 products, 51 features with IS-layer
      descriptions and taxonomy mappings).

      Choose how to proceed:

      1. **Use generic B2B ICT portfolio** — Solution Templates will be grounded in typical
         ICT service capabilities (connectivity, security, cloud, workplace, infrastructure,
         applications, consulting). Building blocks will show coverage against generic features.
         You can replace this with your own portfolio later.

      2. **Continue without portfolio** — Solution Templates will be standalone with
         `coverage: "unknown"` on all building blocks. Connect a portfolio later with
         `/bridge tips-to-portfolio`.

      3. **Set up your own portfolio first** — Pause value-modeling to create a company-specific
         portfolio with `/portfolio-setup`, then return with `/value-model`."

   5. If the user picks **option 1** (generic portfolio):
      - Copy the generic portfolio context file into the TIPS project directory as
        `portfolio-context.json`
      - The file has `is_generic_template: true` — this flag controls behavior in Step 4b
        and Phase 2
      - Set in output metadata: `portfolio_discovered: true`, `portfolio_generic: true`,
        `portfolio_source_slug: "generic-b2b-ict"`
      - Report: "Using generic B2B ICT portfolio (7 products, 51 features, propositions
        generated dynamically for your target context). Solution Templates will be grounded
        in generic ICT capabilities — clearly marked as template-based. You can replace this
        with your own portfolio later via `/portfolio-setup` + `/bridge portfolio-to-tips`."
      - Proceed to Step 4b to validate the context

   6. If the user picks **option 2** (no portfolio):
      - "No portfolio. Solution Templates will be standalone — you can connect them
        to a portfolio later using `/bridge tips-to-portfolio`."

   7. If the user picks **option 3** (set up portfolio):
      - "Run `/portfolio-setup` to create your company portfolio, then come back with
        `/value-model` when you're ready."
      - Exit gracefully

   8. If no generic portfolio context was found for the industry type:
      - Fall back to the original message: "No portfolio found. Solution Templates will
        be standalone — you can connect them to a portfolio later using
        `/bridge tips-to-portfolio`."

Add to the output metadata:

```json
{
  "portfolio_context_version": "3.0",
  "portfolio_context_propositions": 12,
  "portfolio_context_markets_relevant": 2,
  "portfolio_context_quality_assessed": 10,
  "portfolio_context_variants_exist": 3
}
```

These fields are `null` when no enriched context is available.

### Step 5: Load Existing Value Model (Resume Support)

Check for `tips-value-model.json` in the project directory:

1. If found, load it and determine which phases are complete
2. Report progress and ask if the user wants to continue or restart
3. If not found, initialize a fresh value model

### Step 6: Confirm Configuration

Present to the user:

```
Project: {project name}
Industry: {industry/subsector}
Language: {language}
Candidates: {total} across {dimensions} dimensions
Catalog: {found with N entities / not found}
Portfolio: {found / generic B2B ICT (template-based, N products, M features) / not found}
```

Ask: "Ready to build the value model? I'll start by mapping relationship networks across your {total} trend candidates."

## Output

Create `.metadata/value-modeler-output.json`:

```json
{
  "version": "1.0.0",
  "project_id": "{project-slug}",
  "project_language": "{language}",
  "catalog_discovered": true|false,
  "catalog_path": "cogni-trends/catalogs/manufacturing/automotive" | null,
  "portfolio_discovered": true|false,
  "portfolio_generic": false|true,
  "portfolio_path": "path/to/portfolio.json" | null,
  "portfolio_source_slug": "acme-corp" | "generic-b2b-ict" | null,
  "portfolio_source_market": "mid-market-saas-dach" | null,
  "portfolio_context_version": "3.1" | null,
  "portfolio_context_propositions": 12 | null,
  "portfolio_context_markets_relevant": 2 | null,
  "candidate_count": 60,
  "execution": {
    "workflow_state": "initialized",
    "current_phase": 0,
    "phases_completed": ["phase-0"]
  }
}
```

`portfolio_source_slug` and `portfolio_source_market` are carried forward from the
trend-scout `portfolio_source` link. They are `null` when trend-scout was initialized
without a portfolio market selection.
