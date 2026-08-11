---
name: consult-resume
description: |
  This skill should be used when the user wants to resume, continue, or check
  the status of a cogni-consult engagement across sessions. Trigger on:
  "continue the engagement", "resume the engagement", "engagement status",
  "where was I with the engagement", "what's next for the engagement", "show
  engagement progress", "consult resume", or any session start that references
  an existing cogni-consult engagement — even if the user doesn't say "resume"
  explicitly. Double Diamond phrasing ("resume diamond", "diamond status",
  phase talk like "continue discover") refers to a legacy engagement model no
  longer in the ecosystem; cogni-consult engagements have no
  phases; progress lives in the action-fields WBS.
allowed-tools: Read, Bash, Skill
---

# Engagement Re-entry

Re-enter a cogni-consult engagement: discover what exists, show progress
against the action-fields WBS (fields × deliverables × status), and route to
the most valuable next action. This skill is a read-only orienter — it never
edits engagement state; the only files it writes are the derived front-door
artifacts (`README.md`, `assumptions.md`) regenerated from that state, and every
other write belongs to the skill it routes to.

## Workflow

### 0. Resolve the Interaction Language

Before any user-facing output, resolve the **interaction language** — the
workspace default, overridden by the user's message language — per
`$CLAUDE_PLUGIN_ROOT/references/interaction-language.md`, which owns the
resolution ladder. Conduct the entire conversation in the resolved language.
It is independent of the engagement's `language` field, which is the
deliverable axis. This contract holds on the default path: it does not depend
on an output style being active.

The `description` of a Bash tool call is rendered to the consultant, so it is
user copy — write it in the interaction language, outcome-shaped, at most 6
words, with no script, file, or skill names, and never derived from the
script's filename or header comment. Worked pair:
`Discover cogni-consult engagements` → `Laufende Engagements holen`.
Section (f) of `$CLAUDE_PLUGIN_ROOT/references/user-facing-output.md` owns
these five constraints — edit them there, then mirror the change here.

The register that output follows — scope, state lexicon, table rules, step
announcements — is `$CLAUDE_PLUGIN_ROOT/references/user-facing-output.md`;
table cells and headers are user copy too, not an exemption.

### 1. Discover Engagements

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/discover-projects.sh --json
```

When discovery returns **zero engagements**, there is nothing to resume here.
If the user was working a phase-based (Double Diamond) engagement, that engagement
model is no longer part of the ecosystem — those engagements live in git history.
Otherwise recommend scaffolding
an engagement and dispatch `Skill("cogni-consult:consult-setup")`, then stop —
setup owns scaffolding and the knowledge-base binding.

### 2. Select the Engagement

- **One engagement** → select it silently.
- **Multiple, and the user named one** → fuzzy-match the named name or slug
  against discovery and select it directly; confirm only when the match is
  ambiguous.
- **Multiple, and the user named none** → output the full engagement
  list, rendered as the table below, and stop for the
  user's explicit choice. Never silently select or infer an engagement in this
  case. The active git branch, working-tree / uncommitted changes, and recent
  commit history are **not** authorized selection signals — they must never
  substitute for the user's choice or override the list-and-stop obligation.
  Only a name or slug explicitly named in the user's message may skip the list.

Render that list as the table defined in
`$CLAUDE_PLUGIN_ROOT/references/engagement-list-rendering.md` — never as raw
field names — which is authoritative for its columns, padding, sort, five-row
cap and overflow line, the „alle“ re-render, the reply-index rule, the
`scope_state` name-cell suffix, the `last_activity` resolution, the
`Fortschritt` column and the per-displayed-row status read that fills it, and
both language seeds. Read it before rendering. The list-and-stop obligation
above still holds. Step 3's status read for the picked engagement is separate
from that column's per-row read and unaffected by it — Step 3 re-runs it fresh,
per **Derived, not stored** below.

### 3. Read the Engagement Status

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/engagement-status.sh <engagement-path>
```

