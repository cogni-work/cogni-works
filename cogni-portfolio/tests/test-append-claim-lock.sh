#!/usr/bin/env bash
# Regression test for cogni-portfolio/scripts/append-claim.sh covering the
# stale-lock sweep's mtime reading — the BSD-first `stat` chain that returns a
# successful *wrong* answer on GNU coreutils.
#
# Fixtures are built inline under a temp root — no committed blobs to maintain.
# Each case builds a minimal claims project, pre-creates the lock directory so
# the acquire loop is genuinely contended, shadows `stat` with a stub on PATH,
# runs the script, and asserts on the exit code plus both output streams.
#
# Coverage:
#   1  stale-lock-swept-on-non-numeric-stat   non-numeric mtime reading is floored
#                                             to 0, the ancient lock is swept, the
#                                             claim appends, and stderr stays empty
#   2  live-lock-not-swept-on-numeric-stat    negative twin — a numeric current-epoch
#                                             reading leaves a LIVE peer's lock
#                                             alone; the script times out instead
#
# Usage: bash cogni-portfolio/tests/test-append-claim-lock.sh
# Exits non-zero on any assertion failure.
#
# This suite has NO per-case selector — both cases are unconditional top-level
#   code, so an argument naming one is ignored. The recipe below therefore runs
#   the whole suite, and the harness classifies on the named case's output line.
#
# Mutation recipe — the SHARED cogni-service harness. Replayable as written, from the
#   repo root:
#   bash ~/.claude/plugins/cache/managed-service/cogni-service/0.0.402/scripts/mutation-check.sh \
#     --root . \
#     --file cogni-portfolio/scripts/append-claim.sh \
#     --expr 's/lock_mtime=0/lock_mtime_unused=0/' \
#     --test 'bash cogni-portfolio/tests/test-append-claim-lock.sh' \
#     --case stale-lock-swept-on-non-numeric-stat
#   There is no in-repo copy of the SHARED harness; if that version directory is gone,
#   use the newest under the same parent — everything after the path is version-independent.
#
#   The expression redirects the shape floor's assignment to a dead variable, so
#   the non-numeric reading survives into the arithmetic. `lock_mtime=0` occurs
#   exactly once in the fixed script (the read line is `lock_mtime=$(stat ...`,
#   which does not contain it), so the substitution can never be a no-op.
#
#   Only ONE arm is recorded, and the reason is narrower than it may look. An arm
#   mutating the GNU-first ordering (`s/stat -c %Y/stat -f %m/`) reports a vacuous
#   guard against the TWO CASES BELOW, because their stub answers unconditionally
#   and ignores its flags by design — deliberately, so both stay ordering-agnostic.
#
#   That is a property of these two cases, NOT a general limit: a flag-aware stub
#   (`-c` prints an epoch, `-f` prints `%m` and exits 0, simulating GNU) does
#   discriminate the two orderings, and the ordering is worth pinning on its own
#   merits — with the floor present but the ordering swapped, a GNU host floors
#   every contended lock's reading to 0, reads it as ancient, and sweeps a LIVE
#   peer's lock. Do not read this note as "the ordering cannot be tested".

# `set -u` only — `set -e` would abort on the first failing assertion and defeat
# the per-case failure counter below. Both cases also run a script that is
# EXPECTED to exit non-zero in one of them.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/append-claim.sh"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: append-claim.sh not found at $SCRIPT" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
# Keep the message a SEPARATE argument. The shared mutation harness anchors on the
# case token and needs whitespace or end-of-line right after it, so folding it back
# into one `<case>: <msg>` string puts a colon there and the case stops matching.
pass() { printf 'ok: %s %s\n' "$1" "${2:-}"; }
fail() { printf 'FAIL: %s %s\n' "$1" "${2:-}" >&2; failures=$((failures + 1)); }

# Build a stub `stat` on its own PATH prefix. The directory holds exactly one
# file so `date` and `python3` keep resolving to the real binaries — the script
# calls all three by bare name.
#
# The stub ignores its flags and answers unconditionally. That is deliberate: the
# `||` chain short-circuits on the first exit-0 call, so an unconditional stub is
# correct under both the pre-fix BSD-first and post-fix GNU-first orderings, and
# the suite is not coupled to the ordering the fix happens to land with.
make_stat_stub() {
  mkdir -p "$1"
  printf '#!/bin/sh\n%s\n' "$2" > "$1/stat"
  chmod +x "$1/stat"
}

# Each case needs its OWN project directory. The swept path installs the script's
# release trap and cleans the lock up on exit; the timeout path exits from inside
# the acquire loop BEFORE that trap line is reached and deliberately leaves the
# lock behind. Reusing one directory would let case order decide the result.
seed_contended_project() {
  local pdir="$TMPROOT/$1"
  mkdir -p "$pdir/cogni-claims"
  mkdir "$pdir/cogni-claims/.claims.lock"
  printf '%s' "$pdir"
}

