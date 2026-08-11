#!/usr/bin/env bash
# Guard: every absolute reference pointer in cogni-consult resolves, the extracted
# rendering contracts stay extracted, and neither can be silently re-inlined.
#
# Label vocabulary is deliberately NOT the sibling suites' `OK   ` shape. The
# shared mutation harness classifies a case by matching `FAIL: <case>` (red) and
# `ok: <case>` / `PASS: <case>` (green), each requiring whitespace or end-of-line
# immediately after the case token. So a case id is a single whitespace-free
# token and any detail is separated with " - ", never a glued colon: `PASS:
# goes-red: ...` would match neither pattern, and a recipe recorded against this
# suite would return case_not_found instead of a verdict.
#
# Scope note: the pointer scan keys ONLY on the absolute
# `$CLAUDE_PLUGIN_ROOT/references/...` form. A bare-relative `references/...`
# mention predates this guard elsewhere in the plugin; keying on those would make
# this suite red for reasons unrelated to whether a pointer resolves.

set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
NESTED=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) PLUGIN_DIR="$2"; NESTED=1; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s - %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

LIST_REF="references/engagement-list-rendering.md"
DASH_REF="references/engagement-dashboard-rendering.md"
RESUME_SKILL="skills/consult-resume/SKILL.md"

# --- case 1: pointers-resolve ------------------------------------------------
# Every absolute pointer resolves. A token ending in "/" is a directory target.
pointer_tokens() {
  grep -rho --include='*.md' --include='*.sh' --include='*.json' \
    '\$CLAUDE_PLUGIN_ROOT/references/[A-Za-z0-9._/-]*' \
    "$PLUGIN_DIR/skills" "$PLUGIN_DIR/agents" "$PLUGIN_DIR/references" \
    "$PLUGIN_DIR/hooks" "$PLUGIN_DIR/output-styles" 2>/dev/null \
    | sed 's/[.,;:)]*$//' | sort -u
}

tokens="$(pointer_tokens)"
if [ -z "$tokens" ]; then
  # A vacuous scan must never read as success — it would make this case pass by
  # finding nothing to check.
  fail "pointers-resolve" "no absolute reference pointers found under $PLUGIN_DIR (vacuous scan)"
else
  dangling=""
  while IFS= read -r tok; do
    rest="${tok#\$CLAUDE_PLUGIN_ROOT/}"
    [ -e "$PLUGIN_DIR/$rest" ] || dangling="$dangling $rest"
  done <<< "$tokens"
  if [ -n "$dangling" ]; then
    fail "pointers-resolve" "dangling:$dangling"
  else
    pass "pointers-resolve"
  fi
fi

# --- case 2: pointers-absolute ----------------------------------------------
# In the extracted contracts and in the skill body they were extracted from,
# every references/ mention uses the absolute form — so the relocation cannot
# erode back toward relative paths in the files it actually touched.
before=$failures
for rel in "$LIST_REF" "$DASH_REF" "$RESUME_SKILL"; do
  f="$PLUGIN_DIR/$rel"
  if [ ! -f "$f" ]; then
    fail "pointers-absolute" "missing $rel"
    continue
  fi
  all="$(grep -o 'references/' "$f" 2>/dev/null | wc -l)"
  abs="$(grep -o 'CLAUDE_PLUGIN_ROOT/references/' "$f" 2>/dev/null | wc -l)"
  [ "$all" -ne "$abs" ] &&
    fail "pointers-absolute" "$rel has $all references/ mentions but only $abs absolute"
done
[ "$failures" -eq "$before" ] && pass "pointers-absolute"

# --- case 3: reference-anchored ---------------------------------------------
# An extracted contract nobody points at is orphaned prose. Scoped to skill
# bodies on purpose: a reference cited only by another reference is still orphaned
# from the default path.
before=$failures
for rel in "$LIST_REF" "$DASH_REF"; do
  grep -rq "\$CLAUDE_PLUGIN_ROOT/$rel" "$PLUGIN_DIR/skills" 2>/dev/null ||
    fail "reference-anchored" "$rel is not pointed at by any skill body"
done
[ "$failures" -eq "$before" ] && pass "reference-anchored"

# --- case 4: contract-relocated ---------------------------------------------
# The rendering contracts must live in the references, not back in the skill
# body. The subject is derived, not sampled: every non-empty line of every fenced
# example in the two references must be absent from the skill body, so
# re-inlining any part of either rendered table fails CI.
fenced_lines() { awk '/^```/ { inf = !inf; next } inf && NF' "$1"; }

before=$failures
for rel in "$LIST_REF" "$DASH_REF"; do
  [ -f "$PLUGIN_DIR/$rel" ] || continue
  while IFS= read -r line; do
    grep -qF -- "$line" "$PLUGIN_DIR/$RESUME_SKILL" 2>/dev/null &&
      fail "contract-relocated" "rendered example line re-inlined into $RESUME_SKILL: $line"
  done <<< "$(fenced_lines "$PLUGIN_DIR/$rel")"
done
# Explicit presence half, which the derived check above cannot make: grep -F pins
# the umlauts, so an ASCII-folded copy of a relocated rule fails to match.
for tok in 'Weitere' 'TT.MM.JJJJ' 'Nächstes Deliverable' 'Schlüsselfrage:' 'Fortschritt'; do
  grep -qF -- "$tok" "$PLUGIN_DIR/$LIST_REF" "$PLUGIN_DIR/$DASH_REF" 2>/dev/null ||
    fail "contract-relocated" "token absent from both reference files: $tok"
done
[ "$failures" -eq "$before" ] && pass "contract-relocated"

# --- case 5: goes-red -------------------------------------------------------
# Skipped under --root so the nested fixture runs cannot recurse.
if [ "$NESTED" -eq 0 ]; then
  TMPROOT="$(mktemp -d)"
  trap 'rm -rf "$TMPROOT"' EXIT

  build_fixture() {
    mkdir -p "$1"
    for d in skills agents references hooks output-styles; do
      [ -d "$PLUGIN_DIR/$d" ] && cp -R "$PLUGIN_DIR/$d" "$1/"
    done
  }

  # Each fixture gets its own tree named for the case it proves, so a botched
  # mutation cannot leak into the next case and turn it red for the wrong reason.
  expect_red() {
    case_id="$1"; shift
    fixture="$TMPROOT/$case_id"
    build_fixture "$fixture"
    "$@" "$fixture"
    if bash "$0" --root "$fixture" >/dev/null 2>&1; then
      fail "$case_id" "the mutated fixture did not fail the guard"
    else
      pass "$case_id"
    fi
  }

  mutate_dangle() {
    f="$1/$RESUME_SKILL"
    sed 's|references/engagement-list-rendering\.md|references/no-such-reference.md|g' \
      "$f" > "$f.new" && mv "$f.new" "$f"
  }

  mutate_reinline() {
    printf '\nWeitere 6 — sag „alle“ für die vollständige Liste.\n' >> "$1/$RESUME_SKILL"
  }

  expect_red goes-red mutate_dangle
  expect_red goes-red-reinline mutate_reinline
fi

if [ "$failures" -gt 0 ]; then
  echo "$failures assertion(s) failed" >&2
  exit 1
fi
echo "All reference-pointer assertions passed"
