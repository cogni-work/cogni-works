# Engagement-List Rendering

How `consult-resume` renders the engagement-selection list in step 2, in either
interaction language. This document is authoritative for that table's columns,
sort, cap, re-render and `last_activity` resolution, and for the bilingual
seeding principle both consult-resume tables share — both languages seeded by
verbatim example, day-first dates, identical columns and row order. The
list-and-stop obligation that decides *whether* to render it stays in the skill
body; everything about *how* it renders is below.

Render the engagement list as this table — never as raw field names:

```
# | Engagement                                                  | Zuletzt bearbeitet
1 | Lean-Canvas-Schärfung cogni-work                            | 13.07.2026
2 | Benchmark Skill- & Agent-Entwicklung · noch nicht geschärft | 11.07.2026
3 | Marktzugang Mittelstand                                     | 02.07.2026
4 | Serviceportfolio Nord                                       | 28.06.2026
5 | Digitalisierung Werk 2 · noch nicht geschärft               | 21.06.2026

Weitere 6 — sag „alle“ für die vollständige Liste.

Nummer oder Name genügt. Danach zeige ich dir den Stand und einen nächsten Schritt.
```

Pad the name column to the widest rendered cell so the date column lines up —
the suffixed rows usually set that width.

Sort by last activity, newest first, breaking ties on engagement name ascending
so the numbering is stable across a re-render. Number the rendered rows `1`,
`2`, `3` — bare, never `#1`. Cap the table at five rows: with five or fewer
engagements render every one and omit the overflow line entirely (never
`Weitere 0`); above five, render the top five and set `N` to the remainder. On
an „alle“ reply, re-render every engagement with continuous numbering and no
overflow line — the closing line still applies, and the list-and-stop
obligation in the skill's step 2 still holds.

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
to improvise: header `# | Engagement | Last worked on`, row suffix
` · not yet scoped`, overflow line `N more — say “all” for the full list.`, and
closing line `A number or a name is enough. Then I'll show you where it stands
and one next step.` Dates keep the same day-first shape, so a date reads the
same way in either session. The columns, sort, cap, and the list-and-stop
obligation are identical in both languages.
