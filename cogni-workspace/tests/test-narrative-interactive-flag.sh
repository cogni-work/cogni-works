#!/usr/bin/env bash
# narrative --interactive contract guard: the flag must be documented, its
# Phase 2 branch must exist, the default interactive path must survive, and the
# narrative-writer agent must actually pass the flag.
#
# Why this exists. `skills/narrative/SKILL.md` Phase 2 confirms the detected arc
# through AskUserQuestion. Every non-interactive caller stalled there, because
# the skill had no argument telling it to stay quiet — `agents/narrative-writer.md`
# instructed "Do NOT ask user questions during execution" with no skill-side lever
# to enforce it. The fix is a documented `--interactive` flag (default `true`) plus
# a Phase 2 branch, and the agent hardcoding `--interactive false`.
#
# The regression this guards against is not the feature going missing — it is the
# feature being "cleaned up" in the wrong direction. The obvious wrong fix is to
# strip AskUserQuestion from the skill's `allowed-tools:`, which silently breaks
# the confirmation for every human caller while leaving the flag looking correct.
# Case P3 is the guard for exactly that, and it asserts by SITE rather than by a
# bare occurrence count: a count of 2 also holds if someone deletes the frontmatter
# grant and adds a stray mention somewhere else, so a count alone would stay green
# through the very regression it exists to catch — and it would go red on the
# legitimate change of adding a second gated prompt site, which is the direction
# the sibling skills have already taken.
#
# Mutation recipe (proves P2 has teeth). Every flag value is a literal — the
# handoff preflight rejects a variable-bearing recipe, and a
# ${CLAUDE_PLUGIN_ROOT}-relative harness path resolves to one of the two
# argument-less in-repo copies (cogni-consult/scripts/, cogni-portfolio/scripts/)
# and replays to a false green. Run from the repo root:
#
#   bash /Users/stephandehaas/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh \
#     --root . \
#     --file cogni-workspace/skills/narrative/SKILL.md \
#     --expr 's/this confirmation does not run/this confirmation always runs/' \
#     --test 'bash cogni-workspace/tests/test-narrative-interactive-flag.sh' \
#     --case P2
#
# The search literal occurs exactly once at head and zero times at base, so the
# expr cannot report expr_no_op; it is a plain non-global s/// with no capture
# groups and no /d form, so it is valid for `perl -0pi`; and the replacement does
# not contain the search literal, so the mutant cannot re-satisfy P2 — its count
# goes 1 -> 0 and it prints `FAIL: P2`, a real red rather than case_not_found.
# The same mutant leaves P1, P3 and P4 untouched, so the redness is attributable
# to P2 alone.

# set -u but deliberately NOT set -e: a red arm must print its FAIL line and let
# the run reach the summary, not abort the script at the first failing check.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"

# Both targets are workspace-internal, so reach them from WS_ROOT rather than
# routing back down through the repo root — that is the sibling idiom, and it
# keeps the plugin directory name out of the suite entirely.
SKILL="$WS_ROOT/skills/narrative/SKILL.md"
AGENT="$WS_ROOT/agents/narrative-writer.md"

failures=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

# ---------------------------------------------------------------------------
# Both files must exist before any case can mean anything. A missing file would
# otherwise make every grep return 0 and read as a content failure rather than
# a path failure.
# ---------------------------------------------------------------------------
missing_inputs=""
for f in "$SKILL" "$AGENT"; do
  [ -f "$f" ] || missing_inputs="$missing_inputs $f"
done

if [ -n "$missing_inputs" ]; then
  for m in $missing_inputs; do
    printf '%s\n' "  missing input: $m"
  done
  fail "P0 setup expected files are readable"
  echo ""
  echo "RESULT: $failures narrative-interactive case(s) failed."
  exit 1
fi
pass "P0 setup expected files are readable"

