---
name: campaign
description: Build a multi-channel campaign with touch sequences and timeline
argument-hint: "--market <slug> --gtm-path <theme-id> [--name <campaign-name>] [--weeks <n>]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent
---

Build a marketing campaign. Parse arguments for --market, --gtm-path, optional --name and --weeks (default 8). If arguments are missing, ask the user interactively.

Load and follow the `campaign-builder` skill from `${CLAUDE_PLUGIN_ROOT}/skills/campaign-builder/SKILL.md`.
