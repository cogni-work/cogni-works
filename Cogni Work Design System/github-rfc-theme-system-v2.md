# RFC: Theme System v2 — Structured theme directories with tokens, components, and templates

> **Status:** Discussion / RFC
> **Type:** Architecture proposal
> **Pilot:** `themes/cogni-work/` (companion design system already exists; ready to drop in as reference implementation)
> **Related:** [Issue: Deepen the `cogni-work` theme] — Phase 1 of this two-phase migration; lands additive content into the existing `theme.md` format and is fully backwards-compatible.
> **Superseded in part (2026-08-28):** `manage-themes` Operations 3 (Grab Theme from Website) and 4 (Grab from PPTX) were retired in favour of Operation 10 (Import from Claude Design Bundle) — see `cogni-workspace/skills/manage-themes/SKILL.md` § Operations. Operation numbers in the Phase 2 list, the impact table, and the authoring recommendations below are as written at authoring time and are kept unchanged as a record of what this RFC proposed. Only the tier-0 authoring paragraph under "Authoring themes" is corrected below, because it describes today's workflow in the present tense.

---

## TL;DR

Today, every theme in `cogni-workspace/themes/` is a single `theme.md` file. The format is human-readable, regex-parsed by `discover-themes.py`, and read into prompts as text. This works for **palette**, **font families**, and **design philosophy** — but cannot carry **structured tokens** (spacing, radii, shadows, motion), **components** (buttons, cards, slide templates), or **assets** (logos, icons, fonts). Skills that produce themed output therefore reinvent these every time, and brand drift is inevitable.

This RFC proposes evolving themes from "single markdown file" to "structured directory" — a *theme system* with optional tiers: tokens (JSON + CSS), components (JSX/HTML snippets), templates (full-page scaffolds), and assets (logos, icons, fonts). `theme.md` remains the canonical prose summary humans and LLM prompts consume; the new tiers are machine-readable extensions.

The migration is **opt-in and backwards-compatible** via an optional `manifest.json`. Themes without a manifest behave exactly as today.

---

## Motivation

While building a deep design system for the `cogni-work` brand (tokens as CSS vars, two UI kits with React components, a 7-slide deck template, preview cards, asset library, voice guidelines), three structural limits in the current theme model became visible:

### 1. Markdown can't carry structured data well

Spacing scales, radii, shadow definitions, motion tokens, type scales — these are key-value tables. Encoding them as markdown bullets means every consumer regex-parses prose, which is fragile. Phase 1 of this migration adds them as bullet sections to `theme.md`; Phase 2 promotes them to first-class JSON.

### 2. Components can't live in `theme.md` at all

A "Hero" or "KPI tile" or "title slide" is structured markup, not prose. Today, skills like `cogni-visual` or `cogni-portfolio` synthesize these from theme.md prompts — every skill reinventing the same card, button, tile in slightly different ways. The chartreuse selection ring described in `theme.md` Design Principles rarely makes it into actual output, because every skill reimplements cards from scratch.

### 3. Showcase JSX is invisible to discovery and to non-React skills

`themes/cogni-work/cogni-work-theme-showcase.jsx` *has* the components, the spacing, the motion — but `discover-themes.py` only reads `theme.md`, and skills that produce HTML/PPTX/Markdown output can't lift JSX components anyway. The showcase becomes a visual demo, not a source of truth.

### Symptoms

- The flagship `cogni-work` theme.md is currently shallower than `telekom-tsc` and `deutsche-telekom` (no type scale, no font embed snippet) — Phase 1 fixes this.
- Three themes exist; none specify spacing, radii, shadows, or motion tokens.
- Every visual skill that consumes themes hardcodes its own component primitives.
- Onboarding a new client brand currently means writing prose and hoping skills synthesize a coherent identity from it.

---

## Proposed architecture

### Directory layout

