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
#   3  live-lock-not-swept-on-gnu-stat        the ordering pin — a FLAG-AWARE stub
#                                             simulating GNU, where `-f` means
#                                             --file-system and answers with a
#                                             non-mtime, so only a chain that tries
#                                             `-c` first reads the true mtime and
#                                             leaves a LIVE peer's lock alone
#
# Every case drives the acquire loop to its ceiling on purpose, so each sets
#   APPEND_CLAIM_MAX_WAIT=3 as a per-invocation prefix — 0.3s each instead of the
#   production 3s, which is what keeps the whole suite around a second rather than
#   the ~7.3s it cost when the ceiling was a hardcoded constant. The prefix is
#   deliberately NOT a suite-level export: run-plugin-tests.py invokes each suite
#   as a bare `bash <path>`, so each case must carry its own ceiling.
#   Cases 2 and 3 assert the DERIVED form of that ceiling in their stderr literal
#   (`after 0.3s`), not a fixed string — change the ceiling and the literal moves
#   with it. That coupling is the point: it is what stops the message from
#   drifting back into restating a number the loop no longer honours.
#
# Usage: bash cogni-portfolio/tests/test-append-claim-lock.sh
# Exits non-zero on any assertion failure.
#
# This suite has NO per-case selector — all cases are unconditional top-level
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
#   Second arm — the shape floor, case 2's side of it:
#   bash ~/.claude/plugins/cache/managed-service/cogni-service/0.0.402/scripts/mutation-check.sh \
#     --root . \
#     --file cogni-portfolio/scripts/append-claim.sh \
#     --expr 's/\^\[0-9\]\+\$/^NOMATCH\$/' \
#     --test 'bash cogni-portfolio/tests/test-append-claim-lock.sh' \
#     --case live-lock-not-swept-on-numeric-stat
#
#   Arm one mutates the floor's ASSIGNMENT and is caught by case 1; this one
#   mutates the floor's CONDITION and is caught by case 2, which is why both are
#   recorded rather than one standing in for the other. Replacing the character
#   class with one that cannot match makes the `||` fire unconditionally, so a
#   live peer's current-epoch reading is floored to 0, reads as ancient, gets
#   swept, and the script goes on to append — case 2 sees exit 0 where it demands
#   exit 1. The pattern's `^` and `$` are ESCAPED, i.e. matched as the literal
#   characters of the regex text on the floor line, not as anchors — so the
#   expression needs no `/m` under the harness's `perl -0pi`, which slurps the
#   whole file. `^[0-9]+$` occurs exactly once (the ceiling's own floor above
#   reads `^[1-9][0-9]*$`), so the substitution can never be a no-op.
#
#   Third arm — the ceiling-to-message coupling:
#   bash ~/.claude/plugins/cache/managed-service/cogni-service/0.0.402/scripts/mutation-check.sh \
#     --root . \
#     --file cogni-portfolio/scripts/append-claim.sh \
#     --expr 's/APPEND_CLAIM_MAX_WAIT:-30/APPEND_CLAIM_MAX_WAIT_UNUSED:-30/' \
#     --test 'bash cogni-portfolio/tests/test-append-claim-lock.sh' \
#     --case live-lock-not-swept-on-numeric-stat
#
#   The expression redirects the override to a dead variable, so the script
#   ignores the ceiling the cases set, waits the production 3s and announces
#   `after 3s` while case 2 asserts the derived `after 0.3s`. That is exactly the
#   decoupling this arm exists to catch: without it, a message that restates a
#   constant instead of deriving one stays green. `APPEND_CLAIM_MAX_WAIT:-30`
#   occurs exactly once (the header names the variable in prose without the
#   `:-30` default), so the substitution can never be a no-op, and the expression
#   carries no `^`/`$` anchor so it needs no `/m` under the harness's `perl -0pi`.
#
#   Fourth arm — the GNU-first ORDERING:
#   bash ~/.claude/plugins/cache/managed-service/cogni-service/0.0.402/scripts/mutation-check.sh \
#     --root . \
#     --file cogni-portfolio/scripts/append-claim.sh \
#     --expr 's/stat -c %Y/stat -f %m/' \
#     --test 'bash cogni-portfolio/tests/test-append-claim-lock.sh' \
#     --case live-lock-not-swept-on-gnu-stat
#
#   The expression swaps the chain back to BSD-first while leaving the shape floor
#   intact, so this arm mutates the ORDERING rather than the floor arms one and two
#   cover. Under case 3's flag-aware stub the mutated script calls `stat -f %m`
#   first; the stub answers `%m` and exits 0, so the `||` never falls through, the
#   floor coerces that non-numeric reading to 0, a LIVE peer's lock reads as ancient
#   and is swept, and the script appends and exits 0 where case 3 demands exit 1.
#   That is the whole reason the ordering is worth pinning on its own merits: the
#   floor makes this failure silent rather than loud, it does not make it safe, and
#   the host it strikes is exactly the one — Linux — the GNU-first fix was about.
#
#   Only case 3 catches this arm. Cases 1 and 2 pass a stub that ignores its flags,
#   so they answer identically under either ordering and stay ordering-agnostic by
#   design — which is why this arm names case 3 and not one of them. `stat -c %Y`
#   occurs exactly once in the script (the comment above the read line names only
#   `stat -f %m`), so the substitution can never be a no-op, and the expression
#   carries no `^`/`$` anchor so it needs no `/m` under the harness's `perl -0pi`.
#
#   Fifth arm — the OUTPUT ENVELOPE itself:
#   bash ~/.claude/plugins/cache/managed-service/cogni-service/0.0.402/scripts/mutation-check.sh \
#     --root . \
#     --file cogni-portfolio/scripts/append-claim.sh \
#     --expr 's/True/False/' \
#     --test 'bash cogni-portfolio/tests/test-append-claim-lock.sh' \
#     --case stale-lock-swept-on-non-numeric-stat
#
#   The expression flips the success envelope's own flag. `True` occurs exactly once
#   in the script — the two bash-side emits spell the key double-quoted with a
#   lowercase `false`, and the python failure branch spells it `False` — so the
#   substitution can never be a no-op, and it carries no
#   `^`/`$` anchor so it needs no `/m` under the harness's `perl -0pi`.
#
#   Only case 1 catches this arm, because only case 1 reaches the success print at
#   all: cases 2 and 3 exit from the acquire loop before it. Under the mutation the
#   script still exits 0 and still writes nothing to stderr, and its stdout still
#   parses as JSON — so the exit-code and stderr-emptiness assertions stay green and
#   only the envelope assertion discriminates. That is precisely what makes asserting
#   the whole envelope, rather than the nested status alone, worth its line.

