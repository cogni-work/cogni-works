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

| Heading Pattern | Tag |
|----------------|-----|
| H2 "Introduction" (within first 3 sections) | `introduction` |
| H2 between Introduction and Conclusion | `body-section` |
| H2 "Conclusion" or "Recommendations" | `conclusion` |
| H2 "References" or "Bibliography" (last section) | `references` |

If `.metadata/diagram-plan.json` exists, map its `target_section` fields to section IDs.

## Generic Section Tags

All sections tagged as `section` with their heading depth. No special semantic mapping.
