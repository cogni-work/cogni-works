#!/usr/bin/env bash
# stakeholder_review default contract guard: the flag must default to a literal
# `true` in all three story-to-* skills, the superseded coupling clause must stay
# deleted, each skill must state its headless reject successor, the caller's
# explicit passes must survive, and the ruled-out-of-scope `render` default must
# stay put.
#
# Why this exists. All three skills used to declare `stakeholder_review` with a
# Default cell of `interactive` — a default *of another parameter*. Any headless
# caller therefore lost brief review as a side effect of suppressing prompts: no
# error, no warning, just no review. The fix decouples the two, defaulting the
# flag to a literal `true`.
#
# The regression this guards against is not the flip being reverted outright — it
# is the flip re-drifting through prose. The mechanism lives entirely in SKILL.md
# tables and paragraphs, so nothing but a guard holds it. Three drift directions
# are covered specifically:
#
#   * S2 catches the half-fix: a Default cell flipped to `true` while the row's
#     description still says it defaults to `interactive`. That reads as fixed to
#     anyone grepping the Default column and re-seeds the exact drift, so the
#     stale clause must be *deleted*, not merely contradicted.
#   * S3 asserts the headless reject successor per SITE rather than by a bare
#     repo-wide count. A count also holds if two skills state it and the third
#     states it twice, which is precisely the miss this exists to catch —
#     story-to-infographic's Step 8b is the tersest of the three.
#   * S5 pins the `render` default at `true`. A maintainer ruling put that row
#     out of scope; without a guard the next reader sees an obvious-looking
#     asymmetry and "finishes the job", which is a scope violation rather than a
#     bonus.
#
# Mutation recipe (proves S2 has teeth). Every flag value is a literal — the
# handoff preflight rejects a variable-bearing recipe, and a
# ${CLAUDE_PLUGIN_ROOT}-relative harness path resolves to one of the two
# argument-less in-repo copies (cogni-consult/scripts/, cogni-portfolio/scripts/)
# and replays to a false green. Run from the repo root:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/skills/story-to-slides/SKILL.md \
#     --expr 's/after validation\. \|/after validation. Defaults to value of interactive. |/' \
#     --test 'bash cogni-workspace/tests/test-stakeholder-review-default.sh' \
#     --case S2
#
# The search literal occurs exactly once at head (the `stakeholder_review` row,
# whose description ends "after validation." immediately before the closing cell
# pipe) and the replacement re-inserts the very clause this change deleted, so
# S2's occurrence count goes 0 -> 1 and it prints `FAIL: S2`. It is a plain
# non-global s/// with no capture groups and no /d form, so it is valid for
# `perl -0pi`; the replacement does not contain the search literal, so the mutant
# cannot re-satisfy S2. S0, S1, S3, S4, S5 and S6 are untouched by the mutant, so
# the redness is attributable to S2 alone.

# set -u but deliberately NOT set -e: a red arm must print its FAIL line and let
# the run reach the summary, not abort the script at the first failing check.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"

SLIDES="$WS_ROOT/skills/story-to-slides/SKILL.md"
WEB="$WS_ROOT/skills/story-to-web/SKILL.md"
INFOG="$WS_ROOT/skills/story-to-infographic/SKILL.md"
PUBLISH="$WS_ROOT/skills/narrative-publish/SKILL.md"
CONTRACT="$WS_ROOT/skills/narrative-publish/references/pipeline-contract.md"

failures=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

HEADLESS_FRAGMENT='keep the brief, do not render it, and surface the reject in the response'

# ---------------------------------------------------------------------------
# S0 — every input must exist before any case can mean anything. A missing file
# would otherwise make every grep return 0 and read as a content failure rather
# than a path failure.
# ---------------------------------------------------------------------------
missing_inputs=""
for f in "$SLIDES" "$WEB" "$INFOG" "$PUBLISH" "$CONTRACT"; do
  [ -f "$f" ] || missing_inputs="$missing_inputs $f"
done
if [ -n "$missing_inputs" ]; then
  fail "S0 all five contract files must exist (missing:$missing_inputs)"
  echo ""
  echo "RESULT: $failures stakeholder-review case(s) failed."
  exit 1
fi
pass "S0 all five contract files exist"

