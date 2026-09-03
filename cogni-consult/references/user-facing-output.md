# User-facing output

The register every cogni-consult skill follows when it writes for the
consultant. This file is an **overlay**: the ecosystem register is canonical and
carries the shared doctrine — language and orthography (a), governed surfaces
(b), the never-display-a-raw-value rule (c), the table contract (d), step
announcements and brevity budgets (e), tool-call descriptions (f), the anglicism
test (g), and the executive register (h).

Read the canonical file first:

```bash
cat "${COGNI_WORKSPACE_PLUGIN}/references/user-facing-output.md"
```

**If `$COGNI_WORKSPACE_PLUGIN` does not resolve**, cogni-workspace is not
registered in this workspace. Say so once, apply this overlay alone, and carry
on — a missing canonical register degrades the doctrine, it never blocks the
work. Run `/cogni-workspace:manage-workspace` to register it.

This file carries only what is genuinely cogni-consult's: its state lexicon rows,
its own coinage vocabulary, the description constraints its skills mirror inline,
and the pointers to where the rest binds. Section letters match the canonical
file so a rule and its overlay line up.

**This file governs the main loop only.** A dispatched agent never sees it — a
subagent's prompt carries no `CLAUDE.md`, no settings language, no output style
and no skill body. Agents receive the same doctrine through
`references/subagent-output-contract.md`, injected by the `SubagentStart` hook,
plus an `interaction_language` dispatch input. The two are one contract with two
delivery paths, not two contracts: check a rule changed here against that file.

## (a) Language — this plugin's ladder

Resolve the **interaction language** per `references/interaction-language.md`,
which owns the resolution ladder and the separation from the engagement's
deliverable `language`. Do not restate the ladder — read it there.

The canonical file's German orthography rules bind here unchanged. To check an
engagement's stored corpus rather than trust it, run
`python3 $CLAUDE_PLUGIN_ROOT/scripts/orthography-drift-scan.py "<engagement-dir>"`.
Treat a finding as the stored text being wrong, not the rule. The scan is
read-only and matches a curated pair list with bounded recall, so a zero-finding
report means nothing on that list appeared — not that the corpus is ß-correct.

## (c) State lexicon

The canonical rule binds: an engine value is never displayed raw, and a value
missing from this table is a gap in the table, not a licence to pass the raw
value through — add the row.

| Engine value | German | English |
|---|---|---|
| `pending` | offen | pending |
| `in-progress` | in Arbeit | in progress |
| `complete` | fertig | complete |
| `lineage_status.status: "stale"` | überholt | outdated |
| `unreadable` | nicht lesbar | unreadable |
| `personas_gate: "satisfied"` | erfüllt | satisfied |
| `personas_gate: "pending"` | offen | pending |
| adherence `strong` / `partial` / `drifted` | stark / teilweise / abgewichen | strong / partial / drifted |
| outcome `promoted` / `declined` / `none-found` | übernommen / abgelehnt / nichts gefunden | promoted / declined / none found |
| disposition `accepted` / `revised` / `rejected` | übernommen / überarbeitet / begründet verworfen | accepted / revised / rejected with reason |

Four notes travel with the table:

- The `pending` / `in-progress` / `complete` triple is shared by a deliverable's
  `state`, `workflow_state.scope`, and `persona_review`. One triple, one mapping.
- `unreadable` is a **field-rollup** state, written alongside a `warnings[]`
  entry — never conflated with `pending`, which means not started. Surface the
  warning's substance; do not pass the token through.
- The disposition triple is **prose vocabulary**, not a stored field. It names
  how the consultant answered a persona challenge; no JSON key carries it. It is
  the **closed** lexicon the canonical (c) distinguishes: exactly three values,
  and a fourth is an invention rather than a gap to add. The row-gap rule admits
  values the engine actually writes; a disposition the engine never writes has no
  row to add, so reach for one of the three or rewrite the sentence.
- Design-thinking stage names (`empathize` → `define` → `ideate` → `prototype` →
  `test`) are method terms: proper-case them for display (`ideate` → `Ideate`),
  do not translate them. The casing is what carries the meaning: lower-cased,
  they read as engine values — the consultant sees a stored token rather than
  the name of a method stage, which is exactly the failure proper-casing
  prevents. That mandate governs the stage where it appears **as a display
  label** — a table cell, a badge, prose naming the stage as a stage. Two forms
  fall outside it and stay lowercase: a code span (`` `ideate` ``), where the
  token is deliberately being shown as the stored value, and a hyphenated
  compound built from one (`mid-ideate`), where the stage has become a word
  inside a phrase rather than a label being displayed. These two are the
  complete exception set; anywhere else, proper-case.

