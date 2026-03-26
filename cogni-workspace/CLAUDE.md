# cogni-workspace

Workspace-level infrastructure for the cogni plugin ecosystem: theme management, shared conventions, orchestration utilities, and Obsidian vault integration.

## Theme Infrastructure

- `pick-theme` is the entry point for theme selection across all plugins
- Themes live in `themes/` as markdown files describing visual identity
- See `references/design-variables-pattern.md` for the shared convention on producing themed HTML dashboards — any skill generating visual HTML output should follow this pattern

## Obsidian Integration

- `setup-obsidian` scaffolds a complete `.obsidian/` vault config with Terminal plugin and Claude Code launcher
- `update-obsidian` incrementally updates terminal profiles without overwriting user customizations
- Both scripts use `bash/portability-utils.sh` for cross-platform support (macOS, Linux, WSL)
- See `references/note-frontmatter-standard.md` for the YAML frontmatter convention used by all plugin outputs
