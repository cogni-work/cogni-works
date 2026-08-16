# Wiki-tree reconciliation — decisions record

insight-wave carries two copies of the same wiki. `wiki/` at the repository root is edited by
maintainers; `cogni-workspace/wiki/` is the vendored copy that ships inside the plugin so
marketplace users get it in their plugin cache on install. `scripts/release-bundle-wiki.sh`
copies the first over the second. This document records what was decided about every way the
two copies currently disagree.

This is a decisions record, not a delivery plan. Each decision below states what was decided,
the rule behind it, and the consequence of reversing it. Items marked *recorded, not executed*
are decided here and carried out elsewhere; the issue that carries them is named inline.

## On the figures in this document

Every count below is attributed to the command that produced it, measured against
`origin/main` at `0698cb2c`. Where a previously-quoted figure could not be reproduced, that is
recorded plainly rather than smoothed over.

| Figure | Command | Value |
|---|---|---|
| Pending changes | `bash scripts/release-bundle-wiki.sh --check` | `changes_pending: 28` |
| Root page count | same command, `source_page_count` | `170` |
| Bundled page count | `find cogni-workspace/wiki/wiki/pages -maxdepth 1 -name '*.md' \| wc -l` | `176` |
| Itemised breakdown | `rsync -anci --delete wiki/ cogni-workspace/wiki/` | 20 content + 7 delete + 1 add |

**The originating issue says 29; measurement says 28.** Both figures were taken with the same
command at different times, and the difference is not a miscount — it is the metric moving. An
earlier measurement at `bab6a9cd` reported `128`, of which 100 lines were attribute-only
(96 `.f..t....` files plus 4 `.d..t....` directories) produced by `rsync -i` itemising mtime
differences on a fresh checkout. At `0698cb2c` that class is **empty**: all 28 lines are genuine
content differences. Anyone re-measuring on a freshly-cloned tree may see the attribute lines
return, because they are an artefact of checkout order rather than of the trees themselves.

## Decision 1 — `entries_count` is corrected by hand, per tree

**Decision.** Set each tree's `.cogni-wiki/config.json` `entries_count` to that tree's own
measured page count. Root `179` → `170`; bundled `178` → `176`.

**Why.** The field had drifted in both trees, in both cases by omission rather than by error.
It was last set correctly by hand; three later commits deleted pages from one tree or the other
without updating either config.

| Tree | Config path | Recorded | Measured | Drift |
|---|---|---:|---:|---:|
| Root | `wiki/.cogni-wiki/config.json` | 179 | 170 | +9 overstated |
| Bundled | `cogni-workspace/wiki/.cogni-wiki/config.json` | 178 | 176 | +2 overstated |

**The two values stay different, and that is correct.** Each config describes its own tree, and
the trees hold different numbers of pages for as long as Decision 4 is open. A future reader
should not read `170 != 176` as fresh drift.

**Reversing it** restores a count that overstates both trees, which is the state that let three
page-deleting commits pass unnoticed.

## Decision 2 — the expected pending-changes figure is 28, and the residual is explained

**Decision.** After this reconciliation, `bash scripts/release-bundle-wiki.sh --check` is
expected to keep reporting `changes_pending: 28`. That figure is understood and intended.

**Why.** The metric counts `rsync` itemise lines, and none of the three classes it counts is
closed by the changes recorded here:

| Class | Lines | Why it survives |
|---|---:|---|
| `*deleting` | 7 | The bundled-only pages stay in place pending Decision 4 |
| `>f+++++++` | 1 | The dated lint page is root-only by design (Decision 5) |
| Content deltas | 20 | Recorded in Decision 3, executed separately |

The wikilink change in Decision 6 lands identically on both sides, so it adds no line. The
`entries_count` change in Decision 1 does not add a line either: the two configs already
differed, and they still differ.

**Reversing it** means the next person to read `28` treats it as unexplained drift and reaches
for the sync script — the outcome Decision 3's rejected alternative exists to prevent.

## Decision 3 — the 20 content deltas resolve in two opposite directions

*Recorded, not executed. Carried out in issue #1401.*

