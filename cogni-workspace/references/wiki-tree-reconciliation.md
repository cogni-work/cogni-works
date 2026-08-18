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

Every count below is attributed to the command that produced it, measured against the ref named
beside it. Where a previously-quoted figure could not be reproduced, that is recorded plainly
rather than smoothed over.

The figures were re-measured when Decision 3 was executed. The table now carries the **post-
execution** state; the pre-execution values it replaces are kept in the paragraph below rather
than overwritten, because the difference between them is what Decision 3 actually did.

| Figure | Command | Value | Measured at |
|---|---|---|---|
| Substantive pending changes | `rsync -anci --delete wiki/ cogni-workspace/wiki/`, excluding attribute-only lines | 3 content + 7 delete + 1 add = **11** | Decision 3 execution branch |
| Raw pending changes | `bash scripts/release-bundle-wiki.sh --check` | `changes_pending: 167` on a fresh checkout | Decision 3 execution branch |
| Root page count | same command, `source_page_count` | `151` | Decision 3 execution branch |
| Bundled page count | `find cogni-workspace/wiki/wiki/pages -maxdepth 1 -name '*.md' \| wc -l` | `157` | Decision 3 execution branch |

**Read the substantive row, not the raw one.** The two rows disagree by 156 lines and neither is
wrong: `changes_pending` counts every `rsync` itemise line, and on a freshly-checked-out tree 152
`.f..t....` files plus 4 `.d..t....` directories are attribute-only mtime differences rather than
content. This is the same artefact class described below, and it is why the substantive figure is
quoted first and derived from the itemised command.

**The moving figures, in order.** The originating issue said 29. Measurement at `bab6a9cd` said
`128`, of which 100 lines were attribute-only. Measurement at `0698cb2c` said `28` with that class
empty. Measurement at `563098e0` — the base of the Decision 3 execution branch — said **21**
substantive lines (13 content + 7 delete + 1 add). None of those moves is a miscount; each is the
metric moving. The `28` → `21` step was not reconciliation work at all: it is the cogni-claims and
cogni-narrative/cogni-copywriting absorptions deleting pages out of both trees, which retired five
group-A entries outright and left two more already identical. Executing Decision 3 then took the
substantive figure from 21 to **11** by closing 10 of the 13 content deltas.

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

## Decision 2 — the expected substantive residual is 11 lines, and every one is explained

**Decision.** After this reconciliation *and* the execution of Decision 3, the itemised
`rsync -anci --delete wiki/ cogni-workspace/wiki/` is expected to keep reporting **11 substantive
lines**, plus a checkout-dependent number of attribute-only lines that carry no meaning. That
residual is understood and intended.

**Why.** Each surviving line belongs to a decision that deliberately keeps the two trees apart:

| Class | Lines | Why it survives |
|---|---:|---|
| `*deleting` | 7 | The bundled-only pages stay in place pending Decision 4 |
| `>f+++++++` | 1 | The dated lint page is root-only by design (Decision 5) |
| Content delta — `.cogni-wiki/config.json` | 1 | Each config describes its own tree; the values are *supposed* to differ (Decision 1) |
| Content delta — `wiki/log.md` | 1 | Frozen dated history, divergent on purpose (Decision 5) |
| Content delta — `wiki/index.md` | 1 | Merged, never copied: the bundle keeps the seven Decision-4 bullets, the root keeps its maintenance section (Decision 3, group C) |

Decision 3's execution closed the other 10 content deltas — the six live group-A pages and the
four group-B pages are now byte-identical across the trees. The wikilink change in Decision 6
lands identically on both sides, so it adds no line. The `entries_count` change in Decision 1
does not add a line either: the two configs already differed, and they still differ.

**Do not gate on `changes_pending`.** `bash scripts/release-bundle-wiki.sh --check` reported
`changes_pending: 167` on the execution branch, and 156 of those were attribute-only. The
substantive figure is the one to compare against, and it comes from the itemised command.

**Reversing it** means the next person to read a large `changes_pending` treats it as unexplained
drift and reaches for the sync script — the outcome Decision 3's rejected alternative exists to
prevent.

## Decision 3 — the content deltas resolve in two opposite directions

