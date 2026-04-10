# Infographic Pencil Layouts

Pencil MCP frame recipes and grid position tables for rendering infographic briefs into
pixel-precise `.pen` files. The `render-infographic-pencil` agent reads this library at
Step 3 to translate block types into Pencil `batch_design` operations.

This library complements `infographic-layouts.md` (which defines the content schema). Here
we define **how to render** each block type as Pencil frames, and **where to place** each
block on the canvas per layout type.

---

## Canvas Specification

Portrait is the default orientation for editorial infographics — it matches print media
(DIN A4 ratio 1:1.414) and The Economist's magazine format.

| Orientation | Width | Height | Ratio | Margin | Usable Area |
|-------------|-------|--------|-------|--------|-------------|
| portrait (default) | 1080 | 1528 | DIN A4 (1:1.414) | 48 | 984 x 1432 |
| landscape | 1528 | 1080 | DIN A4 rotated | 48 | 1432 x 984 |

**Reserved areas (portrait):**
- Title banner: top 120px of usable area (y: 48 to 168)
- Footer: bottom 56px of usable area (y: 1424 to 1480)
- CTA: 72px above footer when present (y: 1352 to 1424)
- Content area: y=180 to y=1340 (1160px height, or 1244px without CTA)

**Content origin (portrait):** x=48, y=180. Content size: 984 x 1160 (with CTA) or 984 x 1244 (without CTA).
**Content origin (landscape):** x=48, y=180. Content size: 1432 x 686 (with CTA) or 1432 x 770 (without CTA).

**Zone spacing:** 10px gap between zones. 12px internal padding per zone. The Economist
style packs content densely — minimize dead whitespace. Content should fill the page like
a newspaper editorial, not a sparse dashboard.

---

## Economist Design Token Overrides

When `style_preset == economist`, apply these overrides AFTER the theme's standard 14 tokens.
Call `set_variables` a second time with only these keys — they layer on top of the theme.

```
--primary:            #C00000    (The Economist red)
--accent:             #C00000    (red is the accent)
--accent-amber:       #D4A017    (secondary callout — icons, tertiary highlights)
--background:         #FBF9F3    (cream)
--background-alt:     #F0EDE4    (slightly darker cream for alternate zones)
--foreground:         #1A1A1A    (near-black)
--foreground-muted:   #666666    (mid-grey for sublabels and sources)
--surface-dark:       #1A1A1A    (same as foreground — dark bands)
--surface-dark-text:  #FFFFFF    (white on dark)
--surface-dark-muted: #AAAAAA    (muted on dark)
--chart-fill:         #C00000    (primary bar fill)
--chart-fill-2:       #E8A0A0    (secondary bar fill — lighter red)
--chart-fill-3:       #D4A017    (tertiary — amber for multi-series)
--rule-color:         #C00000    (section divider rule lines)
```

For other style presets (`editorial`, `data-viz`, `corporate`), use the theme tokens directly
without overrides. The `--chart-fill` and `--rule-color` custom tokens should be set to
`$--primary` and `$--foreground-muted` respectively as defaults.

---

## Typography Scale

Infographic-specific type sizes. All sizes in px, unitless in Pencil `fontSize` property.
Font family references theme tokens: `$--font-primary` for headlines, `$--font-body` for body.

