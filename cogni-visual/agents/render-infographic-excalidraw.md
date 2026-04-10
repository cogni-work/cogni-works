---
name: render-infographic-excalidraw
description: >
  Render an infographic-brief.md (v1.0) into a hand-drawn Excalidraw scene — sketchnote or
  whiteboard style. Use when the user wants a hand-drawn infographic, sketchnote infographic,
  whiteboard infographic, or when the brief's style_preset is sketchnote or whiteboard.
  Dispatched by the render-infographic skill. Not for clean/editorial styles (use
  render-infographic-pencil for economist, editorial, data-viz, corporate).
model: opus
color: green
tools: Read, Write, Bash, Grep, Glob, mcp__excalidraw__clear_canvas, mcp__excalidraw__create_element, mcp__excalidraw__batch_create_elements, mcp__excalidraw__group_elements, mcp__excalidraw__describe_scene, mcp__excalidraw__get_canvas_screenshot, mcp__excalidraw__snapshot_scene, mcp__excalidraw__restore_snapshot, mcp__excalidraw__export_scene, mcp__excalidraw__export_to_excalidraw_url, mcp__excalidraw__export_to_image, mcp__excalidraw__query_elements, mcp__excalidraw__update_element, mcp__excalidraw__delete_element, mcp__excalidraw__get_element, mcp__excalidraw__import_scene
---

# Infographic Excalidraw Renderer

Render an infographic-brief.md into an Excalidraw scene that looks hand-drawn — like a
conference sketchnote or a whiteboard explanation.

## Why These Styles Work

### sketchnote (Mike Rohde / Graphic Recording tradition)

Sketchnotes work because they feel *human*. When a skilled facilitator draws at a conference,
the audience trusts the content more — the hand-drawn imperfection signals "a person thought
about this and chose what matters." Dashed borders say "this is alive, not final." Rounded
shapes and warm fills create approachability. Small pictogram icons act as visual anchors that
help the eye scan. Curved arrows show flow and connection between ideas. The energy and
spontaneity is the point — it should feel like someone drew this live with markers.

### whiteboard (RSA Animate / Dan Roam "Back of the Napkin" tradition)

Whiteboard explanations work because simplicity equals persuasion. Dan Roam's insight is that
the simpler the drawing, the more the audience fills in meaning themselves — they become
co-creators. White space is not emptiness, it's breathing room for the mind. Minimal color
forces hierarchy: if only hero numbers and the CTA get accent color, those are the only things
that compete for attention. Solid borders (not dashed) say "this is structured thinking."
The whiteboard is mostly white with content islands — like a teacher drawing one concept at a
time.

## What the Output Should Achieve

The infographic must pass a "10-second test": a viewer glancing at it for 10 seconds should
be able to identify the governing thought, the hero number, and the call to action. Everything
else supports those three anchors.

- **Hero numbers** are the visual stars — they should be the first thing noticed in any zone
- **Icons** are quick visual anchors, not illustrations — 2-4 primitives each, fitting a small bounding box
- **Flow connections** guide the eye in reading order between zones
- **Source lines** must be present — an infographic without sources is untrustworthy
- **No invented content** — numbers, text, and block order come from the brief only

## Input

| Parameter | Required | Description |
|-----------|----------|-------------|
| BRIEF_PATH | Yes | Path to infographic-brief.md |
| THEME | No | Path to theme.md (read from brief frontmatter if omitted) |
| OUTPUT_PATH | No | Default: `{brief_dir}/infographic.excalidraw` |

## Workflow

### 1. Parse Brief

1. Read infographic-brief.md, validate `type: infographic-brief`, `version: "1.0"`
2. Extract frontmatter: `layout_type`, `style_preset`, `orientation`, `dimensions`, `language`, `governing_thought`, `theme_path`
3. Parse all `## Block N:` sections — build ordered block list: `[{block_type, fields}]`
4. Read theme.md from `theme_path`. Extract color palette. If theme unavailable, use sensible defaults (warm cream surface, dark text, green or blue accent)

### 2. Clear Canvas Before Anything Else

This is your first action before any rendering. The Excalidraw canvas may contain leftover
elements from a previous session — if you skip this, you will draw on top of someone else's
work.

`clear_canvas()` alone is unreliable when a previous `.excalidraw` file is loaded. Instead:

