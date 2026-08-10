#!/usr/bin/env bash
# Guard: cogni-visual's arc taxonomy must stay in sync with cogni-narrative's arcs.
#
# WHAT THIS PINS
#   The `arc_id` set in the mapping table of cogni-visual/libraries/arc-taxonomy.md
#   must equal the set of arc directories under
#   cogni-narrative/skills/narrative/references/story-arc/.
#
# WHY A TEST AND NOT MORE PROSE
#   Divergence degrades SILENTLY. An `arc_id` absent from the mapping table hits the
#   documented `**Fallback:**` in arc-taxonomy.md and falls back to auto-detection from
#   narrative content — nothing errors, nothing warns. The only symptom is a narrative
#   getting a less-appropriate visual decomposition than it asked for. The two surfaces
#   have drifted apart three separate times; each recurrence was found by a human reading
#   prose and fixed with more prose. This suite makes the seam observable instead.
#
# STRICTNESS LEVEL: (a) HARD ASSERT, BOTH DIRECTIONS — chosen deliberately.
#   The issue that requested this guard laid out three options: (a) hard assert, (b) assert
#   only the table-names-a-missing-arc direction and warn on the missing-row direction, and
#   (c) advisory reporting with no failure. (a) is chosen because the binding requirement is
#   that reintroducing a missing mapping row produce a NON-ZERO EXIT — and that omission is
#   precisely the missing-row direction, which (b) downgrades to a warning and (c) never
#   fails on at all. Neither weaker option can satisfy it.
#
#   The cost is real and accepted: this couples two plugins' CI. A cogni-narrative change
#   that adds a twelfth arc will turn *cogni-visual's* suite red until the taxonomy mirror is
#   updated — a failure attributed to a plugin the author may not have touched. That is the
#   intended trade: adding an arc without a visual mapping is an incomplete change, and a
#   loud failure in the wrong place beats a silent one in the right place.
#
# CASE LABEL SHAPE: `ok: <id>` / `FAIL: <id>` — NOT the `OK   ` / `FAIL ` shape used by
#   three older suites in this repo. The shared mutation harness classifies a case by reading
#   OUTPUT LINES rather than the exit code, matching `FAIL: <case>` for red and
#   `ok: <case>` / `PASS: <case>` for green. The no-colon shape matches neither pattern, so a
#   suite wearing it cannot be driven by the harness and its mutation recipe is unrunnable as
#   written.
#
#   The colon form is also the repo majority, not a deviation from house style: of the suites
#   carrying a pass()/fail() helper, nineteen already emit `FAIL: <case>` and three emit the
#   no-colon shape. This suite is born compatible rather than needing to be migrated later.
#
#   Two label rules are load-bearing, not style:
#     - a case id is a single token followed by a space or end-of-line, never `S2:` or `S2 -`;
#       a trailing colon reads as case_not_found to both the harness and the handoff preflight.
#     - the final summary line must NOT begin with `FAIL:`, or it would itself be parsed as a
#       case verdict. It begins with `RESULT:`.
#
# THE ARC COUNT IS NEVER PINNED. Both sets are derived at run time. Hardcoding the current
#   count would reintroduce the very stale-count failure class this guard exists to prevent.
#
# BOTH PARSES ARE SECTION-SCOPED, and that is load-bearing. An unscoped `^### ` sweep over
#   arc-taxonomy.md matches four extra headings beyond the arc sections — including an Example
#   heading that embeds an arc id in backticks, which would fabricate a phantom duplicate and
#   turn the duplicate check red on a clean file. Likewise the mapping-table parse is bounded to
#   its own section so the Example table's `|`-leading rows are not read as arc rows.
#
# THE NEGATIVE CASE IS SELF-HOSTED (M1), not merely recorded in prose. A guard that only ever
#   sees a healthy tree is indistinguishable from a guard that cannot fail, and a mutation
#   recipe written into a pull-request description is not replayable by anyone reading the repo
#   later. M1 therefore copies the taxonomy into this run's own mktemp -d, deletes one mapping
#   row FROM THE COPY, re-invokes this same file against the mutant, and asserts the child both
#   exits non-zero and reports S2 red by name. It runs on every CI sweep, and the tracked
#   arc-taxonomy.md is never written to — a negative case that edits its own repository is a
#   dirty-tree hazard, not a test.
#
# stdlib-only: bash + coreutils + python3. No network, no credentials, no pip dependencies.
# Writes only under its own mktemp -d. Self-locates from $0, so it is cwd-independent — the
# mutation harness runs it with cwd set to the tree under test, not to this directory.

set -u

