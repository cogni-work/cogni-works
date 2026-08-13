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
| cogni-help | no | no | no | none |
| cogni-narrative | no | no | no | none |
| cogni-sales | no | no | no | none |
| cogni-visual | no | no | no | none |

`cogni-workspace` is exempt rather than scored: it owns `workspace-dashboard` but
no setup or resume skill, and it is the catch-all target of the rule — the
destination cannot also be a candidate.

**On the plugin count.** The repo-root `.claude-plugin/marketplace.json` registers
exactly 13 plugins, and the twelve rows above plus the exempt cogni-workspace
account for all of them. A fourteenth top-level directory, `cogni-portfolio-evals/`,
ships no `.claude-plugin/plugin.json` — it is an eval harness, not a plugin, and is
correctly outside this table.

`cogni-sales` sits in the "none" row on the measurement above. It owns a single
skill (`why-change`) and no lifecycle arc, so the rule places it with the
horizontal set even though it reads as a business capability by name. Recorded
explicitly because it is the one row where the rule and the intuition disagree.

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

**Current state.** Exactly two `.mcp.json` files exist at base `19e6c1a7` —
`cogni-portfolio/.mcp.json` and `cogni-visual/.mcp.json`. cogni-workspace ships
none. This decision therefore establishes a **new** pattern; it is not the
relocation of an existing cogni-workspace file, and nothing here has moved yet.

**`excalidraw_sketch` is live and retained.** It is defined at
`cogni-visual/.mcp.json:3` as a url-type MCP (`https://mcp.excalidraw.com`) and is
documented as the no-install alternative to the `excalidraw` server at
`cogni-workspace/skills/manage-workspace/SKILL.md:149`,
`cogni-workspace/skills/workspace-status/SKILL.md:177`, and
`cogni-workspace/skills/workspace-status/references/mcp-registry.md:30,35`. It is
configured, documented and reachable, so this record does not describe it as dead.
An earlier draft of this decision called it already-dead; that was wrong on the
evidence above. Retiring it remains possible, but it would be a behaviour change
across two plugins, not a line in a documentation file.

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