# `set -u` only — `set -e` would abort on the first failing assertion and defeat
# the per-case failure counter below. All cases also run a script that is
# EXPECTED to exit non-zero in two of them.
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
# The helper is body-agnostic — it writes whatever `$2` holds — and the suite uses
# that in two deliberately different ways. Cases 1 and 2 pass a body that ignores
# its flags and answers unconditionally: the `||` chain short-circuits on the first
# exit-0 call, so such a body is correct under both the pre-fix BSD-first and the
# post-fix GNU-first ordering, which keeps those two cases from being coupled to
# the ordering the fix happens to land with. Case 3 passes a FLAG-AWARE body and is
# coupled to the ordering on purpose — that coupling is the thing it exists to pin.
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
# still installs the trap, appends the claim and exits 0 with the success envelope
# carrying data.status=appended, never having held the lock; its EXIT trap then
# removes a live peer's lock directory it never owned. Exit code and stdout are consequently identical
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
# our OWN scripts' literals by text. Cases 2 and 3 below grep `Could not acquire
# lock` precisely because append-claim.sh emits that string itself.
case1_dir="$(seed_contended_project stale-non-numeric)"
case1_stub="$TMPROOT/stub-non-numeric"
make_stat_stub "$case1_stub" 'echo "%m"'
case1_out="$(PATH="$case1_stub:$PATH" APPEND_CLAIM_MAX_WAIT=3 bash "$SCRIPT" "$case1_dir" '{"id": "claim-1"}' 2>"$TMPROOT/case1.err")"
case1_rc=$?

if [ "$case1_rc" -ne 0 ]; then
  fail "stale-lock-swept-on-non-numeric-stat" "expected exit 0, got $case1_rc (stderr: $(cat "$TMPROOT/case1.err"))"
elif [ -s "$TMPROOT/case1.err" ]; then
  fail "stale-lock-swept-on-non-numeric-stat" "expected silence on stderr, got: $(cat "$TMPROOT/case1.err")"
elif ! printf '%s' "$case1_out" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["success"] is True and d["data"]["status"] == "appended" and d["error"] is None else 1)' 2>/dev/null; then
  fail "stale-lock-swept-on-non-numeric-stat" "stdout did not parse as a {success,data,error} object with data.status=appended: $case1_out"
else
  pass "stale-lock-swept-on-non-numeric-stat" "floored to 0, ancient lock swept, claim appended"
fi

