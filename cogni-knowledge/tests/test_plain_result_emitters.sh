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
# A wider guard must re-home the floors below — the liveness count and the
# fixtures-arm coverage floor are both scoped to this plugin's tree.
#
# This suite owns the deeper fixtures segment, and that ownership is settled
# rather than incidental. The repo-root result-line plainness guard discovers
# suites through two non-recursive globs mirroring run-plugin-tests.py, so a
# shared emitter helper parked one path segment below a tests/ directory is
# structurally out of its reach. A third, deeper glob was considered and
# rejected: that two-glob boundary is exactly what keeps the parked _archive/
# carrier out of the population, and the guard ships no exclusion list,
# allowlist or baseline to compensate — widening it would have forced the very
# exemption machinery the guard exists to avoid, to close a gap nothing is
# failing on today. The accepted cost is that this coverage stays plugin-local
# and is not discoverable from the repo root. The plain-emit-07 floor below is what stops
# it from being dropped silently: break the deeper arm of the discovery loop
# and the only definer leaves the scanned population, while every sourcing file
# still counts toward the liveness floor above.
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
  green "PASS: plain-emit-01 helper emits plain result lines on stdout"
else
  red "FAIL: plain-emit-01 helper did not emit the expected plain result lines"
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
  green "PASS: plain-emit-02 no file under the scanned tree carries an escape literal"
else
  red "FAIL: plain-emit-02 escape literal still present under the scanned tree"
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
fixtures_definers=0
exercisers=0
shape_errors=0

# Offender text for plain-emit-03 / plain-emit-04. The loop accumulates; both
# cases are emitted once, after it closes, under a fixed id. Initialized here
# because `set -u` is on and the post-loop arms read these whether or not the
# loop ever appended to them.
pair_offenders=""
plain_offenders=""

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

  # Tally definers found under the deeper segment separately — the plain-emit-07 floor
  # below keys on this, not on the whole-population count.
  case "$f" in
    */fixtures/*) fixtures_definers=$((fixtures_definers + 1)) ;;
  esac

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

  # Accumulate only — the emission for both cases happens after the loop. The
  # predicates and both shape_errors bumps are unchanged, so the fold below
  # stays arithmetically identical. The file name moves into the message text,
  # since the id no longer carries it. `${f##*/}` rather than $(basename "$f")
  # because the name is now interpolated into an ASSIGNMENT: an assignment
  # takes its exit status from the substitution, so under `set -e` a failing
  # one would abort the run, where the `red "…"` argument it replaced would
  # not have. Parameter expansion also forks nothing.
  if [ "$n_red" -ne 1 ] || [ "$n_green" -ne 1 ]; then
    pair_offenders="$pair_offenders${f##*/} defines red=$n_red green=$n_green (expected 1 each)
"
    shape_errors=$((shape_errors + 1))
  elif [ "$n_plain" -ne 2 ]; then
    plain_offenders="$plain_offenders${f##*/}
$defs
"
    shape_errors=$((shape_errors + 1))
  fi
done

errors=$((errors + shape_errors))

# plain-emit-03 / plain-emit-04 are emitted here, once, rather than per file
# inside the loop. In the loop each id had to carry a per-file discriminator to
# stay unique per emitted line, and the if/elif had no else — so neither id
# could ever print a green line, and a harness aimed at either read a clean run
# as case_not_found instead of a verdict. A fixed id only becomes safe once the
# emission leaves the loop, which is why this is a relocation and not a suffix
# strip. The id stays the second whitespace-separated token, never colon-abutted.
#
# Like the plain-emit-06 block below, neither FAIL arm increments errors: the
# errors=$((errors + shape_errors)) fold above already counted every offending
# file, and counting again would change the failure tally.
if [ -z "$pair_offenders" ]; then
  green "PASS: plain-emit-03 every emitter-defining file defines exactly one red and one green"
else
  red "FAIL: plain-emit-03 emitter-defining file(s) do not define exactly one red and one green:"
  printf '%s' "$pair_offenders" | sed 's/^/  /'
fi

# Scoped to the files that cleared the pairing check: the elif above means a
# pairing offender never reaches the n_plain check, so an unqualified "every
# emitter body is plain" claim would be false on exactly the run where
# plain-emit-03 is red.
if [ -z "$plain_offenders" ]; then
  green "PASS: plain-emit-04 both emitter bodies are the plain printf form in every file that cleared the pairing check above"
else
  red "FAIL: plain-emit-04 emitter-defining file(s) clearing the pairing check have bodies that are not both the plain printf form:"
  printf '%s' "$plain_offenders" | sed 's/^/  /'
fi

# Liveness floor — a broken glob must fail loudly rather than pass vacuously.
# 79 files exercise the contract today (1 defines the emitters — the shared
# helper — and 78 source it). The floor sits at 50 so either direction of drift
# has room, and consolidating definers onto the helper cannot trip it.
if [ "$exercisers" -lt 50 ]; then
  red "FAIL: plain-emit-05 only $exercisers file(s) exercising the emitter contract were found (expected at least 50) — the scan is not reaching them"
  errors=$((errors + 1))
else
  green "PASS: plain-emit-05 $exercisers file(s) exercise the emitter contract (floor 50), so the scan is reaching them"
fi

# plain-emit-06 gates on shape_errors alone rather than chaining off the exercisers
# floor. As an elif, the state (exercisers >= 50, shape_errors > 0) emitted neither
# arm, so --case plain-emit-06 could never observe this case go red. The FAIL arm
# below deliberately does NOT increment errors: the errors=$((errors + shape_errors))
# fold above already counted them, and counting again would change the failure tally.
if [ "$shape_errors" -eq 0 ]; then
  green "PASS: plain-emit-06 emitter-defining files are paired and plain — $definers of $exercisers exercising the contract"
else
  red "FAIL: plain-emit-06 $shape_errors emitter-defining file(s) are not paired or not plain — see the plain-emit-03/plain-emit-04 lines above"
fi

# Coverage floor — the shared emitter helper must stay inside the scanned
# population. Keyed per-arm on definers found under the deeper segment, NOT on
# the exercisers floor above and NOT on the whole-population definer count:
# break the deeper arm of the discovery loop and the only definer leaves the
# population while every sourcing file still counts as an exerciser, so that
# floor stays green, shape_errors stays 0 because there is nothing left to
# shape-check, and the dropped coverage reports as a pass. A whole-population
# definer count would also be satisfied by any future suite that inlines its
# own emitters, which would mask the same drop. Only the per-arm count sees it.
# The label carries a stable first-token case id, space-separated and never
# colon-abutted, so a mutation harness classifies this case instead of
# reporting case_not_found.
if [ "$fixtures_definers" -lt 1 ]; then
  red "FAIL: plain-emit-07 no emitter-defining file under the fixtures segment was scanned — the shared helper left the scanned population"
  errors=$((errors + 1))
else
  green "PASS: plain-emit-07 $fixtures_definers emitter-defining file(s) scanned under the fixtures segment, so shared-helper coverage holds"
fi

echo
if [ "$errors" -eq 0 ]; then
  green "plain result-emitter contract all pass."
else
  red "plain result-emitter contract: $errors failure(s)."
  exit 1
fi
