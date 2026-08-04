# cogni-projects

**Plugin guide** — for canonical positioning see the [cogni-projects README](../../cogni-projects/README.md).

> **Incubating** (v0.0.x) — skills, data formats, and workflows may change at any time.

---

## Overview

cogni-projects is the partner-facing steering layer for a consulting firm's project portfolio. It holds one self-contained directory of consultants, projects, and assignments, and answers the three questions partners otherwise carry in their heads: who is rolling off next month, who fits this mandate, and which assignment actually moves the firm's strategy forward.

The plugin is deliberately narrow. It does not run engagements — that is cogni-consult's job — and it does not model your service offering — that is cogni-portfolio. cogni-projects models *people against work*: availability, profile fit, and strategic impact, scored deterministically so a staffing decision can be defended in a partner meeting rather than justified from memory.

Four skills have shipped: portfolio scaffolding, entity authoring, the staffing match engine, and a read-only partner-meeting dashboard. The backfilling recommender arrives in a later release.

---

## Key Concepts

| Term | What it means in practice |
|------|--------------------------|
| **Portfolio** | One `cogni-projects/<portfolio-slug>/` directory rooted by a `projects-portfolio.json` manifest — the unit everything else writes into |
| **Consultant** | A person record: seniority, skills, availability windows, and the profile the matcher scores against |
| **Project** | A mandate record with open roles, each role naming the skills and seniority it needs |
| **Assignment** | A consultant staffed to a project role for a date range — the link between the two entity types |
| **Open role** | A project role with no active assignment covering it; the unit the staffing engine ranks candidates for |
| **Strategic impact** | A per-project weight that lets staffing optimize for firm strategy rather than raw utilization |
| **Staffing recommendation** | The last-run scorer output — a ranked candidate list per open role, overwritten each run |

### Why the manifest is written last

`portfolio-init.sh` creates the directory skeleton first and writes `projects-portfolio.json` last, so the manifest's existence is a reliable "fully initialized" marker. An interrupted scaffold (directories made, manifest never written) is repairable by simply re-running; a completed portfolio returns a clean "already initialized" no-op and overwrites nothing.

---

## Getting Started

Scaffold a portfolio:

```
/cogni-projects:projects-setup
```

You will be asked for a portfolio name and a slug. Name it "Demo Advisory", accept the derived slug `demo-advisory`, and confirm. You get:

```
cogni-projects/demo-advisory/
├── projects-portfolio.json    Root manifest (identity + entity lists)
├── consultants/
├── projects/
├── assignments/
└── .metadata/                 Append-only logs
```

The manifest starts with portfolio identity and three empty entity lists:

```json
{
  "slug": "demo-advisory",
  "name": "Demo Advisory",
  "language": "en",
  "consultants": [],
  "projects": [],
  "assignments": [],
  "workflow_state": { ... }
}
```

Run the command a second time — it reports the portfolio is already initialized and changes nothing. That idempotency is the point: setup is safe to re-run at any time.

From there the normal sequence is authoring entities, then staffing, then rendering the dashboard.

---

## Capabilities

### `projects-setup` — Initialize a portfolio

Scaffolds the portfolio directory and writes the root manifest. This is the entry point for all portfolio work — every other skill expects a manifest to exist and will point you here if one does not.

Trigger it with any request to begin structured consultant/project/staffing work, even without the word "setup":

> Set up a projects portfolio for my advisory practice

### `projects-entities` — Author and register records

Authors one consultant, project, or assignment record and registers it in the manifest. Each write runs structural validation — frontmatter fields against the entity schema, and for assignments, referential integrity against the consultant and project the assignment names.

Registration is a slug-keyed upsert, so re-authoring the same consultant updates the existing record rather than duplicating it, and every write appends to `.metadata/execution-log.json`.

> Add a consultant: Maria Lang, senior manager, available from March, strong in supply-chain and SAP

Author consultants and projects before assignments — an assignment that names a consultant or project slug that does not exist yet fails validation on the reference check.

### `projects-staff` — Rank candidates per open role

The staffing match engine. It reads every project's open roles and scores each available consultant on three axes — availability against the role's date range, profile fit against the role's required skills and seniority, and the project's strategic impact — then writes a ranked shortlist per role to `.metadata/staffing-recommendations.json`.

Scoring is deterministic (`staffing-score.py`), which is what makes the output defensible: the same portfolio produces the same ranking, and the per-axis contributions are visible rather than buried in a single opaque number.

> Who should I put on the Nordics ERP rollout?

Note that `staffing-recommendations.json` is a snapshot, not a log — each run overwrites it. The append-only history lives in `.metadata/staffing-log.json`, whose `matches[]` array gains one record per run.

### `projects-dashboard` — Partner-meeting snapshot

Renders a read-only HTML snapshot of the portfolio: staffing coverage per project, at-risk projects (open roles with no strong candidate or imminent start), and portfolio value grouped by strategic impact.

The skill is strictly read-only — it holds no write tools and never mutates entity data, so it is safe to run mid-meeting.

