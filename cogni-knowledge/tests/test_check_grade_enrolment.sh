#!/usr/bin/env bash
# test_check_grade_enrolment.sh — enrolment census for the two-part check/grade
# convention.
#
# fixtures/test_helpers.sh's check_grade_census closes the INNER loop: inside a
# suite that calls it, a registration with no matching grade line reddens that
# suite. Adopting it was still an OUTER loop that nothing read — the caller set
# was a hand-maintained list restated in prose, so a fourth suite that picked up
# the convention and never called the helper stayed green with an orphan hidden
# in it. This suite derives that caller set from file content instead, so the
# population is self-enrolling rather than self-listing.
#
# bash 3.2 + python3 stdlib only (no pytest, no pip). Matches tests/README.md.
#
# Three properties are load-bearing.
#
#   1. Neither population anchor may be "simplified", for the reason
#      fixtures/test_helpers.sh property 5 gives one level in — and here the
#      argument does double duty. The registration literal spells an escaped
#      paren, never a bare one, so this file's own source carries no bare
#      registration token and cannot enter the population it polices; and the
#      grade anchor requires whitespace after the word, so a function
#      definition line is not counted as a grade line. Relax either and this
#      suite starts reporting itself.
#
#      The grade anchor is spelled [[:space:]] rather than the awk source's
#      [ \t]: awk reads \t inside a bracket expression as a tab, but grep -E
#      reads it as the two literal characters \ and t, so the awk spelling
#      transplanted here would silently stop matching a tab-separated grade
#      line. [[:space:]] is the grep-correct spelling of the same intent, and
#      still excludes a `(`, which is what property 5 actually requires.
#
#   2. Enrolment is matched in COMMAND POSITION, after comment-stripping —
#      never as a bare substring. Two of the three current callers name the
#      helper in a comment directly above the real call, so a substring test
#      would read a suite that kept the comment and dropped the call as
#      enrolled, masking exactly the non-adopter this suite exists to name. The
#      same discipline keeps the helper's own definition line from counting as
#      a call.
#
#      The TRAILING [[:space:]] in that pattern is what makes this file
#      self-immune: in its own source the next character after the helper's
#      name is `[`, not whitespace. Dropping it as a redundant-looking
#      character would make this suite read as its own caller.
#
#      Comment-stripping uses sed 's/#.*$//', which also truncates a
#      ${var#prefix} parameter expansion. No current call line carries one, so
#      the scan is exact today; a future call sharing its line with such an
#      expansion would go unreported rather than mis-reported, which is the
#      safe direction but worth knowing.
#
#   3. Collect then pair, per tests/README.md rule 7: offenders accumulate into
#      one variable inside the loop with NO emission there, and a single
#      same-id if/else fires after the loop closes, gated on that variable and
#      never on the shared errors counter, which an unrelated earlier case
#      could otherwise silence. The FAIL arm still folds into errors — rule 7
#      forbids gating the PASS on the accumulator, not reporting into it — so
#      the suite's EXIT STATUS reflects the finding. Without that fold the red
#      arm prints while the suite exits 0, and run-plugin-tests.py (which reads
#      only the exit code) would call it a pass.
#
# Deliberately NO self-exclusion clause. This file matches neither population
# predicate by construction (property 1), so an explicit "skip myself" branch
# would be dead code — and would mask a real finding if this suite ever did
# adopt the convention. Do not add one.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
HELPER="$TESTS_DIR/fixtures/test_helpers.sh"
# Argument-driven scan root, per tests/README.md rule 7's forcing clause: the
# red arm is reached by pointing this at a seeded directory, never by mutating
# a real suite in place. Stripping a live caller's census assignment instead
# would leave the following comparison reading an unbound variable, and every
# caller runs `set -eu`, so that suite would abort for a reason unrelated to
# enrolment — a red at the wrong locus.
SCAN_ROOT="${1:-$(cd "$TESTS_DIR/../.." && pwd)}"

. "$HELPER"

errors=0

# The repo's own two globs, copied from scripts/run-plugin-tests.py, which
# rejects a narrower form by name: "the narrower form would silently skip a
# future non-cogni- component that ships suites, and report a green sweep while
# doing it — the same class of silent gap this runner exists to close." Scoping
# this scan to one plugin would reproduce exactly the gap it exists to close,
# one level up: tests/README.md records that these conventions were themselves
# copied in from another plugin's suites, so the convention travels. Widening
# is free — the population is the same three files either way today.
#
# Both globs are non-recursive, so fixtures/ stays out: it holds helpers that
# carry no registrations and were never meant to enrol, the same reason
# scripts/check-case-id-pairing.py cannot reach it.
unenrolled=""
population=0

for f in "$SCAN_ROOT"/tests/*.sh "$SCAN_ROOT"/*/tests/*.sh; do
  [ -f "$f" ] || continue

  grep -qE 'check\("[a-z0-9_]+"' "$f" || continue
  grep -qE '^grade[[:space:]]' "$f" || continue

  population=$((population + 1))

  # Inverted around the single statement it guards, so the accumulator reads
  # directly rather than through a "skip if enrolled" double negative. NOT
  # `grep -q … && continue`: under `set -eu` a standalone A && B list whose A
  # fails returns non-zero and aborts the loop.
  if ! sed 's/#.*$//' "$f" | grep -qE '(^|[;&|(]|\$\()[[:space:]]*check_grade_census[[:space:]]'; then
    # Accumulate only — the emission happens once, after the loop.
    unenrolled="$unenrolled${f##*/}
"
  fi
done

enrolment_desc="check/grade enrolment census - every suite carrying both a registration and a grade line also calls the shared census helper, so adopting the convention is derived from file content rather than read from a maintained list"

if [ -z "$unenrolled" ]; then
  green "PASS: check-grade-enrolment-01 $enrolment_desc ($population file(s) use the convention; all enrolled)"
else
  red "FAIL: check-grade-enrolment-01 $enrolment_desc — suite(s) use the convention without calling the census helper:"
  printf '%s' "$unenrolled" | sed 's/^/  /'
  errors=$((errors + 1))
fi

# Liveness floor, the shape test_plain_result_emitters.sh ships as plain-emit-05.
# The case above is green by construction while the population is fully enrolled,
# so it is also green when the population is EMPTY — a broken glob or a relaxed
# anchor would retire the guard silently and read as a pass. The floor is 1
# rather than the current 3: consolidating the convention onto fewer suites is a
# legitimate move that must not redden this, whereas reaching zero means either
# the convention is gone or the scan stopped reaching it, and both deserve a look.
if [ "$population" -lt 1 ]; then
  red "FAIL: check-grade-enrolment-02 no file under $SCAN_ROOT carries both a registration and a grade line — the convention is gone or the scan is not reaching it, so the enrolment case above passed vacuously"
  errors=$((errors + 1))
else
  green "PASS: check-grade-enrolment-02 $population file(s) carry the convention (floor 1), so the enrolment case above has a live population"
fi

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "All check/grade enrolment cases pass."
