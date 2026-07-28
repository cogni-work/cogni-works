#!/usr/bin/env bash
# on-session-start-language.sh - Inject the language rules Claude Code's own
# "# Language" system-prompt section does not already carry.
#
# That section (built from the `language` settings key) covers three things for
# every language: respond in it, keep technical terms and code identifiers in
# their original form, and maintain full orthographic correctness including all
# diacritics — never substituting ASCII equivalents, with German examples built
# in. So none of that belongs here.
#
# What it does not cover, and what this hook exists for:
#   - German ß/ss discipline. Choosing ß after a long vowel or diphthong versus
#     ss after a short one is not an ASCII substitution, so the built-in rule
#     says nothing about it.
#   - The mid-conversation switch. The built-in says "Always respond in X" with
#     no escape clause, but workspace doctrine is that a user writing in another
#     language wins over the workspace default.
#
# That is also why the RULES table below is German-only by design rather than by
# omission: other languages have no residue once diacritics are covered upstream.
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

# Inverse of LANGUAGE_NAMES in scripts/generate-settings.sh, which writes the
# settings key this reads back. Keep the two in step.
NAMES_TO_ISO = {
    "english": "en",
    "german": "de",
    "french": "fr",
    "italian": "it",
    "dutch": "nl",
    "polish": "pl",
    "spanish": "es",
}

# Rule blocks keyed by ISO code, holding only what the built-in "# Language"
# section does not carry (see header). A language with no residue has no entry
# and emits nothing.
RULES = {
    "de": """## Rechtschreibung: ß und ss

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
