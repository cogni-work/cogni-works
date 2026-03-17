# Citation Formats Reference

## Supported Formats

The `citation_format` field in project config controls how inline citations and the reference list are formatted. The writer agent applies the format via its prompt — no code-level formatting logic.

### APA (default)

**Inline**: `([Author, Year](url))` at the end of the sentence or paragraph.
**Reference list**:
```
Author, A. A. (Year, Month Day). Title of article. *Publisher Name*. url
```
**Example**:
- Inline: `Cloud adoption grew 25% in 2025 ([Gartner, 2025](https://gartner.com/report))`
- Reference: `Gartner. (2025, March 10). Cloud Infrastructure Report 2025. *Gartner Research*. https://gartner.com/report`

### MLA

**Inline**: `([Author](url))` with page numbers where applicable.
**Reference list** (Works Cited):
```
Author Last, First. "Title of Article." *Publisher*, Day Month Year, url.
```

### Chicago (CMS)

**Inline**: Footnote-style superscript numbers: `text<sup>[1](url)</sup>`
**Reference list** (Bibliography):
```
Author Last, First. "Title." *Publisher*, Month Day, Year. url.
```

### Harvard

**Inline**: `([Author Year](url))` — similar to APA but without comma.
**Reference list**:
```
Author, A.A. Year. Title of article. *Publisher*. Available at: url [Accessed Day Month Year].
```

### IEEE

**Inline**: Numbered brackets: `[[1](url)]`
**Reference list** (numbered):
```
[1] A. Author, "Title," *Publisher*, Month Year. [Online]. Available: url
```

### Wikilink

**Inline**: Superscript number linking to an anchored reference entry: `<sup>[[N]](#ref-N)</sup>`
**Reference list** (numbered, anchored):
```
<a id="ref-1"></a>[1] A. Author, "Title," *Publisher*, Month Year. https://example.com/article
```

Number sources sequentially by order of first appearance in the report. Each reference entry starts with an `<a id="ref-N"></a>` HTML anchor so the inline superscript links directly to it. Every reference entry must end with the full clickable URL.

**Full paragraph example**:

> Cloud adoption grew 25% year-over-year in 2025<sup>[[1]](#ref-1)</sup>, driven primarily by AI workload
> migration. Gartner projects that by 2028, over 70% of enterprise AI workloads will run on
> hyperscaler infrastructure<sup>[[2]](#ref-2)</sup>. However, cost optimization remains a challenge —
> a recent Flexera survey found that 32% of cloud spend is wasted<sup>[[3]](#ref-3)</sup>, suggesting
> that governance has not kept pace with adoption.
>
> ## References
>
> <a id="ref-1"></a>[1] Gartner, "Cloud Infrastructure Report 2025," *Gartner Research*, March 2025. https://gartner.com/cloud-report-2025
>
> <a id="ref-2"></a>[2] Gartner, "Top Strategic Technology Trends 2028," *Gartner*, October 2025. https://gartner.com/strategic-trends-2028
>
> <a id="ref-3"></a>[3] Flexera, "2025 State of the Cloud Report," *Flexera*, February 2025. https://flexera.com/state-of-cloud-2025

## Default

When no `citation_format` is specified: **APA**.

## Writer Instructions

The writer agent should:
1. Read `citation_format` from `project-config.json` (default: "apa")
2. Apply the matching inline citation style throughout the report
3. Generate the reference list at the end in the matching format
4. Always include the URL as a clickable markdown hyperlink in citations
5. Maintain consistent formatting across all sections