# --- Case 2 (negative twin): a numeric, current mtime means the lock is LIVE.
#
# Without this case a fix that unconditionally sets lock_mtime=0 satisfies case 1
# while destroying mutual exclusion — every contended lock would read as ancient
# and get swept out from under a running peer once the acquire ceiling elapses.
case2_dir="$(seed_contended_project live-numeric)"
case2_stub="$TMPROOT/stub-numeric"
make_stat_stub "$case2_stub" 'date +%s'
PATH="$case2_stub:$PATH" APPEND_CLAIM_MAX_WAIT=3 bash "$SCRIPT" "$case2_dir" '{"id": "claim-2"}' >/dev/null 2>"$TMPROOT/case2.err"
case2_rc=$?

if [ "$case2_rc" -ne 1 ]; then
  fail "live-lock-not-swept-on-numeric-stat" "expected exit 1, got $case2_rc"
elif ! grep -q 'Could not acquire lock on claims.json after 0.3s' "$TMPROOT/case2.err"; then
  fail "live-lock-not-swept-on-numeric-stat" "stderr did not carry the timeout error: $(cat "$TMPROOT/case2.err")"
elif [ ! -d "$case2_dir/cogni-claims/.claims.lock" ]; then
  fail "live-lock-not-swept-on-numeric-stat" "a live peer's lock was swept"
else
  pass "live-lock-not-swept-on-numeric-stat" "fresh lock left intact, script timed out"
fi

# --- Case 3: the ordering pin — only a chain that tries `-c` first reads an mtime.
#
# Cases 1 and 2 cannot see the ordering at all, and that is by design: their stub
# answers unconditionally, so the `||` chain's first call succeeds whichever form
# it is, and both cases stay green under either ordering. The consequence is that
# nothing above pins the GNU-first chain — reverting it to BSD-first leaves the
# suite green. This case closes that gap with a FLAG-AWARE stub, which is the
# minimum needed to tell the two calls apart.
#
# The stub simulates GNU coreutils, where `-f` means --file-system rather than a
# format string: `-c` answers with a real current epoch, `-f` answers with the
# literal `%m` and — the load-bearing part — exits 0, so a BSD-first chain never
# falls through to its second call. Against the SHIPPED script this case is
# behaviourally identical to case 2: `-c` runs first, returns a numeric current
# epoch, the lock reads as live, and the script times out leaving it intact. The
# two diverge ONLY when the ordering is swapped, which is exactly what makes this a
# distinct case rather than a duplicate of case 2 — under the swap the `%m` reading
# is floored to 0, a live peer's lock reads as ancient and is swept, and the script
# appends and exits 0.
#
# The stub body is SINGLE-quoted so `$1` reaches the written file unexpanded rather
# than being substituted with this suite's own (empty) `$1` at authoring time, and
# make_stat_stub passes it as printf's ARGUMENT, so the `%m` inside it is never
# read as a format specifier — case 1's `echo "%m"` body is the precedent.
#
# The stderr grep is of append-claim.sh's OWN literal, which is why it is a text
# match at all. Anything the shell or coreutils emits is asserted by SHAPE here
# instead — those diagnostics are gettext-localized, so a text match on one would
# pass vacuously off an English-locale host.
case3_dir="$(seed_contended_project live-gnu-ordering)"
case3_stub="$TMPROOT/stub-gnu-ordering"
make_stat_stub "$case3_stub" 'case "$1" in
  -c) date +%s ;;
  -f) echo "%m" ;;
  *) exit 1 ;;
esac'
PATH="$case3_stub:$PATH" APPEND_CLAIM_MAX_WAIT=3 bash "$SCRIPT" "$case3_dir" '{"id": "claim-3"}' >/dev/null 2>"$TMPROOT/case3.err"
case3_rc=$?

if [ "$case3_rc" -ne 1 ]; then
  fail "live-lock-not-swept-on-gnu-stat" "expected exit 1, got $case3_rc — a BSD-first chain would sweep the live lock and append"
elif ! grep -q 'Could not acquire lock on claims.json after 0.3s' "$TMPROOT/case3.err"; then
  fail "live-lock-not-swept-on-gnu-stat" "stderr did not carry the timeout error: $(cat "$TMPROOT/case3.err")"
elif [ ! -d "$case3_dir/cogni-claims/.claims.lock" ]; then
  fail "live-lock-not-swept-on-gnu-stat" "a live peer's lock was swept"
else
  pass "live-lock-not-swept-on-gnu-stat" "GNU-first chain read the true mtime, live lock left intact"
fi

if [ "$failures" -gt 0 ]; then
  printf '\n%d test(s) failed\n' "$failures" >&2
  exit 1
fi
printf '\nAll tests passed.\n'
