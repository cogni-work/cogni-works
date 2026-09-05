---
name: story-to-web
description: >
  Transform any narrative into an optimized brief that Pencil MCP renders: a scrollable web
  narrative by default, or 3-5 printed DIN A posters in storyboard mode. Use this skill
  whenever the user mentions
  "web narrative", "landing page from narrative", "scrollable web page", "web story",
  "single-page narrative", "Webseite aus Bericht", "Landingpage erstellen",
  "Web-Narrative", "scrollbare Webseite",
  "create a web page from report", or, for print output, "storyboard", "Druckposter",
  "poster series", "print posters from narrative", "Poster erstellen",
  or wants to convert prose into a scroll-driven
  section architecture with design tokens and auto-layout. Also trigger for section type
  mapping, hero/CTA optimization and poster pagination, in English or German.
  Produces a web-brief.md, or a storyboard-brief.md in storyboard mode. Important: this skill
  CREATES briefs from a narrative source — not rendering (use the web or storyboard
  agent), not slides (story-to-slides), not prose polish (copywriter).
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite, AskUserQuestion, Agent, Skill
---

# Story-to-Web Skill

## Purpose

Read any narrative document with an existing story arc and produce an optimized web-brief that the Pencil MCP renderer can turn into a scrollable landing-page-style .pen file — or, when `mode=storyboard`, a storyboard-brief that paginates those same sections into 3-5 printed DIN A posters. Act as a **web and print storytelling architect**: analyze the narrative's argument structure, resolve the visual style from the selected theme, decompose the story into web sections, and generate copy and image prompts for each section.

A web narrative is not a slide deck pasted into a tall page. It is a scroll-driven reading experience where each section has ONE clear message, supported by visual hierarchy that guides the reader toward a conversion action. Sections alternate between light and dark to create visual rhythm — in `mode=storyboard` the same rhythm runs down each poster and across the poster sequence. This matters because walls of undifferentiated text lose readers within seconds — alternating visual weight creates natural pause points that let each message land before the next begins.

## Architecture

Two core layers, plus a third in storyboard mode:
1. **Story Arc Analysis** — read narrative, identify argument structure, extract governing thought, build audience model, map section roles
2. **Section Specification + Copywriting** — section type selection, assertion headlines, scroll-optimized copy, image prompts, CTA proposals, visual rhythm enforcement
3. **Poster Pagination** (`mode=storyboard` only) — group sections into arc-station posters, allocate stacked section heights, and resolve DIN poster geometry from `storyboard-layouts.md` (Step 5b)

The brief describes WHAT each section says and which section type to use. The Pencil renderer owns all visual decisions (colors, fonts, spacing) by reading the theme directly — briefs contain no color fields.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `source_path` | auto-discovered | Narrative file or directory. When omitted with `interactive=true`, Step 0 searches nearby. |
| `theme` | interactive | Absolute path to theme.md, or omit to trigger `cogni-workspace:pick-theme` interactive selection. |
| `language` | `en` | Language code (en/de) |
| `title` | auto-detected | Brief title — the web page title, or the poster-set title in `mode=storyboard` (extracted from narrative if not provided) |
| `customer_name` / `provider_name` | from metadata | Organization names |
| `output_path` | `{source_dir}/cogni-visual/web-brief.md` | Brief output location. In `mode=storyboard` the default filename is `storyboard-brief.md` instead. |
| `conversion_goal` | `consultation` | CTA type: consultation, demo, download, trial, contact, calculate |
| `max_sections` | `10` | Maximum section count (forces consolidation if narrative is long). Governs decomposition in both modes; in `mode=storyboard` poster capacity (`poster_count` x 3) can bind tighter — see Step 5b. |
| `mode` | `web` | Output mode. `web` emits a scrollable `web-brief.md`; `storyboard` paginates the same sections into printed posters and emits a `storyboard-brief.md`. |
| `poster_size` | `A1` | **`mode=storyboard` only.** DIN A0-A3, portrait. Dimensions and scale factor resolve from `storyboard-layouts.md`. |
| `max_posters` | `4` | **`mode=storyboard` only.** Poster count cap, range 3-5. |
| `style_guide` | `auto` | **Deprecated — accepted and ignored.** Visual style resolves from the selected theme (Step 4). Passing a value is never an error. |
| `arc_type` | `auto` | Story arc hint: why-change, problem-solution, journey, argument, report |
| `arc_id` | from frontmatter | Narrative arc ID from the `narrative` skill. Mapped to visual `arc_type` in Step 1. |
| `arc_definition_path` | none | Path to arc definition file — element names become `section_label` values. |
| `interactive` | `true` | When `true`, present choices via AskUserQuestion. When `false`, auto-select. |
| `stakeholder_review` | `true` | When `true`, run brief-review-assessor after validation. |
| `audience_context` | none | Structured audience/buyer data for targeted section ordering and CTA calibration. |

