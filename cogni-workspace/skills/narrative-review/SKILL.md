---
name: narrative-review
description: "Review existing narrative files against story arc quality gates, returning a pass/warn/fail verdict per gate. This skill should be used when the user asks to \"review a narrative\", \"score a narrative\", \"check narrative quality\", \"validate narrative\", \"audit narrative\", \"grade a narrative\", \"evaluate narrative quality\", \"narrative scorecard\", \"rate my narrative\", \"run quality gates on a narrative\", or when the narrative-reviewer agent evaluates a generated narrative."
allowed-tools: Read, Write, Edit, Glob, Grep
---

# Narrative Review

## Purpose

Evaluate an existing narrative markdown file against the `narrative` skill quality gates. Produce a structured review report with a `pass`/`warn`/`fail` verdict per gate, the criterion-level verdicts behind each one, and the top 3 actionable improvement suggestions.

## When to Use

- Review a narrative after generation to assess quality
- Audit an existing insight summary for arc compliance
- Compare narrative quality before and after edits
- Track per-gate verdicts for quality tracking across projects

**Not for:**
- Generating new narratives (use `cogni-workspace:narrative` skill instead)
- Editing or rewriting narratives (use copywriter skill instead)
- Adapting narratives to other formats (use the `cogni-workspace:narrative` skill with `--format` instead)

---

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--source-path` | Yes | Path to the narrative `.md` file to review |
| `--arc-id` | No | Override arc detection (uses frontmatter `arc_id` by default) |
| `--language` | No | Override language detection (uses frontmatter `language` by default) |

---

## Output

Two outputs:

1. **Markdown scorecard** written to `{source-dir}/narrative-review.md`
2. **JSON summary** returned on completion

### JSON Summary

```json
{
  "success": true,
  "source_path": "insight-summary.md",
  "arc_id": "corporate-visions",
  "gates": {
    "structural": "pass",
    "critical": "pass",
    "evidence": "warn",
    "structure": "pass",
    "language": "pass"
  },
  "top_improvements": [
    "Add 3 more citations to reach minimum 15 (currently 12)",
    "Expand 'Why Now' section by ~40 words to meet its 21% element allocation (~299 words at default T=1675)",
    "Add citation to uncited quantitative claim in paragraph 3 of 'Why Change'"
  ]
}
```

### Verdict Vocabulary

Every criterion resolves to one of three verdicts, and every gate derives its status from
the criteria it contains. There is no composite figure and no letter grade -- the workflow
computes neither, so it reports neither.

| Level | Verdict | Meaning |
|-------|---------|---------|
| Criterion | `met` | The criterion's target condition holds |
| Criterion | `partial` | An intermediate band defined by the rubric holds |
| Criterion | `unmet` | The criterion's failing band holds |

Gate status is derived from those criterion verdicts by the rule in
[references/scoring-rubric.md](references/scoring-rubric.md) §Evaluation Principles.

---

## Execution Protocol

### Step 1: Load Narrative

1. Read the narrative file from `--source-path`
2. Extract YAML frontmatter fields: `title`, `subtitle`, `arc_id`, `arc_display_name`, `target_length`, `word_count`, `language`, `date_created`, `source_file_count`
3. If frontmatter is missing or incomplete, flag as critical issue
4. Determine `arc_id` from: explicit parameter > frontmatter > detection failure
5. Determine `language` from: explicit parameter > frontmatter > default `en`

### Step 2: Load Arc Standards

Read the arc definition to know expected element names, word targets, and quality gates:

1. **Read:** `../narrative/references/story-arc/arc-registry.md` -- for arc metadata
2. **Read:** `../narrative/references/story-arc/{arc_id}/arc-definition.md` -- for element definitions and word targets
3. **Read:** `../narrative/references/language-templates.md` -- for localized header names

Store the expected element names, proportions, and citation requirements. Read `target_length` from the narrative's frontmatter to compute expected word ranges. If `target_length` is absent (legacy narratives), default to 1675. Compute `total_lower = target_length * 0.85`, `total_upper = target_length * 1.15`, then per-element ranges: `[proportion * total_lower, proportion * total_upper]`.

### Step 3: Run Quality Gates

Evaluate the narrative against each gate category. Use the scoring rubric in [references/scoring-rubric.md](references/scoring-rubric.md).

**Gate evaluation order (matches narrative skill Phase 5):**

1. **Structural Gate**
2. **Critical Gate**
3. **Evidence Gate**
4. **Structure Gate**
5. **Language Gate**

For each gate:
- Assign each criterion `met` / `partial` / `unmet` per the rubric
- Derive gate status from those criterion verdicts using the rubric's gate-status rule
- Record the gate status: `pass` / `warn` / `fail`

### Step 4: Generate Scorecard

Write `narrative-review.md` to the same directory as the source file:

```markdown
---
type: narrative-review
source: "{source filename}"
arc_id: "{arc_id}"
date_reviewed: "{ISO 8601}"
---

# Narrative Review: {source filename}

**Arc:** {arc_display_name} | **Language:** {language}

---

## Gate Results

| Gate | Status | Criteria | Details |
|------|--------|----------|---------|
| Structural | {pass/warn/fail} | {n met, n partial, n unmet} | {summary} |
| Critical | {pass/warn/fail} | {n met, n partial, n unmet} | {summary} |
| Evidence | {pass/warn/fail} | {n met, n partial, n unmet} | {summary} |
| Structure | {pass/warn/fail} | {n met, n partial, n unmet} | {summary} |
| Language | {pass/warn/fail} | {n met, n partial, n unmet} | {summary} |

---

## Top 3 Improvements

1. {Most impactful improvement with specific action}
2. {Second improvement with specific action}
3. {Third improvement with specific action}

---

## Detailed Analysis

### Structural Gate ({pass/warn/fail})

{Detailed findings for each structural criterion}

### Critical Gate ({pass/warn/fail})

{Detailed findings for each critical criterion}

### Evidence Gate ({pass/warn/fail})

{Detailed findings for each evidence criterion}

### Structure Gate ({pass/warn/fail})

{Detailed findings for each structure criterion}

### Language Gate ({pass/warn/fail})

{Detailed findings for each language criterion}
```

### Step 5: Return JSON Summary

Return the JSON summary (see Output section above).

---

## Gate Evaluation Details

For the per-criterion verdict bands per gate -- including counting methods and edge cases -- load [references/scoring-rubric.md](references/scoring-rubric.md).

**Gate summary:** each of Structural, Critical, Evidence, Structure and Language returns `pass`, `warn` or `fail`, derived from its own criterion verdicts by the one rule the rubric states.

---

## Constraints

- DO NOT modify the narrative file -- this is a read-only review
- DO NOT fabricate or assume quality issues -- only report what is measurably found
- DO NOT emit a composite score, a letter grade or a per-gate point total -- the workflow computes none of them
- ALWAYS compute expected word ranges from arc proportions x target length for the word-count criteria
- ALWAYS check against the language-specific header names

---

## Bundled Resources

| File | Purpose | Load When |
|------|---------|-----------|
| `references/scoring-rubric.md` | Criterion verdict bands and edge cases | Step 3 |

**Cross-skill dependencies** (files owned by the `narrative` skill):

| File | Purpose | Load When |
|------|---------|-----------|
| `../narrative/references/story-arc/arc-registry.md` | Arc metadata and detection algorithm | Step 2 |
| `../narrative/references/story-arc/{arc_id}/arc-definition.md` | Element names and word targets | Step 2 |
| `../narrative/references/language-templates.md` | Localized header names per arc | Step 2 |
