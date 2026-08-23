---
name: workspace-status
description: "Diagnose and report on the health of an insight-wave workspace. Use this skill whenever the user mentions workspace status, health, or diagnostics — including \"check workspace\", \"is my workspace ok\", something broke, \"diagnose workspace\", \"verify workspace\", or any situation where understanding the workspace state would help resolve a problem. Even if the user doesn't explicitly say status, trigger this skill when they describe symptoms that suggest a misconfigured workspace (missing env vars, plugins not found in the workspace registry, themes not loading, an MCP server not available in the session). Scope is workspace infrastructure; plugin-level and cross-plugin faults — plugin availability, skill-file integrity, cross-plugin dependencies, and progress or state files — belong to the sibling troubleshoot skill; route there instead."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill, ToolSearch
---

# Workspace Status

Diagnose the health of an insight-wave workspace by checking its foundation files, environment variables, plugin registry, themes, dependencies, and MCP servers. The goal is to give the user a clear picture of what's working and what needs attention, with actionable fixes for every issue found.

## Locating the Workspace

Find the workspace using this priority:
1. User-provided path
2. `$PROJECT_AGENTS_OPS_ROOT` environment variable
3. Current working directory

If no `.workspace-config.json` exists at the resolved path, stop and tell the user no workspace was found. Suggest they run `manage-workspace` to create one and explain briefly what a workspace provides (centralized config, plugin discovery, shared themes).

## Running the Checks

Run all seven checks, then present a single consolidated report. The checks are ordered by dependency — foundation must exist before environment makes sense, environment must be correct before plugins can be verified.

### 1. Foundation

These files form the workspace skeleton. Without them, other checks can't run reliably.

| File | Required | What it does |
|------|----------|--------------|
| `.workspace-config.json` | Yes | Stores workspace metadata — version, language, registered plugins, timestamps. All other checks read from this file. |
| `.claude/settings.local.json` | Yes | Environment variables that Claude Code auto-injects. Plugins use these to find each other's paths. |
| `.workspace-env.sh` | No | Same variables exported for non-Claude contexts (Obsidian Terminal, VS Code tasks, CI/CD). Missing means shell-based tooling won't resolve plugin paths. |
| `.claude/output-styles/` | No | Behavioral anchors that shape Claude's communication style. Missing means default communication style. |

Read `.workspace-config.json` to extract: version, language, installed_plugins, created_at, updated_at.

**If a required file is missing**: report CRITICAL and suggest `manage-workspace`. Skip checks that depend on the missing file rather than producing misleading results.

### 2. Environment

Environment variables are the wiring that lets plugins find each other. A broken variable means a plugin can't locate its data directory or discover sibling plugins.

Verify these core variables exist and point to real directories:
- `PROJECT_AGENTS_OPS_ROOT` — workspace root
- `COGNI_WORKSPACE_ROOT` — shared workspace data directory

Then for each plugin listed in `.workspace-config.json`, verify its computed variables:
- `COGNI_{SUFFIX}_ROOT` or `PLUGIN_{SUFFIX}_ROOT` — the plugin's data directory
- `COGNI_{SUFFIX}_PLUGIN` or `PLUGIN_{SUFFIX}_PLUGIN` — the plugin's install path

Read the actual values from `.claude/settings.local.json` (the `env` object) and check that each path exists on disk. Report:
- **Set and valid**: the variable exists and the path resolves
- **Set but broken**: the variable exists but the path doesn't exist (likely a moved or deleted directory)
- **Missing**: expected variable not found in settings

### 3. Plugin Registry

Plugins can drift out of sync — a user might install a new plugin without running `manage-workspace`, or uninstall one without cleaning up the config. This check catches that drift.

