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

# No workspace found - silent exit
if [ -z "$WORKSPACE" ]; then
  exit 0
fi

if ! command -v python3 &>/dev/null; then
  exit 0
fi

# Resolve the language. The settings key is the source of truth (it is what
# reaches the system prompt); .workspace-config.json is the fallback for
# workspaces generated before the key existed.
LANGUAGE=$(python3 -c "
import json, os

workspace = '$WORKSPACE'
NAMES_TO_ISO = {'english': 'en', 'german': 'de'}

def read(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (IOError, ValueError):
        return {}

settings = read(os.path.join(workspace, '.claude', 'settings.local.json'))
name = settings.get('language')
if isinstance(name, str) and name.lower() in NAMES_TO_ISO:
    print(NAMES_TO_ISO[name.lower()])
else:
    config = read(os.path.join(workspace, '.workspace-config.json'))
    code = config.get('language')
    print(code if isinstance(code, str) else '')
" 2>/dev/null || echo "")

# Per-language rule blocks. A language with no block emits nothing — English
# needs no orthography rule, and the built-in section already covers the rest.
case "$LANGUAGE" in
  de)
    RULES='## Sprache und Rechtschreibung

- Vollständige deutsche Rechtschreibung verwenden: alle Umlaute (ä, ö, ü, Ä, Ö, Ü)
  und Eszett (ß). Keine Umschreibungen wie "ae" für "ä", "oe" für "ö", "ue" für
  "ü" oder "ss" für "ß".
- ß nach langem Vokal und Diphthong (Maßnahme, außerhalb, Größe), ss nach kurzem
  Vokal (dass, muss, Prozess). Kein schweizerisches ss an ß-Stellen.
- Wechselt der Benutzer die Sprache, in dessen Sprache antworten — die
  Workspace-Sprache ist die Vorgabe, nicht ein Zwang.'
    ;;
  *)
    exit 0
    ;;
esac

python3 -c "
import json, sys
print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'SessionStart',
        'additionalContext': sys.argv[1],
    }
}))
" "$RULES"

exit 0
