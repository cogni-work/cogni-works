---
name: cogni-work-design
description: Use this skill to generate well-branded interfaces and assets for Cogni Work (cogni-work.ai / insight-wave), either for production or throwaway prototypes, mocks, decks, and design artifacts. Contains the essential design guidelines, colors, type, fonts, assets, and UI kit components needed to prototype or ship in-brand.
user-invocable: true
---

# Cogni Work · Design Skill

Read the `README.md` file within this skill, and explore the other available files — this skill is self-contained and ships with everything you need.

## What's inside

- `README.md` — brand context, content fundamentals, visual foundations, iconography, and an index of this folder. **Start here.**
- `voice-and-copy.md` — canonical voice & copy guidelines. The three-register system, frameworks (BLUF/Pyramid/SCQA), microcopy, do/don't rewrites, bilingual EN/DE, vocabulary, and a 10-second pre-ship checklist. Read before writing any user-facing copy.
- `Voice and Copy Guidelines.html` — single-page browsable index of all voice specimens.
- `colors_and_type.css` — all design tokens as CSS variables plus semantic element defaults. Import as `<link rel="stylesheet" href="colors_and_type.css">` or `@import` it.
- `assets/` — logo mark and icons. The brand mark is a chartreuse triangle at `assets/logo/mark.svg` (and as a reusable React component `ui_kits/shared/Mark.jsx`). Solid-silhouette deck icons live in `assets/icons/deck/`.
- `preview/` — small isolated HTML specimens for every token cluster (colors, type, spacing, components, brand). Use these as visual references when composing new surfaces.
- `slides/` — a 7-slide deck template (`slides/index.html`) built on `deck-stage.js`. Use it as the shape for any new deck; copy a slide pattern rather than reinventing one.
- `ui_kits/website/` — the cogni-work.ai marketing site kit (Nav, Hero, CapabilitySection, MetricsBand, AudienceTabs, CTAFooter).
- `ui_kits/plugin/` — the plugin-workspace kit (dark sidebar, plugin detail, run terminal).
- `raw/` — source material copied in: the original pptx and extracted deck images. Useful if you need asset provenance.

## How to use it

**If you're creating visual artifacts** (slides, mocks, throwaway prototypes, marketing pages):
- Copy the assets you need out of `assets/` and compose static HTML that links `colors_and_type.css`.
- For a deck, copy `slides/deck-stage.js` + one of the slide patterns in `slides/index.html`.
- For a web surface, start by picking the right building block in `ui_kits/website/*.jsx` and compose.
- Never invent new colors, icons, or typefaces — the system is small on purpose.

**If you're working on production code**, read the `README.md` and `colors_and_type.css` to become an expert in the brand, then author against your real stack using the same tokens and the same restraint.

## If the user invokes this skill without guidance

Ask what they want to build or design. Some good opening questions:
- Is this a deck, a web page, a report, a product UI, or something else?
- Who's the audience — internal team, prospective customers, investors, partners?
- Rough scope — one screen, a flow, a 10-slide deck?
- Do they want tweakable variations, or one focused output?

Then act as an expert designer who outputs HTML artifacts **or** production code, depending on the need. Respect the brand's restraint: one accent colour, no gradients, no emoji, mono eyebrows in UPPERCASE, DM Sans everywhere else, warm whites on `#111` anchors. When in doubt, do less.
