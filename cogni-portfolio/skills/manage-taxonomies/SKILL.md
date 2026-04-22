---
name: manage-taxonomies
description: |
  Create, customize, or replace the taxonomy a cogni-portfolio project uses to classify
  offerings. Use whenever the user wants to customize the taxonomy, clone a standard
  taxonomy for editing, create a new taxonomy from scratch, override the bundled
  template, add or rename dimensions or categories, tweak search patterns, or import
  a taxonomy JSON from an external reference model. Triggers on "customize taxonomy",
  "clone taxonomy", "copy taxonomy", "create a new taxonomy", "my own taxonomy",
  "override taxonomy", "taxonomy dimensions", "taxonomy categories", "edit search
  patterns", "import taxonomy", "my industry isn't in the templates". Project-local:
  the customized taxonomy lives inside the portfolio project, survives plugin updates,
  and overrides the bundled template during scan and setup resolution.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Manage Taxonomies

## Core Concept

`cogni-portfolio` ships 8 industry taxonomy templates — `b2b-ict`, `b2b-saas`, `b2b-fintech`, `b2b-healthtech`, `b2b-martech`, `b2b-industrial-tech`, `b2b-professional-services`, `b2b-opensource`. Each one is a 7-file bundle that drives `portfolio-scan` (search patterns, category tables) and maps discovered offerings to products and features via the product-template contract.

A taxonomy works best when it matches the industry you are scanning. Often the bundled 8 are close enough; sometimes they are not. This skill is how the user takes ownership of the taxonomy — clones a bundled one to edit, authors a new one, or imports one from an external reference model. The customized taxonomy lives **inside the portfolio project** at `{PROJECT_PATH}/taxonomy/` — it is not shared across projects, it is not written back to the plugin, and it survives plugin updates because it is part of the project's own data.

**Resolver precedence** (used by `portfolio-scan` Phase 0 and `portfolio-setup` Step 5):

1. If `{PROJECT_PATH}/taxonomy/` exists → use it (project-local wins)
2. Else if `portfolio.json` has `taxonomy.type` → load `$CLAUDE_PLUGIN_ROOT/templates/{type}/`
3. Else run the industry-match fallback against bundled templates

Project-local ownership means the user can safely edit `{PROJECT_PATH}/taxonomy/template.md`, `categories.json`, `search-patterns.md`, and the rest without worrying about plugin updates reverting their changes.

---

## Prerequisites

A cogni-portfolio project must exist — i.e. `{PROJECT_PATH}/portfolio.json` is readable. If it does not, tell the user to run `cogni-portfolio:setup` first and stop.

---

## Workflow

### Phase 0: Locate the Project

1. Find the target project. If the user did not name one, resolve the active project the same way other project-scoped skills do — `find . -path "*/cogni-portfolio/*/portfolio.json" -type f`, and if multiple match, ask via `AskUserQuestion`.
2. Set `PROJECT_PATH` to the directory containing `portfolio.json`.
3. Read `portfolio.json`. Note whether `taxonomy.type` is set and whether `{PROJECT_PATH}/taxonomy/` already exists — both affect the mode choice.

### Phase 1: Select Mode

Present the three modes via `AskUserQuestion`, including the current state so the user knows what they are working against.

| Mode | When to pick | What it does |
|---|---|---|
| `clone` | "I want the `b2b-ict` taxonomy but with a few categories of my own" — the closest bundled template is good enough to start from | Copies one bundled template into `{PROJECT_PATH}/taxonomy/`, updates `portfolio.json` to reference the clone, and tells the user exactly which files to edit |
| `author` | "None of the 8 bundled templates is close — I want to define mine from scratch" | Interactively collects dimensions, categories, product skeleton, and search patterns, scaffolds the 7-file bundle directly into `{PROJECT_PATH}/taxonomy/` |
| `import` | "I already have a taxonomy definition (JSON, spreadsheet, consultancy model) — load it in" | Accepts an external structured input, validates against the template schema, scaffolds into the 7-file shape |

