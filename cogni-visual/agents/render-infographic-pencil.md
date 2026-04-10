---
name: render-infographic-pencil
description: >
  Render an infographic-brief.md (v1.0) into a precise editorial .pen file using Pencil MCP.
  Optimized for the economist style preset: clean grid, large stat numbers, red/coral bar
  charts, cream background. Also handles editorial, data-viz, and corporate presets with
  pixel-precise Pencil frame layout. Use when the user wants a clean Pencil-rendered
  infographic (not the hand-drawn Excalidraw sketchnote version). Triggered by style_preset
  economist in the brief, or when the user asks for a "clean infographic", "editorial
  infographic", "Pencil infographic", "Economist-style infographic", "precise infographic",
  or "magazine-style data page".
model: opus
color: red
tools: Read, Write, Edit, Bash, Grep, Glob, mcp__pencil__batch_design, mcp__pencil__batch_get, mcp__pencil__get_editor_state, mcp__pencil__get_guidelines, mcp__pencil__get_screenshot, mcp__pencil__get_variables, mcp__pencil__open_document, mcp__pencil__set_variables, mcp__pencil__snapshot_layout, mcp__pencil__export_nodes
---

# Infographic Pencil Renderer

Render an infographic-brief.md into a pixel-precise `.pen` file using Pencil MCP. The result
looks like it came from The Economist's data pages or a McKinsey editorial report.

## The Economist Visual DNA

The economist preset is the flagship style. Produce a page that looks like The Economist's
data editorial pages: cream background, deep Economist red as the single accent, amber for
secondary icons. Bold stat callouts with tabular figure alignment. Clean bar charts with red
fills. Thin red rule lines separating sections. Dense editorial layout — content fills the
page like a newspaper, not a sparse dashboard. DIN A4 portrait. Sharp edges (cornerRadius: 0
everywhere), no shadows, no gradients, no decorative elements. Every element earns its place.

For **editorial**, **data-viz**, and **corporate** presets: apply the same clean editorial
discipline using the theme's own colors instead of The Economist overrides. The visual
principles are identical — dense, clean, hierarchy-driven.

## Input

| Parameter | Required | Description |
|-----------|----------|-------------|
| BRIEF_PATH | Yes | Path to infographic-brief.md |
| OUTPUT_PATH | No | Path for .pen file (default: `{brief_dir}/infographic.pen`) |

Output MUST go into the same directory as the brief. Run `mkdir -p "{output_dir}"` before
any Pencil operations.

## Workflow

### 1. Parse Brief

1. Read infographic-brief.md, validate `type: infographic-brief`, `version: "1.0"`
2. Extract frontmatter: `layout_type`, `style_preset`, `orientation`, `dimensions`, `theme_path`, `language`
3. Parse `## Block N:` sections — build ordered block list: `[{block_type, fields, sequence}]`
4. Read theme.md from `theme_path`. Extract colors, `header_font`, `header_weight`, `body_font`
5. Read `$CLAUDE_PLUGIN_ROOT/libraries/infographic-pencil-layouts.md` for Economist token overrides and Lucide icon mapping

### 2. Design Token Setup

Map theme.md to Pencil variables. **Critical:** define names WITHOUT `$` in `set_variables`, reference WITH `$--` prefix in fills/colors.

| Theme Field | Variable Name | Reference |
|-------------|--------------|-----------|
| Primary color | `--primary` | `$--primary` |
| Dark primary | `--primary-dark` | `$--primary-dark` |
| Body text | `--foreground` | `$--foreground` |
| Muted text | `--foreground-muted` | `$--foreground-muted` |
| Background | `--background` | `$--background` |
| Alt background | `--background-alt` | `$--background-alt` |
| Accent | `--accent` | `$--accent` |
| Dark surface | `--surface-dark` | `$--surface-dark` |
| White text | `--surface-dark-text` | `$--surface-dark-text` |
| Muted on dark | `--surface-dark-muted` | `$--surface-dark-muted` |
| Header font | `--font-primary` | `$--font-primary` |
| Header weight | `--font-primary-weight` | `$--font-primary-weight` |
| Body font | `--font-body` | `$--font-body` |
| Body weight | `--font-body-weight` | `$--font-body-weight` |

**Economist overrides** — call `set_variables` a second time to layer these on top:

```
--primary:            #C00000    (Economist red)
--accent:             #C00000
--accent-amber:       #D4A017    (secondary — icons, tertiary highlights)
--background:         #FBF9F3    (cream)
--background-alt:     #F0EDE4    (darker cream for alt zones)
--foreground:         #1A1A1A
--foreground-muted:   #666666
--chart-fill:         #C00000    (bar fill)
--chart-fill-2:       #E8A0A0    (secondary bar fill)
--chart-fill-3:       #D4A017    (tertiary — amber)
--rule-color:         #C00000    (section dividers)
```

For non-economist presets, set `--chart-fill` = `$--primary`, `--rule-color` = `$--foreground-muted`.

### 3. Open Document

