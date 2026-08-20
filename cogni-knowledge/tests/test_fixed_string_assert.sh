#!/usr/bin/env bash
# test_fixed_string_assert.sh — the fixed-string assert pair discriminates.
#
# `assert_grep` matches under BRE, so a pattern that is meant as a literal but
# carries regex metacharacters can match a file that does not contain it. The
# canonical case is a wikilink: `[[alpha-synthesis]]` parses as a bracket
# expression plus a trailing literal `]`, and the `a-s` range covers the `s` in
# `[[omega-synthesis]]` — so the assertion reports green against a decoy. That
# is a vacuous guard: a test asserting nothing while looking like it passed.
#
# `assert_grep_f` / `assert_not_grep_f` match the pattern verbatim and close it.
#
# Both arms of every case below are fed by ONE label argument, so a case's pass
# and fail ids can never drift apart. Cases that expect the helper to FAIL run it
# inside a command substitution and decide from the CAPTURED text — never from
# the helper's `errors` side effect, which happens in the subshell and is
# invisible here, and never as a live line, which would look like a red case.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
HELPER="$TESTS_DIR/fixtures/test_helpers.sh"

. "$TESTS_DIR/fixtures/test_helpers.sh"

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

# The decoy carries omega but never alpha, and one ordinary heading line.
DECOY="$WORKDIR/decoy.md"
{
  printf '%s\n' '# Concepts'
  printf '%s\n' '- [[omega-synthesis]] — only this one'
} > "$DECOY"

errors=0

# One label argument reaches both arms, so the ids cannot diverge.
fail()  { red "FAIL: $1"; errors=$((errors + 1)); }
check() { if [ "$1" = "yes" ]; then green "PASS: $2"; else fail "$2"; fi; }

# Did a captured helper run report failure?
reported_fail() {
  case "$1" in
    "FAIL:"*) printf '%s' 'yes' ;;
    *)        printf '%s' 'no' ;;
  esac
}

# --- Direct calls: the helper's own pass arm is the result line ---------------

assert_grep_f '[[omega-synthesis]]' "$DECOY" \
  'fixed-assert-01 assert_grep_f matches a bracketed literal that is present'

assert_grep '[[alpha-synthesis]]' "$DECOY" \
  'fixed-assert-03 assert_grep still matches the absent literal under BRE (the false pass being closed)'

assert_grep '^# Concepts$' "$DECOY" \
  'fixed-assert-04 assert_grep still honours an anchored regex, so BRE behaviour is unchanged'

assert_not_grep_f '[[alpha-synthesis]]' "$DECOY" \
  'fixed-assert-06 assert_not_grep_f passes when the literal is genuinely absent'

# --- Captured probes: the helper is expected to FAIL --------------------------

OUT_02="$(assert_grep_f '[[alpha-synthesis]]' "$DECOY" 'probe')"
check "$(reported_fail "$OUT_02")" \
  'fixed-assert-02 assert_grep_f reports failure on the absent bracketed literal'

OUT_05="$(assert_grep_f '^# Concepts$' "$DECOY" 'probe')"
check "$(reported_fail "$OUT_05")" \
  'fixed-assert-05 assert_grep_f treats an anchored pattern as a literal, so it does not match'

OUT_07="$(assert_not_grep_f '[[omega-synthesis]]' "$DECOY" 'probe')"
check "$(reported_fail "$OUT_07")" \
  'fixed-assert-07 assert_not_grep_f reports failure when the literal is present'

# --- Both-arms rule: one label argument, verbatim, on each arm ----------------

LABEL='both-arms probe label'
ARM_PASS="$(assert_grep_f '[[omega-synthesis]]' "$DECOY" "$LABEL")"
ARM_FAIL="$(assert_grep_f '[[alpha-synthesis]]' "$DECOY" "$LABEL" | head -1)"
if [ "$ARM_PASS" = "PASS: $LABEL" ] && [ "$ARM_FAIL" = "FAIL: $LABEL" ]; then
  BOTH_ARMS=yes
else
  BOTH_ARMS=no
fi
check "$BOTH_ARMS" \
  'fixed-assert-08 one label argument reaches both arms verbatim'

# --- Caller errors accounting: exactly one increment per failure --------------
# Run in a child shell that owns its own counter, because the increment made by
# a captured call above happens in a subshell and never reaches this one.

COUNT_09="$(bash -c '. "$1"; errors=0; assert_grep_f "[[alpha-synthesis]]" "$2" probe >/dev/null 2>&1; printf "%s" "$errors"' _ "$HELPER" "$DECOY")"
check "$([ "$COUNT_09" = "1" ] && printf '%s' yes || printf '%s' no)" \
  'fixed-assert-09 a failing assert_grep_f increments the caller errors count by exactly one'

COUNT_10="$(bash -c '. "$1"; errors=0; assert_not_grep_f "[[omega-synthesis]]" "$2" probe >/dev/null 2>&1; printf "%s" "$errors"' _ "$HELPER" "$DECOY")"
check "$([ "$COUNT_10" = "1" ] && printf '%s' yes || printf '%s' no)" \
  'fixed-assert-10 a failing assert_not_grep_f increments the caller errors count by exactly one'

if [ "$errors" -gt 0 ]; then
  exit 1
fi
exit 0
