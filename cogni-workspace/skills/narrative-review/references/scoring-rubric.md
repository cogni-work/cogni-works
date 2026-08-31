# Scoring Rubric

Detailed evaluation rules and edge cases for narrative review quality gates.

## Evaluation Principles

1. **Binary where possible** -- Most criteria resolve to `met` or `unmet`, with no middle band
2. **Partial** -- Some criteria define an intermediate band; those resolve to `partial` (documented below)
3. **Gate status** -- Derived from the verdicts of that gate's criteria:
   - `pass`: every criterion is `met`
   - `warn`: no criterion is `unmet`, and at least one is `partial`
   - `fail`: any criterion is `unmet`

The same rule applies identically to all five gates. There is no composite figure and no
letter grade: the workflow computes neither, so it reports neither.

---

## Structural Gate

### Exactly 4 `##` headers

- **met:** Exactly 4 `##` lines in narrative body
- **partial:** 3 or 5 `##` lines (close but wrong)
- **unmet:** Fewer than 3 or more than 5

**How to count:** Only count lines starting with `## ` (hash-hash-space) below the YAML frontmatter closing `---`. Do not count `#` (h1) or `###` (h3) lines.

### Headers match arc element names

- **met:** All 4 headers match expected names exactly
- **partial:** 2 or 3 of 4 match
- **unmet:** Fewer than 2 match

**Matching rules:**
- Compare against `language-templates.md` for the detected `arc_id` and `language`
- Match is case-sensitive
- Trailing/leading whitespace is trimmed before comparison
- Subtitles after `:` are part of the expected name (e.g., "Why Change: Unconsidered Needs")

### Headers in correct sequence

- **met:** All headers in correct arc order
- **unmet:** Any header out of order

Only evaluated if at least 3 headers match expected names.

### No extra `##` headers

- **met:** No extra `##` headers beyond the 4 arc elements
- **partial:** 1 extra `##` header
- **unmet:** 2+ extra `##` headers

---

## Critical Gate

### Total word count

Compute the expected range from the narrative's `target_length` frontmatter field (default 1675 if absent): `total_lower = target_length * 0.85`, `total_upper = target_length * 1.15`.

- **met:** Within target range (`total_lower` to `total_upper`)
- **partial:** Beyond the target range but within 25% of its bounds (i.e., `total_lower * 0.75` to `total_upper * 1.25`)
- **unmet:** Beyond 25% of target bounds

**Word count method:** Count all words in the markdown body below frontmatter. Exclude YAML frontmatter, citation markup (`<sup>`, `</sup>`), and markdown formatting characters.

### Arc-specific title

- **met:** Title is specific, compelling, and reflects the arc's rhetorical frame
- **partial:** Title exists but is generic or does not reflect the arc
- **unmet:** Title missing or is literally "Insight Summary"

**Generic title indicators:** "Summary", "Report", "Analysis", "Overview", "Insight Summary", "Research Results" used alone without arc-specific framing.

### Hook present

Compute expected hook range from the arc's hook proportion x target range.

- **met:** Hook paragraph exists within the computed hook range between `#` title and first `##`
- **partial:** Hook exists but outside computed range by up to 25%
- **unmet:** No hook paragraph or word count below 50% of expected hook range

### Frontmatter complete

Required fields: `title`, `arc_id`, `word_count`, `language`, `date_created`

- **met:** All required fields present
- **partial:** 3-4 fields present
- **unmet:** Fewer than 3 fields present

---

## Evidence Gate

### Minimum 15 citations

- **met:** 15+ unique citations
- **partial:** 4-14 citations
- **unmet:** Fewer than 4 citations

**Counting method:** Count unique `<sup>[N]` patterns where N is a citation number. Each unique N counts once regardless of how many times it appears.

### All quantitative claims cited

- **met:** Every number, percentage, or quantitative claim has an adjacent citation
- **partial:** 1-5 uncited quantitative claims
- **unmet:** 6+ uncited quantitative claims

**Quantitative claim detection:** Look for patterns like:
- Percentages: `X%`, `X percent`
- Currency: `$X`, `EUR X`, numbers followed by "million", "billion"
- Specific numbers in context: "X companies", "X-fold increase", "grew by X"
- Ratios and multipliers: "3x", "doubled", "tripled"

**Exclusions:** Page numbers, citation numbers, list ordinals, dates, and version numbers are NOT quantitative claims.

### No broken citation refs

- **met:** All citations use valid `<sup>[N](file.md)</sup>` format
- **partial:** 1-2 citations with format issues
- **unmet:** 3+ citations with format issues

**Format issues:** Missing closing `</sup>`, missing `(file.md)` link, non-sequential numbering, duplicate numbers.

---

## Structure Gate

### Element word counts within targets

Compute each element's expected range: `[proportion * total_lower, proportion * total_upper]` using proportions from the arc definition.

- **met:** All 4 elements within computed proportional range (+/-10% tolerance)
- **partial:** 2 or 3 of 4 elements within range
- **unmet:** Fewer than 2 elements within range

### Transitions between elements

Check for transition text: the last paragraph of each section (except the last) should connect to the next section's theme.

- **met:** Clear transitions between all 3 section boundaries
- **partial:** Transitions at 1 or 2 of 3 boundaries
- **unmet:** No transition text detected

**Transition indicators:** Phrases like "Building on...", "This urgency...", "Against this backdrop...", "With these capabilities...", opening sentences that reference the prior section's conclusion.

---

## Language Gate

### Proper umlauts -- only if `language: de`

- **met:** Zero ASCII fallbacks found
- **partial:** 1-3 ASCII fallbacks
- **unmet:** 4+ ASCII fallbacks

**ASCII fallback patterns to search for:** `ue` (should be `ü`), `ae` (should be `ä`), `oe` (should be `ö`), `ss` where `ß` is correct. Common false positives: compound words where "ue", "ae", "oe" are natural letter combinations at morpheme boundaries (e.g., "aeroplane") -- use German language knowledge to distinguish.

If `language: en`, record `met` automatically.

### Consistent language

- **met:** Body text is consistently in the declared language
- **partial:** Minor language mixing (1-2 foreign sentences)
- **unmet:** Significant language mixing

**Exceptions:** Framework names (TIPS, MECE, SWOT), brand names, and technical terms may remain in English regardless of language setting.

If `language: en`, record `met` automatically (English is the default).