# --- Case 1: a non-numeric mtime reading must be floored, not fed to arithmetic.
#
# The stub prints `%m`, and the value MUST stay non-identifier-shaped. `$(( now -
# lock_mtime ))` reads a VARIABLE, and bash evaluates an identifier-shaped value
# recursively, which opens two escape hatches that would make this case vacuous:
# a bare word like `bogus` aborts only because `set -u` happens to be on, and a
# word naming a variable the script already sets (`MAX_WAIT`) resolves to a
# NUMBER and never aborts at all. `%m` is a hard operand syntax error under both.
#
# The stderr assertion is equally load-bearing. On every bash tested — 3.2.57
# through 5.3.9 alike — an arithmetic abort inside a `while` loop abandons the
# loop body AND the loop, then resumes after `done`. The UNFIXED script therefore
# still installs the trap, appends the claim and exits 0 with status=appended,
# never having held the lock; its EXIT trap then removes a live peer's lock
# directory it never owned. Exit code and stdout are consequently identical
# before and after the fix, so only stderr discriminates. A case asserting just
# exit-0 and stdout stays green under the mutation recipe above, i.e. it pins
# nothing.
#
# The discriminator is stderr EMPTINESS, not a text match. Bash's arithmetic-error
# message is gettext-localized, and it varies along TWO axes, not one: the host
# locale, and whether the bash build ships translations at all. Measured on a
# single host under one unchanged locale, bash 3.2.57 emits `syntax error: operand
# expected` while bash 5.3.9 emits `Arithmetischer Syntaxfehler: Operand erwartet`.
# So a grep for the English wording matches nothing, the case passes against the
# UNFIXED script, and the guard guards nothing — and pinning the locale would not
# have saved it, because the version axis remains. The fixed script writes exactly
# 0 bytes here, so emptiness is independent of both axes and catches every
# diagnostic rather than one translation of one of them.
#
# The general rule, worth keeping in view when adding a case: assert a FOREIGN
# tool's output by SHAPE (exit status, stream emptiness, numeric form), and only
# our OWN scripts' literals by text. Case 2 below greps `Could not acquire lock`
# precisely because append-claim.sh emits that string itself.
case1_dir="$(seed_contended_project stale-non-numeric)"
case1_stub="$TMPROOT/stub-non-numeric"
make_stat_stub "$case1_stub" 'echo "%m"'
case1_out="$(PATH="$case1_stub:$PATH" bash "$SCRIPT" "$case1_dir" '{"id": "claim-1"}' 2>"$TMPROOT/case1.err")"
case1_rc=$?

if [ "$case1_rc" -ne 0 ]; then
  fail "stale-lock-swept-on-non-numeric-stat" "expected exit 0, got $case1_rc (stderr: $(cat "$TMPROOT/case1.err"))"
elif [ -s "$TMPROOT/case1.err" ]; then
  fail "stale-lock-swept-on-non-numeric-stat" "expected silence on stderr, got: $(cat "$TMPROOT/case1.err")"
elif ! printf '%s' "$case1_out" | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin).get("status") == "appended" else 1)' 2>/dev/null; then
  fail "stale-lock-swept-on-non-numeric-stat" "stdout did not parse as JSON with status=appended: $case1_out"
else
  pass "stale-lock-swept-on-non-numeric-stat" "floored to 0, ancient lock swept, claim appended"
fi

# --- Case 2 (negative twin): a numeric, current mtime means the lock is LIVE.
#
# Without this case a fix that unconditionally sets lock_mtime=0 satisfies case 1
# while destroying mutual exclusion — every contended lock would read as ancient
# and get swept out from under a running peer after 3s.
case2_dir="$(seed_contended_project live-numeric)"
case2_stub="$TMPROOT/stub-numeric"
make_stat_stub "$case2_stub" 'date +%s'
PATH="$case2_stub:$PATH" bash "$SCRIPT" "$case2_dir" '{"id": "claim-2"}' >/dev/null 2>"$TMPROOT/case2.err"
case2_rc=$?

if [ "$case2_rc" -ne 1 ]; then
  fail "live-lock-not-swept-on-numeric-stat" "expected exit 1, got $case2_rc"
elif ! grep -q 'Could not acquire lock on claims.json after 3s' "$TMPROOT/case2.err"; then
  fail "live-lock-not-swept-on-numeric-stat" "stderr did not carry the timeout error: $(cat "$TMPROOT/case2.err")"
elif [ ! -d "$case2_dir/cogni-claims/.claims.lock" ]; then
  fail "live-lock-not-swept-on-numeric-stat" "a live peer's lock was swept"
else
  pass "live-lock-not-swept-on-numeric-stat" "fresh lock left intact, script timed out"
fi

if [ "$failures" -gt 0 ]; then
  printf '\n%d test(s) failed\n' "$failures" >&2
  exit 1
fi
printf '\nAll tests passed.\n'