> Show me the project portfolio — which projects are at risk?

---

## Data Model

A portfolio is one directory. The manifest holds identity plus the three entity lists; per-entity records live in their own directories; `.metadata/` holds append-only logs plus the staffing snapshot.

```
cogni-projects/<portfolio-slug>/
├── projects-portfolio.json    slug, name, language, timestamps, entity lists, workflow_state
├── consultants/               one record per consultant
├── projects/                  one record per project (with open roles)
├── assignments/               consultant → project role, with date range
└── .metadata/
    ├── execution-log.json     append-only: every entity write
    ├── staffing-log.json      append-only: {"matches": [...]} one entry per staffing run
    ├── decision-log.json      append-only: staffing decisions
    └── staffing-recommendations.json   last-run scorer output (overwritten each run)
```

Full entity schemas — consultant, project, assignment, plus naming and validation rules — live in [`cogni-projects/references/data-model.md`](../../cogni-projects/references/data-model.md).

---

## Integration Points

### Upstream — nothing feeds cogni-projects yet

cogni-projects is standalone at this stage. Consultant and project data is authored directly through `projects-entities` rather than imported from another plugin.

### Downstream — nothing consumes it yet

The portfolio directory is the shared substrate for the plugin's own skills and for the backfilling recommender that lands later.

### Planned bridges

Two cross-plugin bridges are on the roadmap but not yet built:

- **cogni-consult** — an engagement in cogni-consult and a project in cogni-projects describe the same client work from two angles (delivery structure vs. staffing). A bridge would let a scoped engagement seed a project record.
- **cogni-portfolio** — cogni-portfolio models what the firm sells; cogni-projects models who delivers it. Linking a project to the propositions it delivers would let staffing weight strategic impact against portfolio strategy rather than a hand-set number.

Until those land, treat cogni-projects as a self-contained tool.

---

## Common Workflows

### Workflow 1: Stand up a portfolio from scratch

1. `/cogni-projects:projects-setup` — scaffold the directory
2. Author consultants: "Add a consultant: …" (repeat per person)
3. Author projects with their open roles: "Add a project: …"
4. Author any existing assignments so the matcher knows who is already committed
5. `/cogni-projects:projects-dashboard` — confirm the portfolio reads correctly

Author consultants and projects before assignments, so the reference check passes.

### Workflow 2: Staff an open role

1. Confirm the project's open roles are current (re-author the project if a role changed)
2. Run the match engine: "Who should I put on the Nordics ERP rollout?"
3. Read the ranked shortlist — per-axis scores show *why* each candidate ranked where they did
4. Author the assignment for the chosen consultant
5. Re-run the dashboard — staffing coverage for that project should now reflect the new assignment

### Workflow 3: Prepare for a partner meeting

1. `/cogni-projects:projects-dashboard`
2. Review at-risk projects — open roles with no strong candidate are the agenda
3. For each, run the match engine to bring a shortlist into the room rather than a question

---

## Troubleshooting

**"Portfolio already initialized"** — this is the expected no-op from re-running `projects-setup`. Nothing was overwritten. If you genuinely want a second portfolio, run setup with a different slug.

**An assignment fails validation** — the assignment names a consultant or project slug that is not registered in the manifest. Author the referenced entity first, then re-author the assignment.

**A consultant never appears in a shortlist** — check their availability window against the role's date range. The availability axis gates the other two; a consultant with no overlap will not surface regardless of profile fit.

**Scripts fail with a JSON parse error** — every script returns `{"success", "data", "error"}`. Read the `error` field; the scripts are stdlib-only bash + python3, so a failure is usually a malformed entity file rather than a missing dependency.

Run the regression suites directly if you suspect a script-level problem:

```bash
bash cogni-projects/tests/test_portfolio_init.sh
bash cogni-projects/tests/test_register_entity.sh
bash cogni-projects/tests/test_validate_entities_refs.sh
bash cogni-projects/tests/test_staffing_score.sh
bash cogni-projects/tests/test-render-dashboard.sh
```

---

## Extending This Plugin

cogni-projects is open-source under Apache-2.0 and early enough that structural contributions are still cheap. The most useful areas:

- **Scoring axes** — availability, profile fit, and strategic impact cover the common case. Firms that staff against utilization targets, travel constraints, or client-continuity rules would benefit from additional axes in `staffing-score.py`.
- **Entity schema extensions** — the consultant schema is deliberately minimal. Certifications, language proficiency, and industry history are natural additions; see `references/data-model.md`.
- **The planned cross-plugin bridges** — a cogni-consult or cogni-portfolio bridge is the highest-leverage contribution, since it turns three separate models of the same client work into one.

Conventions to follow: scripts return `{"success", "data", "error"}` JSON and stay stdlib-only (bash + python3, no pip); skill names carry the `projects-` domain prefix; the portfolio manifest is the source of truth.

See [CONTRIBUTING.md](../../CONTRIBUTING.md) and the [plugin development guide](../contributing/plugin-development.md) for guidelines.
