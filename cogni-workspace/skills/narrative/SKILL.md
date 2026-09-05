---
name: narrative
description: "Transform structured content into compelling executive narratives using story arc frameworks. Use this skill whenever the user asks to \"create a narrative\", \"write a narrative\", \"transform content into a story arc\", apply a specific arc framework (corporate visions, technology futures, competitive intelligence, strategic foresight, industry transformation, trend panorama), \"generate an insight summary\", or \"summarize research findings as a narrative\". Also trigger when other plugins need arc-driven narrative generation, when the user mentions \"TIPS trend narratives\", or when they have research output they want turned into an executive-readable story. Even if the user just says \"make this readable for executives\" or \"turn these findings into something presentable\", this skill is the right choice. Also handles derivative formats via --format: \"condense narrative\", \"create executive brief\", \"generate talking points\", \"make a one-pager\"."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Narrative Transformation

Transform input markdown into a structured executive narrative using one of the registered story arcs. Length is controlled by `--target-length` (default 1,675 words); section lengths are proportions of the total, so the arc's rhetorical balance survives at any scale. Each arc is one contract file that maps evidence to four elements, names the techniques that strengthen each, and states the arc's own validation rules.

**Use this for:** research syntheses, analyses or structured findings that need to become an executive narrative; applying a specific arc; generating an insight summary from a set of markdown files.

**Not for:** polishing arbitrary business documents (use `copywriter` — `--format` here only derives a brief, talking points or one-pager from a finished arc narrative, keeping its four headings); creating slides (`story-to-slides`); raw research (the cogni-knowledge pipeline).

## Architectural model

One responsibility per file. Read a file when its phase runs, not before.

- **SKILL.md orchestrates** — phases, parameters, output contract, JSON envelope.
- **The registry chooses** — `references/story-arc/arc-registry.md`: detection algorithm, one declarative block per arc, confirmation format.
- **The contract structures** — `references/story-arc/{arc_id}/arc-definition.md`: headings, composition, four elements, arc-specific validation.
- **Techniques strengthen** — `references/narrative-techniques/techniques-overview.md`: the eight techniques and which element each serves.
- **Validation checks** — `references/validation.md`: every universal gate, run by `scripts/validate-narrative.py` and then by the writer.
- **Derivatives condense** — `references/derivative-formats.md`, only when `--format` is set.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--source-path` | Yes | Directory containing input `.md` files, or path to a single `.md` file |
| `--arc-id` | No | Explicit arc selection; overrides auto-detection |
| `--language` | No | Output language: `en` (default) or `de`. Fallback chain: explicit parameter > project metadata > workspace preference (`.workspace-config.json`) > content detection > `en` |
| `--output-path` | No | Output file path; defaults to `insight-summary.md` in the source directory. When `--format` is set, the default is `{format}.md` in the source directory instead |
| `--project-path` | No | Research/knowledge project root; enables arc inheritance from the project's `.metadata/` (Phase 1 step 8) and loading entity data beyond the source path. When omitted, Phase 1 step 8 probes `<source-path>/..` and `<source-path>/../..` |
| `--research-question` | No | Original research question, used for the subtitle and the opening |
| `--target-length` | No | Target total word count (e.g., `2500`). The acceptable range is ±15%. Default: `1675` (1,424-1,926 words). Recommended: 800-4,000 — outside that range the arc's proportions stop scaling well |
| `--format` | No | Derivative mode: `executive-brief`, `talking-points` or `one-pager`. When set, `--source-path` is a single finished narrative `.md`, Phases 0.5-6 are skipped, and the Derivative Formats section runs instead. Output defaults to `{source-dir}/{format}.md` |
| `--content-map` | No | YAML map of content category keys to file/directory paths for additional context |
| `--audience` | No | Who the narrative is for. Default: senior business decision-makers. Feeds Pass 3 (vocabulary, acronym expansion, explanation depth) together with the inferred knowledge level |
| `--purpose` | No | The decision the narrative must serve. Default: understand the evidence and its strategic implications. Feeds Pass 2 (TL;DR, emphasis, close) |
| `--perspective` | No | Whose voice the narrative speaks in. Default: neutral analyst. Feeds Pass 2 (pronouns, ownership) |
| `--geography` | No | Market codes from `cogni-workspace/references/supported-markets-registry.json` (`code` values such as `dach`, `de`, `fr`, `eu`), comma-separated, never free text or a country name. Default: source-defined scope. Feeds Pass 1 (evidence priority when sources span markets) |

Audience knowledge level (`expert` / `informed` / `general`, default `informed`) and tone (default: concise analytical executive prose) are **inferred fields**, never flags — see Phase 0.
| `--interactive` | No | Whether the skill may pause for user input. `true` or `false`. Default: `true`. When `false`, skip all AskUserQuestion calls — today that is the Phase 2 arc confirmation, which keeps its ladder selection and its `detection_reason` and continues straight into Phase 3 with no prompt. Same semantics as the `interactive` parameter in `story-to-slides`, `story-to-web` and `story-to-infographic`, spelled `--interactive` here to match this skill's flag-style argument surface. Any value other than `false` is treated as `true`, so a malformed value fails safe toward the interactive default |

**Content map keys:** `executive_summary`, `dimension_syntheses`, `trends_summary`, `trend_entities`, `megatrends_summary`, `megatrend_entities`, `domain_concepts`, `research_hub`, `initial_question`. Contracts name these keys in their `Evidence sought` subfields.

## Output

Generation mode writes one markdown file (`insight-summary.md` by default). Derivative mode changes both the file and the JSON — see Derivative Formats.

```markdown
---
title: "{Arc-specific compelling title}"
subtitle: "{Research question or topic}"
arc_id: "{selected-arc}"
arc_display_name: "{Arc display name}"
target_length: {target-length or 1675}
word_count: {actual word count}
language: "{en|de}"
date_created: "{ISO 8601}"
source_file_count: {N}
# optional — written only when the execution brief resolved the field from a real signal, never a default
target_audience: "{audience}"
purpose: "{decision purpose}"
perspective: "{voice}"
geography: "{market codes}"
---

