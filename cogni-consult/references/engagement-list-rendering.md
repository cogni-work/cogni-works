# Engagement-List Rendering

How `consult-resume` renders the engagement-selection list in step 2, in either
interaction language. This document is authoritative for that table's columns,
sort, cap, re-render, `last_activity` resolution, and the `Fortschritt` column
together with the per-displayed-row status read that fills it, and for the
bilingual seeding principle both consult-resume tables share — both languages
seeded by verbatim example, day-first dates, identical columns and row order.
The list-and-stop obligation that decides *whether* to render it stays in the
skill body; everything about *how* it renders is below.

Render the engagement list as this table — never as raw field names:

```
# | Engagement                                                  | Zuletzt bearbeitet | Fortschritt
1 | Lean-Canvas-Schärfung cogni-work                            | 13.07.2026         | 3 von 7 fertig
2 | Benchmark Skill- & Agent-Entwicklung · noch nicht geschärft | 11.07.2026         | —
3 | Marktzugang Mittelstand                                     | 02.07.2026         | 12 von 12 fertig
4 | Serviceportfolio Nord                                       | 28.06.2026         | 1 von 4 fertig
5 | Digitalisierung Werk 2 · noch nicht geschärft               | 21.06.2026         | nicht lesbar

Weitere 6 — sag „alle“ für die vollständige Liste.

Nummer oder Name genügt. Danach zeige ich dir den Stand und einen nächsten Schritt.
```

Pad every column but the last to its widest rendered cell, header row included,
so each following column lines up — the suffixed rows usually set the name
column's width, and the `Zuletzt bearbeitet` header sets the date column's.

Sort by last activity, newest first, breaking ties on engagement name ascending
so the numbering is stable across a re-render. Number the rendered rows `1`,
`2`, `3` — bare, never `#1`. Cap the table at five rows: with five or fewer
engagements render every one and omit the overflow line entirely (never
`Weitere 0`); above five, render the top five and set `N` to the remainder. On
an „alle“ reply, re-render every engagement with continuous numbering and no
overflow line, **omitting `Fortschritt` entirely** — that re-render is the
two-column table, and the status read below is never run for it. The closing
line still applies, and the list-and-stop obligation in the skill's step 2 still
holds.

`Fortschritt` answers "how far did I get", which decides a resume better than the
date does. Fill it with one `bash $CLAUDE_PLUGIN_ROOT/scripts/engagement-status.sh
<engagement-path>` run per **displayed** row, using the `path` discovery already
returns; n counts the deliverables at `complete` and m is their flattened total
across every action field the run reports. This is the one place the list reads
per-engagement state — the `last_activity` prohibition below is on reading an
engagement's execution log to resolve a date, not on this rollup. Because the column rides
the capped rendering only, a rendering costs at most five runs; that bound is
what makes the column affordable at all, so never widen it to every registered
engagement. The runs are one announced step, never one announcement per call.

A cell is `—` only when the engagement genuinely has **no planned deliverables**.
Per rule 8 of the table contract in
`$CLAUDE_PLUGIN_ROOT/references/user-facing-output.md`, an action field the run
reports as `unreadable` — or a run that comes back unsuccessful — is that
contract's third case, so it renders `nicht lesbar` rather than `—`. Say what
was unreadable once below the table rather than per row. Drop the column when
every displayed cell would be `—`, but never to hide a `nicht lesbar` cell.

The step-4 engagement dashboard counts the same underlying quantity per action
field and renders it `2/2 fertig`; this column aggregates engagement-wide and
renders `3 von 7 fertig` — the fuller phrasing fits a row carrying one number
rather than a field's worth.

The number is a reply index into the list as most recently rendered, not a new
pre-list skip signal — the skill's step-2 matcher is unchanged and still selects on a
name or slug the user types. The table carries no slug and no `Scope` column;
instead, where `scope_state` (the scoping-phase status, not the engagement's
scope) is not `complete`, append ` · noch nicht geschärft` inside the
engagement's name cell.

`Zuletzt bearbeitet` is the `last_activity` field discovery already returns per
engagement — the newest transition timestamp from that engagement's execution
log, falling back to its root `updated` only when that log is absent, empty, or
unreadable; per `$CLAUDE_PLUGIN_ROOT/references/data-model.md`, "Deliverable work never touches
it", so root `updated` tracks scope edits, not engagement freshness. Never read
that log here. Values arrive raw and heterogeneous (a full timestamp or a bare
date), so render and sort on the date part alone; an empty `last_activity`
sorts last and renders `—`.

German sessions render the strings above and dates as `TT.MM.JJJJ`. An English
session renders the same table, so it is seeded by example too rather than left
to improvise: header `# | Engagement | Last worked on | Progress`, row suffix
` · not yet scoped`, progress cell `3 of 7 complete` with `—` for no planned
deliverables and `unreadable` for the state that cannot be read, overflow line
`N more — say “all” for the full list.`, and
closing line `A number or a name is enough. Then I'll show you where it stands
and one next step.` Dates keep the same day-first shape, so a date reads the
same way in either session. The columns, sort, cap, and the list-and-stop
obligation are identical in both languages.
