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
- **Consumer contracts.** Each known visual consumer (cogni-visual:
  render-html-slides + story-to-* siblings, cogni-portfolio:
  portfolio-dashboard, cogni-website:website-build) and voice consumer
  (cogni-narrative, cogni-sales, cogni-knowledge, cogni-copywriting) must
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
- It handles git-based servers (clone + build), native app detection, and Claude Desktop config patching
- `scripts/install-mcp.sh` handles clone, build, and wrapper creation into `~/.claude/mcp-servers/<name>/`
- `scripts/patch-desktop-config.py` merges MCP entries into `claude_desktop_config.json` (with backup)
- `references/mcp-git-registry.json` (v2.0) declares both git-based and native app MCPs with platform-specific paths
- `templates/mcp-wrappers/` contains wrapper scripts for MCP servers that need companion processes (e.g. canvas server)
- `manage-workspace` delegates to `install-mcp` during init/update (step 5)
- Plugin `.mcp.json` files reference installed servers via `$HOME/.claude/mcp-servers/<name>/start.sh`

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

## Issue Reporting and Diagnostics

Two skills adopted from cogni-help as part of its retirement. Both work here today; cogni-help keeps its own copies until the retirement lands, so the copies under this plugin are the ones to maintain.

- `cogni-issues` is the write path for filing a GitHub issue against any marketplace plugin
- `skills/cogni-issues/scripts/gh-issues-helper.sh` wraps the `gh` CLI (JSON on stdout, errors on stderr); `skills/cogni-issues/scripts/issue-store.sh` maintains the local `issues.json` tracker; `skills/cogni-issues/scripts/resolve-plugin.sh` maps a plugin name to its owning repo, version, and marketplace
- `skills/cogni-issues/references/issue-templates.md` carries the bug / feature / change-request / question body templates that downstream triage parses
- `troubleshoot` diagnoses plugin-level and cross-plugin problems — availability, skill-file integrity, dependency checks, progress/state file health — and reports each finding as Problem → Cause → Fix
- `skills/troubleshoot/references/known-issues.md` is its catalogue of known symptoms and fixes
- `commands/troubleshoot.md` registers `/troubleshoot`; it is this plugin's first command file
- `workspace-status` keeps the infrastructure-side checks (env vars, themes, settings) — `troubleshoot` does not duplicate them
- `tests/test-relocated-skill-hygiene.sh` pins the two properties of the adopted trees that no other guard covers: no `cogni-help:` dispatch token survives, and every `${CLAUDE_PLUGIN_ROOT}` path documented in them resolves under this plugin