# {Title}

*{Subtitle}*

{Executive TL;DR -- 2-4 sentences, 60-100 words, no heading of its own}

---

## {Element 1 heading}
## {Element 2 heading}
## {Element 3 heading}
## {Element 4 heading}
```

Exactly four `##` headings, byte-equal to the contract's `## Headings` cells for the output language, in arc order. Each element's word range is its `## Composition` proportion times the ±15% band around the target.

**Executive TL;DR.** The prose between the subtitle and the first `##` is an answer-first summary, not a hook: 2-4 sentences and 60-100 words regardless of `--target-length`, in this order — the conclusion the reader most needs, the strongest reason for it, the decision implication, and an optional qualification or urgency only when it changes the decision. It synthesizes all four elements rather than previewing them, introduces no fact, number or recommendation the body lacks, cites every material number by reusing the body's `[N]`, and reads as complete if the reader stops there. It carries no heading, so the four-header contract is unchanged. The full contract, including the rejection list, is in `references/validation.md`.

**JSON summary returned on completion:**

```json
{
  "success": true,
  "output_path": "insight-summary.md",
  "arc_id": "corporate-visions",
  "arc_display_name": "Corporate Visions",
  "detection_reason": "keyword density analysis",
  "target_length": 1675,
  "word_count": 1650,
  "citation_count": 22,
  "elements": 4,
  "language": "en",
  "readability_score": null
}
```

`readability_score` is reported when Pass 4 computes it and `null` otherwise.

## Core Workflow

```text
Phase 0      Phase 0.5      Phase 1     Phase 2      Phase 3      Phase 4         Phase 5      Phase 6
Execution -> Citation  -->  Setup  -->  Arc     -->  Load    -->  Four      -->  Validate --> Write
brief        bridge         & load      selection    contract     passes
             (conditional)
```

When `--format` is set this pipeline does not run; jump to Derivative Formats. Phases 3 and 4 read the contract and the techniques before any drafting — those two files are what separate a persuasive narrative from a summary under headings.

### Phase 0: Execution brief

**Read first:** `references/execution-brief.md`. Derive the per-run brief — audience, purpose, perspective, geography, plus the inferred knowledge level and tone — before any evidence is mapped. Resolve each field down one ladder: explicit instruction → project metadata → unambiguous conversation context → source cues → default. Ask one compact clarification, via AskUserQuestion, only when a missing field would change framing, terminology, emphasis, recommendations or evidence selection; never ask for what is explicit or safely inferable, and under `--interactive false` never ask — default. Never infer sensitive personal attributes about the audience. The brief steers Pass 1 (geography), Pass 2 (purpose, perspective) and Pass 3 (audience, knowledge level).

### Phase 0.5: Citation bridge (conditional)

