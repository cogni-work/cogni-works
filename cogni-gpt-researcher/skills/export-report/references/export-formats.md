# Export Formats Reference

## HTML Template

The HTML export uses a self-contained template with CSS custom properties. When `output/design-variables.json` exists, substitute theme tokens into the `:root` block. When no design variables are available, the fallback values (after the `|` pipe) produce the same clean default styling as before.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{report_title}</title>
  {google_fonts_import}
  <style>
    :root {
      --color-bg: {colors.background|#ffffff};
      --color-surface: {colors.surface|#f8f8f8};
      --color-text: {colors.text|#333333};
      --color-text-muted: {colors.text_muted|#888888};
      --color-accent: {colors.accent|#0066cc};
      --color-link: {colors.link|#0066cc};
      --color-link-visited: {colors.link_visited|#004499};
      --color-border: {colors.border|#cccccc};
      --color-toc-bg: {colors.toc_background|#f8f8f8};
      --color-blockquote-border: {colors.blockquote_border|#cccccc};
      --color-source-ref: {colors.source_ref|#888888};
      --font-headers: {fonts.headers|Georgia, serif};
      --font-body: {fonts.body|Georgia, serif};
      --font-mono: {fonts.mono|monospace};
      --radius: {radius|4px};
    }
    body {
      font-family: var(--font-body);
      max-width: 800px;
      margin: 0 auto;
      padding: 2rem;
      line-height: 1.6;
      color: var(--color-text);
      background: var(--color-bg);
    }
    h1 {
      font-family: var(--font-headers);
      border-bottom: 2px solid var(--color-text);
      padding-bottom: 0.5rem;
    }
    h2 {
      font-family: var(--font-headers);
      color: var(--color-text);
      margin-top: 2rem;
    }
    h3 {
      font-family: var(--font-headers);
    }
    a {
      color: var(--color-link);
      text-decoration: underline;
    }
    a:visited {
      color: var(--color-link-visited);
    }
    blockquote {
      border-left: 3px solid var(--color-blockquote-border);
      padding-left: 1rem;
      color: var(--color-text-muted);
    }
    .source-ref {
      font-size: 0.85em;
      color: var(--color-source-ref);
    }
    .source-ref a {
      color: var(--color-link);
      text-decoration: underline;
    }
    .toc {
      background: var(--color-toc-bg);
      padding: 1rem;
      border-radius: var(--radius);
      margin: 1rem 0;
    }
    .toc ul {
      list-style: none;
      padding-left: 1rem;
    }
    .toc a {
      color: var(--color-link);
      text-decoration: underline;
    }
    .meta {
      color: var(--color-text-muted);
      font-size: 0.9em;
      margin-bottom: 2rem;
    }
    code {
      font-family: var(--font-mono);
      background: var(--color-surface);
      padding: 0.15em 0.3em;
      border-radius: 3px;
      font-size: 0.9em;
    }
    table {
      border-collapse: collapse;
      width: 100%;
      margin: 1rem 0;
    }
    th, td {
      border: 1px solid var(--color-border);
      padding: 0.5rem 0.75rem;
      text-align: left;
    }
    th {
      background: var(--color-surface);
      font-family: var(--font-headers);
    }

    @media print {
      body { max-width: 100%; padding: 1rem; font-size: 11pt; }
      .toc { page-break-after: always; }
      h2 { page-break-before: always; }
      a { color: var(--color-link); text-decoration: underline; }
      a[href]::after { content: " (" attr(href) ")"; font-size: 0.8em; color: var(--color-text-muted); }
      .source-ref { font-size: 0.75em; }
    }
  </style>
</head>
<body>
  {content}
</body>
</html>
```

The `{google_fonts_import}` placeholder is either a `<style>@import url(...);</style>` tag from the design-variables `google_fonts_import` field, or empty if no theme is selected or the theme uses system fonts.

Each `{token|fallback}` notation means: use the design variable value if present, otherwise use the hardcoded fallback. Values are baked in at generation time — this is not a runtime mechanism.

## Design Variables Integration

When `<project-dir>/output/design-variables.json` exists, load it and inject tokens into the HTML template:

1. Read the JSON file
2. Extract `colors`, `fonts`, `google_fonts_import`, `radius`
3. Compute report-specific derived tokens if not already present:
   - `link` = `accent` (darken if contrast ratio < 4.5:1 against `background`)
   - `link_visited` = darken `link` by 15%
   - `toc_background` = `surface`
   - `blockquote_border` = `border`
   - `source_ref` = `text_muted`
4. Substitute values into the HTML template's `:root` custom properties
5. If `google_fonts_import` is non-empty, wrap in `<style>` tag and place in `<head>`

When no `design-variables.json` exists, use the fallback values directly (identical to the previous hardcoded template).

## Markdown to HTML Conversion

Use Python stdlib `html` module for escaping, plus simple regex-based markdown conversion:
- `# heading` → `<h1>heading</h1>`
- `**bold**` → `<strong>bold</strong>`
- `[text](url)` → `<a href="url">text</a>` — preserves clickable links
- `- item` → `<li>item</li>`
- Blank line → `<p>` paragraph break

For richer conversion, check if `markdown` package is available:
```python
try:
    import markdown
    html = markdown.markdown(md_text, extensions=['toc', 'tables'])
except ImportError:
    html = simple_md_to_html(md_text)
```

## PDF Generation

If `weasyprint` is available:
```python
from weasyprint import HTML
HTML(filename='output/report.html').write_pdf('output/report.pdf')
```

Weasyprint preserves `<a href>` elements as clickable PDF hyperlinks automatically.

Fallback: inform user to open HTML in browser and use "Print to PDF".

## Table of Contents Generation

The HTML template includes a `.toc` CSS class. Generate the ToC from heading tags:

```python
import re

def generate_toc(html_content: str) -> str:
    """Scan for <h2> tags and build a linked table of contents."""
    headings = re.findall(r'<h2[^>]*>(.*?)</h2>', html_content)
    if not headings:
        return ""

    toc_items = []
    for i, heading in enumerate(headings):
        anchor = f"section-{i}"
        toc_items.append(f'<li><a href="#{anchor}">{heading}</a></li>')

    toc_html = f'<div class="toc"><h3>Contents</h3><ul>{"".join(toc_items)}</ul></div>'

    # Inject anchors into headings
    counter = 0
    def add_anchor(match):
        nonlocal counter
        result = f'<h2 id="section-{counter}">{match.group(1)}</h2>'
        counter += 1
        return result

    html_content = re.sub(r'<h2[^>]*>(.*?)</h2>', add_anchor, html_content)
    return toc_html, html_content
```

Insert the ToC after the `.meta` div and before the first `<h2>`.

## DOCX Generation

If `pandoc` is available, convert markdown to Word format:

```bash
pandoc output/report.md -o output/report.docx \
  --from markdown \
  --to docx \
  --highlight-style=tango
```

Pandoc preserves `[text](url)` markdown links as clickable Word hyperlinks.

Optional: use a reference docx for custom styling:
```bash
pandoc output/report.md -o output/report.docx \
  --from markdown \
  --to docx \
  --reference-doc=template.docx
```

### Themed DOCX

When `design-variables.json` exists and `document-skills:docx` is available, pass theme tokens as parameters:
- `heading_font`: fonts.headers
- `body_font`: fonts.body
- `accent_color`: colors.accent (used for heading color)
- `link_color`: colors.link (used for hyperlink color)

For pandoc fallback, generate a minimal `reference.docx` with:
- Custom heading styles using the theme's header font and accent color
- Body text using the theme's body font
- Hyperlink character style preserving the link color

If neither `document-skills:docx` nor reference doc generation is available, plain pandoc output without theming is acceptable — the user still gets a working Word document with clickable links.

Check availability:
```bash
which pandoc && echo "pandoc available" || echo "pandoc not found"
```

Fallback: inform user to install pandoc (`brew install pandoc` on macOS, `apt install pandoc` on Linux).

## Conversion Fallback Chain

Use this decision logic to select the best available converter:

```
1. weasyprint available?
   → Yes: HTML → PDF via weasyprint (best quality, supports print CSS, preserves hyperlinks)
   → No: continue

2. pandoc available?
   → Yes: MD → DOCX via pandoc (for Word format, preserves clickable links)
   → Also: MD → HTML via pandoc (alternative to markdown package)
   → No: continue

3. markdown package available?
   → Yes: MD → HTML via markdown(extensions=['toc', 'tables']) → serve as HTML
   → No: continue

4. Fallback: MD → HTML via simple regex converter (built-in)
   → Serve as HTML file
   → Inform user: "Open in browser and use Print to PDF for PDF output"
```

Check availability at runtime:
```python
import shutil

def get_converters():
    available = []
    try:
        import weasyprint
        available.append("weasyprint")
    except ImportError:
        pass
    if shutil.which("pandoc"):
        available.append("pandoc")
    try:
        import markdown
        available.append("markdown")
    except ImportError:
        pass
    if not available:
        available.append("simple")
    return available
```