Run plugin discovery:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/discover-plugins.sh
```

Compare the discovered plugins against `installed_plugins` in `.workspace-config.json`:

- **Registered and installed**: healthy, no action needed
- **Registered but not installed**: the plugin was removed or its cache was cleared. Suggest running `manage-workspace` to clean up the stale registration.
- **Installed but not registered**: a new plugin is available but the workspace doesn't know about it yet. Suggest running `manage-workspace` to wire it in.

If `discover-plugins.sh` returns `"success": false`, report the error from `data.error` and note that plugin discovery couldn't complete.

### 4. Themes

Themes let visual plugins (slides, big pictures, web narratives) share a consistent look. Missing themes don't break anything, but they limit visual output options.

Run:

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/inspect-themes.py --pretty
```

The script walks the merged theme set (`${CLAUDE_PLUGIN_ROOT}/themes/` and `${COGNI_WORKSPACE_ROOT}/themes/`, workspace shadowing standard) and returns one row per user-visible theme — `_template` and dot-prefixed entries are filtered. For each row, render:

- `tier` — `tier-0` or `tiered (<schema_version>)`
- `tiers_populated` — comma-joined dotted keys (`tokens, assets, components.web, components.deck`) or `(none)`
- `origin` — `claude-design @ <imported_at> (sha256 <prefix>…)` or `local-authored`
- The legacy `Color Palette ✓ / Typography ✓` line (the tier-0 floor — preserve verbatim, including when both signals are absent)

Then check that `${COGNI_WORKSPACE_ROOT}/themes/_template/` exists (needed to create new themes — render `_template/ ✓ present` on a single line under the per-theme rows).

**Strict mode.** When the user request mentions "strict", "deep", "before-PR", or "validate", append `--strict` to the `inspect-themes.py` call. Each tiered theme row then carries `validator: pass` or `validator: FAIL — <first error>` from `validate-theme-manifest.py`. Default invocation must not pass `--strict` (no subprocess fan-out across N themes).

Canonical tier vocabulary: `${CLAUDE_PLUGIN_ROOT}/references/theme-manifest.md`.

#### Theme drift (shadowed slugs)

The picker merges `${CLAUDE_PLUGIN_ROOT}/themes/` (standard, ships with the plugin) with `${COGNI_WORKSPACE_ROOT}/themes/` (user-owned), and workspace copies shadow standard copies when slugs collide. This shadowing is **intentional** — it enables user customisation. The drift advisories below are **informational, not errors**: the picker still resolves a valid theme either way.

The motivating example is `cogni-work`: the standard copy ships a tiered layout (manifest.json, tokens/, components/, `.claude-design-source` sidecar), while an older workspace copy predating tiered themes carries none of it. That older copy silently downgrades the experience, because the picker resolves the workspace copy first.

Run:

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/check-theme-drift.py
```

The script compares the two locations and emits one row per shadowed slug. Slugs that exist on only one side are not reported (that's the normal case, not drift). Statuses:

| Standard | Workspace | Status | Surface text |
|---|---|---|---|
| tier-0 | tier-0, theme.md equal | `identical` | `identical` |
| tier-0 | tier-0, theme.md differs | `workspace_customised` | `workspace customised` |
| tiered | tier-0 | `upgrade_available` | `upgrade available — workspace copy is tier-0, standard is tiered` |
| tiered | tiered, manifest or tokens.css differs | `tier_drift` | `tier drift — standard manifest sha X, workspace sha Y` |
| tier-0 | tiered | `workspace_ahead` | `workspace ahead` |

When `.claude-design-source` sidecars differ in URL or sha256, the advisory appends `standard imported from bundle X; workspace imported from bundle Y`. A sidecar mismatch on otherwise-identical files promotes the row to `workspace_customised` so the divergence surfaces.

`identical` rows are not surfaced in the default report (they're not a problem). Detailed mode shows them.

### 5. Dependencies

External tools that scripts rely on. Required dependencies block core functionality; optional ones limit specific features.

Run:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-dependencies.sh
```

The script returns JSON with each tool's availability and version. Report:
- **Required** (jq, python3): must be installed for scripts to work. If missing, tell the user what to install and how (`brew install jq`, etc.).
- **Optional** (curl, git, bc): nice to have. Note what functionality is limited without them.

If `check-dependencies.sh` returns `"success": false`, report which required tools are missing.

### 5.5. Optional Python Packages

