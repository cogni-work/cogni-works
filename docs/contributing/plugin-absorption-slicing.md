# Plugin Absorption Slicing

How to slice a plugin-absorption change — folding one plugin's skills, agents and commands
into another and retiring the source — so that each stage is reviewable on its own and
leaves CI green at its merge.

Read this before planning an absorption. The sequencing below is not a style preference:
three of this repo's guards grade the *real* tree against the *real* manifest, so a
plausible-looking decomposition can leave the build red between stages. Those constraints
are stated with the stage they bind.

## Why this exists

The first absorption landed as one pull request of 1736 changed lines across 97 files. The
review gate flagged the size, and the coupling that produced it was real: delete a plugin
and relocate it, and every consumer reference has to move in the same commit or the tree
names a plugin that no longer exists.

The coupling is real but it is not total. It binds *deletion* to *consumer rewrite*, not
*adoption* to either. Adding the adopted trees while the source still exists dangles
nothing, so adoption can land first, on its own, and be reviewed closely. That is the seam
this convention cuts along.

## The four stages

Plan an absorption as four pull requests in this order. Each row states what lands and the
invariant that keeps the tree working when it merges.

| # | Stage | What lands | Invariant at merge |
|---|---|---|---|
| 1 | Adopter | The adopted skills / agents / commands under the adopting plugin, plus the hygiene guard for those trees | Both plugins exist. Every dispatch token in the tree resolves. The adopted copies contain no source-prefixed dispatch token. |
| 2 | Consumer rewrite | Every consuming plugin's dispatch tokens and prose repointed at the new home | Both plugins still exist, so a token resolves whether it was rewritten yet or not. Splittable per consumer group. |
| 3 | Retirement | Source directory, its `plugins[]` entry, both wiki trees' roster pages, and the retired-prefix registration — **atomically** | Manifest and directories are back in bijection, the wiki roster matches the manifest, and no live surface dispatches the newly registered prefix. |
| 4 | Narrative docs | Prose, diagrams and counts that no guard grades — architecture pages, ecosystem overview, README narrative | Nothing is enforced here; correctness is editorial. |

### This departs from the obvious sketch, on purpose

The intuitive decomposition ends with a "docs and wiki" stage that regenerates every roster
surface after the deletion. Do not plan it that way. The **wiki** half of that stage is
graded against the manifest, so it must merge *with* the deletion — see stage 3. Only the
ungraded narrative surfaces can defer to stage 4.

## Per-stage size bound

Target **400 changed lines per stage**. That figure is the review gate's advisory
bound — it is a fail-visible flag raised by the `cogni-service` review tooling, which lives
outside this repository, not a check in `.github/workflows/`. Nothing fails a build at 401
lines.

Stage 3 is the one stage that may not fit. Its contents are bound together by the guards
below, so splitting it to hit the bound trades a review-size flag for a red build — take
the flag. When a stage exceeds the bound because an atomicity rule forces it, say so in the
pull-request body so the reviewer reads the size as intentional.

## What binds stage 3 together

Three guards make stage 3 atomic. Each is enforced by CI, so none of these is advisory.

### The manifest and the directories must move together

`scripts/check-plugin-inventory.py` asserts a bijection in both directions: every
`plugins[].source` in `.claude-plugin/marketplace.json` resolves to a directory carrying
`.claude-plugin/plugin.json`, and every top-level plugin directory appears in `plugins[]`.
`tests/test_check_plugin_inventory.sh` runs it against the real repository, and
`scripts/run-plugin-tests.py` runs that under CI.

Delete the directory without removing the entry and direction 1 fails; remove the entry
without deleting the directory and direction 2 fails. Both edits belong in one commit.

### The wiki roster dies with the manifest entry

`cogni-workspace/tests/test-wiki-namespace-sync.sh` builds its allowed-namespace roster at
runtime from `plugins[].name`, and its first case scans the real wiki trees against that
roster. The moment the source plugin leaves `plugins[]`, every
`plugin-<source>*`, `skill-<source>-*` and `agent-<source>-*` page in both wiki trees
becomes an off-roster offender.

Delete those pages in the same pull request that removes the manifest entry. Do not hand-
edit generated wiki output for any other purpose in an absorption — regenerate it instead.

### Register the retired prefix last

`scripts/check-external-dispatch.py` enforces a hard clean-zero — no ratchet, no
baseline — for every prefix listed in `scripts/retired-plugins.json`, across
`*/skills/*/SKILL.md`, `*/agents/*.md`, `*/commands/*.md` and `*/hooks/**`. Directories
named `references/` and `docs/` are excluded by design, so lineage prose is safe.

