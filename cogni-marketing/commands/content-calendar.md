---
name: content-calendar
description: Generate or update the editorial content calendar
argument-hint: "[--add | --update <date> --status <status> | --reschedule <date> --to <new-date> | --export csv]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

Generate or manage the content calendar. Parse arguments for subcommands:
- No args: Generate full calendar from strategy and campaigns
- --add: Add a new calendar entry interactively
- --update <date> --status <status>: Update entry status
- --reschedule <date> --to <new-date>: Move an entry
- --export csv: Export calendar as CSV file

Load and follow the `content-calendar` skill from `${CLAUDE_PLUGIN_ROOT}/skills/content-calendar/SKILL.md`.