Some plugins ship pip-backed optional fallbacks provisioned by `manage-workspace`
into an isolated venv at `~/.claude/workspace-python-venv/` (e.g. cogni-knowledge's
`pypdf` text-layer PDF fallback). These are always optional — their absence limits
a specific feature, it never blocks core functionality.

Run:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-workspace-python-deps.sh
```

The script returns JSON with `data.venv_present`, a per-package `available` /
`version` / `required_by` list, and `missing_optional`. Report:
- **venv present + all packages importable** → OK.
- **packages missing (or venv absent)** → WARNING, never CRITICAL. Tell the user
  to run `/cogni-workspace:manage-workspace` (or `install-workspace-deps.sh`
  directly) to provision them, and name which feature is limited (from
  `required_by`).

`check-workspace-python-deps.sh` always returns `"success": true` (every package
is optional), so treat a non-empty `missing_optional` as an advisory, not a failure.

### 6. MCP Servers

MCP servers power visual rendering (Excalidraw, Pencil), browser automation (claude-in-chrome),
and other capabilities. No plugin declares an MCP server itself — `install-mcp` installs
each one on demand and writes it into the user's own config, so what is configured always
reflects what is actually installed. This check verifies that required MCPs are available
in the current session.

Read `${CLAUDE_PLUGIN_ROOT}/skills/workspace-status/references/mcp-registry.md` for the full
list of ecosystem MCPs and which plugins need them. Read
`${CLAUDE_PLUGIN_ROOT}/references/mcp-git-registry.json` for any server's `desktop_config_key`
and install metadata — only `excalidraw`'s key is spelled out inline below, so look `pencil`'s
up there rather than assuming it.

**Detection approach**: Probe each known server's one representative tool with `ToolSearch`
using the `select:` prefix — a returned tool definition means the MCP is loaded, no match
means it is not available. The **Install** column decides how a missing server is reported:

| MCP Server | Probe tool | Needed by | Install |
|------------|-----------|-----------|---------|
| `excalidraw` | `mcp__excalidraw__describe_scene` | cogni-portfolio, cogni-workspace | install-mcp |
| `claude-in-chrome` | `mcp__claude-in-chrome__tabs_context_mcp` | cogni-website, cogni-workspace | manual (Chrome extension) |
| `pencil` | `mcp__pencil__get_editor_state` | cogni-website, cogni-workspace | manual (Pencil desktop app) |

**Report format**:

- **Loaded**: The MCP tools are available in this session
- **Not loaded**: An `install-mcp` server that is needed but not available. `ToolSearch`
  alone cannot say why — it returns the same no-match in every case — and the install is
  two independent steps, so read two pieces of state before advising:
  - the **config entry** — the server's `desktop_config_key` (`excalidraw` for the registry
    server `mcp_excalidraw`) in the config of the host **this session runs in**: the
    top-level `mcpServers` in `~/.claude.json` under Claude Code, or the same key in
    `claude_desktop_config.json` under Claude Desktop. Only that host's config feeds the
    table below — an entry present solely in the *other* host's config leaves this one
    unconfigured, and counting it lands on the restart row for a write that never happened
    here
  - the **install directory** — `$HOME/.claude/mcp-servers/mcp_excalidraw/start.sh`, named
    for the registry **server name**, not the config key

    This is the canonical statement of the key-to-directory rule: the dashboard install
    probe, `skills/workspace-dashboard/references/dashboard-sections.md` and
    `skills/install-mcp` all point here rather than restating it. `$CLAUDE_MCP_DIR`, when
    set to a non-empty value, replaces the `$HOME/.claude/mcp-servers` base.

  | Config entry (this host) | `start.sh` | State | Advise |
  |---|---|---|---|
  | absent | absent | never installed | route to `/cogni-workspace:install-mcp` |
  | absent | present | built but not configured | re-run the config write — `/cogni-workspace:install-mcp` |
  | present | absent | configured but not built, or the install directory was deleted | re-run `/cogni-workspace:install-mcp` to clone and build — this is the state that surfaces a *failed* server under `/mcp`, because the config entry points at a `start.sh` that is not there |
  | present | present | configured, but not loaded in this session | advise a session restart |

  A restart *on its own* only fixes the configured-but-not-loaded row: `install-mcp.sh` clones
  and builds, and nothing is configured until `patch-desktop-config.py` runs — so wherever a
  step is missing the write or the build comes first and the new session follows it, never
  instead of it. If a restart does not clear it, first re-check that the entry is in *this*
  host's config — a server written only with `--target desktop` is absent from
  `~/.claude.json` and needs a `--target cli` write, not a restart — and only then treat it
  as a failed spawn (a broken build or a port conflict). Both steps are documented in the
  `mcp-registry.md` read at the top of this check
- **Manual**: The MCP is a manual install — the Claude-in-Chrome browser extension or the
  Pencil desktop app. Name what to fetch and inform the user, but don't flag as an error;
  a missing manual server is not the "Not loaded" case above. The two differ in one way that
  matters: `claude-in-chrome` has no registry entry and so no config entry at all, whereas
  `pencil` is a registry `native` server whose `pencil` config entry `install-mcp` still
  writes. So if Pencil is installed and running and its tools are still missing, check for the
  `pencil` key in the config of the host this session runs in — `~/.claude.json` under
  Claude Code, `claude_desktop_config.json` under Claude Desktop — and run
  `/cogni-workspace:install-mcp` for that target if it is absent, before telling the user to
  open the app

Only check MCPs for plugins that are actually installed (cross-reference with the plugin
registry from Check 3).

## Status Report

Present results as a compact summary. Use OK / WARNING / CRITICAL status per category:

```
Workspace Status: /path/to/workspace
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Foundation:   OK       | 4/4 files present
Environment:  OK       | 12 vars set, 0 missing
Plugins:      OK       | 5 registered, 5 installed
Themes:       OK       | 3 themes available, 1 tiered, 0 drift advisories
Dependencies: OK       | 2/2 required, 3/3 optional
Python pkgs:  OK       | venv present, 1/1 optional importable
MCP Servers:  OK       | 3/3 loaded (2 manual)