If `{PROJECT_PATH}/taxonomy/` **already exists**, add a fourth implicit option in the question: "Keep existing — just show me what is there." Only offer `clone` / `author` / `import` for re-customization after warning the user that the existing project-local taxonomy will be replaced (use `--force` on `clone-taxonomy.sh`).

### Phase 2a: Clone a Bundled Template

This is the most common path.

1. **Pick the base template.** List the 8 bundled templates by reading `$CLAUDE_PLUGIN_ROOT/templates/*/template.md` frontmatter — present `type`, short description, dimension count, and category count. Use `AskUserQuestion` with the list.

2. **Run the clone script:**

   ```bash
   bash $CLAUDE_PLUGIN_ROOT/scripts/clone-taxonomy.sh "${PROJECT_PATH}" "${BASE_TYPE}"
   ```

   The script copies `$CLAUDE_PLUGIN_ROOT/templates/{BASE_TYPE}/*` into `{PROJECT_PATH}/taxonomy/` and updates `portfolio.json`'s `taxonomy` block with `source_path: "taxonomy/"`, `cloned_from: "{BASE_TYPE}"`, and `cloned_at: <today>`. It refuses to overwrite an existing project-local taxonomy unless `--force` is appended — offer that explicitly before passing it.

3. **Parse the script's JSON output.** On `success: false`, surface the error verbatim and stop. On success, report the file count and the destination path.

4. **Guide the edit.** The user now owns the taxonomy. Tell them which files they typically edit:

   | File | What to change |
   |---|---|
   | `template.md` | Dimension names (frontmatter), industry_match patterns, tone of the intro copy |
   | `categories.json` | Add/rename/remove categories; keep `id` in `dimension.number` format |
   | `search-patterns.md` | Tweak web search queries per category (the scan engine reads this verbatim) |
   | `product-template.md` | If you renamed a dimension, update the matching product slug + description here |
   | `cross-category-rules.md` | Add rules for offerings that legitimately span two categories |
   | `provider-unit-rules.md` | Who counts as an in-scope subsidiary/BU for scans |
   | `report-template.md` | Rarely needs editing — the scan report shape is usually fine as-is |

   **Keep categories.json and template.md consistent** — every category id that appears in one must appear in the other. A mismatch will confuse the scan's Phase 3 search and Phase 5 status assignment.

5. **Close the loop.** Tell the user: "Taxonomy cloned to `{PROJECT_PATH}/taxonomy/`. Edit the files above, then run `portfolio-scan` — it will now use your customized taxonomy."

### Phase 2b: Author a New Taxonomy From Scratch

Use when no bundled template is close enough to be worth cloning. Offered but heavier — interactive and slower than clone.

