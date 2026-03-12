#!/usr/bin/env bash
set -euo pipefail
# generate-scan-mapping.sh
# Version: 3.0.0
# Purpose: Generate category-to-entity mapping from scan research logs
# Category: utilities
#
# Usage: generate-scan-mapping.sh --project-path <path> [--output <path>] [--plugin-root <path>]
#
# Arguments:
#   --project-path <path>  Portfolio project directory (required)
#   --output <path>        Output path (optional, defaults to research/.metadata/portfolio-category-mapping.json)
#   --plugin-root <path>   Plugin root directory (optional, defaults to CLAUDE_PLUGIN_ROOT or script's grandparent)
#
# Output (JSON):
#   {
#     "success": true,
#     "data": {
#       "project_slug": "company-slug",
#       "generated_at": "ISO-8601",
#       "category_count": N,
#       "mapped_count": N,
#       "mappings": { ... }
#     }
#   }
#
# Exit codes:
#   0 - Success
#   1 - Invalid project path
#   2 - No research logs found
#   3 - Usage error
#   4 - Unsupported taxonomy type

error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

main() {
    local project_path="" output_path="" plugin_root=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path) project_path="${2:-}"; shift 2 ;;
            --output) output_path="${2:-}"; shift 2 ;;
            --plugin-root) plugin_root="${2:-}"; shift 2 ;;
            *) error_json "Unknown argument: $1" 3 ;;
        esac
    done

    # Validate inputs
    [[ -n "$project_path" ]] || error_json "Project path required (--project-path)" 3
    [[ -d "$project_path" ]] || error_json "Project path not found: $project_path" 1

    local logs_dir="$project_path/research/.logs"
    [[ -d "$logs_dir" ]] || error_json "Research logs directory not found: $logs_dir" 1

    # Resolve plugin root
    if [[ -z "$plugin_root" ]]; then
        if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
            plugin_root="$CLAUDE_PLUGIN_ROOT"
        else
            # Default: script is in scripts/, plugin root is parent
            plugin_root="$(cd "$(dirname "$0")/.." && pwd)"
        fi
    fi

    # Resolve taxonomy type from portfolio.json
    local portfolio_json="$project_path/portfolio.json"
    local taxonomy_type=""
    if [[ -f "$portfolio_json" ]]; then
        taxonomy_type="$(jq -r '.taxonomy.type // ""' "$portfolio_json")"
    fi
    [[ -n "$taxonomy_type" ]] || taxonomy_type="b2b-ict"

    # Load categories from template
    local categories_file="$plugin_root/templates/$taxonomy_type/categories.json"
    if [[ ! -f "$categories_file" ]]; then
        error_json "Categories file not found for taxonomy '$taxonomy_type': $categories_file" 4
    fi

    local category_count
    category_count="$(jq 'length' "$categories_file")"

    # Set default output path
    if [[ -z "$output_path" ]]; then
        output_path="$project_path/research/.metadata/portfolio-category-mapping.json"
    fi

    # Ensure output directory exists
    local metadata_dir
    metadata_dir="$(dirname "$output_path")"
    mkdir -p "$metadata_dir"

    # Get project slug from path
    local project_slug
    project_slug="$(basename "$project_path")"

    # Find research log files
    local log_files=()
    while IFS= read -r f; do
        [[ -n "$f" ]] && log_files+=("$f")
    done < <(find "$logs_dir" -name "portfolio-web-research-*.json" -type f 2>/dev/null || true)

    if [[ ${#log_files[@]} -eq 0 ]]; then
        error_json "No research log files found in $logs_dir" 2
    fi

    # Initialize mappings object from categories.json
    local mappings_json
    mappings_json="$(jq '
        reduce .[] as $cat ({};
            .[$cat.id] = {
                category_name: $cat.name,
                dimension: $cat.dimension_slug,
                offerings: []
            }
        )
    ' "$categories_file")"

    # Process each log file
    local total_offerings=0
    for file in "${log_files[@]}"; do
        # Extract offerings and map to categories
        local offerings_count
        offerings_count="$(jq '.offerings | length' "$file" 2>/dev/null || echo "0")"

        if [[ "$offerings_count" -gt 0 ]]; then
            # For each offering, add to the appropriate category
            local i=0
            while [[ $i -lt $offerings_count ]]; do
                local cat_id offering_name
                cat_id="$(jq -r ".offerings[$i].category // \"\"" "$file")"
                offering_name="$(jq -r ".offerings[$i].name // \"\"" "$file")"

                if [[ -n "$cat_id" && -n "$offering_name" ]]; then
                    mappings_json="$(echo "$mappings_json" | jq \
                        --arg id "$cat_id" \
                        --arg name "$offering_name" \
                        'if .[$id] then .[$id].offerings += [$name] else . end')"
                    ((total_offerings++)) || true
                fi
                ((i++)) || true
            done
        fi
    done

    # Count categories with at least one offering
    local categories_with_offerings
    categories_with_offerings="$(echo "$mappings_json" | jq '[.[] | select(.offerings | length > 0)] | length')"

    # Build final output
    local generated_at
    generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    local output_json
    output_json="$(jq -n \
        --arg project "$project_slug" \
        --arg ts "$generated_at" \
        --arg taxonomy "$taxonomy_type" \
        --argjson cat_count "$category_count" \
        --argjson mapped "$categories_with_offerings" \
        --argjson offerings "$total_offerings" \
        --argjson mappings "$mappings_json" \
        '{
            project_slug: $project,
            generated_at: $ts,
            taxonomy_type: $taxonomy,
            category_count: $cat_count,
            mapped_count: $mapped,
            total_offerings: $offerings,
            mappings: $mappings
        }')"

    # Write to file
    echo "$output_json" > "$output_path"

    # Return success response
    jq -n \
        --arg path "$output_path" \
        --arg taxonomy "$taxonomy_type" \
        --argjson mapped "$categories_with_offerings" \
        --argjson offerings "$total_offerings" \
        '{
            success: true,
            data: {
                output_file: $path,
                taxonomy_type: $taxonomy,
                categories_mapped: $mapped,
                offerings_processed: $offerings
            }
        }'
}

main "$@"
