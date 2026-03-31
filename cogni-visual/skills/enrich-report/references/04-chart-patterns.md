# Chart.js Configuration Patterns

Themed Chart.js templates for each data-track enrichment type. All color values reference CSS custom properties — the generator script resolves them from design-variables.json at HTML build time.

## Global Defaults

Every chart config inherits these base options:

```json
{
  "responsive": true,
  "maintainAspectRatio": true,
  "plugins": {
    "legend": {
      "position": "bottom",
      "labels": {
        "font": { "family": "var(--font-body)", "size": 13 },
        "color": "var(--text)",
        "padding": 16,
        "usePointStyle": true
      }
    },
    "tooltip": {
      "backgroundColor": "var(--surface-dark)",
      "titleColor": "var(--text-light)",
      "bodyColor": "var(--text-light)",
      "titleFont": { "family": "var(--font-headers)", "weight": 600 },
      "bodyFont": { "family": "var(--font-body)" },
      "cornerRadius": 8,
      "padding": 12
    }
  },
  "scales": {
    "shared_axis_style": {
      "ticks": {
        "font": { "family": "var(--font-body)", "size": 12 },
        "color": "var(--text-muted)"
      },
      "grid": {
        "color": "var(--border)",
        "lineWidth": 0.5
      }
    }
  }
}
```

**CSS variable resolution:** The Python generator replaces `var(--name)` tokens in the JSON with actual hex values from design-variables.json before embedding in the HTML script block. Chart.js does not natively support CSS variables — this is a build-time substitution.

## Color Palette

The standard chart color sequence, derived from design-variables:

```javascript
const CHART_COLORS = [
  designVars.colors.accent,       // Primary data series
  designVars.colors.primary,      // Secondary
  designVars.colors.secondary,    // Tertiary
  designVars.status.info,         // 4th
  designVars.status.success,      // 5th
  designVars.status.warning,      // 6th
  designVars.colors.accent_muted, // 7th
  designVars.status.danger        // 8th (only for negative connotation)
];
```

For TIPS-specific charts, use the TIPS dimension colors:
```javascript
const TIPS_COLORS = {
  trend:       '#F59E0B',  // amber
  implication: '#06B6D4',  // cyan
  possibility: '#8B5CF6',  // purple
  solution:    '#22C55E'   // green
};
```

These are the only hardcoded colors (TIPS brand identity) — everything else comes from design-variables.

## Chart Templates

### `kpi-dashboard`

Not a Chart.js canvas — pure HTML metric cards. Optional mini sparkline per card.

**HTML structure per card:**
```html
<div class="kpi-card">
  <div class="kpi-value">{value}</div>
  <div class="kpi-label">{label}</div>
  <div class="kpi-source"><a href="{source_url}">{source_name}</a></div>
</div>
```

**CSS:**
```css
.kpi-row { display: flex; gap: 16px; flex-wrap: wrap; margin: 24px 0; }
.kpi-card {
  flex: 1; min-width: 140px; max-width: 220px;
  background: var(--surface); border-radius: var(--radius);
  padding: 20px; text-align: center;
  box-shadow: var(--shadow-sm);
  border-top: 3px solid var(--accent);
}
.kpi-value {
  font-family: var(--font-headers); font-size: 2rem; font-weight: 700;
  color: var(--accent-dark); line-height: 1.2;
}
.kpi-label {
  font-family: var(--font-body); font-size: 0.85rem;
  color: var(--text-muted); margin-top: 6px;
}
.kpi-source { font-size: 0.75rem; color: var(--text-muted); margin-top: 8px; }
.kpi-source a { color: var(--accent); text-decoration: none; }
```

---

### `horizon-chart`

**Chart.js type:** `bar` (horizontal, stacked)

```json
{
  "type": "bar",
  "data": {
    "labels": ["Theme 1", "Theme 2", "Theme 3"],
    "datasets": [
      {
        "label": "ACT (0-2y)",
        "data": [4, 3, 5],
        "backgroundColor": "var(--status-danger)",
        "barThickness": 28
      },
      {
        "label": "PLAN (2-5y)",
        "data": [3, 4, 2],
        "backgroundColor": "var(--status-warning)",
        "barThickness": 28
      },
      {
        "label": "OBSERVE (5y+)",
        "data": [1, 2, 1],
        "backgroundColor": "var(--status-info)",
        "barThickness": 28
      }
    ]
  },
  "options": {
    "indexAxis": "y",
    "scales": {
      "x": { "stacked": true, "title": { "display": true, "text": "Candidates" } },
      "y": { "stacked": true }
    },
    "plugins": {
      "title": { "display": true, "text": "Horizon Distribution by Theme", "font": { "family": "var(--font-headers)", "size": 16, "weight": 600 } }
    }
  }
}
```

**German labels:** "Handeln (0-2J)", "Planen (2-5J)", "Beobachten (5J+)", axis: "Kandidaten"

**Container:** max-width 720px, height 400px (scales with theme count).

---

### `theme-radar`

