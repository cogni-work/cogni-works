# Absorption roadmap

Why cogni-workspace absorbs some capabilities and leaves others with the owning
plugin, and why three specific calls that look like debt are deliberate.

This is a decisions record, not a delivery plan. Each decision below states what
was decided, the rule behind it, and the consequence of reversing it — so the
call does not have to be re-derived, and so a future maintainer does not "clean
up" something load-bearing.

**On the figures in this document.** Every count is attributed to the command
that produced it, measured against base `19e6c1a7`. A number with no reproducible
command behind it is worse than no number, because it cannot be rechecked as the
tree moves — so where an earlier-quoted figure could not be reproduced, that is
recorded plainly at the point it matters rather than smoothed over.

## Decision 1 — the cut line: what becomes its own plugin

**Rule.** A capability that owns a full `setup → resume → dashboard` arc is a
vertical business plugin and keeps its own plugin. A capability that owns none of
that arc is horizontal infrastructure and belongs in cogni-workspace.

The arc is the test because it is the signature of a *project lifecycle*: state
that a user initializes, returns to across sessions, and inspects. A capability
with a lifecycle has something to own. One without is a tool other plugins call.

**Measured across the plugin set** — `git ls-tree -r --name-only origin/main`,
matching `<plugin>/skills/*/SKILL.md` against the `*-setup` / `*-resume` /
`*-dashboard` slugs:

| Plugin | setup | resume | dashboard | Arc |
|---|---|---|---|---|
| cogni-consult | yes | yes | yes | full |
| cogni-knowledge | yes | yes | yes | full |
| cogni-marketing | yes | yes | yes | full |
| cogni-portfolio | yes | yes | yes | full |
| cogni-trends | no | yes | yes | partial |
| cogni-website | yes | yes | no | partial |
| cogni-claims | no | no | no | none |
| cogni-copywriting | no | no | no | none |
| cogni-narrative | no | no | no | none |
| cogni-sales | no | no | no | none |
| cogni-visual | no | no | no | none |

`cogni-workspace` is exempt rather than scored: it owns `workspace-dashboard` but
no setup or resume skill, and it is the catch-all target of the rule — the
destination cannot also be a candidate.

**On the plugin count.** The table above is the scoring snapshot this roadmap was
derived against, when the repo-root `.claude-plugin/marketplace.json` registered
12 plugins — the eleven rows plus the exempt cogni-workspace accounted for all of
them. Rows are kept as the historical record of why each plugin scored as it did;
they are not re-scored as plugins retire, so read the table against the
absorption-status ledger below rather than as a current roster. `cogni-claims` has since been absorbed
into cogni-workspace, leaving 11 registered plugins. A further top-level directory,
`cogni-portfolio-evals/`, ships no `.claude-plugin/plugin.json` — it is an eval
harness, not a plugin, and is correctly outside this table.

`cogni-sales` sits in the "none" row on the measurement above. It owns a single
skill (`why-change`) and no lifecycle arc, so the rule places it with the
horizontal set even though it reads as a business capability by name. Recorded
explicitly because it is the one row where the rule and the intuition disagree.

## Absorption status

What Decision 1 has actually produced so far. The scoring tables above are the
point-in-time analysis that justified each call and are left as measured; this
section is the running record of what has landed.

| Source plugin | Status | What moved |
|---|---|---|
| cogni-help | retired | `cogni-issues` and `troubleshoot` kept as skills; `guide` / `cheatsheet` / `workflow` folded into `ask`'s bundled wiki; the course-delivery system deleted |
| cogni-claims | retired | the `claims` and `claim-entity` skills, the `claim-verifier` and `source-inspector` agents, and the `/claims` command, all moved verbatim. Nothing folded, nothing dropped — there was no overlapping surface to merge into |

Both prefixes are registered in `scripts/retired-plugins.json`, so
`scripts/check-external-dispatch.py` fails the build on any surviving
`cogni-help:` or `cogni-claims:` dispatch token. `tests/test-relocated-skill-hygiene.sh`
covers the file types that guard's globs miss, pairing each adopted tree with the
token its own source plugin dispatched under.

The cogni-claims move is the case Decision 2 below was written for: the skills
changed plugin, the data directory did not.

## Decision 2 — on-disk data directories keep their names

**Decision.** `{working_dir}/cogni-claims/` and `{source_dir}/cogni-visual/` keep
those exact directory names after the absorption. A plugin named `cogni-workspace`
writing into a directory named `cogni-claims` is **deliberate, not debt.**

