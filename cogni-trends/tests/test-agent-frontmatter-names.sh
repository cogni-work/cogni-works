#!/usr/bin/env bash
# Regression test: every cogni-trends/agents/*.md must declare a frontmatter
# `name:` equal to its own filename stem. Pins the contract for issue #1388.
#
# Why this class needs a guard at all. The host registers a plugin agent under
# its frontmatter `name`, NOT under its filename. When the two disagree, the
# agent is addressable only by the declared name, while every dispatch site and
# doc in the repo naturally reaches for the filename form — so the dispatch
# resolves to nothing. That is a silent failure: no script is wrong, nothing
# raises, and the only evidence is the absence of whatever the agent would have
# produced. It is the same shape the repo CLAUDE.md already calls out for hook
# matchers. In the case that prompted this suite, one agent's declared name was
# missing a `report-` segment its filename carried, which cost the canonical
# TIPS report its per-theme Stake / Move / Cost-of-Inaction cases.
#
# No pre-existing gate covers it, which is why the defect survived:
#   - cogni-workspace/scripts/check-skill-names.sh globs cogni-*/skills/*/SKILL.md
#     — skills only, never agents.
#   - cogni-service's check-frontmatter.sh does scan agents/*.md, but its name
#     regex validates kebab-case SHAPE alone; a well-formed but wrong name passes.
# Both were green on the broken tree.
#
# Case-label shape deviates from the sibling suites on purpose.
# test-project-status.sh and test-stale-detection.sh print "OK   <label>"; this
# suite prints "PASS: <label>" / "FAIL: <label>" because the cogni-service
# mutation harness classifies a case GREEN only on
# ^[[:space:]]*(ok|PASS):[[:space:]]+<case> and RED on the matching FAIL: form.
# Neither "OK   " nor "OK:" is in that vocabulary, so a mutation replay against
# this suite would report case_not_found instead of a verdict. The detail after
# a case id is separated by a SPACE and never a colon — "FAIL: A5: detail" also
# reports case_not_found on a genuinely red case. Case ids are A-prefixed and
# never bare numerals, which keeps the final summary line
# ("FAIL: <n> agent-frontmatter-name test(s) failed.") from being read as a
# case's RED line. Do not "fix" these labels back to the house style.
#
# This file deliberately never spells the pre-fix bare agent name as one
# contiguous token: the repo-wide falsifier for issue #1388 is an unfiltered
# scan for that token expecting zero hits, and naming it here would make the
# suite's own source the hit.
#
# bash-3.2 portable (stock macOS /bin/bash is 3.2.57): no declare -A /
# typeset -A, no mapfile / readarray, no ${var^^} / ${var,,}.
#
# stdlib-only: bash + coreutils. No python3, no pip deps, no network. Writes
# only under its own mktemp -d.
#
# Usage: bash cogni-trends/tests/test-agent-frontmatter-names.sh
# Exits non-zero on any assertion failure.
#
# Mutation recipe (proves case A5 is load-bearing):
#   bash ~/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh \
#     --root . \
#     --file cogni-trends/agents/trend-report-investment-theme-writer.md \
#     --expr 's/^name: trend-report-investment-theme-writer/name: trend-investment-/m' \
#     --test 'bash cogni-trends/tests/test-agent-frontmatter-names.sh' \
#     --case A5

set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
AGENTS_DIR="$PLUGIN_DIR/agents"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

# ---------------------------------------------------------------------------
# The checker. Fixture cases and the real-tree case drive this same function —
# the matcher is never reimplemented in a case body, so pointing a case at a
# broken matcher turns that case red rather than silently passing.
#
# scan_agents <agents_dir> <count_out_file>
#   stdout: one line per violation
#   <count_out_file>: number of *.md files actually scanned (the liveness signal)
# ---------------------------------------------------------------------------
scan_agents() {
  local scan_dir count_file scanned f stem declared
  scan_dir="$1"
  count_file="$2"
  scanned=0

  for f in "$scan_dir"/*.md; do
    # An unmatched glob expands to the literal pattern; skip it so an empty or
    # missing directory reports scanned=0 instead of inventing a phantom file.
    [ -e "$f" ] || continue
    scanned=$((scanned + 1))

    stem="${f##*/}"
    stem="${stem%.md}"

    # First `name:` line at column 0 — the frontmatter key. Trailing whitespace
    # is stripped so a stray space cannot read as a mismatch.
    declared="$(grep -m1 '^name:' "$f" | sed 's/^name:[[:space:]]*//' | sed 's/[[:space:]]*$//')"

    if [ -z "$declared" ]; then
      printf '  %s: no frontmatter "name:" key\n' "${f##*/}"
    elif [ "$declared" != "$stem" ]; then
      printf '  %s: declared "%s" != filename stem "%s"\n' "${f##*/}" "$declared" "$stem"
    fi
  done

  printf '%s' "$scanned" > "$count_file"
}

