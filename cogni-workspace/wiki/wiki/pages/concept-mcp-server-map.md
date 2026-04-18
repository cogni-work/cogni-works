---
id: concept-mcp-server-map
title: MCP server map (excalidraw, claude-in-chrome, pencil)
type: concept
tags: [mcp, mcp-servers, excalidraw, claude-in-chrome, pencil, cogni-workspace]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md
status: stable
---

Three MCP servers ship with the insight-wave marketplace, mapped to the plugins that consume them. All managed by `cogni-workspace:install-mcp`.

## The map

| Server | Plugins | Purpose |
|--------|---------|---------|
| **excalidraw** | cogni-visual, cogni-portfolio | Diagram rendering — infographics, concept diagrams, architecture diagrams |
| **claude-in-chrome** | cogni-claims, cogni-help, cogni-website, cogni-workspace | Browser automation — verification, issue filing, preview, theme extraction |
| **pencil** | cogni-visual, cogni-website | Web narrative, storyboard, poster, hero rendering |

## Installation

`cogni-workspace:install-mcp` is the canonical installer. It clones git-based MCPs, builds them, configures Claude Desktop, and patches the plugin's `.mcp.json` files to reference installed servers via `$HOME/.claude/mcp-servers/{name}/start.sh`.

## Plugin discovery convention

Each plugin that uses an MCP server carries a `.mcp.json` declaring its dependency. `cogni-workspace:install-mcp` walks all plugins, collects `.mcp.json` references, and ensures the underlying server is installed. This keeps the install workflow declarative — adding a new MCP-using plugin doesn't require updating the workspace installer.

## What each does

- **excalidraw** — programmatic creation, manipulation, and export of Excalidraw scenes. cogni-visual uses it for hand-drawn rendering (sketchnote, whiteboard styles); cogni-portfolio uses it for portfolio architecture diagrams.
- **claude-in-chrome** — Chrome browser automation. cogni-claims uses it to fetch and inspect source URLs during verification; cogni-help uses it for GitHub issue filing; cogni-website uses it for preview validation; cogni-workspace uses it for theme extraction from live sites.
- **pencil** — programmatic design system generation in `.pen` files. cogni-visual uses it for editorial infographic rendering (Economist style); cogni-website uses it for hero section rendering and full-page composition.

## Why MCP and not direct Claude tools

Each of these tools needs persistent state across many calls (a canvas, a browser session, a design document). MCP gives that state container; direct tool calls would re-initialize each time.

**Source**: [insight-wave/CLAUDE.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md)