**Why.** These directories are user files. They hold the accumulated state of
every project a user has already run. Renaming them is a breaking change to data
we do not own and cannot migrate: there is no upgrade hook that could find every
existing project directory on every user's disk and rewrite it. The cost of the
mismatched name is one paragraph of explanation — this one. The cost of renaming
is every existing project's store silently failing to load.

**Scale of the reference surface** — `git grep -l` and `git grep -o` at base
`19e6c1a7`, reported with both denominators because the two answer different
questions (how many files a rename touches, versus how many edits it takes):

| Directory token | Files | Occurrences | Files excl. own plugin dir | Occurrences excl. own plugin dir |
|---|---|---|---|---|
| `cogni-claims/` | 63 | 148 | 54 | 126 |
| `cogni-visual/` | 98 | 231 | 70 | 144 |

The magnitude is the argument, not the exact figure: a rename is a three-figure
edit across the tree *plus* an unmigratable change to user data. The figures
above are this document's own measurements — earlier-quoted values of 62 and 51
did not reproduce under any denominator tried, so they are not carried here.

## Decision 3 — MCP configuration moves to install time

**Decision.** MCP server declarations move out of per-plugin `.mcp.json` files and
into `cogni-workspace:install-mcp`, which writes them to user config on demand.

**Why.** A checked-in `.mcp.json` declares a server whether or not the user has it
installed, so the declaration and the machine drift apart with nothing to
reconcile them. Writing at install time makes the user's config the single source
of truth about what is actually available.

**Current state.** Implemented. The two `.mcp.json` files this decision was written
against — `cogni-portfolio/.mcp.json` and `cogni-visual/.mcp.json` — are gone, and no
plugin in the repo ships one. `install-mcp` writes each server into the user's own config
on demand, via `patch-desktop-config.py --target {desktop,cli,both}`. The pattern was new
rather than a relocation of an existing cogni-workspace file, so both the writer and the
guard that keeps it true were introduced here.

**Both declarations had to go together.** `cogni-portfolio`'s `excalidraw` block was
byte-identical to `cogni-visual`'s, so removing one left the eager-spawn failure intact.
The duplicate name was also load-bearing in a second way: two plugin-level declarations of
one server made the client plugin-qualify the tool names, which silently dead-matched the
`mcp__excalidraw__.*` PreToolUse matcher each plugin carries. Removing both restores the
unqualified prefix and revives both matchers without editing either hook.

**Known consequence — the revived matchers now fire twice.** `cogni-visual` and
`cogni-portfolio` ship byte-identical `hooks.json` and `ensure-excalidraw-canvas.sh`, so
on a machine with both installed every `mcp__excalidraw__*` call dispatches two PreToolUse
hooks where zero fired before. The script guards its spawn on `nc -z localhost "$PORT"`,
which is a check, not a mutual-exclusion primitive: two dispatches racing a cold canvas
can both fall through that probe, both `nohup node dist/server.js`, and both write
`canvas.pid` — leaving the loser dead on `EADDRINUSE` with the pid file pointing at it.
The intended fix is an atomic claim before the spawn (`mkdir canvas.lock`, or `flock` on
the pid file), with the loser falling through to the existing wait-for-port loop, applied
identically to both copies. It is deliberately deferred to its own change: the fix belongs
to the two hook files together, outside the declaration move's scope, and is tracked as a
follow-up so the doubled dispatch is not rediscovered later as a mystery.

**`excalidraw_sketch` is retired — retracting the paragraph that kept it.** This record
previously stated it was "live and retained", correcting a still earlier draft that had
called it already-dead. That correction was right about reachability and wrong about use,
and the reasoning is worth keeping visible because both earlier readings failed the same
way: they argued from the documentation rather than from the callers.

What settles it: no file references `mcp__excalidraw_sketch__*` in any executable
position, and the sole consumer this record cited it for — the `render-big-picture` skill
— no longer exists in cogni-visual. A server that is configured, documented and reachable
but has no caller is unused, not live.

Note also that the eager-spawn argument never applied to it. It was a url-type server with
no local process, so it never spawned at session start and was never part of the failing
`/mcp` entry. It goes because this decision leaves no per-plugin declaration for a url
entry to live in, and because nothing calls it — not because it was failing.

## Rejected alternative — renaming cogni-workspace

Renaming the plugin (to `cogni-tools` or similar) was considered, because
"workspace" describes the state it owns rather than the tools it provides, and
after the absorption it provides more tools than state.

