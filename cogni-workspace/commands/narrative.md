---
name: narrative
description: "Transform input files into an executive narrative using a story arc framework"
argument-hint: "[source_path] [--arc arc_id] [--lang en|de]"
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
  - TodoWrite
---

# /narrative Command

Transform a set of input markdown files into a compelling executive narrative using one of the story arcs registered in the `narrative` skill.

## Argument Parsing

Parse the user's arguments to extract:
- `source_path` (required) -- directory with .md files or single .md file
- `--arc` or `--arc-id` (optional) -- explicit arc id; the registered arcs and their governing questions are listed in the skill's `references/story-arc/arc-registry.md` Quick Reference (not duplicated here, so the list cannot drift)
- `--lang` or `--language` (optional) -- `en` (default) or `de`
- `--output` or `-o` (optional) -- output file path

If `source_path` is missing, ask the user for it.

## Execution

1. Load the `cogni-workspace:narrative` skill using the Skill tool
2. Follow the skill's 6-phase workflow with the parsed parameters
3. Present the arc selection to the user for confirmation before transforming
4. Write the output and report the summary

## Examples

```
/narrative ./research-output/
/narrative ./analysis/ --arc technology-futures --lang de
/narrative ./report.md --arc corporate-visions -o ./insight-summary.md
```
