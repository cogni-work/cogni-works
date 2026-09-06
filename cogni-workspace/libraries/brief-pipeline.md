---
library_id: brief-pipeline
version: 1.0.0
created: 2026-09-05
updated: 2026-09-05
---

# Brief Pipeline — shared steps

The steps every `story-to-*` producer runs in the same shape. Each section states the step once and carries a per-producer table for the values that differ; a SKILL.md points here with one line of the form "Read `$CLAUDE_PLUGIN_ROOT/libraries/brief-pipeline.md` § <section> and execute; this skill's values: …" and never restates the algorithm. Where the three former copies differed, the stronger variant was kept and is marked.

## Execution protocol

Each step: verify the previous step's output is available (entry gate), read the reference file for that step, execute, then state the output summary before moving on. Reference files contain step-specific rules that prevent downstream rework — read them at the start of each step.

When a skill is invoked without explicit parameters, search the filesystem first (§ Narrative auto-discovery) rather than prompting for paths: users invoke from project directories that already contain their narrative, and asking for a path they are sitting next to creates unnecessary friction. Do not ask for `source_path`, `theme`, `language` or any other parameter before that search has run.

## Narrative auto-discovery

> Users invoke from project directories containing their narrative. Searching first eliminates path-fumbling.

If `source_path` was explicitly provided: set `source_dir` to its parent directory and proceed to the next step.

Otherwise, search without asking:

1. **Primary:** Glob `**/insight-summary.md` from CWD (max 3 levels)
2. For each candidate: read the first 30 lines, extract title, arc_id, estimate word count
3. **Secondary** (if 0 primary results): Glob `**/*.md`, filter for `arc_id:` in the first 30 lines. Exclude SKILL.md, README.md, CLAUDE.md.
4. Sort: insight-summary.md files first, then by path depth (shallow first)

**If candidates found:** present via AskUserQuestion (max 4 options with filename, title, arc_id, word count). On an empty response, auto-select the top candidate.

**If no candidates:** ask for a path or cancel. On an empty response, stop with: "No narrative path provided. Stopping."

Set `source_dir` = parent directory of the selected `source_path`.

| Producer | Next step |
|----------|-----------|
| story-to-slides | Step 1 |
| story-to-web | Step 1 |
| story-to-infographic | Step 1 |

(The slides and web copies were byte-identical; the infographic copy differed by one word.)

## Theme resolution

The **theme entry point** is the ecosystem's theme picker — today `cogni-workspace:manage-themes` Operation 11 (Select Theme), which scans the standard and workspace theme directories, presents an interactive AskUserQuestion and returns the absolute `theme_path` (to `theme.md`), `theme_name` and `theme_slug`. Producers name the entry point through this section rather than in their own text, so folding the picker into another skill changes one line here. If the entry point is unavailable (cogni-workspace not installed), fall back to Glob scanning `$COGNI_WORKSPACE_ROOT/themes/*/theme.md` and present via AskUserQuestion manually.

**Path convention:** a `theme_path` written into brief frontmatter is the **absolute filesystem path** to the `theme.md` file, so the renderer can read it without path-resolution ambiguity. A caller-supplied path is recorded verbatim — never rewritten, relativised or re-resolved; the `narrative-publish` pipeline resolves the theme once and passes the path through to every producer.

| Producer | When a theme is resolved | Consumes the theme itself? |
|----------|--------------------------|----------------------------|
| story-to-slides | Never in the producer. A caller-supplied `theme` (absolute path) is recorded as `theme_path`; otherwise both keys are omitted. The renderer chosen at the Render checkpoint (Step 11) resolves a theme if it needs one. | No — pass-through only |
| story-to-web | Step 1: a caller-supplied absolute path is used directly; otherwise invoke the entry point. Web and storyboard modes read the theme at Step 4 to resolve the visual style. | Yes |
| story-to-infographic | Step 1: `theme` is a slug (default `smarter-service`) resolved to `/cogni-workspace/themes/{theme}/theme.md`; `auto` under `interactive=true` invokes the entry point. The brief records the absolute path. | Yes |

(The four-step picker delegation and the fallback came from the slides and web copies, which were byte-identical; the path convention from the web copy; the pass-through row from the render-time theme decision.)

## Arc resolution

Execute the `## Arc Resolution Pseudocode` in `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md` — it is the single statement of the priority order (`arc_id` parameter → source frontmatter `arc_id`, with the legacy `report_arc` alias → unset), the mapping lookup with its unknown-id warning, the `arc_context` store, and the `arc_definition_path` element extraction. A mapped `arc_type` overrides the `arc_type` parameter when both are given. The section roles a producer assigns afterwards are the closed set in that library's `## Arc Roles`.

| Producer | When the arc is unset | Element names are used for |
|----------|-----------------------|----------------------------|
| story-to-slides | Step 4 auto-detects | Methodology slide phase labels |
| story-to-web | Step 2 auto-detects | `section_label` values (with translations) |
| story-to-infographic | Step 2 auto-detects | — |

(The override rule and the translations came from the web copy.)

