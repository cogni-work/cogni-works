---
name: install-mcp
description: >-
  End-to-end MCP server installation for the insight-wave ecosystem — clone and
  build git-based MCPs, configure native app MCPs, and patch Claude Desktop's
  config so everything works without manual JSON editing. Use this skill whenever
  the user mentions MCP installation, MCP setup, MCP configuration, "my MCPs
  aren't working", "set up excalidraw", "configure desktop MCPs", "patch desktop
  config", "install MCP servers", "MCP not found", "excalidraw tools not
  available", "update MCP servers", "MCP not loaded", "pencil MCP not working",
  port conflicts with MCP servers (e.g. localhost:3000), or any mention of
  claude_desktop_config.json. Also trigger when manage-workspace needs to handle
  its MCP installation step (step 5), when workspace-status reports MCP servers
  as not loaded and the user wants to fix it, or when a rendering skill
  (render-big-picture, story-to-web) fails because its MCP dependency is missing.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, ToolSearch
---

# Install MCP

## Why This Exists

Plugins in insight-wave depend on MCP servers (Excalidraw for diagrams, Pencil for web
rendering, etc.). No plugin declares a server itself. A checked-in declaration asserts
machine state the repository cannot guarantee, so on a machine that never installed the
server it is spawned at session start and fails visibly. The server is therefore installed
on demand and written into the user's own config, which is the one place that can honestly
say what is available. Git-based MCPs also need cloning and building, and users of either
client used to have to edit that config by hand.

This skill handles the full lifecycle: detect what's needed, install it, configure it
for the user's environment, and verify it works. No manual JSON editing required.

## Detect Environment

Determine the user's runtime environment — this affects what needs patching:

1. **Locate the config to write.** Claude Code reads a user-scope config; Claude Desktop
   reads its own. Check both:
   - Claude Code (all platforms): `~/.claude.json`, top-level `mcpServers`
   - Claude Desktop, macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Claude Desktop, Linux: `${XDG_CONFIG_HOME:-~/.config}/Claude/claude_desktop_config.json`
   - Claude Desktop, Windows: `%APPDATA%/Claude/claude_desktop_config.json`

   Only the top-level `mcpServers` in `~/.claude.json` is user scope. The per-project
   `projects.<path>.mcpServers` objects in that same file are local scope — never write
   there, or the server disappears the moment the user changes directory.

2. **Classify environment:**
   - **Claude Code CLI** — needs the git install AND a `--target cli` write to `~/.claude.json`.
   - **Claude Desktop** — needs the git install AND a `--target desktop` write.
   - **Both** — Desktop config exists alongside CLI usage. Use `--target both`.

Report which environment was detected before proceeding.

## Discover What's Needed

Read the MCP registry to understand what servers exist and which plugins need them:

```bash
REGISTRY="${CLAUDE_PLUGIN_ROOT}/references/mcp-git-registry.json"
cat "$REGISTRY"
```

Cross-reference against installed plugins. There are three ways to determine installed plugins,
in order of preference:

1. **During manage-workspace** — the confirmed plugin list is already available from step 1
2. **Standalone invocation** — discover plugins by scanning the marketplace cache:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/discover-plugins.sh
   ```
3. **Fallback if discover-plugins returns empty** — the plugin cache may be empty in some
   environments. Fall back to scanning sibling directories for a plugin manifest:
   ```bash
   # Scan sibling plugin directories for a plugin manifest
   for dir in $(dirname "${CLAUDE_PLUGIN_ROOT}")/cogni-*; do
     if [ -f "$dir/.claude-plugin/plugin.json" ]; then
       basename "$dir"
     fi
   done
   ```
   This catches the common case where plugins are installed but the cache index is stale.
   Key it on the manifest, the same file `discover-plugins.sh` globs — no plugin ships a
   `.mcp.json` any more, so a scan keyed on that would silently find nothing and report
   success.

For each server in the registry, check if any installed plugin appears in its `required_by`
list. Only install servers that have at least one requiring plugin present.

Present the installation plan to the user before executing:

```
MCP Installation Plan:
  mcp_excalidraw  git clone + build    needed by: cogni-visual, cogni-portfolio
  pencil          native app check     needed by: cogni-visual

  Desktop config:  will be patched (claude_desktop_config.json found)
