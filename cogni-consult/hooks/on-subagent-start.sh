#!/usr/bin/env bash
# on-subagent-start.sh - Carry the interaction language and the register's hard
# rules into cogni-consult's dispatched agents.
#
# A subagent's system prompt is its own body plus a short notes block and the
# environment info. The "language" settings key, the workspace CLAUDE.md, and any
# active output style all reach the main loop only — none of them reach here. So
# an agent that writes user-facing prose (a persona's objections, an empathy map,
# an adherence finding) would default to English and to engine vocabulary unless
# something injects the rules at dispatch time. This is that something.
#
# It supplies the workspace *default* language. A hook cannot see the user's
# message, so rung 2 of references/interaction-language.md (message-detection
# override) is resolved by the dispatching skill and passed as an
# `interaction_language` input, which wins over what is emitted here.
#
# Emits a SubagentStart hookSpecificOutput envelope on stdout.
# Always exits 0 (non-blocking).

set -euo pipefail

# Find workspace: check PROJECT_AGENTS_OPS_ROOT, then cwd
WORKSPACE=""
if [ -n "${PROJECT_AGENTS_OPS_ROOT:-}" ] && [ -f "${PROJECT_AGENTS_OPS_ROOT}/.workspace-config.json" ]; then
  WORKSPACE="$PROJECT_AGENTS_OPS_ROOT"
elif [ -f ".workspace-config.json" ]; then
  WORKSPACE="$(pwd)"
fi

if ! command -v python3 &>/dev/null; then
  exit 0
fi

# Resolve the workspace default. The settings key is the source of truth;
# .workspace-config.json is the fallback for workspaces created before it
# existed; English when neither is present.
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

code = ''
if workspace:
    settings = read(os.path.join(workspace, '.claude', 'settings.local.json'))
    name = settings.get('language')
    if isinstance(name, str) and name.lower() in NAMES_TO_ISO:
        code = NAMES_TO_ISO[name.lower()]
    else:
        value = read(os.path.join(workspace, '.workspace-config.json')).get('language')
        code = value if isinstance(value, str) else ''
print(code or 'en')
" 2>/dev/null || echo "en")

case "$LANGUAGE" in
  de)
    LANGUAGE_RULES='Antworte auf Deutsch. Vollständige deutsche Rechtschreibung: alle
Umlaute (ä, ö, ü, Ä, Ö, Ü) und Eszett (ß), keine Umschreibungen wie "ae", "oe",
"ue" oder "ss". ß nach langem Vokal und Diphthong (Maßnahme, außerhalb, Größe),
ss nach kurzem Vokal (dass, muss, Prozess). Kein schweizerisches ss an
ß-Stellen. Fachbegriffe, Slugs, Skill-Namen, CLI-Befehle und Dateinamen bleiben
englisch.'
    ;;
  *)
    LANGUAGE_RULES='Respond in English. Technical terms, slugs, skill names, CLI
commands, and file names stay in their original form.'
    ;;
esac

CONTEXT="# Interaction language and output register

Your envelope fields carry user-facing prose. It is read by a consultant, not by
the operator of this system, so these rules bind everything you write.

## Language (workspace default)

${LANGUAGE_RULES}

If your dispatch inputs include an \`interaction_language\`, it wins over this
default — it was resolved against the user's own message.

## Register

- Executive register: precise, concise, no filler, no restating the question, no
  postamble. Compression loses words, never a fact, number, caveat, or option.
- Engine vocabulary stays in the engine. Cascade, graph, edge, \`depends_on\`,
  gate, slug, state values (\`complete\`, \`pending\`), log ids (\`d-084\`) are
  internal. Report the business consequence instead.
- Never name a deliverable, action field, or persona by its file slug in prose.
  Use its plain name. Slugs belong in structured fields, not in sentences."

python3 -c "
import json, sys
print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'SubagentStart',
        'additionalContext': sys.argv[1],
    }
}))
" "$CONTEXT"

exit 0