Language: EN | Last updated: 2026-03-04
```

**Expand any category that isn't OK** with specifics and a fix:

```
Plugins:      WARNING  | 5 registered, 6 installed
  New: the `narrative` skill (installed but not registered)
  -> Run manage-workspace to register it

Environment:  WARNING  | 12 vars set, 2 broken
  Broken: COGNI_NARRATIVE_ROOT -> /path/does/not/exist
  Broken: COGNI_NARRATIVE_PLUGIN -> /path/does/not/exist
  -> Run manage-workspace to refresh environment variables (an update also
     removes generated vars for plugins no longer installed)

Themes:       WARNING  | 2 themes available, 1 tiered, 1 drift advisory
  cogni-work   workspace  tiered (1.0) | tokens, assets, components.web, components.deck
                          origin: claude-design @ 2026-05-18T09:35:13Z (sha256 b23aec46…)
                          Color Palette ✓ | Typography ✓
  _template/ ✓ present

  Drift: cogni-work — upgrade available — workspace copy is tier-0, standard is tiered
    standard imported from bundle https://api.anthropic.com/v1/design/h/X9LG…
  -> Run `manage-themes` to refresh the workspace copy (overwrites local edits)

MCP Servers:  WARNING  | 1/3 loaded (2 manual)
  excalidraw   built but not configured — start.sh present, no `excalidraw` key in this host's config (`~/.claude.json`, Claude Code)
    -> Run /cogni-workspace:install-mcp to write the config entry, then start a new session
  pencil       manual install — Pencil desktop app not running
    -> Open Pencil (https://pencil.dev); informational, not an error
```

Every issue should end with a concrete next step — either a skill to run (`manage-workspace`, `manage-themes`) or a command to execute.

## Quick vs Detailed Mode

- **Quick** (default): the compact summary above, expanding only categories with issues
- **Detailed**: expand all categories regardless of status — show every file path, every env var value, every theme name, every dependency version. Use this when the user explicitly asks for details, runs a diagnosis, or says something like "show me everything"
