#!/usr/bin/env bash
# generate-settings.sh - Generate .claude/settings.local.json and .workspace-env.sh
# Usage: generate-settings.sh --target <dir> --language <iso-code> --plugins <json-file-or-string>
# --language takes an ISO 639-1 code. Codes with a natural-language name in
# LANGUAGE_NAMES below also get the Claude Code "language" settings key; anything
# else is reported as data.language_key_skipped and gets no key.
# Optional: --update (preserve custom env vars; drop generated ones for
# plugins no longer in the list)

set -euo pipefail

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Parse arguments
TARGET_DIR=""
LANGUAGE="en"
PLUGINS_ARG="[]"
UPDATE_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET_DIR="$2"; shift 2 ;;
    --language) LANGUAGE="$2"; shift 2 ;;
    --plugins) PLUGINS_ARG="$2"; shift 2 ;;
    --update) UPDATE_MODE=true; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$TARGET_DIR" ]; then
  echo '{"success":false,"data":{"error":"--target is required"}}' >&2
  exit 2
fi

# Resolve plugins JSON: if it's a file path, read it; otherwise treat as inline JSON
PLUGINS_TMPFILE=$(mktemp)
trap 'rm -f "$PLUGINS_TMPFILE"' EXIT

if [ -f "$PLUGINS_ARG" ]; then
  cp "$PLUGINS_ARG" "$PLUGINS_TMPFILE"
else
  echo "$PLUGINS_ARG" > "$PLUGINS_TMPFILE"
fi

# Create directories
mkdir -p "${TARGET_DIR}/.claude"
mkdir -p "${TARGET_DIR}/cogni-workspace/themes"

TARGET_ABS=$(cd "$TARGET_DIR" && pwd)

# Generate all config files via single Python call
python3 << PYEOF
import json, os, re, sys
from datetime import datetime, timezone

target = "$TARGET_ABS"
language = "$LANGUAGE"
update_mode = $( [ "$UPDATE_MODE" = true ] && echo "True" || echo "False" )

with open("$PLUGINS_TMPFILE") as f:
    plugins = json.load(f)

# The generated namespace: every env key this script writes for a plugin has one
# of these two shapes. The prune below keys on that derived namespace rather than
# on a list of retired plugin names, because a name list encodes one historical
# event, needs hand-maintaining, and says nothing about the next plugin removed.
#
# No ^/$ anchors: this Python body sits in an unquoted heredoc, where $ and
# backticks are live. fullmatch() supplies the anchoring, so the pattern carries
# no shell-live metacharacter at all.
GENERATED_KEY = re.compile(r"((?:COGNI|PLUGIN)_.+)_(?:ROOT|PLUGIN)")

# Build env vars
env = {}
env["PROJECT_AGENTS_OPS_ROOT"] = target
env["COGNI_WORKSPACE_ROOT"] = os.path.join(target, "cogni-workspace")
# HOME-relative (NOT target-relative): the optional-Python-dep venv is shared
# across all workspaces on this host, mirroring ~/.claude/mcp-servers/. This is
# the exact path consumers re-exec under (e.g. cogni-knowledge pdf-extract.py).
env["COGNI_WORKSPACE_PYTHON_VENV"] = os.path.expanduser(os.path.join("~", ".claude", "workspace-python-venv"))

# Keyspace stems of the plugins in THIS run's set, accumulated from the same
# root_var the loop already builds so there is no second name source to drift.
# A stem is recorded per plugin, not per key written: a plugin supplied without
# a path writes no _PLUGIN key this run, and its existing one must still count
# as owned rather than read as stale.
current_keyspaces = set()

for p in plugins:
    name = p.get("name", "") if isinstance(p, dict) else p
    path = p.get("path", "") if isinstance(p, dict) else ""

    if name.startswith("cogni-"):
        suffix = name.replace("cogni-", "").upper().replace("-", "_")
        root_var = f"COGNI_{suffix}_ROOT"
        plugin_var = f"COGNI_{suffix}_PLUGIN"
    else:
        suffix = name.upper().replace("-", "_")
        root_var = f"PLUGIN_{suffix}_ROOT"
        plugin_var = f"PLUGIN_{suffix}_PLUGIN"

    env[root_var] = os.path.join(target, name)
    current_keyspaces.add(root_var[: -len("_ROOT")])
    if path:
        env[plugin_var] = path