*Executed in issue #1401.* Six live group-A pages were copied root → bundle, four group-B pages
were back-ported bundle → root, and `wiki/index.md` was merged. The three structural files remain
divergent by design; see Decision 2's residual table.

**Rule.** Direction is decided per group, never by a blanket copy. The group-A files are newer at
the root; four are newer in the bundle; three are structural and take bespoke handling.

**Why.** The root copy is the editing surface, so the reflex is to treat it as correct
everywhere. For four pages that reflex would delete work. Commit `c44d52c3` appended
`## Steps` and `## Common pitfalls` sections — and a `## Two scenarios` section on one page —
directly to the *bundled* copies. Those sections have no root counterpart, so copying root over
bundle discards them.

### Group A — originally 13 files, 6 live at execution, root copy wins

Re-ingest commits enriched the root pages; the bundle was never re-synced afterwards and still
held the thinner generated stub. The six that were still divergent when Decision 3 executed were
copied root → bundle verbatim and are now byte-identical:

`agent-cogni-portfolio-proposition-generator.md`,
`agent-cogni-portfolio-proposition-quality-assessor.md`, `plugin-cogni-portfolio.md`,
`skill-cogni-portfolio-portfolio-verify.md`, `skill-cogni-portfolio-propositions.md`,
`skill-cogni-trends-trend-report.md`

The copy was verified non-destructive before it ran: on all six the root copy strictly enriched
the bundled one — added `related:` entries, added wikilinks, expanded summary lines, and on
`skill-cogni-portfolio-propositions.md` an 87-line rewrite over a 19-line stub — so no bundled
line was lost. Every wikilink the copies carry already resolved in the destination tree, which is
what kept parity cases W4 and W5 green.

**Already identical at execution — 2 entries.** `concept-claim-lifecycle.md` and
`concept-claims-propagation.md` were byte-identical in both trees by the time Decision 3 ran, so
nothing was copied for them. They were live group-A entries when this was recorded; the re-ingest
that closed them is the same class of movement the figures section describes.

**Resolved by deletion — 5 former entries.** `agent-cogni-claims-claim-verifier.md`,
`agent-cogni-claims-source-inspector.md`, `plugin-cogni-claims.md`,
`skill-cogni-claims-claim-entity.md` and `skill-cogni-claims-claims.md` were deleted from **both**
trees when cogni-claims was absorbed into cogni-workspace: `test-wiki-namespace-sync.sh` case C1
derives its roster from `marketplace.json`, so dropping the plugin entry took all five off-roster.
The root-wins direction above is moot for them — there is no copy left on either side to win.

They are recorded here rather than silently dropped because a reconciliation run that still
expected them would look for files that no longer exist, and the deletion is the *reason* the
enrichment asymmetry stopped mattering, not evidence the ledger was wrong. `concept-claim-lifecycle.md`
and `concept-claims-propagation.md` survive in both trees — they are claim *concepts*, not
namespaced plugin pages, so C1 never covered them. They were live Group A entries when this was
recorded and had converged to byte-identical by the time Decision 3 executed, as noted above.

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

These were back-ported bundle → root *before* any sync ran, and are now maintained from the root
like everything else. Each was a pure insertion — the shared prefix was byte-identical on both
sides and `**Source**:` was the last line of both — so the back-port was a verbatim copy with zero
root-only lines to lose.

All four are now pinned to byte-identity by `PAGE_PARITY` in
`cogni-workspace/tests/test-layering-claim-reconciled.sh`, so the sections that once existed only
in the bundle cannot drift back out of the root tree unnoticed.

### Group C — 3 structural files

`wiki/index.md` — merged, not copied, and **still divergent after the merge, on purpose**. The
bundle's seven extra bullets are correct for the tree that holds those seven pages, so they are not
drift and were left in place; promoting them into the root tree would create seven dangling
references there and pre-decide Decision 4. The root's `### Maintenance` section stays root-only
for the same reason in reverse: it links `[[lint-2026-04-20]]`, a root-only page.

Measured at execution, the two copies differed on **four** description/intro lines, not the five
recorded here. Three resolved root-wins: the `### Skills` and `### Agents` preambles (the bundle
asserted "across all 11 plugins", which the nine-plugin marketplace roster contradicts) and the
`skill-cogni-portfolio-propositions` bullet (the bundle still carried the terse stub, matching the
stub page group A replaced).