# One collation authority for every ordered comparison in this file. `comm` requires both inputs
# ordered the same way and reports a WRONG difference set — silently, exit 0 — when they are not.
# Its inputs come from two different sorters: python's byte-wise sorted() and coreutils sort,
# whose order is locale-dependent. Under a UTF-8 locale, sort demotes punctuation to a secondary
# level, so a future arc-id pair like `smart-service` / `smartservice` would order differently in
# the two files and the comparison would quietly return nonsense. Pinning C makes both agree.
export LC_ALL=C

HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$PLUGIN_DIR/.." && pwd)"

# Both inputs default to the real tracked paths and are overridable only so M1 can aim this
# same file at a mutant under $TMPROOT. The override exists for the negative case, not as a
# configuration surface — a normal run, and every CI run, resolves both defaults.
TAXONOMY="${ARC_TAXONOMY_PATH:-$PLUGIN_DIR/libraries/arc-taxonomy.md}"
ARC_DIR="${ARC_STORY_ARC_DIR:-$REPO_ROOT/cogni-narrative/skills/narrative/references/story-arc}"

# The five valid visual arc types. arc-taxonomy.md does not declare this set itself — it is
# stated by the consuming surfaces (cogni-visual/skills/story-to-slides, story-to-web,
# story-to-storyboard, story-to-infographic, render-html-slides), which document `arc_type` as
# one of these values. Mirrored here because there is no machine-readable source to read.
VALID_ARC_TYPES="why-change problem-solution journey argument report"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { echo "ok: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

# Every case downstream of the non-vacuity guards, declared once. Cases that cannot be evaluated
# must still emit their own id: a case id that is simply absent from the output is
# indistinguishable, to the harness, from a typo'd --case — so an unevaluated case is reported as
# a failure under its own name rather than skipped silently.
#
# MAINTENANCE: adding a case below the V-guards means adding its id here too. This list is the
# single declaration bail_out reads; a case missing from it vanishes from the bail output.
DOWNSTREAM_CASES="S1 S2 T1 E1 D1 M1"

# Deliberately not prefixed `FAIL:` — that shape is reserved for per-case verdicts, and a
# summary wearing it would be misread as a case named by its first token.
finish() {
  echo ""
  if [ "$failures" -gt 0 ]; then
    echo "RESULT: $failures arc-taxonomy sync case(s) failed."
    exit 1
  fi
  echo "RESULT: all arc-taxonomy sync cases passed."
  exit 0
}

# Abandon the run when an input is missing or unparseable, reporting every downstream case
# under its own id first.
bail_out() {
  for case_id in $DOWNSTREAM_CASES; do
    fail "$case_id not evaluated — non-vacuity guard failed"
  done
  finish
}

# ---------------------------------------------------------------- non-vacuity guards (V1-V4)
# Without these, a renamed or moved input path yields two empty sets, which compare equal, and
# the suite reports green forever. An empty-vs-empty pass is the same silent degradation this
# guard was written to catch, one level up.

vacuous=0

if [ -f "$TAXONOMY" ]; then
  pass "V1 arc-taxonomy.md is present at $TAXONOMY"
else
  fail "V1 arc-taxonomy.md not found at $TAXONOMY"
  vacuous=1
fi

if [ -d "$ARC_DIR" ]; then
  pass "V2 story-arc directory is present at $ARC_DIR"
else
  fail "V2 story-arc directory not found at $ARC_DIR"
  vacuous=1
fi

if [ "$vacuous" -ne 0 ]; then
  bail_out
fi

# Extract both machine-readable views of the taxonomy in one pass. Emits, into $TMPROOT:
#   rows.tsv        arc_id<TAB>arc_type, one per mapping-table data row, document order
#   map_ids_all.txt every mapping-table arc_id, sorted, duplicates retained (feeds D1)
#   map_ids.txt     the same set, sorted and deduplicated (feeds the set comparisons)
#   sections.txt    every `### <name>` heading inside the Arc Element Names section, sorted
if ! python3 - "$TAXONOMY" "$TMPROOT" <<'PY'
import os
import sys

taxonomy_path, outdir = sys.argv[1], sys.argv[2]

with open(taxonomy_path, encoding="utf-8") as handle:
    lines = handle.read().splitlines()

MAPPING_HEADING = "## Arc ID to Visual Arc Type Mapping"
ELEMENTS_HEADING = "## Arc Element Names"


def section_body(heading):
    """Lines between `heading` and the next H2. Bounding the scan is the whole point:
    an unscoped sweep picks up unrelated tables and headings elsewhere in the file."""
    start = None
    for index, line in enumerate(lines):
        if line.strip() == heading:
            start = index + 1
            break
    if start is None:
        return []
    body = []
    for line in lines[start:]:
        if line.startswith("## "):  # H3 (`### `) does not match, so arc sections survive
            break
        body.append(line)
    return body


rows = []
for line in section_body(MAPPING_HEADING):
    stripped = line.strip()
    if not stripped.startswith("|"):
        continue
    cells = [cell.replace("`", "").strip() for cell in stripped.strip("|").split("|")]
    if len(cells) < 2:
        continue
    # The `|---|---|` separator row: every cell is made only of dashes and colons.
    if all(cell and set(cell) <= set("-:") for cell in cells):
        continue
    arc_id, arc_type = cells[0], cells[1]
    if not arc_id:
        continue
    # The header row names the column rather than an arc.
    if "arc_id" in arc_id:
        continue
    rows.append((arc_id, arc_type))

sections = [
    line[4:].replace("`", "").strip()
    for line in section_body(ELEMENTS_HEADING)
    if line.startswith("### ")
]


def write(name, values):
    with open(os.path.join(outdir, name), "w", encoding="utf-8") as handle:
        for value in values:
            handle.write(value + "\n")


write("rows.tsv", ["%s\t%s" % row for row in rows])
write("map_ids_all.txt", sorted(arc_id for arc_id, _ in rows))
write("map_ids.txt", sorted({arc_id for arc_id, _ in rows}))
write("sections.txt", sorted(sections))
PY
then
  fail "V3 could not parse the mapping table out of arc-taxonomy.md"
  bail_out
fi

# `sort` here agrees with python's byte-wise sorted() above because LC_ALL=C is exported at the
# top of this file. See that comment — the agreement is what makes every `comm` below sound.
find "$ARC_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort > "$TMPROOT/dir_ids.txt"

map_count=$(wc -l < "$TMPROOT/map_ids.txt" | tr -d ' ')
dir_count=$(wc -l < "$TMPROOT/dir_ids.txt" | tr -d ' ')

if [ "$map_count" -gt 0 ]; then
  pass "V3 mapping table yielded $map_count arc_id(s)"
else
  fail "V3 mapping table yielded no arc_id rows — the section heading or table shape changed"
  vacuous=1
fi

if [ "$dir_count" -gt 0 ]; then
  pass "V4 story-arc directory yielded $dir_count arc directory/ies"
else
  fail "V4 story-arc directory contains no arc directories"
  vacuous=1
fi

if [ "$vacuous" -ne 0 ]; then
  bail_out
fi

# ------------------------------------------------------------- set equality, both directions

orphan_rows=$(comm -23 "$TMPROOT/map_ids.txt" "$TMPROOT/dir_ids.txt" | tr '\n' ' ' | sed 's/ *$//')
if [ -z "$orphan_rows" ]; then
  pass "S1 every mapping-table arc_id has a story-arc directory"
else
  fail "S1 mapping-table arc_id(s) with no story-arc directory: $orphan_rows"
fi

# S2 is the direction a dropped mapping row turns red: the arc directory still exists, but
# nothing maps it, so it silently falls through to auto-detection.
unmapped_dirs=$(comm -13 "$TMPROOT/map_ids.txt" "$TMPROOT/dir_ids.txt" | tr '\n' ' ' | sed 's/ *$//')
if [ -z "$unmapped_dirs" ]; then
  pass "S2 every story-arc directory has a mapping-table row"
else
  fail "S2 story-arc directory/ies with no mapping-table row: $unmapped_dirs"
fi

# ------------------------------------------------------------------------ arc_type validity

bad_types=""
while IFS="$(printf '\t')" read -r arc_id arc_type; do
  [ -n "$arc_id" ] || continue
  valid=0
  for candidate in $VALID_ARC_TYPES; do
    if [ "$arc_type" = "$candidate" ]; then
      valid=1
      break
    fi
  done
  if [ "$valid" -eq 0 ]; then
    bad_types="$bad_types $arc_id=$arc_type"
  fi
done < "$TMPROOT/rows.tsv"
bad_types="${bad_types# }"

if [ -z "$bad_types" ]; then
  pass "T1 every mapping-table arc_type is one of: $VALID_ARC_TYPES"
else
  fail "T1 invalid arc_type value(s): $bad_types (valid: $VALID_ARC_TYPES)"
fi

# ------------------------------------------------------- element-section coverage, duplicates
# The half-wired case: arc_type resolves from the mapping table, but the element labels have no
# section to read, so they fall back to generic names. Green mapping, degraded output.

missing_sections=$(comm -23 "$TMPROOT/map_ids.txt" "$TMPROOT/sections.txt" | tr '\n' ' ' | sed 's/ *$//')
if [ -z "$missing_sections" ]; then
  pass "E1 every mapping-table arc_id has a section under Arc Element Names"
else
  fail "E1 mapping-table arc_id(s) with no element section: $missing_sections"
fi

duplicate_ids=$(uniq -d < "$TMPROOT/map_ids_all.txt" | tr '\n' ' ' | sed 's/ *$//')
if [ -z "$duplicate_ids" ]; then
  pass "D1 no arc_id appears more than once in the mapping table"
else
  fail "D1 duplicate mapping-table arc_id(s): $duplicate_ids"
fi

# ------------------------------------------------------------------ executed negative case (M1)
# Proves this guard can actually go red, in-repo and on every sweep, without ever writing to the
# tracked taxonomy. Deletes one mapping row from a COPY, runs this same file against the mutant,
# and requires the child to report S2 red by name. Asserting on the child's exit code alone would
# be too weak: a non-zero exit cannot distinguish S2 going red from any other case going red.

if [ "${ARC_TAXONOMY_SYNC_MUTANT:-0}" = "1" ]; then
  # This run IS the mutant child. Recursing here would not terminate.
  finish
fi

# The victim row. `smarter-service` is the omission this guard was written for, so it is
# preferred when present — but it is looked up in the parsed set rather than assumed, and any
# arc_id serves equally, so removing or renaming that arc cannot stale this case out.
victim=$(grep -x 'smarter-service' "$TMPROOT/map_ids.txt" || head -n 1 "$TMPROOT/map_ids.txt")

if [ -z "$victim" ]; then
  fail "M1 no arc_id available to mutate — the mapping table parsed empty"
  finish
fi

# Section-scoped deletion, for the same reason the main parse is section-scoped: the arc's own
# element table further down the file also has rows, and an unscoped match would cut one of those
# instead. Exits non-zero unless at least one row was removed, so a silently-ineffective mutation
# is never mistaken for a passing negative case. The condition is "the victim is now unmapped",
# not "exactly one line was cut": on a file that already carries a duplicate row — the state D1
# exists to catch — cutting only one would leave the arc still mapped, S2 still green, and M1
# would then wrongly report the guard vacuous. Removing every matching row keeps M1 diagnosing
# its own property rather than going red in sympathy with D1.
if python3 - "$TAXONOMY" "$TMPROOT/mutant.md" "$victim" <<'PY'
import sys

source_path, mutant_path, victim = sys.argv[1], sys.argv[2], sys.argv[3]

with open(source_path, encoding="utf-8") as handle:
    lines = handle.read().splitlines(keepends=True)

MAPPING_HEADING = "## Arc ID to Visual Arc Type Mapping"

kept, removed, in_section = [], 0, False
for line in lines:
    stripped = line.strip()
    if stripped == MAPPING_HEADING:
        in_section = True
    elif in_section and stripped.startswith("## "):
        in_section = False
    if in_section and stripped.startswith("|"):
        first_cell = stripped.strip("|").split("|")[0].replace("`", "").strip()
        if first_cell == victim:
            removed += 1
            continue
    kept.append(line)

with open(mutant_path, "w", encoding="utf-8") as handle:
    handle.writelines(kept)

sys.exit(0 if removed >= 1 else 1)
PY
then
  mutant_out=$(ARC_TAXONOMY_SYNC_MUTANT=1 ARC_TAXONOMY_PATH="$TMPROOT/mutant.md" \
    bash "$HERE/$(basename "$0")" 2>&1)
  mutant_rc=$?

  # The S2 verdict line the child emitted, if any. Matching the case id and the victim name
  # separately keeps the assertion readable and avoids anchoring inside a wildcard.
  mutant_s2=$(printf '%s\n' "$mutant_out" | grep '^FAIL: S2 ' || true)

  if [ "$mutant_rc" -eq 0 ]; then
    fail "M1 dropping the '$victim' mapping row left the suite GREEN — the guard is vacuous"
  elif [ -n "$mutant_s2" ] && printf '%s\n' "$mutant_s2" | grep -qE "(^| )$victim( |$)"; then
    pass "M1 dropping the '$victim' mapping row turns S2 red (child exit $mutant_rc)"
  else
    fail "M1 mutant run exited $mutant_rc, but not via S2 naming '$victim' — got: $(printf '%s' "$mutant_out" | grep '^FAIL:' | tr '\n' ';')"
  fi
else
  fail "M1 could not remove any '$victim' mapping row from the copy"
fi

# ------------------------------------------------------------------------------------ summary

finish