| Role | Size | Weight | Font | Color |
|------|------|--------|------|-------|
| Hero number (kpi-card) | 72 | Bold | `$--font-primary` | `$--primary` |
| Hero unit (%, x, etc.) | 56 | Bold | `$--font-primary` | `$--primary` |
| Title headline | 40 | Bold | `$--font-primary` | `$--foreground` |
| Title subline | 18 | Regular | `$--font-body` | `$--foreground-muted` |
| Section headline | 28 | Bold | `$--font-primary` | `$--foreground` |
| Stat number (stat-row) | 36 | Bold | `$--font-primary` | `$--primary` |
| Stat label | 13 | Regular | `$--font-body` | `$--foreground-muted` |
| Body text | 14 | Regular | `$--font-body` | `$--foreground` |
| Sublabel / source | 11 | Regular | `$--font-body` | `$--foreground-muted` |
| Process step label | 13 | Bold | `$--font-body` | `$--foreground` |
| CTA headline | 28 | Bold | `$--font-primary` | `$--surface-dark-text` |
| CTA button text | 16 | Bold | `$--font-primary` | `$--surface-dark-text` |
| Footer text | 11 | Regular | `$--font-body` | `$--foreground-muted` |
| Chart label | 11 | Regular | `$--font-body` | `$--foreground-muted` |
| Chart value label | 14 | Bold | `$--font-primary` | `$--foreground` |

For **economist preset**: when the theme's `--font-primary` is a sans-serif, numbers still
render well. The monospace feel comes from tabular figure alignment, not font family.

---

## Block Type Frame Recipes

Each recipe defines the Pencil frame nesting structure using tree notation. Properties in
parentheses map to Pencil `batch_design` insert operations.

### title

```
title-zone (frame, width: ZONE_W, layout: vertical, gap: 4, padding: [12, 0, 8, 0])
  headline (text, fontSize: 32, fontWeight: Bold, fontFamily: $--font-primary, fill: $--foreground, content: "{Headline}")
  rule-line (frame, width: fill_container, height: 2, fill: $--rule-color)
  subline (text, fontSize: 14, fontFamily: $--font-body, fill: $--foreground-muted, content: "{Subline}")
```

**Economist note:** Left-aligned, compact. No metadata in the title zone — metadata goes
to the footer. Headline 32px (not 40) to save vertical space. The red rule line is the
visual signature.

### kpi-card

Two layout variants: **icon-left** (wide zones, 2-col) and **icon-top** (narrow zones, 1-col).

**Icon-left variant** (for 2-col+ zones, w >= 480):
```
kpi-zone (frame, width: ZONE_W, height: ZONE_H, layout: horizontal, gap: 12, padding: [0, 12, 8, 12])
  icon-frame (frame, width: 48, height: 48, fill: $--primary at 10%, cornerRadius: 24, alignment: center)
    icon (icon_font, fontSize: 28, fill: $--primary, content: "{lucide-icon}")
  content (frame, layout: vertical, gap: 2, fill_container)
    top-rule (frame, width: fill_container, height: 2, fill: $--rule-color)
    number-row (frame, layout: horizontal, gap: 0, alignment: baseline)
      hero-number (text, fontSize: 64, fontWeight: Bold, fontFamily: $--font-primary, fill: $--primary, content: "{digits}")
      hero-unit (text, fontSize: 44, fontWeight: Bold, fontFamily: $--font-primary, fill: $--primary, content: "{unit}")
    hero-label (text, fontSize: 12, fontWeight: Bold, fontFamily: $--font-body, fill: $--foreground, content: "{Hero-Label}")
    sublabel (text, fontSize: 10, fontFamily: $--font-body, fill: $--foreground-muted, content: "{Sublabel}")
    source (text, fontSize: 9, fontFamily: $--font-body, fill: $--foreground-muted, content: "{Source}")
```

**Icon-top variant** (for 1-col zones, w < 480):
```
kpi-zone (frame, width: ZONE_W, height: ZONE_H, layout: vertical, gap: 2, padding: [8, 12, 8, 12])
  icon-row (frame, layout: horizontal, gap: 8, alignment: center)
    icon (icon_font, fontSize: 24, fill: $--accent-amber, content: "{lucide-icon}")
    top-rule (frame, width: fill_container, height: 2, fill: $--rule-color)
  number-row (frame, layout: horizontal, gap: 0, alignment: baseline)
    hero-number (text, fontSize: 48, fontWeight: Bold, fontFamily: $--font-primary, fill: $--primary, content: "{digits}")
    hero-unit (text, fontSize: 32, fontWeight: Bold, fontFamily: $--font-primary, fill: $--primary, content: "{unit}")
  hero-label (text, fontSize: 11, fontWeight: Bold, fontFamily: $--font-body, fill: $--foreground, content: "{Hero-Label}")
  sublabel (text, fontSize: 10, fontFamily: $--font-body, fill: $--foreground-muted, content: "{Sublabel}")
  source (text, fontSize: 9, fontFamily: $--font-body, fill: $--foreground-muted, content: "{Source}")
```

