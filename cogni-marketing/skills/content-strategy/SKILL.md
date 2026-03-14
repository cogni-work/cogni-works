---
name: content-strategy
description: "This skill should be used when the user asks to plan a content strategy, build a content matrix, decide what content to create, map content to funnel stages, prioritize a content backlog, or plan GTM content. Trigger phrases include: 'plan content strategy', 'content matrix', 'what content should we create', 'content planning', 'marketing strategy', 'funnel mapping', 'content roadmap', 'content backlog', 'content prioritization', 'what should we write next', 'map GTM paths to content', 'marketing plan'. It builds a 3D matrix (market × GTM path × content type) with auto-recommended formats."
version: "1.0"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent
---

# Content Strategy

## Purpose

Build a comprehensive content strategy by mapping TIPS strategic themes (GTM paths) to portfolio propositions per market, then recommending content types and formats for each cell in the 3D matrix: **market × GTM path × content type**.

## Prerequisites

- Marketing project initialized (`marketing-project.json` exists with sources, markets, gtm_paths)

## Workflow

### Step 0: Load Project Context

1. Read `marketing-project.json` — extract markets, GTM paths, brand config, content defaults
2. For each market's GTM paths, load the TIPS strategic theme data:
   - Read `tips-value-model.json` → find the theme by ID
   - Extract: theme name, value chains (T→I→P paths), solution templates, narrative angle
3. For each market, load portfolio data:
   - Read propositions matching that market (`propositions/*--{market}.json`)
   - Read competitors (`competitors/*--{market}.json`)
   - Read customer profiles (`customers/{market}.json`)
4. Build a lookup: which propositions connect to which GTM path (via solution template → portfolio anchor → feature → proposition)

### Step 1: Narrative Angle Extraction

For each GTM path (TIPS strategic theme), extract the "WHY NOW" narrative:

1. **Trend hook**: The most compelling trend from the theme's value chains (T layer) — this drives thought leadership
2. **Implication tension**: The business implication that creates urgency (I layer) — this drives demand generation
3. **Possibility promise**: The opportunity the buyer can capture (P layer) — this drives lead generation
4. **Solution proof**: How the portfolio delivers it (S layer + propositions) — this drives sales enablement

Store as `narrative_angle` per GTM path:
```json
{
  "trend_hook": "AI-driven predictive maintenance reduces unplanned downtime by 47%",
  "implication_tension": "Manufacturers without predictive capabilities face 3x higher maintenance costs by 2027",
  "possibility_promise": "Early adopters achieve 30% asset lifetime extension through continuous condition monitoring",
  "solution_proof": "Our IoT + ML platform delivers real-time anomaly detection across all asset types"
}
```

### Step 2: Content Type Recommendation

For each cell in market × GTM path, recommend content types based on:

**Funnel focus** (from setup, schema enum: awareness|consideration|decision|full-funnel):
- `full-funnel`: All 5 content types
- `consideration`: thought-leadership + demand-gen + lead-gen
- `awareness`: thought-leadership + demand-gen only
- `decision`: sales-enablement + lead-gen (rare — usually part of full-funnel)

**Market maturity** (from portfolio market priority):
- `beachhead`: Full content investment — all recommended formats
- `expansion`: Selective — prioritize high-ROI formats (blog, LinkedIn, email)
- `aspirational`: Minimal — thought leadership only

**Proposition strength** (from portfolio quality assessment):
- Strong propositions (quality pass): Include sales enablement + lead gen
- Weak propositions (quality warn/fail): Limit to awareness content until propositions improve

**Buyer profile** (from portfolio customers):
- C-level decision makers: Prioritize executive briefings, keynote abstracts, whitepapers
- Technical evaluators: Prioritize blog posts, webinars, demo scripts
- Mixed: Full format spread

### Step 3: Format Selection per Cell

For each content type in each cell, select specific formats. Apply consulting logic:

**Thought Leadership formats** — pick 2-3:
- ALWAYS: blog (anchor content, SEO value)
- If LinkedIn is a primary channel: linkedin-article
- If events are relevant: keynote-abstract
- If audience prefers audio: podcast-outline

