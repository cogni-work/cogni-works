#!/usr/bin/env bash
# Guard: the copywriter skill's arc-preservation mirror must stay in sync with the
# narrative skill's story-arc definitions.
#
# WHAT THIS REPLACES
#   The `audit-copywriter` skill. That skill existed solely to diff two plugins that
#   are now one, walking up the directory tree to find cogni-narrative/ and
#   cogni-copywriting/ as siblings. Once both trees live under this plugin the check
#   is an intra-plugin invariant, and an invariant a script can assert should not be
#   an LLM skill a human has to remember to run.
#
# WHAT MOVED ACROSS, AND WHAT DID NOT
#   audit-copywriter ran eight checks, C1-C8. Three mechanize cleanly and are here:
#
#     C1 arc coverage         -> A1, A2 (plus A3, which keeps the ratchet honest)
#     C2 element headings     -> A4
#     C3 localized headings   -> A5, byte-exact, which is what catches an ASCII
#                                substitute silently replacing a diacritic
#
#   Five do not, and pretending otherwise would be worse than saying so:
#
#     C4 word targets         numeric ranges compared with a +/-50 tolerance AND a
#                             judgment about whether upstream has migrated from
#                             absolute counts to proportional percentages
#     C5 technique assignment "contradicts the matrix" is a reading, not a match
#     C6 section proportions  derived percentages within 5 points
#     C7 version alignment    informational only; reports commits for a human to weigh
#     C8 validation rules     asks whether a downstream rule would REJECT a valid
#                             upstream narrative — the most valuable check in the set
#                             and the least mechanizable
#
#   C4-C8 are not lost so much as unfunded. They need a reader. This suite pins the
#   structural half so that half stops depending on one.
#
# THE RATCHET, AND WHY THERE IS ONE
#   Five of the eleven upstream arcs have no downstream mirror at all: company-credo,
#   engagement-model, smarter-service, theme-thesis and trend-panorama appear in
#   neither the detection table nor the technique map. That is pre-existing drift,
#   found while writing this guard, and it is exactly the CRITICAL finding C1 was
#   built to report.
#
#   Closing it means authoring element rows, technique assignments and word targets
#   for five arcs — content work that needs the judgment audit-copywriter deliberately
#   refused to automate ("it never auto-fixes — the human decides"). Doing it inside a
#   plugin-absorption change would bury five arcs' worth of authored guidance in a
#   diff nobody would review as such.
#
#   So the gap is recorded here instead, in KNOWN_UNMIRRORED, where CI reads it. The
#   list is shrink-only: A3 fails if an entry names an arc that no longer exists
#   upstream, and fails if an entry has since been mirrored. Adding an arc to this
#   list to silence A1 or A2 is the wrong fix and inverts the guard's purpose.
#
# CASE LABEL SHAPE: "PASS: <case>" / "FAIL: <case>", matching
#   test-relocated-skill-hygiene.sh and test-wiki-namespace-sync.sh in this same
#   directory. The cogni-service mutation harness classifies a case green only on the
#   PASS: form and red on the matching FAIL: form, so a label printed only on failure
#   would leave every case unclassifiable as green. Case ids are A-prefixed and never
#   bare numerals, so the trailing summary line is not read as a case's red line.
#
# Contract: runs as `bash <path>` with no arguments, from any cwd, touches no network,
# needs nothing beyond bash + coreutils, and exits non-zero on failure.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"

# Upstream (the narrative skill) — the contract source.
ARC_DIR="$WS_ROOT/skills/narrative/references/story-arc"
LANG_TEMPLATES="$WS_ROOT/skills/narrative/references/language-templates.md"

# Downstream (the copywriter skill) — the mirror under audit. Overridable only so the
# executed negative case M1 can aim this same file at a mutant under mktemp -d. The
# override exists for that case, not as a configuration surface.
PRESERVATION="${ARC_PRESERVATION_PATH:-$WS_ROOT/skills/copywriter/references/09-preservation-modes/arc-preservation.md}"
TECHNIQUE_MAP="${ARC_TECHNIQUE_MAP_PATH:-$WS_ROOT/skills/copywriter/references/09-preservation-modes/arc-technique-map.md}"

# Arcs upstream defines that the downstream mirror does not carry. Shrink-only —
# see "THE RATCHET" above before touching this.
KNOWN_UNMIRRORED="company-credo engagement-model smarter-service theme-thesis trend-panorama"

# Arcs for which upstream defines non-EN/DE headings. Only these are in scope for the
# arc-mode translation path, so only these are checked by A5.
TRANSLATION_SCOPE="corporate-visions jtbd-portfolio"

failures=0
pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