**Icon is mandatory.** Every kpi-card MUST render its icon. The icon is a key visual element
in the Economist style — large, colored, and visible. Map the brief's `Icon-Prompt` to
a Lucide icon name using the mapping table below.

**Icon styling:** In the icon-left variant, the icon sits in a circular tinted frame
(primary color at 10% opacity, 48x48, cornerRadius 24 = circle). In icon-top variant,
the icon is bare (no frame), placed in amber next to the rule line.

**Number splitting:** Parse `Hero-Number` to separate digits from unit. "73%" → digits="73", unit="%".

**Ops count:** ~9 operations per kpi-card (icon-left), ~8 (icon-top).

### stat-row

```
stat-zone (frame, width: ZONE_W, height: ZONE_H, layout: horizontal, gap: 0, padding: [12, 0])
  stat-item (frame, layout: vertical, width: ITEM_W, gap: 4, padding: [8, 12], alignment: center) [repeat N]
    icon-circle (frame, width: 36, height: 36, fill: $--accent-amber at 15%, cornerRadius: 18, alignment: center)
      icon (icon_font, fontSize: 20, fill: $--accent-amber, content: "{lucide-icon-name}")
    number (text, fontSize: 28, fontWeight: Bold, fontFamily: $--font-primary, fill: $--primary, content: "{number}")
    label (text, fontSize: 10, fontFamily: $--font-body, fill: $--foreground-muted, content: "{label}")
  divider (frame, width: 1, height: fill_container, fill: $--foreground-muted at 30%) [between items]
```

**Icon circles are mandatory** in stat-rows — every stat gets an amber circular icon above
its number. This is the Economist visual signature: icon circles in warm amber/orange
contrasting with the red stat numbers below.

**Item width formula:** `ITEM_W = ZONE_W / N` where N = number of stats.
**Divider placement:** Insert a 1px vertical divider frame between each stat item.

**Ops count:** ~6 ops per stat + 1 per divider. 3 stats = ~21 ops.

### chart

Bar charts are the primary chart type for the economist preset. Bars are constructed as
proportionally-sized colored rectangle frames.

```
chart-zone (frame, width: ZONE_W, height: ZONE_H, layout: vertical, gap: 8, padding: [16, 16])
  chart-title (text, fontSize: 14, fontWeight: Bold, fontFamily: $--font-body, fill: $--foreground, content: "{Chart-Title}")
  chart-area (frame, width: fill_container, height: BAR_MAX_H + 24, layout: none)
    bar-group (frame, x: BAR_X, y: BAR_Y, width: BAR_W, height: BAR_H, fill: $--chart-fill, cornerRadius: 0) [repeat per data point]
    value-label (text, x: BAR_X, y: BAR_Y - 18, fontSize: 14, fontWeight: Bold, fill: $--foreground, content: "{value}") [above each bar]
  label-row (frame, width: fill_container, layout: horizontal, gap: 0)
    axis-label (text, width: BAR_W + BAR_GAP, fontSize: 11, fill: $--foreground-muted, content: "{label}", alignment: center) [repeat per data point]
```