# ---------------------------------------------------------------------------
# P1 -- the flag is documented where every other narrative argument is documented.
# Binds to the Parameters-table row shape (leading pipe, the flag, the `No`
# required column) AND to the stated default, so a Phase 2 branch shipped without
# a table row does not pass.
# ---------------------------------------------------------------------------
# One pipeline, not two conjuncts: the second stage cannot match unless the
# first produced a row, so a separate row-shape grep would be entailed by this
# and would only duplicate the pattern literal at a second site.
if grep '^| `--interactive` | No |' "$SKILL" | grep -q 'Default: `true`'; then
  pass "P1 the --interactive row exists in the Parameters table and states Default: \`true\`"
else
  fail "P1 the --interactive row exists in the Parameters table and states Default: \`true\`"
fi

# ---------------------------------------------------------------------------
# P2 -- the Phase 2 non-interactive branch is documented. This is the case the
# mutation recipe above drives red.
# ---------------------------------------------------------------------------
branch_hits=$(grep -c 'this confirmation does not run' "$SKILL")
if [ "$branch_hits" -eq 1 ]; then
  pass "P2 the Phase 2 non-interactive branch is documented exactly once"
else
  fail "P2 the Phase 2 non-interactive branch is documented exactly once (found $branch_hits)"
fi

# ---------------------------------------------------------------------------
# P3 -- the default interactive path survives, asserted by SITE, not by a count.
#   (i)  the frontmatter grant is still present
#   (ii) the Phase 2 call site is still present
#
# Deliberately NOT a third "AskUserQuestion occurs exactly N times" conjunct.
# The sibling skills (story-to-slides, story-to-web, story-to-infographic) each
# gate three or four prompt sites on their `interactive` parameter, so narrative
# gaining a second legitimate checkpoint is the expected direction of travel. A
# pinned total would go red on that correct change, and the cheapest reaction to
# it would be to bump the constant — eroding the by-site discipline this case
# exists to enforce. The two site conjuncts already carry the regression.
# ---------------------------------------------------------------------------
p3_grant=$(grep -c '^allowed-tools:.*AskUserQuestion' "$SKILL")
p3_site=$(grep -c 'Present selected arc to user for confirmation using AskUserQuestion' "$SKILL")
if [ "$p3_grant" -eq 1 ] && [ "$p3_site" -eq 1 ]; then
  pass "P3 the default interactive path survives: allowed-tools grant and Phase 2 call site both intact"
else
  fail "P3 the default interactive path survives: allowed-tools grant and Phase 2 call site both intact (grant=$p3_grant site=$p3_site, want 1/1)"
fi

# ---------------------------------------------------------------------------
# P4 -- the agent actually passes the flag. Without this the skill-side branch is
# reachable in principle and unreached in practice, which is the state this whole
# change exists to leave behind.
# ---------------------------------------------------------------------------
if grep -q 'interactive false' "$AGENT"; then
  pass "P4 narrative-writer passes --interactive false on its skill invocation"
else
  fail "P4 narrative-writer passes --interactive false on its skill invocation"
fi

# ---------------------------------------------------------------------------
# P5 -- the agent must not reference AskUserQuestion at all. The skill keeps the
# grant (P3); the agent is the non-interactive caller, so a prompt reaching it is
# the regression this whole change exists to prevent. Asserted here rather than
# assumed, because this diff adds agent-body prose in exactly that neighbourhood.
# ---------------------------------------------------------------------------
if grep -q 'AskUserQuestion' "$AGENT"; then
  fail "P5 narrative-writer.md must not reference AskUserQuestion"
else
  pass "P5 narrative-writer.md must not reference AskUserQuestion"
fi

# ---------------------------------------------------------------------------
# The summary line begins RESULT:, never FAIL:. A FAIL:-prefixed summary is
# itself parsed as a case verdict by the shared mutation harness.
# ---------------------------------------------------------------------------
echo ""
if [ "$failures" -gt 0 ]; then
  echo "RESULT: $failures narrative-interactive case(s) failed."
  exit 1
fi
echo "RESULT: all narrative-interactive cases passed."
exit 0
