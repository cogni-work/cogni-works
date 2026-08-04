---
name: projects-dashboard
description: |
  This skill should be used when a partner or consultant wants a readable
  snapshot of a cogni-projects portfolio for a partner meeting — staffing
  coverage per project, at-risk projects, and portfolio value by strategic
  impact — rather than reading raw entity files. Trigger on: "projects
  dashboard", "portfolio dashboard", "partner-meeting dashboard", "show me the
  project portfolio", "portfolio health", "staffing coverage", "which projects
  are at risk", or any request to review the project portfolio at a glance —
  even if the user does not say "dashboard" explicitly.
allowed-tools: Read, Bash, Glob, Grep
---

# Projects Dashboard

Render a partner-meeting snapshot of a cogni-projects portfolio: every project
with its staffing coverage and a health flag, plus an aggregate view of
portfolio value by strategic impact. The dashboard is a **read-only** view over
the consultant, project, and assignment records that `projects-setup` and
`projects-entities` produce.

## Core concept

The dashboard reads a **portfolio** — one `cogni-projects/<portfolio-slug>/`
directory rooted by `projects-portfolio.json` — and derives, from the entity
records (their field contract lives in
[`../../references/data-model.md`](../../references/data-model.md)):

- **Staffing coverage** per project: filled-vs-open roles plus a one-word
  health flag. Only a live commitment covers a role — a finished assignment
  releases it, so a role can reappear as open with no edit to the project.
  Two flags read alike but are not: `no open roles` means the project needs
  nobody right now, while `staffing unknown` means its coverage cannot be read
  at all — never narrate it as covered.
  The headline figure (`data.open_roles` and the `Open roles` tile) counts
  unfilled roles on non-closed projects only — closed work is delivered or
  lost, not live demand — so it matches the set `projects-staff` shortlists. A
  `prospective` project still counts, so read it as live-and-pipeline demand,
  not active-only. The closed project stays in the table with its `closed`
  flag and still counts toward the `Projects` tile, so a shrinking open-role
  total is not a missing project.
- **Portfolio value**: projects grouped by `strategic_impact` (1–5), so the
  high-impact work is visible at a glance.
- **Utilization**: the envelope carries an average-allocation figure and a
  count of fully allocated consultants. The average covers only consultants
  who declare `allocation_pct` — the rest are dropped silently, so the
  envelope's `consultants` count is not its denominator; caveat the figure
  rather than calling it portfolio-wide. With none declared at all,
  `data.avg_allocation` is `null` — read as unknown, not `0%`.

Role labels are free strings, so when a project lists `open_roles`, a label an
assignment names that no entry matches is surfaced as a warning rather than
silently mis-counted — but only then: a project with absent or empty
`open_roles` yields no such warning, so a quiet warnings list is not proof the
labels line up.

## Workflow

### Step 1: Find the portfolio

Locate the target `cogni-projects/<portfolio-slug>/` directory (the one holding
`projects-portfolio.json`). If the user named a portfolio, use it; if only one
portfolio exists, use it; otherwise list the candidates and ask which one.

### Step 2: Render the dashboard

Run the renderer against the portfolio directory:

```bash
python3 "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/*/cogni-projects/*/ 2>/dev/null | head -1)}/scripts/render-dashboard.py" "<portfolio-dir>"
```

The script writes a self-contained `output/dashboard.html` inside the portfolio
directory and prints a `{"success", "data", "error"}` envelope whose `data.path`
is the written file.

**When `success` is `true`:** if `data.partial` is `true`, `data.warnings` lists
what was missing or mismatched — relay those (Step 4). `partial` is set by *any*
warning, including a non-substantive one such as an unreadable
`--design-variables` file, so check what the warnings actually say before
describing the portfolio data itself as incomplete. The `data` envelope also
carries `projects_detail` (per project: `name`, `client`, `status`, `impact`,
`roles_total`, `roles_filled`, `health_label`, `health_sev`, plus an
`open_roles` **list** of that project's still-unfilled role labels — not the
portfolio integer `data.open_roles`) and `value_by_impact` — Step 4 reads these
to narrate the snapshot.

