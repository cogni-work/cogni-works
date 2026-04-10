# SVG Concept Diagram Patterns

Element recipes for generating concept diagrams as inline SVG strings, themed with design-variables colors. Each pattern describes the viewBox, element structure, coordinate formulas, and color mapping.

> **Note:** This file is for LLM-crafted inline SVG generation (used by the `concept-diagram-svg` agent). For Excalidraw MCP rendering (big pictures, big blocks), see `excalidraw-patterns.md`.

## General Principles

### 1. SVG Structure

Every diagram follows this structure:

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {WIDTH} {HEIGHT}" width="{WIDTH}" height="{HEIGHT}">
  <defs>
    <!-- Gradients, shadows, arrow markers -->
  </defs>
  <!-- Zone backgrounds (large, low-opacity rects) -->
  <!-- Element boxes (rounded rects with gradient fills) -->
  <!-- Text labels (centered, with tspan wrapping) -->
  <!-- Arrows/connections (lines/paths with marker-end) -->
</svg>
```

### 2. Reusable `<defs>` Block

Include these standard definitions in every diagram:

```xml
<defs>
  <!-- Drop shadow filter -->
  <filter id="shadow" x="-5%" y="-5%" width="110%" height="120%">
    <feDropShadow dx="0" dy="2" stdDeviation="3" flood-opacity="0.12"/>
  </filter>

  <!-- Arrow marker -->
  <marker id="arrow" viewBox="0 0 10 8" refX="10" refY="4"
          markerWidth="8" markerHeight="6" orient="auto-start-reverse">
    <path d="M 0 0 L 10 4 L 0 8 z" fill="{ARROW_COLOR}"/>
  </marker>

  <!-- Gradient template (per-box, lighter top to darker bottom) -->
  <linearGradient id="grad-{id}" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0%" stop-color="{COLOR_LIGHT}"/>
    <stop offset="100%" stop-color="{COLOR}"/>
  </linearGradient>
</defs>
```

**Color lightening for gradients:** Take the base color and increase lightness by 8-12% for the top stop. For hex colors, this means blending with white at 15% opacity.

### 3. Theme Color Mapping

Map `DESIGN_VARIABLES.colors` to SVG properties:

| Design Variable | SVG Usage |
|----------------|-----------|
| `colors.accent` | Primary box fills, arrow colors, emphasis elements |
| `colors.primary` | Secondary box fills, borders |
| `colors.surface` | Background zones, neutral box fills |
| `colors.text` | Primary text color (dark on light backgrounds) |
| `colors.text_light` | Text on dark/colored backgrounds (typically white `#FFFFFF`) |
| `colors.text_muted` | Labels, captions, axis headers |
| `colors.border` | Subtle borders, grid lines |
| `colors.secondary` | Tertiary elements, alternative emphasis |

**TIPS dimension colors** (hardcoded brand identity — override theme colors for TIPS diagrams):
- Trend: `#F59E0B` (amber)
- Implication: `#06B6D4` (cyan)
- Possibility: `#8B5CF6` (purple)
- Solution: `#22C55E` (green)

### 4. Typography

- **Font family:** `DESIGN_VARIABLES.fonts.body`, with fallback: `'{font_name}', sans-serif`
- **Headers font:** `DESIGN_VARIABLES.fonts.headers`, with fallback: `'{font_name}', sans-serif`
- **Text sizes:** 20px headings, 16px body, 14px sub-labels, 12px axis headers/captions
- **Text alignment:** Always `text-anchor="middle"` and `dominant-baseline="central"` for centered text
- **Text on colored backgrounds:** Use `colors.text_light` (white) on dark fills; use `colors.text` on light fills
- **Line wrapping:** Max 20 characters per line. Use `<tspan>` elements with `dy="1.2em"` for multi-line text. Wrap on word boundaries.

### 5. Box Styling

Standard box element:
```xml
<rect x="{X}" y="{Y}" width="{W}" height="{H}" rx="8"
      fill="url(#grad-{id})" filter="url(#shadow)"/>
```