```

## Install Git-Based MCP Servers

For each server with `"type": "git"` that's needed:

```bash
WRAPPER_REL=$(python3 -c "
import json
reg = json.load(open('${REGISTRY}'))
print(reg['servers']['SERVER_NAME'].get('wrapper', ''))
")

WRAPPER_ARG=""
if [ -n "$WRAPPER_REL" ]; then
  WRAPPER_ARG="--wrapper ${CLAUDE_PLUGIN_ROOT}/${WRAPPER_REL}"
fi

bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-mcp.sh" \
  --name "SERVER_NAME" \
  --repo "REPO_URL" \
  --build "BUILD_CMD" \
  $WRAPPER_ARG
```

The script outputs JSON — parse `success` and `data.action` to report what happened
(installed / skipped / updated / failed). If any server fails, continue with the rest
but flag the failure clearly.

To force-update an already-installed server (e.g. after upstream changes), add `--force`.

## Check Native App MCP Servers

For each server with `"type": "native"`, check whether the binary exists at its
platform-specific path. Don't try to install it — just report:

- **Found** — binary exists, ready to configure
- **Not found** — tell the user where to get it with a direct link:
  - Pencil: download from https://pencil.dev — install the app, then the MCP binary is bundled inside

## Write MCP Servers Into User Config

Run this **after** the git install succeeds — the writer resolves each server's installed
wrapper, and reports `skipped: not installed` rather than writing an entry that points at
a path which does not exist yet.

Pass `--target` for the environment detected above (`desktop`, `cli`, or `both`). Dry-run
first:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/patch-desktop-config.py" \
  --registry "${CLAUDE_PLUGIN_ROOT}/references/mcp-git-registry.json" \
  --target desktop \
  --dry-run
```

Show the user what would change. If they confirm (or if running non-interactively from
manage-workspace), run again without `--dry-run`.

For a Claude Code CLI environment, write the user-scope entry the same way. Scope it with
`--server` so only the server the user actually needs is written — an unrequested entry is
another server spawned at every session start, which is the condition this whole
arrangement exists to avoid:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/patch-desktop-config.py" \
  --registry "${CLAUDE_PLUGIN_ROOT}/references/mcp-git-registry.json" \
  --target cli --server mcp_excalidraw \
  --dry-run
```

The script:
- Creates a timestamped backup before modifying anything
- Preserves every other key in the file — `~/.claude.json` holds unrelated user state
- Skips servers that are already configured (use `--force` to overwrite)
- Handles both git-installed servers (resolves wrapper path) and native apps (platform binary)
- Reports JSON with every action taken

After writing, remind the user to restart: **Claude Desktop** for a desktop write, or the
**Claude Code session** for a CLI write. Newly written servers do not appear in the session
that wrote them.

## Verify Installation

After installation and patching, verify that MCP servers are actually available in the
current session. Use ToolSearch to probe for MCP tool prefixes:

| Server | Probe Tool |
|--------|-----------|
| excalidraw | `mcp__excalidraw__describe_scene` |
| pencil | `mcp__pencil__get_editor_state` |

For each server that was just installed:

```
Use ToolSearch to search for the probe tool.
```

Report status:
- **Loaded** — tools found, server is active
- **Installed but not loaded** — installed successfully, but needs a session restart to appear
- **Failed** — installation reported success but tools not found even after restart

For servers that show "not loaded", this is expected behavior — the user needs to restart
their Claude session (CLI or Desktop) for newly installed MCPs to appear.

## Summary

Present a compact result:

```
MCP Installation Complete:

  Server            Action          Desktop Config    Status
  ────────────────  ──────────────  ────────────────  ──────────
  mcp_excalidraw    installed       patched           loaded
  pencil            binary found    patched           loaded

  Desktop config: backed up to claude_desktop_config.backup-20260409T...json
  Next: restart Claude Desktop if any servers show "not loaded"
```

## When Called from manage-workspace

This skill replaces the inline step 5a/5b logic in manage-workspace. When invoked as
part of workspace init or update:

- Skip the plugin discovery step (use the confirmed plugin list from manage-workspace)
- Skip the user confirmation of the plan (manage-workspace already has user consent)
- Run install + patch + verify in sequence
- Return the summary for manage-workspace to include in its final report

## Error Handling

- If `install-mcp.sh` fails for a server, report the error from `data.error` and continue
  with remaining servers
- If `patch-desktop-config.py` fails, show the error and suggest manual patching as fallback
- If the Desktop config file has invalid JSON, warn the user and skip patching (don't
  corrupt their config further)
- If a backup can't be created (permissions), abort patching and tell the user why