**When `success` is `false`:** the render did not run at all — read `error`. This
is the environment-level failure branch (missing portfolio directory, missing
`projects-portfolio.json`, unwritable `output/`), distinct from the per-entity
degradation above. A missing `projects-portfolio.json` means the directory is
not an initialized portfolio: point the user at `projects-setup` rather than
retrying the render.

### Step 3: Open it

Report `data.path` as the deliverable, then offer to open it as a convenience:

```bash
open "<data.path>"      # macOS
xdg-open "<data.path>"  # Linux
```

A failure here is cosmetic — the dashboard is already written to `data.path`.

### Step 4: Narrate the snapshot

The dashboard's purpose is to be explained to a partner, so close with a few
plain lines — do not stop at reporting the path. Read these from the renderer's
stdout envelope only; do not re-open `output/dashboard.html` and do not
re-derive anything from the entity records:

- **Counts** — `data.projects` projects and `data.consultants` consultants,
  with `data.open_roles` roles still open across the portfolio.
- **At-risk projects, by name** — from `data.projects_detail`, name each project
  whose `health_sev` is `risk` or `warn` (quote its `health_label`). If no
  project carries `risk` or `warn`, say no project is currently flagged. Either
  way, name any project whose flag is `closed` or `no open roles` rather than
  folding it into a staffing claim — neither means the project is fully staffed.
- **Where the strategic-impact weight sits** — from `data.value_by_impact` (a
  map of impact tier `"1"`–`"5"`, string keys in the JSON envelope, to project
  count), point to the tier(s) carrying the most projects. Projects whose
  `strategic_impact` is missing or outside 1–5 are omitted (they surface as a
  warning and carry `impact: null` in `projects_detail`), so these counts need
  not sum to `data.projects`. When no project declares a valid impact the map is
  all zeros — a meaningless five-way tie, not a real distribution to point at.
- **Warnings** — if `data.partial` is `true`, relay `data.warnings` so the
  partner knows which records to fix.

Read `health_sev`, `health_label`, and the impact tiers as the renderer reports
them — never restate a flag's trigger condition or threshold. `render-dashboard.py`
stays the source of truth for how those are computed (see Notes below).

Illustrative shape only — take every number, name, and label from the envelope,
never from this example:

> Six projects, nine consultants, eleven roles still open. Three projects are
> flagged: **Harbour Replatform** is `unstaffed`, **Meridian Rollout** is
> `2/3 roles open`, **Tallow Freight** is `staffing unknown`. **Southbank
> Archive** carries `closed`. The strategic weight sits in tier 5 (three
> projects), with nothing at tier 1. One warning, relayed as reported:
> *project Tallow Freight has no open_roles — staffing status unknown*.

## Notes

- **The renderer is the source of truth for the flags and aggregates.**
  `scripts/render-dashboard.py` computes every health flag, the strategic-impact
  grouping, and the utilization figures; this skill explains what the output
  *means*, not how it is computed. To change a threshold or a flag rule, change
  the script, not this skill.
- **Read-only.** The renderer never writes `projects-portfolio.json` (only
  `projects-entities` does, via `register-entity.py`) and never touches
  `.metadata/`. Re-running only rewrites `output/dashboard.html`.
- **Partial snapshots are expected mid-authoring.** Any of these is reported in
  the warnings list, not treated as an error: a project without a
  `strategic_impact`, a project that omits `open_roles`, an entity whose
  `status`, role label, or `open_roles` entry is not text, an entity whose
  `status` is text but not lowercase, an assignment whose `project` is absent,
  unusable, or names no project in the portfolio, or an entity file that cannot
  be read or decoded. A non-text value — `status: 2026`, `role: 2`, or
  `open_roles: [2]` — is read as a number, then coerced back to text. A status
  authored in mixed case — `status: Closed` — is read case-insensitively and
  reported normalized. Both sides of the role comparison are coerced, so a
  numeric role still matches its numeric `open_roles` entry and still counts as
  filled. An unresolved `project` is named whatever the assignment's status — a
  completed assignment pointing at a deleted project is still a broken
  reference — and coverage is unchanged. The non-text warning and the
  not-lowercase warning both say to fix the record, not that the coverage
  figure or flag beside it is wrong. One bad record never costs the rest of the
  portfolio.
- **Theming is optional.** The dashboard renders with a built-in palette;
  pass `--design-variables <path.json>` to override colors when a themed look is
  wanted.
