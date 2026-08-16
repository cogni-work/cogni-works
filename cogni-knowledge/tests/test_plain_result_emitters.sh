#!/usr/bin/env bash
# test_plain_result_emitters.sh — the result-line shape every suite here relies on.
#
# The `red`/`green` emitters must write their argument verbatim, with no escape
# sequence wrapping it. A mutation harness matches result lines by their
# `PASS: <case>` / `FAIL: <case>` label; an escape sequence sitting in front of
# the label makes that match miss and the harness reports `case_not_found`
# instead of a real verdict — a red case reads as a missing one.
#
# Contract under test:
#   1. The shared helper emits exactly the text it was handed, one line per
#      call, on stdout.
#   2. No file under the scanned tree carries an escape literal at all.
#   3. Any file defining an emitter defines BOTH, and both bodies are the plain
#      form — catching a half-conversion, and a definition deleted while its
#      call sites live on.
#
# Two properties this suite deliberately does NOT assert, because asserting
# them would work against the conventions it exists to protect:
#
#   - It never requires a file to define the emitters INLINE. The liveness
#     floor counts files that *exercise* the contract — defining the emitters
#     or sourcing the shared helper — so consolidating a suite onto
#     fixtures/test_helpers.sh keeps this suite green. A floor keyed on inline
#     definitions would turn the shared helper's own purpose into a failure.
#   - It never spells the escape literal itself: case 2 assembles the pattern
#     at run time, so the file cannot trip its own sweep and needs no exclusion
#     marker to pass.
#
# The scan root defaults to this file's directory and can be overridden by the
# first argument, so a wider guard can reuse this file rather than fork it.
# A wider guard must re-home the liveness floor below — that count is scoped to
# this plugin.
#
# bash 3.2 + python3 stdlib only (no pytest, no pip). Matches tests/README.md.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
HELPER="$TESTS_DIR/fixtures/test_helpers.sh"
SCAN_ROOT="${1:-$TESTS_DIR}"

. "$HELPER"

errors=0

# --- Case 1: the helper emits its argument verbatim -------------------------
# `cat -v` renders an escape byte as `^[`, so an exact string comparison proves
# plain-ness, one line per call, and stdout delivery in a single assertion —
# without this file needing to contain an escape byte to compare against.
# Whole-string equality is the point: a substring match would still succeed
# against a colour-wrapped label, so it could not falsify what is under test.

CAPTURED="$(bash -c '. "$1"; green "PASS: probe-green"; red "FAIL: probe-red"' _ "$HELPER" | cat -v)"
EXPECTED='PASS: probe-green
FAIL: probe-red'

if [ "$CAPTURED" = "$EXPECTED" ]; then
  green "PASS: helper emits plain result lines on stdout"
else
  red "FAIL: helper did not emit the expected plain result lines"
  red "  expected: $EXPECTED"
  red "  actual:   $CAPTURED"
  errors=$((errors + 1))
fi

# --- Case 2: no escape literal anywhere under the scanned tree --------------
# Assembled at run time from a lone backslash so the 4-character literal never
# appears contiguously in this file's own source.

BSL='\'
ESC_PAT="${BSL}033"

CARRIERS="$(grep -rlF -- "$ESC_PAT" "$SCAN_ROOT" || true)"

if [ -z "$CARRIERS" ]; then
  green "PASS: no file under the scanned tree carries an escape literal"
else
  red "FAIL: escape literal still present under the scanned tree"
  echo "$CARRIERS" | sed 's/^/  /'
  errors=$((errors + 1))
fi

# --- Case 3: emitter definitions are paired and plain -----------------------
# Keyed on definition lines only. Call-site labels are deliberately not
# inspected: some suites emit bare labels with no PASS:/FAIL: prefix, and a
# fixture that defines neither emitter must pass rather than fail.
#
# One grep per file: the emitters are one-liners, so the definition line
# carries its own body and feeds every check below from a single read.

definers=0
exercisers=0
shape_errors=0

for f in "$SCAN_ROOT"/*.sh "$SCAN_ROOT"/fixtures/*.sh; do
  [ -f "$f" ] || continue

  defs="$(grep -E '^(red|green)\(\)' "$f" || true)"

  if [ -z "$defs" ]; then
    # Sourcing the shared helper exercises the same contract without defining
    # anything — that is the preferred shape, so it must count toward liveness.
    if grep -qF 'test_helpers.sh' "$f"; then
      exercisers=$((exercisers + 1))
    fi
    continue
  fi

  definers=$((definers + 1))
  exercisers=$((exercisers + 1))

  n_red=0
  n_green=0
  n_plain=0
  while IFS= read -r line; do
    case "$line" in
      red\(\)*) n_red=$((n_red + 1)) ;;
      green\(\)*) n_green=$((n_green + 1)) ;;
    esac
    case "$line" in
      *"printf '%s"*) n_plain=$((n_plain + 1)) ;;
    esac
  done <<<"$defs"

  if [ "$n_red" -ne 1 ] || [ "$n_green" -ne 1 ]; then
    red "FAIL: $(basename "$f") defines red=$n_red green=$n_green (expected 1 each)"
    shape_errors=$((shape_errors + 1))
  elif [ "$n_plain" -ne 2 ]; then
    red "FAIL: $(basename "$f") emitter bodies are not both the plain printf form"
    printf '%s\n' "$defs" | sed 's/^/  /'
    shape_errors=$((shape_errors + 1))
  fi
done

errors=$((errors + shape_errors))

# Liveness floor — a broken glob must fail loudly rather than pass vacuously.
# 78 files exercise the contract today (1 defines the emitters — the shared
# helper — and 77 source it). The floor sits at 50 so either direction of drift
# has room, and consolidating definers onto the helper cannot trip it.
if [ "$exercisers" -lt 50 ]; then
  red "FAIL: only $exercisers file(s) exercising the emitter contract were found (expected at least 50) — the scan is not reaching them"
  errors=$((errors + 1))
elif [ "$shape_errors" -eq 0 ]; then
  green "PASS: $definers emitter-defining file(s) are paired and plain, of $exercisers exercising the contract"
fi

echo
if [ "$errors" -eq 0 ]; then
  green "plain result-emitter contract all pass."
else
  red "plain result-emitter contract: $errors failure(s)."
  exit 1
fi