- Rounded corners: `rx="8"` on all boxes
- Drop shadow: `filter="url(#shadow)"` on primary boxes (not on zone backgrounds)
- Gradient fill: use per-box gradient from `<defs>`
- Border (optional): `stroke="{colors.border}" stroke-width="1"` for subtle outline

### 6. Arrow Styling

```xml
<line x1="{X1}" y1="{Y1}" x2="{X2}" y2="{Y2}"
      stroke="{ARROW_COLOR}" stroke-width="2"
      marker-end="url(#arrow)"/>
```

For curved arrows:
```xml
<path d="M {X1} {Y1} Q {CX} {CY} {X2} {Y2}"
      fill="none" stroke="{ARROW_COLOR}" stroke-width="2"
      marker-end="url(#arrow)"/>
```

### 7. Zone Backgrounds

Large rectangles behind groups of elements to create visual grouping:
```xml
<rect x="{X}" y="{Y}" width="{W}" height="{H}" rx="12"
      fill="{ZONE_COLOR}" opacity="0.08"/>
```

- `opacity="0.08"` to `0.12` — subtle wash, not overpowering
- `rx="12"` — slightly more rounded than element boxes
- No shadow, no border — zones are purely spatial grouping

---

## Diagram Patterns

---

### `tips-flow` — T->I->P->S Value Chain

**Layout:** 4-column horizontal flow with zone backgrounds per TIPS dimension.

```
 TREND        IMPLICATIONS      POSSIBILITIES     SOLUTIONS
┌─────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  zone   │  │    zone      │  │    zone      │  │    zone      │
│ [Trend] │→ │ [Impl 1]     │→ │ [Poss 1]     │→ │ [Sol 1]      │
│         │  │ [Impl 2]     │  │              │  │ [Sol 2]      │
└─────────┘  └──────────────┘  └──────────────┘  └──────────────┘
                                                  ┌──────────────────────┐
                                                  │  [Foundation]        │
                                                  └──────────────────────┘
```

**viewBox calculation:**
- Width: `80 + (N_columns * column_width) + ((N_columns - 1) * column_gap)` where `column_width = 200`, `column_gap = 60`
- Height: `80 + (max_items_in_any_column * 90) + (foundation ? 80 : 0)`
- Minimum: `viewBox="0 0 1060 350"`

**Coordinate formulas:**
- Column X positions: Trend=40, Implications=300, Possibilities=560, Solutions=820
- Column header Y: 30 (12px text, uppercase, `colors.text_muted`)
- First box Y: 60
- Box spacing: 90px vertical (70px box height + 20px gap)
- Vertical centering: offset shorter columns to center relative to tallest

**Element recipe:**

| Element | Size | Fill | Text Color |
|---------|------|------|------------|
| Trend box | 220x80 | `#F59E0B` gradient | white |
| Implication boxes | 200x70 | `#06B6D4` gradient | white |
| Possibility boxes | 200x70 | `#8B5CF6` gradient | white |
| Solution boxes | 200x70 | `#22C55E` gradient | white |
| Foundation bar | full-width x 40 | `colors.surface` | `colors.text` |

**Zone backgrounds:** One subtle rect behind each column group, color-matched to dimension at 8% opacity.

**Arrows:** Horizontal lines from right edge of each box to left edge of next column's aligned box. Use `marker-end="url(#arrow)"`. Arrow color: `#555555`.

**Column headers:** 12px uppercase text above each column. EN: "TREND", "IMPLICATIONS", "POSSIBILITIES", "SOLUTIONS". DE: "TREND", "IMPLIKATIONEN", "MOGLICHKEITEN", "LOSUNGEN".

**Foundation row:** If present, full-width rect at bottom with 30px gap above. Dashed top border (`stroke-dasharray="6 3"`).

**Total elements:** 15-25 depending on chain complexity.

---

### `relationship-map` — Theme Interconnections

**Layout:** Central hub circle with radiating theme nodes and labeled connections.

```
            [Theme 2]
               |
[Theme 1] --- [Hub] --- [Theme 3]
               |
            [Theme 4]
```

