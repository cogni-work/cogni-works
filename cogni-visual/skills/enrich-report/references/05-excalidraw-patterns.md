# Excalidraw Concept Diagram Patterns

Element recipes for generating concept diagrams via Excalidraw MCP, themed with design-variables colors. Each pattern describes the spatial layout, element types, and color mapping.

## General Principles

1. **Theme colors:** Map design-variables to Excalidraw element properties:
   - `backgroundColor` → `colors.surface` or `colors.accent` (fills)
   - `strokeColor` → `colors.primary` or `colors.text` (borders)
   - Text `color` → `colors.text` or `colors.text_light` (on dark backgrounds)
   - Arrow `strokeColor` → `colors.accent` or `colors.secondary`

2. **TIPS dimension colors** (hardcoded brand identity):
   - Trend: `#F59E0B` (amber)
   - Implication: `#06B6D4` (cyan)
   - Possibility: `#8B5CF6` (purple)
   - Solution: `#22C55E` (green)

3. **Element sizing:**
   - Boxes: 200x80px (standard), 240x100px (large/hero)
   - Text: 16px body, 20px headings, 14px labels
   - Arrows: 2px stroke, round endpoints
   - Padding: 20px between elements, 40px between columns

4. **Export:** After building all elements, export as SVG via `mcp__excalidraw__export_to_image` with transparent background. Target width: 720px (matches chart container width).

5. **Canvas cleanup:** Clear the canvas (`mcp__excalidraw__clear_canvas`) before each diagram to prevent element bleed between diagrams.

## Diagram Patterns

---

### `tips-flow` — T→I→P→S Value Chain

**Layout:** 4-column horizontal flow, left to right.

```
[Trend]  →  [Implication 1]  →  [Possibility 1]  →  [Solution 1]
             [Implication 2]     [Possibility 2]     [Solution 2]
                                                      [Foundation]
```

**Element recipe:**

| Column | X offset | Color | Shape |
|--------|----------|-------|-------|
| Trend (1 box) | 0 | `#F59E0B` fill, white text | rounded rectangle 220x90 |
| Implications (1-3 boxes) | 300 | `#06B6D4` fill, white text | rounded rectangle 200x70 |
| Possibilities (1-3 boxes) | 560 | `#8B5CF6` fill, white text | rounded rectangle 200x70 |
| Solutions (1-3 boxes) | 820 | `#22C55E` fill, white text | rounded rectangle 200x70 |

**Y positioning:** Stack boxes vertically with 20px gap. Center each column vertically relative to the tallest column.

**Arrows:**
- Trend → each Implication: straight horizontal arrow, 2px, `#333333`
- Each Implication → relevant Possibility: straight horizontal arrow
- Each Possibility → relevant Solution: straight horizontal arrow

**Column headers:** Small text label above each column: "TREND", "IMPLICATIONS", "POSSIBILITIES", "SOLUTIONS" (or German: "TREND", "IMPLIKATIONEN", "MÖGLICHKEITEN", "LÖSUNGEN"). Font size 12px, color `colors.text_muted`, uppercase.

**Foundation row:** If foundation requirements exist, add a horizontal bar below Solutions: full-width rectangle (820x40px) at Y = bottom + 30px, `colors.surface` fill, `colors.border` stroke, text centered.

**Total elements:** 15-25 depending on chain complexity.

**Excalidraw MCP calls:**
1. `clear_canvas`
2. `batch_create_elements` — all rectangles + text labels
3. `batch_create_elements` — all arrows (after elements exist for binding)
4. `export_to_image` — format: svg, width: 720

---

### `relationship-map` — Theme Interconnections

**Layout:** Central hub with radiating spokes to theme nodes.

```
            [Theme 2]
               |
[Theme 1] --- [Hub] --- [Theme 3]
               |
            [Theme 4]
```

**Element recipe:**

| Element | Position | Style |
|---------|----------|-------|
| Hub circle | center (360, 250) | `colors.accent` fill, 80px radius, "Interconnections" label |
| Theme nodes | radial, 200px from center | `colors.surface` fill, `colors.primary` stroke, rounded rect 180x60 |
| Connection lines | hub → each theme | 2px, `colors.accent_muted`, labeled with connection reason |