**Bar computation:**
```
BAR_MAX_H = ZONE_H - 80 (title + labels + padding)
max_value = max(Data.datasets[0].values)
BAR_H = round(value / max_value * BAR_MAX_H)
BAR_W = min(60, (ZONE_W - 32 - (N-1)*BAR_GAP) / N)
BAR_GAP = 12
BAR_X = 16 + i * (BAR_W + BAR_GAP)
BAR_Y = BAR_MAX_H - BAR_H    (bars anchor from top, grow downward)
```

**Multi-dataset:** If 2 datasets, render grouped bars side-by-side. Bar 1 uses `$--chart-fill`, bar 2 uses `$--chart-fill-2`. Each bar is half the normal BAR_W, with 4px gap between grouped bars.

**Doughnut/line/radar:** For non-bar chart types, render as a stat-row of the values instead (Pencil cannot draw circles or paths). Note this in the chart zone as a text annotation: "See data below" and use the values as a stat-row.

**Ops count:** ~3 + 2*N ops. 5 bars = ~13 ops.

### process-strip

```
process-zone (frame, width: ZONE_W, height: ZONE_H, layout: horizontal, gap: 0, padding: [16, 16], alignment: center)
  step (frame, layout: vertical, width: STEP_W, gap: 6, alignment: center) [repeat per step]
    icon (icon_font, fontSize: 24, fill: $--accent-amber, content: "{lucide-icon-name}")
    label (text, fontSize: 13, fontWeight: Bold, fontFamily: $--font-body, fill: $--foreground, content: "{label}", alignment: center)
  connector (frame, layout: horizontal, width: 32, alignment: center) [between steps]
    arrow (icon_font, fontSize: 16, fill: $--foreground-muted, content: "chevron-right")
```

**Step width:** `STEP_W = (ZONE_W - 32 - (N-1)*32) / N`
**Vertical process (portrait):** Swap horizontal → vertical layout, use "chevron-down" for connectors.

**Ops count:** ~3 per step + 1 per connector. 5 steps = ~19 ops.

### text-block

**Standard variant** (with optional icon):
```
text-zone (frame, width: ZONE_W, height: ZONE_H, layout: horizontal, gap: 10, padding: [12, 12])
  icon-col (frame, width: 32, layout: vertical, gap: 4, padding: [4, 0]) [if Icon-Prompt provided]
    icon (icon_font, fontSize: 24, fill: $--accent-amber, content: "{lucide-icon}")
  text-col (frame, layout: vertical, gap: 4, fill_container)
    headline (text, fontSize: 13, fontWeight: Bold, fontFamily: $--font-primary, fill: $--foreground, content: "{Headline}")
    body (text, fontSize: 11, fontFamily: $--font-body, fill: $--foreground, content: "{Body}")
```

**When no icon:** Skip icon-col, text-col fills the full zone width.

**Pull-quote variant** (full-width zone at bottom of page):
```
pull-quote-zone (frame, width: ZONE_W, height: ZONE_H, layout: horizontal, gap: 12, padding: [12, 16])
  left-border (frame, width: 3, height: fill_container, fill: $--rule-color)
  quote-text (text, fontSize: 15, fontStyle: italic, fontFamily: $--font-body, fill: $--foreground, content: "{Headline}")
```

The pull-quote uses the `Headline` field as the quote text (body is empty). Red left
border (3px) is the visual marker.

**Ops count:** ~5 ops (with icon), ~3 ops (no icon), ~3 ops (pull-quote).

### comparison-pair

