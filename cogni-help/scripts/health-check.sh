#!/bin/bash
# Quick health check for cogni-works plugin ecosystem.
# Usage: health-check.sh [project-dir]
# Outputs JSON with plugin availability, stale state, and dependency status.
# Exit codes: 0 = success, 1 = error
set -euo pipefail

PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo '{"error": "Valid directory required. Usage: health-check.sh [project-dir]"}' >&2
  exit 1
fi

# Find the monorepo root (directory containing .claude-plugin/marketplace.json)
MONOREPO_ROOT=""
if [ -f "$PROJECT_DIR/.claude-plugin/marketplace.json" ]; then
  MONOREPO_ROOT="$PROJECT_DIR"
elif [ -n "${COGNI_WORKSPACE_ROOT:-}" ]; then
  # Walk up from workspace root to find monorepo
  CANDIDATE="$(dirname "$COGNI_WORKSPACE_ROOT")"
  if [ -f "$CANDIDATE/.claude-plugin/marketplace.json" ]; then
    MONOREPO_ROOT="$CANDIDATE"
  fi
fi

python3 -c "
import json, os, re, sys

project_dir = '$PROJECT_DIR'
monorepo_root = '$MONOREPO_ROOT'

results = {
    'marketplace': {'status': 'unknown', 'plugins': 0},
    'stale_state': [],
    'missing_deps': [],
    'environment': {}
}

# Check marketplace
if monorepo_root:
    try:
        with open(os.path.join(monorepo_root, '.claude-plugin', 'marketplace.json')) as f:
            mkt = json.load(f)
        plugins = mkt.get('plugins', [])
        results['marketplace'] = {'status': 'ok', 'plugins': len(plugins)}

        # Check each plugin source directory exists
        missing = []
        for p in plugins:
            src = os.path.join(monorepo_root, p['source'].lstrip('./'))
            if not os.path.isdir(src):
                missing.append(p['name'])
        if missing:
            results['marketplace']['status'] = 'warn'
            results['marketplace']['missing_dirs'] = missing
    except Exception as e:
        results['marketplace'] = {'status': 'fail', 'error': str(e)}
else:
    results['marketplace'] = {'status': 'fail', 'error': 'marketplace.json not found'}

# Check for stale state files
stale_checks = [
    ('.claude/cogni-teacher.local.md', 'Renamed to cogni-help.local.md'),
    ('diamond-project.json', 'Renamed to consulting-project.json'),
]
for path, note in stale_checks:
    full = os.path.join(project_dir, path)
    if os.path.exists(full):
        results['stale_state'].append({'file': path, 'fix': note})

# Check environment
for var in ['COGNI_WORKSPACE_ROOT']:
    val = os.environ.get(var, '')
    results['environment'][var] = 'set' if val else 'missing'

# Check tools
import shutil
for tool in ['gh', 'node', 'npm']:
    results['environment'][tool] = 'installed' if shutil.which(tool) else 'missing'

print(json.dumps(results, indent=2))
"
