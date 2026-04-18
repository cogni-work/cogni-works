---
id: concept-script-output-format
title: Script output format (universal JSON contract)
type: concept
tags: [conventions, scripts, json, stdlib]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md
status: stable
---

Every utility script in insight-wave returns JSON in a single canonical shape:

```json
{"success": true, "data": {...}, "error": ""}
```

On failure: `{"success": false, "data": {}, "error": "human-readable error message"}`.

## Why this is non-negotiable

Skills and agents call scripts via the Bash tool, then parse the JSON to decide what to do next. A uniform contract means the calling code doesn't have to special-case each script — `success` is the gate, `data` is the payload, `error` is the diagnostic.

## stdlib only

All scripts are bash + python3 standard library. **No pip dependencies, no npm dependencies, anywhere.** This keeps the repo installable on any machine with a sane Unix environment and python3 — no environment management story to maintain, no supply chain to audit.

## Where it appears

Every plugin with a `scripts/` directory follows this. cogni-claims has no `scripts/` directory at all (its work is fully agent-driven), but every other plugin uses this format universally. Hook scripts in `hooks/` follow the same convention even though they signal via exit code rather than stdout.

## Implications for new code

When writing a new utility script, the first design decision is the JSON shape under `data`. That shape becomes a contract — calling skills depend on the field names. Breaking changes to `data` need the same version discipline as bridge files (see [[concept-bridge-files]]).

**Source**: [insight-wave/CLAUDE.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md)
