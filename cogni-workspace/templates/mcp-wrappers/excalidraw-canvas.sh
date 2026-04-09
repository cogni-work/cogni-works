#!/bin/bash
# Wrapper for yctimlin/mcp_excalidraw: starts the canvas server (Express)
# in the background, then runs the MCP server (stdio) in the foreground.
# Installed by cogni-workspace install-mcp.sh — all paths are relative.

DIR="$(cd "$(dirname "$0")" && pwd)"
PORT="${EXCALIDRAW_CANVAS_PORT:-3000}"
LOG_FILE="${DIR}/excalidraw-canvas.log"

# Start canvas server in background with logging
node "$DIR/dist/server.js" > "$LOG_FILE" 2>&1 &
CANVAS_PID=$!

# Clean up canvas server when MCP server exits
trap "kill $CANVAS_PID 2>/dev/null" EXIT

# Wait for canvas to be ready (max 10s, adaptive)
for _ in $(seq 1 20); do
  nc -z localhost "$PORT" 2>/dev/null && break
  sleep 0.5
done

if ! nc -z localhost "$PORT" 2>/dev/null; then
  echo "Warning: Canvas server did not start on port $PORT — check $LOG_FILE" >&2
fi

# Run MCP server in foreground (stdio transport)
exec node "$DIR/dist/index.js"
