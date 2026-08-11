---
name: projects-backfill
description: |
  This skill should be used when a consultant is leaving a project and the
  partner needs both halves of the resulting gap answered: which open roles the
  freed consultant should move to next, and who replaces them on the role they
  vacated. Trigger on: "roll-off", "rolls off", "rolling off", "is coming off",
  "backfill", "backfill this role", "who replaces", "find a replacement for",
  "next assignment", "what should they work on next", "where do we put them
  next", "fill the vacated role", "re-staff this role", "minimize bench time",
  or any request to move a consultant between projects on a cogni-projects
  portfolio — even if the user does not name the portfolio.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Projects Backfill

Answer a roll-off from both sides at once. When a consultant comes off a project,
two questions open together: **where does that consultant go next**, and **who
takes the role they left**. This skill answers both from one scorer run, so a
partner can move people between projects with minimal bench time and defend each
move with the same visible sub-scores the staffing engine produces.

The ranking itself is not recomputed here. `scripts/staffing-score.py` — the same
deterministic scorer `projects-staff` uses — produces every score, and this skill
selects, filters, and reorders its output. Reusing the scorer is deliberate: a
second ranking implementation would drift from the first, and two contradictory
shortlists for the same portfolio is worse than none.

## Core concept

One scorer run yields a candidate x role matrix for the whole portfolio. A
roll-off is two different reads of that same matrix:

- **Direction (a) — the freed consultant.** Hold the consultant fixed and vary
  the role: walk every open role in the portfolio and keep the rows where the
  departing consultant appears as a candidate. This produces their ranked
  next-assignment options.
- **Direction (b) — the vacated role.** Hold the role fixed and vary the
  consultant: take the vacated role's candidate list and drop the departing
  consultant. This produces the replacement shortlist.

On top of the scorer's own ranking this skill applies **one exclusion the scorer
does not make**: a consultant whose `allocation_pct` is `100` is already fully
committed and must never be proposed. Read the section below before assuming the
scorer covers this — it does not.

### What the scorer excludes, and what it does not

The scorer drops a consultant from a project's ranking **only** when their
`available_from` / `available_until` window has zero overlap with the project
window. Those consultants never appear in `candidates[]` at all; they surface
only as the per-role `excluded_count`, and are never proposed.

Full allocation is a different matter. A consultant at `allocation_pct: 100`
still overlaps the project window, so the scorer keeps ranking them — their
capacity merely lowers the availability sub-score. Proposing them would be wrong.
Apply the filter in Step 3 explicitly; do not treat `excluded_count` as if it
already covered full allocation.

The field contract for the records these read lives in
[`../../references/data-model.md`](../../references/data-model.md).

## Workflow

### Step 1: Locate the portfolio and pin the roll-off

Find the portfolio directory the user means. If they name a slug, use
`cogni-projects/<portfolio-slug>/`. Otherwise glob
`cogni-projects/*/projects-portfolio.json` and, when more than one portfolio
exists, ask which one. If none exists, direct the user to
`/cogni-projects:projects-setup` — this skill steers an existing portfolio, it
does not scaffold one.

Then pin three inputs: the **departing consultant** slug, the **project** they
are leaving, and the **role** they vacate. Ask for whichever the user did not
supply rather than guessing.

Resolve each against the portfolio before running anything. When a named
consultant, project, or role does not exist in the portfolio, report the
unresolved name as a portfolio-data gap and stop — the fix is to author or
correct the record with `/cogni-projects:projects-entities`, not to proceed
against a guess.

The vacated role is frequently **not** present in the project's `open_roles` at
this point: a role only becomes open once someone declares it open, and a
roll-off is usually what makes it open. Treat this as the expected case, not an
error. Direction (b) needs the role to be open in order to have a candidate list,
so instruct the user to add it to the project's `open_roles` via
`/cogni-projects:projects-entities` and re-run; alternatively, deliver direction
(a) alone and say plainly that the replacement half is pending that edit.

### Step 2: Run the scorer

Run `staffing-score.py` against the portfolio directory and capture its JSON:

