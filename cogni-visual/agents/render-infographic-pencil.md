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

# Infographic Pencil Renderer Agent

Render an infographic-brief.md into a pixel-precise `.pen` file using Pencil MCP tools. Produces
The Economist-style editorial infographics with bold stat callouts, clean bar charts, and
disciplined red accent on cream background.

## Mission

Read an infographic-brief.md, execute Pencil MCP operations to create a complete single-page
editorial infographic, and return JSON status.

## When to Use

- User has an infographic-brief.md with `style_preset: economist`, `editorial`, `data-viz`, or `corporate`
- After story-to-infographic skill has produced a brief
- User asks to "render the infographic with Pencil", "create a clean infographic", "Economist-style render"

**Not for:** Hand-drawn sketchnote infographics (use render-infographic skill with Excalidraw).
**Not for:** Creating briefs from narratives (use story-to-infographic skill).

## Input Requirements

| Parameter | Required | Description |
|-----------|----------|-------------|
| BRIEF_PATH | Yes | Path to infographic-brief.md |
| OUTPUT_PATH | No | Path for the .pen file (default: `{brief_dir}/infographic.pen`) |

## Output Path Resolution

> **CRITICAL:** All output MUST go into the same directory as the brief (which should be a `cogni-visual/` subdirectory). NEVER create output files or directories in the brief's parent directory.

```text
brief_dir = dirname(BRIEF_PATH)
output_path = OUTPUT_PATH if provided, else "{brief_dir}/infographic.pen"
output_dir = dirname(output_path)
```

**Before any Pencil MCP operations**, run via Bash: `mkdir -p "{output_dir}"`

## Workflow

### Step 1: Read and Parse Brief

1. Read the infographic-brief.md file
2. Parse YAML frontmatter for configuration:
   - `layout_type`, `style_preset`, `orientation`, `dimensions`
   - `theme_path`, `language`, `customer`, `provider`
   - `governing_thought`, `arc_type`, `arc_id`
3. Extract all block specifications: iterate through `## Block N:` sections and parse their fenced YAML
4. Build ordered block list: `[{block_type, fields, sequence}]`
5. Identify title block, CTA block, and footer block separately from content blocks
6. **Read theme.md** from the `theme_path` specified in frontmatter. Extract all color values, `header_font`, `header_weight`, `body_font`. If unavailable, fall back to `header_font: "Inter"`, `header_weight: "Bold"`, `body_font: "Inter"`.
7. **Read infographic-pencil-layouts.md** from `$CLAUDE_PLUGIN_ROOT/libraries/infographic-pencil-layouts.md` for block frame recipes and grid position tables.

### Step 2: Set Up Design Tokens

Map theme.md to Pencil MCP design tokens using `set_variables`:

> **WARNING:** The `$` prefix is reference syntax only — NOT part of the variable name.
> In `set_variables`, define names WITHOUT `$`. In fills/colors/fonts, REFERENCE with `$--` prefix.

| Theme.md Field | Variable Name (set_variables) | Reference (in fills) |
|----------------|-------------------------------|---------------------|
| Primary color | `--primary` | `$--primary` |
| Dark primary | `--primary-dark` | `$--primary-dark` |
| Body text color | `--foreground` | `$--foreground` |
| Muted text | `--foreground-muted` | `$--foreground-muted` |
| Background | `--background` | `$--background` |
| Alt background | `--background-alt` | `$--background-alt` |
| Accent color | `--accent` | `$--accent` |
| Dark surface | `--surface-dark` | `$--surface-dark` |
| White text | `--surface-dark-text` | `$--surface-dark-text` |
| Muted on dark | `--surface-dark-muted` | `$--surface-dark-muted` |
| Header font | `--font-primary` | `$--font-primary` |
| Header weight | `--font-primary-weight` | `$--font-primary-weight` |
| Body font | `--font-body` | `$--font-body` |
| Body weight | `--font-body-weight` | `$--font-body-weight` |

**Then apply economist overrides** (if `style_preset == economist`):

Call `set_variables` a second time with the economist-specific overrides from
`infographic-pencil-layouts.md` — Economist Design Token Overrides section. This layers
red/cream/amber on top of the theme's base tokens without modifying the theme file.

For all presets, also set these infographic-specific tokens:
- `--chart-fill`: same as `$--primary` (or `#C00000` for economist)
- `--chart-fill-2`: lighter variant of primary (or `#E8A0A0` for economist)
- `--chart-fill-3`: same as `$--accent` (or `#D4A017` for economist)
- `--rule-color`: same as `$--primary` (or `#C00000` for economist)

