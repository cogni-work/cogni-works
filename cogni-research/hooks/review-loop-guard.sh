#!/usr/bin/env bash
# review-loop-guard.sh
# Hook: SubagentStop matcher for claim-revisor
# Purpose: Enforce maximum revision iterations (2)
# Reads .metadata/revision-log.json and blocks if iteration count exceeds 2

set -euo pipefail

# Extract project path from the agent's output or environment
# The hook receives the tool input as JSON on stdin
INPUT=$(cat)

# Try to find project path from the agent context
PROJECT_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    # Look for project path in various locations
    for key in ['PROJECT_PATH', 'project_path', 'project-path']:
        if key in data:
            print(data[key])
            sys.exit(0)
    # Try to extract from the output text
    import re
    text = json.dumps(data)
    match = re.search(r'project.path[\":\\s]+([/][^\"\\s,}]+)', text)
    if match:
        print(match.group(1))
        sys.exit(0)
except:
    pass
print('')
" 2>/dev/null || echo "")

if [ -z "$PROJECT_PATH" ]; then
    # Cannot determine project path — allow execution (non-blocking)
    echo '{"success": true, "data": {"message": "Could not determine project path — allowing execution", "blocked": false}}'
    exit 0
fi

REVISION_LOG="$PROJECT_PATH/.metadata/revision-log.json"
MAX_ITERATIONS=2

if [ ! -f "$REVISION_LOG" ]; then
    echo "{\"success\": true, \"data\": {\"iterations_used\": 0, \"max_iterations\": $MAX_ITERATIONS, \"blocked\": false}}"
    exit 0
fi

ITERATIONS=$(python3 -c "
import json, sys
try:
    with open('$REVISION_LOG') as f:
        data = json.load(f)
    print(data.get('total_iterations', 0))
except:
    print(0)
" 2>/dev/null || echo "0")

if [ "$ITERATIONS" -ge "$MAX_ITERATIONS" ]; then
    echo "{\"success\": false, \"error\": \"Max revision iterations ($MAX_ITERATIONS) reached. Total iterations: $ITERATIONS. Proceeding to finalization.\", \"data\": {\"iterations_used\": $ITERATIONS, \"max_iterations\": $MAX_ITERATIONS, \"blocked\": true}}"
    exit 1
fi

echo "{\"success\": true, \"data\": {\"iterations_used\": $ITERATIONS, \"max_iterations\": $MAX_ITERATIONS, \"blocked\": false}}"
exit 0