### Caller-supplied overrides

Read `$CLAUDE_PLUGIN_ROOT/libraries/brief-pipeline.md` § Caller-supplied overrides; this skill's column is **web** — `confidence_threshold` (section-type mapping), `governing_thought` and `section_roles` (validated in Step 2), `buyer_appendix_path` (Step 3 only).

---

## Conventions

Read `$CLAUDE_PLUGIN_ROOT/libraries/brief-conventions.md` and apply every section: theme-driven visuals (the Pencil renderer owns styling; briefs carry no color field), the structured AskUserQuestion format and the empty-response rule, German fidelity (real Unicode in generated copy, frontmatter trigger phrases left untouched), the good-vs-bad quick reference for headlines, number plays, bullets and CTAs, and absolute printed paths. This skill's interactive checkpoints are narrative selection (Step 0), the section plan (Step 5) and the CTA plan (Step 6b). When `interactive` is `false`, skip every AskUserQuestion call and auto-select.

---

## Workflow

### Execution protocol

Read `$CLAUDE_PLUGIN_ROOT/libraries/brief-pipeline.md` § Execution protocol and follow it for every step: entry gate, read the step's reference, execute, state the output summary. When invoked without explicit parameters, search the filesystem first (Step 0) rather than prompting for paths.

---

### Step 0: Narrative Auto-Discovery

Read `$CLAUDE_PLUGIN_ROOT/libraries/brief-pipeline.md` § Narrative auto-discovery and execute; this skill's values: on selection, set `source_dir` and proceed to Step 1.

---

### Step 1: Parse Parameters & Resolve Context

> Arc resolution and theme loading happen before reading the narrative because they shape how you interpret the story — a pre-resolved arc_type tells you what section pattern to look for.

Determine input type (directory with metadata vs single file) and load metadata.

**Arc resolution:** read `$CLAUDE_PLUGIN_ROOT/libraries/brief-pipeline.md` § Arc resolution and execute; this skill's values: when the arc stays unset, Step 2 auto-detects; `arc_definition_path` element names and their translations become `section_label` values.

**Theme resolution:** read `$CLAUDE_PLUGIN_ROOT/libraries/brief-pipeline.md` § Theme resolution and execute the web row: a caller-supplied absolute path is used directly, otherwise the theme entry point returns `theme_path` (the absolute path to `theme.md`), `theme_name` and `theme_slug`; store all three, and read the theme at Step 4.

**Provider/customer resolution:** Extract `provider_name` and `customer_name` from source metadata. If not found in the source file's frontmatter, search parent and sibling directories for files with `provider:` or `customer:` fields (e.g., sales-presentation.md, pitch-log.json). If still not found, leave empty — never default to the theme name.

**Load libraries:** `web-layouts.md`, `EXAMPLE_WEB_BRIEF.md` (in `mode=storyboard`, `EXAMPLE_STORYBOARD_BRIEF.md` instead — the format exemplar must match the brief being written), `cta-taxonomy.md`, `arc-taxonomy.md` (if arc_id set), theme.md.

---

### Step 2: Read Narrative & Analyze Story Arc

> The governing thought and arc type cascade through everything downstream. Getting them right here prevents rework.

**Read reference:** `references/02-section-architecture.md` (Arc-to-Section Mapping section)

