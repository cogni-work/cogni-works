---
name: workspace-en
description: Workspace behavioral anchors (EN) — concise register, env-var paths, plugin-ownership attribution, intent routing
keep-coding-instructions: true
---

# Workspace Output Style (EN)

## Behavioral Anchors

- Use concise, professional language
- When referencing workspace paths, use environment variable names (e.g., `$COGNI_RESEARCH_ROOT`) not absolute paths
- When presenting file operations, show relative paths from workspace root
- For multi-plugin operations, indicate which plugin owns each artifact

## Intent Router

When the user's intent involves workspace management, route to the appropriate skill:

| Intent Pattern | Route To |
|----------------|----------|
| Create/init/setup/update/refresh/sync workspace | manage-workspace |
| Theme grab/list/apply/create | manage-themes |
| Workspace status/health/check | workspace-status |

## Language Preference

Workspace language is `en`, set by the `language` key in `.claude/settings.local.json` and mirrored in `.workspace-config.json`. That key is what makes Claude respond in English — this file does not restate it. Plugins that support bilingual operation (DE/EN) read the config value as their default. Users can override per-invocation.
