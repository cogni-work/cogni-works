# MCP Server Registry

Known MCP servers in the insight-wave ecosystem. Each entry documents which plugin
provides the MCP, how it's installed, and which skills depend on it.

## Installed On Demand (written to user config by install-mcp)

No plugin ships an MCP declaration. Running the `install-mcp` skill installs the server
and writes it into the user's own config — `~/.claude.json` for Claude Code,
`claude_desktop_config.json` for Claude Desktop. A server therefore appears in the config
only once it is actually installed.

### excalidraw (yctimlin/mcp_excalidraw)

- **Provided by:** cogni-visual, cogni-portfolio
- **Type:** git-installed (cloned and built by `cogni-workspace/scripts/install-mcp.sh`)
- **Install path:** `~/.claude/mcp-servers/mcp_excalidraw/`
- **Entry point:** `~/.claude/mcp-servers/mcp_excalidraw/start.sh` (wrapper that starts canvas + MCP)
- **Source repo:** https://github.com/yctimlin/mcp_excalidraw.git
- **Canvas frontend:** React + Excalidraw on localhost:3000 (auto-started by wrapper)
- **Probe tool:** `mcp__excalidraw__describe_scene`
- **Skills:** enrich-report, portfolio-architecture, and the concept-diagram / infographic render agents
- **Features:** WebSocket canvas sync, snapshots, mermaid-to-excalidraw, image export
- **Troubleshooting:**
  - If tools not available: run `manage-workspace` init/update to install, or manually run:
    `bash cogni-workspace/scripts/install-mcp.sh --name mcp_excalidraw --repo https://github.com/yctimlin/mcp_excalidraw.git --wrapper cogni-workspace/templates/mcp-wrappers/excalidraw-canvas.sh`
  - If tools available but canvas not visible: check `http://localhost:3000`
  - To update: run `install-mcp.sh` with `--force` to pull latest and rebuild
  - **Claude Desktop users:** run the `install-mcp` skill to write `claude_desktop_config.json`
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
- **Skills:** claims (cobrowse verification), cogni-issues (GitHub automation), manage-themes (website extraction), website-preview (browser review)
- **Troubleshooting:**
  - If not available: install the Claude-in-Chrome extension in Chrome
  - The extension controls the user's visible Chrome browser — not headless
  - The user must be logged into relevant services (GitHub, etc.) in Chrome

### pencil

- **Type:** Desktop app with bundled MCP server
- **Install:** Download from https://pencil.dev, open the app — MCP auto-starts
- **Probe tool:** `mcp__pencil__get_editor_state`
- **Skills:** story-to-web (web narrative rendering), story-to-storyboard (poster rendering)
- **Note:** Skills that use Pencil tell the user "open Pencil" if the MCP is unavailable.
  This is handled at the skill level, not by cogni-workspace.
- **Troubleshooting:**
  - If not available: open the Pencil desktop app
  - Pencil registers its MCP automatically when running
