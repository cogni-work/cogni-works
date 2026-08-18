#!/usr/bin/env bash
# Regression test: the Phase 2 research-manifest template in
# cogni-trends/skills/trend-research/SKILL.md must declare every `files.sections`
# dimension path with a `.md` extension, and must keep the sibling
# `files.enriched_trends` / `files.claims` maps on `.json`. Pins the contract for
# issue #1389.
#
# Why this class needs a guard at all. The manifest is advertised as the single
# source of truth downstream steps use to discover per-dimension artefact paths,
# and it restates paths that are actually produced elsewhere — the writer agent
# emits `section-<dimension>.md` unconditionally. Nothing reconciles the two, so a
# wrong extension in the template is invisible: no script is wrong, nothing
# raises, and a consumer that resolved the key would simply get a path that is
# never written. In the case that prompted this suite, one of the four dimensions
# carried a `.json` extension while the other three, the authoritative schema at
# skills/trend-research/references/research-manifest-schema.md, and SKILL.md's own
# prose all said `.md`.
#
# What makes it hard to see by eye, and why a naive guard misses it: the same
# `files` block holds three sub-maps keyed by the same four dimensions, and two of
# them (`enriched_trends`, `claims`) are legitimately `.json`. A `.json` value in
# that block is therefore not intrinsically wrong — only wrong under `sections`.
# That is also why case A7 exists: a plugin-wide `.json` -> `.md` sweep would
# "fix" this bug and silently corrupt eight correct paths, so the suite has to
# fail on that too.
#
# A bare grep for the single wrong path would be worthless here. It passes the
# moment that one token is corrected and can never catch any of the other three
# dimensions drifting the same way later — which is precisely the "so the four
# cannot drift apart again" property this suite owes the issue. Every dimension is
# therefore asserted individually, off a parsed map rather than a text match.
#
# Case-label shape is "PASS: <label>" / "FAIL: <label>" — matching
# test-agent-frontmatter-names.sh, and the shape every discovered suite in this
# repo now carries, test-project-status.sh and test-stale-detection.sh included.
# It is what it is because the cogni-service mutation harness
# classifies a case GREEN only on ^[[:space:]]*(ok|PASS):[[:space:]]+<case> and
# RED on the matching FAIL: form. Neither "OK   " nor "OK:" is in that vocabulary.
# The detail after a case id is separated by a SPACE and never a colon —
# "FAIL: A2: detail" also reports case_not_found on a genuinely red case. Case ids
# are A-prefixed and never bare numerals, which keeps the final summary line
# ("FAIL: <n> research-manifest-sections test(s) failed.") from being read as a
# case's RED line — a hazard the colon form creates and every suite must answer.
#
# This file deliberately never spells the pre-fix section path as one contiguous
# token. The repo-wide falsifier for issue #1389 is an unfiltered scan under
# cogni-trends/ for that token expecting zero hits, so naming it here — in a
# comment, a fixture, or the mutation recipe below — would make this suite's own
# source the hit, and would falsify the acceptance criterion it exists to defend.
# Case A6 builds the token from parts at runtime for the same reason. Note that
# the alternative, excluding tests/ from the sweep, was rejected twice over: it
# would weaken the plugin-wide scan, and an inverted substring filter such as
# `| grep -v tests` is unsafe here regardless, because every in-scope path already
# begins with "cogni-trends/".
#
# bash-3.2 portable (stock macOS /bin/bash is 3.2.57): no declare -A / typeset -A,
# no mapfile / readarray, no ${var^^} / ${var,,}.
#
# stdlib-only: bash + coreutils + awk. No python3, no pip deps, no network. Writes
# only under its own mktemp -d.
#
# Usage: bash cogni-trends/tests/test-research-manifest-sections.sh
# Exits non-zero on any assertion failure.
#
# Mutation recipe (proves case A2 is load-bearing):
#   bash ~/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh \
#     --root . \
#     --file cogni-trends/skills/trend-research/SKILL.md \
#     --expr 's|(section-externe-effekte)\.md|${1}.json|' \
#     --test 'bash cogni-trends/tests/test-research-manifest-sections.sh' \
#     --case A2
# The expression is written with a capture group so this file never spells the
# forbidden token (see the sweep note above); the replacement text does not
# contain the matched literal, so the mutated tree genuinely reverts the fix
# instead of staying green. After the fix that literal occurs exactly once in
# SKILL.md, so the substitution is unambiguous.

set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SKILL_MD="$PLUGIN_DIR/skills/trend-research/SKILL.md"
# The authoritative copy of the same manifest template. Read-only here: case A7
# pins its sibling maps too, because the over-broad fix this suite guards against
# would corrupt this file just as readily as SKILL.md.
SCHEMA_MD="$PLUGIN_DIR/skills/trend-research/references/research-manifest-schema.md"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

