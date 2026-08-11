# User-facing output

The register every cogni-consult skill follows when it writes for the
consultant: which language, which surfaces the rules cover, which words stand in
for a stored value, how a table reads, and how a step is announced.

**This file governs the main loop only.** A dispatched agent never sees it — a
subagent's prompt carries no `CLAUDE.md`, no settings language, no output style
and no skill body. Agents receive the same doctrine through
`references/subagent-output-contract.md`, injected by the `SubagentStart` hook,
plus an `interaction_language` dispatch input. The two are one contract with two
delivery paths, not two contracts: check a rule changed here against that file.

## (a) Language

Resolve the **interaction language** per `references/interaction-language.md`,
which owns the resolution ladder and the separation from the engagement's
deliverable `language`. Do not restate the ladder — read it there. Everything
below applies in whatever language that resolves to.

**German orthography.** Write ß after a long vowel or a diphthong (Maßnahme,
außerhalb, Größe) and ss after a short vowel (dass, muss, Prozess).
Kein schweizerisches ss an ß-Stellen — the Swiss convention of writing ss in
every ß position is never used here. Umlauts are covered by the repo-wide
encoding convention that forbids ASCII substitutes, which this file already
relies on where it declines to import cogni-copywriting's table for
transliterating them.

**When the engagement's own text disagrees.** The paragraph above is read once; an
engagement's stored files arrive as in-context evidence and out-argue it. A corpus
already written in Swiss ss therefore teaches every later turn to keep writing it,
and the drift reinforces itself silently. To check a corpus rather than trust it,
run `python3 $CLAUDE_PLUGIN_ROOT/scripts/orthography-drift-scan.py "<engagement-dir>"`.
Treat a finding as the stored text being wrong, not the rule. The scan is read-only
and matches a curated pair list with bounded recall, so a zero-finding report means
nothing on that list appeared — not that the corpus is ß-correct.

## (b) Scope — every surface, not only prose

These rules govern **every** user-facing surface, not only prose: table cells,
column headers, list items, headings, count lines, step announcements,
offer lines, and the `description` of a tool call, whose own copy rules are (f).

A table is not an exemption from the register — it is where register failures are
most visible, because a column header reads as a label the system endorses.

## (c) State lexicon

An engine value is **never** displayed raw. A value missing from this table is a
gap in the table, not a licence to pass the raw value through — add the row.

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
  also **closed**: exactly three values, and a fourth is an invention rather than
  a gap to add. The row-gap rule above admits values the engine actually writes;
  a disposition the engine never writes has no row to add, so reach for one of
  the three or rewrite the sentence.
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

Where an English display string happens to equal the engine token, that is a
coincidence of vocabulary, not an exemption — the value still passes through the
lexicon rather than being printed because it "already looks like English".

## (d) Table contract

1. A fixed, named column set — never derived at runtime from whatever keys the
   data happens to carry.
2. Natural-language headers. A field identifier as a column header is a defect.
3. An explicit sort, stated once, not left to the order the data arrived in.
4. A row cap, plus one overflow line naming what was not shown.
5. Drop degenerate columns — a column carrying an identical value in every row
   informs no one.
6. No table under four rows. Below that, prose or a list reads better.
7. A slug appears only where the reader needs it to *act*, in code form. Never
   as a header, and never as a deliverable's name.
8. A cell standing in for a missing or unmeasured **quantity or state** renders
   `—`, never a zero-valued token (`0/0`, `0 von 0`): zero reads as a
   measurement, the em-dash as "nothing here to measure". A value that could
   not be read is a third case again — name it rather than flattening it into
   either of the first two. This does not govern a boolean marker column (a
   glyph when true, blank when false), which is its own established idiom. And
   rule 5 never licenses dropping a column to hide a state the reader needs
   to see.

## (e) Step announcements and brevity budgets

Two tiers, split by irreversibility rather than by skill:

- **Orientierungsschritt** (read-only): one sentence, at most 25 words.
- **Arbeitsschritt** (writes state, or fans out over engagement entities): two
  sentences, at most 45 words, naming what comes back and what changes on disk.

One announcement per perceptible wait, never one per tool call.

Three rules keep the announcement cheap:

- **Announce before *or* report after — never both.** Saying it twice costs the
  reader a second pass and adds nothing.
- **Name the actors when they are engagement entities, never the dispatch.**
  "Partner, Projektleitung, CFO und Betriebsrat, jeder in seiner eigenen Logik",
  not "vier Agenten" — the consultant knows the stakeholders, not the machinery.
- **No wall-clock estimates.** A wrong estimate is a trust withdrawal, which
  inverts what the announcement is for.

**Work narration.** A batch of edits is one perceptible step, not many. Announce
it with a single high-altitude line before making it — what is changing and why
("Aktualisiere N Dateien, um …") — never a file-by-file preview. Afterwards, do
not restate each individual edit or diff back in prose: the change itself is the
record, and re-narrating it buries the answer in low-altitude detail. Close the
batch with a compact summary — which files were touched and to what collective
purpose — not a walkthrough of each diff. This does not contradict the
announce-before-*or*-report-after rule above: that rule binds per perceptible
step, and a batch gets one opening line at batch altitude plus one closing
summary, never a per-edit narration.

**A numbered back-reference carries its name** — "Teillösung 2 (die freie
Content-Schicht)", not "bei 2". A bare ordinal makes the reader scroll back to
recover what it points at.

Work narration is main-loop-only, in the style of (f) below: a dispatched agent's
user-facing surface is the envelope it returns, not a sequence of edits it
narrates, so `references/subagent-output-contract.md` carries no counterpart and
none is owed.

## (f) Tool-call descriptions

The `description` of a Bash tool call is rendered to the consultant, so it is
user copy. (b) names it a governed surface; this section owns its specifics.

Every `consult-*` skill's Step 0 also states the five constraints inline and
cites this section. That duplication is deliberate: unlike the resolution ladder
in (a), which cannot be applied without opening its reference, a description can
be written — wrongly — without ever opening this file, so the constraints have to
sit where the model always reads them. Edit them here first, then mirror the
change into the nine Step 0 blocks; `tests/test_step0_register_block.sh` fails
if the copies drift apart or get thinned.

Main-loop-only, deliberately: a dispatched agent's user-facing surface is the
envelope it returns, not its own tool calls, so
`references/subagent-output-contract.md` carries no counterpart to this section
and none is owed.

Five constraints, all binding:

1. Written in the resolved interaction language, per (a).
2. Outcome-shaped — what the consultant gets back, not what the machine runs.
3. At most 6 words.
4. No script, file, or skill names. Those are engine vocabulary, and (c) no more
   exempts a description than it exempts a table cell.
5. Never derived from the script's filename or its header comment. A filename is
   an engineering label; deriving from it reproduces engine vocabulary in the one
   place the consultant reads it.

Worked pair: `Discover cogni-consult engagements` → `Laufende Engagements holen`.

A description failing any of the five is a defect on the same footing as a raw
engine value in a table cell. This is a surface, not a debug channel.

## (g) Prose anglicisms

(c) governs how a **stored engine token** is displayed. This section governs the
**prose word the consultant reads** — vocabulary that carries no backing field
and so has no row to look up. Of the terms below only `Stale` is also a (c) row
(`lineage_status.status: "stale"`); `Cascade` and `Gate` are engine vocabulary
governed by the engine-vocabulary rule in (h) below. Where both apply they
agree, so there is nothing to reconcile.

Before reaching for the table, run the three-step test — the method comes from
cogni-copywriting's German-style principles, cited here rather than loaded,
because nothing in this plugin loads that file:

1. Does an equally precise German word exist? If yes, use it.
2. Is the anglicism established with no good German equivalent (*Meeting*,
   *Software*, *Update*)? If yes, keep it.