**Radial positioning:** Distribute N themes evenly around the circle:
- 3 themes: 120 degrees apart (top, bottom-left, bottom-right)
- 4 themes: 90 degrees (top, right, bottom, left)
- 5 themes: 72 degrees
- 6+ themes: equal distribution

**Connection labels:** Small text (12px) on each line describing the relationship. Max 6 words. Color: `colors.text_muted`.

**Total elements:** 10-20 depending on theme count.

---

### `concept-sketch` — Abstract Concept Patterns

Select the sub-pattern based on the conceptual structure detected in the text:

#### Layered Stack (for "layers of...", "foundation → application → value")

```
┌─────────────────────────┐
│      Value Layer         │  ← accent fill
├─────────────────────────┤
│   Application Layer      │  ← primary fill
├─────────────────────────┤
│   Foundation Layer       │  ← surface-dark fill
└─────────────────────────┘
```

- 3-5 horizontal rectangles stacked vertically (300x60px each, 4px gap)
- Bottom = foundation (darkest), top = value (accent color)
- Text centered in each layer, white on dark fills
- Optional arrow on left side labeled "Maturity" or "Abstraction"

#### Convergence (for "convergence of X and Y", "intersection of...")

```
    [Force A]       [Force B]
         \           /
          \         /
           [Result]
```

- 2-3 source rectangles at top (200x70px, spaced 100px apart)
- 1 result rectangle at bottom center (240x80px, accent fill)
- Diagonal arrows from each source to result
- Source boxes: `colors.surface` fill. Result box: `colors.accent` fill

#### Phase Progression (for "stages", "evolving from", "maturity model")

```
[Phase 1] → [Phase 2] → [Phase 3] → [Phase 4]
  Early        Growth      Mature     Transform
```

- Horizontal sequence of 3-5 rectangles (180x70px, 40px gap)
- Connected by right-pointing arrows
- Color gradient: leftmost = `colors.surface`, rightmost = `colors.accent`
- Phase labels below each box (12px, `colors.text_muted`)
- Optional progress bar below the sequence

#### 2x2 Matrix (for "quadrant", "high/low", "risk vs reward")

```
         High Impact
    ┌──────────┬──────────┐
    │  Quick   │ Strategic │
    │  Wins    │ Bets      │
    ├──────────┼──────────┤
    │  Low     │ Long      │
    │  Priority│ Shots     │
    └──────────┴──────────┘
         Low Impact
```

- 4 rectangles in a 2x2 grid (200x120px each, 4px gap)
- Axis labels on left and bottom (rotated text for Y-axis)
- Top-right quadrant highlighted with `colors.accent` fill
- Other quadrants: `colors.surface` fill
- Axis labels: `colors.text_muted`, 14px

**Total elements per concept sketch:** 10-20.

---

## SVG Export Settings

When calling `mcp__excalidraw__export_to_image`:

```json
{
  "format": "svg",
  "background": false,
  "padding": 20,
  "scale": 2
}
```

- `background: false` — transparent background, allowing themed HTML container to show through
- `padding: 20` — breathing room around elements
- `scale: 2` — high-DPI export for crisp rendering

The exported SVG is embedded inline in the HTML:
```html
<div class="enrichment concept-diagram" data-type="tips-flow" data-id="enr-003">
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="..." width="720">
    <!-- exported content -->
  </svg>
  <p class="enrichment-caption">T→I→P→S value chain: {trend_name}</p>
</div>
```

## CSS for Concept Containers

```css
.concept-diagram {
  max-width: 720px;
  margin: 32px auto;
  padding: 24px;
  background: var(--surface);
  border-radius: var(--radius);
  box-shadow: var(--shadow-sm);
  text-align: center;
}
.concept-diagram svg {
  max-width: 100%;
  height: auto;
}
.enrichment-caption {
  font-family: var(--font-body);
  font-size: 0.85rem;
  color: var(--text-muted);
  margin-top: 12px;
  font-style: italic;
}
```
