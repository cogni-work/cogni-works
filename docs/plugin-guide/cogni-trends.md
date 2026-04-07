# cogni-trends

Strategic trend scouting and reporting — combines the Smarter Service Trendradar with the TIPS framework to move from industry signals to investment-grade solution blueprints.

For the canonical IS/DOES/MEANS positioning of this plugin, see the [cogni-trends README](../../cogni-trends/README.md).

---

## Overview

cogni-trends automates the research-heavy parts of strategic trend analysis while keeping framework judgment where it belongs — with the analyst. The pipeline runs in four stages: scout signals across 4 Trendradar dimensions, model them into investment themes and solution blueprints, generate CxO-level narrative reports, and accumulate curated knowledge in reusable industry catalogs.

The plugin is purpose-built for the DACH market (Germany, Austria, Switzerland). Web research runs bilingually in English and German, targeting curated German institutional sources — VDMA, BITKOM, Fraunhofer, Zukunftsinstitut, EUR-Lex — alongside international databases. The underlying bilingual search architecture is generalizable; see `cogni-trends/references/architecture-pattern.md` for the reusable pattern.

Two complementary frameworks drive the analytical structure:

- **Smarter Service Trendradar** organizes *where* trends live across four strategic dimensions
- **TIPS** defines *how* each trend is analyzed — Trends, Implications, Possibilities, Solutions — as a value chain from signal to action

Each project is multi-session. A trend-scout run can take 10–20 minutes; value modeling adds another session; report generation dispatches parallel agents per investment theme. `/trends-resume` re-enters any project with full state recovery.

---

## Key Concepts

### Smarter Service Trendradar

The Trendradar places trends in a 4-dimension model by Bernhard Steimel (Smarter Service). Dimensions answer different strategic questions:

| Dimension | German Name | Core Question |
|-----------|-------------|---------------|
| External forces | Externe Effekte | What external forces are impacting the organization? |
| Future revenue | Neue Horizonte | What will the company be paid for in the future? |
| Digital value | Digitale Wertetreiber | Where do we create value through digital means? |
| Foundation | Digitales Fundament | What capabilities must exist for the next decade? |

Each trend also carries an **action horizon**: **Act** (0–2 years), **Plan** (2–5 years), or **Observe** (5+ years). The scouting phase fills a 4×3 grid: 4 dimensions × 3 horizons = 12 cells, 5 candidates per cell = 60 scored candidates.

### TIPS Framework

TIPS (Trends, Implications, Possibilities, Solutions) is the content expansion applied to every discovered trend. Originally documented in Siemens patent WO2018046399A1 (filed 2017, ceased 2019 — freely usable).

```
T (Trend)       → What is happening?
I (Implications) → What does this mean for the industry?
P (Possibilities) → How can the organization capitalize?
S (Solutions)    → What concrete steps deliver value?
```

The T→I→P→S chain is the bridge from a scouted signal to an actionable solution blueprint. The value-modeler skill constructs relationship networks across these chains and consolidates them into investment themes (Handlungsfelder).

### Multi-Framework Scoring

The trend-generator agent scores each candidate against four frameworks simultaneously:

| Framework | What it scores |
|-----------|---------------|
| TIPS value chain | Completeness of the T→I→P→S path |
| Ansoff signal intensity | Market disruption level (levels 1–5) |
| Rogers diffusion stage | Adoption curve position (innovators → laggards) |
| CRAAP source quality | Source credibility (Currency, Relevance, Authority, Accuracy, Purpose) |

The combined score drives candidate selection and influences investment theme prioritization in the value-modeler.

### Industry Catalogs

Each industry has a persistent catalog that accumulates curated knowledge across engagements. When you run `trends-catalog` at the end of a project, selected solution templates, SPIs, metrics, and collaterals are promoted to the catalog. Future projects in the same industry start with this accumulated baseline — each pursuit improves the next.

### Project File Structure

