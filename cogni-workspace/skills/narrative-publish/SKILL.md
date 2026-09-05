---
name: narrative-publish
description: >-
  Sequence the whole narrative-to-deliverable chain in one invocation: generate a
  narrative from a research directory, optionally polish it, resolve a theme once,
  build one or more briefs, and optionally render them. Owns no transformation
  logic — every hop is an existing cogni-workspace skill. Use this skill whenever
  the user asks to "publish this narrative", "run the narrative pipeline",
  "take this research directory all the way through", "one invocation from
  research to deliverable", "narrative end to end", "Narrativ in einem Durchgang
  veröffentlichen", or otherwise wants the chain walked for them instead of
  invoking narrative and a story-to-* skill separately. Also triggers when a
  caller needs several deliverables from one narrative in a single pass.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, TodoWrite, Agent, Skill
---

# Narrative Publish

Walk the existing chain — narrative → optional polish → theme → brief(s) → optional
render — in one invocation, and return a single consolidated JSON envelope.

This skill is an orchestrator: it owns no transformation logic. Each step dispatches
an existing skill and threads its output into the next, so the generating, editing and
rendering are done by the hops, not here — the broad tool grant above exists to let
those hops run in-context, not to license this skill to author artifacts itself. Read
[`references/pipeline-contract.md`](references/pipeline-contract.md) for the
argument matrix, the per-hop parameter translation, the reject rule, render
ordering and the exact JSON shape. That reference is the contract — consult it
before dispatching any hop, because two callee defaults must be overridden
explicitly and getting either wrong silently changes behaviour.

## Arguments

`<source>` is required. `--to`, `--polish`, `--theme`, `--render` and `--interactive` are
optional. Their values, defaults and interactions are declared once, in the contract — read it
rather than inferring them from the procedure below.

## Procedure

1. **Resolve the source.** A directory runs the narrative hop. A `.md` file
   carrying `arc_id:` frontmatter is an existing narrative — skip generation and
   report the path back unchanged. Reject a `.md` file without `arc_id:`
   frontmatter rather than treating it as a narrative.
2. **Generate** (directory sources only). Dispatch `narrative` with its flag-style
   arguments. Under `--interactive false` pass `--interactive false` to suppress
   the arc confirmation; under `front` and `full` leave it interactive (the
   contract's interactivity table fixes the per-value prompt budget).
3. **Polish** (only when `--polish` was given). Dispatch `copywriter` in-context.
   Map the `--polish` value onto copywriter's `--scope`. Never offer `compress`:
   copywriter rejects it in arc mode and aborts.
4. **Resolve the theme once.** Dispatch `pick-theme` a single time and keep all
   three return values. Under `--interactive false` a theme must come from
   `--theme`; do not prompt.
5. **Build each brief.** Walk `--to` in order, dispatching the matching
   `story-to-*` skill sequentially — never in parallel, since they share the
   source directory. Spell the review flag out at each hop; it is not inherited:
   - `slides` → `story-to-slides` with `stakeholder_review=true`
   - `web` and `storyboard` → `story-to-web` with `stakeholder_review=true`
     (plus `mode=storyboard` for the latter)
   - `infographic` → `story-to-infographic` with `stakeholder_review=true` and
     `render=false` unless `--render` was given
   Both flags have callee defaults that otherwise override this skill's contract;
   the reference explains each.
6. **Apply the reject rule** after each target — read the brief's `.review.json`
   sibling and branch on its verdict string, per the contract's reject rule, which
   fixes both the field to read and the continue-or-fail semantics.
7. **Render** (only when `--render` was given). Renders run sequentially, never
   concurrently. Dispatch the infographic render as a bare
   `Skill("render-infographic", args: "{brief_path}")`.
8. **Return one consolidated JSON envelope** — never a prose summary. Its exact
   fields are declared in the contract.
