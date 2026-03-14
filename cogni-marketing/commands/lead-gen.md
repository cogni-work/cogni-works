---
name: lead-gen
description: Generate lead generation content (whitepapers, landing pages, email nurture, webinars)
argument-hint: "--market <slug> --gtm-path <theme-id> [--format <format>]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, WebSearch, WebFetch
---

Generate lead generation content. Parse arguments for --market, --gtm-path, and optional --format. If arguments are missing, ask the user interactively.

Load and follow the `lead-generation` skill from `${CLAUDE_PLUGIN_ROOT}/skills/lead-generation/SKILL.md`.