The fourth is the case this rule was written for — **neither side was right.** The root said the
website-setup skill discovers content from "cogni-portfolio, cogni-marketing, cogni-trends, and
cogni-research"; the bundle omitted the fourth source entirely. `cogni-research` has no directory
and is not on the marketplace roster, and the generating source
`cogni-website/skills/website-setup/SKILL.md` names `cogni-knowledge`. Both trees now carry that
corrected text. A blanket root-wins merge would have propagated a plugin name that does not exist;
a blanket bundle-wins merge would have dropped a real source.

Both `.cogni-wiki/config.json` files — closed by Decision 1.

`wiki/log.md` — frozen by Decision 5.

**Reversing it** and running a blanket sync destroys the group-B sections and cannot be
recovered from the bundled tree afterwards.

### Extension — the same rule applied to bare prose names

*Carried out in issue #1426.*

The pass above reached only references shaped as `[[wikilink]]`s or `related:` frontmatter — the
mechanically detectable set. A **bare** plugin name in prose carries no wrapper, so the wikilink
resolvers behind W4/W5 never saw that class and the suites stayed green with it fully present. The
same rule — name the adopting plugin and the relocated skill — now applies to bare prose too.

**The surface is the two-tree intersection of `wiki/wiki/pages/*.md`, non-recursive.** Measured at
the time of the sweep: 150 pages in the intersection, all 150 byte-identical; 25 of them carried a
bare retired name. Everything else is outside the surface **structurally, with no exclusion list**:

- `index.md`, `log.md` and `overview.md` fall out by **depth** — they sit at `wiki/wiki/` level.
- `lint-2026-04-20.md` falls out because it is the only **root-only** page (and Decision 5 freezes it).
- The 7 pages of Decision 4 fall out because they are **bundled-only** — the very property that
  decision is about.

A surface with no exclusion entries cannot be widened by accident, which matters here: the
substring-matching `is_excluded()` in `tests/test-layering-claim-reconciled.sh` turns one loose
fragment into a repo-wide exemption. It also self-heals — when #1402 rules, the held pages enter or
leave the surface with no guard edit.

**Adopters used.** `cogni-narrative` and `cogni-copywriting` → cogni-workspace, citing its
`narrative` and `copywriter` skills (`audit-copywriter` was deleted, not adopted, and is never cited
as live). `cogni-research` → cogni-knowledge. `cogni-consulting` → cogni-consult, **but not as a
rename**: several pages described the retired plugin's *phase-gated* architecture, which
cogni-consult does not have, so those were rewritten against the live model (action fields as WBS
containers, a per-deliverable design-thinking loop, `consult-project.json`) rather than
substituted. `cogni-wiki` had zero bare occurrences in the surface.

**Five claims were false, not merely stale**, and were corrected as content: cogni-knowledge ships
no `hooks/` (the four that do are cogni-consult, cogni-portfolio, cogni-visual, cogni-workspace);
the "no `scripts/`" census named plugins whose code now lives in cogni-workspace, which has one —
only cogni-marketing and cogni-website lack it; cogni-knowledge's entity vocabulary is not
SubQuestion/Context/Source/ReportClaim; the `portfolio_path` frontmatter edge had no cogni-consult
consumer at all; and the `canvas-{slug}.md` bridge row named a file no plugin emits — removed per
Decision 6 rather than repointed.

**`cogni-claims/` paths are preserved deliberately.** Per `cogni-workspace/CLAUDE.md`, the
discriminator is the colon: a `cogni-claims:` dispatch token is rewritten, a `cogni-claims/` path is
not. All 8 surviving occurrences in the surface (4 per tree) are paths. Two of them share a line
with a rewritten `cogni-research` token.

**`cogni-docs` and `cogni-service` are not retired** — they are live plugins hosted in a different
marketplace, already allowlisted as `EXTRA_ALLOWED` in `tests/test-wiki-namespace-sync.sh`. They are
out of scope here, and any future roster-derived scan needs that same allowance or it reports false
positives on them.

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

**Why both copies.** This page is one of eight pinned to byte-identity between the trees by
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

