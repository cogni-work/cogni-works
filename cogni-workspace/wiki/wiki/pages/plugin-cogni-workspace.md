---
id: plugin-cogni-workspace
title: "cogni-workspace (plugin)"
type: entity
tags: [cogni-workspace, plugin, foundation, themes, mcp, env-vars, workspace]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-workspace/README.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-workspace.md
status: stable
related: [concept-theme-inheritance, concept-mcp-server-map]
---

> **Preview** (v0.6.3) — core skills defined but may change.

Foundation-layer plugin for the insight-wave marketplace. Manages shared infrastructure (env vars, settings), MCP server installation and Desktop config patching, theme management, theme picker, plugin discovery, workspace health, and Obsidian vault integration.

## Layer

[[concept-four-layer-architecture|Foundation layer]]. Every plugin that produces visual HTML output reads themes from cogni-workspace; every plugin needing an MCP server is installed via cogni-workspace.

## Skills

| Skill | Purpose |
|-------|---------|
| `cogni-workspace:manage-workspace` | Initialize or update an insight-wave workspace; the entry point everyone runs first |
| `cogni-workspace:install-mcp` | End-to-end MCP server installation (clone, build, configure, patch Claude Desktop) |
| `cogni-workspace:manage-themes` | Extract themes from live websites (claude-in-chrome), PowerPoint templates, or presets |
| `cogni-workspace:pick-theme` | Standard theme picker called by every visual plugin — see [[concept-theme-inheritance]] |
| `cogni-workspace:workspace-status` | Diagnose workspace health |

(Also bundled: `cogni-workspace:ask` — the wiki query wrapper that points at this plugin's bundled insight-wave wiki.)

## What it owns

- **Themes** — extracted, imported, or selected; consumed by all visual plugins through the design-variables CSS pattern
- **MCP servers** — excalidraw, claude-in-chrome, pencil; managed via the [[concept-mcp-server-map]]
- **Env vars and settings** — shared configuration across all insight-wave plugins
- **Obsidian vault integration** — projects can be browsed in Obsidian natively because all entity outputs are markdown with YAML frontmatter (see [[concept-data-model-patterns]])
- **insight-wave wiki** — bundled at `cogni-workspace/wiki/`, lands in the plugin cache on install, queryable via `cogni-workspace:ask` (this is the wiki you're reading)

## Integration

Foundation for all 13 other plugins. cogni-workspace is the first install — `manage-workspace` initializes the directory structure that every other plugin's project directories live inside. `pick-theme` is called by every visual plugin (cogni-visual, cogni-website, cogni-portfolio dashboards, cogni-trends dashboards).

**Source**: [cogni-workspace README](https://github.com/cogni-work/insight-wave/blob/main/cogni-workspace/README.md) · [plugin guide](https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-workspace.md)
