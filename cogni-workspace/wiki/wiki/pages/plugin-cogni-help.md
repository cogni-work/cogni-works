---
id: plugin-cogni-help
title: "cogni-help (plugin)"
type: entity
tags: [cogni-help, plugin, help, courses, training, workflow, troubleshoot, cheatsheet, guide]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-help/README.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-help.md
status: stable
---

> **Incubating** (v0.0.4) — skills may change or be removed at any time.

Central help hub for the insight-wave ecosystem. Interactive courses (12-course curriculum), plugin discovery, cross-plugin workflow guides, troubleshooting, quick-reference cheatsheets, and GitHub issue filing.

## Layer

Cross-cutting utility. Depends on every other plugin via knowledge of skills/agents (read-only); is depended on by nothing.

## Skills

| Skill | Purpose |
|-------|---------|
| `cogni-help:guide` | Help users find the right insight-wave plugin or skill for their task |
| `cogni-help:cheatsheet` | Generate a quick-reference card for any insight-wave plugin |
| `cogni-help:workflow` | Cross-plugin workflow templates for common multi-plugin pipelines |
| `cogni-help:teach` | Interactive course delivery — start or resume one of the 12 courses |
| `cogni-help:course-deck` | Generate professional PPTX slide decks for course curriculum or per-course intros |
| `cogni-help:troubleshoot` | Diagnose and fix common issues with insight-wave plugins |
| `cogni-help:cogni-issues` | File and track GitHub issues against insight-wave plugins via browser automation (claude-in-chrome) |

## How users encounter it

cogni-help is the answer to "I have insight-wave installed — now what?" Users invoke `/cogni-help:guide` to find the right plugin for their goal, `/cogni-help:teach` to learn one through an interactive course, `/cogni-help:cheatsheet` for a quick reference, or `/cogni-help:troubleshoot` when something breaks.

## Future integration

Optional follow-up (not yet implemented): cogni-help:guide and cogni-help:troubleshoot consult the bundled insight-wave wiki ([[plugin-cogni-workspace]]'s bundled `wiki/`) as their first lookup before falling back to grep — would keep the wiki authoritative for ecosystem-level questions.

**Source**: [cogni-help README](https://github.com/cogni-work/insight-wave/blob/main/cogni-help/README.md) · [plugin guide](https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-help.md)
