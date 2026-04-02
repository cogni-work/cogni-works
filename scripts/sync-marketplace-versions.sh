#!/usr/bin/env bash
# Sync version fields in .claude-plugin/marketplace.json from each plugin's plugin.json.
# Run after bumping a plugin version to keep marketplace.json in sync for Cowork.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"

if [ ! -f "$MARKETPLACE" ]; then
  echo "ERROR: marketplace.json not found at $MARKETPLACE" >&2
  exit 1
fi

changed=0
for plugin_json in "$REPO_ROOT"/cogni-*/.claude-plugin/plugin.json; do
  plugin_name=$(python3 -c "import json; print(json.load(open('$plugin_json'))['name'])")
  plugin_version=$(python3 -c "import json; print(json.load(open('$plugin_json'))['version'])")

  # Read current marketplace version for this plugin
  market_version=$(python3 -c "
import json
with open('$MARKETPLACE') as f:
    d = json.load(f)
for p in d['plugins']:
    if p['name'] == '$plugin_name':
        print(p.get('version', ''))
        break
")

  if [ "$plugin_version" != "$market_version" ]; then
    echo "  $plugin_name: $market_version -> $plugin_version"
    python3 -c "
import json
with open('$MARKETPLACE') as f:
    d = json.load(f)
for p in d['plugins']:
    if p['name'] == '$plugin_name':
        p['version'] = '$plugin_version'
        break
with open('$MARKETPLACE', 'w') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
    changed=1
  fi
done

if [ "$changed" -eq 0 ]; then
  echo "All marketplace versions are in sync."
else
  echo "Done. marketplace.json updated."
fi
