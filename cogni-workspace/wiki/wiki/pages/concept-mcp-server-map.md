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
| **excalidraw** | cogni-workspace, cogni-portfolio | Diagram rendering — infographics, concept diagrams, architecture diagrams |
| **claude-in-chrome** | cogni-website, cogni-workspace | Browser automation — preview validation, source-URL fetching for claim verification |
| **pencil** | cogni-workspace, cogni-website | Web narrative, storyboard, poster, hero rendering |

## Installation

`cogni-workspace:install-mcp` is the canonical installer. It clones git-based MCPs, builds them, and writes each server into the user's own config — the top-level `mcpServers` in `~/.claude.json` for Claude Code, `claude_desktop_config.json` for Claude Desktop — referencing the installed wrapper at `$HOME/.claude/mcp-servers/{name}/start.sh`.

## Server discovery convention

No plugin carries a `.mcp.json` — a checked-in declaration claims the server exists on a machine that may never have installed it, and it is spawned at session start regardless. Instead `references/mcp-git-registry.json` is the single declaration: each server entry lists the plugins that need it under `required_by`, and `cogni-workspace:install-mcp` writes only the servers a present plugin actually requires. This keeps the workflow declarative — adding a new MCP-using plugin means adding it to that server's `required_by`, not shipping another config file.

## What each does

- **excalidraw** — programmatic creation, manipulation, and export of Excalidraw scenes. cogni-workspace uses it for hand-drawn rendering (sketchnote, whiteboard styles); cogni-portfolio uses it for portfolio architecture diagrams.
- **claude-in-chrome** — Chrome browser automation. cogni-website uses it for preview validation; cogni-workspace uses it to fetch and inspect source URLs during claim verification.
- **pencil** — programmatic design system generation in `.pen` files. cogni-workspace uses it for editorial infographic rendering (Economist style); cogni-website uses it for hero section rendering and full-page composition.

## Why MCP and not direct Claude tools

Each of these tools needs persistent state across many calls (a canvas, a browser session, a design document). MCP gives that state container; direct tool calls would re-initialize each time.

**Source**: [insight-wave/CLAUDE.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md)
