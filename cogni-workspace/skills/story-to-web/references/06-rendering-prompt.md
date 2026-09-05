# Rendering Prompt Templates

The two rendering-prompt sections story-to-web Step 11 appends to the brief and prints to the conversation — one for `mode=web` (the `web` agent) and one for `mode=storyboard` (the `storyboard` agent). Both need absolute paths because the receiving Claude session has no access to this session's variables.

After the brief is written and validated, **append** a rendering prompt section to the end of web-brief.md (after Generation Metadata), then also print it to the conversation so the user can copy it directly.

Use the absolute paths resolved during the workflow:

```markdown
---

## Rendering Prompt

Copy this prompt into a new Claude chat to render the web narrative:

> Please render a web narrative using:
> - Web brief: {absolute_path_to_web_brief}
> - Theme: {absolute_path_to_theme_md}
```

Replace `{absolute_path_to_web_brief}` with the resolved `output_path` and `{absolute_path_to_theme_md}` with the `theme_path` from Step 1.

Both paths must be absolute — never use `~`, `$HOME`, `$CLAUDE_PLUGIN_ROOT`, or relative paths, because the receiving Claude session has no access to variables from this session.

**`mode=storyboard` only:** append the prompt to the end of `storyboard-brief.md` instead, and name the print renderer:

```markdown
---

## Rendering Prompt

Copy this prompt into a new Claude chat to render the posters:

> Please render a print storyboard using:
> - Storyboard brief: {absolute_path_to_storyboard_brief}
> - Theme: {absolute_path_to_theme_md}
>
> Use the `storyboard` agent; it writes a multi-poster .pen file next to the brief.
```

Replace `{absolute_path_to_storyboard_brief}` with the `output_path` resolved in Step 10. The same absolute-path rule applies.
