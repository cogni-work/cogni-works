#!/bin/bash
# setup-gh.sh — readiness probe for cogni-issues
# Usage: bash setup-gh.sh check
#
# Returns a JSON object describing the gh CLI readiness state so the SKILL
# setup mode can branch cleanly:
#   { "platform": "macos|linux|unknown",
#     "gh_installed": bool,
#     "gh_version": "x.y.z" | null,
#     "authenticated": bool,
#     "gh_user": "login" | null,
#     "install_hint": "...",
#     "login_hint": "gh auth login" }
#
# This is a thin wrapper around `gh-issues-helper.sh check` so the SKILL has
# one canonical setup-mode probe and the full helper has one canonical
# readiness implementation. Keeping both names lets older docs / agent
# instructions that reference `setup-gh.sh check` keep working.
#
# Compatible with bash 3.2 (macOS default).

set -euo pipefail

COMMAND="${1:-}"

if [ "$COMMAND" != "check" ]; then
  echo "Usage: bash $0 check" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/gh-issues-helper.sh" check
