#!/usr/bin/env bash
# Workplace Orchestrator - Claude Code Launcher
# Version: 4.0.0
# Plugin: cogni-workspace
# Launches Claude Code from the Obsidian Terminal, setting the workspace language

set -e

# Configuration - substituted by setup script
WORKPLACE_ROOT="{{WORKPLACE_ROOT_WSL}}"
CLAUDE_CMD=""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

show_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    ${BLUE}${BOLD}WORKPLACE${NC}${CYAN} with claude code          ║${NC}"
    echo -e "${CYAN}║      ${MAGENTA}cogni-workspace v4.0.0${CYAN}             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo
}

setup_claude_path() {
    local claude_locations=(
        "$HOME/.local/bin/claude"
        "$HOME/.npm-global/bin/claude"
        "/usr/local/bin/claude"
        "/opt/homebrew/bin/claude"
    )

    # Try npm prefix if available
    local npm_prefix
    npm_prefix="$(npm config get prefix 2>/dev/null || true)"
    if [[ -n "$npm_prefix" ]]; then
        claude_locations+=("${npm_prefix}/bin/claude")
    fi

    for location in "${claude_locations[@]}"; do
        if [[ -x "$location" ]]; then
            CLAUDE_CMD="$location"
            return 0
        fi
    done

    if command -v claude &>/dev/null; then
        CLAUDE_CMD="claude"
        return 0
    fi

    return 1
}

select_language() {
    local default_lang="en"
    if [[ -f "$WORKPLACE_ROOT/.workspace-config.json" ]] && command -v jq &>/dev/null; then
        default_lang="$(jq -r '.language // "en"' "$WORKPLACE_ROOT/.workspace-config.json" 2>/dev/null || echo "en")"
    fi

    echo -e "${YELLOW}Language:${NC}" >&2
    echo -e "  ${GREEN}1${NC}) English" >&2
    echo -e "  ${GREEN}2${NC}) Deutsch" >&2
    echo -e "  ${GREEN}3${NC}) Default (${default_lang})" >&2
    echo "" >&2
    echo -ne "${GREEN}Choose (1-3, default: 3): ${NC}" >&2
    read -r lang_choice

    case "$lang_choice" in
        1) echo "en" ;;
        2) echo "de" ;;
        3|"") echo "$default_lang" ;;
        *) echo "$default_lang" ;;
    esac
}

write_settings_language() {
    local lang="$1"
    local settings="$WORKPLACE_ROOT/.claude/settings.local.json"

    if ! command -v python3 &>/dev/null; then
        echo -e "${YELLOW}⚠${NC} python3 not found — language not switched" >&2
        return 0
    fi

    # The "language" settings key builds a "# Language" system-prompt section,
    # so the choice reaches the session directly. The workspace-root CLAUDE.md
    # is the user's file and is never touched here.
    if python3 - "$settings" "$lang" <<'PYEOF'
import json, os, sys

settings_path, lang = sys.argv[1], sys.argv[2]
# Keep in step with LANGUAGE_NAMES in cogni-workspace/scripts/generate-settings.sh.
# This script runs standalone from the Obsidian terminal with no plugin
# environment, so it cannot source the map from there.
NAMES = {
    "en": "english",
    "de": "german",
    "fr": "french",
    "it": "italian",
    "nl": "dutch",
    "pl": "polish",
    "es": "spanish",
}
name = NAMES.get(lang)
if not name:
    sys.exit(1)

settings = {}
if os.path.isfile(settings_path):
    try:
        with open(settings_path) as f:
            settings = json.load(f)
    except (IOError, ValueError):
        settings = {}

settings["language"] = name
os.makedirs(os.path.dirname(settings_path), exist_ok=True)
with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PYEOF
    then
        echo -e "${GREEN}✓${NC} Session language set to ${lang}" >&2
    else
        echo -e "${YELLOW}⚠${NC} Could not set session language to ${lang}" >&2
    fi
}

launch_claude() {
    cd "$WORKPLACE_ROOT"

    # Source workspace environment
    if [[ -f "$WORKPLACE_ROOT/.workspace-env.sh" ]]; then
        # shellcheck disable=SC1091
        source "$WORKPLACE_ROOT/.workspace-env.sh"
    fi

    echo -e "${GREEN}Launching Claude Code...${NC}"
    echo -e "Workplace: ${BLUE}${WORKPLACE_ROOT}${NC}"
    echo ""

    local LANGUAGE
    LANGUAGE="$(select_language)"
    echo ""

    write_settings_language "$LANGUAGE"
    echo ""

    # No file to probe for: the register ships with the plugin rather than the
    # workspace. Naming the picker rather than a style name keeps this correct if
    # the register is renamed, and honest where the plugin is not installed.
    echo -e "${CYAN}Optional register:${NC} pick the workspace output style in /config"
    echo ""

    exec "$CLAUDE_CMD"
}

main() {
    export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.npm-global/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$PATH"

    if ! setup_claude_path; then
        echo -e "${RED}Claude Code not found${NC}"
        echo "Install: npm install -g @anthropic-ai/claude-code"
        echo ""
        echo "Starting shell instead..."
        cd "$WORKPLACE_ROOT"
        [[ -f "$WORKPLACE_ROOT/.workspace-env.sh" ]] && source "$WORKPLACE_ROOT/.workspace-env.sh"
        exec "${SHELL:-bash}"
    fi

    show_header
    launch_claude
}

main "$@"
