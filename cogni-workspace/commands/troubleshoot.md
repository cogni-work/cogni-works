---
name: troubleshoot
description: Diagnose and fix issues with insight-wave plugins
argument-hint: "[plugin-name]"
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

Diagnose issues with insight-wave plugins using the cogni-workspace workspace-status skill,
which carries plugin diagnostics as its plugin-level tier.

Accept either:
- A plugin name — run targeted diagnostics for that plugin and its dependencies
- No argument — run a full diagnostic scan across all plugins

Steps:
1. Load the cogni-workspace workspace-status skill for its diagnostic checks and known issues
2. If a plugin name is provided, run the plugin-level probes for it (availability, integrity, dependencies)
3. If no argument, run all eight checks — workspace infrastructure and plugin-level alike — and present the full-scan summary table
4. For each issue found, report: Symptom → Cause → Fix
