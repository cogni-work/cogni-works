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
#   3. empty-pair-list: empty SWISS_PAIRS between its sentinel comments in
#      orthography-drift-scan.py; expect test_orthography_drift_scan.sh to go RED
#      (the drift cases pin an exact finding count that collapses to zero).
#
# No mutation touches the working tree: the target is copied to a temp dir, mutated
# there, and its suite is aimed at the copy through that suite's own env override —
# each falsifier names its target, suite and override variable, so the harness is not
# tied to any one script. test_discover_extractor.sh's M13 end-to-end case runs the
# real discovery wrapper and therefore stays green under mutation by design; that
# suite's exit code turns red on the assert_extract cases, which is what falsifiers
# 1 and 2 target.
#
# Kept under scripts/ (NOT tests/) deliberately: run-plugin-tests.py auto-discovers
# tests/*.sh and would run this as a normal suite; this is a manual meta-check that
# deliberately drives failing sub-runs.
#
# Usage: bash cogni-consult/scripts/mutation-check.sh   (no args, no network)

set -u

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
overall=0

# One subject under falsification = one triple (script, its suite, that suite's override
# variable). Named once here rather than re-spelled per falsifier: a mis-PAIRING — right
# suite, wrong override — would run the UNMUTATED script through a green suite and report
# "mutation survived", sending someone to debug a detector that is fine.
DISCOVER=(
  "$SCRIPTS_DIR/_discover_extractor.py"
  "$PLUGIN_DIR/tests/test_discover_extractor.sh"
  CONSULT_DISCOVER_EXTRACTOR
)
ORTHOGRAPHY=(
  "$SCRIPTS_DIR/orthography-drift-scan.py"
  "$PLUGIN_DIR/tests/test_orthography_drift_scan.sh"
  CONSULT_ORTHOGRAPHY_SCAN
)

# run_mutation <target> <suite> <env-var> <label> <description> <python-re-program>
#
# Copies <target> to a temp dir, applies the mutation program to the copy (which must
# report exactly one substitution or the run fails loud rather than passing silently),
# runs <suite> against the mutant — reached through <env-var>, the override that suite
# defines for exactly this purpose — and asserts it goes RED. Returns 0 when the
# mutation is caught, non-zero otherwise.
#
# Target and suite are parameters rather than globals so a second script can be
# falsified without restructuring the harness: a falsifier that cannot be registered
# is a detector with no recorded teeth.
run_mutation() {
  local target="$1" suite="$2" env_var="$3" label="$4" description="$5" program="$6"
  for f in "$target" "$suite"; do
    [ -f "$f" ] || { echo "FAIL: missing $f" >&2; return 1; }
  done

  # Baseline: the suite must be GREEN before we mutate, or a later red tells us
  # nothing about the mutation.
  if ! bash "$suite" >/dev/null 2>&1; then
    echo "FAIL: baseline $(basename "$suite") is already red before mutation ($label)" >&2
    return 1
  fi

  local tmp; tmp="$(mktemp -d)"
  local mutated="$tmp/$(basename "$target")"
  cp "$target" "$mutated"

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
  if env "$env_var=$mutated" bash "$suite" >/dev/null 2>&1; then
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
run_mutation "${DISCOVER[@]}" "newest-not-last" "max(stamps) replaced by stamps[-1]" \
  'mutated, n = re.subn(r"max\(stamps\)", "stamps[-1]", src, count=1)' \
  || overall=1

# --- Mutation 2: defensive log read -------------------------------------------
# Narrows the log read's own `except Exception` so it no longer catches the
# errors a missing or corrupt log actually raises — the guard stays textually
# present but stops guarding. This is what the "a malformed log never breaks
# discovery" claim rests on; excising the block outright would instead leave
# `stamps` empty and the fallback still reached, which is a weaker mutant.
run_mutation "${DISCOVER[@]}" "defensive-log-read" "the log read's except clause narrowed so it no longer catches" \
  'mutated, n = re.subn(
    r"(    log = os\.path\.join.*?)    except Exception:",
    r"\1    except ZeroDivisionError:",
    src,
    count=1,
    flags=re.DOTALL,
)' \
  || overall=1

# --- Mutation 3: empty pair list ----------------------------------------------
# SWISS_PAIRS is the single machine-readable home of what the orthography scan can
# find, so emptying it must collapse detection to zero. The suite pins the drift
# fixture's exact count, so a mutant that still reported most forms would be caught
# too — a bare non-zero check would not have been. Same sentinel substitution the
# suite's own 13a case uses, so the two agree on what "detection" means.
run_mutation "${ORTHOGRAPHY[@]}" "empty-pair-list" "the curated SWISS_PAIRS list emptied" \
  'mutated, n = re.subn(
    r"# --- swiss-pairs-begin ---.*?# --- swiss-pairs-end ---",
    "# --- swiss-pairs-begin ---\nSWISS_PAIRS = ()\n# --- swiss-pairs-end ---",
    src,
    count=1,
    flags=re.S,
)' \
  || overall=1

if [ "$overall" -eq 0 ]; then
  echo "All mutations caught."
else
  echo "One or more mutations survived." >&2
fi
exit "$overall"