**Rule.** Direction is decided per group, never by a blanket copy. Thirteen files are newer at
the root; four are newer in the bundle; three are structural and take bespoke handling.

**Why.** The root copy is the editing surface, so the reflex is to treat it as correct
everywhere. For four pages that reflex would delete work. Commit `c44d52c3` appended
`## Steps` and `## Common pitfalls` sections — and a `## Two scenarios` section on one page —
directly to the *bundled* copies. Those sections have no root counterpart, so copying root over
bundle discards them.

### Group A — 13 files, root copy wins

Re-ingest commits enriched the root pages; the bundle was never re-synced afterwards and still
holds the thinner generated stub.

`agent-cogni-portfolio-proposition-generator.md`,
`agent-cogni-portfolio-proposition-quality-assessor.md`, `concept-claim-lifecycle.md`,
`concept-claims-propagation.md`, `plugin-cogni-portfolio.md`,
`skill-cogni-portfolio-portfolio-verify.md`, `skill-cogni-portfolio-propositions.md`,
`skill-cogni-trends-trend-report.md`

**Resolved by deletion — 5 former entries.** `agent-cogni-claims-claim-verifier.md`,
`agent-cogni-claims-source-inspector.md`, `plugin-cogni-claims.md`,
`skill-cogni-claims-claim-entity.md` and `skill-cogni-claims-claims.md` were deleted from **both**
trees when cogni-claims was absorbed into cogni-workspace: `test-wiki-namespace-sync.sh` case C1
derives its roster from `marketplace.json`, so dropping the plugin entry took all five off-roster.
The root-wins direction above is moot for them — there is no copy left on either side to win.

They are recorded here rather than silently dropped because a reconciliation run that still
expected them would look for files that no longer exist, and the deletion is the *reason* the
enrichment asymmetry stopped mattering, not evidence the ledger was wrong. `concept-claim-lifecycle.md`
and `concept-claims-propagation.md` survive in both trees and stay live Group A entries — they are
claim *concepts*, not namespaced plugin pages, so C1 never covered them.

**Resolved by deletion — 14 further entries per tree.** The same mechanism fired again when
cogni-narrative and cogni-copywriting were absorbed: `plugin-cogni-narrative.md`,
`plugin-cogni-copywriting.md`, the three `skill-cogni-narrative-*` and four
`skill-cogni-copywriting-*` pages, and the three `agent-cogni-narrative-*` and two
`agent-cogni-copywriting-*` pages went off-roster the moment both `plugins[]` entries were
removed, and were deleted from **both** trees in that same commit.

Two consequences worth stating, because neither is obvious from the page list and both turned a
suite red before they were handled:

- **Both trees' `entries_count` had to move with the page count** — 165 → 151 for the root tree and
  171 → 157 for the bundled one. `test-wiki-tree-parity.sh` cases W1 and W2 count live pages per
  tree, so a stale count reads as drift rather than as a deletion.
- **Six prose references across four pages pointed at the deleted plugin pages.**
  `ecosystem-overview.md`, `workflow-content-pipeline.md` and `workflow-portfolio-to-pitch.md` in
  both trees, plus `workflow-research-to-report.md` in the bundled tree only, linked
  `[[plugin-cogni-narrative]]` / `[[plugin-cogni-copywriting]]` in pipeline prose and in
  `related:` front-matter. They were rewritten to name the adopting plugin and the relocated skill
  rather than repointed link-for-link — "feeds cogni-workspace which feeds cogni-workspace" is not
  a sentence — and each tree's `index.md` lost its two roster bullets.

The dated ingest lines in each tree's `log.md` keep the retired names. They record what was ingested
on the date they name, which is the same treatment the cogni-claims re-ingest lines already had.

### Group B — 4 files, bundled copy wins

| Page | Root lines | Bundled lines | Sections only in the bundle |
|---|---:|---:|---|
| `workflow-portfolio-to-website.md` | 55 | 76 | Steps, Common pitfalls |
| `workflow-content-pipeline.md` | 50 | 79 | Steps, Common pitfalls |
| `workflow-portfolio-to-pitch.md` | 56 | 72 | Steps, Common pitfalls |
| `workflow-trends-to-solutions.md` | 52 | 79 | Two scenarios, Steps, Common pitfalls |

