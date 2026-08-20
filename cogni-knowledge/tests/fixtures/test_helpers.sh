# test_helpers.sh — shared bash helpers sourced by cogni-knowledge/tests/*.
#
# Before this file landed at v0.0.17, every test file inlined `red()` /
# `green()` (byte-identical) and re-implemented `assert_grep` with two
# divergent signatures across plugins. The cogni-wiki form took (pattern,
# description) with a $SKILL global; the cogni-knowledge form added the
# file as an explicit first argument. The 3-arg form is the more general
# of the two and is the convention adopted here.
#
# Source via:
#   . "$(dirname "$0")/fixtures/test_helpers.sh"
#
# Bash 3.2 compatible.

red()   { printf '%s\n' "$1"; }
green() { printf '%s\n' "$1"; }

# assert_grep PATTERN FILE DESCRIPTION
#   Increments the caller's `errors` variable on failure.
assert_grep() {
  local pattern="$1" file="$2" description="$3"
  if grep -q -- "$pattern" "$file" 2>/dev/null; then
    green "PASS: $description"
  else
    red "FAIL: $description"
    red "  pattern: $pattern"
    red "  file:    $file"
    errors=$((errors + 1))
  fi
}

# assert_not_grep PATTERN FILE DESCRIPTION
#   Symmetric counterpart — fails if PATTERN is present.
assert_not_grep() {
  local pattern="$1" file="$2" description="$3"
  if grep -q -- "$pattern" "$file" 2>/dev/null; then
    red "FAIL: $description"
    red "  pattern (should NOT appear): $pattern"
    red "  file: $file"
    errors=$((errors + 1))
  else
    green "PASS: $description"
  fi
}

# The fixed-string counterparts of the pair above.
#
# Reach for these whenever the pattern is a literal that carries regex
# metacharacters — a wikilink, a glob, a file path, a JSON key, anything
# containing [ ] . * ^ $ or a backslash. The BRE pair reads such a pattern as a
# regex: `[[alpha-synthesis]]` parses as a bracket expression plus a trailing
# literal ], so it matches any <one-of-those-chars>] sequence and the assertion
# passes green against a file that does not contain the string at all.
#
# These match the pattern verbatim instead, so metacharacters carry no meaning.
# Keep using the BRE pair when you actually want a regex — an anchored
# '^# Concepts$', or an alternation written with \| .

# assert_grep_f PATTERN FILE DESCRIPTION
#   Fixed-string counterpart of assert_grep. Increments the caller's `errors`
#   variable on failure.
assert_grep_f() {
  local pattern="$1" file="$2" description="$3"
  if grep -qF -- "$pattern" "$file" 2>/dev/null; then
    green "PASS: $description"
  else
    red "FAIL: $description"
    red "  pattern (fixed): $pattern"
    red "  file:            $file"
    errors=$((errors + 1))
  fi
}

# assert_not_grep_f PATTERN FILE DESCRIPTION
#   Symmetric counterpart — fails if PATTERN is present as a literal.
assert_not_grep_f() {
  local pattern="$1" file="$2" description="$3"
  if grep -qF -- "$pattern" "$file" 2>/dev/null; then
    red "FAIL: $description"
    red "  pattern (fixed, should NOT appear): $pattern"
    red "  file: $file"
    errors=$((errors + 1))
  else
    green "PASS: $description"
  fi
}
