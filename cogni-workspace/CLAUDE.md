# cogni-workspace

Workspace-level infrastructure for the cogni plugin ecosystem: theme management, shared conventions, MCP server installation, orchestration utilities, and Obsidian vault integration.

## Scope

cogni-workspace is the horizontal layer: it owns shared workspace state and tooling, while each vertical business plugin keeps its own project lifecycle. The dividing rule is the `setup → resume → dashboard` arc — a capability that owns one is its own plugin, a capability that owns none is infrastructure.

- See `references/absorption-roadmap.md` for what cogni-workspace absorbs, what it deliberately leaves with the owning plugin, and the rationale behind each call

## Theme Infrastructure

- `pick-theme` is the entry point for theme selection across all plugins
- Themes live in `themes/` as markdown files describing visual identity
- See `references/design-variables-pattern.md` for the shared convention on producing themed HTML dashboards — any skill generating visual HTML output should follow this pattern
- **Claude Design bundles are the recommended authoring path for tiered themes** (RFC #132 Phase 3): the user mocks the design system at `claude.ai/design`, exports a bundle URL, and `manage-themes` Operation 10 materialises it into the local `themes/<slug>/` directory in one re-syncable step. `scripts/import-claude-design-bundle.py` is the importer; `references/claude-design-bundle-mapping.md` is the mapping contract. The runtime contract through `pick-theme` is unchanged — consumers keep reading the local tier files.

### Pre-PR checks for theme-touching changes

Run the umbrella backwards-compat harness before submitting any PR that
touches `themes/`, `skills/pick-theme/`, `skills/manage-themes/`, or any
consumer plugin's theme-reading surface:

```bash
bash cogni-workspace/scripts/verify-theme-backcompat.sh
bash cogni-workspace/scripts/verify-claude-design-importer.sh  # if the change touches the importer or its mapping doc
```

The harness verifies the Theme System v2 contract end-to-end:

- **Tier-0 invariant.** `discover-themes.py` output for the bundled
  `_template/` theme (via a non-underscore fixture) must match the
  committed snapshot at `scripts/baselines/_template-tier0-output.json`.
  The contract from RFC #124 is "themes without manifest.json must keep
  working exactly as today" — this is the regression test.
- **Tiered invariant.** The `cogni-work` theme must surface
  `tiers.tokens` resolving to a `tokens/` directory containing
  `tokens.css`.
- **Consumer contracts.** Each known visual consumer (cogni-workspace:
  render-html-slides + story-to-* siblings, cogni-portfolio:
  portfolio-dashboard, cogni-website:website-build) and voice consumer
  (cogni-sales, cogni-knowledge, and this plugin's own narrative and copywriter skills) must
  still reference the theme contract in its SKILL.md.

The harness complements the per-skill validators
(`validate-theme-manifest.py`, `check-skill-names.sh`) — those catch
local violations; this catches integration drift across plugins.

`--help` prints a failure-mode triage table mapping each failure to the
likely upstream child issue (#126–#130). The harness runs in CI through the
wrapper suite `cogni-workspace/tests/test-theme-backcompat.sh`, which
`scripts/run-plugin-tests.py` discovers and the "Plugin test suites" job in
`.github/workflows/lint.yml` runs; invoking it manually before a PR still
gives the faster signal. A listed visual consumer whose `SKILL.md` is missing
is a hard failure, not a skip — the check has to fire precisely when the file
it guards has disappeared.

## Language

The `language` key in `.claude/settings.local.json` is the single source of truth for the workspace language. `scripts/generate-settings.sh` writes it, mapping the ISO code in `.workspace-config.json` to the natural-language name the setting expects (`de` → `"german"`). Claude Code turns that key into a `# Language` system-prompt section, so a fresh session responds in the workspace language with no output style and no `CLAUDE.md` — which is why neither is used to carry language rules any more.

What the built-in section does **not** carry travels in `hooks/on-session-start-language.sh`: German orthography (umlauts, ß/ss) and the rule that a user switching language mid-conversation wins over the workspace default. It emits a `SessionStart` `hookSpecificOutput` envelope, or nothing when the language has no rule block. Add a language by adding a `case` branch there — plain stdout is not injected as context, only the parsed `additionalContext` field, so the envelope is required.

Two consequences worth keeping straight:

- **The workspace-root `CLAUDE.md` is the user's file.** Nothing in this plugin creates, copies, or overwrites it. The Obsidian launcher's per-session language switch writes the settings key instead.
- **Subagents get none of this.** A subagent's system prompt is its own body plus a notes block and the environment info — no settings language, no memory. A plugin whose agents produce user-facing prose needs its own `SubagentStart` hook (see cogni-consult).

## MCP Server Installation

- The `install-mcp` skill is the primary entry point for end-to-end MCP setup
- It handles git-based servers (clone + build), native app detection, and writing the user's MCP config
- `scripts/install-mcp.sh` handles clone, build, and wrapper creation into `~/.claude/mcp-servers/<name>/`
- `scripts/patch-desktop-config.py` merges MCP entries into the user's config, with backup — `--target desktop` writes `claude_desktop_config.json`, `--target cli` writes the top-level `mcpServers` in `~/.claude.json` (Claude Code user scope), `--target both` does each in turn. `--server <name>` scopes the write to one registry server
- `references/mcp-git-registry.json` (v2.0) declares both git-based and native app MCPs with platform-specific paths
- `templates/mcp-wrappers/` contains wrapper scripts for MCP servers that need companion processes (e.g. canvas server)
- `manage-workspace` delegates to `install-mcp` during init/update (step 5)
- No plugin ships a `.mcp.json`. A checked-in declaration asserts machine state the repo cannot guarantee — it is spawned at session start even where the server was never installed — so the entry is written to user config at install time instead, pointing at `$HOME/.claude/mcp-servers/<name>/start.sh`
- `tests/test-mcp-declaration-hygiene.sh` keeps that true: no `cogni-*/.mcp.json` exists, the registry still maps `mcp_excalidraw` to the desktop key `excalidraw` (the key MCP tool names derive from, so renaming it silently breaks every `mcp__excalidraw__*` matcher), both plugins' PreToolUse matchers survive, and the two copies of `concept-mcp-server-map.md` stay byte-identical. It carries a per-arm liveness floor so a glob that stops matching cannot make every case pass vacuously

## Markets

`references/supported-markets-registry.json` is the canonical taxonomy — codes, names, locales, currencies, languages, regional qualifiers, regulatory bodies, and the canonical authority-domain set per market. `scripts/get-market-config.py` is the merge utility plugins call: it joins the registry with a plugin overlay (e.g. `cogni-trends/skills/trend-research/references/region-authority-sources.json` for trends-side dimension queries) and returns the merged config in the shape each plugin expects.

Plugins do not duplicate shared market fields. The `manage-markets` skill is the write path for the registry (status + add); `audit-region-sources` is the read-only sibling. Drift between registry and overlays is structurally impossible by design — overlays carry only plugin-specific metadata keyed against registry domains.

## Shared Project Discovery

`scripts/discover-plugin-projects.sh` is a parameterized generic that per-plugin `discover-projects.sh` wrappers (cogni-portfolio, cogni-consult, cogni-trends, …) call to find their projects in any workspace. It owns argument parsing, workspace-root resolution (`--root` > `$PROJECT_AGENTS_OPS_ROOT` > walk-up to the plugin-named ancestor > `$PWD`), registry CRUD (`--register` / `--unregister`), `find`-based discovery across one or more `--find <basename>:<path-glob>:<dirname-levels>` specs, dedup, and JSON envelope output (`{count, search_root, projects[]}`). Per-plugin wrappers supply only the plugin name, registry path, a Python extractor file defining `extract(project_dir) -> dict`, and one or more `--find` specs. The pattern keeps three plugins on one source of truth for cwd handling.

## Obsidian Integration

- Obsidian vault setup and updates are handled as sub-steps of `manage-workspace` (Init Mode step 6, Update Mode step 6)
- `scripts/setup-obsidian.sh` scaffolds a complete `.obsidian/` vault config with Terminal plugin and Claude Code launcher
- `scripts/update-obsidian.sh` incrementally updates terminal profiles without overwriting user customizations
- Both scripts use `bash/portability-utils.sh` for cross-platform support (macOS, Linux, WSL)
- Obsidian templates live in `templates/obsidian/`
- See `references/note-frontmatter-standard.md` for the YAML frontmatter convention used by all plugin outputs

## Wiki Trees

The wiki ships twice: `wiki/` at the repository root is the editing surface maintainers change, and `cogni-workspace/wiki/` is the vendored copy that travels inside this plugin so marketplace users get it in their plugin cache. The two trees are allowed to differ, and they do.

- See `references/wiki-tree-reconciliation.md` for the decisions record covering both trees — every way `wiki/` and `cogni-workspace/wiki/` currently disagree, what was decided for each delta, and what reversing it would cost. Counts and figures live there, each attributed to the command that produced it; read them off the record rather than restating them here, where they would go stale silently.
- `tests/test-wiki-tree-parity.sh` is that record's enforcement arm. It asserts, per tree and never tree-wide: each `.cogni-wiki/config.json` `entries_count` equals a live count of that same tree's pages; every wiki reference in a tree resolves within that same tree — scanning each tree's pages **and** its top-level `index.md` / `log.md` / `overview.md` as link *sources*, not merely resolving them as link *targets*, off one enumeration so the source half cannot go blind while the target half keeps working; and every page present in only one tree is named in the decisions record. It deliberately does **not** assert that the two trees are equal — they are not, by design, and the record explains each surviving difference. So a one-sided page with no decision written down turns the suite red: the fix is to record the decision in `references/wiki-tree-reconciliation.md`, not to route around the guard.
- `tests/test-wiki-bare-name-roster.sh` is that record's content-level enforcement arm. Where the parity suite asserts structure and `test-wiki-namespace-sync.sh` asserts filenames, this one asserts what the pages *say*: no `cogni-…` token anywhere on the scanned surface may name something absent from the live roster. The allowed set is derived at runtime from `.claude-plugin/marketplace.json` `plugins[].name`, never written down, so a plugin retired tomorrow is caught without editing the suite. That surface has two parts: the two-tree basename intersection of the page directories, and a per-tree arm over the explicit `{index.md, overview.md}` tree-level set — scanned once per tree, never as an intersection, because the two `index.md` copies diverge by design and comparing them to each other would skip the pair entirely. `log.md` is in neither part, per the record's Decision 5. Every arm is its own call, and one that cannot see the pages it names or cannot read a roster fails loudly rather than reporting clean. It still carries **zero** path-fragment exclusions: out-of-scope pages fall out of the intersection by construction, and the tree-level set is a two-name allowlist rather than a directory scan minus an exclusion. The declared allowances and the reasoning behind the surface live in the record; read them there rather than here, where they would go stale silently. One of them is the store path whose dispatch form is still caught — the same colon-versus-slash discriminator stated under the claims section below. The fix for a red is to rename the stale name, not to add an exclusion.

## Issue Reporting and Diagnostics

What cogni-help contributed when it was retired. `cogni-issues` survives as a skill; the troubleshoot material — its checks, its catalogue and its evals — is now `workspace-status`'s plugin-level tier, reached by the surviving `/troubleshoot` command. These are the only copies.

- `cogni-issues` is the write path for filing a GitHub issue against any marketplace plugin
- `skills/cogni-issues/scripts/gh-issues-helper.sh` wraps the `gh` CLI (JSON on stdout, errors on stderr); `skills/cogni-issues/scripts/issue-store.sh` maintains the local `issues.json` tracker; `skills/cogni-issues/scripts/resolve-plugin.sh` maps a plugin name to its owning repo, version, and marketplace
- `skills/cogni-issues/references/issue-templates.md` carries the bug / feature / change-request / question body templates that downstream triage parses
- `workspace-status` check 7 diagnoses plugin-level and cross-plugin problems — availability, skill-file integrity, dependency checks, progress/state file health — and reports each finding as Symptom → Cause → Fix, in the same label shape `skills/workspace-status/references/known-issues.md` uses, so a catalogued fix and a fresh diagnosis read identically. `skills/workspace-status/references/plugin-diagnostics.md` carries the procedures behind its six probes
- `skills/workspace-status/references/known-issues.md` is its catalogue of known symptoms and fixes
- `/troubleshoot` keeps its bare, undomained name by decision rather than oversight. The decision was recorded when the name belonged to a skill; the skill has since folded into `workspace-status`, and the decision carries over to the command unchanged. It is the only command of that name in the monorepo, so nothing is mechanically owed and no ambiguity exists to resolve. It also differs in kind from the generic words `scripts/check-skill-names.sh` rejects: `status`, `dashboard` and `resume` are ecosystem-wide nouns several plugins each own a version of, whereas `troubleshoot` names a domain action only this plugin performs. Against that, a domain-prefixed rename would break the command's existing callers, both wiki trees and generated `docs/` — a user-visible break buying no disambiguation
- `commands/troubleshoot.md` registers `/troubleshoot`; it is this plugin's first command file, and since the merge it is the only surface carrying that name
- `tests/test-relocated-skill-hygiene.sh` pins the two properties of every adopted tree that no other guard covers: no source-plugin dispatch token survives, and every `${CLAUDE_PLUGIN_ROOT}` path documented in them resolves under this plugin. It pairs each tree with the token its own source plugin used, so both the cogni-help arm and the cogni-claims arm stay falsifiable

## Claim Verification

Absorbed from cogni-claims when it was retired. These are now the only copies. Claim verification is the cross-plugin quality gate: cogni-trends, cogni-portfolio, cogni-consult and (on the opt-in `knowledge-refresh --resweep` path only) cogni-knowledge submit sourced assertions here and get back a verdict per claim.

- `claims` is the six-mode orchestrator — `submit`, `verify`, `dashboard`, `inspect`, `resolve`, `cobrowse`
- `claim-entity` is the data contract every submitting plugin follows: `ClaimRecord`, `DeviationRecord`, `ResolutionRecord`, with five deviation types, four severity levels and five resolution actions
- `agents/claim-verifier.md` fetches one source URL and verifies every claim against it, returning strict JSON; dispatch one per unique URL, in parallel
- `agents/source-inspector.md` is the cobrowse path — it opens a source in the browser via claude-in-chrome and locates the passage when WebFetch cannot reach it
- `commands/claims.md` registers `/claims`
- `skills/claims/scripts/claims-store.sh` is the JSON state manager

**The on-disk store keeps the name `{working_dir}/cogni-claims/`** — `claims.json`, `sources/`, `history/`. This is deliberate and load-bearing, not leftover debt: those are user files holding the accumulated state of every project already run, and no upgrade hook could find and rewrite them on every user's disk. `references/absorption-roadmap.md` Decision 2 is the standing rationale. When editing anything under `skills/claims/`, the discriminator is the colon: rewrite a `cogni-claims:` dispatch token, never a `cogni-claims/` path.

Verification is live-source: `claims` fetches each cited URL and compares. cogni-knowledge's default pipeline deliberately does **not** use it — `knowledge-verify` scores citations against claims extracted at ingest time, zero-network. The two are different guarantees, and the split is by design.

### Source Fetching Strategy

`claim-verifier` uses **WebFetch** as its sole automated fetch method. On failure (403, timeout, anti-bot, paywall) the claim is marked `source_unavailable` — there is no automatic browser fallback. Unreachable sources are recovered interactively through `/claims cobrowse`, where the user handles authentication, cookie banners and navigation while Claude reads and verifies in real time via claude-in-chrome. `source-inspector` (inspect mode) opens a source in the browser for visual evidence review.

Source cache files record which method succeeded via `fetch_method`. This enum is a **shared cross-plugin contract** — cogni-knowledge's fetch-cache reads and writes the same vocabulary, so keep the two aligned; adding a value is an additive contract change that must be mirrored on both sides:

- `"webfetch"` — the standard automated fetch. Emitted here.
- `"cobrowse_interactive"` — interactive recovery. Emitted here.
- `"webfetch_fulltext"` — a fuller-body primary-tier fetch for dense legal/regulatory text whose standard extract may omit sections. Written by cogni-knowledge's `source-curator`; recognized-but-never-emitted here.
- `"direct"` — a non-web local source already in hand (local file, pasted text, local PDF, interview note). Written by cogni-knowledge's local-source ingest; recognized-but-never-emitted here.

The two recognized-but-never-emitted values exist because this engine is a web-source verifier with neither a fuller-body fetch nor a local-ingest path. Both always record a successfully-held body and carry no negative-cache reason: cogni-knowledge writes them as `status: ok` in its own vocabulary; the equivalent in this engine's source cache, whose statuses are `success` / `failed`, is `status: success`.

## Narrative and Copywriting

Absorbed from cogni-narrative and cogni-copywriting when both were retired. These are now the only copies. Both were stateless file-in/file-out transformers with no project lifecycle of their own, which is what put them on the infrastructure side of the cut-line rule at the top of this file.

- `narrative` transforms structured input into an executive narrative using one of 11 story arcs and, with `--format`, condenses an existing narrative into executive briefs, talking points or one-pagers; `narrative-review` scores the result against quality gates, returning a pass/warn/fail verdict per gate. Agents: `narrative-writer`, `narrative-reviewer`, `narrative-adapter`
- `copywriter` polishes documents with 7 messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB, Inverted Pyramid), arc-aware preservation, and EN/DE-pivot translation across seven languages; `copy-reader` runs parallel stakeholder personas; `copy-json` polishes text fields inside JSON. Agents: `copywriter`, `reader`
- `commands/{narrative,narrative-review,narrative-adapt,copywrite,review-doc}.md` register the five slash commands

**`audit-copywriter` was deleted rather than adopted.** It existed only to diff the two plugins, walking up the directory tree to find them as siblings — a check with no meaning once they are one plugin. `tests/test-arc-reference-sync.sh` replaces its mechanizable half: cases A1–A5 assert arc coverage, element-heading resolution, and byte-exact localized headings between `skills/narrative/references/story-arc/` and the copywriter's `09-preservation-modes/` mirror, with a self-hosted negative case. Its judgment-bearing checks — the word-target paradigm question, technique contradiction, and above all whether a downstream validation rule would *reject* a valid narrative — did not survive mechanization. The suite header names which and why rather than implying the replacement is total.

That guard carries a **shrink-only ratchet**, `KNOWN_UNMIRRORED`. Five upstream arcs (`company-credo`, `engagement-model`, `smarter-service`, `theme-thesis`, `trend-panorama`) have no downstream mirror at all — pre-existing drift, found while writing the guard, and exactly the CRITICAL finding `audit-copywriter`'s C1 was built to report. Case A3 fails if an entry names an arc that is no longer upstream, and fails if an entry has since been mirrored, so the list can only shrink. Adding an arc to it to silence A1 or A2 inverts the guard's purpose.

`skills/copywriter/test-docs/` and `skills/copywriter/test-fixtures/` came across with the skill. They are test **inputs**, not eval run artifacts: `test-fixtures/readability-rule/run.sh` is the standing harness for the translation readability rule, and `test-docs/arc-narrative.md` is also an input to cogni-visual's story-to-web eval — the copywriter CHANGELOG records that dependency explicitly. The 27 eval *run* artifacts under the former `copywriter-workspace/` were pruned; these 18 fixture files were kept.

## Visual Rendering

Adopted from cogni-visual across the absorption stages, and now the only copy: the retirement stage deleted the source tree, so the duplicate window this section used to warn about is closed and `check-skill-names.sh` reports no duplicates. The adopted trees are still graded by their own hygiene arm rather than by a name check — that arm outlived the duplicate window, because what it pins is the absence of a `cogni-visual:` dispatch token in a relocated file, not the uniqueness of a name. The six slash commands landed with the retirement rather than with the first stage, so a command definition never existed in two plugins at once.

- `story-to-slides`, `story-to-web` (scrollable web narratives, and printed-poster storyboards in `mode=storyboard`), `story-to-infographic` turn a narrative with a story arc into a brief for one rendering target; `render-html-slides` and `enrich-report` render; `review-brief` scores a brief from three stakeholder perspectives before rendering. 19 agents came with them, from the per-format renderers (`render-infographic-pencil`, `render-infographic-sketchnote`, `render-infographic-whiteboard`, `storyboard`, `web`, `pptx`, `html-slides`) down to the workers (`concept-diagram-svg`, `editorial-sketch`, `report-html-writer`, `enriched-report-reviewer`)
- `libraries/` is a new tree in this plugin — 17 files of layout vocabulary, arc and CTA taxonomies, and worked example briefs that the rendering skills read at run time
- `commands/` did **not** come across in this stage. A slash command has no host-side tiebreaker when two plugins declare the same name, and no guard catches the collision, so the command definitions land with the deletion instead

**`hooks.json` is a merge, not a copy.** cogni-workspace already declared `SessionStart`; the adopted tree declared a `PreToolUse` matcher for the Excalidraw canvas auto-start. Both are now sibling keys of one `hooks` object. Copying the file over would have silently destroyed both `SessionStart` commands — the destination is the only file in the adoption set that already existed.

**Two guards were repaired because the adoption makes them load-bearing here for the first time.** `tests/test-arc-taxonomy-sync.sh` resolved its story-arc directory by walking out of its own plugin to a sibling, so it had only ever worked inside the monorepo checkout and never in the installed layout; it now roots both inputs at the plugin directory, which is correct precisely because `narrative` lives in this plugin. `tests/test-de-ascii-orthography.sh` self-roots to the plugin directory, so on arrival it scans this entire plugin rather than cogni-visual's tree — it is a sampling guard over a fixed vocabulary, not a general rule. Keeping it that way is a settled decision, recorded in `references/absorption-roadmap.md`: a rule that infers corrupted German from spelling shape alone is red on the base tree, because the same scan root holds deliberate transliteration documented as content, five other languages, and correctly-spelled German that no shape test separates from a substitution. Coverage therefore grows by adding vocabulary rows, not by generalising the matcher — and every inherited row came from the originating plugin's corpus, so a row drawn from this plugin's own trees is what makes the guard load-bearing here.

**Hygiene specs name files, not directories, wherever the destination is shared.** `tests/test-relocated-skill-hygiene.sh` forbids the source plugin's dispatch token inside each adopted tree. That is safe as a directory-level spec only for the six new skill directories, the new `libraries/`, and `references/cartographic-data/`, because other files under this plugin carry the retired colon-form token legitimately: the hygiene suite's own spec table (where the literal is the guard's matching data), this file's discriminator, `references/absorption-roadmap.md`, and the wiki entity pages that document the source plugin. The consumer surfaces that once carried it — `scripts/verify-theme-backcompat.sh`, `skills/manage-themes` and `skills/narrative` — were repointed at the consumer stage of the absorption and no longer do. A directory-level spec over `agents/`, `references/`, `scripts/`, `tests/` or `hooks/` would fail on arrival against files the adoption never touched.