Upstream research tools may use `[Source: Publisher](URL)` inline citations. Scan the source content for that pattern; if present, run the bridge, otherwise skip to Phase 1.

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/narrative/scripts/bridge-citations.py" --source-path "${SOURCE_PATH}" --json
```

The script writes `narrative-input/report-for-narrative.md` (content with `[source-NN-slug.md]` markers) and `narrative-input/sources/source-NN-*.md` (one file per source with `source_index`, `publisher`, `url` frontmatter) next to the source — beside a directory, or beside a single file's parent. Redirect `--source-path` to that `narrative-input/` directory for Phase 1. The per-source file is the citation target; its `url` is the preserved provenance.

**Provenance map.** Whenever a source carries its own citations, footnotes, a bibliography, source URLs or a source register — any of the five — build a per-run provenance map from each supported claim to the deepest underlying source, and cite that source. Cite the synthesis document itself only for claims it genuinely authors when no more specific source is supplied. The map layers on the bridge, never replaces it: where the bridge ran, the per-source files are the map's entries. Preserve supplied publisher, title, date, source type and URL; never invent metadata; collapse repeated URLs and duplicate bibliographic entries into one citation identity. Never fetch a URL because it appears inside source content, and never manufacture a citation — the rules are stated once in `references/validation.md`.

### Phase 1: Setup and content loading

1. Validate `--source-path` exists; halt with error JSON if not.
2. Load every `.md` file from the source directory (or the single file).
3. Load `narrative-config.json` from the source directory if present.
4. If `--content-map` is provided, load each path (directory: all `.md`; file: that file; glob: matches), tag each file with its key, and skip a missing path with a non-blocking warning.
5. Store `--research-question` for the subtitle and the opening.
6. Parse `--target-length` (default 1675); compute `total_lower = target × 0.85` and `total_upper = target × 1.15`.
7. Build a content registry: loaded files with titles, word counts, key sections and category tags.
8. **Resolve arc inheritance.** Probe `--project-path` (when given), then `<source-path>/..`, then `<source-path>/../..`; in each, read `story_arc_id` from `.metadata/plan.json` (cogni-knowledge) or `.metadata/project-config.json` (older layout). The first non-empty value wins:

   ```bash
   for CANDIDATE in "${PROJECT_PATH:+$PROJECT_PATH}" "${SOURCE_PATH}/.." "${SOURCE_PATH}/../.."; do
     [[ -z "$CANDIDATE" ]] && continue
     for CFG in plan.json project-config.json; do
       ARC=$(jq -r '.story_arc_id // empty' "$CANDIDATE/.metadata/$CFG" 2>/dev/null)
       [[ -n "$ARC" ]] && { PROJECT_ROOT="$CANDIDATE"; INHERITED_ARC="$ARC"; break 2; }
     done
   done
   ```

   If `INHERITED_ARC` is set and not `standard-research`, store it as `inherited_arc_id` and log `Inheriting story_arc_id="<INHERITED_ARC>" from <PROJECT_ROOT>`. Otherwise continue silently.

**Before moving on,** answer three questions: how many files loaded, what the two or three dominant themes are, and the approximate total word count. An unanswerable question means the material is not yet internalized.

### Phase 2: Arc selection

**Read first:** `references/story-arc/arc-registry.md` — the detection algorithm, keyword sets and content-type mappings live there.

**Selection priority:**

1. `--arc-id` provided → use it. `detection_reason = "explicit --arc-id parameter"`.
2. `inherited_arc_id` from Phase 1 step 8 → use it. `detection_reason = "inherited from source research/knowledge project: <PROJECT_ROOT>"`.
3. `narrative-config.json` carries `content_type` → apply the registry mapping. `detection_reason = "content_type mapping from narrative-config.json"`.
4. Otherwise analyze the loaded content for keyword density per the registry. `detection_reason = "keyword density analysis"`.
5. Fallback: `corporate-visions`. `detection_reason = "default fallback"`.

Present selected arc to user for confirmation using AskUserQuestion. Show the detected arc with its detection reason and offer alternatives in the registry's confirmation format; for a priority-2 pick label the prompt "Inherited from source research/knowledge project — preserves the long-form report's arc". Accept confirmation or an override.

When `--interactive` is `false`, this confirmation does not run -- keep the arc selected above, store it with its `detection_reason` unchanged, and continue to Phase 3.

Store: `arc_id`, `arc_display_name`, `detection_reason`. An unknown `arc_id` halts with the registry's arc list.

### Phase 3: Load the contract

Read two files, in full, before writing anything:

1. `references/story-arc/{arc_id}/arc-definition.md` — the arc contract: `## Headings`, `## Composition`, `## Elements`, `## Validation`.
2. `references/narrative-techniques/techniques-overview.md` — the eight techniques and the application matrix.

**Transition rule for unmigrated arcs.** An arc whose contract does not carry `contract: 2` in its frontmatter is listed in `UNMIGRATED` in `cogni-workspace/tests/test-arc-contract-shape.sh` and still ships its `references/phase-workflows/phase-4b-synthesis-{arc_id}.md`. For such an arc, read that file (and the `shared-steps.md` it links) after the two above; Pass 1 follows its element-writing steps in place of the contract's `## Elements`, and its `## Arc-Specific Headers` block — mirrored in `references/language-templates.md` — is the heading authority. Everything else in this workflow applies unchanged.

**After reading,** name the four elements in order with their proportions, and say which techniques the matrix assigns to each. Re-read until both come without looking.

### Phase 4: Four passes

