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
#   scripts/release-bundle-wiki.sh --force            # sync even when it would destroy content
#
# A bare sync REFUSES, exits 1 and writes nothing when the bundled tree holds
# content the source does not: a file absent from source, or a shared file whose
# bundled copy carries non-blank lines the source copy lacks. The refusal names
# every such path in its JSON payload. Pass --force to sync anyway.
#
# Output: JSON to stdout per insight-wave script convention.
#   {"success": true, "data": {...}, "error": ""}

set -eu

SOURCE_WIKI="$(cd "$(dirname "$0")/.." && pwd)/wiki"
BUNDLED_WIKI="$(cd "$(dirname "$0")/.." && pwd)/cogni-workspace/wiki"
MODE="sync"
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE="check"; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help)
      # The upper bound must equal the last line of the header comment block.
      # tests/test_release_bundle_wiki.sh case RBW7 pins both directions: it
      # fails if the range truncates the usage text, and it fails if the range
      # runs past the header into the code below.
      sed -n '2,24p' "$0"
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

# Pre-sync destruction gate.
#
# rsync --delete treats the bundled tree as a pure mirror, so anything the bundle
# holds and the source does not is destroyed without trace. The post-sync page
# count check below cannot defend against this: by the time it runs, rsync has
# already made both trees identical, so it compares a number to itself. It also
# cannot see an overwrite at all, since replacing a file's contents leaves the
# file count unchanged.
#
# So classify BEFORE writing. This block sits ahead of `mkdir -p`, the first
# write-capable call in this script, which is what makes the refusal a true
# no-op on disk rather than merely an early exit.
#
# Two destructive classes, both reported:
#   would_delete    — a path in the bundle with no counterpart in the source.
#   would_overwrite — a path on both sides whose bundled copy carries non-blank
#                     lines the source copy lacks, i.e. content that is not
#                     derivable from the source and would be lost.
#
# A bundled file that is merely a subset of its source counterpart is NOT
# destructive: the source is enriching it, nothing is lost. That asymmetry is
# deliberate. A gate that fired on any difference would refuse every ordinary
# sync, and an override the operator must pass every time is an override they
# stop reading — which would reinstate exactly the data loss this gate prevents.
if [ "$FORCE" -eq 0 ] && [ -d "$BUNDLED_WIKI" ]; then
  # No pipe here, so rsync's own exit status would trip `set -e`; exit 24
  # (files vanished mid-scan) is benign on a live tree.
  ITEMS=$(rsync -anci --delete "$SOURCE_WIKI/" "$BUNDLED_WIKI/" 2>/dev/null || true)

  # Itemise lines are `*deleting <path>` and `>fcst.... <path>`. The flag field
  # is not fixed-width across rsync builds, so take everything from the start of
  # field 2 rather than a hardcoded column; that also keeps a path containing a
  # space intact.
  WOULD_DELETE=$(printf '%s\n' "$ITEMS" | awk '$1 == "*deleting" { print substr($0, index($0, $2)) }' | LC_ALL=C sort)
  CANDIDATES=$(printf '%s\n' "$ITEMS" | awk '$1 ~ /^>f/ { print substr($0, index($0, $2)) }')

  WOULD_OVERWRITE=""
  while IFS= read -r REL; do
    [ -n "$REL" ] || continue
    SRC_FILE="$SOURCE_WIKI/$REL"
    BUN_FILE="$BUNDLED_WIKI/$REL"
    # A `>f+++++++` addition has no bundled counterpart, so nothing to lose.
    { [ -f "$SRC_FILE" ] && [ -f "$BUN_FILE" ]; } || continue
    # Lines present in the bundle but in no line of the source. grep -c exits 1
    # at a count of zero, hence `|| true`.
    EXTRA=$(grep -Fxv -f "$SRC_FILE" "$BUN_FILE" 2>/dev/null | grep -cv '^[[:space:]]*$' || true)
    [ "${EXTRA:-0}" -gt 0 ] || continue
    WOULD_OVERWRITE="${WOULD_OVERWRITE}${REL}
"
  done <<EOF
$CANDIDATES
EOF

  # `grep -c .` and not `wc -l`: printf appends a newline, so `wc -l` reports 1
  # for an empty value and the gate would refuse every clean sync.
  DELETE_COUNT=$(printf '%s' "$WOULD_DELETE" | grep -c . || true)
  OVERWRITE_COUNT=$(printf '%s' "$WOULD_OVERWRITE" | grep -c . || true)
  DESTRUCTIVE_COUNT=$(( DELETE_COUNT + OVERWRITE_COUNT ))

  if [ "$DESTRUCTIVE_COUNT" -gt 0 ]; then
    # json.dumps the whole envelope. Every other printf in this file
    # interpolates %s raw into a JSON format string, which is safe only for the
    # integers and self-derived absolute paths those call sites emit; a list of
    # arbitrary repository paths is not in that category.
    SRC="$SOURCE_WIKI" BUN="$BUNDLED_WIKI" DEL="$WOULD_DELETE" OVR="$WOULD_OVERWRITE" \
      COUNT="$DESTRUCTIVE_COUNT" python3 - <<'PY'
import json
import os


def paths(raw):
    return sorted(line for line in raw.splitlines() if line.strip())


would_delete = paths(os.environ["DEL"])
would_overwrite = paths(os.environ["OVR"])
count = int(os.environ["COUNT"])

print(json.dumps({
    "success": False,
    "data": {
        "mode": "sync",
        "source": os.environ["SRC"],
        "bundled": os.environ["BUN"],
        "would_delete": would_delete,
        "would_overwrite": would_overwrite,
        "destructive_path_count": count,
        "override": "re-run with --force to sync anyway",
    },
    "error": (
        "refusing to sync: %d bundled path(s) would be destroyed; "
        "re-run with --force to sync anyway" % count
    ),
}))
PY
    exit 1
  fi
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