```
themes/cogni-work/
  theme.md                      # canonical brand spec (existing — required)
  manifest.json                 # tier index (new — optional)
  showcase.jsx                  # visual reference (existing — optional)

  tokens/                       # tier 1: structured tokens
    colors.json                 # palette as machine-readable
    typography.json             # families, scale, tracking, line-heights
    spacing.json                # 4pt scale
    radii.json
    shadows.json
    motion.json
    tokens.css                  # generated CSS-var bundle, @import-able

  assets/                       # tier 2: brand assets
    logo/
      mark.svg                  # primary brand mark
      mark-light.svg            # variant for dark backgrounds
      wordmark.svg
    icons/                      # if a branded icon set exists
    fonts/                      # if self-hosting (else just CDN URL in tokens)

  components/                   # tier 3: reusable composition primitives
    web/                        # marketing-site primitives
      Card.jsx
      Button.jsx
      MetricTile.jsx
      Eyebrow.jsx
    deck/                       # slide composition primitives
      title-slide.html
      content-slide.html
      metrics-slide.html
      cta-slide.html
    dashboard/                  # app-surface primitives
      KpiCard.jsx
      DataTable.jsx

  templates/                    # tier 4: full-page scaffolds
    deck.html                   # blank deck shell wired to tokens
    report.html
    landing-page.html
    dashboard.html
```

### `manifest.json` schema

```json
{
  "schema_version": "1.0",
  "name": "Cogni Work",
  "slug": "cogni-work",
  "tiers": {
    "tokens": "tokens/",
    "assets": "assets/",
    "components": {
      "web": "components/web/",
      "deck": "components/deck/",
      "dashboard": "components/dashboard/"
    },
    "templates": {
      "deck": "templates/deck.html",
      "report": "templates/report.html",
      "landing": "templates/landing-page.html",
      "dashboard": "templates/dashboard.html"
    }
  },
  "showcase": "showcase.jsx",
  "voice_ref": "theme.md#voice--copy-guidelines"
}
```

### Tier semantics

| Tier | Required? | Consumers |
|---|---|---|
| **`theme.md`** | ✅ Required | Every skill (palette, voice, philosophy) — current behavior preserved |
| **`tokens/`** | Optional | Skills producing HTML/CSS/PPTX (lift exact values for spacing, radii, etc.) |
| **`assets/`** | Optional | Any skill that needs the logo or branded iconography |
| **`components/`** | Optional | Visual skills (slides, dashboards, web pages) — copy/lift component snippets |
| **`templates/`** | Optional | Skills generating full pages/decks — start from a wired-up scaffold |

A theme without a `manifest.json` is treated as "tier 0 only" — same as today's themes. `discover-themes.py` keeps working unchanged.

### Component contract (proposed)

To prevent the "who owns the Nav component" question:

- Themes ship **primitives**: Card, Button, MetricTile, Eyebrow, KpiCard, DataTable, slide templates.
- Themes do **not** ship **compositions**: Nav, Hero, full landing pages — those stay with surface plugins (`cogni-website`, `cogni-portfolio`) and consume theme primitives.
- Rule of thumb: if a component appears in 3+ surface plugins, it's a primitive. If it's specific to one product surface, it lives with the plugin.

---

## Migration strategy

### Phase 1 (already proposed — separate issue)

Deepen `cogni-work/theme.md` with type scale, spacing/radii/shadow/motion sections, voice guidelines, font embed snippet. Strictly additive. **No code changes.** Establishes which content is universal enough to promote to JSON in Phase 2.

### Phase 2 (this RFC)

1. **Define `manifest.json` schema and validate via JSON Schema.** Ship a validator script in `cogni-workspace/scripts/`.
2. **Update `discover-themes.py`** to read `manifest.json` if present, falling back to current regex parsing of `theme.md`. Output gains an optional `tiers` field listing what's available.
3. **Pilot: convert `cogni-work/`** to the new structure using the existing companion design system as the source. This is mostly a copy-paste — the work is done.
4. **Update `manage-themes` SKILL.md**: Operations 3–6 (create/extract/audit) emit a manifest + tokens by default. Operation 7 (showcase) auto-generates from tokens.
5. **Document migration path for `deutsche-telekom` and `telekom-tsc`** as separate follow-up issues. Themes can stay in tier-0 form indefinitely; migration is opt-in.
6. **Add a primitives library to `cogni-visual`, `cogni-portfolio`, `cogni-website`** that resolves theme components: `loadComponent('cogni-work', 'web', 'Card')`. Skills stop hardcoding primitives.

### Backwards compatibility

- Themes without `manifest.json` work exactly as today — `pick-theme`, `manage-themes`, all downstream skills unchanged.
- Themes with `manifest.json` add capabilities; consumers that don't know about manifests ignore them.
- `theme.md` remains the canonical brand spec for prompt context — nothing replaces it.

---

## Impact on existing skills

