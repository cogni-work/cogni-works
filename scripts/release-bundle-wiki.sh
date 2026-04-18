#!/usr/bin/env bash
# release-bundle-wiki.sh — copy the source-of-truth insight-wave wiki into
# cogni-workspace/wiki/ for marketplace distribution.
#
# The wiki at insight-wave/wiki/ is the source of truth (edited by maintainers,
# git-tracked). Marketplace users get the wiki bundled inside cogni-workspace
# so it lands in their plugin cache on install. This script keeps the bundled
# copy in sync with the source of truth.
#
# Run BEFORE every cogni-workspace marketplace publish. Drift between the two
# copies between releases is acceptable — only publishes need the copy fresh.
#
# Usage:
#   scripts/release-bundle-wiki.sh                    # full sync (rsync --delete)
#   scripts/release-bundle-wiki.sh --check            # dry-run; report diff but don't write
#
# Output: JSON to stdout per insight-wave script convention.
#   {"success": true, "data": {...}, "error": ""}

set -eu

SOURCE_WIKI="$(cd "$(dirname "$0")/.." && pwd)/wiki"
BUNDLED_WIKI="$(cd "$(dirname "$0")/.." && pwd)/cogni-workspace/wiki"
MODE="sync"

while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE="check"; shift ;;
    -h|--help)
      sed -n '2,18p' "$0"
      exit 0
      ;;
    *)
      printf '{"success": false, "data": {}, "error": "unknown argument: %s"}\n' "$1"
      exit 1
      ;;
  esac
done

if [ ! -d "$SOURCE_WIKI" ]; then
  printf '{"success": false, "data": {}, "error": "source wiki not found at %s"}\n' "$SOURCE_WIKI"
  exit 1
fi

if [ ! -f "$SOURCE_WIKI/.cogni-wiki/config.json" ]; then
  printf '{"success": false, "data": {}, "error": "source wiki at %s is missing .cogni-wiki/config.json — not a valid wiki"}\n' "$SOURCE_WIKI"
  exit 1
fi

# Count source pages for reporting
SOURCE_PAGE_COUNT=$(find "$SOURCE_WIKI/wiki/pages" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

if [ "$MODE" = "check" ]; then
  # Dry-run: rsync --dry-run reports what would change without writing
  if [ ! -d "$BUNDLED_WIKI" ]; then
    DIFF_LINES=$(find "$SOURCE_WIKI" -type f 2>/dev/null | wc -l | tr -d ' ')
    printf '{"success": true, "data": {"mode": "check", "source": "%s", "bundled": "%s", "bundled_exists": false, "files_to_create": %s, "source_page_count": %s}, "error": ""}\n' \
      "$SOURCE_WIKI" "$BUNDLED_WIKI" "$DIFF_LINES" "$SOURCE_PAGE_COUNT"
  else
    DIFF_LINES=$(rsync -anci --delete "$SOURCE_WIKI/" "$BUNDLED_WIKI/" 2>/dev/null | wc -l | tr -d ' ')
    printf '{"success": true, "data": {"mode": "check", "source": "%s", "bundled": "%s", "bundled_exists": true, "changes_pending": %s, "source_page_count": %s}, "error": ""}\n' \
      "$SOURCE_WIKI" "$BUNDLED_WIKI" "$DIFF_LINES" "$SOURCE_PAGE_COUNT"
  fi
  exit 0
fi

# Sync mode: rsync the source wiki over the bundled copy
if ! command -v rsync >/dev/null 2>&1; then
  printf '{"success": false, "data": {}, "error": "rsync not found in PATH"}\n'
  exit 1
fi

mkdir -p "$BUNDLED_WIKI"
RSYNC_OUTPUT=$(rsync -a --delete "$SOURCE_WIKI/" "$BUNDLED_WIKI/" 2>&1) || {
  ESCAPED=$(printf '%s' "$RSYNC_OUTPUT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')
  printf '{"success": false, "data": {}, "error": %s}\n' "$ESCAPED"
  exit 1
}

# Verify bundled copy parity
BUNDLED_PAGE_COUNT=$(find "$BUNDLED_WIKI/wiki/pages" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

if [ "$SOURCE_PAGE_COUNT" != "$BUNDLED_PAGE_COUNT" ]; then
  printf '{"success": false, "data": {"source_pages": %s, "bundled_pages": %s}, "error": "page count mismatch after sync"}\n' \
    "$SOURCE_PAGE_COUNT" "$BUNDLED_PAGE_COUNT"
  exit 1
fi

printf '{"success": true, "data": {"mode": "sync", "source": "%s", "bundled": "%s", "page_count": %s}, "error": ""}\n' \
  "$SOURCE_WIKI" "$BUNDLED_WIKI" "$SOURCE_PAGE_COUNT"
