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
must look like a real Economist data page — not a dashboard, not a slide deck, not a poster.

## The Economist Visual DNA

Study any Economist data page and you'll see these non-negotiable traits. They are what
separate "clean infographic" from "this belongs in The Economist":

### It's a Newspaper Page, Not a Dashboard

The Economist data page is a **multi-column newspaper layout**. Content flows in 2-3 columns
with blocks sitting *beside* each other, not stacked in a single column. Data visualizations,
text paragraphs, and icons coexist side by side in a complex but readable grid. Every square
centimeter is used — the page is FULL. If your output has large empty areas between blocks,
it's wrong.

Think of how a magazine editor lays out a feature page: text wraps, charts sit inline, stats
anchor columns, pull-quotes break up prose. That's the density target.

### No Cards, No Boxes

Data lives directly on the cream background. There are NO bordered cards, NO box shadows, NO
container frames around individual stats. Structure comes from:
- **Red rule lines** (thin horizontal lines, `height: 2, fill: $--rule-color`) between major
  sections — this is The Economist's most recognizable visual signature
- **Spatial grouping** — related elements sit close together, unrelated ones have breathing
  room between them
- **Alternating background bands** — optional `$--background-alt` zones for visual rhythm

### Numbers at Poster Scale

Hero numbers are ENORMOUS — think 64-80pt font. They are the visual anchors that a reader's
eye lands on first from across the room. Supporting stat numbers are 36-48pt. Labels are tiny
(10-12pt) beneath them. The size contrast between number and label should be dramatic — at
least 4:1 ratio.

### Icons as Visual Landmarks

Icons are bold, sized 36-48px, in red or amber fill. They serve as visual landmarks that help
the eye navigate the dense layout — like section markers in a newspaper. A tiny 16px icon is
useless; it disappears in the density. Map Icon-Prompt descriptions to Lucide icon names
(see layouts library).

### The Color Discipline