| Skill | Change required | Effort |
|---|---|---|
| `pick-theme` | Read `manifest.json` if present; surface `tiers` in the picker description (optional) | XS |
| `discover-themes.py` | Add manifest.json read + new optional fields in JSON output | S |
| `manage-themes` | Update Operations 3–6 to emit tokens/manifest by default; Operation 7 auto-generates from tokens | M |
| `cogni-visual` (render-big-picture, render-big-block, slide generators) | Add component-loader util; consume primitives instead of synthesizing | M |
| `cogni-portfolio` (portfolio-dashboard) | Same as cogni-visual | S |
| `cogni-website` | Optional: refactor to consume theme primitives | M |
| `cogni-narrative`, `cogni-sales`, `cogni-research`, `cogni-copywriting` | None — these consume `theme.md` voice/palette only | none |
| `document-skills:pptx`, `:docx` | Optional: read tokens.json instead of regex-parsing theme.md | S |

Total: small per-skill, but adds up across the ecosystem. Mitigation: each skill migrates independently; no big-bang.

---

## Open questions

### 1. Is `tokens/tokens.css` generated or hand-maintained?

**Option A:** Hand-maintained — author edits `tokens.css` directly; JSON files are generated from it.
**Option B:** JSON is canonical — `tokens.css` generated from `colors.json` etc. via a build step.
**Option C:** Both hand-maintained, validator ensures parity.

Recommendation: **Option B** — JSON is canonical (machine-readable, queryable, validatable), CSS is a generated artifact. Removes the parity problem.

### 2. How are components versioned?

If `cogni-visual` lifts `themes/cogni-work/components/deck/title-slide.html` and the theme later changes that component, downstream usage breaks silently. Options:

- **Pin via manifest version** (`schema_version: "1.0"`) and require components to be backwards-compatible within a major version.
- **Components are copy-on-use** — skills snapshot at generation time, no live link.
- **No versioning** — accept that updating the theme updates downstream output (often desirable for brand consistency).

Recommendation: copy-on-use as default, with an opt-in "live theme" mode for surfaces that want to track brand updates.

### 3. Component format: JSX, HTML, or both?

- **HTML snippets** are universal — any skill can splice them.
- **JSX components** are richer (props, state) but only React surfaces consume them.
- **Both** doubles the maintenance.

Recommendation: **HTML for portable primitives** (slides, cards, sections), **JSX optional** for app-surface components. Themes that produce HTML-only outputs only need to maintain HTML.

### 4. Should `themes/` be renamed?

A directory containing tokens, components, assets, and templates is more than a "theme" — it's a brand or design system. Options:

- Leave `themes/` and expand its meaning (zero migration).
- Rename to `brands/` or `design-systems/` (clearer naming, breaks every reference).
- Add a parallel `brands/` directory and deprecate `themes/` over time.

Recommendation: **leave `themes/`**. The directory name is a minor concern; semantics matter more than naming.

### 5. Where do voice/copy templates live?

Voice rules are in `theme.md` Voice section (Phase 1). But concrete copy templates ("CTA patterns," "section opener formulae," "BLUF templates") could be a tier of their own:

```
themes/cogni-work/copy/
  cta-patterns.md
  bluf-templates.md
  section-openers.md
```

This is more aligned with `cogni-copywriting` than visual rendering. Could be deferred to a Phase 3.

### 6. How does this interact with `insight-wave-pro` (private marketplace)?

`pick-theme` already merges standard + workspace themes. `insight-wave-pro` plugins consume themes via the same picker. A theme system in `cogni-workspace` benefits the entire marketplace ecosystem; private plugins gain access to richer themes for free. No changes to pro/private plugins required.

---

## Reference implementation

The companion design system project I just built for the `cogni-work` brand is **already structured along these tier boundaries**:

```
cogni-work-design-system/
  README.md                     # → theme.md voice + visual foundations content
  colors_and_type.css           # → tokens/tokens.css (becomes JSON in Phase 2)
  assets/logo/mark.svg          # → assets/logo/mark.svg
  assets/icons/deck/*.png       # → assets/icons/deck/*.png
  preview/*.html                # → components/web/*.html primitives
  ui_kits/website/*.jsx         # → components/web/*.jsx (after splitting compositions out)
  ui_kits/plugin/*.jsx          # → components/dashboard/*.jsx
  slides/index.html             # → templates/deck.html + components/deck/*.html
  slides/deck-stage.js          # → templates/deck-shell.js (optional runtime)
```