DIMENSIONS="externe-effekte digitale-wertetreiber neue-horizonte digitales-fundament"

# Held apart from the "section-<dimension>" stem so the contiguous pre-fix token
# never appears in this file. Concatenated only at runtime, in case A6 and in the
# fixture writer.
JSON_EXT=".json"

COUNT_FILE="$TMPROOT/parsed"

# ---------------------------------------------------------------------------
# The matcher. The fixture cases (A8, A9) and every real-tree case drive this
# same function — it is never reimplemented in a case body, so a case pointed at
# a broken matcher turns red rather than silently passing.
#
# extract_map <file> <map-key> <count-out-file>
#   stdout: one "dimension<TAB>path" line per entry in that sub-map
#   <count-out-file>: number of entries actually parsed (the liveness signal)
#
# Parses the first `"<map-key>": {` block only. Splitting on the quote character
# tolerates arbitrary whitespace after the key colon, which matters because the
# schema reference aligns its values with runs of spaces while SKILL.md uses one.
# ---------------------------------------------------------------------------
extract_map() {
  local em_file em_key em_count
  em_file="$1"
  em_key="$2"
  em_count="$3"

  # A missing file must read as zero entries, not as an awk error, so the
  # vacuity floor stays meaningful instead of the case dying early.
  if [ ! -f "$em_file" ]; then
    printf '0' > "$em_count"
    return 0
  fi

  awk -F'"' -v key="$em_key" -v countfile="$em_count" '
    !seen && !inmap && index($0, "\"" key "\":") && index($0, "{") { inmap = 1; next }
    inmap && $0 ~ /^[[:space:]]*\}/ { inmap = 0; seen = 1; next }
    inmap && NF >= 5 { printf "%s\t%s\n", $2, $4; n++ }
    END { printf "%s", n + 0 > countfile }
  ' "$em_file"
}

# map_value <dump> <dimension> -> the path for that dimension, empty if absent
map_value() {
  printf '%s\n' "$1" | awk -F'\t' -v d="$2" '$1 == d { print $2 }'
}

# write_bad_fixture <path>
# Builds a minimal manifest excerpt carrying the very defect this suite guards
# against, for the matcher-liveness case. The extension is concatenated from the
# file-scope JSON_EXT at runtime — that, not the call signature, is what keeps
# the contiguous token out of this file's source.
write_bad_fixture() {
  local wf_path
  wf_path="$1"
  {
    echo '```json'
    echo '{'
    echo '  "files": {'
    echo '    "sections": {'
    echo "      \"externe-effekte\": \".logs/section-externe-effekte${JSON_EXT}\","
    echo '      "digitale-wertetreiber": ".logs/section-digitale-wertetreiber.md",'
    echo '      "neue-horizonte": ".logs/section-neue-horizonte.md",'
    echo '      "digitales-fundament": ".logs/section-digitales-fundament.md"'
    echo '    }'
    echo '  }'
    echo '}'
    echo '```'
  } > "$wf_path"
}

SECTIONS_DUMP="$(extract_map "$SKILL_MD" "sections" "$COUNT_FILE")"
SECTIONS_COUNT="$(cat "$COUNT_FILE")"

# --- A1: the real files.sections map parsed, with exactly the four dimensions --
# The vacuity floor for every assertion below: without it, a matcher that stopped
# matching would leave A2-A5 passing over an empty dump. A9 proves the counter can
# genuinely read zero, which is what gives this non-zero assertion its meaning.
A1_MISSING=""
for d in $DIMENSIONS; do
  if [ -z "$(map_value "$SECTIONS_DUMP" "$d")" ]; then
    A1_MISSING="$A1_MISSING $d"
  fi
done
if [ "$SECTIONS_COUNT" = "4" ] && [ -z "$A1_MISSING" ]; then
  pass "A1 files.sections parsed with exactly the 4 expected dimensions"
else
  fail "A1 files.sections should parse 4 known dimensions, got count $SECTIONS_COUNT missing:${A1_MISSING:- none}"
fi

# --- A2-A5: every dimension's section path uses the .md form ------------------
# One case per dimension, so a single drifted entry names itself instead of
# hiding behind an aggregate. A2 is the case the mutation recipe targets.
assert_md() {
  local am_id am_dim am_val
  am_id="$1"
  am_dim="$2"
  am_val="$(map_value "$SECTIONS_DUMP" "$am_dim")"
  if [ -z "$am_val" ]; then
    fail "$am_id $am_dim is missing from the files.sections map"
    return
  fi
  case "$am_val" in
    *.md) pass "$am_id $am_dim section path uses the .md form ($am_val)" ;;
    *)    fail "$am_id $am_dim section path is $am_val, expected a .md path" ;;
  esac
}