Read all source files. Extract governing thought. A narrative generated by the `narrative` skill ends with a bold `**Sources**` paragraph after its fourth `##`: element 4's content ends at that line, and the block is the citation lookup for source attribution — it never becomes page or poster content.

**Arc type resolution** (priority order):
1. **Pre-resolved from Step 1:** If `arc_context` was populated, use mapped `arc_type` directly. Validate against content but prefer pre-resolved value.
2. **Caller-provided `arc_type`:** If set (not `auto`), use directly.
3. **Auto-detect:** Detect from narrative content. For detailed rules, read `$CLAUDE_PLUGIN_ROOT/skills/story-to-slides/references/03-story-arc-analysis.md` if available.

When caller provides `governing_thought`/`section_roles`: validate against narrative rather than re-deriving. Accept if valid, re-derive if narrative contradicts.

**Content checkpoint:** State arc type, governing thought, section count estimate.

---

### Step 3: Build Audience Model

> The audience model shapes how downstream steps order sections, frame headlines, and calibrate CTA urgency — Rich mode enables targeted prioritization, Lean mode infers from narrative vocabulary.

**Read reference:** `$CLAUDE_PLUGIN_ROOT/skills/story-to-slides/references/02-audience-model.md`

Build Audience Model: Rich mode (from `audience_context`, `buyer_appendix_path`, or pitch-log.json) or Lean mode (inferred from narrative). Identify primary decision-maker, priorities, objections.

**Brief-specific usage** (differs from slides):
- **Section ordering:** Decision-maker priorities surface earlier in the reading sequence — the scroll in `mode=web`, the poster walkthrough in `mode=storyboard`
- **Headline framing:** Technical audience = precise language; executive = business impact language
- **CTA urgency calibration:** Known champion -> higher urgency; known blockers -> address objections before CTA
- **Body text depth:** Expert audience = fewer words, more data; general audience = more context

**Content checkpoint:** State mode, confidence, decision-maker, top priority, top objection.

---

### Step 4: Resolve Visual Style from Theme

> Visual style comes from the theme selected in Step 1, not from a separate style-guide catalogue. Resolving it from the theme keeps one source of truth for design tokens and removes a selection step that has no backing tool.

**Read reference:** `$CLAUDE_PLUGIN_ROOT/references/theme-component-loader.md`

A `style_guide` value on an inbound brief or parameter is accepted and ignored — never an error, so legacy briefs and callers that still pass it run unchanged.

Step 1 already resolved the theme and stored `theme_path`, `theme_name`, and `theme_slug`. Read the design tokens — typography, spacing, color roles, imagery direction — directly from that `theme.md`. It is the authoritative style source for every section.

**Optional tier enrichment.** A theme may additionally expose Theme System v2 component primitives. Probe for one with all four required flags:

```bash
python3 $CLAUDE_PLUGIN_ROOT/scripts/load-theme-component.py \
    --themes-dir <abs-themes-dir> \
    --theme-slug <theme_slug> \
    --surface web \
    --component <component-name>
```

**`mode=storyboard` only:** pass `--surface deck`. That is the surface the `storyboard` renderer itself probes (`libraries/storyboard-layouts.md` § Pencil MCP Rendering Notes, item 3), so brief-time and render-time enrichment resolve the same component set; leaving `web` here would pull web primitives into a print brief on any theme that declares both surfaces.

Probe per section type you are about to render — pass the section type name (`hero`, `feature-alternating`, `stat-row`, `cta`, …) as `--component`. If no component name is in hand, skip the probe and take the Tier-0 / miss path below; it lands on the same complete style source.

Derive `themes_dir` explicitly, because `pick-theme` yields a slug but no themes directory: `themes_dir` = `dirname(dirname(theme_path))`. Passing `--themes-dir` explicitly is the first-ranked source in `theme-component-loader.md` §Themes-dir resolution, so this derived value wins over the `$COGNI_WORKSPACE_ROOT/themes` and walk-up fallbacks the loader would otherwise try — which is what you want here, since the slug `pick-theme` returned is only guaranteed to exist under the directory that produced it.

Tiers come only from this probe. `pick-theme` returns exactly `theme_path`, `theme_name`, and `theme_slug` — never a `tiers` map — so never read tiers off its return contract.

