# Narrative-publish pipeline contract

The operative contract for the `narrative-publish` skill. SKILL.md carries the
procedure; this file carries the argument matrix, the per-hop parameter
translation, the reject rule, render ordering and the consolidated JSON shape.

## Argument matrix

| Argument | Values | Default | Notes |
|---|---|---|---|
| `<source>` | directory, or `.md` with `arc_id:` frontmatter | — | Required. A `.md` **without** `arc_id:` frontmatter is rejected, never treated as a narrative. |
| `--to` | comma list of `slides`, `web`, `storyboard`, `infographic` | `slides` | Targets run in the order given. `storyboard` is `story-to-web` in `mode=storyboard`. |
| `--polish[=SCOPE]` | `tone`, `full`, `formatting` | off; bare `--polish` means `tone` | Maps onto copywriter's `--scope`. `compress` is deliberately not offered. |
| `--theme` | theme name or path | prompt via `pick-theme` | Required under `--interactive false`. |
| `--render` | flag | off | Render is opt-in at this layer. |
| `--interactive` | `front`, `full`, `false` | `front` | See "Interactivity" below. |

## Per-hop parameter translation

The hops do **not** share an argument style. `narrative` is flag-style; every
`story-to-*` skill is snake_case. Translate, never pass through.

| Hop | Style | Parameters used |
|---|---|---|
| `narrative` | flag | `--source-path`, `--arc-id`, `--output-path`, `--language`, `--target-length`, `--interactive` |
| `story-to-slides` / `story-to-web` / `story-to-infographic` | snake_case | `source_path`, `theme`, `arc_id`, `interactive`, `stakeholder_review`, `output_path`, `render` (infographic only), `mode` (web only) |
| `copywriter` | flag + skill args | `--scope`; `review_mode` |
| `pick-theme` | — | returns `theme_path`, `theme_name`, `theme_slug` |

### Two interim overrides, pending a callee fix

Both are cases where a downstream default silently overrides this skill's own contract, so this
skill passes the value explicitly. **Each is an interim workaround, not settled design** — the
root-cause fix belongs in the callee, which defaults the value in a way that silently degrades
*every* headless caller, not just this pipeline. Tracked separately; do not read the rule below as
a reason to stop fixing the callee.

1. **`stakeholder_review=true` on every `story-to-*` hop.** All three skills
   default `stakeholder_review` to the *value of `interactive`*. Because
   `--interactive front` passes `interactive=false` downstream, an omitted
   `stakeholder_review` silently disables brief review on every target — a quiet
   capability loss, not a visible failure. Spell it out at each hop.
2. **`render=false` on the `story-to-infographic` hop whenever `--render` was not
   given.** That skill's `render` parameter defaults to `true` and auto-dispatches
   the infographic render after validation. Left unset, an opt-in-render pipeline
   renders anyway. This is the exact mirror of rule 1: same failure shape,
   opposite direction.

### Theme fan-out

Resolve the theme once, then fan out by consumer form. `story-to-slides` and
`story-to-web` take the **absolute `theme_path`**; `story-to-infographic` takes the
**`theme_slug`**. Passing a path where a slug is expected does not fail loudly.

## Brief paths

Each `story-to-*` skill writes into `{source_dir}/cogni-visual/`.

| Target | Brief |
|---|---|
| `slides` | `presentation-brief.md` |
| `web` | `web-brief.md` |
| `storyboard` | `storyboard-brief.md` |
| `infographic` | `infographic-brief.md` |

## Reject rule

After each target, read the brief's `.review.json` sibling — for
`presentation-brief.md` that is `presentation-brief.review.json`.

**Branch on the top-level `overall` field**, a string taking `accept`, `revise` or
`reject`. Use `synthesis.verdict` as a fallback if `overall` is absent. **Never
read a numeric field.** The review JSON currently also carries a numeric
`overall_score` alongside `overall`, and per-perspective `score` fields; keying on
any of them couples this pipeline to a scoring scheme that is under active change,
whereas the verdict vocabulary is stable.

On a `reject` verdict:

- keep the brief on disk — it is the artifact a human inspects to see why;
- do not render it;
- record `rendered: false` in that target's entry;
- **continue with the remaining targets.**

The run fails only when **every** requested target failed. A two-target run with
one rejection exits successfully, carrying a warning.

## Render ordering

Renders are opt-in (`--render`) and run **sequentially** — never dispatch two concurrently, so
this skill never has to reason about which renderer a given brief selects. The Excalidraw-backed
renderers share a single MCP canvas (see `story-to-infographic/SKILL.md` § concurrency callout);
running the whole render set in sequence satisfies that constraint unconditionally.

Dispatch the infographic render as the bare form:

```
Skill("render-infographic", args: "{brief_path}")
```

Use the bare, unprefixed name. `render-infographic` exists as a command plus its
renderer agents, with no `skills/render-infographic/` directory, so a
`cogni-workspace:render-infographic` token does not resolve and is reported as an
unresolved dispatch target. `story-to-infographic` already dispatches this exact
bare form.

## Interactivity

| Value | Prompts presented |
|---|---|
| `front` (default) | At most three, all up front — the narrative Phase 0 clarification (only when a brief field is unresolved and material), the narrative arc-shortlist confirmation, and one `pick-theme` prompt. Every `story-to-*` hop receives `interactive=false`. |
| `full` | Each hop stays interactive. |
| `false` | None. `--theme` is required, and the narrative hop receives `--interactive false`. |

## Consolidated JSON shape

One envelope per run.

```json
{
  "narrative": {
    "output_path": "...", "arc_id": "...", "arc_display_name": "...",
    "detection_reason": "keyword density analysis",
    "target_length": 1675, "word_count": 1502, "citation_count": 22,
    "elements": 4, "language": "en",
    "readability_score": 48.2, "qa_verdict": "pass",
    "generated": true
  },
  "polish": null,
  "theme": { "theme_path": "...", "theme_name": "...", "theme_slug": "..." },
  "targets": [
    { "target": "slides", "brief": "...", "verdict": "accept", "rendered": false,
      "render_path": null }
  ],
  "warnings": []
}
```

- The `narrative` block carries only fields the narrative hop actually returns,
  copied through unchanged: `readability_score` is the Pass 4 measurement (or
  `null` when it was not computed) and `qa_verdict` is the release review's
  rollup, one of `pass` / `needs_revision` / `fail`. Read `qa_verdict` as a
  verdict, never as a number — the same insulation this contract applies to the
  brief review's `overall` field.
- `generated` is `false` when `<source>` was an existing narrative `.md`, and
  `output_path` is then the path that was passed in, unchanged.
- `polish` is `null` unless `--polish` ran.
- `targets[]` carries **exactly one entry per requested target**, including
  targets that were rejected or that failed. A target that ran with no entry is a
  contract violation.
- `warnings[]` carries per-target rejections and any skipped render.