These must be back-ported bundle → root *before* any sync runs, then maintained from the root
like everything else.

### Group C — 3 structural files

`wiki/index.md` — the bundle's seven extra bullets are correct for the tree that holds those
seven pages, so they are not drift. Separately, the root copy carries five description
corrections and a root-only maintenance section. Neither side is wholly right; this one is
merged, not copied.

Both `.cogni-wiki/config.json` files — closed by Decision 1.

`wiki/log.md` — frozen by Decision 5.

**Reversing it** and running a blanket sync destroys the group-B sections and cannot be
recovered from the bundled tree afterwards.

## Decision 4 — the 7 bundled-only pages are held pending a maintainer ruling

*Recorded, not executed. Carried out in issue #1402.*

**Decision.** Neither promote these pages into the root tree nor delete them from the bundle.
They stay exactly as they are, and are listed here so the state is deliberate rather than
forgotten.

| Page | Named entities resolved | Verdict | Proposal |
|---|---|---|---|
| `concept-canonical-workflow-ids` | none asserted | current | promote |
| `ecosystem-plugin-selection` | 12/12 resolve | current | promote |
| `workflow-consulting-engagement` | 8 resolve, 1 self-documented removal | current | promote |
| `workflow-docs-pipeline` | 9 resolve, all in another marketplace | current | promote |
| `workflow-full-onboarding` | 5/5 resolve | current | promote |
| `workflow-research-to-report` | 7/7 resolve | current | promote |
| `ecosystem-command-reference` | 18 resolve, 1 mislabelled, 2 stale | lightly stale | update, then promote |

**Why the ruling is reserved.** Accepting a page into the root tree is what makes
`cogni-workspace:ask` serve it as a grounded answer. Promoting a stale page therefore does not
degrade gracefully — it makes the assistant answer confidently and wrongly, which is worse than
the dangling reference it would have fixed.

**The one page that is stale, and how.** `ecosystem-command-reference` states that
cogni-workspace ships no commands directory, lists 9 of its 11 skills, and counts
`render-infographic-editorial` as a skill when it is a command. The first two are the
cogni-help retirement seam: `troubleshoot` and `cogni-issues` moved into cogni-workspace and the
page predates the move. Three table rows, not a rewrite.

**Reversing it** — promoting all seven without the ruling — ships the stale page into the
grounded answer set.

## Decision 5 — dated records are history and are never rewritten

**Rule.** A dated snapshot records what was true on its date. Editing it is not reconciliation.

This extends an exemption the repository already recorded for `lint-2026-04-20.md`, and applies
it to the other dated record carrying the same figure.

| Path | Content | Treatment |
|---|---|---|
| `wiki/wiki/pages/lint-2026-04-20.md` | quotes a roster count true on its date | byte-identical, both trees |
| `wiki/wiki/log.md` | ingest entries quoting the same count | byte-identical, both trees |

The two trees' `log.md` copies additionally record two genuinely separate cleanup events on
different dates. That is divergent history, not staleness, and merging them would fabricate a
record of something that did not happen.

**Consequence for grading.** The requirement that no document assert a roster count disagreeing
with the marketplace manifest applies to current-state documents only. A change that "corrects"
a count inside a dated record violates this decision rather than satisfying that requirement.

## Decision 6 — the two unresolved references are removed from both copies

**Decision.** `workflow-install-to-infographic.md` line 60 listed six follow-on workflows, two
of which name pages absent from the root tree. Both are removed, identically, from both copies.

**Why not the other direction.** The obvious fix is to make the two pages exist at the root —
but those are two of the seven pages Decision 4 holds, so taking that route would decide
Decision 4 as a side effect. Removing the two references decides nothing and leaves four valid
options in the sentence.

**Why both copies.** This page is one of four pinned to byte-identity between the trees by
`cogni-workspace/tests/test-layering-claim-reconciled.sh`. A one-sided edit turns that suite red.

**On promotion.** If Decision 4 resolves toward promoting, restore both references — in both
copies — as part of that work. Issue #1402 carries this.

## Rejected alternative — run the sync script and accept the deletions

Rejected on three grounds:

