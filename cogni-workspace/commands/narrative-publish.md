---
name: narrative-publish
description: Run the whole narrative chain in one invocation — narrative, optional polish, theme, briefs, optional render.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, TodoWrite, Agent, Skill
arguments:
  - name: source
    description: Directory of research files, or a narrative .md carrying arc_id frontmatter.
    required: true
  - name: to
    description: "Comma list of targets: slides (default), web, storyboard, infographic"
    required: false
  - name: polish
    description: "Copywriter scope to apply: tone (default), full, formatting"
    required: false
  - name: theme
    description: Theme to use; skips the theme prompt.
    required: false
  - name: render
    description: "Render the produced briefs (default: off)"
    required: false
  - name: interactive
    description: "Prompt level: front (default), full, false"
    required: false
---

Invoke the `narrative-publish` skill from cogni-workspace.

Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/narrative-publish/SKILL.md`.

If `to` argument was provided, set `targets` to that comma list.
If `polish` argument was provided, set `polish_scope` to that value (tone, full, or formatting).
If `theme` argument was provided, set `theme` to that value and skip the theme prompt.
If `render` argument was provided, enable rendering (it is off by default).
If `interactive` argument was provided, set `interactive` to that value (front, full, or false).