In other words, the work is largely done. Approving this RFC means **moving** content from the design-system project into `themes/cogni-work/` as the pilot.

---

## Authoring themes

The theme directory is the contract. How you produce its contents is up to you.

**For tier-0 themes** (palette + fonts + voice prose), `manage-themes` in Claude Code remains the recommended path. Its Claude Design bundle import (Operation #10) and preset-blending (Operation #5) operations produce excellent `theme.md` files in minutes. No change to today's workflow.

**For tier-1 themes** (+ structured tokens), `manage-themes` will be extended to emit `tokens/*.json` alongside `theme.md`. Hand-authoring is also straightforward — token JSON is human-readable, and a designer with a Figma tokens export or a CSS variables file can produce it directly.

**For tier-2 and above** (+ assets, components, templates), a visual authoring environment becomes valuable. Components are fundamentally a design exercise: layout, hierarchy, motion, edge cases, content placeholders, dark/light variants. Hand-writing them blind from a prose brief is hard; iterating on them visually is easy. Any tool that can produce HTML/JSX, SVG assets, and structured tokens will work — examples include design canvases in Claude.ai, Figma with a dev-handoff workflow, or any visual prototyping environment that exports clean code. **The directory structure is the contract; the tool is your choice.**

**Provenance of the `cogni-work` reference implementation:** the populated design system used to seed this RFC was authored across iterative sessions in Anthropic's Claude.ai design canvases — tokens, two UI kits (website + plugin surface), a 7-slide deck template, preview cards, asset library, and voice guidelines. It is contributed as a directory of files; the tool used to produce it is incidental and replaceable. Any future contributor producing a similarly-structured theme directory is equally welcome regardless of how they authored it.

**Recommendation for the `manage-themes` skill update:** when implementing Phase 2's update to `manage-themes`, document these authoring paths in the SKILL.md "Operations" section so users know which path matches their depth ambition. Specifically:
- Operations #3–#5 (extract / preset) emit tier-0 + tier-1 by default.
- A new Operation should be added: *"Author a deep theme system"* — points users to a visual design environment, lists the directory structure they need to produce, and (when complete) validates the contributed directory against the manifest schema.

---

## Acceptance criteria for Phase 2

- [ ] `manifest.json` schema documented and JSON-Schema validated.
- [ ] `discover-themes.py` reads `manifest.json` when present; existing tier-0 themes (`telekom-tsc`, `deutsche-telekom`) still discovered with no regression.
- [ ] `cogni-work` migrated to full tiered structure as reference implementation.
- [ ] At least one downstream skill (proposed: `cogni-visual:render-big-block`) refactored to consume tier-1 tokens and tier-3 component primitives, demonstrating end-to-end brand fidelity.
- [ ] `manage-themes` SKILL.md updated to describe tier emission for create/extract operations.
- [ ] Migration guide in `cogni-workspace/docs/` for converting tier-0 themes to tiered themes.
- [ ] Backwards compat verified: themes without manifests behave identically to today.

---

## Why now / why this is the right time

Three reasons this RFC is timely:

1. **The cogni-work design system already exists in tiered form** — adopting it as the pilot has effectively zero design cost.
2. **Phase 1 (deepening `theme.md`) is the right preview** — it surfaces which content is universal enough to promote to JSON, and reveals exactly where markdown stops scaling.
3. **The marketplace is growing.** Every new plugin that produces visual output (`cogni-website`, `cogni-portfolio`, future plugins) reinvents primitives from `theme.md` prose. The cost of *not* doing this scales linearly with plugin count.

The smaller the ecosystem, the cheaper the migration. The bigger it gets, the more skills hardcode their own component vocabularies and the harder this gets later.

---

## Asks

1. **Approve the tier model** (`tokens/` / `assets/` / `components/` / `templates/`) and `manifest.json` schema.
2. **Approve the migration path** (opt-in, backwards-compatible, `cogni-work` as pilot).
3. **Decide on the open questions** (token format, component versioning, component format, naming, copy tier, scope).

If approved, I'll open follow-up issues to:
- Implement the manifest schema + discover-themes.py changes
- Migrate `cogni-work/` to tiered structure (largely a copy-paste from the design system project)
- Refactor one pilot consumer skill (suggest `cogni-visual:render-big-block`) end-to-end
- Document migration path for the other two existing themes