```
comparison-zone (frame, width: ZONE_W, height: ZONE_H, layout: horizontal, gap: 0, padding: [16, 16])
  left-col (frame, layout: vertical, width: COL_W, gap: 8, padding: [16, 16])
    col-label (text, fontSize: 13, fontWeight: Bold, fontFamily: $--font-body, fill: $--foreground-muted, content: "{Left.label}")
    rule (frame, width: fill_container, height: 1, fill: $--foreground-muted at 30%)
    bullet-list (frame, layout: vertical, gap: 4)
      bullet (text, fontSize: 13, fontFamily: $--font-body, fill: $--foreground, content: "- {bullet_text}") [repeat]
  divider (frame, width: 2, height: fill_container, fill: $--rule-color)
  right-col (frame, layout: vertical, width: COL_W, gap: 8, padding: [16, 16])
    col-label (text, fontSize: 13, fontWeight: Bold, fontFamily: $--font-body, fill: $--primary, content: "{Right.label}")
    rule (frame, width: fill_container, height: 1, fill: $--primary at 30%)
    bullet-list (frame, layout: vertical, gap: 4)
      bullet (text, fontSize: 13, fontFamily: $--font-body, fill: $--foreground, content: "- {bullet_text}") [repeat]
```

**Column width:** `COL_W = (ZONE_W - 34) / 2` (2px divider + padding).
**Color distinction:** Left column uses muted tones (grey label, grey rule). Right column uses primary tones (red label, red rule). This mirrors The Economist's before/after visual language.

**Ops count:** ~8 + 2*bullets ops. 4 bullets each = ~16 ops.

### icon-grid

```
grid-zone (frame, width: ZONE_W, height: ZONE_H, layout: horizontal, gap: 16, padding: [16, 16], wrap: true)
  grid-item (frame, layout: vertical, width: ITEM_W, gap: 6, padding: [12, 12]) [repeat per item]
    icon (icon_font, fontSize: 24, fill: $--accent-amber, content: "{lucide-icon-name}")
    label (text, fontSize: 14, fontWeight: Bold, fontFamily: $--font-body, fill: $--foreground, content: "{label}")
    sublabel (text, fontSize: 11, fontFamily: $--font-body, fill: $--foreground-muted, content: "{sublabel}")
```

**Item width for 2-column grid:** `ITEM_W = (ZONE_W - 48) / 2`
**Item width for 3-column grid:** `ITEM_W = (ZONE_W - 64) / 3`
Column count from brief's `Columns` field (default 2).

**Ops count:** ~4 per item. 6 items = ~25 ops (split across 2 batches if needed).

### svg-diagram

For the economist preset, svg-diagram blocks are rendered as a structured icon-grid layout
rather than attempting radial or flow diagrams. The Economist avoids complex diagrams —
information is presented in clean, scannable blocks.

**Hub-spoke mapping:** Render hub as a highlighted header text with red rule, then spokes as
an icon-grid below. The hub label becomes the section headline.

```
diagram-zone (frame, width: ZONE_W, height: ZONE_H, layout: vertical, gap: 12, padding: [16, 16])
  hub-label (text, fontSize: 24, fontWeight: Bold, fontFamily: $--font-primary, fill: $--foreground, content: "{hub}")
  hub-rule (frame, width: 120, height: 2, fill: $--rule-color)
  spoke-grid (frame, layout: horizontal, gap: 16, wrap: true)
    spoke-item (frame, layout: vertical, width: ITEM_W, gap: 4, padding: [8, 12]) [repeat per spoke]
      icon (icon_font, fontSize: 20, fill: $--accent-amber, content: "{lucide-icon-name}")
      label (text, fontSize: 13, fontWeight: Bold, fontFamily: $--font-body, fill: $--foreground, content: "{label}")
```

**Process-flow mapping:** Render as a horizontal process-strip recipe (see above).

**Ops count:** ~4 + 3*spokes. 5 spokes = ~19 ops.

### cta

```
cta-zone (frame, width: ZONE_W, height: 56, layout: horizontal, gap: 16, padding: [12, 24], fill: $--primary, alignment: center)
  headline (text, fontSize: 16, fontWeight: Bold, fontFamily: $--font-primary, fill: $--surface-dark-text, content: "{Headline}")
  spacer (frame, width: fill_container)
  button (frame, layout: horizontal, padding: [8, 20], fill: $--surface-dark-text, cornerRadius: 0)
    button-text (text, fontSize: 13, fontWeight: Bold, fontFamily: $--font-primary, fill: $--primary, content: "{CTA-Text}")
```