## Output-path resolution

Run via Bash before writing:

- If `output_path` is explicit: `mkdir -p "$(dirname "${output_path}")"`
- Otherwise: set `output_path = {source_dir}/cogni-visual/{default filename}` and `mkdir -p "{source_dir}/cogni-visual"`

| Producer | Default filename | Resolved at |
|----------|------------------|-------------|
| story-to-slides | `presentation-brief.md` | Step 8.2, before the enrichment agent launches; Step 10 (fallback path) reuses the value |
| story-to-web (`mode=web`) | `web-brief.md` | Step 10 |
| story-to-web (`mode=storyboard`) | `storyboard-brief.md` | Step 10 |
| story-to-infographic | `infographic-brief.md` | Step 9 |

(The `mkdir -p` line was byte-identical in all three; the storyboard filename came from the web copy.)

## Stakeholder review loop

> Structural validation catches schema and formatting issues, but cannot tell whether the brief will work for its audience, its presenter or reader, and as a visual communication. The `brief-review-assessor` agent evaluates from the three stakeholder perspectives matching the `brief_type` it is given — catching weak headlines that pass schema checks, layout monotony that passes variety rules, and CTA gaps that pass structural validation. Reviewing at the brief stage is efficient because changes are text edits, not re-renders.

**Skip this step** if `stakeholder_review=false`.

Launch the `brief-review-assessor` agent with `brief_type`, the brief content, `source_narrative` (the narrative path from Step 0), `audience_context` if provided, and `round: 1`. The verdict thresholds — accept, revise, reject, and the round-2 acceptance rule — are owned by `$CLAUDE_PLUGIN_ROOT/agents/brief-review-assessor.md` § Verdict Logic and are not restated here.

**On accept:** proceed to the next step.

**On revise:**
1. Apply CRITICAL improvements first, then HIGH improvements — edit the brief surgically (headlines, unit types, notes, CTAs, sequence as recommended)
2. Re-run the producer's validation step to ensure structural integrity after the edits
3. Re-launch the assessor (`round: 2`)
4. If round 2 accepts: proceed
5. If round 2 still has issues: present the remaining issues to the user, then proceed

**On reject:** surface the verdict to the user via AskUserQuestion and let them decide whether to proceed, edit manually, or abandon.

**Headless reject** (`interactive=false`, which `stakeholder_review=true` no longer implies): a headless run reaches the reject branch with no user to ask. The AskUserQuestion is skipped per the standing convention, and the run must instead keep the brief, not render it, and surface the reject in the response — the verdict is still written to the review sibling, so the signal is recorded rather than lost — then continue. Never abort or error: this matches the caller reject rule in `cogni-workspace/skills/narrative-publish/references/pipeline-contract.md`, under which a multi-target run fails only when every requested target failed.

**Verdict file:** write the review verdict beside the brief, deriving its name from the resolved `output_path` — replace the trailing `.md` with `.review.json`. The defaults yield `presentation-brief.review.json`, `web-brief.review.json`, `storyboard-brief.review.json` and `infographic-brief.review.json`; a caller-supplied `output_path` keeps its own stem.

| Producer | `brief_type` | Brief content passed | Validation step re-run on revise |
|----------|--------------|----------------------|----------------------------------|
| story-to-slides | `slides` | the file at `output_path` (written by the enrichment agent in Step 8.2, or by Step 10 on the fallback path) | Step 9 |
| story-to-web (`mode=web`) | `web` | the brief, written to a `.draft` temp file if not yet written | Step 9 |
| story-to-web (`mode=storyboard`) | `storyboard` — the assessor loads the Print Designer / Target Audience / Exhibition Presenter trio | same | Step 9 |
| story-to-infographic | `infographic` | the brief, written to a `.draft` temp file if not yet written | Step 8 |

(The revise ladder came from the slides copy, the generalised verdict-file rule and the `brief_type` branching from the web copy; the headless-reject paragraph was byte-identical in all three.)

## Caller-supplied overrides

These are typically set by an upstream agent (e.g., why-change-work), not by a human user:

| Parameter | Default | Meaning | slides | web | infographic |
|-----------|---------|---------|--------|-----|-------------|
| `confidence_threshold` | `0.8` | Minimum confidence for automatic unit-type mapping | layout mapping | section-type mapping | — |
| `governing_thought` | auto-extracted | Pre-computed governing thought — validated rather than re-derived | Step 4 | Step 2 | Step 2 (a plain parameter there) |
| `section_roles` | auto-detected | Pre-mapped section roles — validated rather than re-derived | Step 4 | Step 2 | — |
| `buyer_appendix_path` | none | Path to buyer-appendix.md read as a supplementary source | enriched Q&A prep (Step 8.2 only) | enriched audience model (Step 3 only) | — |
| `design` | per `presentation-intent.md` | The deck's design intent (`register`, `dark_slides`, `speaker_notes`, `imagery`, `variations`) | Step 8.2 | — | — |

(The slides table was the superset; the web table carried four of its rows with different step numbers.)