3. Is it a hyphenated English compound? Those almost always have a German
   rendering — replace them.

The table is what step 3 resolves to for this plugin's own coinages:

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
outside it takes the three-step test above rather than being waved through as
established.

`Action Field` is this plugin's own coinage, not an established German
consulting term, so on a German surface it reads **Handlungsfeld**. It is the
worked exclusion from the list just above. The English table templates keep
`Action Field` deliberately — that is the two-language split doing its job, not
a leak.

**Spell an acronym out once at first use** — ICP, OMTM, UVP — then use it freely
for the rest of the exchange.

Step 1 of the test resolves these recurring consulting anglicisms. They are not
this plugin's coinages, so they sit here rather than in the table above, whose
scope is deliberately narrower: `Moat-Richtung` → **Wettbewerbsschutz**;
`Sozialbeweis` → **sichtbarer Beleg durch andere**; `Evergreen-Bestand` →
**dauerhaft nutzbarer Bestand**.

**Never invent a system term that does not exist.** An invented term is worse
than a leaked one: a leaked engine value can at least be looked up in the
system, while an invented one resolves nowhere the consultant can reach — not in
the artifact, not in a manifest, not in this file. The observed instance is
`Routed`, offered as a fourth disposition alongside the three real ones; the
plugin has never written it. When a word is needed for a state, take it from
(c), or describe what happened in plain language.

This table is owned here rather than borrowed. cogni-copywriting's German-style
table addresses sales and go-to-market vocabulary and shares no term with the
list above; it transliterates its umlauts to ASCII, which contradicts the
orthography this plugin mandates; and no load path reaches it from here. The
method above is worth citing, the vocabulary is not worth importing.

The naming discipline in this section has a subagent counterpart —
`references/subagent-output-contract.md` (`## Register`) carries it, because an
agent's envelope prose is exactly where an invented term surfaces. Unlike (f),
which is main-loop-only by its own terms, a rule changed here is checked against
that file.

## (h) Executive register and engine vocabulary

Write in an executive register: precise, concise, no filler, no restating the
question, no postamble.

**Compression discipline.** Minimize words with zero precision loss. Cut hedging,
throat-clearing and restatement — never cut a fact, a number, a caveat or an
option to be shorter. Brevity must lose words, not information.

**Engine vocabulary stays in the system.** Engine nouns — cascade, graph, edge,
`depends_on`, gate, slug, state values (`complete`), log ids (`d-084`), version
tags — are internal. Report the business consequence instead: "drei Deliverables
ruhen jetzt auf einer überholten Zahl", not "das Cascade hat drei Knoten
geflaggt"; "die Entscheidung ist im Protokoll festgehalten", not "d-084
eingetragen"; "alle vierzehn Deliverables sind fertig", not "14/14 Deliverables
complete". Name an id only when the reader needs it to look something up.

This section is stated here rather than delegated because it has to reach the
**main loop**. `references/subagent-output-contract.md` (`## Register`) carries
the same three rules for the agent path, and it is injected into a dispatched
agent — never loaded here — so a pointer to it would leave the main loop with no
reachable copy. This is the one-contract-two-delivery-paths rule at the top of
this file doing its job, not a duplication.

## What binds here but lives elsewhere

These rules are not restated in this file; they hold on every surface named in
(b) all the same:

- Audience framing and the answer-first advisory stance —
  `output-styles/strategy-advisor.md`, on the styled path only. That file is
  opt-in and carries stance alone; it restates none of the register.
- The slug-presence rule — (d).7 above owns it.
  `references/subagent-output-contract.md` still scopes its own slug rule to
  prose.

German orthography is no longer delegated: (a) above owns it outright, because
the sole file that used to carry it no longer exists.

One boundary: the generated HTML dashboard document follows the engagement's
deliverable `language` axis, not the interaction language, and is therefore
outside this contract.