# ---------------------------------------------------------------------------
# S1 — asserted per site. The Default cell must read `true`, and must not read
# `interactive`, in each of the three skills independently.
# ---------------------------------------------------------------------------
s1_bad=""
for pair in "story-to-slides:$SLIDES" "story-to-web:$WEB" "story-to-infographic:$INFOG"; do
  name="${pair%%:*}"; file="${pair#*:}"
  if ! grep -qE '^\| `stakeholder_review` \| `true` \|' "$file"; then
    s1_bad="$s1_bad $name(no-true-cell)"
  fi
  if grep -qE '^\| `stakeholder_review` \| `interactive` \|' "$file"; then
    s1_bad="$s1_bad $name(still-coupled)"
  fi
done
if [ -n "$s1_bad" ]; then
  fail "S1 stakeholder_review must default to a literal \`true\` in all three skills —$s1_bad"
else
  pass "S1 stakeholder_review defaults to a literal \`true\` in all three skills"
fi

# ---------------------------------------------------------------------------
# S2 — the superseded coupling clause must stay deleted, not merely contradicted.
# ---------------------------------------------------------------------------
s2_hits=$(cat "$SLIDES" "$WEB" | grep -c 'Defaults to value of' || true)
if [ "$s2_hits" -ne 0 ]; then
  fail "S2 the superseded 'Defaults to value of' clause must stay deleted (found $s2_hits)"
else
  pass "S2 the superseded 'Defaults to value of' clause stays deleted"
fi

# ---------------------------------------------------------------------------
# S3 — the headless reject successor, asserted per site (see header).
# ---------------------------------------------------------------------------
s3_bad=""
for pair in "story-to-slides:$SLIDES" "story-to-web:$WEB" "story-to-infographic:$INFOG"; do
  name="${pair%%:*}"; file="${pair#*:}"
  n=$(grep -c "$HEADLESS_FRAGMENT" "$file" || true)
  [ "$n" -eq 1 ] || s3_bad="$s3_bad $name(count=$n)"
done
if [ -n "$s3_bad" ]; then
  fail "S3 each skill must state its headless reject successor exactly once —$s3_bad"
else
  pass "S3 each skill states its headless reject successor exactly once"
fi

# ---------------------------------------------------------------------------
# S4 — the caller's three explicit passes are belt-and-braces, not dead code.
# Dropping them because the callee default now agrees is the tempting wrong fix.
# ---------------------------------------------------------------------------
s4_hits=$(grep -c 'stakeholder_review=true' "$PUBLISH" || true)
if [ "$s4_hits" -ne 3 ]; then
  fail "S4 narrative-publish must keep its 3 explicit stakeholder_review=true passes (found $s4_hits)"
else
  pass "S4 narrative-publish keeps its 3 explicit stakeholder_review=true passes"
fi

# ---------------------------------------------------------------------------
# S5 — the ruled-out-of-scope `render` default stays `true` (see header).
# ---------------------------------------------------------------------------
if grep -qE '^\| `render` \| `true` \|' "$INFOG"; then
  pass "S5 story-to-infographic keeps its \`render\` default of \`true\`"
else
  fail "S5 story-to-infographic must keep its \`render\` default of \`true\` — the flip is ruled out of scope"
fi

# ---------------------------------------------------------------------------
# S6 — the two overrides no longer share a shape, so the mirror framing is false.
# ---------------------------------------------------------------------------
s6_hits=$(grep -c 'exact mirror of rule 1' "$CONTRACT" || true)
if [ "$s6_hits" -ne 0 ]; then
  fail "S6 the falsified 'exact mirror of rule 1' framing must be gone (found $s6_hits)"
else
  pass "S6 the falsified 'exact mirror of rule 1' framing is gone"
fi

# ---------------------------------------------------------------------------
# The summary line begins RESULT:, never FAIL:. A FAIL:-prefixed summary is
# itself parsed as a case verdict by the shared mutation harness.
# ---------------------------------------------------------------------------
echo ""
if [ "$failures" -gt 0 ]; then
  echo "RESULT: $failures stakeholder-review case(s) failed."
  exit 1
fi
echo "RESULT: all stakeholder-review cases passed."
exit 0