# Build a fixture agent file with an arbitrary declared name.
# write_agent <dir> <stem> <declared-name-or-NONE>
write_agent() {
  local wa_dir wa_stem wa_name
  wa_dir="$1"
  wa_stem="$2"
  wa_name="$3"
  mkdir -p "$wa_dir"
  {
    echo "---"
    if [ "$wa_name" != "NONE" ]; then
      echo "name: $wa_name"
    fi
    echo "description: fixture agent for the frontmatter-name regression suite."
    echo "tools: Read"
    echo "model: sonnet"
    echo "---"
    echo
    echo "Fixture body."
  } > "$wa_dir/$wa_stem.md"
}

COUNT_FILE="$TMPROOT/scanned"

# --- A1: a fixture whose names all match their stems reports clean -----------
CLEAN_DIR="$TMPROOT/clean/agents"
write_agent "$CLEAN_DIR" "alpha-agent" "alpha-agent"
write_agent "$CLEAN_DIR" "beta-agent" "beta-agent"
A1_OUT="$(scan_agents "$CLEAN_DIR" "$COUNT_FILE")"
A1_COUNT="$(cat "$COUNT_FILE")"
if [ -z "$A1_OUT" ] && [ "$A1_COUNT" = "2" ]; then
  pass "A1 matching fixture reports no violations (scanned 2)"
else
  fail "A1 matching fixture should be clean, got violations: ${A1_OUT:-<none>} (scanned $A1_COUNT)"
fi

# --- A2: a mismatched fixture is caught, and names both sides ----------------
# This is the liveness case for the matcher itself: if the checker cannot fire,
# A2 goes red and the green A5 below is worthless.
BAD_DIR="$TMPROOT/bad/agents"
write_agent "$BAD_DIR" "alpha-agent" "alpha-agent"
write_agent "$BAD_DIR" "gamma-agent" "delta-agent"
A2_OUT="$(scan_agents "$BAD_DIR" "$COUNT_FILE")"
A2_LINES="$(printf '%s\n' "$A2_OUT" | grep -c 'gamma-agent')"
if [ "$A2_LINES" = "1" ] \
  && printf '%s' "$A2_OUT" | grep -q 'delta-agent' \
  && printf '%s' "$A2_OUT" | grep -q 'gamma-agent'; then
  pass "A2 mismatched fixture is reported, naming file, declared and expected"
else
  fail "A2 mismatched fixture not reported correctly, got: ${A2_OUT:-<none>}"
fi

# --- A3: a fixture with no name: key fails rather than being skipped ---------
NONAME_DIR="$TMPROOT/noname/agents"
write_agent "$NONAME_DIR" "orphan-agent" "NONE"
A3_OUT="$(scan_agents "$NONAME_DIR" "$COUNT_FILE")"
if printf '%s' "$A3_OUT" | grep -q 'no frontmatter'; then
  pass "A3 agent missing a name: key is reported, not skipped"
else
  fail "A3 agent missing a name: key was not reported, got: ${A3_OUT:-<none>}"
fi

# --- A4: an empty agents dir reports scanned=0 (the vacuity floor) -----------
# Without this, a glob that silently stops matching would make A5 pass by
# scanning nothing at all. A4 proves the liveness counter can read zero, which
# is what gives A6's non-zero assertion its meaning.
EMPTY_DIR="$TMPROOT/empty/agents"
mkdir -p "$EMPTY_DIR"
A4_OUT="$(scan_agents "$EMPTY_DIR" "$COUNT_FILE")"
A4_COUNT="$(cat "$COUNT_FILE")"
if [ -z "$A4_OUT" ] && [ "$A4_COUNT" = "0" ]; then
  pass "A4 empty agents dir scans 0 files (vacuity floor is real)"
else
  fail "A4 empty agents dir should scan 0 files, got count $A4_COUNT violations ${A4_OUT:-<none>}"
fi

# --- A5: the real cogni-trends/agents tree is clean --------------------------
# The case the mutation recipe in the header targets.
A5_OUT="$(scan_agents "$AGENTS_DIR" "$COUNT_FILE")"
REAL_COUNT="$(cat "$COUNT_FILE")"
if [ -z "$A5_OUT" ]; then
  pass "A5 every cogni-trends agent declares a name matching its filename stem"
else
  fail "A5 agent frontmatter name does not match filename stem"
  printf '%s\n' "$A5_OUT" >&2
fi

# --- A6: the real-tree scan actually visited files ---------------------------
# Deliberately asserts "> 0" and never a fixed count: cogni-trends/agents holds
# 12 files today while cogni-trends/CLAUDE.md's inventory table still says 11,
# and pinning a number would couple this suite to that unrelated drift.
if [ "$REAL_COUNT" -gt 0 ]; then
  pass "A6 real-tree scan visited $REAL_COUNT agent file(s)"
else
  fail "A6 real-tree scan visited no files — the agents glob matched nothing"
fi

if [ $failures -gt 0 ]; then
  echo
  echo "FAIL: $failures agent-frontmatter-name test(s) failed." >&2
  exit 1
fi
echo
echo "All agent-frontmatter-name assertions passed."