**Rejected.** Three grounds:

1. **Identity.** `cogni-workspace` is the first thing a user initializes and the
   name every onboarding path, README, and doc page already teaches. The name is
   part of how the ecosystem is explained.
2. **Breadth of churn.** A rename does not stop at the plugin: it reaches the
   other registered plugins, `docs/`, both wiki trees, and the marketplace
   manifest — a repo-wide edit whose benefit is a better noun.
3. **Absolute cost.** Roughly 135 files reference `cogni-workspace` from outside
   the plugin's own directory — 35 namespaced (`cogni-workspace:`) and 102 by
   bare path (`cogni-workspace/`), `git grep -l` at base `19e6c1a7`. That is the
   whole price of the change, and nothing but a better noun is bought with it.

**On the cost figures.** Ground 3 is an *absolute* count, deliberately not the
inbound-reference **comparison** originally supplied. That comparison — ~193
inbound files for cogni-workspace against ~70 for the five horizontal candidates
combined — does not reproduce, because its two sides were transposed. Measured at
base `19e6c1a7` with `git grep -l`, excluding each plugin's own directory:

| Target | `<name>:` (namespaced) | `<name>/` (bare path) |
|---|---|---|
| cogni-workspace | 35 | 102 |
| five horizontal candidates, summed | 197 | 205 |

The `~193` figure is the five candidates' *namespaced* sum, not cogni-workspace's
total; the `~70` is `cogni-visual`'s bare-path count alone. Read correctly, the
horizontal set carries *more* inbound references than cogni-workspace does, and
`cogni-visual` alone (85 namespaced / 70 bare-path) exceeds what was claimed as
the five-way combined total. The comparison therefore points the other way and
cannot carry the decision — which is why the cost ground above is stated in
absolute terms instead.

## Decision 5 — the four-layer concept page is retained in reduced form