Add the source prefix to the registry **in stage 3, never earlier**. Register it while
stage 2 is still in flight and every not-yet-rewritten consumer becomes a build failure.

```json
{
  "retired_prefixes": ["cogni-wiki", "cogni-research", "cogni-help"]
}
```

## The relocated-skill hygiene guard

`cogni-workspace/tests/test-relocated-skill-hygiene.sh` is the pattern to copy for a new
adoption. Read what it actually asserts before reasoning about it, because it is easy to
assume a scope it does not have.

Its first case walks **only the adopted trees under the adopting plugin** and fails if any
file contains the source plugin's qualified dispatch token. It never scans consumers. Its
own header states that every assertion reads the destination tree alone and that it passes
the same whether or not a source tree exists anywhere in the repository.

Two consequences for slicing:

- **The consumer-rewrite stage does not violate this guard.** Tokens surviving in consuming
  plugins are invisible to it. The guard that governs those tokens is
  `check-external-dispatch.py`, and it is inert until the prefix is registered — which is
  why registration waits for stage 3.
- **Author the guard in stage 1.** The adopted trees must be clean of source-prefixed
  dispatch tokens the moment they land, and the guard carries a liveness floor that fails
  when it scans zero files. A guard added before the trees exist fails; a guard added after
  leaves the adoption ungraded in between.

Extend `test-relocated-skill-hygiene.sh` rather than writing a parallel guard. This reverses
earlier advice here, and the reversal is empirical: two absorptions have now added arms to it, and
the pairing it grew — one `<tree>|<forbidden token>` spec per adopted tree, each checked against the
token its *own* source plugin used — is what makes multiple source plugins work in one file without
any arm going vacuous. A second guard would duplicate the walk, the liveness floor and the
`${CLAUDE_PLUGIN_ROOT}` resolution for no gain.

Two things to get right when you extend it. A spec's tree may be a directory **or a single file** —
adopted agents land as bare files under `agents/`, and a directory-only form leaves every adopted
agent silently ungraded, which is exactly what happened to the cogni-claims agents until the
narrative/copywriting absorption noticed. And the token must stay the **colon-qualified** form, so a
bare-name path that the adoption is required to preserve is not mistaken for a dispatch.

## The duplicate-plugin window

Stages 1 and 2 leave both plugins shipping the same skills. **Accept that window, and
time-box it to a single planning sequence** — open stage 2 as soon as stage 1 merges, and
do not start an unrelated absorption while one is open.

It is accepted because the alternative is the coupling this convention exists to break:
avoiding the window means adoption, rewrite and deletion collapse back into one
unreviewable commit. It is time-boxed because its two costs are real and neither is caught
by CI.

**A duplicate skill name is reported, but not by CI.**
`cogni-workspace/scripts/check-skill-names.sh` globs `cogni-*/skills/*/SKILL.md` across
every plugin and reports a duplicate when two plugins carry the same frontmatter `name:`.
It is a documented pre-pull-request check, not a workflow step, and its own suite exercises
fixtures rather than the real tree. So during the window the check reports errors that are
expected. Note that in the stage-1 and stage-2 pull-request bodies, naming the duplicated
skills, so a reviewer can tell an expected report from a regression.

**A trigger-phrase collision is caught by nothing.**
`cogni-workspace/tests/test-skill-trigger-phrases.sh` is scoped to a single plugin
deliberately — two plugins may legitimately quote the same phrase, because the host
disambiguates by plugin. Across the duplicate window that assumption does not hold: the
source and the adopted copy are the same skill, and the host has no tiebreaker.

Therefore, during the window:

- Do not duplicate a slash command. Land the command definition in stage 3, with the
  deletion, or leave it on the source plugin until then.
- Do not rename an adopted skill to dodge the duplicate report. A rename is a user-visible
  dispatch change and does not belong inside a hygiene workaround.

## Absorptions this governs

The queued absorption work is planned against this convention. Slice each of these into the
stages above rather than filing one pull request per issue:

- **#1351** — absorb cogni-narrative and cogni-copywriting into cogni-workspace — **done**, and the worked example for these four stages
- **#1352** — move the excalidraw `.mcp.json` out of the plugin into `install-mcp`
- **#1353** — absorb cogni-visual into cogni-workspace
- **#1354** — reconcile docs, marketplace metadata, diagrams and wiki for the reduced roster

#1352 is not itself an absorption; it is a gate one of them depends on, and it stays a
single pull request.

## Related Documents

- [plugin-development.md](plugin-development.md) — how to build a plugin, and the conventions an adopted tree must still satisfy
- [../architecture/plugin-anatomy.md](../architecture/plugin-anatomy.md) — every file type an absorption relocates
