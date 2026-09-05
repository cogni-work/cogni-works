# Render Hand-off

What story-to-slides Step 11 — the Render checkpoint — prints and dispatches once the brief is written and validated. The checkpoint offers one path per renderer; each path below carries its box text, its prompt where one exists, and the rule for resolving a theme. The theme is a render-time parameter: the producer records a caller-supplied `theme_path` verbatim and never prompts for one, so a path that needs a theme resolves it here and a path that does not never asks.

## Before the question: export the outline

Claude Design consumes a prompt plus attachments against an organization design system, and it has no meaning for the brief's `Layout:` vocabulary (`title-slide`, `is-does-means`, `four-quadrants`, ...) — handed the brief unchanged it re-derives the structure and paraphrases copy the client already approved. Step 11 therefore exports `presentation-outline.md` next to the brief with `scripts/brief-to-outline.py` before asking anything, on every path, interactive or not:

```bash
python3 "$CLAUDE_PLUGIN_ROOT/skills/story-to-slides/scripts/brief-to-outline.py" --brief "{absolute_path_to_presentation_brief}"
```

It returns the absolute path as `data.outline_path`. Pass `--include-internal` only when the presenter-prep slides (Methodology, Buying Center) belong in the handoff; by default they are excluded, since they are internal preparation rather than client-facing copy. On `success: false`, report the `error`, skip the outline box, and still offer the other paths.

## Option 1 — Claude Design (claude.ai/design)

No theme is resolved: the organization design system applies. Print:

```
─── File to attach in claude.ai/design ───

Presentation outline: {absolute_path_to_presentation_outline}

Hand the outline to Claude Design at claude.ai/design — the organization
design system applies, so attach theme.md only when none is configured.
──────────────────────────────────────────
```

Replace `{absolute_path_to_presentation_outline}` with the exporter's `data.outline_path`.

## Option 2 — claude.ai attachment (Anthropic PPTX skill)

Resolve a theme **now**, and only now: use the brief's `theme_path` when the frontmatter carries one; otherwise invoke `cogni-workspace:pick-theme` via the Skill tool and take the absolute `theme_path` it returns. Then tell the user:

1. **Open a new chat on claude.ai** — the PPTX skill handles attachments natively there
2. **Attach two files:** `presentation-brief.md` and the resolved `theme.md`
3. **Use this prompt:**

```
Build a .pptx from the attached presentation-brief.md, styled by the attached theme.md.
Follow the brief's Rendering Contract: copy is frozen, speaker notes travel complete into the notes channel,
citation markers become hyperlinks and the references slide stays last.
```

Print both paths:

```
─── Files to attach in claude.ai ───

Presentation brief: {absolute_path_to_presentation_brief}
Theme:              {absolute_path_to_theme_md}

Open claude.ai → new chat → attach both files → paste the prompt above.
─────────────────────────────────────────────────
```

## Option 3 — pptx inside Claude Code (pptx agent)

Resolve a theme exactly as in Option 2, then dispatch the `cogni-workspace:pptx` agent via the Agent tool with:

```
PRESENTATION_BRIEF: {absolute_path_to_presentation_brief}
THEME_FILE: {absolute_path_to_theme_md}
OUTPUT_PATH: {source_dir}/cogni-visual/presentation.pptx
```

The agent resolves the installed Anthropic pptx skill (`anthropic-skills:pptx` first, `document-skills:pptx` from the marketplace second), builds the deck from the brief's Rendering Contract and `libraries/pptx-render-recipe.md`, then round-trips the result against the brief and reports a `qa` block. Print the returned `output_path` and summarise `qa` (missing text or notes, validation status, thumbnails status). When the agent returns `{"success": false, "error": "pptx_skill_unavailable"}`, neither skill name resolves in this session: print the Option 2 instructions and paths instead — never fail the run on it.

## Option 4 — HTML deck (render-html-slides)

Dispatch `cogni-workspace:render-html-slides` via the Skill tool with `brief_path={absolute_path_to_presentation_brief}`. The renderer resolves its own theme — the brief's `theme_path` when present, otherwise the ecosystem picker — so nothing is resolved here. Report the HTML path it returns.

## Option 5 — Later

Print the brief path and the outline path, render nothing, and stop.

## Headless runs

When `interactive` is `false`, or the user answers with an empty response, the checkpoint behaves as Option 5 after the outline export: it prints the brief and outline paths, renders nothing, and asks nothing. The `narrative-publish` pipeline relies on this.

## Printed paths

Every path **printed to the user** must be absolute — never `~`, `$HOME`, `$CLAUDE_PLUGIN_ROOT`, or relative. That governs printed handoff paths only; `$CLAUDE_PLUGIN_ROOT` remains the correct way to invoke a bundled script.

## What the outline carries

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
