# Section Analysis

Rules for parsing report markdown into a section tree with metadata, and extracting data structures for visualization planning.

## Generic Section Parsing

1. Split on heading lines (`# `, `## `, `### `, `#### `).
2. Each heading starts a new section. Content between headings belongs to the section above.
3. Build a tree: H1 is root, H2 are children of H1, H3 are children of preceding H2, etc.

## Numeric Claim Extraction

Scan each section's text for quantitative data:

**Patterns to match:**
```
Currency:     €?\$?\d[\d,.]+\s*(billion|million|Mrd|Mio|B|M|k|K|trillion|T)
Percentage:   \d[\d,.]*\s*%
Year-range:   20\d{2}[-–]20\d{2}
Large number: \d{1,3}([.,]\d{3})+
Change:       [+-]\d[\d,.]*\s*%
Multiplier:   \d+[xX]
Ratio:        \d+:\d+
```

For each match, extract:
- `value` — the number as-is (preserve formatting)
- `context` — surrounding 10 words (before and after)
- `source_url` — nearest `[text](url)` link within 100 characters

## Table Detection

A markdown table is a block of lines containing `|` with a separator row (`|---|---|`).

Extract:
- `headers` — first row cell texts
- `rows` — subsequent row cell texts
- `is_numeric` — true if >50% of non-header cells contain numbers
- `row_count` — number of data rows

## T→I→P→S Chain Detection (trend-report specific)

Value chains follow this pattern:
```markdown
#### [Chain Name]

**Trend:** [trend description with citations]

**Implication:**
- **[Name 1]** — [description]
- **[Name 2]** — [description]

**Possibility:**
- **[Name 1]** — [description]

**Foundation Requirements:** [description]
```

Extract:
- `chain_name` — H4 heading text
- `trend` — text after `**Trend:**`
- `implications` — list of name + description pairs
- `possibilities` — list of name + description pairs
- `solutions` or `foundations` — text after `**Foundation Requirements:**` or `**Solution:**`

## Trend-Report Section Tags

Map headings to semantic tags for enrichment planning:

| Heading Pattern | Tag |
|----------------|-----|
| First H2 (or contains "Executive Summary" / "Zusammenfassung") | `executive-summary` |
| Subsection with "Headline Evidence" or bullet list of 3+ numbers after exec summary | `headline-evidence` |
| Table immediately after exec summary intro with theme names | `strategic-themes-table` |
| Paragraph with "strategic posture" or "horizon" language | `strategic-posture` |
| Numbered H2 (e.g., "## 1. Theme Name") | `theme-N` |
| H3/H4 with "Investment Thesis" or containing "Why Change" | `investment-thesis` |
| H4 containing value chain content (T→I→P→S pattern) | `value-chain` |
| H3 "Solution Templates" | `solution-templates` |
| H3 with "Strategic Actions" or "Why Pay" | `strategic-actions` |
| Single paragraph between two theme sections (H2→H2) | `bridge` |
| H2 containing "Synthesis" or "Closing" or last H2 before appendix | `synthesis` |
| H2 containing "Emerging Signals" | `emerging-signals` |
| Table with horizon data (ACT/PLAN/OBSERVE columns) | `horizon-distribution` |
| Table with MECE or "Mutual Exclusivity" | `mece-validation` |
| Table with "Evidence" and "%" columns | `evidence-coverage` |
| H2 "Claims Registry" or table with Claim # and Source columns | `claims-registry` |

## Research-Report Section Tags

Research reports vary widely in topic and heading conventions. Section intelligence uses a two-layer system: a small set of universal heading-based tags for structurally stable sections, plus content-pattern tags detected by analyzing the section body text. Content-pattern tags are the primary driver for enrichment decisions — they work regardless of domain or heading language.

### Layer A — Universal Heading Tags

| Heading Pattern | Tag |
|----------------|-----|
| First H2, or H2 containing "Executive Summary" / "Zusammenfassung" / "Key Findings" / "Abstract" | `executive-summary` |
| H2 "Introduction" or "Einleitung" (within first 3 sections) | `introduction` |
| H2 containing "Methodology" / "Methods" / "Approach" / "Methodik" | `methodology` |
| H2 "Conclusion" / "Fazit" / "Schlussfolgerung" | `conclusion` |
| H2 containing "Recommendations" / "Empfehlungen" (when standalone, not combined "Conclusion and Recommendations" — if combined, tag as `conclusion`) | `recommendations` |
| H2 "References" / "Bibliography" / "Literaturverzeichnis" / "Quellen" (last section) | `references` |
| All other H2 sections | `body-section` |

