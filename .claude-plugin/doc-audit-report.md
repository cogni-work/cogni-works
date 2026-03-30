# Documentation Drift Report
Generated: 2026-03-30
Repo: /Users/stephandehaas/GitHub/dev/insight-wave

## Summary

| Plugin | Components | Architecture | Descriptions | Dependencies | plugin.json | CLAUDE.md | Messaging | docs/ | Commercial | Overall |
|--------|-----------|--------------|-------------|-------------|-------------|-----------|-----------|-------|------------|---------|
| cogni-claims | OK | OK | OK | OK | OK | OK | OK | MISSING | UNWELCOMING | NEEDS UPDATE |
| cogni-narrative | OK | OK | DRIFT | OK | DRIFT | MISSING | WEAK | MISSING | UNWELCOMING | NEEDS UPDATE |
| cogni-copywriting | OK | OK | DRIFT | OK | OK | OK | WEAK | MISSING | UNWELCOMING | NEEDS UPDATE |
| cogni-workspace | OK | OK | OK | OK | OK | OK | WEAK | MISSING | UNWELCOMING | NEEDS UPDATE |
| cogni-trends | OK | OK | DRIFT | OK | DRIFT | MISSING | WEAK | MISSING | UNWELCOMING | NEEDS UPDATE |
| cogni-portfolio | OK | OK | DRIFT | OK | DRIFT | MISSING | OK | MISSING | UNWELCOMING | NEEDS UPDATE |
| cogni-visual | DRIFT | OK | OK | OK | OK | OK | OK | MISSING | UNWELCOMING | NEEDS UPDATE |
| cogni-help | DRIFT | DRIFT | OK | OK | OK | MISSING | WEAK | MISSING | UNWELCOMING | NEEDS UPDATE |
| cogni-marketing | OK | OK | DRIFT | OK | DRIFT | MISSING | WEAK | MISSING | UNWELCOMING | NEEDS UPDATE |
| cogni-research | OK | OK | DRIFT | OK | DRIFT | OK | OK | MISSING | UNWELCOMING | NEEDS UPDATE |
| cogni-sales | OK | OK | OK | OK | OK | OK | WEAK | MISSING | UNWELCOMING | NEEDS UPDATE |
| cogni-consulting | OK | OK | DRIFT | OK | DRIFT | OK | OK | MISSING | UNWELCOMING | NEEDS UPDATE |

**Totals: 2 component drift, 1 architecture drift, 7 description drift, 6 plugin.json drift, 5 missing CLAUDE.md, 7 weak messaging, 12 missing docs/, 12 unwelcoming commercial tone**

## Systemic Issues

These affect ALL 12 plugins:

1. **No `docs/` directory** — Zero plugins have user documentation beyond the README. No plugin guides, no workflow guides.
2. **No Contributing section** — Zero READMEs include a Contributing section with community guidance. 8/12 plugins have a `CONTRIBUTING.md` file but the README doesn't link to it.
3. **No built-by footer** — Zero READMEs include the canonical `Built by [cogni-work](https://cogni-work.ai)` footer after License.
4. **Missing "What it is" section** — 7/12 plugins use "What it does" (capability list) instead of the separate "What it is" (identity/positioning) section. Only cogni-claims, cogni-portfolio, cogni-visual, cogni-consulting, and cogni-trends (via title paragraph) have genuine IS-expanded content.

---

## cogni-claims

### Component Table Drift
- OK

### Architecture Tree Drift
- OK

### Description Alignment
- OK — README, plugin.json, and marketplace.json descriptions are consistent

### Dependency Table Drift
- OK

### plugin.json
- OK

### CLAUDE.md
- OK — below complexity threshold (2 skills, 2 agents)

### Power Messaging
- OK — all four IS/DOES/MEANS layers present with evidence-backed problem table (sourced citations)

### docs/
- MISSING: no docs/ directory

### Commercial Tone
- UNWELCOMING: has Custom development section but no Contributing section in README