**Tier-0 / miss path.** A theme with no `manifest.json` emits no `tiers` key at all, and the probe returns `status: "miss"` at exit 0. Treat a miss as normal control flow: fall back to the `theme.md` tokens plus the `libraries/web-layouts.md` defaults and continue — in `mode=storyboard`, the `libraries/storyboard-layouts.md` defaults, plus `web-layouts.md` for the shared section-type schemas, rather than blocking or prompting — a tier-0 theme is a supported configuration, not a failure.

**Output:** Resolved style source — the theme's `theme.md` design tokens, plus the contents of any component file the probe resolved (the loader returns a `path`, never bytes: open the returned `path` to read the primitive).

---

### Step 5: Decompose Narrative into Sections

> Section decomposition is the structural backbone. Each section maps to a part of the story arc and gets a section type that determines its visual container.

**Read reference:** `references/02-section-architecture.md`

Break the narrative into 6-10 sections (capped by `max_sections`). Each section maps to a part of the story arc and has a section type.

For each section:
1. Determine arc role (hook, problem, urgency, solution, proof, roadmap, CTA)
2. Map arc role to section type using arc-to-section mapping
3. **Score mapping confidence** (0.0-1.0) and record it in each section's YAML as `confidence: 0.XX`. Primary section type with strong evidence = high (0.9+). Alternate type or ambiguous mapping = medium (0.7-0.8). No clear match = low (<0.7). Flag mappings below `confidence_threshold` for manual review.
4. Assign `section_theme` (dark/light/light-alt/accent)
5. Identify hero message and key data points
6. Enforce bookend rules (hero first, CTA last)
7. Set feature-alternating positions (odd/even)
8. Assign `section_label` (content-source-first, role-based fallback):
   - If arc_elements available: check which narrative H2 chapter content came from -> match to arc element name (content-source method). Fall back to role-based mapping for intro/synthesized content. Use localized names per `language`. See `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md` for full heuristic.
   - If no arc_elements: use generic role-based labels (e.g., "Das Problem", "Die Lösung", "Der Weg")

**Content checkpoint:** State section count, section types used, theme alternation pattern, any low-confidence mappings.

---

### Step 5b: Paginate Sections into Posters (`mode=storyboard` only)

> A poster is one arc station holding 1-3 stacked sections. Skip this step entirely when `mode=web`. **Read reference:** `references/print/01-poster-architecture.md`

1. **Poster count from narrative length**, then cap at `max_posters` — take the word-count thresholds and the 3-5 bound from the reference's poster-count decision tree. Then resolve section capacity (`poster_count` x 3) before mapping stations in item 2 — it, not `max_sections`, is the binding cap; when `section_count` exceeds it, the reduction procedure, the prohibited poster patterns and the hero/cta bookends are owned by the reference § Section Capacity Is the Binding Cap.
2. **Map arc stations to posters** using the poster templates in the reference.
3. **Stack 1-3 sections per poster**, taking the height splits, the split-ratio selection rules and the portrait adaptations from `$CLAUDE_PLUGIN_ROOT/libraries/storyboard-layouts.md` — the same library item 4 reads for geometry, and the authoritative home for all three. `references/print/01-poster-architecture.md` restates them for readers arriving from the poster templates.
4. **Resolve poster geometry from `poster_size`.** Read the scale-factor table in `$CLAUDE_PLUGIN_ROOT/libraries/storyboard-layouts.md` (A0-A3, portrait only): that row gives `print_width`, `print_height` and `scale_factor`. `base_width` / `base_height` are the fixed design resolution 1440 x 2036, and `poster_gap` defaults to that library's base gap of 200px. With `poster_size` and the `poster_count` from item 1, these are exactly the eight frontmatter fields Step 10 writes.

**Content checkpoint:** State poster count, the station-to-poster mapping, the height split per poster, and the resolved poster geometry, and confirm `section_count` is at most `poster_count` x 3.

---

### Step 6: Write Section Copy & Image Prompts

> Web copy must work in a scroll context where readers decide within 2 seconds whether to keep scrolling or bounce; in `mode=storyboard` the same copy is read at 1-2m from a printed poster, so it must land without a scroll to reward it.

