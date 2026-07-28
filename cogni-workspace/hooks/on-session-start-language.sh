#!/usr/bin/env bash
# on-session-start-language.sh - Inject the workspace language rules Claude Code
# does not already carry in its own "# Language" system-prompt section.
#
# That built-in section says "Always respond in <language>" and "technical terms
# and code identifiers should remain in their original form" — nothing about
# orthography, and nothing about the user switching language mid-conversation.
# Both are workspace doctrine, so they travel here.
#
# Emits a SessionStart hookSpecificOutput envelope on stdout, or nothing at all.
# Always exits 0 (non-blocking).

set -euo pipefail

# Find workspace: check PROJECT_AGENTS_OPS_ROOT, then cwd
WORKSPACE=""
if [ -n "${PROJECT_AGENTS_OPS_ROOT:-}" ] && [ -f "${PROJECT_AGENTS_OPS_ROOT}/.workspace-config.json" ]; then
  WORKSPACE="$PROJECT_AGENTS_OPS_ROOT"
elif [ -f ".workspace-config.json" ]; then
  WORKSPACE="$(pwd)"
fi

[ -n "$WORKSPACE" ] || exit 0
command -v python3 &>/dev/null || exit 0

python3 - "$WORKSPACE" <<'PYEOF' || exit 0
import json, os, sys

workspace = sys.argv[1]

# Keep in step with LANGUAGE_NAMES in scripts/generate-settings.sh, which writes
# the settings key this reads back.
NAMES_TO_ISO = {"english": "en", "german": "de"}

# Rule blocks keyed by ISO code. A language with no block emits nothing —
# English needs no orthography rule, and the built-in section covers the rest.
RULES = {
    "de": """## Sprache und Rechtschreibung

- Vollständige deutsche Rechtschreibung verwenden: alle Umlaute (ä, ö, ü, Ä, Ö, Ü)
  und Eszett (ß). Keine Umschreibungen wie "ae" für "ä", "oe" für "ö", "ue" für
  "ü" oder "ss" für "ß".
- ß nach langem Vokal und Diphthong (Maßnahme, außerhalb, Größe), ss nach kurzem
  Vokal (dass, muss, Prozess). Kein schweizerisches ss an ß-Stellen.
- Wechselt der Benutzer die Sprache, in dessen Sprache antworten — die
  Workspace-Sprache ist die Vorgabe, nicht ein Zwang.""",
}


def read(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (IOError, ValueError):
        return {}


# The settings key is the source of truth (it is what reaches the system
# prompt); .workspace-config.json is the fallback for workspaces generated
# before the key existed.
name = read(os.path.join(workspace, ".claude", "settings.local.json")).get("language")
if isinstance(name, str) and name.lower() in NAMES_TO_ISO:
    code = NAMES_TO_ISO[name.lower()]
else:
    value = read(os.path.join(workspace, ".workspace-config.json")).get("language")
    code = value if isinstance(value, str) else ""

rules = RULES.get(code)
if not rules:
    sys.exit(0)

# Plain stdout is not injected as context — only the parsed
# hookSpecificOutput.additionalContext field is.
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": rules,
    }
}))
PYEOF

exit 0
