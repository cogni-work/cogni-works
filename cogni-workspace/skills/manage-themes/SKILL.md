---
name: manage-themes
description: >-
  Create, audit, improve, and apply visual design themes for the workspace —
  sourced from Claude Design bundles or presets. Audits cover contrast and accessibility, palette harmony, typography
  pairing, and completeness. Use this skill whenever the user mentions themes,
  brand colors, visual identity, or extracting styles, wants a consistent
  look-and-feel across outputs, or wants to review, fix, choose, or build a
  theme. Trigger phrases include "my theme feels off", "check contrast",
  "improve my colors", "what
  theme for my brand?", "help me pick a theme", "I need a visual identity for
  my startup", "make it match our brand", "use our company colors", "grab the
  style from that site", "brand guidelines", "design system", "brand identity",
  "visual standards", "author tokens", "build a tiered theme system", "deepen a
  theme", and "match the cogni-work pattern". Also triggers on a Claude Design
  bundle URL (api.anthropic.com/v1/design/h/...).
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Skill
---

# Manage Themes

## Why This Exists

Without centralized theme management, visual plugins each hardcode their own colors and fonts, producing inconsistent outputs. This skill provides a single place to create, store, audit, and apply themes so every visual output — slides, documents, diagrams, reports — shares a coherent brand identity. Themes are compact markdown files containing color palettes, typography, and design principles.

## Prerequisites

Before any operation, resolve the workspace themes directory:

1. Use `${COGNI_WORKSPACE_ROOT}/themes/` if the env var is set
2. Otherwise fall back to `{workspace}/cogni-workspace/themes/`
3. If the themes directory does not exist, create it (and `_template/` inside it) before proceeding

Themes are authored in Claude Design and imported as a bundle (Operation 10). If the user has no bundle, offer a theme-factory preset (Operation 5) or build a theme.md directly from colours and fonts they supply.

## Theme Storage

All themes live in the resolved themes directory. Each theme gets its own directory:

```
themes/
├── _template/theme.md    # Canonical template (see Theme File Format below)
├── digital-x/theme.md    # Brand theme
├── cogni-work/theme.md   # Brand theme
└── {custom}/theme.md     # User themes
```

When a theme slug already exists, ask the user whether to overwrite or create a versioned alternative (e.g., `acme-v2`).

## Operations

Operation numbers are stable identifiers, not a running sequence. The live-website and PPTX extraction paths that once held 3 and 4 were retired in favour of Operation 10, and every surviving operation keeps its original number so existing references stay valid — the gap is expected, not a missing section.

### 1. Recommend Theme

When the user asks for theme advice — e.g., "what theme for my brand?", "help me pick a theme", "I need a visual identity" — guide them through a short discovery to route them to the best creation path.