```bash
python3 "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/*/cogni-projects/*/ 2>/dev/null | head -1)}/scripts/staffing-score.py" "cogni-projects/<portfolio-slug>"
```

It returns `{"success", "data", "error"}` (exit 0 ok / 1 domain failure / 2 usage
or unexpected failure). On `success: false`, surface `error` to the user and
stop. A domain failure (exit 1) usually means the portfolio directory or its
manifest is unreadable — but an `error` naming `validate-entities.py` instead
means a broken or partial plugin install, not a portfolio-data problem; say so
rather than pointing the user at their entities.

On success, `data.projects[]` holds the non-closed projects, each with an
`open_roles[]` array whose entries carry a `candidates[]` list already ranked by
combined score and a per-role `excluded_count`.

Read the scorer output only. Both `staffing-recommendations.md` and
`.metadata/staffing-recommendations.json` belong to `projects-staff`; consult
them for context if useful, but never write or overwrite either from this skill.

### Step 3: Apply the full-allocation filter

A scorer candidate carries `consultant`, `name`, and `scores` — it does **not**
carry `allocation_pct`. Read that field from the consultant's own record at
`cogni-projects/<portfolio-slug>/consultants/<slug>.md`.

Drop every candidate whose `allocation_pct` is a number `>= 100` from both
directions' output.

Key the filter on the **raw** `allocation_pct` value, never on the scorer's
internal headroom calculation. Headroom returns zero for a present-but-non-numeric
`allocation_pct` as well as for a genuinely full one, so filtering on it would
silently discard a typo as though it were a booked consultant. Instead, treat a
present-but-non-numeric value as a data-quality finding: keep the candidate,
and report the malformed field so someone can fix the record. An absent
`allocation_pct` means no committed allocation is recorded — do not filter it.

**The departing consultant is exempt from this filter in direction (a).** They
are rolling off, so their recorded `allocation_pct` still reflects the assignment
they are leaving; filtering them out would remove the one person the
recommendation exists to place.

State that exemption's limitation in the output rather than hiding it: the
departing consultant's freed capacity is **assumed, not computed**. The scorer
never reads `assignments/` at all, so nothing nets the vacated assignment out of
their recorded allocation. A partner reading the recommendation should know the
freed capacity is taken on faith.

### Step 4: Direction (a) — rank the freed consultant's next roles

Walk `data.projects[].open_roles[].candidates[]` across every project and keep
the entries whose `consultant` equals the departing consultant's slug. Each
surviving entry becomes one row: the project, the role, and that candidate's
sub-scores.

Order the rows by **`candidates[].scores.strategic_impact` descending first**
(equivalently the project-level `strategic_impact_norm` — they carry the same
normalized value), then `scores.combined` descending, then project slug ascending
and role label ascending as the deterministic tiebreak.

Lead with strategic impact deliberately. It is a project attribute, identical for
every candidate within a role, so it cannot discriminate inside one role's
shortlist — but this table compares roles *across* projects, which is the one
ranking where it does discriminate. Sorting on `scores.combined` alone would
silently discard the firm's own priority ordering at the exact moment it becomes
meaningful. Render both columns so a partner can re-read the table by fit alone.

Key the missing-value decision on the **raw** `data.projects[].strategic_impact`
being null, not on the normalized score — the normalized value is `0.0` for both
an absent value and a raw `1`, so it cannot distinguish "missing" from
"tactical". Render an em dash (`—`) in the Strategic impact column for those
rows; they tie at `0.0` with genuinely tactical projects, and the project-slug
tiebreak settles the order.

Exclude the role the consultant is vacating from their own next-assignment list.

When the list is empty after filtering, say so and name the reason — usually no
open role anywhere overlaps the consultant's availability window. That is a
portfolio-data gap, not a scoring failure.

### Step 5: Direction (b) — rank replacements for the vacated role

Take the vacated role's `candidates[]` list. Drop the departing consultant's own
entry, keyed on `candidates[].consultant` matching their slug. Apply the
full-allocation filter from Step 3 — with **no** exemption here, since a fully
committed consultant genuinely cannot take the role.

