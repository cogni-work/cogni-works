# HTML Structure

Layout architecture, CSS patterns, and script structure for the enriched report HTML output.

## Overall Layout

```
┌─────────────────────────────────────────────────────┐
│  ┌──────────┐  ┌─────────────────────────────────┐  │
│  │ Sidebar  │  │  Main Content (max-width 860px) │  │
│  │ (260px)  │  │                                 │  │
│  │          │  │  H1 Title                       │  │
│  │ Contents │  │  ─────────────────              │  │
│  │ ● Sec 1  │  │  Report prose...               │  │
│  │ ● Sec 2  │  │                                 │  │
│  │   ○ 2.1  │  │  ┌─[KPI Dashboard]─────────┐   │  │
│  │   ○ 2.2  │  │  │ €173B │ 47% │ 3.2x     │   │  │
│  │ ● Sec 3  │  │  └─────────────────────────┘   │  │
│  │          │  │                                 │  │
│  │          │  │  More prose...                  │  │
│  │          │  │                                 │  │
│  │          │  │  ┌─[Chart.js Canvas]────────┐   │  │
│  │          │  │  │  ████ ██ █████           │   │  │
│  │          │  │  │  Horizon Distribution     │   │  │
│  │          │  │  └─────────────────────────┘   │  │
│  │          │  │                                 │  │
│  │          │  │  ┌─[Concept SVG]─────────────┐   │  │
│  │          │  │  │  T → I → P → S flow      │   │  │
│  │          │  │  └─────────────────────────┘   │  │
│  │          │  │                                 │  │
│  │          │  │  Footer                        │  │
│  └──────────┘  └─────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

## CSS Architecture

All styles use CSS custom properties from `:root {}` — no hardcoded values in component styles.

**Design token categories:**
- Colors: `--primary`, `--secondary`, `--accent`, `--accent-muted`, `--accent-dark`, `--bg`, `--surface`, `--surface2`, `--surface-dark`, `--border`, `--text`, `--text-light`, `--text-muted`
- Status: `--status-success`, `--status-warning`, `--status-danger`, `--status-info`
- Typography: `--font-headers`, `--font-body`, `--font-mono`
- Spacing: `--radius`, `--shadow-sm`, `--shadow-md`, `--shadow-lg`, `--shadow-xl`

## Enrichment Container Classes

| Class | Purpose | Max-Width |
|-------|---------|-----------|
| `.chart-container` | Chart.js canvas wrapper | 720px |
| `.concept-diagram` | Concept diagram SVG wrapper | 720px |
| `.summary-card` | Key takeaway callout | 720px |
| `.kpi-row` | Flex container for KPI cards | 720px |
| `.kpi-card` | Individual metric card | 220px |

All enrichment containers are centered with `margin: 32px auto` to create visual breathing room between prose and visualizations.

## Chart.js Integration

Chart.js is loaded once from CDN in `<head>`:
```html
<script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>
```

Each chart gets:
1. A `<canvas id="enr-XXX">` element in the content flow
2. An initialization function in the bottom `<script>` block

**Color resolution:** CSS variable tokens in chart configs (`var(--accent)`) are resolved to hex values at build time by the Python generator. Chart.js does not support CSS variables natively.

## SVG Embedding

Concept diagrams are embedded inline as `<svg>` elements (not `<img src>`). This ensures:
- No external file dependencies (self-contained HTML)
- SVG inherits page context (though colors are baked in from export)
- Responsive scaling via `max-width: 100%; height: auto`

## Navigation Sidebar

- **Sticky:** `position: sticky; top: 0; height: 100vh`
- **Scroll spy:** JavaScript tracks scroll position and highlights the current section's nav link
- **Depth indentation:** H2 links flush left, H3 indented 16px, H4 indented 32px
- **Active state:** `.active` class applies accent background color
- **Hidden on mobile:** `display: none` below 1024px viewport width

## Script Block Structure

```html
<script>
document.addEventListener('DOMContentLoaded', function() {
  // 1. Chart.js initializations (one IIFE per chart)
  (function() { new Chart('enr-001', {...}); })();
  (function() { new Chart('enr-002', {...}); })();

  // 2. Scroll spy for navigation
  // Updates .active class on nav links based on scroll position

  // 3. Smooth scroll for nav link clicks (optional)
});
</script>
```

## Responsive Breakpoints

| Breakpoint | Changes |
|-----------|---------|
| > 1024px | Sidebar visible, content max-width 860px |
| 768-1024px | Sidebar hidden, content full width with 20px padding |
| < 768px | KPI cards stack vertically, charts full width, smaller headings |

## File Size Considerations

- Chart.js CDN: ~60KB gzipped (cached across loads)
- Inline SVGs: 5-30KB each depending on complexity
- Total HTML: typically 200-500KB for a fully enriched trend-report
- All self-contained except Chart.js CDN reference