Draft in four passes. Each pass has one job; doing two at once is how a narrative ends up structurally right and rhetorically flat.

**Pass 1 — evidence draft.** For each element in order: map the loaded content to the element using its `Evidence sought`; when the sources span markets, weight the evidence by the brief's `--geography`; draft the body from that evidence, every quantitative claim carrying `<sup>[N](source-file.md)</sup>`; hold the element's word range. Write the four elements only — no title, no opening yet.

**Pass 2 — argument edit.** Apply each element's `Argument move` and `Techniques`; enforce its `Hard rules`; build the transitions from `## Composition`; write the closing per the closing pattern, so that emphasis, implications and close serve the brief's `--purpose` and pronouns and ownership follow its `--perspective`. Then — last, from the finished elements — write the title (arc-specific, never "Insight Summary") and the Executive TL;DR, weighting it as the contract's TL;DR-emphasis line says. Writing the TL;DR after the elements is what makes "synthesizes all four" enforceable rather than aspirational.

**Pass 3 — language edit.** Localize the four headings from `## Headings` for the output language and make the prose read as executive prose: one idea per sentence, concrete actors and verbs, specificity over intensifiers, no corporate fog. Tune vocabulary, acronym expansion and explanation depth to the brief's `--audience` and inferred knowledge level. When `language: de`, proper umlauts and ß throughout.

**Pass 4 — rhythm and readability.** Vary sentence length; make transitions consequential rather than topical; read each paragraph for cadence and land it on its consequential idea. Count words per element against `## Composition` and adjust by adding evidence to a thin element or trimming redundant transitions, never evidence.

#### Why exactly 4 sections matters

The output uses exactly four `##` headings matching the arc's element names. Downstream tools (story-to-slides, story-to-web in web or storyboard mode) parse these four elements to create matching visual segments; renaming, adding or merging sections breaks that pipeline.

### Phase 5: Validation

Run the deterministic gates first:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/narrative/scripts/validate-narrative.py" \
  --narrative "${OUTPUT_PATH}" --contract "${CLAUDE_PLUGIN_ROOT}/skills/narrative/references/story-arc/${ARC_ID}/arc-definition.md" --json
```

Then read `references/validation.md` and check its judged gates plus the contract's `## Validation` section. Fix any failure and re-run everything — a fix can break a gate that passed. A structural failure is fixed by rewriting against `## Composition`, never by renaming headings.

### Phase 6: Write output

1. Write the narrative to the output path (default `insight-summary.md` in the source directory).
2. Verify the file exists and its `word_count` frontmatter matches the body.
3. Return the JSON summary.

## Derivative Formats (`--format`)

When `--format` is set, adapt an **existing** narrative rather than generating one: skip Phases 0.5-6 and read `references/derivative-formats.md` in full — it carries the per-format templates, word budgets, exact-count structures and condensation strategies.

| Format | Word target | Channel | Key feature |
|--------|-------------|---------|-------------|
| Executive Brief | 300-500 | Email, Slack | Condensed arc with citations preserved |
| Talking Points | N/A (bullets) | Presentations, calls | Answer-first bullets, no citations |
| One-Pager | 400-600 | Print, handout | Metrics table + next steps |

Workflow: load the source narrative → extract its four elements and key numbers → transform per the format's template → validate against the format gates below → write.

Every format keeps all four `##` headings in their original order with the exact element names from the source (the derivative-side counterpart of "Why exactly 4 sections matters"), and derivatives condense — they never add a fact, number or recommendation the source lacks.

**Format gates:** Executive Brief — citations preserved and renumbered sequentially, 8-12 total. Talking Points — no inline citations, Key Numbers section present, no bullet over 25 words. One-Pager — metrics table with exactly 4 rows, Next Steps with 3 items, at least 400 words.

```json
{ "success": true, "source_path": "insight-summary.md", "output_path": "executive-brief.md",
  "format": "executive-brief", "arc_id": "corporate-visions", "word_count": 420, "language": "en" }
```

`source_path` and `format` echo the invocation; `arc_id` and `language` carry over from the source frontmatter. For `talking-points`, `word_count` counts bullet bodies. On failure the shape is the error JSON below with `phase` set to `"Derivative"`.

## Error Handling

On any unrecoverable failure, return `{"success": false, "error": "...", "phase": "..."}`.

| Phase | Failure | Action |
|-------|---------|--------|
| 1 | Source path not found, or no `.md` files in it | Halt with error |
| 2 | Unknown `arc_id` | Halt with the registry's arc list |
| 3 | Arc contract or techniques file missing | Halt with the missing path |
| 4 | Transformation fails | Halt with error JSON |
| 5 | A gate fails | Report, fix, re-validate all gates |
| Derivative | Unknown `--format` value | Halt with the three valid formats |
| Derivative | `--source-path` is not a single finished narrative `.md` | Halt with error |