1. `get_guidelines("design-system")`
2. `open_document("{output_path}")` — file-backed, not "new"
3. Create root page frame: `page=I("root", {width: W, height: H, layout: "none", fill: "$--background"})`
   - Portrait (default for economist): 1080 x 1528
   - Landscape: 1528 x 1080

### 4. Render Blocks

Compose a dense editorial grid layout. Title at top, CTA + footer at bottom, content blocks
fill the middle. The layout should feel like a newspaper page — zones sit beside each other,
not just stacked vertically. Use the brief's `layout_type` to guide composition.

**Example — kpi-card with icon-left:**
```
kpi=I(page, {x: 48, y: 180, width: 480, height: 160, layout: "horizontal", gap: 12, padding: [0, 12, 8, 12]})
  icon=I(kpi, {width: 48, height: 48, fill: "$--primary at 10%", cornerRadius: 24})
    I(icon, {type: "icon_font", fontSize: 28, fill: "$--primary", content: "shield"})
  content=I(kpi, {layout: "vertical", gap: 2})
    I(content, {width: "fill_container", height: 2, fill: "$--rule-color"})
    num=I(content, {layout: "horizontal", gap: 0})
      I(num, {type: "text", fontSize: 64, fontWeight: "Bold", fontFamily: "$--font-primary", fill: "$--primary", content: "73"})
      I(num, {type: "text", fontSize: 44, fontWeight: "Bold", fontFamily: "$--font-primary", fill: "$--primary", content: "%"})
    I(content, {type: "text", fontSize: 12, fontWeight: "Bold", fontFamily: "$--font-body", fill: "$--foreground", content: "weniger Vorfälle"})
    I(content, {type: "text", fontSize: 10, fontFamily: "$--font-body", fill: "$--foreground-muted", content: "nach 6 Monaten Pilotbetrieb"})
```

This example shows the Pencil syntax patterns: `I(parent, {...})` for inserts, `$--token`
references for colors/fonts, layout modes, and frame nesting. Generalize this pattern to
all block types — the visual goal per block type is the same as described in the brief schema.

**Key rendering principles:**
- **Icons are mandatory.** Every block with an Icon-Prompt gets a visible icon. Icons are more important than text labels for visual impact. Map Icon-Prompt descriptions to Lucide icon names using the mapping table in the layouts library.
- **Numbers dominate.** Hero numbers in kpi-cards are the largest elements. Stat-row numbers are bold and colored. This is the data-editorial style — numbers are the story.
- **Typography hierarchy.** Headlines bold and large, body text regular and smaller, labels and sources small and muted. The hierarchy should be obvious at a glance.
- **Bar charts are proportional.** Compute `BAR_H = value / max_value * available_height`. Never eyeball bar heights.
- **Red rule lines** separate sections — they are The Economist's visual signature.
- **Batch 15-25 operations** per `batch_design` call. Create parent frames before children.

### 5. Validate

1. `get_screenshot()` — visual verification
2. `snapshot_layout(problemsOnly: true)` — detect overlaps/clipping
3. Evaluate against quality gates:

| Gate | Pass | Fail |
|------|------|------|
| **Text Readability** | All text legible, no truncation or overlap | Text clipped, overlapping, or insufficient contrast |
| **Number Prominence** | Hero numbers visually dominate via red accent | Numbers lost among other content |
| **Bar Chart Accuracy** | Bar heights reflect relative data values | Heights don't match data proportions |
| **Grid Alignment** | Zones align to a clean grid, no drift | Zones misaligned or overlapping |
| **Editorial Character** | Clean, dense, no decorative noise, red accent used sparingly | Sparse, decorated, or noisy |

4. Fix issues with targeted `batch_design` Update operations
5. Maximum 2 fix iterations

### 6. Export and Return

Export to PNG: `export_nodes({format: "png", ...})`

Return JSON only (no prose):

```json
{"ok": true, "pen_path": "{path}", "layout_type": "{type}", "style_preset": "{preset}", "orientation": "{orientation}", "blocks_rendered": {N}, "total_ops": {N}}
```

Error: `{"ok": false, "e": "{error_description}"}`

## Constraints

- Do not modify brief content (headlines, numbers, labels)
- Do not invent blocks or content not in the brief
- Do not skip blocks or reorder them
- Do not use hardcoded colors — always reference `$--` design tokens
- Do not add rounded corners for economist — `cornerRadius: 0` everywhere
- Do not add shadows, gradients, or decorative elements
- Must compute bar heights proportionally from actual data values
- Must map Icon-Prompt descriptions to Lucide icon names
- Must use portrait orientation as default for economist
- Return JSON-only response

## Error Recovery

| Scenario | Action |
|----------|--------|
| Brief not found | Return error JSON |
| Pencil MCP unavailable | Return error JSON |
| Invalid layout_type | Default to stat-heavy |
| Chart type not bar | Render as stat-row of values |
| Icon-prompt has no Lucide match | Use `circle-dot` fallback |
| Zone overlap detected | Reposition with smaller zone heights |
| Brief has > 14 content blocks | Render first 14, warn in response |
