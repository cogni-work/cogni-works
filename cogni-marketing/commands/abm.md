---
name: abm
description: Generate account-based marketing content (account plans, personalized emails, executive briefings)
argument-hint: "--market <slug> --account <name-or-slug> [--gtm-path <theme-id>] [--format <format>]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, WebSearch, WebFetch
---

Generate ABM content for a specific named account. Parse arguments for --market, --account, optional --gtm-path and --format. If arguments are missing, ask the user interactively.

Load and follow the `abm` skill from `${CLAUDE_PLUGIN_ROOT}/skills/abm/SKILL.md`.
