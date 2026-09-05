# Shared Phase 4b Steps

These steps are common to all arc-specific workflow files. Each workflow file contains the arc-unique content (entity loading, extended thinking sub-steps, arc-specific headers) and references this file for the shared mechanical steps.

---

## Step: Count Entity Files for Stats Grid

Count entity files to populate `stats_*` frontmatter fields and the inline HTML stats grid. Use Glob to count files in each entity `data/` directory:

- `stats_syntheses` from `12-synthesis/data/*.md`
- `stats_megatrends` from `06-megatrends/data/*.md`
- `stats_trends` from `11-trends/data/*.md`
- `stats_concepts` from `05-domain-concepts/data/*.md`
- `stats_findings` from `04-findings/data/*.md`
- `stats_claims` from `10-claims/data/*.md`

All 6 counts must be integers (0 is valid for missing/empty directories). These exact values must appear in both the YAML frontmatter AND the HTML stats grid -- any mismatch fails validation.

**Language-aware labels:** Check `project_language` from sprint-log.json. Use German labels (Dimensionen, Konzepte, Erkenntnisse, Aussagen) for `de`, English labels (Dimensions, Concepts, Findings, Claims) for `en`.

---

## Step: Output Template

The output document follows this exact structure. The 4 `##` headers are arc-specific (see your workflow file for the correct headers). Downstream visualization tools (story-to-slides, story-to-web in web or storyboard mode) parse these 4 elements to create matching visual segments, so the structure cannot be modified.

```markdown
---
title: "{Arc-Specific Compelling Title}"
subtitle: "{Research Question}"
arc_id: "{arc-id}"
arc_display_name: "{Arc Display Name}"
target_length: {target-length or 1675}
word_count: {actual word count}
date_created: "{ISO 8601}"
stats_syntheses: {count}
stats_megatrends: {count}
stats_trends: {count}
stats_concepts: {count}
stats_findings: {count}
stats_claims: {count}
---

# {Arc-Specific Title}

*{Research Question subtitle}*

{Opening paragraph with narrative hook -- hook proportion of target}

<div class="stats-grid" style="display:grid; grid-template-columns:repeat(3,1fr); gap:8px; margin:20px 0;">
  <div style="background:#f5f5f5; padding:14px 10px; border-radius:8px; text-align:center;">
    <div style="font-size:1.6em; font-weight:bold; color:#1a1a1a;">{stats_syntheses}</div>
    <div style="font-size:0.82em; color:#666;">{DE: Dimensionen | EN: Dimensions}</div>
  </div>
  <div style="background:#f5f5f5; padding:14px 10px; border-radius:8px; text-align:center;">
    <div style="font-size:1.6em; font-weight:bold; color:#1a1a1a;">{stats_megatrends}</div>
    <div style="font-size:0.82em; color:#666;">Megatrends</div>
  </div>
  <div style="background:#f5f5f5; padding:14px 10px; border-radius:8px; text-align:center;">
    <div style="font-size:1.6em; font-weight:bold; color:#1a1a1a;">{stats_trends}</div>
    <div style="font-size:0.82em; color:#666;">Trends</div>
  </div>
  <div style="background:#f5f5f5; padding:14px 10px; border-radius:8px; text-align:center;">
    <div style="font-size:1.6em; font-weight:bold; color:#1a1a1a;">{stats_concepts}</div>
    <div style="font-size:0.82em; color:#666;">{DE: Konzepte | EN: Concepts}</div>
  </div>
  <div style="background:#f5f5f5; padding:14px 10px; border-radius:8px; text-align:center;">
    <div style="font-size:1.6em; font-weight:bold; color:#1a1a1a;">{stats_findings}</div>
    <div style="font-size:0.82em; color:#666;">{DE: Erkenntnisse | EN: Findings}</div>
  </div>
  <div style="background:#f5f5f5; padding:14px 10px; border-radius:8px; text-align:center;">
    <div style="font-size:1.6em; font-weight:bold; color:#1a1a1a;">{stats_claims}</div>
    <div style="font-size:0.82em; color:#666;">{DE: Aussagen | EN: Claims}</div>
  </div>
</div>

---

## {Element 1 Header}

{element 1 proportion of target words with evidence grounding}

## {Element 2 Header}

{element 2 proportion of target words with evidence grounding}

## {Element 3 Header}

{element 3 proportion of target words with evidence grounding}

## {Element 4 Header}

{element 4 proportion of target words with evidence grounding}
```

**Trend-panorama note:** Add `total_trends` and `horizon_distribution` (act/plan/observe counts) to the frontmatter.

---

## Step: Validate Output

The universal gates live in one place: `../validation.md`. Run its deterministic gates with `scripts/validate-narrative.py`, then check its judged gates and the arc's own quality gates. Do not restate gates here.

Two gate families this layer used to carry — an entity-wikilink count and the `stats_*` / stats-grid presentation gates — are not in `validation.md` and are not gates any more; they bound the narrative to the retired numbered research-project layout. The stats grid in the template above is legacy output-template content for this layer only.

---

## Step: Write Output

Write to `insight-summary.md` at project root -- the directory that contains the numbered entity directories (04-findings/, 12-synthesis/, etc.). Not inside any subdirectory.

Before writing, verify:
1. File content starts with `---` (YAML frontmatter)
2. `arc_id` in frontmatter matches the selected arc
3. `word_count` in frontmatter matches the actual body word count

After writing, verify the file exists and check word count:

```bash
if [[ ! -f "insight-summary.md" ]]; then
  echo "ERROR: insight-summary.md not created"
  exit 1
fi
word_count=$(wc -w < insight-summary.md | tr -d ' ')
echo "insight-summary.md created (${word_count} words) at project root"
```