**Economist CTA:** Compact (56px), sharp edges, inverted button (white bg, red text). Red background band spans full width.

**Ops count:** ~6 ops.

### footer

```
footer-zone (frame, width: ZONE_W, height: 48, layout: vertical, gap: 2, padding: [6, 12, 6, 12])
  top-rule (frame, width: fill_container, height: 1, fill: $--rule-color)
  footer-row (frame, layout: horizontal, gap: 0)
    left (text, fontSize: 9, fontFamily: $--font-body, fill: $--foreground-muted, content: "{Left}")
    spacer (frame, width: fill_container)
    center (text, fontSize: 9, fontFamily: $--font-body, fill: $--foreground-muted, content: "{Center}")
    spacer (frame, width: fill_container)
    right (text, fontSize: 9, fontFamily: $--font-body, fill: $--foreground-muted, content: "{Right}")
  source-line (text, fontSize: 9, fontFamily: $--font-body, fill: $--foreground-muted, content: "{Source-Line}")
```

**Ops count:** ~9 ops.

---

## Grid Position Tables

Zone coordinates for each layout type. **Portrait (1080x1920) is the default** — it matches
magazine print format and gives more vertical space for data blocks. All positions are
absolute (`layout: none` on root frame).

The root page frame uses `layout: none` so all zone positions are absolute. This gives the
precise grid control that editorial infographics demand — zones align to an invisible grid
without flex-flow drift.

Abbreviations: W = usable width (984 for portrait, 1824 for landscape). All zones start at x=48.

---

### stat-heavy (Portrait — default)

Dense multi-column editorial grid inspired by The Economist data pages. Content fills the
page like a newspaper — mixed-size zones packed tightly in a 2-3 column grid. The governing
principle: every zone sits beside another zone, not below. Vertical stacking is for rows
of zones, not individual blocks.

**Grid system:** 3-column base grid. Column width = `(984 - 2*10) / 3 = 321px`. Zones
span 1, 2, or 3 columns. Row heights vary by content.

```
+--[title: 984 x 80]--------------------------+  y=48
+--[intro-text: 640]---+--[hero-kpi: 324]------+  y=138
+--[kpi-row: 3x across, 321px each]-----------+  y=310
+--[chart: 640]--------+--[text-col: 324]------+  y=460
+--[stat-row: 984 full width]---------+--------+  y=680
+--[text-1: 487]--+--[text-2: 487]-------------+  y=830
+--[kpi-bottom: 640]--+--[icon-col: 324]-------+  y=990
+--[pull-quote: 984 full width]----------------+  y=1140
+--[cta: 984 x 56]----------------------------+  y=1352
+--[footer: 984 x 48]-------------------------+  y=1418
```

| Zone | x | y | w | h | Block Type | Notes |
|------|---|---|---|---|------------|-------|
| title | 48 | 48 | 984 | 80 | title | Compact: headline + rule only, no subline padding |
| intro-text | 48 | 138 | 640 | 162 | text-block | 2-col span. Intro paragraph setting the scene |
| hero-kpi | 698 | 138 | 334 | 162 | kpi-card | Right column. Biggest number, red, dominant |
| kpi-a | 48 | 310 | 321 | 140 | kpi-card | 1-col. Supporting stat |
| kpi-b | 379 | 310 | 321 | 140 | kpi-card | 1-col. Supporting stat |
| kpi-c | 710 | 310 | 322 | 140 | kpi-card | 1-col. Supporting stat |
| chart | 48 | 460 | 640 | 210 | chart | 2-col span. Bar chart beside text |
| chart-text | 698 | 460 | 334 | 210 | text-block | Right column. Explains chart context |
| stat-row | 48 | 680 | 984 | 140 | stat-row | Full width. 3-4 stats with dividers |
| text-left | 48 | 830 | 487 | 150 | text-block | Left half. Additional context |
| text-right | 545 | 830 | 487 | 150 | text-block / kpi-card | Right half. Stat or text |
| bottom-kpi | 48 | 990 | 640 | 140 | kpi-card | 2-col span. Closing anchor number |
| bottom-right | 698 | 990 | 334 | 140 | icon-grid / text-block | Right column. Icons or text |
| pull-quote | 48 | 1140 | 984 | 80 | text-block | Full width. Bold pull-quote or key takeaway |
| cta | 48 | 1352 | 984 | 56 | cta | Red band |
| footer | 48 | 1418 | 984 | 48 | footer | Sources |