On the tree as originally recorded here a bare sync refused on 27 paths: the 7 of Decision 4, the
4 group-B pages, and — because the root re-ingest reworded lines rather than only appending — the
13 group-A pages together with `wiki/index.md`, `wiki/log.md` and `.cogni-wiki/config.json`.

Once Decision 3 executed, that inventory narrowed to **10**: the 7 of Decision 4, plus
`wiki/index.md`, `wiki/log.md` and `.cogni-wiki/config.json`. The group-A and group-B pages no
longer appear, because they are now byte-identical across the trees and a sync has nothing to
change on them. The gate is deliberately blind to Decision 3's ruling that root wins for group A: a
script cannot read this document, so it refuses and defers to the operator. Decision 4 is now the
only decision standing between a bare sync and silence, and #1402 carries it.

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
| Group-A pages thinner in the bundle | closed — the 6 still divergent were copied root → bundle; 5 had been deleted from both trees and 2 had already converged | #1401 |
| 4 group-B pages missing sections at the root | closed — back-ported bundle → root and pinned by `PAGE_PARITY` | #1401 |
| `wiki/index.md` needs a merge, not a copy | closed — merged per the group-C rule; the two copies still differ by design | #1401 |
| 7 bundled-only pages held | awaiting a maintainer ruling | #1402 |
| `ecosystem-command-reference` names a retired command surface | held with the page above | #1402 |
| Sync script destroys bundle-only content | closed — refuses by default; `--force` is the opt-in | #1403 |
| This record and its guard are unregistered in the plugin guide | closed — `cogni-workspace/CLAUDE.md` names both under `## Wiki Trees` | #1404 |
| Bare prose plugin names are invisible to every resolver | closed — swept over the two-tree `pages/*.md` intersection and pinned by `tests/test-wiki-bare-name-roster.sh`, a runtime-roster-derived body scan with one arm per tree | #1426, guard in #1438 |
| The 5 bundled-only pages still name retired plugins | held with the pages themselves — editing them would pre-decide the ruling | #1402, sweep in #1440 |
| `index.md` and `overview.md` carry the same bare-name class | outside the swept surface by depth; needs its own decision, since the two `index.md` copies diverge by design and a TOC of deleted pages is a Decision-6 removal, not a rename | #1439 |
| The generated `docs/` mirror repeats the dead `portfolio_path` edge | open — cogni-docs ships from a separate repo, so the fix is correct-the-output plus an upstream filing, never a local regeneration | #1441 |
| Two `consulting-project.json` residues name a manifest no plugin writes | open — outside the page surface (`troubleshoot/known-issues.md`, `docs/contributing/`) | #1442 |

## Deliberately left standing

The two `log.md` copies and `lint-2026-04-20.md` are untouched, per Decision 5 — a future reader
should not read them as misses. The two `entries_count` values remain different from each other,
per Decision 1. The substantive residual remains 11 lines, per Decision 2 — and the two
`wiki/index.md` copies remain different from each other, per Decision 3's group-C rule. None of the
seven bundled-only pages is edited, promoted or deleted, per Decision 4.

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

`cogni-workspace/tests/test-wiki-bare-name-roster.sh` closes the prose gap the two guards above leave
open. It asserts that no `cogni-…` token in the body of a page present in both trees names something
absent from the live roster, with the allowed set read at runtime from `plugins[].name` rather than
written down — so the next retirement is caught without anyone remembering to edit the suite. Its
declared surface is the two-tree basename intersection of the page directories, and every page
outside that surface is excluded by construction rather than by a list: the top-level `index.md`,
`log.md` and `overview.md` fall out by depth, and the one-sided pages fall out by symmetric
difference. That distinction is what keeps the suite honest here, because those one-sided pages
demonstrably still carry retired names — editing them to satisfy a guard would pre-decide the
rulings Decisions 4 and 5 hold open. Three allowances are declared, each keyed to an exact token
rather than a substring: plugins hosted in a different marketplace, the GitHub org token, and the
preserved `cogni-claims/` store path, whose dispatch form is still caught. Each carries both halves
of its case, so an allowance cannot quietly widen into an escape hatch. Two per-arm liveness floors —
one on shared pages scanned, one on roster size — make a half-dead arm fail with a named error
instead of reporting clean, which is the failure mode a guard over an already-clean surface is
otherwise blind to.
