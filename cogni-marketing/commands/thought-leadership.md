---
name: thought-leadership
description: Generate thought leadership content (blog, LinkedIn article, keynote, podcast, op-ed)
argument-hint: "--market <slug> --gtm-path <theme-id> [--format <format>]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, WebSearch, WebFetch
---

Generate thought leadership content for the specified market and GTM path. Parse arguments for --market, --gtm-path, and optional --format. If arguments are missing, ask the user interactively.

Load and follow the `thought-leadership` skill from `${CLAUDE_PLUGIN_ROOT}/skills/thought-leadership/SKILL.md`.