**Zone assignment strategy:** The agent maps brief blocks to grid zones top-to-bottom,
left-to-right. The first kpi-card goes to `hero-kpi` (biggest number, most prominent).
The chart goes to `chart`. Remaining kpi-cards fill the `kpi-a/b/c` row. Stat-row fills
`stat-row`. Text-blocks fill `intro-text`, `chart-text`, `text-left`, `text-right`, or
`pull-quote` in order. If the brief has fewer blocks than zones, collapse unused zones
(reduce their height to 0 and shift subsequent zones up).

**Density rules:**
- Gap between zones: 10px vertical, 10px horizontal
- Internal padding: 12px per zone
- No zone taller than 210px except the chart
- No dead whitespace bands — if a zone is unused, collapse it
- Pull-quote zone: italic text, larger font (18px), left-aligned, red left border (3px)

**Fewer than 6 content blocks:** If brief has only 3-5 blocks, use a simplified 2-row grid:
- Row 1: kpi cards across (1-3 columns)
- Row 2: chart (2-col) + text (1-col) — or stat-row full width
- Skip the text-left/text-right and bottom rows. Place CTA closer to content.

### comparison (Portrait)

| Zone | x | y | w | h | Block Type |
|------|---|---|---|---|------------|
| title | 48 | 48 | 984 | 120 | title |
| kpi-hero | 48 | 180 | 984 | 170 | kpi-card (optional, full width) |
| comparison | 48 | 370 | 984 | 400 | comparison-pair |
| evidence | 48 | 790 | 984 | 140 | stat-row |
| extra | 48 | 950 | 984 | 180 | chart / text-block |
| cta | 48 | 1352 | 984 | 72 | cta |
| footer | 48 | 1424 | 984 | 56 | footer |

### timeline-flow (Portrait)

Portrait timeline flows vertically — steps stack top-to-bottom.

| Zone | x | y | w | h | Block Type |
|------|---|---|---|---|------------|
| title | 48 | 48 | 984 | 120 | title |
| process | 48 | 180 | 984 | 700 | process-strip (vertical) |
| support | 48 | 900 | 984 | 220 | stat-row / text-block / kpi-card |
| cta | 48 | 1352 | 984 | 72 | cta |
| footer | 48 | 1424 | 984 | 56 | footer |

**Support zone split:** If 2 support blocks, stack vertically (h=100 each, gap 20).

### hub-spoke (Portrait)

| Zone | x | y | w | h | Block Type |
|------|---|---|---|---|------------|
| title | 48 | 48 | 984 | 120 | title |
| diagram | 48 | 180 | 984 | 560 | svg-diagram (rendered as icon-grid) |
| support | 48 | 760 | 984 | 160 | stat-row / text-block |
| cta | 48 | 1352 | 984 | 72 | cta |
| footer | 48 | 1424 | 984 | 56 | footer |

### funnel-pyramid (Portrait — natural fit)

| Zone | x | y | w | h | Block Type |
|------|---|---|---|---|------------|
| title | 48 | 48 | 984 | 120 | title |
| tiers | 48 | 180 | 984 | 700 | icon-grid (rendered as tier bands) |
| support | 48 | 900 | 984 | 140 | stat-row |
| cta | 48 | 1352 | 984 | 72 | cta |
| footer | 48 | 1424 | 984 | 56 | footer |

