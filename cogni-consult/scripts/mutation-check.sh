#!/usr/bin/env bash
# Mutation harness for cogni-consult.
#
# Runs each falsifier in turn and asserts the targeted test suite goes RED
# against the mutant — proving the detection actually has teeth rather than
# claiming it. Exit 0 iff EVERY mutation is caught; non-zero if any survives.
#
#   1. newest-not-last: swap `max(stamps)` for `stamps[-1]` in
#      _discover_extractor.py; expect test_discover_extractor.sh to go RED
#      (case M1 stores the newest transition in a non-final position).
#   2. defensive log read: narrow the log read's own `except Exception` so it
#      stops catching; expect test_discover_extractor.sh to go RED (M3/M4/M5/
#      M10/M12 have an absent or corrupt log and extract() now raises).
#
# Neither mutation touches the working tree: the extractor is copied to a temp
# dir, mutated there, and the suite is aimed at the copy via
# CONSULT_DISCOVER_EXTRACTOR. The suite's M13 end-to-end case runs the real
# discovery wrapper and therefore stays green under mutation by design — the
# suite's exit code turns red on the assert_extract cases, which is what these
# falsifiers target.
#
# Kept under scripts/ (NOT tests/) deliberately: run-plugin-tests.py auto-discovers
# tests/*.sh and would run this as a normal suite; this is a manual meta-check that
# deliberately drives failing sub-runs.
#
# Usage: bash cogni-consult/scripts/mutation-check.sh   (no args, no network)

set -u

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
TARGET="$SCRIPTS_DIR/_discover_extractor.py"
SUITE="$PLUGIN_DIR/tests/test_discover_extractor.sh"

overall=0

# run_mutation <label> <description> <python-re-program>
#
# Copies the extractor to a temp dir, applies the mutation program to the copy
# (which must report exactly one substitution or the run fails loud rather than
# passing silently), runs the suite against the mutant, and asserts it goes RED.
# Returns 0 when the mutation is caught, non-zero otherwise.
run_mutation() {
  local label="$1" description="$2" program="$3"
  for f in "$TARGET" "$SUITE"; do
    [ -f "$f" ] || { echo "FAIL: missing $f" >&2; return 1; }
  done

  # Baseline: the suite must be GREEN before we mutate, or a later red tells us
  # nothing about the mutation.
  if ! bash "$SUITE" >/dev/null 2>&1; then
    echo "FAIL: baseline test_discover_extractor.sh is already red before mutation ($label)" >&2
    return 1
  fi

  local tmp; tmp="$(mktemp -d)"
  local mutated="$tmp/_discover_extractor.py"
  cp "$TARGET" "$mutated"

  if ! python3 - "$mutated" <<PY
import re, sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()
$program
if n != 1:
    sys.stderr.write("mutation target not found — the expression matched %d times, expected 1\n" % n)
    sys.exit(3)
open(path, "w", encoding="utf-8").write(mutated)
PY
  then
    echo "FAIL: $label mutation could not be applied" >&2
    rm -rf "$tmp"; return 1
  fi

  local rc=0
  if CONSULT_DISCOVER_EXTRACTOR="$mutated" bash "$SUITE" >/dev/null 2>&1; then
    echo "FALSIFIER: mutation survived — the suite stayed GREEN with $description" >&2
    rc=1
  else
    echo "OK: mutation caught — the suite goes red with $description"
  fi
  rm -rf "$tmp"
  return "$rc"
}

# --- Mutation 1: newest-not-last ----------------------------------------------
# `max(stamps)` is what makes the newest transition win regardless of its
# position in the log. `stamps[-1]` passes casual testing on an append-ordered
# log and silently mis-sorts a hand-edited or merged one.
run_mutation "newest-not-last" "max(stamps) replaced by stamps[-1]" \
  'mutated, n = re.subn(r"max\(stamps\)", "stamps[-1]", src, count=1)' \
  || overall=1

# --- Mutation 2: defensive log read -------------------------------------------
# Narrows the log read's own `except Exception` so it no longer catches the
# errors a missing or corrupt log actually raises — the guard stays textually
# present but stops guarding. This is what the "a malformed log never breaks
# discovery" claim rests on; excising the block outright would instead leave
# `stamps` empty and the fallback still reached, which is a weaker mutant.
run_mutation "defensive-log-read" "the log read's except clause narrowed so it no longer catches" \
  'mutated, n = re.subn(
    r"(    log = os\.path\.join.*?)    except Exception:",
    r"\1    except ZeroDivisionError:",
    src,
    count=1,
    flags=re.DOTALL,
)' \
  || overall=1

if [ "$overall" -eq 0 ]; then
  echo "All mutations caught."
else
  echo "One or more mutations survived." >&2
fi
exit "$overall"
