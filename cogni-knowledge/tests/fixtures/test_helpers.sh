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

# case_slug VALUE
#   Fold an arbitrary loop value into the [a-z0-9-] discriminator a case id
#   admits: lowercase, every run of non-alnum collapsed to ONE hyphen, and
#   leading/trailing hyphens trimmed. The trim is the load-bearing part — a
#   scanned name like `_cycle_guard_lib.sh` otherwise mints
#   `<slug>-NN--cycle-guard-lib-sh`, whose empty segment the recorded shape
#   rejects. Such ids sit on fail-only arms, so running the suite green can
#   never reveal the defect; one shared spelling is what keeps it from
#   recurring per call site.
case_slug() {
  printf '%s' "$1" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9][^a-z0-9]*/-/g; s/^-//; s/-$//'
}

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

# check_grade_census FILE
#   Census the two-part check/grade convention in FILE and print a verdict
#   string on stdout: `PASS`, or a diagnostic naming the offending tag(s). The
#   caller owns its own case id and both result arms — this function emits no
#   label and increments no `errors`, so it follows case_slug's return-a-value
#   shape rather than the assert_* family's emit-and-increment one.
#
#   The convention has no structural enforcement of its own: a python-side
#   registration prints "<tag>: OK"/"<tag>: FAIL" into the suite's $OUT, and
#   only a bash-side `grade <tag> "..."` line ever reads it, so a registration
#   with no grade line is never read and can never fail the suite. #1753 found
#   two such orphans.
#
#   The census is bash-side rather than part of the python harness because the
#   heredoc runs as a subprocess with no handle on the suite's own source, and
#   half the subject here — the grade lines — is script text that never enters
#   it. Callers fold the verdict into their own $errors so the rest of the
#   report still prints; it is not fatal.
#
#   Five properties are load-bearing.
#
#   1. Every extraction keeps the `|| true` guard #1753 wrote. Measured, it is
#      belt-and-braces rather than the thing holding the suite up: each guard
#      sits on the LAST element of its pipeline, where `sort` and `tr` succeed
#      on empty input, so a zero-match extraction survives `set -eu` without
#      them — and under `set -o pipefail` too. Keep them anyway: they are the
#      guard a future edit needs if the grep or awk ever moves to the tail of
#      its pipeline, which is where the abort #1753 described would be real.
#   2. It returns 0 on every path. Every call site is
#      `census_verdict=$(check_grade_census "$0")`, and under `set -e` an
#      assignment takes its status from the substitution — a body ending in a
#      failing test would kill the caller instead of reporting a verdict.
#   3. It mints its own scratch dir and installs NO `EXIT` handler of its own.
#      test_ingest_contract.sh defines no $WORK at all, so a caller-supplied
#      scratch dir cannot be assumed; and test_knowledge_lib.sh and
#      test_pdf_extract.sh each already install an `EXIT` handler that removes
#      their $WORK. A second one here would silently REPLACE the caller's,
#      leaking that caller's $WORK with every suite still green, so nothing
#      would report it. Clean up inline instead, as the body below does.
#   4. Pass FILE as the caller's own `"$0"`. Pointing it at this helper is
#      harmless — neither extractor matches its own literal, so the census
#      comes back `EMPTY - registrations=0 grade lines=0`, which is the honest
#      answer: this file carries no registrations to pair.
#   5. Neither anchor may be "simplified". The registration literal spells an
#      escaped paren, never a bare one, so it cannot match itself; and
#      `/^grade[ \t]/` requires whitespace after `grade`, so a `grade() {`
#      definition line is not counted as a grade line. Relaxing either turns a
#      clean census into a phantom finding.
#
#   LC_ALL=C keeps sort and comm byte-collated, since the tags contain `_`.
check_grade_census() {
  local file scratch dup_reg dup_graded only_reg only_graded verdict
  file="$1"
  scratch=$(mktemp -d)

  grep -oE 'check\("[a-z0-9_]+"' "$file" | sed 's/^check("//; s/"$//' | LC_ALL=C sort > "$scratch/reg" || true
  awk '/^grade[ \t]/{print $2}' "$file" | LC_ALL=C sort > "$scratch/graded" || true
  dup_reg=$(LC_ALL=C uniq -d "$scratch/reg" | tr '\n' ' ' || true)
  dup_graded=$(LC_ALL=C uniq -d "$scratch/graded" | tr '\n' ' ' || true)
  only_reg=$(LC_ALL=C comm -23 "$scratch/reg" "$scratch/graded" | tr '\n' ' ' || true)
  only_graded=$(LC_ALL=C comm -13 "$scratch/reg" "$scratch/graded" | tr '\n' ' ' || true)

  verdict="PASS"
  if [ ! -s "$scratch/reg" ] || [ ! -s "$scratch/graded" ]; then
    verdict="EMPTY - registrations=$(wc -l < "$scratch/reg") grade lines=$(wc -l < "$scratch/graded"); an extractor matched nothing, so the convention was renamed or the scan is broken"
  elif [ -n "$dup_reg" ]; then
    verdict="DUP-REGISTRATION - tag registered more than once: $dup_reg"
  elif [ -n "$dup_graded" ]; then
    verdict="DUP-GRADE - tag graded more than once: $dup_graded"
  elif [ -n "$only_reg" ]; then
    verdict="ORPHAN-REGISTRATION - registered but never graded, so its result is never read: $only_reg"
  elif [ -n "$only_graded" ]; then
    verdict="ORPHAN-GRADE - graded but never registered: $only_graded"
  fi

  rm -rf "$scratch"
  printf '%s' "$verdict"
  return 0
}
