#!/usr/bin/env bash
# Structural guard for the Step 0 register block duplicated across every
# consult-* skill.
#
# The block is mandated in all nine SKILL.md files, so it cannot be deduplicated
# away — but nothing else asserts the copies still match. Byte-identity is the
# only property that makes a mandated duplicate safe: it turns a silent nine-way
# drift into a failing test. The specifics the block used to restate now live in
# references/user-facing-output.md (f), so this also asserts no skill has
# re-inlined one.
#
# Reads the shipped files directly — no fixtures, no temp dir, no generator.
#
# Coverage:
#   1  glob-count     skills/consult-*/SKILL.md resolves to exactly 9 files
#   2  anchor-once    each carries exactly one register-paragraph anchor line
#   3  register-same  the 4-line register paragraph is byte-identical in all 9
#   4  ladder-same    the 7-line ladder paragraph is byte-identical in all 9
#   5  no-re-inline   no SKILL.md restates a specific owned by (f)
#   6  owner-present  user-facing-output.md carries (f), the 6-word cap and the
#                     worked pair
#
# Usage: bash cogni-consult/tests/test_step0_register_block.sh
# Exits non-zero on any assertion failure.

# `set -u` only — `set -e` would abort on the first failing assertion.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
OWNER="$PLUGIN_DIR/references/user-facing-output.md"

REGISTER_ANCHOR='^The register that output follows'
LADDER_ANCHOR='^Before any user-facing output, resolve the'

failures=0
pass() { printf 'OK   %s\n' "$1"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

# Extract the paragraph starting at the line matching $2, from file $1.
# A paragraph ends at the first blank line, which is what makes the comparison
# whitespace-exact rather than a fuzzy grep.
paragraph() {
  awk -v pat="$2" '$0 ~ pat {f = 1} f {if ($0 == "") exit; print}' "$1"
}

# --- 1  glob-count ---------------------------------------------------------

skills=()
for f in "$PLUGIN_DIR"/skills/consult-*/SKILL.md; do
  [ -f "$f" ] && skills+=("$f")
done

if [ "${#skills[@]}" -eq 9 ]; then
  pass "glob-count: 9 consult-* SKILL.md found"
else
  fail "glob-count" "expected 9 consult-*/SKILL.md, found ${#skills[@]}"
fi

if [ "${#skills[@]}" -eq 0 ]; then
  echo "$failures assertion(s) failed" >&2
  exit 1
fi

# --- 2  anchor-once --------------------------------------------------------

for f in "${skills[@]}"; do
  name="$(basename "$(dirname "$f")")"
  n="$(grep -c "$REGISTER_ANCHOR" "$f")"
  if [ "$n" -eq 1 ]; then
    pass "anchor-once: $name"
  else
    fail "anchor-once" "$name has $n register-paragraph anchors, expected 1"
  fi
done

# --- 3  register-same / 4  ladder-same -------------------------------------

check_identical() {
  label="$1"
  anchor="$2"
  reference=""
  reference_name=""
  for f in "${skills[@]}"; do
    name="$(basename "$(dirname "$f")")"
    block="$(paragraph "$f" "$anchor")"
    if [ -z "$block" ]; then
      fail "$label" "$name has no paragraph matching $anchor"
      continue
    fi
    if [ -z "$reference" ]; then
      reference="$block"
      reference_name="$name"
      continue
    fi
    if [ "$block" = "$reference" ]; then
      pass "$label: $name matches $reference_name"
    else
      fail "$label" "$name diverges from $reference_name"
    fi
  done
}

check_identical "register-same" "$REGISTER_ANCHOR"
check_identical "ladder-same" "$LADDER_ANCHOR"

# --- 5  no-re-inline -------------------------------------------------------

# Each string is a specific (f) owns. Any hit under skills/ means a copy grew
# back. `at most 6` rather than `6 words` on purpose: the prose these replaced
# wrapped as "at most 6\nwords", so a `6 words` search would pass vacuously and
# guard nothing.
for needle in 'at most 6' 'outcome-shaped' 'header comment'; do
  hits="$(grep -l "$needle" "${skills[@]}" 2>/dev/null || true)"
  if [ -z "$hits" ]; then
    pass "no-re-inline: '$needle' absent from every SKILL.md"
  else
    named="$(for h in $hits; do basename "$(dirname "$h")"; done | tr '\n' ' ')"
    fail "no-re-inline" "'$needle' re-inlined in: $named"
  fi
done

# --- 6  owner-present ------------------------------------------------------

if [ ! -f "$OWNER" ]; then
  fail "owner-present" "user-facing-output.md not found at $OWNER"
else
  for needle in '## (f) Tool-call descriptions' '6 words' 'Discover cogni-consult engagements'; do
    if grep -qF "$needle" "$OWNER"; then
      pass "owner-present: '$needle'"
    else
      fail "owner-present" "'$needle' missing from user-facing-output.md"
    fi
  done
fi

if [ "$failures" -gt 0 ]; then
  echo "$failures assertion(s) failed" >&2
  exit 1
fi
echo "All step0-register-block assertions passed"
