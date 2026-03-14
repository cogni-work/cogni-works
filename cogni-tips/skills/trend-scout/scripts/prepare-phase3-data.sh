#!/usr/bin/env bash
set -euo pipefail
# prepare-phase3-data.sh
# Version: 2.0.0
# Purpose: Generate compact candidate data for Phase 3 of trend-scout
# Category: utilities
#
# Usage: prepare-phase3-data.sh <PROJECT_PATH>
#
# Arguments:
#   PROJECT_PATH  Absolute path to project directory (required)
#
# Outputs:
#   - ${PROJECT_PATH}/.logs/candidates-compact.json (compact for Claude reading)
#
# Dependencies: jq
#
# Exit codes:
#   0 = success
#   1 = missing PROJECT_PATH argument
#   2 = candidates file not found
#   3 = jq not available


# Validate arguments
if [[ -z "${1:-}" ]]; then
    echo '{"ok":false,"error":"missing_project_path","message":"Usage: prepare-phase3-data.sh <PROJECT_PATH>"}'
    exit 1
fi

PROJECT_PATH="$1"
CANDIDATES_FILE="${PROJECT_PATH}/.logs/trend-generator-candidates.json"

# Validate dependencies
if ! command -v jq &>/dev/null; then
    echo '{"ok":false,"error":"jq_not_found","message":"jq is required but not installed"}'
    exit 3
fi

# Validate input file exists
if [[ ! -f "$CANDIDATES_FILE" ]]; then
    echo "{\"ok\":false,\"error\":\"candidates_not_found\",\"message\":\"File not found: ${CANDIDATES_FILE}\"}"
    exit 2
fi

# Ensure output directories exist
mkdir -p "${PROJECT_PATH}/.logs"

# Generate compact version for Claude (~8-10K tokens instead of ~27K)
# Uses short keys to minimize token usage while preserving all Phase 3 required fields
jq '{
  meta: {
    ts: .generation_metadata.timestamp,
    subsector: .generation_metadata.subsector,
    total: .generation_metadata.total_candidates
  },
  c: [
    (.candidates_by_dimension // .candidates_by_cell) | to_entries[] | .value | to_entries[] |
    # Sort by score descending within each cell
    (.value | sort_by(-.score) | to_entries) | .[] |
    {
      d: .value.dimension,
      h: .value.horizon,
      n: .value.name,
      s: .value.trend_statement,
      r: .value.research_hint,
      k: .value.keywords,
      sc: .value.score,
      ct: .value.confidence_tier,
      si: .value.signal_intensity,
      src: .value.source,
      url: .value.source_url
    }
  ] | sort_by(.d, .h, -.sc)
}' "$CANDIDATES_FILE" > "${PROJECT_PATH}/.logs/candidates-compact.json"

# Calculate file size for verification
COMPACT_SIZE=$(wc -c < "${PROJECT_PATH}/.logs/candidates-compact.json" | tr -d ' ')

# Output success JSON
echo "{\"ok\":true,\"files\":{\"candidates_compact\":\"${PROJECT_PATH}/.logs/candidates-compact.json\"},\"sizes\":{\"compact_bytes\":${COMPACT_SIZE}}}"
