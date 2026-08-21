---
name: troubleshoot
description: >-
  This skill diagnoses and fixes plugin-level and cross-plugin faults in insight-wave
  plugins: plugin availability, skill-file integrity, cross-plugin dependencies, and
  progress or state files. Workspace infrastructure — env vars, themes, settings,
  the plugin registry, and MCP servers in the session — belongs to the sibling
  workspace-status skill; route there instead. It should be used whenever the user
  reports something broken, a skill not working, an error from a plugin, needs
  debugging help, or says things like "something is wrong", "plugin error",
  "skill not responding", "fix my setup", or "why isn't X working". It also triggers
  when the user encounters unclear errors during plugin use — even without an
  explicit troubleshooting request.
allowed-tools: Read, Bash, Glob, Grep
---

# troubleshoot: Plugin Diagnostics

Diagnose and resolve issues with insight-wave plugins. This complements
the sibling `workspace-status` skill, which checks infrastructure (env vars,
themes, settings). Troubleshoot focuses on plugin-level and cross-plugin problems.

## Language

Read the workspace language from `.workspace-config.json` in the workspace root
(`language` field — `"en"` or `"de"`). Present diagnostic findings, explanations,
and fix instructions in that language (Symptom → Cause → Fix stays as a pattern,
but the content within each section uses the workspace language).

If the file is missing or unreadable, detect the user's language from their message.
If still unclear, default to English.

Keep in English regardless of language setting:
- Plugin names, command names, file paths
- Status values (`OK`, `WARN`, `FAIL`)
- Error messages, stack traces, code snippets
- Column headers in diagnostic tables
- The `Symptom` / `Cause` / `Fix` field labels themselves — the label stays fixed so
  the report shape is recognisable across languages; only its content is translated

## Scope Boundary

| This skill owns | workspace-status owns |
|-----------------|---------------------|
| Plugin availability and integrity | Workspace env vars and settings |
| Skill file validation | Theme installation and config |
| Cross-plugin dependency checks | Plugin discovery/registry |
| Progress/state file health | Session hooks and lifecycle |
| Stale state from renames | Dependency tool versions (node, gh, etc.) |

If the issue is clearly infrastructure (missing env var, broken theme), suggest
the user run `/workspace-status` instead.

## Diagnostic Flow

When a user reports a problem:

1. **Identify the scope** — is this about a specific plugin, a cross-plugin workflow,
   or something vague? Ask if unclear.

2. **Run targeted checks** based on what the user describes. Don't run everything
   every time — start with the most likely cause and expand if needed.

3. **Report findings clearly** — state what's wrong, why, and how to fix it. Use
   the format: Symptom → Cause → Fix, one finding per block, using the same field
   labels `references/known-issues.md` uses so a catalogued fix and a fresh diagnosis
   read identically:

   **Symptom**: a cogni-marketing skill reports that portfolio data cannot be found.

   **Cause**: cogni-marketing depends on cogni-portfolio, which has no entry in
   `.claude-plugin/marketplace.json` for this workspace.

   **Fix**: install cogni-portfolio from the marketplace, then re-run.

   Keep the three labels even when a field is short — a finding with no known cause
   says so under **Cause** rather than dropping the label, so every report has the
   same three anchors to scan for.

## Diagnostic Checks

### 1. Plugin Availability

Verify the plugin directory exists and has a valid plugin.json:

```bash
# Check plugin exists in marketplace
cat .claude-plugin/marketplace.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for p in data['plugins']:
    print(f\"{p['name']}: {p['source']}\")
"
```

Then verify the source directory exists and contains `.claude-plugin/plugin.json`.

### 2. Skill File Integrity

For a named plugin, check that all skill directories contain a valid SKILL.md
with YAML frontmatter (at minimum: `name` and `description` fields):

```bash
# List all skills for a plugin
ls -d <plugin-dir>/skills/*/SKILL.md 2>/dev/null
```

Read each SKILL.md and verify the frontmatter parses correctly.

### 3. Progress/State File Health

Check `.claude/*.local.md` files for valid YAML frontmatter structure.
Common issues:
- Malformed YAML (missing closing `---`, bad indentation)
- Stale project or entity IDs from renamed plugins
- Corrupted status values

`.claude/cogni-help.local.md` is inert — it held progress for the retired course
system and nothing reads it. Treat it as safe to delete, never as a fault.

### 4. Cross-Plugin Dependencies

Many plugins require others to function. Check that dependencies are installed:

| Plugin | Requires |
|--------|----------|
| cogni-marketing | cogni-trends, cogni-portfolio |
| cogni-sales | cogni-portfolio, cogni-workspace (the `narrative` skill) |
| cogni-consult | cogni-knowledge (required research spine) |

Verify by checking if the required plugin directories exist in the marketplace.

cogni-consulting was retired (its source remains in git history). It has no
marketplace entry, so it is absent from the table above rather than listed as a
dependency nothing can satisfy; route new consulting issues to cogni-consult.

### 5. Stale State Detection

After plugin retirements, orphaned files may linger:

```bash
# Check for retired cogni-diamond / cogni-consulting engagement state.
# find, not a ** glob: engagement files sit two segments deep
# ({plugin}/{engagement-slug}/), and ** only recurses where globstar is on.
# -maxdepth 3 is that same bound, so the walk skips .git, caches and vaults.
find . -maxdepth 3 -type f \( -name 'diamond-project.json' -o -name 'consulting-project.json' \) 2>/dev/null

# Check for inert course-progress files (the course system is retired)
ls .claude/cogni-teacher.local.md .claude/cogni-help.local.md 2>/dev/null
```

Route each hit to `references/known-issues.md`, which carries the full remedy:

- Engagement file (`diamond-project.json`, `consulting-project.json`) — "Leftover
  engagement file from a retired consulting plugin". Keep it as an inert local
  record; there is no import path into cogni-consult.
- Course-progress file (`cogni-teacher.local.md`, `cogni-help.local.md`) —
  "Leftover course-progress file". Delete it; nothing reads it any more.

### 6. Common Misconfigurations

- **Missing COGNI_WORKSPACE_ROOT**: Many plugins need this env var. Check
  `.workspace-env.sh` exists and is sourced.
- **GitHub CLI not authenticated**: Required for cogni-issues. Run `gh auth status`;
  when authentication is missing, guide the user through `gh auth login`.
- **PPTX rendering skill unavailable**: `document-skills:pptx` renders the story-to-slides
  brief and does not ship from this marketplace. Confirm the session provides it before
  dispatching the `pptx` agent; otherwise take story-to-slides Step 11, "Guide User to
  PPTX Rendering".

## Full Scan Mode

When `/troubleshoot` is invoked with no argument, run all checks and present a
summary table:

| Check | Status | Details |
|-------|--------|---------|
| Marketplace | OK/WARN/FAIL | N plugins registered |
| Plugin integrity | OK/WARN/FAIL | Any missing SKILL.md files |
| State files | OK/WARN/FAIL | Any corrupted or stale files |
| Dependencies | OK/WARN/FAIL | Any missing cross-plugin deps |
| Environment | OK/WARN/FAIL | Key env vars and tools |

## Reference

See `references/known-issues.md` for a maintained list of known issues and their fixes.
