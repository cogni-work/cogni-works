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

## (b) Scope — every surface, not only prose

These rules govern **every** user-facing surface, not only prose: table cells,
column headers, list items, headings, count lines, step announcements,
offer lines, and the `description` of a tool call.

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
  how the consultant answered a persona challenge; no JSON key carries it.
- Design-thinking stage names (`empathize` → `define` → `ideate` → `prototype` →
  `test`) are method terms: proper-case them for display (`ideate` → `Ideate`),
  do not translate them.

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

## What binds here but lives elsewhere

These rules are not restated in this file; they hold on every surface named in
(b) all the same:

- Audience framing, executive register and compression discipline, the
  engine-vocabulary-stays-internal rule, and the no-slug-in-prose rule —
  `references/subagent-output-contract.md` (`## Register`) and
  `output-styles/strategy-advisor.md` / `strategy-advisor-de.md`.
- German orthography (ß/ss, Umlaute) — `output-styles/strategy-advisor-de.md`.

One boundary: the generated HTML dashboard document follows the engagement's
deliverable `language` axis, not the interaction language, and is therefore
outside this contract.
