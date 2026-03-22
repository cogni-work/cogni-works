---
name: troubleshoot
description: Diagnose and fix issues with cogni-works plugins
argument-hint: "[plugin-name]"
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

Diagnose issues with cogni-works plugins using the troubleshoot skill.

Accept either:
- A plugin name — run targeted diagnostics for that plugin and its dependencies
- No argument — run a full diagnostic scan across all plugins

Steps:
1. Load the troubleshoot skill for diagnostic checks and known issues
2. If a plugin name is provided, run targeted checks (availability, integrity, dependencies)
3. If no argument, run all checks and present a summary table
4. For each issue found, report: Problem → Cause → Fix