```
cogni-trends/{project-slug}/
├── tips-project.json          # Project config + workflow state
├── trend-candidates.md        # 60 scored candidates (human-readable)
├── tips-value-model.json      # Investment themes + solution templates
├── tips-big-block.md          # Solution architecture summary
├── tips-solution-ranking.md   # Ranked solutions with BR scores
├── tips-trend-report.md       # Full CxO narrative report
└── .metadata/                 # Execution logs, verification state
```

---

## Getting Started

**First prompt:**

> Scout trends for the industrial automation sector in Germany

What happens:

1. `trend-scout` presents the industry taxonomy and confirms your subsector selection
2. Initializes a project with a semantic slug (e.g., `industrial-automation-dach-abc12345`)
3. Dispatches `trend-web-researcher` — 32 bilingual web searches + academic and patent API queries
4. Dispatches `trend-generator` (Opus) — produces 60 scored candidates across the 4×3 Trendradar grid using extended thinking
5. Presents candidates for review and agreement
6. Writes `trend-candidates.md` and marks candidates as agreed for downstream modeling

**Expected output (tips-project.json fragment):**

```json
{
  "slug": "industrial-automation-dach-abc12345",
  "name": "Industrial Automation DACH",
  "language": "de",
  "industry": {
    "primary": "manufacturing",
    "subsector": "industrial-automation"
  },
  "research_topic": "AI-driven industrial automation trends",
  "execution": {
    "workflow_state": "agreed",
    "current_phase": 4
  }
}
```

From there: `/value-modeler` → `/trend-report` → `/trends-catalog`.

---

## Capabilities

### trend-scout

End-to-end trend scouting with industry selection, bilingual research, and 60 scored candidates. Dispatches two agents in sequence: `trend-web-researcher` (bilingual signals) and `trend-generator` (Opus, multi-framework scoring). Candidates are presented for user agreement before downstream modeling.

**Example prompt:** "Scout trends for the logistics industry, focus on last-mile delivery in DACH"

---

### value-modeler

Transform agreed candidates into investment themes and ranked solution templates. Builds T→I→P→S relationship networks, consolidates them into 3–7 MECE investment themes (Handlungsfelder), generates solution blueprints with portfolio composition and readiness scoring. Includes interactive Business Relevance (BR) scoring. Optionally anchors solutions to real portfolio products when cogni-portfolio is available.

**Example prompt:** "Model investment themes from the agreed candidates and rank solution templates"

---

### trend-report

Generate a CxO-level narrative report organized around investment themes. Dispatches one `trend-report-investment-theme-writer` agent per theme in parallel — each writes a narrative section using the Corporate Visions arc (Why Change → Why Now → Why You → Why Pay) backed by T→I→P→S evidence. Enriches every quantitative claim with web-sourced evidence and inline citations. Assembles the final report with executive summary, portfolio analysis, and a verifiable claims registry compatible with cogni-claims.

**Example prompt:** "Generate the trend report from the modeled investment themes"

---

### trends-catalog

Curate solutions, SPIs, metrics, and collaterals from a completed project into the persistent industry catalog. Each run enriches the base catalog for future pursuits in the same industry.

**Example prompt:** "Export the curated solutions from this project to the industrial automation catalog"

---

### trends-dashboard

Generate a self-contained HTML dashboard visualizing the full TIPS project lifecycle — candidate landscape, dimension coverage, scoring distributions, investment themes, and report status.

**Example prompt:** "Show me the TIPS project dashboard"

---

### trends-resume

Re-enter a project mid-stream. Reads project state, shows phase progress and entity counts, and recommends the next action. Use at the start of any follow-up session.

**Example prompt:** "Where was I in the industrial automation project?"

---

## Integration Points

### Upstream (what cogni-trends consumes)

| Plugin | Skill | What is consumed |
|--------|-------|-----------------|
| cogni-portfolio | trends-bridge | Portfolio anchors that enrich solution relevance scoring |
| cogni-workspace | trends-dashboard | Theme selection via pick-theme |