`<engagement-path>` is the `path` field from discovery. The script derives
the rollups at read time: `scope_state`, an engagement-level `personas_gate`
(`satisfied` once a scope-seeded persona or a `.gate-waiver` marker exists,
else `pending`), and per field its `state` plus each deliverable's `state`,
`dt_stage`, `producing_route`, and `persona_review`.
Never suppress `warnings[]` (an unreadable field manifest is a problem for
the consultant to see, not to paper over), but render its state as its
display string, not the raw value.

### 4. Present the Dashboard

Lead with the key question, then one table row per action field, rendered per
`$CLAUDE_PLUGIN_ROOT/references/engagement-dashboard-rendering.md`, which is
authoritative for the table's columns, row order, action-field and deliverable
naming, the completion counts, the next-deliverable and `chosen_framework`
display rules, and both language seeds. Read that file before emitting the
table.
Keep it to this one table — the deep WBS view (planning deliverable sets,
splitting fields) belongs to `consult-action-fields`, not here.

**Offer the visual dashboard.** After the text table, offer the consultant a
themed, browsable HTML view of the same status via `/cogni-consult:consult-dashboard`
(action-field WBS, deliverable states, design-thinking stages, persona-review
coverage). When the engagement already has `output/design-variables.json` from a
prior dashboard run, regenerate and open it without a theme prompt by
delegating to the `consult-dashboard-refresher` agent with
`engagement_dir: <engagement-dir>` and `plugin_root: $CLAUDE_PLUGIN_ROOT`. This
stays read-only — the agent runs the read-only generator; it never edits
engagement state.

**Point at the project plan (only when scheduling data exists).** When the engagement
carries a schedule, surface it here as a one-line read-only pointer. Detect it cheaply:
a `<engagement-dir>/project-plan.md` already exists, **or**
`python3 $CLAUDE_PLUGIN_ROOT/scripts/deliverable-graph.py "<engagement-dir>" schedule`
returns a non-empty `data.schedule[]` with at least one scheduled (not `unscheduled`)
entry. When it does, name the **next critical-path deliverable** — the first
not-yet-`complete` deliverable whose key is in `data.critical_path[]` — and offer
`/cogni-consult:consult-project-plan` to (re)render `project-plan.md` (phase timeline +
critical path + optional gantt). When no deliverable carries scheduling fields (the
`schedule` read is empty or every entry is `unscheduled`), say nothing — this pointer
degrades silently and the dashboard above is unchanged. It is informational only: do not
add it as a branch in the Step-5 next-action ladder — the project plan is a derived
read model, not a competing recommendation.

**Milestone README refresh.** On every re-entry, also run
`python3 $CLAUDE_PLUGIN_ROOT/scripts/generate-engagement-readme.py "<engagement-dir>"`
automatically (no prompt) to refresh the engagement-root README front door —
unconditional (unlike the theme-gated dashboard offer above, no
`output/design-variables.json` needed) and non-fatal: on failure, warn and
continue. An engagement that predates the README front door gains one here on
its next re-entry — no migration step needed; a hand-authored root `README.md`
is never overwritten (the generator refuses when its marker footer is absent —
that refusal is the same non-fatal warning case). The README is a derived front-door
artifact regenerated from engagement state, not engagement state itself, so the
read-only contract over `consult-project.json`, `field.json`, personas, and logs
holds.

**Assumption register refresh.** On every re-entry, also run
`python3 $CLAUDE_PLUGIN_ROOT/scripts/register-generator.py "<engagement-dir>"`
automatically (no prompt) to regenerate the engagement-root `assumptions.md`
register — the human-browsable table of every registered assumption's value,
provenance, status, and `used_by[]` backlinks — from `assumptions.json`.
Unconditional and non-fatal: the generator's `load_assumptions` is fail-soft (a
missing, empty, or malformed registry degrades to an empty register, never an
error), and on any failure, warn and continue. Back-fill and no-overwrite
behave as for the README above: a populated `assumptions.json` gains a register
on its next re-entry, and a hand-authored `assumptions.md` is never overwritten.
Like the README it is a derived read model, not engagement state itself, so the
read-only contract above holds.