Preserve the scorer's within-role ordering for the survivors; that ordering is
already the combined-score ranking and re-sorting it would diverge from
`projects-staff` for the same role.

When the candidate list is empty after exclusions, report that explicitly rather
than rendering an empty table, and give the count that was excluded for no
availability overlap alongside the count dropped for full allocation — the two
have different fixes.

### Step 6: Write the backfill artifact

Render both directions into
`cogni-projects/<portfolio-slug>/backfill-recommendations.md`, and write the
selected raw JSON alongside it at
`cogni-projects/<portfolio-slug>/.metadata/backfill-recommendations.json`.

Give that file a fixed shape so a later dashboard can read it without sniffing:
an object with `portfolio`, `departing_consultant`, `vacated_project`,
`vacated_role`, `next_assignments[]` (the direction (a) rows, in rendered order)
and `replacements[]` (the direction (b) rows, in rendered order), each row
carrying the candidate's `consultant`, `name`, and `scores` object copied
unchanged from the scorer plus the row's `project` and `role`. Copying `scores`
verbatim keeps the JSON and the markdown provably the same numbers.

```markdown
# Backfill — <consultant name> off <project name>

## Next assignments for <consultant name> (`<slug>`)

| Rank | Project | Role | Strategic impact | Availability | Profile fit | Combined |
|------|---------|------|------------------|--------------|-------------|----------|
| 1 | <project> | `<role>` | 0.75 | 0.84 | 0.53 | 0.70 |

_Freed capacity is assumed, not computed: the recorded allocation still includes
the assignment being left._

## Replacements for `<role>` on <project name>

| Rank | Consultant | Availability | Profile fit | Strategic impact | Combined |
|------|-----------|--------------|-------------|------------------|----------|
| 1 | <name> (`<slug>`) | 0.80 | 0.61 | 0.75 | 0.71 |

_<n> excluded for no availability overlap; <m> dropped as fully allocated._
```

Show the sub-scores separately in both tables. The per-factor breakdown is what a
partner defends the move with — never collapse it to one opaque number.

### Step 7: Append a run record

Record the run in `cogni-projects/<portfolio-slug>/.metadata/backfill-log.json`,
an object with a `backfills` array. The portfolio scaffolder seeds only the
execution, staffing, and decision logs, so this file will usually be absent on
first run: create it with exactly `{"backfills": []}`, then read-append-write.
Preserve that envelope on every subsequent run — never overwrite it with a bare
array.

Each record captures `portfolio`, `departing_consultant`, `vacated_project`,
`vacated_role`, `ranked_role_count`, `replacement_candidate_count`, and
`artifact_path`. Record no wall-clock value: the log stays reproducible.

### Step 8: Summarize

Report the artifact path, the top next-assignment for the departing consultant,
and the top replacement for the vacated role. Keep it short. Call out any empty
list and its reason, and repeat the assumed-capacity caveat once.

## Notes

- **The scorer is the source of truth for scoring.** This skill selects, filters,
  and reorders; it never re-weights or recomputes. To change how candidates are
  scored, change `scripts/staffing-score.py`, not this skill. No scoring weight
  or constant is redeclared here.
- **The full-allocation filter belongs to this skill, not the scorer.** The
  scorer excludes only on zero availability-window overlap. Keeping the filter
  here leaves `projects-staff` output unchanged.
- **Freed capacity is assumed.** Nothing reads `assignments/` to net a departing
  consultant's vacated allocation out of their recorded `allocation_pct`. Netting
  live assignments is a separate capability.
- **Deterministic output.** Identical portfolio inputs always yield the same
  recommendation: ties break deterministically — consultant slug ascending
  within a role (the scorer's own tiebreak, preserved in direction (b)), and
  project slug then role label ascending across roles in direction (a) — and no
  wall-clock value enters the artifact or the log.
- **`projects-staff` artifacts are read-only here.** This skill writes only its
  own `backfill-*` files.