assert_md A2 externe-effekte
assert_md A3 digitale-wertetreiber
assert_md A4 neue-horizonte
assert_md A5 digitales-fundament

# --- A6: no section-<dimension> path anywhere under the plugin uses .json ------
# The plugin-wide falsifier. Built from parts at runtime; see the header note on
# why this is construction rather than an exclusion filter. -F keeps the dot a
# literal dot rather than a regex wildcard.
A6_HITS=""
for d in $DIMENSIONS; do
  needle="section-${d}${JSON_EXT}"
  hit="$(grep -rIlF -- "$needle" "$PLUGIN_DIR" 2>/dev/null || true)"
  if [ -n "$hit" ]; then
    A6_HITS="$A6_HITS $(printf '%s' "$hit" | tr '\n' ' ')"
  fi
done
if [ -z "$A6_HITS" ]; then
  pass "A6 no section-<dimension> path under the plugin carries the json extension"
else
  fail "A6 a section-<dimension> path still carries the json extension in:$A6_HITS"
fi

# --- A7: the sibling maps stay on .json, in BOTH copies of the template --------
# Guards the over-broad fix. A plugin-wide .json -> .md sweep would satisfy
# A1-A6 while corrupting these correct paths, so it has to fail here.
#
# Both documents are checked, not just SKILL.md. The sweep this case exists to
# catch does not respect document boundaries, and the template is duplicated —
# checking only one copy would advertise a protection the case does not provide,
# and would leave the schema reference's eight sibling paths corruptible with no
# signal. Reading that file here is not editing it.
A7_BAD=""
A7_COUNTS=""
for f in "$SKILL_MD" "$SCHEMA_MD"; do
  f_label="${f##*/}"
  for m in enriched_trends claims; do
    m_dump="$(extract_map "$f" "$m" "$COUNT_FILE")"
    m_count="$(cat "$COUNT_FILE")"
    A7_COUNTS="$A7_COUNTS $f_label:$m=$m_count"
    if [ "$m_count" != "4" ]; then
      A7_BAD="$A7_BAD $f_label:$m(parsed $m_count entries, expected 4)"
      continue
    fi
    for d in $DIMENSIONS; do
      v="$(map_value "$m_dump" "$d")"
      case "$v" in
        *"$JSON_EXT") ;;
        *) A7_BAD="$A7_BAD $f_label:$m.$d=$v" ;;
      esac
    done
  done
done
if [ -z "$A7_BAD" ]; then
  pass "A7 sibling enriched_trends and claims maps still use the json extension ($A7_COUNTS)"
else
  fail "A7 sibling map entries should keep the json extension, offenders:$A7_BAD"
fi

# --- A8: the matcher actually catches a bad extension -------------------------
# Liveness for the .md assertion itself. If this cannot fire, A2's green above is
# worthless — it would only mean the matcher never looks.
BAD_FIXTURE="$TMPROOT/bad-manifest.md"
write_bad_fixture "$BAD_FIXTURE"
A8_DUMP="$(extract_map "$BAD_FIXTURE" "sections" "$COUNT_FILE")"
A8_COUNT="$(cat "$COUNT_FILE")"
A8_VAL="$(map_value "$A8_DUMP" "externe-effekte")"
case "${A8_VAL:-}" in
  *.md) fail "A8 fixture with a bad extension was read as $A8_VAL, matcher cannot detect the defect" ;;
  "")   fail "A8 fixture parse produced no externe-effekte entry (count $A8_COUNT)" ;;
  *)    pass "A8 fixture with a bad extension is detected ($A8_VAL, scanned $A8_COUNT)" ;;
esac

# --- A9: a file with no sections map parses zero entries (vacuity floor) -------
# Proves the liveness counter can read zero, which is what makes A1's "exactly 4"
# a real assertion rather than a tautology.
EMPTY_FIXTURE="$TMPROOT/no-sections.md"
printf '%s\n' 'No manifest here.' > "$EMPTY_FIXTURE"
A9_DUMP="$(extract_map "$EMPTY_FIXTURE" "sections" "$COUNT_FILE")"
A9_COUNT="$(cat "$COUNT_FILE")"
if [ -z "$A9_DUMP" ] && [ "$A9_COUNT" = "0" ]; then
  pass "A9 a file with no sections map parses 0 entries (vacuity floor is real)"
else
  fail "A9 a file with no sections map should parse 0 entries, got count $A9_COUNT dump ${A9_DUMP:-<none>}"
fi

if [ $failures -gt 0 ]; then
  echo
  echo "FAIL: $failures research-manifest-sections test(s) failed." >&2
  exit 1
fi
echo
echo "All research-manifest-sections assertions passed."