1. It deletes the seven pages of Decision 4, converting a held decision into an executed one
   with no ruling.
2. It overwrites the four group-B pages with shorter root copies, destroying content that
   exists nowhere else.
3. Its post-sync check compares page *counts*, so it cannot detect the second failure at all —
   the counts still match after the content is gone.

The script's own header states the root tree is the editing surface, so the deletion is
intentional in principle. What was missing was any refusal when the bundle holds something the
sync is about to destroy.

The script now carries that refusal. It classifies the bundled tree *before* writing any bytes
and exits non-zero, naming every path it would have destroyed, in two classes: a bundled file
with no source counterpart (ground 1), and a bundled file carrying non-blank lines the source
copy lacks (ground 2 — the class the count-based check of ground 3 structurally cannot see,
since an overwrite leaves the file count unchanged). Taking this rejected alternative therefore
now requires passing `--force` explicitly, which makes converting a held decision into an
executed one a deliberate act rather than an accident.

Ground 3 still describes the post-sync check accurately. That check is left in place, and it is
the new pre-sync gate rather than any change to it that supplies the defence.

On the tree as recorded here a bare sync refuses on 27 paths: the 7 of Decision 4, the 4
group-B pages, and — because the root re-ingest reworded lines rather than only appending — the
13 group-A pages together with `wiki/index.md`, `wiki/log.md` and `.cogni-wiki/config.json`. The
gate is deliberately blind to Decision 3's ruling that root wins for group A: a script cannot
read this document, so it refuses and defers to the operator. Executing #1401 and #1402 is what
returns a bare sync to silence.

## Rejected alternative — regenerate `entries_count` with the wiki linter

The repository does contain a writer for this field, reached through the wiki linter's
drift fix. It does not apply here. That tool enumerates pages by walking a fixed set of
per-type subdirectories, and this wiki stores every page in one flat directory that is not in
that set — pointed at either tree it would count zero pages rather than 170 or 176, and write
that. The field is informational for this wiki, no test asserts on it, no schema documents it,
and the sync script never reads it. Setting it by hand matches how it was last set correctly.

## Known remaining contradictions

Kept as a permanent inventory so the set stays auditable rather than being rediscovered.

| Item | State | Carried by |
|---|---|---|
| 13 group-A pages thinner in the bundle | recorded, not executed | #1401 |
| 4 group-B pages missing sections at the root | recorded, not executed | #1401 |
| `wiki/index.md` needs a merge, not a copy | recorded, not executed | #1401 |
| 7 bundled-only pages held | awaiting a maintainer ruling | #1402 |
| `ecosystem-command-reference` names a retired command surface | held with the page above | #1402 |
| Sync script destroys bundle-only content | closed — refuses by default; `--force` is the opt-in | #1403 |
| This record and its guard are unregistered in the plugin guide | closed — `cogni-workspace/CLAUDE.md` names both under `## Wiki Trees` | #1404 |

## Deliberately left standing

The two `log.md` copies and `lint-2026-04-20.md` are untouched, per Decision 5 — a future reader
should not read them as misses. The two `entries_count` values remain different from each other,
per Decision 1. The pending-changes figure remains 28, per Decision 2. None of the seven
bundled-only pages is edited, promoted or deleted, per Decision 4.

## What guards this

`cogni-workspace/tests/test-wiki-tree-parity.sh` asserts, per tree and never tree-wide: that
each `.cogni-wiki/config.json` `entries_count` equals a live count of that same tree's pages;
that every wiki reference in a tree resolves to a page in that same tree; and that every page
present in only one tree is named in this document. The last of those is what makes adding or
promoting a page without recording a decision here fail rather than pass silently. It does not
assert the two trees are equal — they are not, by Decisions 1, 4 and 5.

`tests/test_release_bundle_wiki.sh` guards the other direction: that
`scripts/release-bundle-wiki.sh` refuses, by default, to destroy what this document holds. It
covers both refused classes, the `--force` opt-in, and — as the case that matters most for the
gate staying usable — that a bundle which loses nothing still syncs without `--force`. It runs
entirely against `mktemp` fixtures, never these two trees, because a bare sync against them is
the data loss the gate exists to prevent.
