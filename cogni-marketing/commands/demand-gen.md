---
name: demand-gen
description: Generate demand generation content (LinkedIn posts, SEO articles, carousels, video scripts)
argument-hint: "--market <slug> --gtm-path <theme-id> [--format <format>] [--count <n>]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, WebSearch, WebFetch
---

Generate demand generation content. Parse arguments for --market, --gtm-path, optional --format and --count (for batch generation, e.g., 4 LinkedIn posts). If arguments are missing, ask the user interactively.

Load and follow the `demand-generation` skill from `${CLAUDE_PLUGIN_ROOT}/skills/demand-generation/SKILL.md`.
