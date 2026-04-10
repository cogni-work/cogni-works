# Infographic Pencil Reference

Pencil MCP reference for the `render-infographic-pencil` agent. Contains tool-specific
knowledge the LLM cannot derive from design experience alone: token overrides, icon mapping,
and API syntax patterns.

---

## Canvas Specification

| Orientation | Width | Height | Margin | Usable Area |
|-------------|-------|--------|--------|-------------|
| portrait (default) | 1080 | 1528 | 48 | 984 x 1432 |
| landscape | 1528 | 1080 | 48 | 1432 x 984 |

---

## Economist Design Token Overrides

When `style_preset == economist`, call `set_variables` a second time with these overrides.
They layer The Economist's visual identity on top of the theme's base tokens.

```
--primary:            #C00000    (Economist red)
--accent:             #C00000    (red is the accent)
--accent-amber:       #D4A017    (secondary — icons, tertiary highlights)
--background:         #FBF9F3    (cream)
--background-alt:     #F0EDE4    (darker cream for alternate zones)
--foreground:         #1A1A1A    (near-black)
--foreground-muted:   #666666    (mid-grey for sublabels)
--surface-dark:       #1A1A1A    (dark bands)
--surface-dark-text:  #FFFFFF    (white on dark)
--surface-dark-muted: #AAAAAA    (muted on dark)
--chart-fill:         #C00000    (primary bar fill)
--chart-fill-2:       #E8A0A0    (secondary bar — lighter red)
--chart-fill-3:       #D4A017    (tertiary — amber for multi-series)
--rule-color:         #C00000    (section divider rule lines)
```

For other presets: `--chart-fill` = `$--primary`, `--rule-color` = `$--foreground-muted`.

---

## Lucide Icon Mapping

Map brief `Icon-Prompt` descriptions to Lucide icon names for `icon_font` elements.

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

Default fallback: `circle-dot`

---

## Pencil batch_design Syntax

Target 15-25 operations per `batch_design` call. Create parent frames before child elements
in the same batch.

**Insert:** `foo=I("parent_id", { properties })`
**Update:** `U("node_id", { properties })`
**Copy:** `bar=C("source_id", "parent_id", { overrides })`
**Replace:** `baz=R("old_id", { properties })`

Variable references use `$--` prefix in property values: `fill: "$--primary"`,
`fontFamily: "$--font-body"`. Variable names are defined WITHOUT `$` in `set_variables`.

---

## Composition Patterns for Economist Pages

These patterns show how to build the specific visual elements that make an Economist
data page feel like The Economist, not a dashboard.

### Two-Column Row (data beside data)

A chart in the left column, context stats in the right column — separated by space, not borders:

```
row=I(page, {x: 48, y: Y, width: 984, height: 280, layout: "horizontal", gap: 32})
  left=I(row, {width: 600, layout: "vertical", gap: 8})
    I(left, {type: "text", fontSize: 13, fontWeight: "Bold", content: "Sicherheitsvorfälle pro Quartal"})
    // ... chart bars here
  right=I(row, {width: 352, layout: "vertical", gap: 16})
    I(right, {type: "text", fontSize: 11, fontWeight: "Bold", fill: "$--primary", content: "KONTEXT DEUTSCHLAND"})
    // ... context stats here
```

### Hero KPI with Inline Stats (single row)

The hero number shares its row with 3 supporting stats — everything on one line:

```
row=I(page, {x: 48, y: Y, width: 984, height: 140, layout: "horizontal", gap: 0})
  hero=I(row, {width: 360, layout: "vertical", gap: 4})
    I(hero, {type: "icon_font", fontSize: 36, fill: "$--primary", content: "shield"})
    I(hero, {type: "text", fontSize: 96, fontWeight: "Bold", fill: "$--primary", content: "73%"})
    I(hero, {type: "text", fontSize: 14, fontWeight: "Bold", content: "weniger Vorfälle"})
  stats=I(row, {width: 624, layout: "horizontal", gap: 24, padding: [24, 0, 0, 48]})
    // 3 stat columns here, each with icon + number (44px) + label (11px)
```

### Red Rule Line (section divider)

```
I(page, {x: 48, y: Y, width: 984, height: 2, fill: "$--rule-color"})
```

### Editorial Annotation (prose beside data)

Short prose text that sits beside a chart or stat block, explaining context:

```
ann=I(row, {width: 300, layout: "vertical", gap: 8, padding: [8, 16, 8, 16]})
  I(ann, {type: "text", fontSize: 11, fontWeight: "Bold", fill: "$--primary", content: "WARUM DAS WICHTIG IST"})
  I(ann, {type: "text", fontSize: 12, lineHeight: 1.5, content: "Seit dem Pilotstart in München sinken die Vorfälle rapide. Der Trend zeigt: KI-gestützte Überwachung wirkt präventiv."})
```

### Large Illustration Icon (visual landmark)

An icon at editorial scale — serves as visual anchor, not UI element:

```
icon_bg=I(parent, {width: 80, height: 80, fill: "$--primary at 8%", cornerRadius: 0})
  I(icon_bg, {type: "icon_font", fontSize: 48, fill: "$--primary", content: "shield"})
```

### Section Subheading (red uppercase label)

```
I(parent, {type: "text", fontSize: 11, fontWeight: "Bold", fill: "$--primary", letterSpacing: 1.5, content: "DAS PROBLEM"})
```

### Proportional Bar Chart

Compute bar heights from data. With max_bar_height = 180px:

```
bar_h = (value / max_value) * 180
```

Each bar: rectangle with `fill: "$--chart-fill"`, value label (11px bold) above, category
label (10px muted) below. Bars sit directly on the cream background with thin baseline rule.