**Read references:**
- `references/03-section-copywriting.md`
- `references/04-image-prompts.md`
- **`mode=storyboard` only**, layered as overrides on the two above: `references/print/02-poster-copywriting.md` and `references/print/03-image-prompts.md`. Take the print image-prompt suffix verbatim from `03-image-prompts.md`, along with its per-poster image cap — a paraphrased suffix fails Step 9's image-consistency check.

For each section, generate:

1. **Assertion headline** (max 70 chars)
2. **Body text** or **bullets** (per section type constraints)
3. **Stat numbers** with reframed number plays (where applicable)
4. **Image prompt** (for hero background, feature images — per section type)
5. **Section label** (optional, per arc role)
6. **CTA text** matching `conversion_goal` (for hero and CTA sections)

**Output:** Complete section specifications with copy and image prompts.

---

### Step 6b: Propose CTAs (INTERACTIVE)

> Without explicit CTAs, the reader scrolls to the bottom and leaves — or, on a poster wall, walks past with no action to take. CTAs convert attention into action.

**Entry gate:** Verify Step 6 outputs — all sections have assertion headlines, copy, and image prompts.

**Read reference:** `$CLAUDE_PLUGIN_ROOT/libraries/cta-taxonomy.md`

1. Extract implicit CTAs from narrative + generate from governing thought, arc type, hero numbers, `conversion_goal`
2. Per section: assign `cta.text` (max 50 chars, imperative verb), `cta.type` (explore/evaluate/commit/share), `cta.urgency` (low/medium/high)
3. Build `cta_summary`: 3-5 proposals, `primary_cta` = highest-urgency commit CTA matching `conversion_goal`

**Web-specific CTA rendering** (`mode=web` only):
- `commit` CTAs -> rendered as buttons in hero and CTA sections
- `evaluate` CTAs -> rendered as secondary buttons or highlighted links
- `explore` and `share` CTAs -> rendered as text links within section copy

**`mode=storyboard`:** a printed poster has no interactive affordances, so CTA type drives placement and prominence rather than a control — the `commit` CTA becomes the `cta` section text on the closing poster, and lower-commitment CTAs stay inside section copy. Carry `cta.text` / `cta.type` / `cta.urgency` through unchanged; `EXAMPLE_STORYBOARD_BRIEF.md` shows the resulting shape.

If interactive: present CTA plan via AskUserQuestion (Approve/Adjust, with primary_cta in question text). On empty response, treat as approval.

**Output:** Per-section CTA assignments and CTA summary block.

---

### Step 7: Section Preview Checkpoint (INTERACTIVE)

> The section plan is the last structural checkpoint before final validation. Catching errors here is cheaper than fixing the full brief. In `mode=storyboard` the unit being approved is the poster, so the table must show the pagination Step 5b decided — otherwise the reader approves a section list and gets a poster set.

**`mode=storyboard` only:** prefix the section table with a poster plan — one row per poster carrying `Poster | Label | Sections | Section Types`, a `Size: {poster_size} portrait | Posters: {count}` footer, and a `SELF-CHECK: Total posters = {count}. Must be 3-5.` line — so the approve/adjust gate below covers the pagination and not only the section list.

If interactive:

First, output the section plan table as a regular message:

```
| # | Type | Theme | Headline | Arc Role | Section Label |
|---|------|-------|----------|----------|---------------|
| 1 | hero | dark | {headline} | hook | -- |
| 2 | problem-statement | light | {headline} | problem | {label} |
| ... | ... | ... | ... | ... | ... |

Sections: {count} | Arc: {arc_id or arc_type} | CTA: {cta_text}
```

Then present via AskUserQuestion (Approve/Adjust). On empty response, treat as approval.

If not interactive: skip this checkpoint.

---

### Step 8: Generate Header & Footer Content (`mode=web` only)

> Header and footer provide the page's navigation frame and brand presence.

