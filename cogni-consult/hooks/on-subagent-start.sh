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
# The register rules themselves live in references/subagent-output-contract.md,
# following the plugin convention that normative contracts belong in references/.
#
# Emits a SubagentStart hookSpecificOutput envelope on stdout.
# Always exits 0 (non-blocking). Runs once per dispatch, so it stays to a single
# process — the Test-stage and Empathize fan-outs dispatch several in parallel.

set -euo pipefail

# Find workspace: check PROJECT_AGENTS_OPS_ROOT, then cwd
WORKSPACE=""
if [ -n "${PROJECT_AGENTS_OPS_ROOT:-}" ] && [ -f "${PROJECT_AGENTS_OPS_ROOT}/.workspace-config.json" ]; then
  WORKSPACE="$PROJECT_AGENTS_OPS_ROOT"
elif [ -f ".workspace-config.json" ]; then
  WORKSPACE="$(pwd)"
fi

command -v python3 &>/dev/null || exit 0

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

python3 - "$WORKSPACE" "$PLUGIN_ROOT/references/subagent-output-contract.md" <<'PYEOF' || exit 0
import json, os, sys

workspace, contract_path = sys.argv[1], sys.argv[2]

# Keep in step with LANGUAGE_NAMES in cogni-workspace's generate-settings.sh,
# which writes the settings key this reads back.
NAMES_TO_ISO = {"english": "en", "german": "de"}

LANGUAGE_RULES = {
    "de": """Antworte auf Deutsch. Vollständige deutsche Rechtschreibung: alle
Umlaute (ä, ö, ü, Ä, Ö, Ü) und Eszett (ß), keine Umschreibungen wie "ae", "oe",
"ue" oder "ss". ß nach langem Vokal und Diphthong (Maßnahme, außerhalb, Größe),
ss nach kurzem Vokal (dass, muss, Prozess). Kein schweizerisches ss an
ß-Stellen. Fachbegriffe, Slugs, Skill-Namen, CLI-Befehle und Dateinamen bleiben
englisch.""",
}
DEFAULT_LANGUAGE_RULES = """Respond in English. Technical terms, slugs, skill names, CLI
commands, and file names stay in their original form."""


def read_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (IOError, ValueError):
        return {}


# The settings key is the source of truth; .workspace-config.json is the
# fallback for workspaces created before it existed; English when neither is
# present. An empty workspace path simply yields no readable file.
name = read_json(os.path.join(workspace, ".claude", "settings.local.json")).get("language")
if isinstance(name, str) and name.lower() in NAMES_TO_ISO:
    code = NAMES_TO_ISO[name.lower()]
else:
    value = read_json(os.path.join(workspace, ".workspace-config.json")).get("language")
    code = value if isinstance(value, str) else ""

sections = [
    "# Interaction language and output register",
    "## Language (workspace default)\n\n"
    + LANGUAGE_RULES.get(code, DEFAULT_LANGUAGE_RULES)
    + "\n\nIf your dispatch inputs include an `interaction_language`, it wins over"
    " this default — it was resolved against the user's own message.",
]

# Emit the contract from its first "## " heading onward. Everything above that is
# the maintainer preamble explaining why the file exists — true, but not something
# a dispatched agent needs in its context.
try:
    with open(contract_path) as f:
        body = f.read()
    marker = body.find("\n## ")
    sections.append((body[marker:] if marker != -1 else body).strip())
except IOError:
    pass

# Plain stdout is not injected as context — only the parsed
# hookSpecificOutput.additionalContext field is.
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SubagentStart",
        "additionalContext": "\n\n".join(sections),
    }
}))
PYEOF

exit 0