**Decision.** `concept-four-layer-architecture.md` keeps its descriptive
Orchestration / Data / Output groupings and loses the dependency ordering built on
top of them: the total-order claim ("plugins in higher layers depend on lower
layers, but never the reverse") and the Foundation rung both go, and
cogni-workspace is restated as the horizontal band alongside the vertical groups.
The page's filename and frontmatter `id:` are **unchanged**.

**Why.** Two things were tangled on that page. The dependency ordering is falsified
by Decision 1 and had to go regardless of any taxonomy question. The role groupings
are a separate, still-useful description of what each plugin does, and nothing in
this record contradicts them. Deleting the page outright would have discarded the
second to remove the first, and would have stranded 31 inbound references —
20 of which are wikilink *aliases* on the per-plugin pages (`Data layer`,
`Output layer`, `Foundation layer`) where the alias text is the assertion. Nothing
in CI catches a dangling `[[...]]`: `test-wiki-namespace-sync.sh` checks only
`plugin-*` / `skill-*` / `agent-*` filename stems against the marketplace roster and
skips the `concept-*` family entirely.

**What this leaves open.** Replacing the role taxonomy outright with an explicit
horizontal/vertical vocabulary remains available, and costs no more later than it
would have here: it would additionally rewrite the 18 surviving `Data layer` /
`Output layer` aliases across 9 pages × 2 trees, and commit the ecosystem to a
vocabulary this record does not ratify. That is an architecture-owner call. The
reduced form is the reversible one, which is why it is the default taken here.

**Reversing it** means re-deriving those 18 aliases and the page body together —
the same work either way, so nothing is foreclosed.

## Decision 6 — vendored trees follow a rename only where the text dispatches

**Decision.** A vendored tree is a mirror of an upstream origin and is **not**
rewritten for a downstream plugin rename — except where its text names the
dispatch target a caller is told to invoke. Those references are rewritten with
the rest of the surface; everything else in the tree keeps its upstream wording.

**Why.** The two halves fail differently. Prose that merely mentions the source
plugin is a historical statement and stays true; rewriting it only widens the
drift between the mirror and its origin, which is the one property the tree
exists to hold. A reference naming the dispatch target is an **instruction**: it
tells an operator — or a model reading the docstring — which skill or agent to
invoke, and after a retirement that name resolves to nothing. Left alone it also
contradicts the live caller, which *was* re-pointed.

**Applied at the cogni-claims absorption** to the three references in
`cogni-knowledge/scripts/vendor/cogni-wiki/skills/wiki-claims-resweep/scripts/`
(`resweep_planner.py`, `extract_page_claims.py`), which name the skill and agent
that `knowledge-refresh/SKILL.md` dispatches for the resweep. The SKILL.md sites
moved to `cogni-workspace:`; these moved with them. No other vendored file was
touched.

These sites sit in a coverage hole by construction:
`scripts/check-external-dispatch.py` drops `cogni-knowledge/` wholesale via
`EXCLUDE_PREFIXES`, and `tests/test-relocated-skill-hygiene.sh` walks the adopted
`cogni-workspace` trees only. Neither guard reports this class — the rule above is
the record that keeps the next absorption from re-litigating it.

## Decision 7 — a retired namespace token survives where it carries no dispatch intent

**Decision.** After a plugin is retired into an adopting plugin, the completeness
test for its colon-form token is **dispatch intent, not textual presence**. The
gate of record is `scripts/check-external-dispatch.py` returning a clean zero. An
occurrence is a violation only where the text names a target something would
actually be dispatched to. Three categories are admitted alongside the dated
historical record:

1. **A guard's forbidden-token lookup table.** The literal is the guard's
   matching data, not a reference to the retired plugin.
2. **Meta-documentation of the rewrite rule itself**, including this file and the
   plugin's `CLAUDE.md`.
3. **A dated record naming a retired dispatch that has no successor** to be
   re-pointed at.

**Why.** A textual reading is not merely strict, it is incoherent — it forbids
the very literal that the hygiene suite must assert. `tests/test-relocated-skill-hygiene.sh`
carries the retired token in its `TREES` table because that token *is* what the P1
arm matches on; delete it and the arm still passes while protecting nothing. The
same collision recurs one level up: a rule that cannot be written down without
using the literal it governs. Meta-documentation and a guard's own data are
statements *about* the token, not uses of it, and the two failure modes are
opposite — a live dispatch resolves to nothing at runtime, whereas rewriting a
dated record falsifies history to reach a cosmetic zero. That second failure is
already rejected for CHANGELOG files, and the reasoning does not stop there.

**Applied at the cogni-claims absorption** to five sites: the hygiene suite's
`TREES` table and header comment, the colon-vs-slash discriminator in
`cogni-workspace/CLAUDE.md`, the rule statement in this file, and two dated
records under `cogni-knowledge/references/` — one of which names a pipeline stage
for which no adopting-plugin equivalent exists, so a rewrite would invent a
dispatch that never ran. Genuine dispatch-intent sites found in the same sweep,
the vendored resweep docstrings of Decision 6, were re-pointed rather than
excepted. That is the line: this rule admits statements about a name, never
instructions that use it.

## Known remaining contradictions — reconciled

The layering claim this record replaces — that cogni-workspace is the layer every
other plugin depends on — was not confined to the plugin README. It was asserted at
the paths below, measured at base `19e6c1a7`. **All are now reconciled**; the table
is kept as the historical inventory rather than deleted, so the set stays auditable.

| Path | Note | State |
|---|---|---|
| `cogni-workspace/README.md:212` | Inside the auto-generated `## Dependencies` section. | Reconciled — sentence deleted. The `doc-generate` template for this section emits only a heading and a table and specifies no lead-in prose, so the deletion is regeneration-stable and needed no generator change. |
| `docs/plugin-guide/cogni-workspace.md:9`, `:214` | Generated plugin guide. | Reconciled in the output only. The generator ships from another repository, so the fix could not be made at its source — see the caveat below. |
| `docs/architecture/er-diagram.md:22` | Architecture prose. | Reconciled — `## Four Architectural Layers` is now `## Architectural Groups`. |
| `docs/er-diagram.md:13` | Mermaid subgraph label `Foundation["Foundation Layer"]`. | Reconciled — display label only; the `Foundation` subgraph id is unchanged so every edge still resolves. |
| `docs/claude-code-desktop.md:236` | Onboarding prose. | Reconciled. |
| `cogni-workspace/wiki/wiki/pages/plugin-cogni-workspace.md:21` | Bundled wiki copy. | Reconciled — alias and the second occurrence at `:45`. |
| `wiki/wiki/pages/plugin-cogni-workspace.md:21` | Repo-root wiki mirror. | Reconciled — same two edits, byte-identical. |
| `concept-four-layer-architecture.md` (both wiki trees) | A dedicated page built on the four-layer framing. | Reconciled per Decision 5 above. |

**The inventory above was incomplete.** These carried the same claim, were present
at `19e6c1a7` too, and were missed when the table was first written:

| Path | Note |
|---|---|
| `docs/ecosystem-overview.md:13`, `:17` | A `### Foundation` layer-group heading with cogni-workspace as its sole occupant, plus the table cell beneath it. Rewriting only the cell would have left the framing standing structurally. |
| `docs/architecture/er-diagram.md:9` | The total-order sentence above the ASCII diagram — the table named only `:22`. |
| `cogni-help/skills/guide/references/plugin-catalog.md:240`, `:248` | `**Foundation for**: All other plugins`. |
| `cogni-help/skills/teach/.../tour-install-to-infographic.md:80` | Course prose. |
| `cogni-help/skills/workflow/references/workflows/install-to-infographic.md:23` | Workflow prose. |
| `arch-er-diagram.md:15-17` (both trees) | `## Four architectural layers` + the total-order sentence. |
| `workflow-install-to-infographic.md:42` (both trees) | Wiki workflow prose. |
| `plugin-cogni-workspace.md:45` (both trees) | `Foundation for all 13 other plugins.` — two paragraphs below the `:21` alias the table did name. |
| `cogni-workspace/skills/ask/SKILL.md:72` | The worked example quoting the four-layer model. |

**A second pass found five more**, all of which the first two passes above also
missed. They are recorded separately because the shape of each miss is the
lesson, not the count:

| Path | How it evaded the earlier passes |
|---|---|
| `docs/workflows/install-to-infographic.md:43`, `:65` | The narrative tutorial the `cogni-help` workflow template hands off to at its closing line, and which `docs/claude-code-desktop.md:236` recommends as the next step. Reconciling the template while leaving the page it links to meant a reader crossed from a reconciled sentence straight into an unreconciled one. Neither phrasing (`the foundation the others depend on`, `is the shared foundation`) matched any literal the guard then carried. |
| `plugin-cogni-workspace.md:17` (both trees) | The hyphenated `Foundation-layer plugin`, four lines above the `:21` alias the first table did name — so the page asserted both framings about itself. The hyphen is why it evaded the `foundation layer` grep. |
| `wiki/wiki/index.md:52` (both trees) | The index one-liner derived from that page's first line; correcting the page alone left the index contradicting it. |
| `tour-install-to-infographic.md:34-38` (plus `:42`, `:52`) | The retired four-tier taxonomy, 46 lines above the `:80` line the first pass fixed and in the module a first-run learner reads first. It asserted a Foundation rung, and memberships for cogni-help and cogni-claims, that Decision 5 and the rewritten concept page deny. |
| `.claude-plugin/plugin.json` + its `marketplace.json` mirror | The plugin description — the claim's highest-visibility surface and the upstream source of the wiki line above. **Not reconciled here:** the scope boundary confines this diff to markdown and `tests/*.sh`. The guard excludes `.claude-plugin/` explicitly rather than reporting clean over it; remove that exclusion when the manifests are corrected. |

The recurring shape is worth naming: every miss but the last was **a second
occurrence in a file the inventory had already listed**, or **a page derived from
one**. A path-level inventory cannot catch either — only a re-grep of the whole
tree after each edit can, which is what the guard now automates.

**Deliberately left standing**, with reasons, so a future reader does not read them
as misses: the ASCII-art fill labels in `cogni-visual/libraries/`
(`excalidraw-patterns.md:165`, `svg-patterns.md:283`) are diagram legends unrelated
to the claim; `wiki/log.md` and `wiki/pages/lint-2026-04-20.md` are dated historical
artifacts, and rewriting history is not reconciliation; and
`plugin-cogni-help.md:18-20` ("depends on every other plugin … is depended on by
nothing") is an accurate statement *about cogni-help*, which stays true under the
reduced form.

**One caveat survives.** `docs/plugin-guide/cogni-workspace.md` is `cogni-docs`
generator output, and `cogni-docs` ships from a separate repository — there is no
`cogni-docs/` directory here to fix at source. The output is corrected so readers
stop seeing a falsified claim, but a regeneration pass could reintroduce the wording
in that one file until the generator is changed.

`cogni-workspace/tests/test-layering-claim-reconciled.sh` guards the reconciled
state: a forbidden-literal scan over the paths above, plus per-page byte-parity
between the two wiki trees. Parity is asserted **per touched page**, never
tree-wide — the trees legitimately differ by one page, so a tree-wide assertion
would fail on arrival.