**`mode=storyboard`:** skip this step. A storyboard brief has no page-level header or footer — `EXAMPLE_STORYBOARD_BRIEF.md` defines no such fields. Each poster instead carries its own header strip, built from the `sequence` and poster label resolved in Step 5b under the governing-headline rules in `references/print/02-poster-copywriting.md`.

Generate header and footer content based on metadata:

```yaml
header:
  logo_text: "{provider_name}"
  cta_text: "{cta_text from conversion_goal}"

footer:
  company_name: "{provider_name}"
  copyright: "{year} {provider_name}"
  provider: "{provider_description or empty}"
  date: "{month year in language}"
```

---

### Step 9: Validate Against Schema

> Self-assessment is unreliable without explicit measurement. The four-layer gate forces honest evaluation.

**Read reference:** `references/05-validation.md`  *(`mode=web`)*

Four layers — stop on first failure, fix, re-check:

1. **Schema** — run `python3 "$CLAUDE_PLUGIN_ROOT/scripts/check-brief.py" --type web "{output_path}"` (`--type storyboard` in `mode=storyboard`) and fix every `fail`, then the section-type checks the checklist keeps by eye
2. **Message quality** — assertion headlines, number plays, parallel bullets
3. **Visual coherence** — section theme alternation, feature position alternation, image consistency
4. **Content integrity** — all narrative sections represented, language consistency

**`mode=storyboard` only:** read `references/print/04-validation.md` **instead of** `05-validation.md`, not in addition to it. It restates all four layers against the storyboard-brief schema and then adds a fifth print group — poster count within 3-5, per-section minimum heights, poster font-size minimums, safe-area margins, and contiguous poster sequence numbering. The substitution is load-bearing, not tidiness — the web layers fail four CRITICAL checks on a sound storyboard brief and would rewrite it into web shape; `print/04-validation.md` opens with the full rationale.

---

### Step 9b: Stakeholder Review (when `stakeholder_review=true`)

> Structural validation catches schema and formatting issues, but cannot tell whether the web brief will create an effective scroll experience — whether the opening hooks visitors, whether CTAs are placed at motivation peaks, or whether the content converts. In `mode=storyboard` the same question is a print one — whether a poster reads at arm's length, whether the station sequence survives a physical walkthrough, and whether any single poster is overloaded. The brief-review-assessor evaluates from the perspective trio matching the `brief_type` it is given.

Read `$CLAUDE_PLUGIN_ROOT/libraries/brief-pipeline.md` § Stakeholder review loop and execute; this skill's values: `brief_type: web`, or `storyboard` in `mode=storyboard` (the assessor then loads the Print Designer / Target Audience / Exhibition Presenter trio from `libraries/brief-review-perspectives.md`); the brief content is written to a `.draft` temp file when the brief is not yet written; on accept proceed to Step 10; on revise re-run Step 9 after the edits; the verdict file is the brief's name with `.md` replaced by `.review.json` (`web-brief.review.json` or `storyboard-brief.review.json` by default). On a headless reject, keep the brief, do not render it, and surface the reject in the response, then continue.

---

### Step 10: Write the Brief

> The output path convention keeps briefs in `cogni-visual/` to prevent clutter.

**Output path resolution:** read `$CLAUDE_PLUGIN_ROOT/libraries/brief-pipeline.md` § Output-path resolution and execute; this skill's default filename is `web-brief.md`, or `storyboard-brief.md` in `mode=storyboard`.

Generate the final brief with YAML frontmatter and section specifications following `EXAMPLE_WEB_BRIEF.md` format. Write using Write tool.

**`mode=storyboard` only:** follow `$CLAUDE_PLUGIN_ROOT/libraries/EXAMPLE_STORYBOARD_BRIEF.md` instead — its frontmatter and body schema are the contract the `storyboard` agent parses, so reproduce both exactly rather than adapting the web shape. Frontmatter carries the eight poster-geometry fields resolved in Step 5b alongside the shared theme/arc fields — carry them through unchanged rather than recomputing them here; the body is one `## Poster N` block per poster, each holding its 1-3 stacked section YAML blocks with `section_theme` and `height_percent`.