in_list() {
  # in_list <needle> <space-separated haystack>
  case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

# Arc ids upstream declares: one directory per arc under story-arc/.
upstream_arcs() {
  find "$ARC_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort
}

# Arc ids the detection table names. The table is the block whose header row starts
# "| Arc ID | Element 1" — matched on that header rather than on line numbers, so
# inserting prose above it does not silently empty this list.
detection_arcs() {
  awk '
    /^\| *Arc ID *\| *Element 1/ { intable = 1; next }
    intable && /^\|[ -]*-/       { next }
    intable && /^\|/             { line = $0; sub(/^\| */, "", line); sub(/ *\|.*/, "", line); print line; next }
    intable                      { exit }
  ' "$PRESERVATION" | sort
}

# Arc ids the technique map carries a section for.
technique_arcs() {
  sed -n 's/^## Arc: *//p' "$TECHNIQUE_MAP" | sed 's/ *$//' | sort
}

trim() { printf '%s' "$1" | sed 's/^ *//; s/ *$//'; }

# ---------------------------------------------------------------------------
# Preflight — every input file must exist. Without this the parsers below return
# empty and every case passes vacuously.
# ---------------------------------------------------------------------------
missing_inputs=""
for f in "$LANG_TEMPLATES" "$PRESERVATION" "$TECHNIQUE_MAP"; do
  [ -f "$f" ] || missing_inputs="$missing_inputs $f"
done
[ -d "$ARC_DIR" ] || missing_inputs="$missing_inputs $ARC_DIR"

if [ -n "$missing_inputs" ]; then
  for m in $missing_inputs; do
    printf '%s\n' "  missing input: $m"
  done
  fail "A0 contract inputs are readable"
  printf '%s\n' "FAIL: $failures arc-reference-sync test(s) failed."
  exit 1
fi
pass "A0 contract inputs are readable"

UPSTREAM="$(upstream_arcs)"
DETECTION="$(detection_arcs)"
TECHNIQUE="$(technique_arcs)"

# Liveness floor. A parser that silently returns nothing must not report clean —
# that is the failure mode that makes a sync guard worse than no guard.
if [ -z "$UPSTREAM" ] || [ -z "$DETECTION" ] || [ -z "$TECHNIQUE" ]; then
  fail "A0b every parse returned at least one arc (upstream/detection/technique)"
else
  pass "A0b every parse returned at least one arc (upstream/detection/technique)"
fi

# ---------------------------------------------------------------------------
# A1 — every upstream arc appears in the detection table, or is a recorded gap.
# An arc absent from detection means the copywriter cannot enter arc-aware mode
# for it at all: it polishes the document as ordinary prose and the arc skeleton
# is unprotected. Nothing errors.
# ---------------------------------------------------------------------------
a1_missing=""
for arc in $UPSTREAM; do
  in_list "$arc" "$(echo "$DETECTION" | tr '\n' ' ')" && continue
  in_list "$arc" "$KNOWN_UNMIRRORED" && continue
  a1_missing="$a1_missing $arc"
done
if [ -n "$a1_missing" ]; then
  for a in $a1_missing; do
    printf '%s\n' "  upstream arc absent from the detection table: $a"
  done
  fail "A1 every upstream arc is in the arc-preservation detection table"
else
  pass "A1 every upstream arc is in the arc-preservation detection table"
fi

# ---------------------------------------------------------------------------
# A2 — every upstream arc has a technique-map section, or is a recorded gap.
# Detection without a technique section is the subtler failure: arc-aware mode
# engages, then finds no element-level guidance to apply.
# ---------------------------------------------------------------------------
a2_missing=""
for arc in $UPSTREAM; do
  in_list "$arc" "$(echo "$TECHNIQUE" | tr '\n' ' ')" && continue
  in_list "$arc" "$KNOWN_UNMIRRORED" && continue
  a2_missing="$a2_missing $arc"
done
if [ -n "$a2_missing" ]; then
  for a in $a2_missing; do
    printf '%s\n' "  upstream arc absent from the technique map: $a"
  done
  fail "A2 every upstream arc has an arc-technique-map section"
else
  pass "A2 every upstream arc has an arc-technique-map section"
fi

# ---------------------------------------------------------------------------
# A3 — the ratchet is shrink-only. Two ways an entry goes stale, and both make
# A1/A2 quietly weaker rather than louder, so both are failures here.
# ---------------------------------------------------------------------------
a3_bad=""
for arc in $KNOWN_UNMIRRORED; do
  if ! in_list "$arc" "$(echo "$UPSTREAM" | tr '\n' ' ')"; then
    printf '%s\n' "  recorded gap names an arc that is not upstream: $arc"
    a3_bad="yes"
    continue
  fi
  if in_list "$arc" "$(echo "$DETECTION" | tr '\n' ' ')" && in_list "$arc" "$(echo "$TECHNIQUE" | tr '\n' ' ')"; then
    printf '%s\n' "  recorded gap is now mirrored and must be removed from KNOWN_UNMIRRORED: $arc"
    a3_bad="yes"
  fi
done
if [ -n "$a3_bad" ]; then
  fail "A3 every KNOWN_UNMIRRORED entry is still upstream and still unmirrored"
else
  pass "A3 every KNOWN_UNMIRRORED entry is still upstream and still unmirrored"
fi

# ---------------------------------------------------------------------------
# A4 — element short names in the detection table resolve upstream.
# The detection table carries short names ("Why Change") while the arc definition
# carries full headings ("Why Change: Unconsidered Needs"), so this is a prefix
# containment check, not equality. A renamed element upstream leaves the detection
# table matching a heading that no longer exists.
# ---------------------------------------------------------------------------
a4_bad=""
a4_checked=0
while IFS='|' read -r _lead arc e1 e2 e3 e4 _rest; do
  a="$(trim "$arc")"
  [ -n "$a" ] || continue
  [ -f "$ARC_DIR/$a/arc-definition.md" ] || continue
  for e in "$e1" "$e2" "$e3" "$e4"; do
    el="$(trim "$e")"
    [ -n "$el" ] || continue
    a4_checked=$((a4_checked + 1))
    if ! grep -Fq "$el" "$ARC_DIR/$a/arc-definition.md"; then
      printf '%s\n' "  detection element not found in the upstream arc definition: $a :: $el"
      a4_bad="yes"
    fi
  done
done <<EOF
$(awk '
  /^\| *Arc ID *\| *Element 1/ { intable = 1; next }
  intable && /^\|[ -]*-/       { next }
  intable && /^\|/             { print; next }
  intable                      { exit }
' "$PRESERVATION")
EOF
if [ "$a4_checked" -eq 0 ]; then
  fail "A4 detection element names resolve in the upstream arc definitions (parsed zero elements)"
elif [ -n "$a4_bad" ]; then
  fail "A4 detection element names resolve in the upstream arc definitions"
else
  pass "A4 detection element names resolve in the upstream arc definitions ($a4_checked elements)"
fi

# ---------------------------------------------------------------------------
# A5 — localized headings match upstream byte-for-byte.
#
# Byte-exact is the whole point. The repo mandates real characters per language and
# never ASCII substitutes — DE ae/oe/ue/ss for ä/ö/ü/ß, FR e for é, PL l for ł. A
# substitution keeps the heading readable and breaks the positional substitution the
# copywriter performs in its translate-then-polish pass, because the string it writes
# no longer equals the string the narrative skill emits.
# ---------------------------------------------------------------------------
a5_bad=""
a5_checked=0
for arc in $TRANSLATION_SCOPE; do
  while IFS='|' read -r _lead rowarc _num en de fr it pl nl es _rest; do
    [ "$(trim "$rowarc")" = "$arc" ] || continue
    for cell in "$en" "$de" "$fr" "$it" "$pl" "$nl" "$es"; do
      c="$(trim "$cell")"
      [ -n "$c" ] || continue
      a5_checked=$((a5_checked + 1))
      if ! grep -Fq "$c" "$LANG_TEMPLATES"; then
        printf '%s\n' "  localized heading not found in language-templates.md: $arc :: $c"
        a5_bad="yes"
      fi
    done
  done < "$PRESERVATION"
done
if [ "$a5_checked" -eq 0 ]; then
  fail "A5 localized headings match language-templates.md byte-for-byte (parsed zero headings)"
elif [ -n "$a5_bad" ]; then
  fail "A5 localized headings match language-templates.md byte-for-byte"
else
  pass "A5 localized headings match language-templates.md byte-for-byte ($a5_checked headings)"
fi

# ---------------------------------------------------------------------------
# M1 — executed negative case.
#
# A guard that has never been observed failing is a guard nobody knows still works.
# M1 copies the detection table into this run's own mktemp -d, deletes a mirrored
# arc's row, re-runs this same file against the mutant, and requires a non-zero exit.
# It never writes to a tracked path.
#
# The mutated arc is read from the live detection table rather than hard-coded, so
# renaming an arc upstream cannot leave M1 cutting a row that is no longer there and
# then reporting the guard vacuous.
# ---------------------------------------------------------------------------
if [ "${ARC_SYNC_MUTANT:-}" = "1" ]; then
  # Inner run under M1 — do not recurse.
  if [ "$failures" -ne 0 ]; then
    printf '%s\n' "FAIL: $failures arc-reference-sync test(s) failed."
    exit 1
  fi
  exit 0
fi

MUT_ARC="$(echo "$DETECTION" | head -1)"
if [ -z "$MUT_ARC" ]; then
  fail "M1 no mirrored arc available to mutate — the detection table parsed empty"
else
  TMPROOT="$(mktemp -d)"
  trap 'rm -rf "$TMPROOT"' EXIT
  grep -v "^| *$MUT_ARC *|" "$PRESERVATION" > "$TMPROOT/arc-preservation.md"
  mutant_out="$(ARC_SYNC_MUTANT=1 ARC_PRESERVATION_PATH="$TMPROOT/arc-preservation.md" bash "$HERE/$(basename "$0")" 2>&1)"
  mutant_code=$?
  if [ "$mutant_code" -eq 0 ]; then
    printf '%s\n' "  the mutant dropped every '$MUT_ARC' row and the guard still passed"
    printf '%s\n' "$mutant_out" | sed 's/^/    /'
    fail "M1 dropping a mirrored arc from the detection table turns this guard red"
  else
    pass "M1 dropping a mirrored arc from the detection table turns this guard red"
  fi
fi

if [ "$failures" -ne 0 ]; then
  printf '%s\n' "FAIL: $failures arc-reference-sync test(s) failed."
  exit 1
fi

printf '%s\n' "OK: arc-reference-sync checks passed."
exit 0
