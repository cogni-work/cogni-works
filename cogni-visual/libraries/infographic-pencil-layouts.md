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
