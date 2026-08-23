#!/usr/bin/env bash
# test_prose_density_contract.sh — #309 P2.1 + P2.4 cross-cutting contract.
#
# The prose-density knob spans three files (composer drafting discipline,
# compose dispatch threading, reviewer advisory Word Count Gate). This file is
# the single regression guard that the standard-floor / executive-ceiling
# contract stays intact end-to-end — and, critically, that it never grows an
# expansion LOOP (the composer stays single-pass; the floor/ceiling is advisory).
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

COMPOSER="$PLUGIN_ROOT/agents/wiki-composer.md"
COMPOSE="$PLUGIN_ROOT/skills/knowledge-compose/SKILL.md"
REVIEWER="$PLUGIN_ROOT/agents/wiki-reviewer.md"

# Collect then pair: emitting per iteration gives the case an id that can only
# ever print red, so `--case prose-density-00` could never be verified. Accumulate
# inside the loop and emit one fixed-id if/else after it closes — the
# plain-emit-03 model in test_plain_result_emitters.sh.
_missing_required=""
for _p in composer:"$COMPOSER" compose:"$COMPOSE" reviewer:"$REVIEWER"; do
  _cid="${_p%%:*}"; f="${_p#*:}"
  if [ ! -f "$f" ]; then
    _missing_required="${_missing_required}${_cid}: $f
"
  fi
done
if [ -z "$_missing_required" ]; then
  green "PASS: prose-density-00 every required file is present"
else
  red "FAIL: prose-density-00 required file(s) not found:"
  printf '%s' "$_missing_required" | sed 's/^/    /'
  exit 1
fi

# --- composer: standard soft-budget vs executive ceiling, single pass ----
# Brevity-first retune: standard treats TARGET_WORDS as a soft UPPER BUDGET (not a
# floor), so the outline budgets to ≤ TARGET_WORDS with no 5% headroom and never pads.
assert_grep 'soft upper budget' "$COMPOSER" "prose-density-01-standard-treats-target-words wiki-composer: standard treats TARGET_WORDS as a soft upper budget (not a floor)"
assert_grep 'ceiling' "$COMPOSER" "prose-density-02-names-executive-density-ceiling wiki-composer: names the executive-density ceiling"
assert_grep 'no headroom' "$COMPOSER" "prose-density-03-executive-outline-budgets-ceiling wiki-composer: executive outline budgets to a ceiling (no headroom)"
assert_grep 'sum(budgets) ≤ TARGET_WORDS' "$COMPOSER" "prose-density-04-standard-outline-budgets-target wiki-composer: standard outline budgets to ≤ TARGET_WORDS (no quota padding)"
assert_not_grep '× 1.05' "$COMPOSER" "prose-density-05-no-5-floor-headroom wiki-composer: no 5% floor headroom remains (brevity-first retune)"
# The self-check must branch but explicitly NEVER loop.
assert_grep 'NEVER loop\|never loops\|no re-dispatch loop\|there is no re-dispatch loop' "$COMPOSER" "prose-density-06-word-count-self-check wiki-composer: the word-count self-check shapes ONE pass, never loops (#309 P2.4)"
assert_grep 'Over ceiling\|over .TARGET_WORDS. (the ceiling)\|over the ceiling\|trim .*redundancy' "$COMPOSER" "prose-density-07-executive-trims-redundancy-when wiki-composer: executive trims redundancy when over the ceiling"
# The single-pass invariant in the NOT-list must survive the density knob.
assert_grep 'Does NOT iterate on word-count shortfall\|does NOT re-dispatch' "$COMPOSER" "prose-density-08-not-list-keeps-single wiki-composer: NOT-list keeps the single-pass / no-re-dispatch invariant"