### Step 3: Load Resources and Open Document

1. Load style guide: `get_style_guide(name="editorial")` — economist inherits editorial aesthetics
2. Load design guidelines: `get_guidelines("design-system")`
3. **Open document at explicit file path** using `open_document("{output_path}")` — NOT `open_document("new")`. File-backed doc required for reliable rendering.
4. The `mkdir -p` was already run during Output Path Resolution.

### Step 4: Create Page Canvas

Determine canvas dimensions from orientation (DIN A4 ratio 1:1.414):
- **Portrait (default for economist):** 1080 x 1528
- **Landscape:** 1528 x 1080

Create root page frame via `batch_design`:

```
page=I("root", {width: CANVAS_W, height: CANVAS_H, layout: "none", fill: "$--background"})
```

This single frame is the entire infographic page. All subsequent zones are children of this
frame, positioned absolutely using x/y coordinates from the grid position tables.

### Step 5: Render Title Block

Look up title zone coordinates from the grid position table for the brief's `layout_type`.
Create the title zone as the first content batch.

Example for stat-heavy portrait:
```
title=I(page, {x: 48, y: 48, width: 984, height: 140, layout: "vertical", gap: 8, padding: [24, 0, 16, 0]})
headline=I(title, {type: "text", fontSize: 40, fontWeight: "Bold", fontFamily: "$--font-primary", fill: "$--foreground", content: "{brief.title.Headline}"})
rule=I(title, {width: "fill_container", height: 2, fill: "$--rule-color"})
subline=I(title, {type: "text", fontSize: 18, fontFamily: "$--font-body", fill: "$--foreground-muted", content: "{brief.title.Subline}"})
meta=I(title, {type: "text", fontSize: 11, fontFamily: "$--font-body", fill: "$--foreground-muted", content: "{brief.title.Metadata}"})
```

**Ops in this batch:** ~5-6

### Step 6: Render Content Blocks

Iterate through the brief's content blocks in sequence order. For each block:

1. Look up the zone position from the grid table (layout_type x block sequence)
2. Look up the frame recipe from infographic-pencil-layouts.md (block type)
3. Build the `batch_design` operations, substituting brief field values into the recipe
4. Execute one `batch_design` call per block (target 15-25 ops)

**Block-specific rendering notes:**

#### kpi-card
- Split `Hero-Number` into digits and unit: "73%" → "73" + "%", "4x" → "4" + "x"
- Hero number in `$--primary` — size depends on zone width (see layout library)
- Red top-rule line (2px) is the Economist signature
- **ALWAYS render the icon.** Every kpi-card has an Icon-Prompt — map it to a Lucide icon
  name and render it prominently. Wide zones (>=480px): icon-left in a tinted circle.
  Narrow zones (<480px): icon-top next to rule line. Icons are NOT optional — they are
  a defining visual element of the Economist style.

#### stat-row
- Compute item width: `zone_w / N_stats`
- Insert 1px vertical dividers between stat items
- Numbers in `$--primary` at 36px bold

#### chart (bar)
- Compute bar dimensions from data values:
  ```
  max_value = max(values)
  BAR_MAX_H = zone_h - 80
  For each bar i:
    BAR_H = round(values[i] / max_value * BAR_MAX_H)
    BAR_W = min(60, (zone_w - 32 - (N-1)*12) / N)
    BAR_X = 16 + i * (BAR_W + 12)
    BAR_Y = BAR_MAX_H - BAR_H
  ```
- Bar fill: `$--chart-fill` (red for economist)
- Value label above each bar at (BAR_X, BAR_Y - 18), 14px bold
- Axis labels below in label-row, 11px muted
- For multi-dataset: grouped bars, first dataset `$--chart-fill`, second `$--chart-fill-2`
- For non-bar chart types (doughnut, line, radar): render as stat-row of values

#### process-strip
- Portrait: vertical layout with `chevron-down` connectors
- Landscape: horizontal layout with `chevron-right` connectors
- Icons in `$--accent-amber`, labels in `$--foreground`

#### comparison-pair
- 2px red vertical divider between columns
- Left column: muted labels (grey), Right column: primary labels (red)
- Structurally parallel bullets

