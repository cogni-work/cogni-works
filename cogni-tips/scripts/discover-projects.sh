#!/bin/bash
# Discover cogni-tips projects in the workspace.
# Usage: discover-projects.sh [--json]
# Scans for tips-project.json and trend-scout-output.json under cogni-tips/ directories.
# Returns one line per project (default) or a JSON array (--json).
# Exit codes: 0 = success (even if 0 projects found)
set -euo pipefail

JSON_OUTPUT=false
if [ "${1:-}" = "--json" ]; then
  JSON_OUTPUT=true
fi

SEARCH_ROOT="${COGNI_WORKSPACE_ROOT:-$(pwd)}"

# Find projects by tips-project.json (preferred) or trend-scout-output.json (fallback)
declare -a PROJECT_DIRS=()

# Method 1: tips-project.json in cogni-tips/*/
while IFS= read -r f; do
  dir="$(dirname "$f")"
  PROJECT_DIRS+=("$dir")
done < <(find "$SEARCH_ROOT" -maxdepth 4 -name "tips-project.json" -path "*/cogni-tips/*" 2>/dev/null || true)

# Method 2: trend-scout-output.json (for projects without tips-project.json)
while IFS= read -r f; do
  dir="$(dirname "$(dirname "$f")")"  # go up from .metadata/
  # Skip if already found via tips-project.json
  already_found=false
  for existing in "${PROJECT_DIRS[@]+"${PROJECT_DIRS[@]}"}"; do
    if [ "$existing" = "$dir" ]; then
      already_found=true
      break
    fi
  done
  if [ "$already_found" = false ]; then
    PROJECT_DIRS+=("$dir")
  fi
done < <(find "$SEARCH_ROOT" -maxdepth 5 -name "trend-scout-output.json" -path "*/cogni-tips/*/.metadata/*" 2>/dev/null || true)

if [ "$JSON_OUTPUT" = true ]; then
  python3 -c "
import json, os, sys

dirs = sys.argv[1:]
projects = []

for d in dirs:
    project = {'path': d, 'slug': os.path.basename(d)}

    # Try tips-project.json first
    pf = os.path.join(d, 'tips-project.json')
    if os.path.exists(pf):
        try:
            data = json.load(open(pf))
            project['slug'] = data.get('slug', project['slug'])
            project['language'] = data.get('language', 'en')
            ind = data.get('industry', {})
            project['industry'] = ind.get('primary_en') or ind.get('primary') or ''
            project['subsector'] = ind.get('subsector_en') or ind.get('subsector') or ''
            project['research_topic'] = data.get('research_topic') or ''
            project['updated'] = data.get('updated', data.get('created', ''))
        except Exception:
            pass

    # Enrich with workflow state from trend-scout-output.json
    sf = os.path.join(d, '.metadata', 'trend-scout-output.json')
    if os.path.exists(sf):
        try:
            data = json.load(open(sf))
            exe = data.get('execution', {})
            project['workflow_state'] = exe.get('workflow_state', 'unknown')
            project['candidates_total'] = data.get('tips_candidates', {}).get('total', 0)
            # Fill gaps from scout output if tips-project.json was sparse
            if not project.get('industry'):
                ind = data.get('config', {}).get('industry', {})
                project['industry'] = ind.get('primary_en') or ind.get('primary') or ''
                project['subsector'] = ind.get('subsector_en') or ind.get('subsector') or ''
            if not project.get('research_topic'):
                project['research_topic'] = data.get('config', {}).get('research_topic') or ''
            if not project.get('language'):
                project['language'] = data.get('project_language', 'en')
        except Exception:
            project.setdefault('workflow_state', 'unknown')
            project.setdefault('candidates_total', 0)

    # Check for report
    project['has_report'] = os.path.exists(os.path.join(d, 'tips-trend-report.md'))

    projects.append(project)

print(json.dumps({'count': len(projects), 'projects': projects}, indent=2, ensure_ascii=False))
" "${PROJECT_DIRS[@]+"${PROJECT_DIRS[@]}"}"
else
  if [ ${#PROJECT_DIRS[@]} -eq 0 ]; then
    echo "No cogni-tips projects found in $SEARCH_ROOT"
  else
    for dir in "${PROJECT_DIRS[@]}"; do
      echo "$dir"
    done
  fi
fi