---

## cogni-narrative

### Component Table Drift
- OK

### Architecture Tree Drift
- OK

### Description Alignment
- DRIFT: plugin.json says "7 story arc frameworks" (including theme-thesis), marketplace.json and README say "6 story arc frameworks"

### Dependency Table Drift
- OK

### plugin.json
- DRIFT: description count mismatch — "7 story arc frameworks" vs "6" in marketplace.json

### CLAUDE.md
- MISSING: 3 agents meets complexity threshold but no CLAUDE.md exists

### Power Messaging
- WEAK: no "What it is" section (IS-expanded) — uses "What it does" as capability list. "What it means for you" lists features ("Six frameworks", "Format-flexible") more than business outcomes

### docs/
- MISSING: no docs/ directory

### Commercial Tone
- UNWELCOMING: has Custom development section but no Contributing section

---

## cogni-copywriting

### Component Table Drift
- OK

### Architecture Tree Drift
- OK

### Description Alignment
- DRIFT: marketplace.json includes "arc contract audit against cogni-narrative" which plugin.json omits

### Dependency Table Drift
- OK

### plugin.json
- OK (description is consistent within itself)

### CLAUDE.md
- OK — below complexity threshold (4 skills, 2 agents)

### Power Messaging
- WEAK: no "What it is" section (IS-expanded). "What it means for you" has good outcome framing but IS layer is incomplete

### docs/
- MISSING: no docs/ directory

### Commercial Tone
- UNWELCOMING: has Custom development section but no Contributing section

---

## cogni-workspace

### Component Table Drift
- OK

### Architecture Tree Drift
- OK

### Description Alignment
- OK

### Dependency Table Drift
- OK

### plugin.json
- OK

### CLAUDE.md
- OK — has CLAUDE.md

### Power Messaging
- WEAK: no "What it is" section (IS-expanded). Has strong title paragraph and good "What it means for you" outcomes, but missing the identity/methodology positioning layer

### docs/
- MISSING: no docs/ directory

### Commercial Tone
- UNWELCOMING: has Custom development section but no Contributing section

---

## cogni-trends

### Component Table Drift
- OK

### Architecture Tree Drift
- OK

### Description Alignment
- DRIFT: plugin.json description fundamentally different from marketplace.json
  - plugin.json: "Bridges industry trends to portfolio solutions via value paths using patented TIPS methodology..."
  - marketplace.json: "Strategic trend scouting and reporting pipeline. Combines the Smarter Service Trendradar..."
  - README: "A Claude Cowork plugin for scouting, selecting, and reporting on strategic industry trends..."
  - All three describe different aspects with different emphasis

### Dependency Table Drift
- OK

### plugin.json
- DRIFT: description diverges significantly from marketplace.json and README — emphasizes "patented TIPS methodology" and "portfolio solutions" while marketplace and README emphasize "trend scouting" and "Trendradar"

### CLAUDE.md
- MISSING: 6 skills, 4 agents — exceeds complexity threshold. No CLAUDE.md exists

### Power Messaging
- WEAK: no "What it is" section (IS-expanded). Strong title paragraph naming Smarter Service Trendradar and TIPS with patent reference, but no separate IS-expanded section positioning the plugin in the ecosystem

### docs/
- MISSING: no docs/ directory

### Commercial Tone
- UNWELCOMING: has Custom development section but no Contributing section

---

## cogni-portfolio

### Component Table Drift
- OK — all 20 skills and 17 agents present in README table

### Architecture Tree Drift
- OK — counts match (20 skills, 17 agents)

### Description Alignment
- DRIFT: plugin.json missing capabilities present in marketplace.json
  - plugin.json: "...Includes TAM/SAM/SOM targeting, competitor and customer analysis."
  - marketplace.json adds: "deep-dive research for features and propositions, Lean Canvas bootstrapping, and eight pluggable industry taxonomies"

### Dependency Table Drift
- OK