**Point at the register (only when it is non-empty).** When the generator returns
`success: true` with `data.assumptions_count > 0`, surface a one-line read-only
pointer to the regenerated `assumptions.md` — mirroring the project-plan pointer
above so the refresh is visible rather than silent (e.g. *"Assumption register:
`assumptions.md` (N registered) — value, provenance, and `used_by[]` backlinks"*).
When the count is `0` (no registered assumptions) or the generator warned, say
nothing — the pointer degrades silently. It is informational only: like the
project-plan pointer, do not add it as a branch in the Step-5 next-action ladder.

> **Strategy Advisor voice** — this plugin ships one advisory output style: **Strategy Advisor** (answer-first, MECE options), language-neutral, so it renders in the resolved interaction language. Enable it from the `/config` output-style picker; it's opt-in and fixed at session start, so set it now or `/clear` after.

### 5. Recommend the Next Action

Branch on the derived state, first match wins, and say *why*:

- **`scope_state` is not `complete`** → the WBS doesn't exist yet; recommend
  `consult-scope` ("scope not done — let's frame the key question and derive
  the action fields").
- **A field's `state` is `unreadable`** → its manifest is broken, not
  unplanned; the surfaced warning *is* the recommendation — fix or inspect
  that `field.json` before any routing.
- **A field has an empty `deliverables[]`** (and is not `unreadable`) → the
  WBS has an unplanned container; recommend `consult-action-fields` to plan
  that field's deliverable set.
- **Any deliverable carries `lineage_status.status: "stale"`** → an upstream
  deliverable it depends on changed, so its artifact is out of date. Stale work
  outranks both in-progress and pending work here: finishing fresh work on a
  stale foundation wastes it, so refreshing comes first. Recommend refreshing
  the stale set in **topological order — upstream before dependents**: run
  `deliverable-graph.py <engagement-dir> refresh-order` and recommend the
  layer-0 deliverable(s) first (they depend on nothing else that is stale, so
  they are safe to refresh now); a deeper-layer deliverable is refreshed only
  once the layer above it has been. Route to `knowledge-refresh` for the
  research, then `consult-design-thinking` to re-run that deliverable's loop.
  Never recommend refreshing a dependent before its upstream dependency.
- **`scope_state` is `complete` AND `personas_gate` is `"pending"`** (no
  scope-seeded persona and no `.gate-waiver` marker yet) → the first
  design-thinking deliverable's empathize and test stages would run on degraded
  fallback, and the hard gate blocks a not-yet-started deliverable until personas
  are seeded. Recommend `consult-personas` to seed acting personas from the
  scope's Stakeholder dimension (or waive to defaults) *before* recommending any
  deliverable work. Placed after the scope/unreadable/stale checks so it never
  masks a broken manifest or a stale set, but ahead of the pending-deliverable
  recommendation so it front-runs the first deliverable. Read `personas_gate`
  from the `engagement-status.sh` rollup already fetched above; this stays a
  read-only route — never write persona state here. (This gate is naturally
  once-per-engagement: once satisfied it stays satisfied, and it never fires
  for an `in-progress` or resumed deliverable, which the branches below own.)
- **A deliverable is `in-progress`** → resume it where it stands; recommend
  `consult-design-thinking` naming the field, the deliverable, and its
  `dt_stage` ("Competitor map is mid-ideate — pick the loop back up there").
- **A deliverable is `complete` but its `persona_review` is `pending` or
  `in-progress`** → the acting-persona challenge hasn't closed; recommend
  `consult-personas` to run (or finish) the challenge pass.
- **A deliverable is `pending`** → start the next one; recommend
  `consult-design-thinking` (or the deliverable's own `producing_route` when
  it names a different skill).
- **Everything is `complete`** → say so — the engagement is complete by
  derivation — and offer `consult-action-fields` to extend the WBS if the
  consultant wants to add fields or deliverables. Per-deliverable publish/render
  next steps follow the publish offer below (read each `complete` deliverable's
  `publish[]` and offer `consult-publish` or the Claude Design handoff) — surface
  them only as elect-only offers, never as a standing menu item.

Four further offers surface only when the consultant's request or a deliverable's
state calls for them — not as standing menu items:

- **The consultant names an already-`complete` deliverable to revisit or
  modify** (a rework request) → offer to reopen it and route to
  `consult-design-thinking`, naming the field, the deliverable, and the stage
  the rework should re-enter (often `define` or `ideate`); mention that the loop
  will first ask what the rework should improve and record it as a
  `rework-intent` entry. That intent capture, like the reopen write itself —
  the `complete` → `in-progress` Edit and the up-front cascade-stale of its
  downstream dependents — is owned by `consult-design-thinking`'s Open-the-Loop
  step, so resume stays read-only; it routes, it does not ask and does not write.
- **A deliverable's stored `chosen_framework` is `null`** (a legacy deliverable
  created before a framework was chosen) and the consultant wants to assign one
  → offer to set it inline rather than sending them on a separate
  `consult-action-fields` round-trip. "Inline" means the offer surfaces here in
  the recommendation flow; the actual `field.json` write is delegated to
  `consult-action-fields` (which owns the deliverable manifest), so resume's
  read-only contract holds. Surface this only when the framework gap is
  relevant to the next action — never as blanket nagging across every legacy
  deliverable.
- **A deliverable is `complete` with a non-`null` `chosen_framework` whose
  conformance hasn't been verified** → offer a **framework-adherence review**:
  dispatch the `consult-framework-adherence-reviewer` agent
  (`engagement_dir`, `field_slug`, `deliverable_slug`, `plugin_root`,
  `interaction_language`) to score
  the finished artifact against its stored framework's structure signature and
  report drift with concrete findings. This is a structural-conformance axis
  distinct from the persona-challenge (Test) pass, so it complements rather
  than duplicates `consult-personas`. The reviewer is read-only — it reports
  drift, it never rewrites the artifact — so resume stays read-only too;
  acting on a finding is a separate `consult-design-thinking` rework. Surface
  this only when the conformance question is relevant to the next action, not
  as a standing audit of every complete deliverable.
- **A `complete` deliverable (its `persona_review` closed) is unpublished, or
  published but not yet rendered** → offer the publish / render next step from
  its `publish[]` lineage, even before the whole engagement is complete: an
  empty/absent `publish[]` → offer `/cogni-consult:consult-publish` to produce a
  presentation-ready brief; a populated `publish[]` → name its `brief_path`(s)
  and point the consultant to hand them to Claude Design (claude.ai/design) to
  render. This is read-only over `publish[]` — `consult-publish` owns brief
  production; resume only routes. Surface it only when the consultant elects it
  or names that deliverable, never as a standing menu item.

Recommend one action, not a menu. On the consultant's confirmation, dispatch
the named skill via `Skill(...)` with the engagement path as the in-session
handoff (the target skills skip rediscovery on handoff).

## Important Notes

- **Read-only**: this skill never writes `consult-project.json`,
  `field.json`, personas, or logs — state writes belong to the routed
  skills. See `$CLAUDE_PLUGIN_ROOT/references/data-model.md` for ownership.
- **Derived, not stored**: field and engagement completion are computed at
  read time by `engagement-status.sh`; never trust a stale summary over a
  fresh script run.
- **One recommendation**: the dashboard orients, the recommendation commits —
  a single next action with its reason beats a list of options.