### Layer B — Content-Pattern Tags

Applied to ANY section (including those already tagged in Layer A) by analyzing the section body text. A section can accumulate multiple content-pattern tags — e.g., `body-section` + `has-data-table` + `has-comparison`.

| Content Pattern | Tag | Detection Rules |
|----------------|-----|-----------------|
| Markdown table with 3+ data rows containing numeric values | `has-data-table` | Lines matching `\|.*\|` with separator row `\|---`; >50% of non-header cells contain numbers (currency, percentages, integers) |
| 5+ numeric claims within 500 words | `stat-dense` | Cluster of currency amounts, percentages, multipliers, large numbers (see Numeric Claim Extraction patterns above) within a 500-word window |
| Sequential steps or causal chains | `has-process` | Ordered list (`1.`, `2.`, `3.`+) describing stages; OR causal connectors ("leads to", "results in", "enables", "triggers", "followed by", "step N", "phase N"); OR numbered sub-headings (H3/H4) describing sequential stages |
| 3+ date/year references in temporal order | `has-timeline` | Three or more matches of year/quarter/month patterns (`20\d{2}`, `Q[1-4] 20\d{2}`, `by 20\d{2}`, month-year) appearing in chronological sequence within the section |
| Comparison of 2+ named entities across shared dimensions | `has-comparison` | Table with entity names as row labels and evaluation criteria as columns; OR prose with comparison language ("vs", "compared to", "while X has... Y has...", "outperforms", "in contrast") referencing 2+ named entities |
| Proportional data summing to ~100% | `has-distribution` | Percentage values in table cells or inline text that sum to 95-105%; OR explicit share/proportion language ("accounts for N%", "represents N% of") |
| Synthesis across 3+ other report sections | `has-synthesis` | Section references 3+ other topics from the report by name or keyword (not necessarily exact heading text — inline mentions like "Requirements", "Design", "Testing" count if they refer to report sections); OR aggregating language ("across all phases", "across all sections", "common pattern", "recurring theme", "cutting across", "interconnected"); OR section has a structured breakdown mapping items to multiple other report topics (e.g., "Impact Across Phases: Requirements — ..., Design — ..., Coding — ...") |
| Clear thesis + supporting evidence (>800 words) | `has-thesis` | Section word count >800; AND first 2 sentences contain an assertion (verb + quantitative claim or strong evaluative statement) |

### Content Structure Detection (Research-Report)

When a content-pattern tag is detected, extract structured data for visualization planning:

**Comparison structures** (`has-comparison`):
1. If table: extract entity names (row labels), dimension names (column headers), cell values
2. If prose: extract entity names from comparison language, dimension names from shared attributes being compared
3. Output: `entities[]`, `dimensions[]`, `values[][]` (matrix)

**Process/workflow structures** (`has-process`):
1. Extract step labels from ordered list items, numbered sub-headings, or noun phrases after causal connectors
2. Extract connections: sequential (A → B → C) or branching (A → B, A → C)
3. Cap at 8 steps (merge or simplify if more)
4. Output: `steps[]`, `connections[{from, to, label?}]`

**Statistical clusters** (`stat-dense`):
1. Group numeric claims by topic similarity (shared keywords within 50 words)
2. Normalize to common unit where possible (e.g., all percentages, all currency amounts)
3. Output: `clusters[{topic, claims[{value, label, source_url?}]}]`

**Chronological structures** (`has-timeline`):
1. Extract date-event pairs: date (normalized to YYYY or YYYY-QN), label (event/milestone, max 10 words), category (regulatory/market/technical/organizational — inferred from context)
2. Sort chronologically
3. Output: `events[{date, label, category}]`, `span{earliest, latest}`

If `.metadata/diagram-plan.json` exists, map its `target_section` fields to section IDs.

## Generic Section Tags

All sections tagged as `section` with their heading depth. No special semantic mapping.