**viewBox:** `0 0 720 {HEIGHT}` where HEIGHT = max(500, needed for node count).

**Coordinate formulas:**
- Hub center: `(360, HEIGHT/2)`
- Hub radius: 50px (circle element)
- Node distance from hub: 200px
- Node angle distribution (N nodes):
  - 3: 90deg, 210deg, 330deg (top, bottom-left, bottom-right)
  - 4: 0deg, 90deg, 180deg, 270deg (right, top, left, bottom — but rotated 45deg so top-right, top-left, bottom-left, bottom-right)
  - 5+: 360/N degrees apart, starting from top (90deg)
- Node position: `x = hub_cx + distance * cos(angle)`, `y = hub_cy - distance * sin(angle)`

**Element recipe:**

| Element | Style |
|---------|-------|
| Hub circle | 50px radius, `colors.accent` fill, white text, `filter="url(#shadow)"` |
| Hub label | 16px, `colors.text_light`, centered |
| Theme nodes | 180x60 rounded rect, `colors.surface` fill, `colors.primary` 1.5px stroke |
| Node labels | 14px, `colors.text`, centered |
| Connection lines | 1.5px, `colors.accent` at 40% opacity, no arrow (bidirectional) |
| Connection labels | 11px, `colors.text_muted`, positioned at line midpoint, italic |

**Connection label positioning:** Place at the midpoint of the line, offset 12px perpendicular to avoid overlapping the line. Use `transform="rotate()"` to align with line angle for readability.

**Total elements:** 10-20 depending on theme count.

---

### `process-flow` — Sequential Workflow

**Layout:** Horizontal flow (3-5 steps) or vertical flow (6-8 steps).

```
Horizontal:
  [1. Step 1] → [2. Step 2] → [3. Step 3] → [4. Step 4]
    sublabel      sublabel      sublabel      sublabel

Vertical:
  [1. Step 1]
       ↓
  [2. Step 2]
       ↓
  [3. Step 3]
```

**viewBox calculation:**
- Horizontal: width = `60 + (N_steps * 180) + ((N_steps - 1) * 60)`, height = `180`
- Vertical: width = `280`, height = `60 + (N_steps * 80) + ((N_steps - 1) * 50)`
- Auto-select: horizontal if N <= 5, vertical if N > 5

**Coordinate formulas (horizontal):**
- Box X: `30 + i * (180 + 60)` for step i
- Box Y: `40` (all boxes on same baseline)
- Arrow: from `(box_x + 180, box_y + 35)` to `(next_box_x, next_box_y + 35)`
- Sub-label Y: `box_y + 70 + 16`

**Coordinate formulas (vertical):**
- Box X: `50` (all boxes left-aligned)
- Box Y: `30 + i * (80 + 50)` for step i
- Arrow: from `(box_x + 90, box_y + 80)` to `(box_x + 90, next_box_y)`

**Element recipe:**

| Element | Style |
|---------|-------|
| Step boxes | 180x70, `colors.surface` fill, `colors.primary` 1.5px stroke, rx=8 |
| Active step (first or last) | `colors.accent` gradient fill, white text, shadow |
| Step number badge | 12px bold, circle (20px radius), `colors.accent` fill, white text, top-left of box |
| Step label | 14px, `colors.text`, centered in box |
| Sub-label | 12px, `colors.text_muted`, centered below box |
| Arrows | 2px, `colors.accent` at 60%, `marker-end="url(#arrow)"` |

**Number badge positioning:** Small circle at `(box_x + 16, box_y + 16)` with step number text inside.

**Total elements:** 10-25 depending on step count.

---

### `concept-sketch` — Abstract Concept Patterns

Select the sub-pattern based on `CONCEPT_SUBTYPE`:

---

#### `layered-stack` — Capability / Maturity Layers

```
┌────────────────────────────┐
│     Value Layer            │  ← accent gradient
├────────────────────────────┤
│   Application Layer        │  ← primary gradient
├────────────────────────────┤
│   Foundation Layer         │  ← surface-dark gradient
└────────────────────────────┘
  ↑ Maturity / Abstraction
```