### plugin.json
- DRIFT: description shorter than marketplace.json — missing deep-dive, Lean Canvas, and taxonomy capabilities

### CLAUDE.md
- MISSING: 20 skills, 17 agents — far exceeds complexity threshold. This is the highest-priority CLAUDE.md gap in the ecosystem

### Power Messaging
- OK — all four IS/DOES/MEANS layers present with specificity. Strong problem table with quantifiers ("2 weeks of work"), IS-expanded names IS/DOES/MEANS framework and 8 taxonomy templates, MEANS has outcome bullets with quantifiers

### docs/
- MISSING: no docs/ directory

### Commercial Tone
- UNWELCOMING: has Custom development section but no Contributing section

---

## cogni-visual

### Component Table Drift
- DRIFT: 3 agents exist on disk but missing from README Components table
  - ADDED: `big-block` (Agent) — exists at agents/big-block.md
  - ADDED: `big-picture` (Agent) — exists at agents/big-picture.md
  - ADDED: `story-to-big-block` (Agent) — exists at agents/story-to-big-block.md

### Architecture Tree Drift
- OK — architecture tree says "13 agents" which matches disk, but Components table only lists 10

### Description Alignment
- OK

### Dependency Table Drift
- OK

### plugin.json
- OK

### CLAUDE.md
- OK — has CLAUDE.md

### Power Messaging
- OK — all four layers present. Brief pipeline description in IS-expanded, strong outcome bullets in MEANS

### docs/
- MISSING: no docs/ directory

### Commercial Tone
- UNWELCOMING: has Custom development section but no Contributing section

---

## cogni-help

### Component Table Drift
- DRIFT: `/issues` command listed in README Components table but no `commands/issues.md` exists on disk (only 7 command files found, README lists 8)

### Architecture Tree Drift
- DRIFT: README says "8 slash commands" but only 7 exist on disk (missing `issues.md`)

### Description Alignment
- OK

### Dependency Table Drift
- OK (text-based dependency statement, no formal table)

### plugin.json
- OK

### CLAUDE.md
- MISSING: 7 skills — exceeds complexity threshold. No CLAUDE.md exists

### Power Messaging
- WEAK: title paragraph is generic ("Central help hub") without positioning statement. Problem section uses Need/Solution format instead of Problem/What happens/Impact. No "What it is" section. No "What it means for you" section. Three of four messaging layers missing or structurally deficient — weakest messaging in the ecosystem

### docs/
- MISSING: no docs/ directory

### Commercial Tone
- UNWELCOMING: has Custom development section but no Contributing section

---

## cogni-marketing

### Component Table Drift
- OK

### Architecture Tree Drift
- OK

### Description Alignment
- DRIFT: plugin.json and marketplace.json use different terminology
  - plugin.json: "cogni-trends strategic themes (GTM paths)"
  - marketplace.json: "cogni-trends investment themes (Handlungsfelder)"

### Dependency Table Drift
- OK

### plugin.json
- DRIFT: terminology mismatch — "GTM paths" vs "Handlungsfelder" (investment themes)

### CLAUDE.md
- MISSING: 11 skills, 3 agents — exceeds complexity threshold. No CLAUDE.md exists

### Power Messaging
- WEAK: no "What it is" section (IS-expanded). Has good problem table and outcome bullets, but missing the identity positioning layer

### docs/
- MISSING: no docs/ directory

### Commercial Tone
- UNWELCOMING: has Custom development section but no Contributing section

---

## cogni-research

### Component Table Drift
- OK

### Architecture Tree Drift
- OK

### Description Alignment
- DRIFT: plugin.json says "five report types (basic, detailed, deep, outline, resource)" while marketplace.json says "three report types (basic, detailed, deep)"

### Dependency Table Drift
- OK

### plugin.json
- DRIFT: report type count mismatch — 5 in plugin.json vs 3 in marketplace.json

### CLAUDE.md
- OK — has CLAUDE.md

