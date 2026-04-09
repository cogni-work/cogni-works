# cogni-workspace

Workspace-level infrastructure for the cogni plugin ecosystem: theme management, shared conventions, MCP server installation, orchestration utilities, and Obsidian vault integration.

## Theme Infrastructure

- `pick-theme` is the entry point for theme selection across all plugins
- Themes live in `themes/` as markdown files describing visual identity
- See `references/design-variables-pattern.md` for the shared convention on producing themed HTML dashboards — any skill generating visual HTML output should follow this pattern

## MCP Server Installation

- The `install-mcp` skill is the primary entry point for end-to-end MCP setup
- It handles git-based servers (clone + build), native app detection, and Claude Desktop config patching
- `scripts/install-mcp.sh` handles clone, build, and wrapper creation into `~/.claude/mcp-servers/<name>/`
- `scripts/patch-desktop-config.py` merges MCP entries into `claude_desktop_config.json` (with backup)
- `references/mcp-git-registry.json` (v2.0) declares both git-based and native app MCPs with platform-specific paths
- `templates/mcp-wrappers/` contains wrapper scripts for MCP servers that need companion processes (e.g. canvas server)
- `manage-workspace` delegates to `install-mcp` during init/update (step 5)
- Plugin `.mcp.json` files reference installed servers via `$HOME/.claude/mcp-servers/<name>/start.sh`

## Obsidian Integration

- Obsidian vault setup and updates are handled as sub-steps of `manage-workspace` (Init Mode step 6, Update Mode step 6)
- `scripts/setup-obsidian.sh` scaffolds a complete `.obsidian/` vault config with Terminal plugin and Claude Code launcher
- `scripts/update-obsidian.sh` incrementally updates terminal profiles without overwriting user customizations
- Both scripts use `bash/portability-utils.sh` for cross-platform support (macOS, Linux, WSL)
- Obsidian templates live in `templates/obsidian/`
- See `references/note-frontmatter-standard.md` for the YAML frontmatter convention used by all plugin outputs