# Merge with existing settings if update mode. Read-modify-write the whole
# document, not just "env": the file is the user's too (permissions, hooks,
# outputStyle), and replacing it wholesale destroys anything we don't generate.
#
# Carrying every prior key over unconditionally is what kept a retired plugin's
# vars alive forever, pointing at directories that no longer exist. Each prior
# key now takes one of three arms:
#
#   1. regenerated this run  -> keep what this run computed
#   2. ours, plugin now gone -> prune
#   3. anything else         -> preserve untouched, value included
#
# Arm 1 is also what spares PROJECT_AGENTS_OPS_ROOT, COGNI_WORKSPACE_ROOT and
# COGNI_WORKSPACE_PYTHON_VENV: they are assigned unconditionally above, so they
# are already in env before any shape test runs. That identity check is required
# rather than merely convenient - cogni-workspace reaches the loop as an ordinary
# plugin, so COGNI_WORKSPACE_ROOT is a shape a real plugin genuinely produces, and
# a shape-only rule would delete the workspace's own root pointer for anyone who
# deselects cogni-workspace at the confirm step.
#
# Accepted residual: a hand-added key wearing the generated shape for an absent
# plugin is pruned. That is the intent of keying on the namespace - it names
# wiring this workspace no longer maintains.
settings_path = os.path.join(target, ".claude", "settings.local.json")
settings = {}
if update_mode and os.path.isfile(settings_path):
    with open(settings_path) as f:
        settings = json.load(f)
    for k, v in settings.get("env", {}).items():
        if k in env:
            continue
        m = GENERATED_KEY.fullmatch(k)
        if m and m.group(1) not in current_keyspaces:
            continue
        env[k] = v

settings["env"] = env

# The "language" settings key builds a "# Language" system-prompt section, so
# the workspace language reaches a fresh session with no output style and no
# CLAUDE.md. The key wants a natural-language name, not an ISO code.
#
# Adding a language means updating the inverse maps in
# hooks/on-session-start-language.sh and cogni-consult/hooks/on-subagent-start.sh
# too — the market registry carries ISO codes only, so there is no shared source
# to point at yet.
LANGUAGE_NAMES = {
    "en": "english",
    "de": "german",
    "fr": "french",
    "it": "italian",
    "nl": "dutch",
    "pl": "polish",
    "es": "spanish",
}
language_name = LANGUAGE_NAMES.get(language)
language_key_skipped = None
if language_name:
    settings["language"] = language_name
else:
    # Report it rather than silently shipping a workspace with no "# Language"
    # section at all: without the key, nothing sets the response language.
    language_key_skipped = language

# Write settings.local.json
with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

# Write .workspace-env.sh
env_sh_path = os.path.join(target, ".workspace-env.sh")
lines = [
    "#!/usr/bin/env bash",
    "# Auto-generated by cogni-workspace. Do not edit manually.",
    "# Source this file in non-Claude contexts (Obsidian Terminal, VS Code, CI/CD)",
    ""
]
for k, v in sorted(env.items()):
    lines.append(f'export {k}="{v}"')
lines.append("")
with open(env_sh_path, "w") as f:
    f.write("\n".join(lines))

# Write .workspace-config.json
config_path = os.path.join(target, ".workspace-config.json")
plugin_names = sorted([p.get("name", p) if isinstance(p, dict) else p for p in plugins])

if update_mode and os.path.isfile(config_path):
    with open(config_path) as f:
        config = json.load(f)
    config["installed_plugins"] = plugin_names
    config["updated_at"] = datetime.now(timezone.utc).isoformat()
    config["language"] = language
else:
    config = {
        "version": "0.1.0",
        "language": language,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "installed_plugins": plugin_names,
        "tool_integrations": []
    }

with open(config_path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")

# Output result
result = {
    "success": True,
    "data": {
        "target": target,
        "language": language,
        "env_vars_count": len(env),
        **({"language_key_skipped": language_key_skipped} if language_key_skipped else {}),
        "files_written": [
            ".claude/settings.local.json",
            ".workspace-env.sh",
            ".workspace-config.json"
        ],
        "update_mode": update_mode
    },
    "metadata": {
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "script": "$SCRIPT_NAME",
        "version": "0.1.0"
    }
}
print(json.dumps(result, indent=2))
PYEOF