**viewBox:** `0 0 500 {40 + N_layers * 70}`

**Coordinate formulas:**
- Box width: 400px, centered at x=50
- Box height: 60px
- Box Y: `20 + (N_layers - 1 - i) * 68` (stack bottom-up: first layer = bottom)
- Gap between layers: 8px

**Color gradient:** Bottom layer = darkest (surface with overlay), top layer = lightest/accent. Interpolate linearly for middle layers. Suggested: bottom `colors.border`, middle `colors.primary`, top `colors.accent`.

**Optional side arrow:** Vertical arrow on the left labeled "Maturity" or "Abstraction" — from bottom to top.

**Total elements:** 8-15.

---

#### `convergence` — Forces Merging into Outcome

```
    [Force A]       [Force B]       [Force C]
         \           |           /
          \          |          /
           \         |         /
            ┌────────────────┐
            │    Result      │
            └────────────────┘
```

**viewBox:** `0 0 {60 + N_forces * 200} {300}`

**Coordinate formulas:**
- Force boxes: distributed evenly across top row, Y=30
- Force box width: 180px, height: 60px
- Force box X: `30 + i * (total_width - 60) / N_forces + (total_width - 60) / N_forces / 2 - 90`
- Result box: centered at bottom, Y=210, 240x80px
- Diagonal arrows: from center-bottom of each force box to center-top of result box

**Colors:**
- Force boxes: `colors.surface` fill, `colors.primary` stroke
- Result box: `colors.accent` gradient fill, white text, shadow
- Arrows: `colors.accent` at 50%, 2px stroke

**Total elements:** 8-15.

---

#### `phase-progression` — Stages / Maturity Model

```
  [Phase 1] → [Phase 2] → [Phase 3] → [Phase 4]
    Early       Growth      Mature     Transform
```

**viewBox:** Same as process-flow horizontal.

**Coordinate formulas:** Same as process-flow horizontal layout.

**Key difference from process-flow:** Color gradient across phases. Leftmost = `colors.surface`, rightmost = `colors.accent`. Intermediate phases interpolate between these colors.

**Color interpolation:** For N phases, phase i gets a color that's `i / (N-1)` of the way from `colors.surface` to `colors.accent`. Apply as gradient fill.

**Optional progress bar:** Horizontal bar below all phases, filled proportionally to indicate current/target phase. Height: 8px, rounded ends, `colors.accent` fill on progress portion.

**Total elements:** 10-20.

---

#### `2x2-matrix` — Quadrant Positioning

```
           High {y_axis}
    ┌──────────┬──────────┐
    │  Top     │ Top      │
    │  Left    │ Right    │  ← highlight quadrant
    ├──────────┼──────────┤
    │  Bottom  │ Bottom   │
    │  Left    │ Right    │
    └──────────┴──────────┘
Low {x_axis}  →  High {x_axis}
```

**viewBox:** `0 0 560 480`

**Coordinate formulas:**
- Grid origin: (80, 60)
- Quadrant size: 200x160px
- Gap between quadrants: 4px
- Total grid: 404x324px
- Y-axis label: rotated -90deg, x=30, centered vertically
- X-axis label: centered horizontally, y=grid_bottom + 40
- Quadrant positions:
  - top-left: (80, 60)
  - top-right: (284, 60)
  - bottom-left: (80, 224)
  - bottom-right: (284, 224)

**Colors:**
- Default quadrant: `colors.surface` fill
- Highlighted quadrant (typically top-right = high/high): `colors.accent` gradient fill, white text
- Quadrant labels: 16px, centered in quadrant
- Axis labels: 14px, `colors.text_muted`, italic
- Axis direction labels: "Low" and "High" at axis endpoints, 11px

**Grid lines:** 1px, `colors.border`, between quadrants (horizontal and vertical center lines).

**Total elements:** 12-18.

---

## CSS for Concept Containers (in HTML report)

The HTML generator wraps inline SVGs in themed containers:

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

The SVG itself uses resolved hex colors (not CSS variables) so it renders correctly both standalone and inline in the HTML container.