**Chart.js type:** `radar`

```json
{
  "type": "radar",
  "data": {
    "labels": ["Candidates", "Evidence Density", "ACT Ratio", "Claims", "Solution Templates"],
    "datasets": [
      {
        "label": "Theme 1",
        "data": [80, 65, 90, 70, 50],
        "borderColor": "var(--accent)",
        "backgroundColor": "var(--accent)20",
        "pointBackgroundColor": "var(--accent)"
      }
    ]
  },
  "options": {
    "scales": {
      "r": {
        "beginAtZero": true,
        "max": 100,
        "ticks": { "stepSize": 25, "font": { "size": 11 } },
        "pointLabels": { "font": { "family": "var(--font-body)", "size": 12 } }
      }
    },
    "plugins": {
      "title": { "display": true, "text": "Investment Theme Comparison" }
    }
  }
}
```

**German labels:** "Kandidaten", "Evidenzdichte", "Handeln-Anteil", "Claims", "Lösungsbausteine"

**Container:** 400x400px, centered.

---

### `coverage-heatmap`

**Chart.js type:** `bar` (grouped)

```json
{
  "type": "bar",
  "data": {
    "labels": ["Theme 1", "Theme 2", "Theme 3"],
    "datasets": [
      {
        "label": "With Evidence",
        "data": [85, 60, 92],
        "backgroundColor": "var(--status-success)"
      },
      {
        "label": "Without Evidence",
        "data": [15, 40, 8],
        "backgroundColor": "var(--border)"
      }
    ]
  },
  "options": {
    "scales": {
      "x": { "stacked": true },
      "y": { "stacked": true, "max": 100, "title": { "display": true, "text": "%" } }
    }
  }
}
```

**Container:** max-width 720px, height 350px.

---

### `distribution-doughnut`

**Chart.js type:** `doughnut`

```json
{
  "type": "doughnut",
  "data": {
    "labels": ["Segment A", "Segment B", "Segment C"],
    "datasets": [{
      "data": [45, 35, 20],
      "backgroundColor": ["var(--accent)", "var(--primary)", "var(--secondary)"],
      "borderColor": "var(--surface)",
      "borderWidth": 3
    }]
  },
  "options": {
    "cutout": "55%",
    "plugins": {
      "legend": { "position": "right" },
      "title": { "display": true, "text": "Distribution" }
    }
  }
}
```

**Container:** 350x350px, centered.

---

### `timeline-chart`

**Chart.js type:** `line` with custom point styles

```json
{
  "type": "line",
  "data": {
    "labels": ["Q1 2025", "Q2 2025", "Q3 2025", "Q4 2025", "Q1 2026", "Q2 2026"],
    "datasets": [{
      "label": "Milestones",
      "data": [null, 1, null, 2, null, 3],
      "borderColor": "var(--accent)",
      "backgroundColor": "var(--accent)",
      "pointRadius": 8,
      "pointStyle": "rectRounded",
      "showLine": true,
      "borderDash": [5, 5]
    }]
  },
  "options": {
    "scales": {
      "y": { "display": false },
      "x": { "title": { "display": true, "text": "Timeline" } }
    },
    "plugins": {
      "tooltip": {
        "callbacks": { "label": "function(ctx) { return milestoneLabels[ctx.dataIndex]; }" }
      }
    }
  }
}
```

For a true timeline, use milestone labels as tooltip callbacks. The Y-axis is hidden — this is a 1D timeline.

**Container:** max-width 720px, height 200px.

---

### `comparison-bar`

**Chart.js type:** `bar` (horizontal)

```json
{
  "type": "bar",
  "data": {
    "labels": ["Item A", "Item B", "Item C", "Item D"],
    "datasets": [{
      "data": [85, 72, 68, 45],
      "backgroundColor": ["var(--accent)", "var(--accent-muted)", "var(--primary)", "var(--secondary)"],
      "barThickness": 24,
      "borderRadius": 4
    }]
  },
  "options": {
    "indexAxis": "y",
    "scales": {
      "x": { "beginAtZero": true }
    },
    "plugins": {
      "legend": { "display": false }
    }
  }
}
```

**Container:** max-width 720px, height scales with item count (60px per item + 80px padding).

---

### `stat-chart`

**Chart.js type:** `bar` (vertical) or `line` — decision rule:
- If data has temporal axis (years, quarters) → `line`
- If data is categorical (items, regions, categories) → `bar`

Uses the base `comparison-bar` or `timeline-chart` template as appropriate, with adjusted orientation and labels.

**Container:** max-width 720px, height 350px.

---

## Responsive Behavior

All chart containers use:
```css
.chart-container {
  max-width: 720px;
  margin: 32px auto;
  padding: 24px;
  background: var(--surface);
  border-radius: var(--radius);
  box-shadow: var(--shadow-sm);
}
.chart-container canvas {
  max-width: 100%;
}
```

At viewport < 768px:
- Chart containers go full width
- KPI cards stack vertically (1 per row)
- Radar charts reduce to 300x300px