### Power Messaging
- OK — strong title paragraph naming STORM methodology, sourced problem table, good MEANS with quantifiers ("5-7 agents", "15-25")

### docs/
- MISSING: no docs/ directory

### Commercial Tone
- UNWELCOMING: has Custom development section but no Contributing section

---

## cogni-sales

### Component Table Drift
- OK

### Architecture Tree Drift
- OK

### Description Alignment
- OK

### Dependency Table Drift
- OK

### plugin.json
- OK

### CLAUDE.md
- OK — below complexity threshold (1 skill, 2 agents)

### Power Messaging
- WEAK: no "What it is" section (IS-expanded). Strong title paragraph naming Corporate Visions methodology, but missing the separate IS-expanded section with ecosystem positioning

### docs/
- MISSING: no docs/ directory

### Commercial Tone
- UNWELCOMING: has Custom development section but no Contributing section

---

## cogni-consulting

### Component Table Drift
- OK

### Architecture Tree Drift
- OK

### Description Alignment
- DRIFT: marketplace.json includes capabilities not in plugin.json
  - marketplace.json adds: "Includes Lean Canvas authoring and multi-persona stress testing via the business-model-hypothesis vision class"
  - plugin.json omits these capabilities

### Dependency Table Drift
- OK

### plugin.json
- DRIFT: description omits Lean Canvas and multi-persona stress testing capabilities present in marketplace.json

### CLAUDE.md
- OK — has CLAUDE.md

### Power Messaging
- OK — all four layers present. Strong IS-expanded ("process orchestrator... senior partner who runs the engagement"), strong MEANS ("Big-5 complexity with boutique team")

### docs/
- MISSING: no docs/ directory

### Commercial Tone
- UNWELCOMING: has Custom development section but no Contributing section

---

## Priority Fixes

### Tier 1 — Structural Drift (fix first)
1. **cogni-visual**: Add 3 missing agents to Components table (`big-block`, `big-picture`, `story-to-big-block`)
2. **cogni-help**: Remove `/issues` from Components table and fix architecture count (8→7 commands), OR create the missing `commands/issues.md`

### Tier 2 — Description Alignment (fix next)
3. **cogni-narrative**: Align framework count — plugin.json says 7, marketplace.json says 6
4. **cogni-trends**: Align plugin.json description with marketplace.json and README
5. **cogni-portfolio**: Add missing capabilities to plugin.json (deep-dive, Lean Canvas, taxonomies)
6. **cogni-marketing**: Align terminology — "GTM paths" vs "Handlungsfelder"
7. **cogni-research**: Align report type count — plugin.json says 5, marketplace.json says 3
8. **cogni-consulting**: Add Lean Canvas and stress testing to plugin.json description
9. **cogni-copywriting**: Add "arc contract audit" mention to plugin.json description

### Tier 3 — Developer Guides (for complex plugins)
10. **cogni-portfolio**: Generate CLAUDE.md (20 skills, 17 agents — highest priority)
11. **cogni-marketing**: Generate CLAUDE.md (11 skills, 3 agents)
12. **cogni-trends**: Generate CLAUDE.md (6 skills, 4 agents)
13. **cogni-help**: Generate CLAUDE.md (7 skills)
14. **cogni-narrative**: Generate CLAUDE.md (3 agents)

### Tier 4 — Messaging (strengthen positioning)
15. **cogni-help**: Most urgent — missing 3 of 4 messaging layers. Needs full IS/DOES/MEANS rewrite
16. **cogni-narrative**: Add "What it is" section, rewrite MEANS for outcomes not features
17. **cogni-copywriting, cogni-workspace, cogni-trends, cogni-marketing, cogni-sales**: Add "What it is" (IS-expanded) section

### Tier 5 — Community (systemic)
18. Add Contributing section to all 12 READMEs
19. Add built-by footer to all 12 READMEs

### Tier 6 — User Documentation
20. Generate `docs/` directory with plugin guides and workflow docs
