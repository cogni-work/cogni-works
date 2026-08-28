# MCP Server Registry

Known MCP servers in the insight-wave ecosystem. Each entry documents which plugins
need the MCP, how it's installed, and which skills depend on it.

## Installed On Demand (written to user config by install-mcp)

No plugin ships an MCP declaration. Running the `install-mcp` skill installs the server
and writes it into the user's own config — `~/.claude.json` for Claude Code,
`claude_desktop_config.json` for Claude Desktop. A server therefore appears in the config
only once it is actually installed.

### excalidraw (yctimlin/mcp_excalidraw)

- **Needed by:** cogni-portfolio, cogni-workspace
- **Type:** git-installed (cloned and built by `cogni-workspace/scripts/install-mcp.sh`)
- **Install path:** `~/.claude/mcp-servers/mcp_excalidraw/`
- **Entry point:** `~/.claude/mcp-servers/mcp_excalidraw/start.sh` (wrapper that starts canvas + MCP)
- **Source repo:** https://github.com/yctimlin/mcp_excalidraw.git
- **Canvas frontend:** React + Excalidraw on localhost:3000 (auto-started by wrapper)
- **Probe tool:** `mcp__excalidraw__describe_scene`
- **Skills:** enrich-report, portfolio-architecture, and the concept-diagram / infographic render agents
- **Features:** WebSocket canvas sync, snapshots, mermaid-to-excalidraw, image export
- **Troubleshooting:**
  - If tools not available: run `manage-workspace` init/update to install, or run the two
    steps by hand. Both are needed — `install-mcp.sh` only clones and builds; since no
    plugin declaration supplies the entry any more, nothing is configured until the writer
    runs. Anchor every path with `${CLAUDE_PLUGIN_ROOT}`: `install-mcp.sh` runs under
    `set -euo pipefail`, so a repo-relative wrapper path that misses aborts it with no JSON
    output at all.

    ```bash
    bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-mcp.sh" \
      --name mcp_excalidraw \
      --repo https://github.com/yctimlin/mcp_excalidraw.git \
      --wrapper "${CLAUDE_PLUGIN_ROOT}/templates/mcp-wrappers/excalidraw-canvas.sh"

    python3 "${CLAUDE_PLUGIN_ROOT}/scripts/patch-desktop-config.py" \
      --registry "${CLAUDE_PLUGIN_ROOT}/references/mcp-git-registry.json" \
      --target cli --server mcp_excalidraw
    ```
  - If tools available but canvas not visible: check `http://localhost:3000`
  - To update: run `install-mcp.sh` with `--force` to pull latest and rebuild
  - **Pick the write target:** `--target cli` writes `~/.claude.json` (Claude Code),
    `--target desktop` writes `claude_desktop_config.json`, `--target both` does each in
    turn. Whichever is written, the server loads only after a restart — a new Claude Code
    session, or a Claude Desktop restart.
- **Retired sibling:** a url-type `excalidraw_sketch` server (`https://mcp.excalidraw.com`)
  was once offered as a no-install alternative. It was removed after its only documented
  consumer skill ceased to exist, leaving it with no caller; being url-type it never
  spawned a local process, so it was not part of the failing-server problem that moved
  declarations out of plugins.

## Manual Install

These MCPs are not written by install-mcp and require user action.

### claude-in-chrome

- **Used by:** cogni-website, cogni-workspace
- **Type:** Chrome extension (manual install)
- **Requires:** Claude-in-Chrome extension installed in Chrome and active
- **Probe tool:** `mcp__claude-in-chrome__tabs_context_mcp`
- **Skills:** claims (cobrowse verification), cogni-issues (GitHub automation), website-preview (browser review)
- **Troubleshooting:**
  - If not available: install the Claude-in-Chrome extension in Chrome
  - The extension controls the user's visible Chrome browser — not headless
  - The user must be logged into relevant services (GitHub, etc.) in Chrome

### pencil

- **Needed by:** cogni-website, cogni-workspace
- **Type:** Desktop app with bundled MCP server
- **Install:** Download from https://pencil.dev, open the app — MCP auto-starts
- **Probe tool:** `mcp__pencil__get_editor_state`
- **Skills:** story-to-web (web narrative and printed-poster rendering), website-build (homepage hero rendering)
- **Note:** Skills that use Pencil tell the user "open Pencil" if the MCP is unavailable.
  This is handled at the skill level, not by cogni-workspace.
- **Troubleshooting:**
  - If not available: open the Pencil desktop app
  - Pencil registers its MCP automatically when running
