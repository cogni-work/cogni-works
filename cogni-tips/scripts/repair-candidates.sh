#!/usr/bin/env bash
set -euo pipefail
# repair-candidates.sh
# Version: 1.0.0
# Purpose: Backfill missing dimension/horizon fields in trend-scout-output.json
# Category: utilities
#
# Usage: repair-candidates.sh --project-path <path> [--json] [--dry-run]
#
# Arguments:
#   --project-path <path>  Absolute path to project directory (required)
#   --json                 Output JSON format (optional)
#   --dry-run              Show what would change without writing (optional)
#
# Strategy:
#   1. If .logs/trend-generator-candidates.json exists, rebuild from authoritative nested source
#   2. Otherwise, use position-based inference (15 candidates per dimension)
#
# Exit codes:
#   0 - Success (or nothing to repair)
#   1 - Validation error
#   2 - File not found
#   3 - jq error


PROJECT_PATH=""
JSON_OUTPUT=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    --json) JSON_OUTPUT=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$PROJECT_PATH" ]]; then
  echo '{"success": false, "error": "Missing --project-path"}' >&2
  exit 1
fi

OUTPUT_FILE="${PROJECT_PATH}/.metadata/trend-scout-output.json"
GENERATOR_LOG="${PROJECT_PATH}/.logs/trend-generator-candidates.json"

if [[ ! -f "$OUTPUT_FILE" ]]; then
  if $JSON_OUTPUT; then
    echo "{\"success\": false, \"error\": \"File not found: $OUTPUT_FILE\"}"
  else
    echo "Error: File not found: $OUTPUT_FILE" >&2
  fi
  exit 2
fi

if ! command -v jq &>/dev/null; then
  echo '{"success": false, "error": "jq is required"}' >&2
  exit 3
fi

# Check if repair is needed
MISSING_COUNT=$(python3 -c "
import json
d = json.load(open('$OUTPUT_FILE'))
items = d.get('tips_candidates', {}).get('items', [])
missing = sum(1 for i in items if not i.get('dimension'))
print(missing)
" 2>/dev/null || echo "0")

if [[ "$MISSING_COUNT" == "0" ]]; then
  if $JSON_OUTPUT; then
    echo '{"success": true, "repaired": 0, "method": "none", "message": "All candidates already have dimension fields"}'
  else
    echo "No repair needed — all candidates already have dimension fields."
  fi
  exit 0
fi

# Strategy 1: Rebuild from authoritative generator log
if [[ -f "$GENERATOR_LOG" ]]; then
  METHOD="generator-log"

  REPAIRED=$(jq '[(.candidates_by_dimension // .candidates_by_cell) | to_entries[] | .key as $dim | .value | to_entries[] | .key as $hor | .value[] | . + {dimension: $dim, horizon: $hor}]' "$GENERATOR_LOG" 2>/dev/null)

  if [[ -z "$REPAIRED" ]] || [[ "$REPAIRED" == "null" ]]; then
    METHOD="position-based"
  else
    REPAIRED_COUNT=$(echo "$REPAIRED" | jq 'length')
    if [[ "$REPAIRED_COUNT" -lt 1 ]]; then
      METHOD="position-based"
    fi
  fi
fi

# Strategy 2: Position-based inference
if [[ "${METHOD:-position-based}" == "position-based" ]]; then
  METHOD="position-based"

  REPAIRED=$(jq '.tips_candidates.items | [to_entries[] | .value + {
    dimension: (["externe-effekte","neue-horizonte","digitale-wertetreiber","digitales-fundament"][([(.key / 15 | floor), 3] | min)]),
    horizon: (if (.key % 15) < 5 then "act" elif (.key % 15) < 10 then "plan" else "observe" end)
  }]' "$OUTPUT_FILE" 2>/dev/null)

  if [[ -z "$REPAIRED" ]] || [[ "$REPAIRED" == "null" ]]; then
    if $JSON_OUTPUT; then
      echo '{"success": false, "error": "Failed to repair candidates with position-based inference"}'
    else
      echo "Error: Failed to repair candidates" >&2
    fi
    exit 3
  fi
fi

# Verify dimension distribution
DIST=$(echo "$REPAIRED" | python3 -c "
import json, sys
items = json.load(sys.stdin)
dims = {}
for it in items:
    d = it.get('dimension', 'unknown')
    dims[d] = dims.get(d, 0) + 1
print(json.dumps(dims))
" 2>/dev/null)

if $DRY_RUN; then
  if $JSON_OUTPUT; then
    echo "{\"success\": true, \"dry_run\": true, \"would_repair\": $MISSING_COUNT, \"method\": \"$METHOD\", \"distribution\": $DIST}"
  else
    echo "Dry run — would repair $MISSING_COUNT candidates using $METHOD method"
    echo "Distribution: $DIST"
  fi
  exit 0
fi

# Apply repair atomically
jq --argjson items "$REPAIRED" '.tips_candidates.items = $items' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" \
  && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

FINAL_COUNT=$(echo "$REPAIRED" | jq 'length')

if $JSON_OUTPUT; then
  echo "{\"success\": true, \"repaired\": $MISSING_COUNT, \"total\": $FINAL_COUNT, \"method\": \"$METHOD\", \"distribution\": $DIST}"
else
  echo "Repaired $MISSING_COUNT candidates (method: $METHOD, total: $FINAL_COUNT)"
  echo "Distribution: $DIST"
fi
