---
name: cheatsheet
description: Generate a quick-reference card for any cogni-works plugin
argument-hint: "[plugin-name]"
allowed-tools:
  - Read
  - Glob
  - Grep
---

Generate a one-screen reference card for a cogni-works plugin using the cheatsheet skill.

Accept either:
- A plugin name (with or without "cogni-" prefix) — generate its cheatsheet
- No argument — list all available plugins

Steps:
1. Load the cheatsheet skill for the reference card template
2. If a plugin name is provided, read its README, plugin.json, and skill frontmatter
3. Generate the formatted cheatsheet following the template
4. If no argument, list plugins from the guide skill's catalog
