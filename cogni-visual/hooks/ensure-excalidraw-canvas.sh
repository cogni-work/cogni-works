#!/usr/bin/env bash
# Ensure Excalidraw canvas frontend is running and browser is open before MCP
# tool execution. Triggered by PreToolUse hook for all mcp__excalidraw__* tools.
#
# The Excalidraw MCP server (stdio) runs separately from the canvas frontend
# (Express + WebSocket on port 3000). Tools like describe_scene, export_scene,
# export_to_image, and get_canvas_screenshot require the frontend AND a browser
# tab open at localhost:3000.
#
# Reliability model:
#   1. Fast path (~10ms): port listening AND WebSocket client connected → exit 0
#   2. Canvas down: start server, open browser, wait for WS connection
#   3. Tab closed: detect websocket_clients=0, re-open browser, wait for WS
#   No sticky /tmp flags — always checks actual WebSocket state.
#
# Start serialisation:
#   cogni-visual and cogni-portfolio ship byte-identical copies of this script
#   and register the same unqualified mcp__excalidraw__* PreToolUse matcher, so
#   on a machine carrying both plugins every tool call dispatches two of these
#   in parallel. The port probe below is a check, not a mutual-exclusion
#   primitive: two invocations against a cold canvas can both fall through it
#   and both spawn a server, leaving the loser dead on EADDRINUSE and the pid
#   file naming a dead process. The spawn is therefore taken behind an atomic
#   directory claim; the loser skips the spawn and waits on the same port the
#   winner is binding.

set -euo pipefail

EXCALIDRAW_DIR="${EXCALIDRAW_MCP_DIR:-$HOME/.claude/mcp-servers/mcp_excalidraw}"
PORT="${EXCALIDRAW_CANVAS_PORT:-3000}"
LOG_FILE="${EXCALIDRAW_DIR}/excalidraw-canvas.log"
PID_FILE="${EXCALIDRAW_DIR}/canvas.pid"

# Consume stdin (hook input JSON) to prevent broken pipe
cat > /dev/null

# Check if a WebSocket client is connected via the /health endpoint
has_ws_client() {
  local health
  health=$(curl -sf "http://localhost:${PORT}/health" 2>/dev/null) || return 1
  echo "$health" | grep -qE '"websocket_clients":[1-9]'
}

# Open browser (platform-aware)
open_browser() {
  local url="http://localhost:${PORT}"
  case "$(uname -s)" in
    Darwin) open "$url" ;;
    Linux)  xdg-open "$url" 2>/dev/null || true ;;
  esac
}

# Fast path: port up AND WebSocket client connected. Nothing above this point
# touches the start claim, so an already-warm canvas costs one probe plus one
# /health call, exactly as before.
if nc -z localhost "$PORT" 2>/dev/null && has_ws_client; then
  exit 0
fi

# If port not up: start canvas server
if ! nc -z localhost "$PORT" 2>/dev/null; then
  LOCK_DIR="${EXCALIDRAW_DIR}/canvas-start.lock"
  # Four times the hook's own 15s timeout (hooks.json), so a spawn killed at
  # that deadline expires but a healthy in-flight winner is never robbed.
  LOCK_STALE_SECS=60
  # Declared before the handler that reads it, which runs under `set -u`.
  SPAWN_CLAIMED=0

  # Release the claim, but only if this invocation actually holds it. The guard
  # is load-bearing rather than cosmetic: the trap below is armed
  # unconditionally, so without it a loser exiting through the shared wait-loop
  # paths would delete the winner's claim mid-spawn.
  release_start_claim() {
    if [[ "$SPAWN_CLAIMED" -eq 1 ]]; then
      SPAWN_CLAIMED=0
      rmdir "$LOCK_DIR" 2>/dev/null || true
    fi
  }

  # Bare mkdir is the claim: atomic on POSIX, and it fails when the directory
  # already exists, which is the exclusion signal. Never `mkdir -p`, which
  # succeeds against an existing directory and so cannot tell winner from
  # loser. flock(1) is not stock on macOS, which this script already targets.
  try_claim_start() {
    mkdir "$LOCK_DIR" 2>/dev/null
  }

  # Armed before the claim is taken, so every exit reachable while it is held
  # is covered — including a SIGTERM at the hook's 15s deadline, which lands in
  # one of the wait loops below rather than at a clean exit. Bash traps are
  # process-global, so this still fires at the final exit outside this branch.
  trap release_start_claim EXIT INT TERM

  if [[ ! -f "${EXCALIDRAW_DIR}/dist/server.js" ]]; then
    echo "Warning: Excalidraw canvas server not found at ${EXCALIDRAW_DIR}/dist/server.js" >&2
    exit 0
  fi

  # Claim the start. The attempt sits in an `if` condition so a lost claim
  # cannot abort the hook under `set -e` — a non-zero exit here would block the
  # very tool call this hook exists to enable.
  if try_claim_start; then
    SPAWN_CLAIMED=1
  elif [[ -d "$LOCK_DIR" ]]; then
    # Sweep a claim left behind by a spawn killed before it could release. The
    # stat chain resolves into a variable first: an empty command substitution
    # nested inside $(( )) is a hard bash syntax error.
    lock_mtime=$(stat -f %m "$LOCK_DIR" 2>/dev/null || stat -c %Y "$LOCK_DIR" 2>/dev/null || echo 0)
    [[ -n "$lock_mtime" ]] || lock_mtime=0
    now_secs=$(date +%s)
    lock_age=$(( now_secs - lock_mtime ))
    if [[ "$lock_age" -gt "$LOCK_STALE_SECS" ]]; then
      rmdir "$LOCK_DIR" 2>/dev/null || true
      if try_claim_start; then
        SPAWN_CLAIMED=1
      fi
    fi
  fi

  # Only the winner spawns, and only the winner writes the pid file — so
  # canvas.pid can never name a process that lost an EADDRINUSE race.
  if [[ "$SPAWN_CLAIMED" -eq 1 ]]; then
    cd "$EXCALIDRAW_DIR"
    nohup node dist/server.js > "$LOG_FILE" 2>&1 &
    CANVAS_PID=$!
    echo "$CANVAS_PID" > "$PID_FILE"
  fi

  # Wait for port to become available (max 10 seconds). Reached by winner and
  # loser alike: the loser's rendezvous is the port the winner is binding, so
  # it needs no wait loop of its own.
  for _ in $(seq 1 20); do
    nc -z localhost "$PORT" 2>/dev/null && break
    sleep 0.5
  done

  if ! nc -z localhost "$PORT" 2>/dev/null; then
    echo "Warning: Excalidraw canvas frontend did not start within 10s" >&2
    exit 0
  fi
fi

# Port is up but no WS client → open browser and wait for connection
if ! has_ws_client; then
  open_browser

  # Wait for WS client to connect (max 5s)
  for _ in $(seq 1 10); do
    sleep 0.5
    has_ws_client && break
  done
fi

# Report status
if has_ws_client; then
  echo '{"systemMessage": "Excalidraw canvas ready with browser connected"}'
else
  echo '{"systemMessage": "Warning: Excalidraw canvas running but no browser connected — export_to_image and get_canvas_screenshot may fail. Open http://localhost:'"${PORT}"' in your browser."}'
fi
exit 0
