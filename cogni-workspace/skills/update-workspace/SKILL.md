---
name: update-workspace
description: >-
  This skill should be used when the user asks to "update workspace",
  "refresh workspace", "sync workspace", "update plugins",
  "re-scan plugins", or mentions updating an existing insight-wave workplace.
  Handles plugin re-discovery, environment variable refresh, and
  configuration updates without losing user data.
version: 0.1.0
---

# Update Workspace

Update an existing insight-wave workspace by re-scanning installed plugins, refreshing environment variables, and updating shared configuration. Preserves all user data and customizations.

## Prerequisites

A valid workspace must exist. Detect by checking for `.workspace-config.json` at the target path or `$PROJECT_AGENTS_OPS_ROOT`.

If no workspace is found, suggest using `init-workspace` instead.

## Update Workflow

### Step 1: Locate Workspace

Find the workspace using this priority:
1. User-provided path
2. `$PROJECT_AGENTS_OPS_ROOT` environment variable
3. Current working directory

Read `.workspace-config.json` to understand current state (language, installed plugins, tool integrations).

### Step 2: Create Backup

Before modifying anything, create a timestamped backup:

```bash
BACKUP_DIR=".backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "${BACKUP_DIR}"
cp .workspace-config.json "${BACKUP_DIR}/"
cp -r .claude/ "${BACKUP_DIR}/"
cp .workspace-env.sh "${BACKUP_DIR}/" 2>/dev/null
```

### Step 3: Re-Discover Plugins

Run plugin discovery to detect new, removed, or updated plugins:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/discover-plugins.sh
```

Compare against the `installed_plugins` list in `.workspace-config.json`. Present changes to the user:
- **New plugins**: Not in config but found installed
- **Removed plugins**: In config but no longer installed
- **Unchanged plugins**: Still present

Ask user to confirm the updated plugin list.

### Step 4: Refresh Environment Variables

Regenerate `settings.local.json` and `.workspace-env.sh` with the confirmed plugin list:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-settings.sh \
  --target "${WORKSPACE_DIR}" \
  --language "${LANGUAGE}" \
  --plugins "${UPDATED_PLUGIN_LIST_JSON}" \
  --update
```

The `--update` flag preserves any custom env vars the user added manually.

### Step 5: Update Output Styles

Copy latest output-style files from `${CLAUDE_PLUGIN_ROOT}/assets/output-styles/` to `.claude/output-styles/`, overwriting existing ones (these are plugin-managed, not user-customized).

### Step 6: Update Theme Template

Refresh `_template/theme.md` from `${CLAUDE_PLUGIN_ROOT}/themes/_template/`. Preserve all user-created themes.

### Step 7: Update Workspace Config

Update `.workspace-config.json`:
- Refresh `installed_plugins` list
- Update `updated_at` timestamp
- Bump version if schema changed

### Step 8: Verify and Report

Check all expected files exist. Present a summary:
- Plugins added/removed
- Environment variables changed
- Files updated
- Backup location (for rollback if needed)

## Rollback

If something goes wrong, restore from backup:

```bash
cp -r .backups/{timestamp}/.claude/ .claude/
cp .backups/{timestamp}/.workspace-config.json .
cp .backups/{timestamp}/.workspace-env.sh . 2>/dev/null
```

## Additional Resources

### Scripts

- **`${CLAUDE_PLUGIN_ROOT}/scripts/discover-plugins.sh`** - Scan for installed plugins
- **`${CLAUDE_PLUGIN_ROOT}/scripts/generate-settings.sh`** - Generate/update settings files
