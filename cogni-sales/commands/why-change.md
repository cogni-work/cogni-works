---
name: why-change
description: Create a Why Change sales pitch for a named customer or market segment
usage: /why-change [--project-path <path>]
aliases: [pitch, sales-pitch, segment-pitch]
category: sales
allowed-tools: [Read, Bash, Skill]
---

# /why-change

Create or resume a Why Change sales pitch. Supports named-customer pitches (deal-specific) and segment pitches (reusable for a market).

## Usage

```
/why-change                        # Start new pitch or discover existing
/why-change --project-path <path>  # Resume specific pitch project
```

## Behavior

**New pitch:** If no `--project-path` is provided:
1. Discover existing pitch projects via `pitch-status.sh`
2. If incomplete projects found: ask user to resume or start new
3. If no projects: invoke the `why-change` skill to start fresh
4. The skill will ask whether this is a named-customer or segment pitch

**Resume pitch:** If `--project-path` is provided:
1. Read pitch-log.json for current state and pitch mode
2. Resume from the last incomplete phase

## Examples

```
/why-change
> "Starting new pitch. Are you creating a pitch for a named customer or a reusable segment pitch?"

/why-change --project-path ./siemens-pitch
> "Resuming Siemens pitch (customer mode) — Phase 2 (Why Now) is next."

/why-change --project-path ./enterprise-manufacturing-dach-segment-pitch
> "Resuming Enterprise Manufacturing DACH segment pitch — Phase 3 (Why You) is next."
```

## Implementation

Invoke the `cogni-sales:why-change` skill:

```
Skill tool: cogni-sales:why-change
Args: {provided arguments}
```

If `--project-path` is provided, pass it through. Otherwise, first scan for existing projects:

```bash
# Find pitch projects in workspace
for dir in */; do
  if [ -f "${dir}.metadata/pitch-log.json" ]; then
    "${CLAUDE_PLUGIN_ROOT}/scripts/pitch-status.sh" "$dir"
  fi
done
```

Present discovered projects to user (showing mode: customer or segment), then invoke the skill.
