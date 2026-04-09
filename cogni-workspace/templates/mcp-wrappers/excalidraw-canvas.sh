#!/bin/bash
# Wrapper for yctimlin/mcp_excalidraw: starts the canvas server (Express)
# in the background, then runs the MCP server (stdio) in the foreground.
# Installed by cogni-workspace install-mcp.sh — all paths are relative.

DIR="$(cd "$(dirname "$0")" && pwd)"

# Start canvas server in background (suppress output to avoid polluting stdio)
node "$DIR/dist/server.js" > /dev/null 2>&1 &
CANVAS_PID=$!

# Clean up canvas server when MCP server exits
trap "kill $CANVAS_PID 2>/dev/null" EXIT

# Wait briefly for canvas to start
sleep 1

# Run MCP server in foreground (stdio transport)
exec node "$DIR/dist/index.js"