### Downstream (what cogni-trends produces for others)

| Plugin | Skill | What is provided |
|--------|-------|-----------------|
| cogni-portfolio | trends-bridge | Solution templates exported as portfolio features |
| cogni-narrative | (manual) | Trend report and insight summary as narrative input |
| cogni-claims | trend-report | Claims registry submitted for source URL verification |
| cogni-copywriting | (manual) | Report prose for executive polish |
| cogni-visual | story-to-big-block | TIPS value-modeler output as Big Block diagram data |

---

## Common Workflows

### Workflow 1: Full TIPS Pipeline

The standard four-stage sequence for a new industry engagement.

1. `/trend-scout` — industry selection, bilingual web research, 60 candidates
2. Review and agree on candidates (interactive checkpoint)
3. `/value-modeler` — investment themes, T→I→P→S networks, solution blueprints, BR scoring
4. `/trend-report` — CxO narrative with parallel theme writers, evidence enrichment, claims registry
5. `/trends-catalog` — promote curated solutions to the industry catalog

For the extended flow that connects trend output to portfolio messaging and solution blueprints, see [../workflows/trends-to-solutions.md](../workflows/trends-to-solutions.md).

---

### Workflow 2: Trend-Grounded Portfolio Update

Use this when existing portfolio messaging needs to be refreshed against current market signals.

1. `/trend-scout` — scout trends for your portfolio's primary market
2. `/value-modeler` — model investment themes, anchor to portfolio products via cogni-portfolio
3. `/trends-bridge` (in cogni-portfolio) — import TIPS solution templates as new portfolio features
4. `/propositions` (in cogni-portfolio) — generate messaging for the new Feature x Market pairs
5. `/trend-report` — generate a briefing document for internal stakeholders

---

### Workflow 3: Executive Briefing from Trend Report

Use this when you have a completed trend report and need to transform it into visual and narrative deliverables.

1. `/trend-report` — complete the trend report with evidence and claims
2. cogni-narrative `/narrative` — transform the report into an arc-driven narrative
3. cogni-visual `/story-to-big-block` — generate a Big Block solution architecture diagram from `tips-value-model.json`
4. cogni-visual `/story-to-slides` — create a slide deck from the narrative
5. cogni-claims `/claims` — verify the claims registry

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| "No TIPS project found" | Running value-modeler or trend-report without completing trend-scout | Run `/trend-scout` first or use `/trends-resume` to find an existing project |
| Web research returns few results | Industry subsector too narrow | Try a broader subsector during the trend-scout selection step |
| Candidate scores all low | Research signals are weak or mixed for this horizon | Accept candidates at Act horizon first; Observe-horizon candidates are inherently speculative |
| Investment themes overlap | Too many candidates per dimension | Reduce to the 10–15 highest-scoring candidates before running value-modeler |
| Report sections thin on evidence | Quantitative data not available in web sources | trend-report-investment-theme-writer falls back to qualitative analysis; this is expected for emerging trends |
| Catalog import fails | Project not in `agreed` state | Ensure trend-scout candidates are agreed (`workflow_state: agreed`) before running trends-catalog |
| Dashboard shows stale data | Project files updated outside the workflow | Re-run `/trends-dashboard` — it reads all state from files, not session memory |

---

## Extending This Plugin

cogni-trends accepts contributions in several areas:

- **Industry catalogs** — seed catalogs for new sectors (Healthcare, Energy, Logistics, etc.)
- **Research source integrations** — curated source lists for non-DACH markets (UK, US, APAC)
- **Scoring frameworks** — additional multi-framework scoring dimensions for the trend-generator
- **Market adaptations** — bilingual search architectures for non-DACH markets following `references/architecture-pattern.md`

See [CONTRIBUTING.md](../../cogni-trends/CONTRIBUTING.md) for guidelines.
