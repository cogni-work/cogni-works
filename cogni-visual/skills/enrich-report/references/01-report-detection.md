# Report Detection

How to identify the report type from a markdown file. Detection uses three layers in order of confidence.

## Layer 1: YAML Frontmatter (highest confidence)

| Field | Value | Report Type |
|-------|-------|-------------|
| `generated_by` | `trend-report` | `trend-report` |
| `generated_by` | `research-report` | `research-report` |
| `total_themes` | present (any value) | `trend-report` |
| `total_claims` | present + `total_themes` | `trend-report` |
| `report_type` | `basic`/`detailed`/`deep`/`outline`/`resource` | `research-report` |
| `citation_format` | present (apa/mla/chicago/harvard/ieee/wikilink) | `research-report` |

## Layer 2: Structural Heuristics (medium confidence)

Scan the first 200 lines for heading patterns:

**Trend-report indicators (need 2+ to classify):**
- H2 containing "Investment Thesis" or "Investitionsthese"
- H3/H4 containing "Value Chain" or "Wertschöpfungskette"
- H3 containing "Solution Templates" or "Lösungsbausteine"
- H2 containing "Claims Registry" or "Claims-Register"
- H2 containing "Emerging Signals"
- H2 containing "Portfolio Analysis"
- Bold labels: `**Trend:**`, `**Implication:**`, `**Possibility:**`

**Research-report indicators (need 2+ to classify):**
- H2 "Introduction" or "Einleitung" (within first 100 lines)
- H2 "Conclusion" or "Fazit" or "Schlussfolgerung"
- H2 "References" or "Literaturverzeichnis" or "Quellen"
- Citation format matching APA/MLA patterns in body text
- Parent directory contains `.metadata/project-config.json`

## Layer 3: Fallback

If neither pattern matches with sufficient confidence → classify as `generic`.

## Language Detection

1. Frontmatter `language:` field (authoritative)
2. First 500 words: count German-specific characters (ä, ö, ü, ß) and common German words ("und", "der", "die", "das", "ist", "für"). If German signal > 5 → `de`. Otherwise → `en`.

## File Discovery Patterns

When `source_path` is not provided, search from CWD:

```
# Trend-report candidates (highest priority)
**/tips-trend-report.md

# Research-report candidates
**/output/report.md
**/output/draft-v*.md

# Generic candidates (lowest priority)
**/*.md  (exclude SKILL.md, README.md, CLAUDE.md, MEMORY.md, CHANGELOG.md)
```

Sort: trend-report first, then research-report, then by path depth (shallow first). Present max 4 candidates.
