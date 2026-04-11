---
description: Render an infographic-brief.md as a pixel-precise editorial .pen file via Pencil MCP — The Economist data page style (data journalism, Tufte data-ink discipline, Financial Times visual journalism tradition). Use for "editorial infographic", "Economist infographic", "Economist-style infographic", "The Economist data page", "magazine-style data page", "data journalism infographic", "FT-style infographic", "Tufte data-ink infographic", "data-viz infographic", "corporate infographic", "clean infographic", or when you already know the brief uses economist/editorial/data-viz/corporate style_preset. Direct dispatcher — for style-unknown briefs or auto-routing use /render-infographic instead.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Agent, mcp__pencil__batch_design, mcp__pencil__batch_get, mcp__pencil__export_nodes, mcp__pencil__get_editor_state, mcp__pencil__get_guidelines, mcp__pencil__get_screenshot, mcp__pencil__get_variables, mcp__pencil__open_document, mcp__pencil__set_variables, mcp__pencil__snapshot_layout
---

# /render-infographic-editorial

Render an infographic-brief.md into a pixel-precise editorial .pen file via Pencil MCP — **The
Economist data page** style, in the tradition of data journalism (Edward Tufte's data-ink
discipline, Financial Times visual journalism). Direct dispatcher to the
`render-infographic-pencil` agent — skips the style-preset routing in `/render-infographic`,
so only use this when you already know the brief's `style_preset` is `economist`, `editorial`,
`data-viz`, or `corporate`.

## Usage

```
/render-infographic-editorial [brief_path] [--output <path>]
```

## Behavior

Dispatch the `render-infographic-pencil` agent with any provided arguments. If no brief path
is given, the agent auto-discovers `**/infographic-brief.md` nearby.

```
Agent: render-infographic-pencil
Prompt: Render the infographic brief at {brief_path} into a .pen file. {additional args}
```
