# Render Hand-off

What story-to-slides Step 11 tells the user once the brief is written and validated — the claude.ai attachment box and prompt, and why that path is preferred over rendering inside Claude Code.

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

Replace `{absolute_path_to_presentation_brief}` with the resolved `output_path` and `{absolute_path_to_theme_md}` with the `theme_path` from Step 1. Both paths must be absolute — never use `~`, `$HOME`, `$CLAUDE_PLUGIN_ROOT`, or relative paths.

**Why claude.ai?** The web interface handles file attachments natively, which is what makes the PPTX skill render best there. Claude Code can also render via the `document-skills:pptx` skill — a working fallback, not the recommended path.
