# Engagement-Dashboard Rendering

How `consult-resume` renders the action-field dashboard in step 4, in either
interaction language. This document is authoritative for that table's columns,
row order, naming, counts and next-deliverable rule. The bilingual seeding
principle and the `last_activity` / date resolution it reuses are authoritative
in `$CLAUDE_PLUGIN_ROOT/references/engagement-list-rendering.md`; read that
alongside this one. The offers that follow the table — the visual dashboard, the
project-plan pointer, the README and assumption-register refreshes — stay in the
skill body.

Lead with the key question, then one table row per action field:

```
Engagement: <name> — zuletzt bearbeitet <TT.MM.JJJJ>
Schlüsselfrage: <key_question>

| Handlungsfeld | Stand | Deliverables | Nächstes Deliverable |
|---------------|-------|--------------|----------------------|
| Market Evidence | fertig | 2/2 fertig | — |
| Portfolio Fit | in Arbeit | 1/3 fertig | Competitor map (Ideate · pyramid-principle) |
| Go-to-Market | offen | 0/2 fertig | Channel strategy (Empathize · —) |
```

That is a German session. `Deliverables` is the same token in both header
rows — the established German loanword, not an untranslated leftover, so leave
it. The one carve-out is the action-field and deliverable names in the table
above — stored titles, here English, because stored titles keep their technical
terms whatever the session language. That carve-out covers those names and
nothing else; it is not a licence for English elsewhere in the table.

The parenthesised pair's stage is a display label, so it takes the casing
`$CLAUDE_PLUGIN_ROOT/references/user-facing-output.md` (c) note 4 mandates
(`ideate` → `Ideate`), in either session.

An English session renders the same table, seeded by example too: preamble
labels `Engagement: <name> — last worked on <DD.MM.YYYY>` and
`Key question: <key_question>`, header
`| Action Field | Status | Deliverables | Next Deliverable |`, `Status` values
`complete`, `in progress` and `pending` — the shapes
`generate-engagement-readme.py`'s `STATE_LABEL` already renders, so the two
surfaces agree — counts `2/2 complete` and `0/2 complete`. Dates keep the
day-first shape the engagement-list table uses, per
`$CLAUDE_PLUGIN_ROOT/references/engagement-list-rendering.md`. The columns, the row order and the
one-row-per-action-field rule are identical in both languages.

Name action fields by the `title` read from
`<engagement-path>/action-fields/<slug>/field.json` — step 3's rollup carries a
field's `slug` but not its title — and deliverables by the `title` the rollup
passes through with each deliverable. Fall back to the slug only when no title
is stored — slugs are storage keys, not display names, and titles are rendered
as stored, never translated.
`zuletzt bearbeitet` is the same discovery-supplied `last_activity` for the
selected engagement, resolved and rendered exactly as the engagement list does —
that rule is authoritative in
`$CLAUDE_PLUGIN_ROOT/references/engagement-list-rendering.md` and covers this
table too: its column headers, status cells, preamble labels and the date shape.

`Deliverables` counts deliverables at `complete` over the field total — that
`complete` is the engine state being counted, not the word to print; the cell
renders its count in the interaction language (`2/2 fertig` / `2/2 complete`).
`Nächstes Deliverable` / `Next Deliverable` names the
first non-complete deliverable with its `dt_stage` and stored
`chosen_framework` in parentheses (`<stage> · <framework>`), or the
first whose `persona_review` is still open when everything else is done.
The framework is the stored `chosen_framework` surfaced verbatim, read-only — a
registry slug that keeps its stored spelling in either session; for a
`combo:<slugA>+<slugB>` pairing, join the two slugs as `<slugA> + <slugB>` (the
stored `combo:` prefix dropped for display); render `—` when no framework is
stored (legacy deliverables) — never inferred here.
Keep it to this one table — the deep WBS view (planning deliverable sets,
splitting fields) belongs to `consult-action-fields`, not here.
