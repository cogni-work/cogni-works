# Render Hand-off

What story-to-slides Step 11 tells the user once the brief is written and validated — two attachment boxes, one per render path. Handoff A is the PPTX path via claude.ai chat, with the prompt and why that path is preferred over rendering inside Claude Code. Handoff B is the Claude Design path, which consumes the `presentation-outline.md` that `scripts/brief-to-outline.py` exports from the brief.

## Handoff A — PPTX (claude.ai chat)

After the brief is written and validated, tell the user:

1. **Open a new chat on claude.ai** (not Claude Code — the PPTX skill works best in the claude.ai web interface)
2. **Paste these two files** into the chat window as attachments:
   - `presentation-brief.md` (the brief you just generated)
   - `theme.md` (the theme file used in this workflow)
3. **Use this prompt:**

```
Please create a PPTX presentation using the attached presentation-brief.md and theme.md
```

Print the absolute paths to both files so the user can locate them easily:

```
─── Files to attach in claude.ai ───

Presentation brief: {absolute_path_to_presentation_brief}
Theme:              {absolute_path_to_theme_md}

Open claude.ai → new chat → attach both files → paste the prompt above.
─────────────────────────────────────────────────
```

Replace `{absolute_path_to_presentation_brief}` with the resolved `output_path` and `{absolute_path_to_theme_md}` with the `theme_path` from Step 1. Both paths **printed to the user** must be absolute — never use `~`, `$HOME`, `$CLAUDE_PLUGIN_ROOT`, or relative paths. That governs printed handoff paths only; `$CLAUDE_PLUGIN_ROOT` remains the correct way to invoke a bundled script.

**Why claude.ai?** The web interface handles file attachments natively, which is what makes the PPTX skill render best there. Claude Code can also render via the `document-skills:pptx` skill — a working fallback, not the recommended path.

## Handoff B — Outline (claude.ai/design)

Claude Design consumes a prompt plus attachments against an organization design system, and it has no meaning for the brief's `Layout:` vocabulary (`title-slide`, `is-does-means`, `four-quadrants`, ...) — handed the brief unchanged it re-derives the structure and paraphrases copy the client already approved. Step 11 therefore exports `presentation-outline.md` next to the brief with `scripts/brief-to-outline.py`, and once the exporter's envelope reports `success: true`, prints this second box:

```
─── File to attach in claude.ai/design ───

Presentation outline: {absolute_path_to_presentation_outline}

Hand the outline to Claude Design at claude.ai/design — the organization
design system applies, so attach theme.md only when none is configured.
──────────────────────────────────────────
```

Replace `{absolute_path_to_presentation_outline}` with the exporter's `data.outline_path`. As above, the printed path must be absolute — never `~`, `$HOME`, `$CLAUDE_PLUGIN_ROOT`, or relative. On `success: false`, report the `error`, skip this box, and still deliver Handoff A — a failed outline export degrades the handoff, it does not invalidate the brief.

### What the outline carries

The outline is written in the shape `libraries/presentation-intent.md` defines. It gives Claude Design what it does read:

| Element | Source |
|---------|--------|
| `design:` block | the brief's frontmatter, verbatim |
| `key_figures` | every `Hero-Stat-Box.Number` and stat-mode `Quadrant-N.Number`, each marked `(src: [N])` when its slide carries a numbered `<sup>[N](url)</sup>` citation — a bare `Source:` line alone produces no marker |
| `climax` | the slide whose `intent.emphasis` is `climax`, rendered with its headline |
| one `## ` section per slide | `title`, a `type` tag, `slide_points` (on-slide copy, max four lines), `talk_track` (the first `>>`-headed speaker-notes section) and `notes` (the second, plus `Source`). The split is ordinal on the `>>` prefix, so it holds no marker literal and works in either language |
| trailing `note:` lines | the three meta-instructions the renderer must honour |

Slides marked `Slide-Kind: internal-prep` (Methodology, Buying Center) are excluded unless `--include-internal` is passed.

**Copy is frozen.** Every `slide_points` line is an on-slide leaf reproduced verbatim, with `<sup>[N](url)</sup>` reduced to a bare `[N]`; the exporter never re-summarises. `cogni-workspace/tests/test-brief-to-outline.sh` asserts that as a substring check against the source brief.

**One file owns the layout-to-type mapping.** The exporter holds no layout name and no tag string as a literal — it parses the `## Layout to type mapping` table out of `libraries/presentation-intent.md` at run time, so the library keeps sole authority and the two cannot drift. Reshaping that table breaks the export.
