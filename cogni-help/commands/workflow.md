---
name: workflow
description: Show cross-plugin workflow templates for common multi-plugin pipelines
argument-hint: "[workflow-name]"
allowed-tools:
  - Read
  - Glob
---

Show step-by-step workflow templates for chaining insight-wave plugins.

Accept either:
- A workflow name (research-to-report, trends-to-solutions, portfolio-to-pitch,
  consulting-engagement, full-onboarding) — show that specific workflow
- No argument — list all available workflows

Steps:
1. Load the workflow skill for template structure and presentation rules
2. If a workflow name is provided, load the matching template from references/workflows/
3. Present the pipeline diagram and walk through each step
4. If no argument, present the workflow summary table
