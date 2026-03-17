---
name: export-report
description: |
  Export a completed research report to different formats: Markdown (default), HTML, PDF, or DOCX.
  Supports branded theming via cogni-workspace:pick-theme — applies theme colors and fonts to all visual exports.
  Use when the user asks to "export report", "save as HTML", "export to PDF", "export to Word",
  "export to DOCX", "publish report", "convert report", "download report", "share the report",
  "make it pretty", or wants the research output in a specific format for sharing or presentation.
---

# Export Report Skill

## Quick Example

**User**: "Export the report as HTML"

**Result**: Self-contained HTML file at `output/report.html` with:
- Theme-branded typography and colors (or professional defaults if no theme selected)
- Auto-generated table of contents
- Clickable source links (visually distinct in both screen and print)
- Print-optimized CSS that preserves link visibility

## Prerequisites

- Completed research project with `output/report.md`
- For PDF: `weasyprint` Python package (optional, falls back to browser print-to-PDF)

## Workflow

### Phase 0: Locate Report

The export skill needs to find the right project and verify the report exists. Without a completed report, there is nothing to export — and exporting a draft mid-review would publish unverified content.

1. Find the project directory (ask user if ambiguous)
2. Verify `output/report.md` exists (NOT `draft-v*.md` — only the finalized report)
3. Determine requested format(s) from user request

### Phase 1: Pick Theme

Branded exports look more professional and help the user's report stand out. This phase uses the ecosystem's standard theme picker so all cogni plugins produce visually consistent output.

1. Call `cogni-workspace:pick-theme` to let the user select a theme — this returns `theme_path`, `theme_name`, and `theme_slug`
2. Read the selected `theme.md` and derive a `design-variables.json` at `<project-dir>/output/design-variables.json`

**Required tokens** (following `cogni-workspace/references/design-variables-pattern.md`):

| Group | Tokens | Notes |
|-------|--------|-------|
| `colors` | `background`, `surface`, `text`, `accent`, `border` | Foundation palette from theme |
| `colors` | `text_muted`, `text_light`, `surface_dark` | Derived variants |
| `fonts` | `headers`, `body`, `mono` | Font stacks with system fallbacks |
| `google_fonts_import` | Full `@import url(...)` string | Empty string if using system fonts |

**Report-specific derived tokens** (extend the standard design-variables):

| Token | Derived From | Purpose |
|-------|-------------|---------|
| `colors.link` | `accent` | Citation hyperlinks — must meet WCAG AA contrast against `background` |
| `colors.link_visited` | darken `link` by 15% | Visited citation links |
| `colors.toc_background` | `surface` | Table of contents background |
| `colors.blockquote_border` | `border` | Blockquote left border |
| `colors.source_ref` | `text_muted` | Source reference annotations |

**Skip conditions** (proceed without prompting):
- Export format is Markdown only — no theming needed, skip entirely
- Caller already provided a `theme_path` — use it directly
- Only one theme exists — auto-select it, tell the user which theme is being applied

**Fallback**: If no themes are found or the user declines, proceed with the hardcoded default styling (Georgia serif, professional neutrals). The export must never fail because of missing themes.

### Phase 2: Export

Each format builds on the previous — HTML is generated from markdown, PDF from HTML. This cascade means the markdown source is always the single source of truth.

**Citation clickability**: All citation links (`[Source: Publisher](URL)` or configured citation style) must remain clickable in every export format. Links must be visually distinct (colored + underlined) in both screen and print views. Never strip `href` attributes or flatten links to plain text.

**Markdown** (always available):
- `output/report.md` is already the markdown output
- Optionally copy to a user-specified location

**HTML**:
1. Read `references/export-formats.md` for the HTML template
2. Read `output/report.md`
3. If `output/design-variables.json` exists, inject theme tokens into the HTML template's CSS custom properties. If no design variables, use the hardcoded fallback values in the template.
4. If `google_fonts_import` is non-empty, insert it as a `<style>` tag in `<head>`
5. Generate self-contained HTML with: table of contents from headings, clickable source links (underlined, colored), clean typography
6. Write to `output/report.html`

**PDF**:
1. First generate HTML (as above) — the HTML already carries theme styling
2. **Preferred**: Invoke `Skill(document-skills:pdf)` to create the PDF from HTML with full formatting control (reportlab-based, no external dependency). Pass `output/design-variables.json` if it exists so the skill can apply theme tokens to PDF-native elements.
3. **Fallback**: If the pdf skill is unavailable and `weasyprint` is installed: `python3 -c "import weasyprint; weasyprint.HTML('output/report.html').write_pdf('output/report.pdf')"` — weasyprint preserves `<a href>` hyperlinks automatically.
4. **Last resort**: Inform user HTML is available, suggest browser print-to-PDF
5. Write to `output/report.pdf`

**DOCX** (Word):
1. **Preferred**: Invoke `Skill(document-skills:docx)` to create the DOCX from the markdown report with professional formatting (headings, ToC, hyperlinked citations). Pass theme tokens if available: `heading_font` (fonts.headers), `body_font` (fonts.body), `accent_color` (colors.accent), `link_color` (colors.link). The docx skill preserves markdown links as Word hyperlinks.
2. **Fallback**: If the docx skill is unavailable, check if `pandoc` is available: `which pandoc`. If so: `pandoc output/report.md -o output/report.docx --from markdown --to docx`. Pandoc preserves `[text](url)` as clickable Word hyperlinks.
3. **Last resort**: Inform user and suggest `brew install pandoc` or `apt install pandoc`
4. Write to `output/report.docx`

**Presentation** (optional):
- If cogni-visual is available, delegate: `Skill(cogni-visual:presentation-brief)`
- Generates a presentation brief from the report

### Phase 3: Report to User

- List exported files with paths and file sizes
- Mention which theme was applied (or "default styling" if no theme)
- Preview: show first 5 lines of the HTML or confirm PDF page count
- Suggest next steps (share, present, further research)

## Supported Formats

| Format | Output Path | Requirements | Quality |
|--------|-------------|-------------|---------|
| Markdown | `output/report.md` | None (always available) | Source format |
| HTML | `output/report.html` | None (generated inline) | Best for sharing |
| PDF | `output/report.pdf` | `document-skills:pdf` (preferred) or weasyprint | Best for printing |
| DOCX | `output/report.docx` | `document-skills:docx` (preferred) or pandoc | Best for editing/collaboration |

## Error Recovery

| Scenario | Recovery |
|----------|----------|
| `output/report.md` not found | Check if drafts exist — suggest completing review loop first |
| `output/report.md` is empty | Report error, suggest re-running Phase 4 (writer) |
| No themes found | Proceed with hardcoded defaults, inform user |
| pdf skill unavailable + weasyprint not installed | Generate HTML, suggest `pip install weasyprint` or browser print-to-PDF |
| docx skill unavailable + pandoc not installed | Inform user, suggest `brew install pandoc` or `apt install pandoc` |
| HTML generation fails | Fall back to markdown copy with formatting note |
| cogni-visual not available | Skip presentation option, note in output |