## (f) Tool-call descriptions

The canonical file owns the five constraints. They are restated here, and inline
in every `consult-*` skill's Step 0, because a description can be written —
wrongly — without ever opening any reference, so the constraints have to sit
where the model always reads them. Edit them in the canonical file first, then
mirror the change here and into the nine Step 0 blocks;
`tests/test_step0_register_block.sh` fails if the copies drift apart or get
thinned.

1. Written in the resolved interaction language, per (a).
2. Outcome-shaped — what the consultant gets back, not what the machine runs.
3. At most 6 words.
4. No script, file, or skill names. Those are engine vocabulary, and (c) no more
   exempts a description than it exempts a table cell.
5. Never derived from the script's filename or its header comment. A filename is
   an engineering label; deriving from it reproduces engine vocabulary in the one
   place the consultant reads it.

Worked pair: `Discover cogni-consult engagements` → `Laufende Engagements holen`.

## (g) Prose anglicisms — this plugin's coinages

The canonical file owns the three-step test. Of the terms below only `Stale` is
also a (c) row (`lineage_status.status: "stale"`); `Cascade` and `Gate` are engine
vocabulary governed by the engine-vocabulary rule in canonical (h). Where both
apply they agree, so there is nothing to reconcile.

The table is what step 3 of the test resolves to for this plugin's own coinages:

| English | German | Note |
|---|---|---|
| Front-Door | Einstiegsseite | |
| Ramp | Anlaufphase | |
| Slip-Signal | Verzugssignal | |
| Base-Case / Base-Fall | Basisfall | |
| Promote-Check | Annahmenprüfung | |
| Gate | Freigabepunkt | usually cut entirely rather than translated — name what the consultant decides, not the checkpoint |
| Cascade | als überholt markieren | |
| Stale | überholt | |
| Rollup | Gesamtstand | |
| Handoff | Übergabe | |
| Waiver | begründete Ausnahme | |
| WBS | Arbeitsstruktur | |

The established domain terms that may stay English are
**Deliverable**, **Design Thinking** and **Persona**, together with file and
skill names, CLI commands, and slugs in code form. That list is closed — anything
outside it takes the three-step test rather than being waved through as
established.

`Action Field` is this plugin's own coinage, not an established German
consulting term, so on a German surface it reads **Handlungsfeld**. It is the
worked exclusion from the list just above. The English table templates keep
`Action Field` deliberately — that is the two-language split doing its job, not
a leak.

Step 1 of the test resolves these recurring consulting anglicisms. They are not
this plugin's coinages, so they sit here rather than in the table above, whose
scope is deliberately narrower: `Moat-Richtung` → **Wettbewerbsschutz**;
`Sozialbeweis` → **sichtbarer Beleg durch andere**; `Evergreen-Bestand` →
**dauerhaft nutzbarer Bestand**.

The canonical never-invent-a-system-term rule has a worked instance here:
`Routed`, offered as a fourth disposition alongside the three real ones; the
plugin has never written it.

This table is owned here rather than borrowed. The `copywriter` skill's
German-style table addresses sales and go-to-market vocabulary and shares no term
with the list above; it transliterates its umlauts to ASCII, which contradicts
the orthography this plugin mandates; and no load path reaches it from here. The
method above is worth citing, the vocabulary is not worth importing.

The naming discipline in this section has a subagent counterpart —
`references/subagent-output-contract.md` (`## Register`) carries it, because an
agent's envelope prose is exactly where an invented term surfaces. Unlike (f),
which is main-loop-only by its own terms, a rule changed here is checked against
that file.

## What binds here but lives elsewhere

These rules are not restated in this file; they hold on every surface named in
canonical (b) all the same:

- The shared register — language and orthography, governed surfaces, the table
  contract, step announcements and brevity budgets, the anglicism test, and the
  executive register — `${COGNI_WORKSPACE_PLUGIN}/references/user-facing-output.md`.
- Audience framing and the answer-first advisory stance —
  `output-styles/strategy-advisor.md`, on the styled path only. That file is
  opt-in and carries stance alone; it restates none of the register.
- The slug-presence rule — canonical (d).7 owns it.
  `references/subagent-output-contract.md` still scopes its own slug rule to
  prose.

German orthography is not delegated away from this plugin by the overlay split:
canonical (a) owns it for the ecosystem, and the corpus-drift scan that checks an
engagement against it stays here, because the script is this plugin's.

One boundary: the generated HTML dashboard document follows the engagement's
deliverable `language` axis, not the interaction language, and is therefore
outside this contract.