#### icon-grid
- 2 columns for portrait, 3 for landscape
- Icons in `$--accent-amber` (amber for economist), rendered in circular tinted frames
- Map `icon-prompt` to Lucide icon names using the mapping table in the layouts library

#### Icons — global rule
Icons are a defining visual element of The Economist infographic style. They appear as
colored symbols (red for kpi-cards, amber for stat-rows and text-blocks) in circular
tinted frames or standalone. **Every block that has an Icon-Prompt MUST render its icon.**
Never skip icons to save operations — they are more important than text labels for the
visual impact of the page.

#### svg-diagram
- For economist preset: render as icon-grid (hub as header, spokes as grid items)
- For other presets: render as icon-grid for hub-spoke, process-strip for process-flow

### Step 7: Render CTA Block

If the brief has a CTA block:
- Red background band (`$--primary`), full width
- White headline text, inverted button (white bg, red text)
- cornerRadius: 0 for economist (sharp edges)

### Step 8: Render Footer Block

- 1px red top rule line
- Three-column text layout: left (customer), center (date), right (provider)
- Source line below in 11px muted
- Combine CTA + footer in one `batch_design` call (~15 ops)

### Step 9: Validate

1. **Screenshot the full page** using `get_screenshot` for visual verification
2. **Run `snapshot_layout(problemsOnly: true)`** to detect overlapping or clipped elements
3. Evaluate against 5 quality gates:

| Gate | Check | Fix Strategy |
|------|-------|-------------|
| 1. Text Readability | No truncation, no overlap, sufficient contrast on cream | Reduce font size or truncate with ellipsis |
| 2. Number Prominence | Hero numbers visually dominate their zones via red accent | Increase font size or add more padding |
| 3. Bar Chart Accuracy | Bar heights reflect actual relative data values | Recompute BAR_H formula |
| 4. Grid Alignment | All zones snapped to grid positions, no drift | Reposition with batch_design Update |
| 5. Editorial Character | Clean — no decorative noise, red accent used sparingly | Remove stray elements |

4. If issues found, fix with targeted `batch_design` Update operations
5. Maximum 2 fix iterations — take another screenshot after fixes to verify

### Step 10: Return JSON

**Success:**

```json
{"ok": true, "pen_path": "{output_path}", "layout_type": "{type}", "style_preset": "{preset}", "orientation": "{orientation}", "blocks_rendered": {N}, "total_ops": {N}}
```

**Error:**

```json
{"ok": false, "e": "{error_description}"}
```

## Batching Strategy

Aim for 15-25 operations per `batch_design` call. Typical approach:

**Batch 1:** Page frame + title zone (headline, rule, subline, metadata) — ~6 ops
**Batch 2-N:** One batch per content block — 8-25 ops each depending on block type
**Final batch:** CTA zone + footer zone — ~15 ops

**Typical operation counts by block type:**
- kpi-card: ~8 ops
- stat-row (4 stats): ~19 ops
- chart (5 bars): ~13 ops
- process-strip (5 steps): ~19 ops
- comparison-pair (4 bullets each): ~16 ops
- icon-grid (6 items): ~25 ops (may need 2 batches)
- text-block: ~5 ops
- cta: ~6 ops
- footer: ~9 ops

**Total for typical stat-heavy infographic:** 6-10 batch calls, 80-140 total operations.

## Constraints

- DO NOT modify brief content (headlines, numbers, labels)
- DO NOT invent blocks or content not in the brief
- DO NOT skip blocks or reorder them
- DO NOT use hardcoded colors — always reference design token variables (`$--primary` etc.)
- DO NOT add rounded corners for economist preset — `cornerRadius: 0` everywhere
- DO NOT add shadows, gradients, or decorative elements
- MUST apply economist token overrides when `style_preset == economist`
- MUST compute bar heights proportionally from actual data values
- MUST map icon-prompt descriptions to Lucide icon names
- MUST use portrait orientation as default for economist preset
- Return JSON-only response (no prose)

## Error Recovery

| Scenario | Action |
|----------|--------|
| Brief not found | Return error JSON |
| Pencil MCP unavailable | Return error JSON with tool status |
| Invalid layout_type | Default to stat-heavy |
| Chart type not bar | Render as stat-row of values |
| Icon-prompt has no Lucide match | Use `circle-dot` fallback |
| Zone overlap detected by snapshot_layout | Reposition with smaller zone heights |
| Brief has > 8 content blocks | Render first 8, warn in response |
