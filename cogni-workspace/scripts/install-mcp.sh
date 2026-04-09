#!/usr/bin/env bash
# install-mcp.sh - Install a git-based MCP server into ~/.claude/mcp-servers/
# Usage: install-mcp.sh --name <name> --repo <git-url> [--build <cmd>] [--wrapper <template>] [--force]
# Output: JSON with success, install path, and wrapper path
#
# The script clones (or pulls) the repo, runs the build command, and
# optionally creates a wrapper script that starts companion services
# (e.g. a canvas server) alongside the MCP stdio process.

set -euo pipefail

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
MCP_BASE_DIR="${CLAUDE_MCP_DIR:-$HOME/.claude/mcp-servers}"

# Defaults
NAME=""
REPO=""
BUILD_CMD="npm install && npm run build"
WRAPPER_TEMPLATE=""
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)    NAME="$2";             shift 2 ;;
    --repo)    REPO="$2";             shift 2 ;;
    --build)   BUILD_CMD="$2";        shift 2 ;;
    --wrapper) WRAPPER_TEMPLATE="$2"; shift 2 ;;
    --force)   FORCE=true;            shift ;;
    *)
      echo "{\"success\":false,\"data\":{\"error\":\"Unknown argument: $1\"}}" >&2
      exit 2
      ;;
  esac
done

# Validate required args
if [ -z "$NAME" ] || [ -z "$REPO" ]; then
  cat <<EOF
{"success":false,"data":{"error":"--name and --repo are required","usage":"install-mcp.sh --name <name> --repo <git-url> [--build <cmd>] [--wrapper <path>] [--force]"}}
EOF
  exit 2
fi

INSTALL_DIR="$MCP_BASE_DIR/$NAME"
WRAPPER_PATH="$INSTALL_DIR/start.sh"

# Resolve wrapper template path before any cd
if [ -n "$WRAPPER_TEMPLATE" ]; then
  WRAPPER_TEMPLATE="$(cd "$(dirname "$WRAPPER_TEMPLATE")" 2>/dev/null && pwd)/$(basename "$WRAPPER_TEMPLATE")"
fi

# Create base directory
mkdir -p "$MCP_BASE_DIR"

# Clone or update
if [ -d "$INSTALL_DIR/.git" ]; then
  if [ "$FORCE" = true ]; then
    cd "$INSTALL_DIR"
    git fetch origin 2>/dev/null
    git reset --hard origin/HEAD 2>/dev/null || git reset --hard origin/main 2>/dev/null
    ACTION="updated"
  else
    # Already installed — check if build artifacts exist
    if [ -d "$INSTALL_DIR/dist" ] || [ -d "$INSTALL_DIR/build" ]; then
      cat <<EOF
{"success":true,"data":{"action":"skipped","install_dir":"$INSTALL_DIR","wrapper":"$WRAPPER_PATH","message":"Already installed. Use --force to update."}}
EOF
      exit 0
    fi
    ACTION="rebuilt"
  fi
else
  # Fresh clone
  rm -rf "$INSTALL_DIR"
  git clone --depth 1 "$REPO" "$INSTALL_DIR" 2>/dev/null
  ACTION="installed"
fi

# Build
cd "$INSTALL_DIR"
if ! eval "$BUILD_CMD" > /tmp/install-mcp-build.log 2>&1; then
  BUILD_LOG=$(tail -5 /tmp/install-mcp-build.log | tr '\n' ' ')
  cat <<EOF
{"success":false,"data":{"error":"Build failed","build_cmd":"$BUILD_CMD","log":"$BUILD_LOG"}}
EOF
  exit 1
fi

# Create wrapper script if template provided
if [ -n "$WRAPPER_TEMPLATE" ] && [ -f "$WRAPPER_TEMPLATE" ]; then
  cp "$WRAPPER_TEMPLATE" "$WRAPPER_PATH"
  chmod +x "$WRAPPER_PATH"
elif [ ! -f "$WRAPPER_PATH" ]; then
  # Default wrapper: just run the main entry point
  cat > "$WRAPPER_PATH" <<'WRAPPER'
#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
exec node "$DIR/dist/index.js"
WRAPPER
  chmod +x "$WRAPPER_PATH"
fi

# Record install metadata
cat > "$INSTALL_DIR/.mcp-install.json" <<EOF
{
  "name": "$NAME",
  "repo": "$REPO",
  "build_cmd": "$BUILD_CMD",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "wrapper": "$WRAPPER_PATH"
}
EOF

cat <<EOF
{"success":true,"data":{"action":"$ACTION","install_dir":"$INSTALL_DIR","wrapper":"$WRAPPER_PATH","name":"$NAME"}}
EOF