**`industry` provenance.** `industry` is not a caller parameter — it is inferred from the narrative's own content (sector language, customer and process vocabulary), the inference `references/04-image-prompts.md` § Prompt Consistency Rules item 3 already requires of every image prompt. Record the inferred value in the storyboard brief's `industry` frontmatter field so the `storyboard` agent and the print image prompts read one consistent value; in `mode=web` the inference stays implicit in the image prompts and `EXAMPLE_WEB_BRIEF.md` writes no such frontmatter field.

**Final checks:**
- YAML frontmatter complete (type, version, theme, theme_path, conversion_goal, arc_id if available, confidence_score as average of per-section scores; plus `industry` in `mode=storyboard`)
- Header and footer sections present (`mode=web` only)
- All sections specified with type, section_theme, arc_role, headline, confidence
- First section is hero (dark), last content section is CTA (accent)
- Image prompts present for hero and feature-alternating sections
- CTA summary block present
- Generation metadata populated
- Zero color fields in entire document

---

### Step 11: Generate Rendering Prompt

> The user needs a ready-to-use prompt for a fresh Claude chat with the renderer agent — the web agent, or the storyboard agent in print mode. Absolute paths make it self-contained.

After the brief is written and validated, **append** the rendering prompt from `references/06-rendering-prompt.md` to the end of the brief (after Generation Metadata) and print it to the conversation — the `mode=web` template names the `web` agent and goes into `web-brief.md`; the `mode=storyboard` template names the `storyboard` agent and goes into `storyboard-brief.md`. Interpolate the `output_path` resolved in Step 10 and the `theme_path` from Step 1 as absolute paths — never `~`, `$HOME`, `$CLAUDE_PLUGIN_ROOT` or relative paths, because the receiving Claude session has no access to variables from this session.

---

## Bundled Resources

### References (loaded at specific steps — progressive disclosure)

| Reference | Step | Purpose |
|-----------|------|---------|
| **02-audience-model.md** (from story-to-slides) | 3 | Audience Model construction (Rich/Lean mode) |
| **theme-component-loader.md** (plugin root) | 4 | Tier probe envelope, miss-is-normal control flow, themes-dir resolution |
| **02-section-architecture.md** | 2, 5 | Arc-to-section mapping, decomposition rules, section_theme alternation |
| **03-section-copywriting.md** | 6 | Web headline hierarchy, CTA copy patterns, number plays |
| **04-image-prompts.md** | 6 | Web image formats, hero bg+overlay pattern, stock vs AI guidance |
| **05-validation.md** | 9 | *(`mode=web`)* Four-layer validation framework |
| **06-rendering-prompt.md** | 11 | Rendering-prompt templates for the `web` and `storyboard` agents |
| **print/01-poster-architecture.md** | 5b | *(`mode=storyboard`)* Arc-station-to-poster mapping, poster templates, poster-count decision tree |
| **print/02-poster-copywriting.md** | 6, 8 | *(`mode=storyboard`)* Print-vs-web copy overrides, poster governing-headline rules |
| **print/03-image-prompts.md** | 6 | *(`mode=storyboard`)* Print-resolution prompt suffix, max-2-images rule, poster image sizing |
| **print/04-validation.md** | 9 | *(`mode=storyboard`)* Replaces 05-validation.md — all four layers against the storyboard schema, plus print-specific checks and poster font-size minimums |

### Libraries (loaded as needed)

| Library | Step | Purpose |
|---------|------|---------|
| **arc-taxonomy.md** | 1 | Arc ID -> visual arc type mapping, element names |
| **web-layouts.md** | 1 | Section type schemas, typography scale, spacing, theme-to-variable mapping |
| **cta-taxonomy.md** | 6b | CTA types, urgency, arc-to-CTA heuristics |
| **EXAMPLE_WEB_BRIEF.md** | 1 | *(`mode=web`)* Output format reference |
| **storyboard-layouts.md** | 4, 5b | *(`mode=storyboard`)* DIN A0-A3 dimensions, 3-zone poster model, height allocation, portrait adaptations, `poster_x` canvas arrangement |
| **EXAMPLE_STORYBOARD_BRIEF.md** | 1, 10 | *(`mode=storyboard`)* Output format reference — the contract the `storyboard` agent parses |
