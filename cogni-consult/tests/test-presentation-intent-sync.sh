#!/usr/bin/env bash
# Parity guard for the presentation-intent vocabulary.
#
# The vocabulary is defined once, in cogni-workspace/libraries/presentation-intent.md,
# and mirrored into cogni-consult/references/publish-routing.md so consult-publish
# still has a complete schema when cogni-consult is installed without a
# cogni-workspace tree beside it. Both copies delimit the shared text with:
#
#     <!-- PRESENTATION-INTENT:SHARED:START -->
#     <!-- PRESENTATION-INTENT:SHARED:END -->
#
# The extraction includes the marker lines and the blank-line padding, so the two
# copies must match byte for byte including that padding.
#
# Emitters are plain on purpose: scripts/check-result-line-plainness.py forbids an
# escape literal anywhere in a discovered suite, and this file is discovered by
# scripts/run-plugin-tests.py via the */tests/*.sh glob. Do not import the coloured
# c_skip/c_info helpers from cogni-workspace/scripts/verify-theme-backcompat.sh —
# those survive only because that path matches neither discovery glob.
#
# SKIP vs FAIL: a MISSING library file is the installed-plugin layout and skips
# cleanly. A file that is PRESENT but whose block is empty or malformed FAILS — a
# vacuous scan must never read as success.

set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO_ROOT="$(cd "$PLUGIN_DIR/.." && pwd)"
NESTED=0

while [ $# -gt 0 ]; do
  case "$1" in
    --root) REPO_ROOT="$2"; NESTED=1; shift 2 ;;
    *) shift ;;
  esac
done

LIB_FILE="$REPO_ROOT/cogni-workspace/libraries/presentation-intent.md"
CONSULT_FILE="$REPO_ROOT/cogni-consult/references/publish-routing.md"

START_MARK='<!-- PRESENTATION-INTENT:SHARED:START -->'
END_MARK='<!-- PRESENTATION-INTENT:SHARED:END -->'

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s - %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

WORK_DIR="$(mktemp -d)"
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

extract_block() {
  sed -n "/^$START_MARK\$/,/^$END_MARK\$/p" "$1"
}

# The installed-plugin layout carries no cogni-workspace tree. That is a clean
# skip, not a failure -- there is nothing to compare against.
if [ ! -f "$LIB_FILE" ]; then
  printf 'SKIP  pi-sync-00 (cogni-workspace library not found at %s)\n' "$LIB_FILE"
  exit 0
fi

if [ ! -f "$CONSULT_FILE" ]; then
  fail "pi-sync-00-consult" "publish-routing.md not found at $CONSULT_FILE"
  exit 1
fi
pass "pi-sync-00-consult"

extract_block "$LIB_FILE" > "$WORK_DIR/lib.block"
extract_block "$CONSULT_FILE" > "$WORK_DIR/consult.block"

# pi-sync-01 / pi-sync-02 -- vacuity guards. An empty extraction would make the
# byte-compare below trivially pass over two broken files.
if [ -s "$WORK_DIR/lib.block" ]; then
  pass "pi-sync-01"
else
  fail "pi-sync-01" "the shared block in $LIB_FILE is empty or its markers are missing"
fi

if [ -s "$WORK_DIR/consult.block" ]; then
  pass "pi-sync-02"
else
  fail "pi-sync-02" "the shared block in $CONSULT_FILE is empty or its markers are missing"
fi

# pi-sync-03 -- the parity assertion itself.
if cmp -s "$WORK_DIR/lib.block" "$WORK_DIR/consult.block"; then
  pass "pi-sync-03"
else
  fail "pi-sync-03" "the shared blocks differ; run: diff <(sed -n '/START/,/END/p' $LIB_FILE) <(sed -n '/START/,/END/p' $CONSULT_FILE)"
fi

# pi-sync-04-* -- exactly one marker of each kind per file. Two of either makes
# the sed range ambiguous.
check_marker_count() {
  case_id="$1"; target="$2"
  starts=$(grep -c "^$START_MARK\$" "$target")
  ends=$(grep -c "^$END_MARK\$" "$target")
  if [ "$starts" -eq 1 ] && [ "$ends" -eq 1 ]; then
    pass "$case_id"
  else
    fail "$case_id" "expected exactly one START and one END in $target, found start=$starts end=$ends"
  fi
}
check_marker_count "pi-sync-04-library" "$LIB_FILE"
check_marker_count "pi-sync-04-consult" "$CONSULT_FILE"

# pi-sync-05-* -- marker ORDER. With END before START the sed range runs from
# START to end of file, and two identically-inverted files still compare equal,
# so the count check and the byte-compare together still read green.
check_marker_order() {
  case_id="$1"; target="$2"
  start_line=$(grep -n "^$START_MARK\$" "$target" | head -1 | cut -d: -f1)
  end_line=$(grep -n "^$END_MARK\$" "$target" | head -1 | cut -d: -f1)
  if [ -n "$start_line" ] && [ -n "$end_line" ] && [ "$start_line" -lt "$end_line" ]; then
    pass "$case_id"
  else
    fail "$case_id" "START must precede END in $target (start=${start_line:-none} end=${end_line:-none})"
  fi
}
check_marker_order "pi-sync-05-library" "$LIB_FILE"
check_marker_order "pi-sync-05-consult" "$CONSULT_FILE"

# pi-sync-06 -- self-sufficiency. consult-publish defers to this subsection as the
# canonical schema and is forbidden from restating the field shape, so a reduction
# to a pointer-plus-blurb would silently remove the schema it builds from.
missing=""
for token in 'register' 'dark_slides' 'speaker_notes' 'imagery' 'variations' \
             'slide_points' 'talk_track' 'key_figures' 'climax:' 'tbd:' 'note:' \
             'cover' 'bluf' 'two-column' 'table' 'timeline' 'quote' 'metric' 'roles' \
             'design is frozen'; do
  if ! grep -q -- "$token" "$WORK_DIR/consult.block"; then
    missing="$missing $token"
  fi
done
if [ -z "$missing" ]; then
  pass "pi-sync-06"
else
  fail "pi-sync-06" "the consult block is no longer self-sufficient; missing:$missing"
fi

# pi-sync-07 -- goes-red proof. Build a fixture tree whose library block is
# mutated and assert this suite fails against it. Skipped when already nested so
# the fixture run cannot recurse.
if [ "$NESTED" -eq 1 ]; then
  printf 'SKIP  pi-sync-07 (nested fixture run)\n'
else
  FIX="$WORK_DIR/fixture"
  mkdir -p "$FIX/cogni-workspace/libraries" "$FIX/cogni-consult/references" "$FIX/cogni-consult/tests"
  cp "$CONSULT_FILE" "$FIX/cogni-consult/references/publish-routing.md"
  sed 's/speaker_notes/speaker_note/' "$LIB_FILE" > "$FIX/cogni-workspace/libraries/presentation-intent.md"
  SELF="$FIX/cogni-consult/tests/$(basename "$0")"
  cp "$0" "$SELF"
  if bash "$SELF" --root "$FIX" >/dev/null 2>&1; then
    fail "pi-sync-07" "a mutated library block did not make this suite fail"
  else
    pass "pi-sync-07"
  fi
fi

if [ "$failures" -gt 0 ]; then
  printf '%s\n' "$failures failure(s)" >&2
  exit 1
fi
exit 0