**Discovery questions** (ask only what's needed, skip what you can infer from context):

1. **Existing assets?** — "Do you have a website, PowerPoint template, or brand guidelines (colors/fonts) I can use as a starting point?"
2. **Industry & audience** — "What's the domain (fintech, healthcare, creative agency, etc.) and who sees these outputs?"
3. **Mood & tone** — "Any adjectives that describe the feel you're after? (e.g., bold & modern, calm & trustworthy, playful)"

**Routing logic based on answers:**

| User has... | Action |
|---|---|
| A Claude Design bundle URL (`api.anthropic.com/v1/design/h/<hash>`) | → **Operation 10** (Import from Claude Design Bundle) — the recommended authoring path; ships tokens, components, and assets in one re-syncable step |
| A website URL or a PPTX template | → **Operation 10** (Import from Claude Design Bundle) — recreate the source in Claude Design, then import the bundle |
| Specific colors/fonts but no file | → Create a custom theme.md directly from their inputs, following the template |
| Nothing concrete, just a description | → **Operation 5** (Create from Preset) — recommend 2-3 theme-factory presets that match their mood/industry, let them pick or blend |
| An existing workspace theme that's close | → **Operation 6** (Audit/Improve) — review it and suggest targeted tweaks |

After creating or selecting a theme, always run a quick audit (Operation 6) on the result before finalizing — this catches contrast issues and missing sections early. Then offer to generate a theme showcase (Operation 8) so the user can see all tokens in action.

### 2. List Themes

When the user asks to list or show available themes, scan the themes directory:

Use the Glob tool to find all themes:
```
pattern: "*/theme.md"
path: "${COGNI_WORKSPACE_ROOT}/themes"
```

Present each theme with its name (directory name) and first line description from the theme.md file.

### 5. Create Theme from Preset

Delegate to `document-skills:theme-factory` for preset theme creation:

1. Invoke the `theme-factory` skill to show available presets or create custom themes
2. Once user selects/creates a theme, capture the color palette and typography
3. Generate a theme.md following the template (see Theme File Format below)
4. Save to `{themes-dir}/{theme-slug}/theme.md`
5. Emit a starter `manifest.json` next to `theme.md` (see [Starter Manifest](#starter-manifest) below) and validate with `validate-theme-manifest.py` before completing
6. Offer to deepen this into a tiered theme system (Operation 7)
7. Offer to generate a theme showcase (Operation 8)

This bridges theme-factory's preset system with the workspace's theme storage.

### 6. Audit / Improve Theme

When the user wants feedback on an existing theme — e.g., "my theme feels off", "check my colors", "improve this theme" — read the theme.md and evaluate it across these dimensions:

**Contrast & Accessibility** — measured, never estimated. Build a flat `{"role": "#rrggbb"}` JSON map of the palette, then read the verdicts out of the script:

```bash
python3 cogni-workspace/scripts/check-contrast.py <palette.json>
```

Build the map from whichever source the theme actually has: `tokens/colors.json` when the theme is tiered, otherwise the `## Color Palette` bullets in its `theme.md` (`- **Role**: \`#RRGGBB\``). Write it to a scratch path such as `/tmp/<slug>-palette.json`.

Name the keys with the roles the script pairs on — surfaces `background` (or `bg`), `surface`, `surface-2`, `surface-dark`; text `text`, `text-light`, `text-muted`; and UI `primary`, `secondary`, `accent`, `accent-dark`, `accent-muted`, `border`, `link`, `success`, `warning`, `danger`, `info`. Map the theme's own labels onto them, so a bullet named "Card Surface" becomes `surface` and one named "Danger" stays `danger`. A label you leave unmapped forms no pair — but it is not lost, because the run names it back to you. Then:

- Report `data.pairs[]` as it stands — each entry carries `ratio`, `threshold`, `passes_aa_normal` (4.5:1), `passes_aa_large` (3:1), and the two `fg_luminance` / `bg_luminance` figures the ratio was computed from. Do not recompute or round any of them.
- Read `data.unclassified` on **every** run, before reporting anything. It lists the palette roles that parsed as colours but matched no role name above, so they formed no pair. Close each role it names either way: remap the key onto the vocabulary and re-run, or grade it explicitly with `--pair` / `--large-pair`. The field is computed from the whole palette at the start of the run, independent of which pairs were requested, so a role graded with `--pair` stays listed rather than dropping off. Judge completeness against the roles it names — not against its length, and not against how large `data.evaluated` is: never present a contrast result as complete while any role it names has been neither remapped nor explicitly graded.
- Read `data.collisions` on every run too. Each entry names two spellings that normalised onto one role — `Text` and `text` collapse to one — carrying the `superseded_key`, the `superseded_value` it held, and the `kept_key` that beat it. A non-empty list means fewer colours were graded than were written down, and which spelling won depends on key order in the file, so de-duplicate the source palette and re-run rather than trusting the survivor. The run still succeeds, because the verdicts it did produce are sound.
- Treat `passes: false` as the below-AA flag, and `data.failures` as the list to raise. A failing pair is a finding, not an error — the run still exits 0.
- Before raising a failure, check what the theme says the two roles are *for*. The script pairs every foreground with every surface, because a flat colour map carries no intent; the theme's own `## Color Palette` prose does ("Text Light — text on dark backgrounds", "Surface Dark — dark sections, hero bands"). A failure between two roles the theme never pairs — light text on a light surface, dark text on a dark one — is an artefact of the cross-product, and the luminances are the evidence for saying so. Report it as such rather than as a defect; do not silently drop it, and do not apply the reverse rule either, since a genuine finding can also sit between two light colours.
- Offer `suggested_hex` verbatim as the replacement value — the measured shade that clears. The script has already re-verified it against the threshold, so never substitute a hex of your own. At the two thresholds this CLI exposes, a failing pair always carries a suggestion, and it can be an extreme one: `#000000` or `#FFFFFF`, with the dark endpoint winning a tie where both would clear. When that is too extreme for the design, ask the user for a different colour or a different surface and re-run so the ratio stays measured. Read the key rather than assuming it: `suggested_hex` is still `null`-able in the JSON contract, for a caller driving the module strictly above ~4.583:1.
- When `data.evaluated` is 0, no pair could be formed — and the causes need opposite fixes. Read `data.unclassified` first: it names outright which colours came through under labels outside the vocabulary, so remap those keys and re-run. Only when `data.unparsed` lists them (present, but not `#rrggbb`) is the palette genuinely unusable and worth asking the user about.
- To grade a pair the defaults miss, name it: `--pair text:background` at 4.5:1, or `--large-pair accent:surface` at 3:1.
- On `success: false` the run produced no verdicts at all. Read `error`, fix the cause it names, and re-run. Never report a contrast verdict from a failed run.

**Palette Harmony**
- Check whether the palette follows a recognizable color scheme (complementary, analogous, triadic, split-complementary)
- Flag colors that feel disconnected — e.g., an accent that clashes with the primary
- Suggest adjustments that bring cohesion without losing brand identity

**Typography Pairing**
- Evaluate whether header and body fonts complement each other (contrast in weight/style without clashing)
- Flag if both fonts are the same family with no differentiation, or if a decorative font is used for body text
- Suggest alternatives from commonly available web/system fonts if pairing is weak

**Completeness**
- Compare against the template at `{themes-dir}/_template/theme.md`
- Flag missing sections (e.g., no Status Colors, no Design Principles, no Source)
- Flag palette roles that are absent — a theme needs at minimum: Primary, Background, Surface, Text

**Design Principles Review**
- Check whether the stated principles are actionable and specific enough for a downstream skill to follow
- Flag vague principles (e.g., "make it look good") and suggest concrete rewrites

**Output format**: Present findings as a checklist grouped by dimension, with pass/fail/warning per item and concrete suggestions for anything that fails. If the user agrees with suggestions, apply the fixes directly to the theme.md. After applying fixes, offer to regenerate the theme showcase (Operation 8) so the user can verify the changes visually.

**Manifest handling**: If the theme already has a `manifest.json`, leave it untouched (the audit fixes go in `theme.md`). If the theme is tier-0 and the audit surfaces structural needs that tokens would solve — e.g., the same hex repeats across many surfaces, downstream skills hard-code values that should swap by theme — offer to promote the theme via Operation 7 (Author a Deep Theme System) rather than expanding `theme.md` further. If the theme has neither a `theme.md` nor a `manifest.json` (rare — Op 6 mostly acts on existing themes), emit a starter `manifest.json` (see [Starter Manifest](#starter-manifest) below) so the next operation has an entry point.

### 7. Author a Deep Theme System

When a theme outgrows the single-file `theme.md` and the user wants structured authoring — variable swap-out by downstream skills, component primitives, voice/copy templates — promote the theme to a **tiered** layout per Theme System v2. This operation is opt-in: tier-0 themes (`theme.md` only, no manifest) remain valid forever.

**When to offer**: After a successful Operation 5 (ask: *"Want to deepen this into a tiered theme system?"*), or when the user explicitly asks to "build a deep theme", "author tokens", "make this brand a system", or "match the cogni-work pattern". The end-to-end walkthrough — when to migrate, what to keep, tier-by-tier authoring, manifest examples, validation, rollback, common pitfalls — lives at [`cogni-workspace/docs/theme-system-v2-migration.md`](../../docs/theme-system-v2-migration.md). Read that guide first when promoting a tier-0 theme; this operation is the in-skill entry point, the guide is the authoritative how-to.

**Reference implementation**: `themes/cogni-work/` is the canonical tiered theme. Read its `manifest.json` and `tokens/` layout before authoring any new tiered theme — that file shape is the contract every downstream consumer expects.

**The four tiers** — populate in this order; each tier is independently optional, but tokens is the foundation:

1. **Tier 1 — Tokens** (`tokens/`). Canonical design variables as flat JSON maps. Six canonical files: `colors.json`, `typography.json`, `spacing.json`, `radii.json`, `shadows.json`, `motion.json`. Each is a `{key: value}` map with primitive values (string, integer, or float — nested values are silently skipped in v1.0). Generate `tokens/tokens.css` deterministically from these JSON sources — never hand-edit the CSS:
   ```bash
   python3 cogni-workspace/scripts/generate-tokens-css.py \
       --tokens-dir <themes-dir>/<slug>/tokens --write
   ```
   The generator emits a single `:root { ... }` block with `--<stem>-<key>` custom properties in canonical-file then alphabetical-key order. Re-running it must produce a byte-identical file (idempotency check via `git diff --exit-code`).

2. **Tier 2 — Assets** (`assets/`). Brand-bound static files — logos (SVG preferred), reference fonts, sample documents, hero imagery. Flat layout is fine; nested directories are allowed where the asset family naturally groups (e.g., `assets/logos/`).

3. **Tier 3 — Components** (`components/`). Portable HTML primitives that downstream skills can copy-on-use — copy-on-use is the default, and an opt-in live-theme binding is reserved rather than implemented. JSX is allowed but optional; HTML is the contract. Both rules are settled in [`cogni-workspace/docs/theme-system-v2-migration.md`](../../docs/theme-system-v2-migration.md). Each component is one file; reference the theme's tokens via CSS custom properties (e.g., `var(--colors-primary)`) so consumers inherit the active palette without rewriting markup.

4. **Tier 4 — Templates** (`templates/`). Voice-and-copy scaffolds — IS/DOES/MEANS messaging templates, headline patterns, CTA wording. Deferred — the directory is reserved but most themes will not populate it yet; see [`cogni-workspace/docs/theme-system-v2-migration.md`](../../docs/theme-system-v2-migration.md).

**Manifest update**: Each tier you populate gets a corresponding entry in `manifest.json`. The `tiers` map is the contract — `discover-themes` and downstream consumers route exclusively through it:

```json
{
  "schema_version": "1.0",
  "name": "<Theme Name>",
  "slug": "<theme-slug>",
  "tiers": {
    "tokens": "tokens/",
    "assets": "assets/",
    "components": "components/"
  }
}
```

Reserved keys `live`, `live_within_session`, and `copy` must never appear at any nesting depth (the validator hard-fails on them).

**Validate before completing**: Always run the validator after touching a tiered theme — it checks schema conformance, that declared tier paths exist, and (when `tokens.css` is present) that it matches `generate()` byte-for-byte:

```bash
python3 cogni-workspace/scripts/validate-theme-manifest.py <themes-dir>/<slug>
```

A non-zero exit means the theme is not shippable; fix the failure before declaring the operation complete.

**Workflow** (typical promotion of an existing tier-0 theme):

1. Read the existing `theme.md` to extract palette, typography, and design principles.
2. Create `tokens/`; split the palette into `colors.json`, fonts into `typography.json`, and any spacing/radii/shadow/motion values into the corresponding canonical files.
3. Run `generate-tokens-css.py --write` to emit `tokens.css`; verify the diff is what you expect.
4. Update `manifest.json` to declare `tiers.tokens: "tokens/"`.
5. Optionally populate `assets/` and `components/` — only what the user actually needs.
6. Run `validate-theme-manifest.py` and confirm `success: true`.
7. Offer to regenerate the theme showcase (Operation 8) so the tokens render against the canonical primitives.

### 8. Generate Theme Showcase

After creating, importing, or improving a theme, offer to generate an interactive React showcase component that demonstrates every design token in context — colors, typography, buttons, cards, tables, forms, status badges, KPI panels, pricing layouts, and navigation patterns.

**When to offer**: After any successful theme creation, deepening, update, or bundle import (Operations 5–7 and 10), ask the user: *"Want me to generate a theme showcase component so you can see all the tokens in action?"*

**Workflow**:

1. Read the theme.md for the target theme
2. Generate a self-contained JSX file that renders every palette color, typography scale, button variant, card layout, status badge, data table, form element, and at least one dark-section/light-section pair — all wired to the theme's actual hex values, fonts, and design principles
3. Save to `{themes-dir}/{theme-slug}/{theme-slug}-theme-showcase.jsx`

**Output requirements**:

- Single-file React component using inline styles (no external CSS) — works in any React sandbox or claude.ai artifact
- A `theme` object at the top mapping every palette role (primary, secondary, accent, accentMuted, accentDark, bg, surface, surfaceDark, text, textLight, textMuted, border, plus status colors) to the hex values from theme.md
- Google Fonts link injected at runtime for the theme's font families
- Sections: Hero (dark), Color Palette grid, Typography scale, Buttons & interactions (toggle, slider), Navigation & Tabs, Cards, Status Badges + Data Table (dark), KPI Dashboard, Form Elements, Pricing example (dark), Footer
- Interactive elements using `useState` (tabs, toggle, slider, card selection) to show the theme in motion
- Design principles from the theme.md reflected in visual structure (e.g., dark-light rhythm, accent usage rules)
- The component name follows PascalCase of the theme slug (e.g., `cogni-work` → `CogniWorkThemeShowcase`)

**Reference**: See `themes/cogni-work/cogni-work-theme-showcase.jsx` as the canonical example of quality, structure, and completeness.

### 9. Apply Theme

When the user asks to apply a theme, read the theme.md and feed its contents into the downstream skill that produces the output.

1. Read the requested theme from `{themes-dir}/{name}/theme.md`
2. If the user hasn't specified which artifact to theme, ask them (e.g., "Apply this to which output — slides, a document, a diagram?")
3. Include the full theme.md content in the prompt/context when invoking the downstream skill. The consuming skill needs the raw color hex codes, font names, and design principles to apply them. For example:
   - **Slides** (`document-skills:pptx`): pass theme colors and fonts so they map to slide master styles
   - **Documents** (`document-skills:docx`): pass palette for heading colors, accent boxes, table styling
   - **Diagrams** (e.g., `cogni-workspace:story-to-infographic`): pass primary/secondary/accent colors and design principles
   - **Web/HTML outputs** (e.g., `cogni-workspace:enrich-report`): pass full palette and typography for CSS variable mapping

The theme.md content is the single source of truth — always read it fresh rather than relying on cached or partial values.

### 10. Import from Claude Design Bundle

The recommended authoring path for tiered themes under Theme System v2. The user authors a complete design system in Claude Design (claude.ai/design) — tokens, components, assets, and theme.md prose — then exports a handoff bundle at `https://api.anthropic.com/v1/design/h/<hash>`. This operation materialises the bundle into a Theme System v2 theme directory in one re-syncable step.

**Why this replaced the live website and PPTX extraction paths**: Claude Design is the authoring tool; this operation is the importer. The bundle ships a complete tiered theme — tokens (canonical JSON + generated CSS), HTML component primitives, deck primitives, and brand assets — that older operations could only produce piecemeal at tier-0. Re-running the importer is idempotent: the bundle is the upstream truth, the local theme directory is the materialised mirror.

**Prerequisites**:
- A Claude Design bundle URL (the user gets one from claude.ai/design at the end of an authoring session). The URL is a stable handle for that bundle version — re-exporting produces a new URL.
- The bundle's `project/{slug}-theme.md` ideally contains a `## Voice & Copy Guidelines` section (the Theme System v2 Phase D structural contract checks the header exists). If the section is missing, the importer auto-injects a clearly-tagged stub so the import still succeeds and the backcompat harness still passes. Real voice content always beats the stub — re-author the bundle with a structured voice section and re-import with `--allow-overwrite` to replace the stub.

**Workflow**:

1. Ask for the Claude Design bundle URL (or path to a local `.tar.gz` for testing). Confirm the target theme slug — typically derived from the bundle's root directory `{slug}-design-system/`.
2. Resolve the target theme directory: `{themes-dir}/{slug}/`. If the directory already exists and is non-empty, ask the user to confirm overwrite (the operation passes `--allow-overwrite` to the importer).
3. Run the importer:
   ```bash
   python3 cogni-workspace/scripts/import-claude-design-bundle.py \
       --url <bundle-url> --target <themes-dir>/<slug> [--allow-overwrite]
   ```
   For testing or air-gapped flows, swap `--url` for `--bundle <path>` against a local `.tar.gz`. Use `--dry-run` to preview what would be written without touching the target.
4. Inspect the JSON envelope. The importer reports the materialised slug, sha256 of the bundle, populated tiers, allowlisted components written, specimens skipped, components warned-about (preview files matching no rule — review and either extend the allowlist in `references/claude-design-bundle-mapping.md` or accept the skip), assets, and the validator payload.
5. The importer runs `validate-theme-manifest.py` itself before writing the `.claude-design-source` sidecar — a successful import means the theme is already schema-valid. Then run `bash cogni-workspace/scripts/verify-theme-backcompat.sh` to confirm the broader integration contract (Phase A discover, Phase B consumer references, Phase D voice section).
6. Offer to regenerate the theme showcase (Operation 8) so the new tokens render against the canonical primitives. Operation 7 (deep theme authoring) is unnecessary after Op 10 — the bundle ships tiered already.

**Re-syncability**: When the user re-exports the bundle from Claude Design (e.g., after iterating on the design), they get a new URL. Re-run the importer with the new URL and `--allow-overwrite`; the materialised theme refreshes from upstream. Idempotency is preserved at the sha256 level — running the importer against an unchanged URL is a no-op.

**Mapping details**: The bundle → theme materialisation rules (which preview files become components, how `colors_and_type.css` projects into the six canonical token JSON files, which bundle directories are ignored) live in `cogni-workspace/references/claude-design-bundle-mapping.md`. Edits to that mapping doc are the right place to extend or constrain importer behaviour; the script reads its rules from there as the source of truth.

**Cogni-work canary status**: The first cogni-work bundle export (2026-04-25) omits a structured `## Voice & Copy Guidelines` section, so the auto-inject policy in Prerequisites applies — the import succeeds with a clearly-tagged stub inserted before `## Source`, and the result passes Phase D of `verify-theme-backcompat.sh`. Replacing that stub with real voice content follows the same re-author-and-re-import remedy stated there.

## Theme File Format

Follow the template at `{themes-dir}/_template/theme.md`. Key sections:

- **Color Palette**: 6-12 colors with hex codes and usage descriptions
- **Status Colors**: Success, Warning, Danger, Info (standardized)
- **Typography**: Header, Body, Mono fonts with fallbacks
- **Design Principles**: 3-8 rules for visual consistency
- **Best Used For**: Target contexts
- **Source**: Origin (Claude Design bundle URL, preset name) and import date

## Starter Manifest

Operations 5 and (conditionally) 6 emit a minimal `manifest.json` next to `theme.md` for every newly-created theme. The file is the entry point that lets a tier-0 theme opt in to Theme System v2 later (via Operation 7) without renaming or restructuring anything that already shipped:

```json
{
  "schema_version": "1.0",
  "name": "<Theme Name>",
  "slug": "<theme-slug>",
  "tiers": {}
}
```

- `schema_version` is always `"1.0"` for now — it pins the file to the current `references/theme-manifest.schema.json`.
- `name` is the human-readable theme name (e.g., `"Cogni Work"`).
- `slug` matches the directory name (kebab-case, see [Naming Convention](#naming-convention) below).
- `tiers` starts empty (`{}`); tiers are added by Operation 7 only when the user explicitly populates them.

Operation 5 finishes by running `python3 cogni-workspace/scripts/validate-theme-manifest.py <themes-dir>/<slug>` to confirm the manifest is schema-valid before the operation reports success.

**Backwards-compat:** `_template/` and any pre-existing tier-0 theme without a manifest stay valid forever — Operation 6 (Audit/Improve) preserves the manifestless layout unless the user explicitly asks to promote via Operation 7.

## Naming Convention

Theme directories use kebab-case slugs derived from the brand/source name:
- `digital-x` (from DIGITAL X brand)
- `cogni-work` (from cogni-work.ai)
- `ocean-depths` (from theme-factory preset)
- `client-acme` (from client brand name)

## Additional Resources

### Template

- **`{themes-dir}/_template/theme.md`** — Canonical theme template with all sections. Read this template before generating any new theme to ensure all required sections are present.
- **`{themes-dir}/cogni-work/cogni-work-theme-showcase.jsx`** — Reference showcase component. Read this before generating a showcase for a new theme to match the expected quality, structure, and section coverage.