Only three colors carry meaning:
- **Economist red** (#C00000) — hero numbers, bar chart fills, rule lines, primary icons
- **Amber** (#D4A017) — secondary icons, tertiary highlights
- **Near-black** (#1A1A1A) — body text, labels

Everything else is cream (#FBF9F3) or darker cream (#F0EDE4). If you find yourself reaching
for a fourth color, stop — restraint is the style.

### Illustrations and Visual Storytelling

Real Economist data pages include small illustrations, diagrams, and visual metaphors
alongside the data — a map showing geographic context, a simple diagram explaining a
process, a visual metaphor (scales, gears, arrows) reinforcing the narrative. These are
NOT decorative — they are editorial illustrations that help the reader understand the story.

For each infographic, generate 1-2 small editorial illustrations:
- **Process diagrams** — if the brief has a process-strip, render it as a visual diagram
  with connected shapes, not just a text chain
- **Contextual icons at scale** — a large (80-120px) illustration-style icon that anchors
  the page visually (e.g., a camera + shield composite for security, a building for
  infrastructure)
- **Comparison visuals** — if before/after, show a visual transformation (arrow from old to new)
- **Data callout annotations** — short 1-2 sentence prose annotations beside charts
  explaining what the data means ("Seit Q3 2024 sinken die Vorfälle rapide — der Pilotstart
  markiert den Wendepunkt")

### Content Amplification

A real Economist data page feels dense because it contains MORE content than just the raw
data blocks. The brief provides the core data — you should amplify it:

- **Add prose annotations** (2-3 sentences) beside major data blocks explaining context
- **Add data callouts** — "↓ 73% seit Pilotstart" as an annotation on the chart
- **Add section subheadings** — "DAS PROBLEM", "DIE LÖSUNG", "DER BEWEIS" in red uppercase
- **Add pull-quote style callouts** from the governing thought
- **Reference the source** inline beside data, not just in the footer

Do NOT invent new numbers or statistics. Annotations must derive from the brief's content
and governing thought. You are adding editorial context, not fabricating data.

### Sharp Edges, Zero Decoration

- `cornerRadius: 0` on everything — rounded corners would undermine authority
- No shadows, no gradients, no purely decorative elements
- No borders on content blocks (only red rule lines between sections)
- Illustrations must be editorial (communicating meaning), not ornamental

### Other Presets (editorial, data-viz, corporate)

These follow the same density and layout discipline but use the theme's own palette:
- **editorial**: Theme accent instead of red. Same sharp edges, same density.
- **data-viz**: Monospace numbers, accent-tinted backgrounds for stat zones, uppercase labels.
- **corporate**: Dark header banner, primary color for numbers, strong footer branding.

## What the Output Must Achieve

A viewer should perceive "credible data journalism." The 10-second test: from a glance, they
should see the governing thought (headline), the hero number, and the call to action. The
density tells them "this is thoroughly researched."

- **Bar chart heights must be proportional** to actual data values — compute heights, never eyeball
- **Sources must appear** — unsourced data is untrustworthy
- **Do not invent, skip, or reorder blocks** from the brief
- **All text and numbers verbatim** from the brief — no rounding, no rephrasing

## Input

| Parameter | Required | Description |
|-----------|----------|-------------|
| BRIEF_PATH | Yes | Path to infographic-brief.md |
| OUTPUT_PATH | No | Path for .pen file (default: `{brief_dir}/infographic.pen`) |

Output goes into the same directory as the brief.

## Workflow

### 1. Parse Brief

1. Read infographic-brief.md, validate `type: infographic-brief`, `version: "1.0"`
2. Extract frontmatter: `layout_type`, `style_preset`, `orientation`, `dimensions`, `theme_path`, `language`
3. Parse `## Block N:` sections — build ordered block list
4. Read theme.md from `theme_path`. If unavailable, use Economist defaults
5. Read `$CLAUDE_PLUGIN_ROOT/libraries/infographic-pencil-layouts.md` for Pencil-specific patterns (Economist token overrides, Lucide icon mapping)

### 2. Design Token Setup

Map theme to Pencil variables. Define names WITHOUT `$` in `set_variables`, reference WITH `$--` prefix in fills/colors.

**Economist overrides** — layer on top of theme variables:

| Token | Value | Purpose |
|-------|-------|---------|
| `--primary` | `#C00000` | Economist red — hero numbers, bars, rules |
| `--background` | `#FBF9F3` | Cream — the paper feel |
| `--background-alt` | `#F0EDE4` | Darker cream for alternating bands |
| `--foreground` | `#1A1A1A` | Near-black text |
| `--foreground-muted` | `#666666` | Labels, source lines |
| `--chart-fill` | `#C00000` | Bar fills |
| `--chart-fill-2` | `#E8A0A0` | Secondary bar series |
| `--rule-color` | `#C00000` | Section divider lines |
| `--accent-amber` | `#D4A017` | Secondary icons, tertiary highlights |

For non-economist presets: `--chart-fill` = theme primary, `--rule-color` = theme foreground-muted.

### 3. Open Document and Compose

1. `get_guidelines("design-system")` — load Pencil design system
2. `open_document("{output_path}")` — file-backed
3. Create root page frame (portrait 1080x1528 for economist, landscape 1528x1080 otherwise)
4. Set page margins: 48px left/right, 32px top/bottom. Usable content area: ~984px wide.

#### Think Before You Draw

Before inserting ANY Pencil elements, use extended thinking to plan the full page layout.
This planning step is critical — without it you will default to a dashboard layout, which
is NOT what The Economist looks like.

1. **Count your blocks** — how many content blocks, what types, what sizes they need
2. **Sketch the grid in your mind** — which blocks share a row? Which span full width?
3. **Compute dimensions** — usable area is ~984px wide × ~1460px tall. Every pixel must be
   accounted for. Allocate specific heights per row. They must sum to fill the page.
4. **Pair blocks** — every block should share its row with another block unless it genuinely
   needs full width (only charts and process strips qualify). A single KPI alone on a row
   is wasted space — pair it with a text annotation or another data block.
5. **Check density** — if any row has more than 24px of empty padding around its content,
   the content is too small or the row is too tall. Scale up or redistribute.

Only after you have a complete layout plan should you start inserting elements.

#### Reference: What a Stat-Heavy Economist Page Looks Like

This is the spatial composition you're aiming for. Study it — notice how dense it is,
how blocks share rows, how text and data interweave:

```
┌──────────────────────────────────────────────────┐
│ DEUTSCHE BAHN AG | TECHVISION SOLUTIONS | 2026   │ ← red uppercase metadata, 11px
│══════════════════════════════════════════════════│ ← double rule (black)
│                                                  │
│ KI-Videoanalytik senkt                          │ ← serif headline, 38-42px bold
│ Sicherheitsvorfälle um 73%                      │
│ Warum Deutsche Bahn jetzt auf automatisierte... │ ← subline, 14px muted
│──────────────────────────────────────────────────│ ← RED rule line
│ 🛡                        ⏱           📷   🕐  │
│ 73%              < 2s    500+   24/7  │ ← hero 96px + 3 stats 44px
│ weniger Vorfälle   Erkennungs- Kameras Über-    │   ALL ON THE SAME ROW
│ nach Pilotprojekt  zeit    skalierbar wachung   │
│ München Hbf                                     │
│ Quelle: Interne...                              │
│──────────────────────────────────────────────────│ ← RED rule line
│ Sicherheitsvorfälle    │ Kontext Deutschland     │ ← TWO COLUMNS side by side
│ pro Quartal            │                         │
│ ┌──┐┌──┐┌──┐          │  ⚠ 688                  │
│ │  ││  ││  │┌──┐      │    Bahnsuizide 2023     │
│ │  ││  ││  ││  │┌──┐  │                         │
│ │172│168│155│ 89│ 47│  │  ⓘ 2.661                │
│ └──┘└──┘└──┘└──┘└──┘  │    Übergriffe           │
│ Q1   Q2  Q3  Q4  Q1   │                         │
│ 24   24  24  24  25   │  🏢 5.400                │
│                        │    Bahnhöfe             │
│──────────────────────────────────────────────────│ ← RED rule line
│ 🚀 12 Wochen          │ Kameradaten → KI-Analyse │ ← KPI + PROCESS on same row
│ bis zum Pilotstart     │ → Echtzeit-Alert →      │
│ schlüsselfertige Impl. │ Einsatzsteuerung        │
│──────────────────────────────────────────────────│ ← RED rule line
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│▓ Pilot in 12 Wochen starten  [Erstgespräch]    ▓│ ← dark CTA band
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│ Deutsche Bahn AG    April 2026   TechVision Sol. │
│ Quellen: BKA Bundeslagebild 2023, Interne Pilot..│
└──────────────────────────────────────────────────┘
```

Key things to notice in this reference:
- **Hero KPI (73%) shares its row with the supporting stats** — not separate sections
- **Bar chart sits beside context evidence** — two columns, not stacked
- **12 Wochen shares its row with the process strip** — never one item alone on a row
- **Red rules between every major section** — 4-5 rules on the page
- **No borders on any data block** — only rules and spatial grouping
- **The page is completely FULL** — no row has unused space

#### Page Composition: The Newspaper Grid

Think like a magazine editor laying out a feature page:

**Top band** (full width): Title block
- Double rule line (2px black, 1px black, 4px gap) across full width — The Economist header
- Metadata line (uppercase, 11px, red, letterspaced) — "DEUTSCHE BAHN AG | TECHVISION SOLUTIONS | APRIL 2026"
- Headline (serif, 36-42px, bold black) immediately below
- Subline (16px, muted) beneath headline
- Red rule line below the title band

**Content area** (2-3 column grid, fills the middle 60-70% of the page):
- Divide into columns: 2-col = ~480px each, 3-col = ~312px each, with 24px gutters
- **Place blocks beside each other across columns**, not just stacked vertically
- A hero KPI can take a full column or half. A stat-row of 3 items spans full width.
- A bar chart spans 1.5-2 columns. A text block or icon-grid fills 1 column beside it.
- Between major content rows, insert a red rule line (full width, 2px, `$--rule-color`)
- Alternate cream bands: every other content row gets `$--background-alt` fill behind it

**Block rendering — what each block becomes on the page:**

| Block Type | What It Becomes |
|------------|----------------|
| **kpi-card** | Large red number (64-80px bold) with tiny label below (10-12px muted). Red/amber icon (36-48px) to the left or above. Source line (9px muted) at bottom. NO border, NO card frame. Sits directly on cream. |
| **stat-row** | Horizontal strip spanning full width. Each stat: bold number (36-48px) with tiny label below. Separated by vertical thin rules or spacing. Icons (28-36px, amber) beside each number. |
| **chart** | Bar chart spanning 1.5-2 columns. Red fill bars, proportional heights computed as `bar_h = value / max_value * max_bar_height`. Value labels (11px bold) above each bar. Category labels (10px) below. Thin axis line at bottom. |
| **comparison-pair** | Two columns with visual weight difference. Left (status quo): muted text, small red warning icon. Right (proposed): bold text, green/amber success icon. Vertical rule line between columns. Column headers bold with icon. |
| **process-strip** | Horizontal chain: icon circles (36px, red fill) connected by thin arrows. Step labels (11px) below each. Spans full width. |
| **text-block** | Headline (16px bold) + body (12px) flowing in a single column. Sits beside a chart or stat block, not on its own row. |
| **icon-grid** | 2-3 column mini-grid. Each item: icon (36px, red/amber) + bold label (13px) + sublabel (11px muted). No borders on items. |
| **cta** | Dark band (`$--surface-dark`) spanning full width. White headline text + red button. |
| **footer** | Full width: left/center/right metadata + source line. Tiny text (9-10px). Top border rule. |

**Critical layout rules:**
- Fill the page — if content doesn't reach the bottom, increase spacing or scale up elements
- Never stack more than 2 blocks vertically without placing something beside them
- Hero numbers and icons must be visible from arm's length — if they're small, scale up
- Red rule lines between every major section transition — aim for 3-5 rules on the page

**Pencil syntax patterns:**
- `I(parent, {...})` for inserts, `$--token` references for colors/fonts
- Create parent frames before children
- Batch 15-25 operations per `batch_design` call
- Rule line: `I(parent, {width: "fill_container", height: 2, fill: "$--rule-color"})`

### 4. Validate

1. `get_screenshot()` — visual verification
2. `snapshot_layout(problemsOnly: true)` — detect overlaps/clipping
3. Check quality gates:

| Gate | What to Look For |
|------|-----------------|
| **Density** | Page should feel FULL — like a newspaper, not a dashboard. No large empty areas. |
| **Number Scale** | Hero numbers must be the largest elements on the page — visible from across a room |
| **No Cards/Boxes** | Blocks must NOT have bordered containers. Only red rules and spatial grouping. |
| **Column Layout** | Content must flow in 2-3 columns, not single-column stack |
| **Red Rules** | Thin red horizontal lines between major sections — The Economist signature |
| **Icon Size** | Icons at 36-48px in red/amber fill, not tiny dots |
| **Bar Proportions** | Bar heights must match actual data ratios |

4. Fix issues with targeted Update operations. Maximum 2 fix iterations.

### 5. Export and Return

Export to PNG: `export_nodes({format: "png", ...})`

Return JSON only:
```json
{"ok": true, "pen_path": "{path}", "layout_type": "{type}", "style_preset": "{preset}", "orientation": "{orientation}", "blocks_rendered": {N}, "total_ops": {N}}
```

## Error Recovery

| Scenario | Action |
|----------|--------|
| Brief not found | Return error JSON |
| Pencil MCP unavailable | Fall back to generating a self-contained HTML file with the same editorial styling. Use the `generate-infographic.py` script at `$CLAUDE_PLUGIN_ROOT/skills/render-infographic/scripts/generate-infographic.py` if available, or generate HTML directly. Return `{"ok": true, "fallback": "html", "html_path": "{path}", ...}` |
| Invalid layout_type | Default to stat-heavy |
| Chart type not bar | Render as stat-row of values |
| Icon-prompt has no Lucide match | Use `circle-dot` fallback |
| Zone overlap detected | Reposition with smaller zone heights |
| Brief has > 14 content blocks | Render first 14, warn in response |