**Tier band rendering:** Each tier is a horizontal frame with decreasing width, stacked vertically inside the tiers zone. Width formula: `tier_w = 984 * (1 - tier_index * 0.15)`. All tiers centered horizontally. Fill intensity increases toward apex (lighter cream → darker surface).

### list-grid (Portrait)

| Zone | x | y | w | h | Block Type |
|------|---|---|---|---|------------|
| title | 48 | 48 | 984 | 120 | title |
| grid | 48 | 180 | 984 | 700 | icon-grid (2-col, 3-4 rows) |
| support | 48 | 900 | 984 | 140 | text-block / stat-row |
| cta | 48 | 1352 | 984 | 72 | cta |
| footer | 48 | 1424 | 984 | 56 | footer |

### flow-diagram (Portrait)

| Zone | x | y | w | h | Block Type |
|------|---|---|---|---|------------|
| title | 48 | 48 | 984 | 120 | title |
| diagram | 48 | 180 | 984 | 480 | svg-diagram (rendered as process-strip or icon-grid) |
| annot-1 | 48 | 680 | 984 | 100 | text-block |
| annot-2 | 48 | 800 | 984 | 100 | text-block |
| annot-3 | 48 | 920 | 984 | 100 | text-block |
| cta | 48 | 1352 | 984 | 72 | cta |
| footer | 48 | 1424 | 984 | 56 | footer |

**Annotations stack vertically** in portrait (unlike landscape where they sit side-by-side).

---

### Landscape Overrides

When `orientation == landscape`, use the 1528x1080 canvas (DIN A4 rotated). The general
pattern: zones sit side-by-side instead of stacking. Title at y=48 (h=120), content from
y=180, CTA at y=858 (h=72), footer at y=930 (h=56). Usable width = 1432.

Key differences from portrait:
- KPI cards sit 3-across (w=590 each) instead of 2+1
- Chart sits beside stat-row (60/40 split) instead of full-width stacked
- Process strip runs horizontal (chevron-right) instead of vertical (chevron-down)
- Icon-grid uses 3 columns instead of 2
- Annotation text-blocks sit side-by-side in a row instead of stacking

Compute landscape positions using the same zone structure with `W=1824` and content area
height of 686px (with CTA) or 808px (without CTA).

---

## Lucide Icon Mapping

Map brief `icon-prompt` descriptions to Lucide icon names for `icon_font` elements.

| Prompt Pattern | Lucide Icon |
|---------------|-------------|
| shield, security, protection | `shield` |
| chart, graph, trending | `bar-chart-2` |
| brain, AI, intelligence | `brain` |
| camera, video, surveillance | `camera` |
| bell, alert, notification | `bell` |
| clock, time, speed | `clock` |
| check, success, complete | `check-circle` |
| warning, danger, risk | `triangle-alert` |
| users, people, team | `users` |
| globe, world, international | `globe` |
| target, goal, focus | `target` |
| lightbulb, idea, insight | `lightbulb` |
| arrow-up, increase, growth | `trending-up` |
| arrow-down, decrease, decline | `trending-down` |
| lock, secure, privacy | `lock` |
| euro, money, cost, price | `euro` |
| dollar, revenue, profit | `dollar-sign` |
| calendar, date, schedule | `calendar` |
| zap, energy, power, fast | `zap` |
| layers, stack, tiers | `layers` |

When no match found, default to `circle-dot`.

---

## Batching Guidelines

- Target 15-25 operations per `batch_design` call
- Title + background: 1 batch (~6 ops)
- Each content block: 1 batch (8-25 ops depending on type)
- CTA + footer: 1 batch (~15 ops)
- Typical infographic total: 6-10 batch calls, 80-160 total operations
- Always create parent frames before child elements in the same batch
