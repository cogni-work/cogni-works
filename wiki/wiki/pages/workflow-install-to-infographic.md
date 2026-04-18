---
id: workflow-install-to-infographic
title: "Workflow: Install to Infographic (first-run)"
type: summary
tags: [workflow, onboarding, first-run, install, infographic, mcp]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/install-to-infographic.md
status: stable
related: [plugin-cogni-workspace, plugin-cogni-visual, concept-mcp-server-map]
---

First-run workflow with insight-wave: install the marketplace, set up your workspace, extract a theme from your company website, and render your first infographic.

## Pipeline

```
install marketplace
   ↓
cogni-workspace:manage-workspace        (initialize workspace)
   ↓
cogni-workspace:install-mcp             (install excalidraw + pencil MCPs)
   ↓
cogni-workspace:manage-themes           (extract theme from your website)
   ↓
cogni-visual:story-to-infographic       (turn narrative into infographic brief)
   ↓
cogni-visual:render-infographic-...     (render via excalidraw or pencil)
```

## Duration

Roughly 30–60 minutes including MCP installation and theme extraction.

## End deliverable

A themed infographic rendered as SVG (Excalidraw) or `.pen` file (Pencil), aligned with your company brand.

## How it works

The workflow is sequenced so you verify each layer before depending on it. [[plugin-cogni-workspace]] is installed first because every other plugin depends on it. `manage-workspace` initializes the directory structure, `install-mcp` brings up the MCP servers ([[concept-mcp-server-map]]), and `manage-themes` extracts your brand colors via `claude-in-chrome` browser automation.

[[plugin-cogni-visual]] then renders an infographic. `story-to-infographic` turns a narrative (e.g., a one-paragraph product positioning) into a structured `infographic-brief.md`. The matching render skill (Pencil for editorial, Excalidraw for sketchnote/whiteboard) then produces the visual. See [[concept-brief-based-rendering]].

## Why this is the first-run workflow

It exercises every layer of the platform — workspace foundation, MCP installation, theme inheritance ([[concept-theme-inheritance]]), brief-driven rendering — in the smallest end-to-end loop. If any layer is misconfigured, the failure surfaces here before bigger workflows hit it.

**Source**: [docs/workflows/install-to-infographic.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/install-to-infographic.md)
