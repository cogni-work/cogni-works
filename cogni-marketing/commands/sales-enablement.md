---
name: sales-enablement
description: Generate sales enablement content (battle cards, one-pagers, demo scripts, objection handlers)
argument-hint: "--market <slug> --gtm-path <theme-id> [--format <format>]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent
---

Generate sales enablement content. Parse arguments for --market, --gtm-path, and optional --format. If arguments are missing, ask the user interactively.

Load and follow the `sales-enablement` skill from `${CLAUDE_PLUGIN_ROOT}/skills/sales-enablement/SKILL.md`.
