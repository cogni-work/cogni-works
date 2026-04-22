#!/usr/bin/env bash
# clone-taxonomy.sh — Copy a bundled taxonomy template into a portfolio project
# for local customization. After the copy, the project owns its taxonomy — edits
# stay local, survive plugin updates, and override the bundled template during
# scan/setup resolution.
#
# Usage:
#   clone-taxonomy.sh <project_path> <base_type> [--force]
#
# Arguments:
#   project_path  Absolute path to the portfolio project (dir containing portfolio.json)
#   base_type     Slug of a bundled template (b2b-ict, b2b-saas, b2b-fintech, ...)
#   --force       Overwrite an existing project-local taxonomy (default: refuse)
#
# Output (stdout, single JSON object):
#   {"success": true,  "data": {...}}   on success
#   {"success": false, "error": "..."}  on any failure (exit 1)
#
# Contract:
# - Never writes files outside <project_path>/taxonomy/ or <project_path>/portfolio.json.
# - Never touches the bundled template directory (read-only source).
# - On success: <project_path>/taxonomy/ contains the 7–8 canonical template files,
#   and portfolio.json's taxonomy.source_path is set to "taxonomy/" so the resolver
#   picks up the clone.
# - On failure (missing inputs, collision without --force, read errors): exit 1 with
#   {"success": false, "error": "..."} and make no changes.

set -euo pipefail

die() {
  printf '{"success":false,"error":"%s"}\n' "$1"
  exit 1
}

[ $# -ge 2 ] || die "usage: clone-taxonomy.sh <project_path> <base_type> [--force]"

PROJECT_PATH="$1"
BASE_TYPE="$2"
FORCE="no"
[ "${3:-}" = "--force" ] && FORCE="yes"

# Locate plugin root — the script lives in {plugin_root}/scripts/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$PLUGIN_ROOT/templates/$BASE_TYPE"
DEST_DIR="$PROJECT_PATH/taxonomy"
PORTFOLIO_JSON="$PROJECT_PATH/portfolio.json"

[ -d "$PROJECT_PATH" ]   || die "project_path not found: $PROJECT_PATH"
[ -f "$PORTFOLIO_JSON" ] || die "portfolio.json not found in project: $PORTFOLIO_JSON"
[ -d "$SRC_DIR" ]        || die "bundled template not found: $BASE_TYPE (looked in $SRC_DIR)"

if [ -d "$DEST_DIR" ] && [ "$FORCE" != "yes" ]; then
  die "project-local taxonomy already exists at $DEST_DIR; re-run with --force to overwrite"
fi

# Copy template bundle
mkdir -p "$DEST_DIR"
# cp -R of the directory contents (not the directory itself) — works on macOS bash 3.2
for f in "$SRC_DIR"/*; do
  cp -R "$f" "$DEST_DIR/"
done

# Record the clone in portfolio.json: set taxonomy.source_path so the resolver
# finds the project-local version, and taxonomy.cloned_from so downstream skills
# can audit provenance. Keep taxonomy.type as the base type unless the user
# later renames the clone.
python3 - "$PORTFOLIO_JSON" "$BASE_TYPE" <<'PY'
import json, sys, datetime
path, base_type = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
tax = data.get("taxonomy") or {}
tax["type"] = tax.get("type") or base_type
tax["source_path"] = "taxonomy/"
tax["cloned_from"] = base_type
tax["cloned_at"] = datetime.date.today().isoformat()
data["taxonomy"] = tax
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY

# Count files copied for the success payload
FILE_COUNT="$(find "$DEST_DIR" -maxdepth 1 -type f | wc -l | tr -d ' ')"

printf '{"success":true,"data":{"base_type":"%s","dest":"%s","files_copied":%s,"portfolio_json_updated":true}}\n' \
  "$BASE_TYPE" "$DEST_DIR" "$FILE_COUNT"