**Demand Generation formats** — pick 2-3:
- ALWAYS: linkedin-post (highest frequency, lowest effort)
- If SEO is important: seo-article
- If visual channel: carousel
- If video channel: video-script

**Lead Generation formats** — pick 2-3:
- ALWAYS: landing-page (conversion point)
- Choose ONE gated asset: whitepaper OR webinar-outline OR gated-checklist (based on audience preference)
- ALWAYS: email-nurture (post-conversion follow-up)

**Sales Enablement formats** — pick 2-3:
- ALWAYS: battle-card (competitive differentiation)
- If complex solution: demo-script
- If price-sensitive market: one-pager with ROI
- ALWAYS: objection-handler

**ABM formats** (only for primary markets with named accounts):
- account-plan + personalized-email + executive-briefing

### Step 4: Build Content Matrix

Assemble `content-strategy.json` following the schema in `${CLAUDE_PLUGIN_ROOT}/references/data-model.md`.

Present the matrix to the user as a readable table per market:

```
Market: mid-market-saas-dach (primary)

GTM Path: AI-Driven Predictive Maintenance
  Thought Leadership:  blog, linkedin-article, keynote-abstract     [3 pieces]
  Demand Generation:   linkedin-post ×4, seo-article, carousel      [6 pieces]
  Lead Generation:     whitepaper, landing-page, email-nurture ×3   [5 pieces]
  Sales Enablement:    battle-card, one-pager, objection-handler    [3 pieces]
                                                          Total:    [17 pieces]

GTM Path: Cloud-Native Transformation
  Thought Leadership:  blog, linkedin-article                       [2 pieces]
  Demand Generation:   linkedin-post ×3, seo-article                [4 pieces]
  Lead Generation:     webinar-outline, landing-page, email ×2      [4 pieces]
                                                          Total:    [10 pieces]

Market total: 27 pieces across 2 GTM paths
```

### Step 5: Priority Sequencing

Recommend a production sequence based on:
1. **GTM path priority** — highest-ranked themes first
2. **Content dependency** — anchor content (blog, whitepaper) before derivative (social posts, emails)
3. **Funnel logic** — awareness before consideration before decision
4. **Quick wins** — LinkedIn posts and battle cards are fast to produce

Present as ordered backlog:
```
Priority 1: [TL] Blog — AI Predictive Maintenance (anchor for all derivatives)
Priority 2: [DG] LinkedIn post ×2 — Promote blog + trend hook
Priority 3: [LG] Whitepaper — Deep dive on predictive maintenance ROI
Priority 4: [LG] Landing page — Whitepaper download gate
Priority 5: [SE] Battle card — vs. top 2 competitors in this space
...
```

### Step 6: Confirm & Save

Ask user to confirm or adjust the strategy:
> "This strategy produces {total} content pieces across {market_count} markets and {path_count} GTM paths. The estimated production sequence starts with {first_piece}. Shall I proceed, or would you like to adjust priorities, add/remove formats, or change the scope?"

Save `content-strategy.json` to the project directory.

Display next steps:
```
Content strategy saved. Next:
  1. /thought-leadership — Start with priority 1 (blog on AI Predictive Maintenance)
  2. /campaign — Build a campaign around the top GTM path
  3. /content-calendar — Generate a publication calendar
```

## Consulting Patterns

### Gap Detection
After building the matrix, flag gaps:
- Markets with GTM paths but no propositions → "messaging gap — run /propositions first"
- GTM paths with no competitor data → "competitive blind spot — run /compete first"
- Markets with no customer profiles → "persona gap — run /customers first"

### Cross-Market Synergy
Identify content that can be reused across markets with localization:
- Same GTM path in multiple markets → shared anchor content, market-specific variants
- Flag these as "reuse candidates" to reduce production volume

### Content Velocity Estimate
Based on format defaults and typical production:
- LinkedIn post: 15 min
- Blog: 1-2 hours
- Whitepaper: 4-6 hours
- Battle card: 1 hour
Present total estimated effort for user planning.
