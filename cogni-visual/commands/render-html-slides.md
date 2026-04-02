---
name: render-html-slides
description: Render a presentation-brief.md into a themed HTML slide presentation with speaker notes, keyboard navigation, and smooth transitions.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Agent, Skill
arguments:
  - name: source
    description: Path to presentation-brief.md. If omitted, auto-discovers nearby briefs.
    required: false
  - name: transition
    description: "Slide transition: fade (default), slide, none"
    required: false
---

Invoke the `render-html-slides` skill from cogni-visual.

Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/render-html-slides/SKILL.md`.

If `source` argument was provided, set `brief_path` to that value.
If `transition` argument was provided, set `transition` to that value (must be fade, slide, or none).