# --- compose: threads PROSE_DENSITY + TARGET_WORDS, density-aware summary -
# Brevity-first: standard NO LONGER warns "Below target" (under-budget is the
# intended outcome); it surfaces a coverage line instead. executive keeps over-ceiling.
assert_grep 'PROSE_DENSITY=' "$COMPOSE" "prose-density-09-threads-prose-density-composer knowledge-compose: threads PROSE_DENSITY into the composer dispatch"
assert_not_grep 'Below target' "$COMPOSE" "prose-density-10-no-standard-budget-warning knowledge-compose: no standard under-budget warning (brevity is the intended outcome)"
assert_grep 'coverage:' "$COMPOSE" "prose-density-11-standard-surfaces-coverage-line knowledge-compose: standard surfaces a coverage line, not a word warning"
assert_grep 'Over ceiling' "$COMPOSE" "prose-density-12-executive-ceiling-warning knowledge-compose: executive over-ceiling warning"
# Coverage-gated expansion now fires under executive too (ceiling-bounded). The
# Step 5.5 actuator must reach executive runs, and the wiki/log Expansion summary
# line must no longer be omitted on every non-standard density run.
assert_grep 'standard or executive density' "$COMPOSE" "prose-density-13-step-5-5-expansion-summary knowledge-compose: Step 5.5 Expansion summary line emits under standard OR executive density"
assert_not_grep "omit the line on a non-.standard. density run" "$COMPOSE" "prose-density-14-expansion-line-no-longer knowledge-compose: the Expansion line is no longer omitted on every non-standard density run"

# --- reviewer: advisory Word Count Gate — brevity-neutral, no loop --------
assert_grep 'Word Count Gate (advisory)\|advisory Word Count Gate' "$REVIEWER" "prose-density-15-advisory-word-count-gate wiki-reviewer: has an advisory Word Count Gate"
assert_grep 'Possible truncated draft' "$REVIEWER" "prose-density-16-standard-caps-only-likely wiki-reviewer: standard caps only a likely-truncated draft (not brevity)"
assert_not_grep 'Word deficit' "$REVIEWER" "prose-density-17-no-word-deficit-penalty wiki-reviewer: no Word deficit penalty (brevity-first retune)"
assert_grep 'Word excess' "$REVIEWER" "prose-density-18-executive-excess-emits-word wiki-reviewer: executive excess emits Word excess"
# Representative thresholds: the executive >1.25 excess tier and the standard <0.50 truncation tier.
assert_grep '1.25' "$REVIEWER" "prose-density-19-gate-1-25-excess-tier wiki-reviewer: gate has the >1.25 excess tier"
assert_grep '0.50' "$REVIEWER" "prose-density-20-gate-0-50-truncation-tier wiki-reviewer: gate has the <0.50 truncation tier"
# The cap targets Completeness, NOT Depth (Depth is the density gate's job).
assert_grep 'cap.*Completeness\|caps Completeness\|Completeness.*cap\|applied_completeness_cap' "$REVIEWER" "prose-density-21-word-count-gate-caps wiki-reviewer: Word Count Gate caps Completeness"
# Hard invariant: advisory only — no expansion loop, never blocks finalize.
assert_grep 'no expansion loop\|never gates finalize\|never blocks\|advisory only\|drives no\|drives NO' "$REVIEWER" "prose-density-22-word-count-gate-advisory wiki-reviewer: Word Count Gate is advisory — no expansion loop, never blocks"

# allow_short must NOT be a live input parameter (it only made sense against the
# upstream expansion loop). The reviewer prose legitimately EXPLAINS why it is
# not ported, so we assert it is not a `| `allow_short` |` parameter-table row.
if grep -q "| \`allow_short\` |\|allow_short.*input parameter\|takes.*allow_short" "$REVIEWER"; then
  red "FAIL: prose-density-23-allow-short-not-live wiki-reviewer: allow_short must not be a live input (no upstream loop to short-circuit)"
  errors=$((errors + 1))
else
  green "PASS: prose-density-23-allow-short-not-live wiki-reviewer: allow_short is not a live input parameter (not ported)"
fi
assert_grep 'allow_short.*not ported\|allow_short. is not ported\|not ported' "$REVIEWER" "prose-density-24-documents-allow-short-intentionally wiki-reviewer: documents that allow_short is intentionally not ported"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