1. **Name and identify.**
   - Ask for a `type` slug (kebab-case, e.g. `b2b-logistics`, `b2b-automotive-tier1`).
   - Ask for a one-line description and the `industry_match` patterns (comma-separated keywords that should match this vertical in setup's detection step).

2. **Define dimensions.** Dimension 0 is reused verbatim from any bundled template — it is industry-agnostic (Provider Profile Metrics with 6 categories: Financial Scale, Workforce Capacity, Geographic Presence, Market Position, Certifications, Partnership Ecosystem). Read it from `$CLAUDE_PLUGIN_ROOT/templates/b2b-ict/categories.json` and copy forward.

   For dimensions 1–7, ask the user for:
   - `dimension_name` (e.g. `Fleet & Telematics`, `Cold Chain`, `Customs & Compliance`)
   - `dimension_slug` (kebab-case of the name)

   Aim for 5–7 service dimensions. Fewer than 4 misses coverage; more than 8 gets unwieldy.

3. **Define categories per dimension.** For each dimension 1–N ask for 4–10 categories:
   - `id` = `{dimension}.{number}` (auto-numbered)
   - `name` (free text, 2–5 words, title case)

4. **Define the product skeleton.** One standard product per dimension 1–N (Dim 0 is never a product). Ask for:
   - `slug` (kebab-case, defaults to `dimension_slug`)
   - `name` (title-cased dimension_name usually fits)
   - One-line description

5. **Generate search-pattern stubs.** For each category, generate two query stubs automatically:
   - Marketing: `"{dimension_name}" "{category_name}" services {vertical_keyword}`
   - Technical docs: `"{category_name}" documentation OR product page {vertical_keyword}`

   Write them into `search-patterns.md` with the same section structure the bundled templates use. Tell the user these are starting-point queries — they will want to tune them once they see the first scan results.

6. **Write the 7-file bundle** into `{PROJECT_PATH}/taxonomy/`. Use the bundled `b2b-ict` files as the structural template — copy structure, replace content. The full shape to produce:
   - `template.md` — frontmatter (type, version `0.1.0`, dimensions count, categories count, industry_match) plus a dimension/category table
   - `categories.json` — flat array of category objects (one per id)
   - `search-patterns.md` — Phase 1 (company discovery, copy from b2b-ict), Phase 2 (provider profile, copy from b2b-ict), Phase 3 (per-category stubs you generated)
   - `product-template.md` — the dimension → product table with the skeleton
   - `cross-category-rules.md` — start empty with a comment explaining it can be added later
   - `provider-unit-rules.md` — copy from `b2b-ict` and tell the user to adapt
   - `report-template.md` — copy from `b2b-ict` (rarely needs vertical-specific edits)

7. **Update `portfolio.json`** — set `taxonomy.type`, `taxonomy.source_path: "taxonomy/"`, `taxonomy.authored_at: <today>`.

### Phase 2c: Import From External JSON

Use when the user has a structured taxonomy definition in hand.

1. Ask the user for the input source — a local file path (JSON, CSV, or markdown table). Read it.
2. Normalize into the internal shape: dimensions[], categories[] (with id/name/dimension mapping), and ideally products[] and search_patterns{} if the source has them.
3. If products are missing, prompt the user for each dimension's product slug/name/description (same fields as 2b Step 4).
4. If search patterns are missing, generate stubs as in 2b Step 5 and flag them for tuning.
5. Write the 7-file bundle and update `portfolio.json` as in 2b Step 6–7.

---

## Validation

After any of the three modes completes, run these checks before handing off:

1. `{PROJECT_PATH}/taxonomy/template.md` exists and has parseable frontmatter.
2. `{PROJECT_PATH}/taxonomy/categories.json` is valid JSON with at least one entry per dimension declared in `template.md`.
3. Every category id mentioned in `categories.json` appears at least once in `search-patterns.md`.
4. `portfolio.json` has `taxonomy.source_path: "taxonomy/"`.

If any check fails, report it to the user and suggest which file to fix — do not silently repair, because the user's edit intent might differ from the fix.

---

## What Happens Next

Once the project-local taxonomy is in place:

- `portfolio-setup` Step 5 — if re-run, will pick up the project-local taxonomy and skip the bundled-template match.
- `portfolio-scan` Phase 0 Step 5 — resolves to `{PROJECT_PATH}/taxonomy/` first (see [portfolio-scan SKILL.md](../portfolio-scan/SKILL.md) for the resolver order).
- `portfolio-web-researcher` agent — reads `{PROJECT_PATH}/taxonomy/search-patterns.md` instead of the plugin-bundled file.
- `portfolio-dashboard` and `portfolio-communicate` — group features by the user's custom dimensions automatically because they read from `portfolio.json` + discovered features, which already carry the right `taxonomy_mapping`.

No code changes in the downstream consumers are needed — they already resolve the template from a single path, and that path now points project-local.

---

## Variables Reference

| Variable | Description | Example |
|---|---|---|
| `PROJECT_PATH` | Absolute path to the portfolio project directory | `/Users/me/work/cogni-portfolio/acme-corp` |
| `BASE_TYPE` | Slug of the bundled template used for `clone` mode | `b2b-ict` |
| `TYPE` | Slug of the user's taxonomy (`clone` keeps BASE_TYPE; `author`/`import` is user-chosen) | `b2b-logistics` |