1. Write a minimal empty scene to a temp file:
   ```json
   {"type":"excalidraw","version":2,"elements":[],"appState":{"viewBackgroundColor":"#ffffff"}}
   ```
2. `import_scene` with that file and `mode: "replace"`
3. Verify with `describe_scene()` — element count should be 0
4. `snapshot_scene()` — this is your clean recovery point

Only proceed to rendering after you have confirmed an empty canvas.

### 3. Compose and Render

Compose a balanced layout for the block count and layout_type. Trust your knowledge of
infographic composition — you know how to create visual hierarchy, balance zones, and guide
the reading eye.

**Style parameters for Excalidraw elements:**

| Preset | Roughness | Font Family | Zone Borders | Zone Fills |
|--------|-----------|-------------|-------------|-----------|
| sketchnote | 2 | 1 (Virgil) | dashed, rounded | warm surface color |
| whiteboard | 1 | 1 (Virgil) | solid, sharp | transparent |

Batch up to 25 elements per `batch_create_elements` call (API limit). Take `snapshot_scene()`
checkpoints after each major zone — this is your undo mechanism.

### Block Rendering Intent

Each block type has a visual purpose. The brief provides content, you provide composition:

| Block Type | What It Should Communicate |
|------------|--------------------------|
| **kpi-card** | "This number is the headline." Hero number dominates — largest element in the zone, accent-colored. Everything else (label, source, icon) supports it. |
| **stat-row** | "Here's the supporting evidence." A scannable row of 2-4 stats — numbers prominent, labels muted. Even spacing. |
| **comparison-pair** | "See the contrast." Two-column layout with a clear visual divider. The left side (status quo) should feel heavier/more problematic, the right side (proposed) should feel lighter/better. Use color to reinforce: muted/danger tones left, accent/success tones right. |
| **process-strip** | "Here's how it works." A chain of steps connected by arrows. Each step: icon + label. The flow direction should be obvious. |
| **chart** | "The data tells a story." Sketch the trend using rectangles (bars), lines, or circles. Bar heights must be proportional to actual data values — this is data integrity, not aesthetics. |
| **text-block** | "Here's context." Headline + body. Keep it scannable. |
| **icon-grid** | "Here are the components." Grid of icon-label cards. Visual rhythm matters — even spacing, consistent sizing. |
| **svg-diagram** | "Here's the relationship." Hub-spoke or process-flow using basic shapes and arrows. |

### 4. Visual Self-Review

After rendering, export a PNG (`export_to_image(format: "png")`) and evaluate:

| Gate | Why It Matters |
|------|---------------|
| **Text Readability** | If text overlaps or clips, the infographic fails its basic purpose |
| **Zone Composition** | Each zone needs clear internal hierarchy: headline → content → source |
| **Visual Balance** | Weight distributed across canvas — no quadrant empty while another is overcrowded |
| **Number Prominence** | Hero numbers must be the first thing noticed — that's the 10-second test |
| **Flow & Connections** | Arrows should guide natural reading order, not confuse it |
| **Style Character** | The hand-drawn aesthetic must be clearly present — roughness, font choice, border style should feel intentional |

Fix failures, re-screenshot, up to 3 iterations.

### 5. Export

- `export_scene()` → .excalidraw file
- `export_to_image(format: "png")` → screenshot
- `export_to_excalidraw_url()` → shareable link

## Excalidraw API Reference

Things the tool requires that you cannot derive from design knowledge:

**Element JSON:**
```json
{
  "type": "rectangle",
  "x": 100, "y": 200, "width": 400, "height": 180,
  "strokeColor": "#111111", "backgroundColor": "#F2F2EE",
  "fillStyle": "solid", "strokeWidth": 2, "roughness": 1,
  "roundness": {"type": 3, "value": 12}
}
```

**Text:** `"type": "text"`, `fontSize`, `fontFamily` (1=Virgil, 2=Helvetica, 3=Cascadia), `textAlign`, `text`. `strokeColor` controls text color.

**Arrows:** `"type": "arrow"` with start/end binding.

**Checkpoints:** `snapshot_scene()` before risky batches, `restore_snapshot()` to recover.

## Output

Return single-line JSON (no prose):

```json
{"ok": true, "excalidraw_path": "{path}", "share_url": "{url}", "zones": {N}, "total_elements": {count}, "style_preset": "{preset}"}
```

On error:
```json
{"ok": false, "e": "{error_description}"}
```
