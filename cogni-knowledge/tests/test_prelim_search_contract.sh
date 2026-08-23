#!/usr/bin/env bash
# test_prelim_search_contract.sh — #382 preliminary/scoping search contract.
#
# Ports cogni-research's Phase-0.5 preliminary search into knowledge-plan as an
# opt-in, fail-soft scan folded into the Step 0.4 topic-framing pass. This file
# is the single regression guard that the scan stays:
#   - opt-in (rides framing's engage decision, --no-prelim-search opts out),
#   - fail-soft (any error → pure-reasoning path),
#   - web-bounded (WebSearch only; WebFetch is still forbidden), and
#   - documented in both the skill and the topic-framing playbook.
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

PLAN="$PLUGIN_ROOT/skills/knowledge-plan/SKILL.md"
FRAMING="$PLUGIN_ROOT/references/topic-framing.md"

# Collect then pair: emitting per iteration gives the case an id that can only
# ever print red, so `--case prelim-search-00` could never be verified. Accumulate
# inside the loop and emit one fixed-id if/else after it closes — the
# plain-emit-03 model in test_plain_result_emitters.sh.
_missing_required=""
for _p in plan:"$PLAN" framing:"$FRAMING"; do
  _cid="${_p%%:*}"; f="${_p#*:}"
  if [ ! -f "$f" ]; then
    _missing_required="${_missing_required}${_cid}: $f
"
  fi
done
if [ -z "$_missing_required" ]; then
  green "PASS: prelim-search-00 every required file is present"
else
  red "FAIL: prelim-search-00 required file(s) not found:"
  printf '%s' "$_missing_required" | sed 's/^/    /'
  exit 1
fi

# --- knowledge-plan: WebSearch enabled, scan is opt-in + fail-soft ---------
assert_grep 'allowed-tools:.*WebSearch' "$PLAN" "prelim-search-01-allowed-tools-includes-websearch knowledge-plan: allowed-tools includes WebSearch"
assert_grep 'reliminary scoping scan' "$PLAN" "prelim-search-02-documents-preliminary-scoping-scan knowledge-plan: documents the preliminary scoping scan"
assert_grep 'no-prelim-search' "$PLAN" "prelim-search-03-no-prelim-search-opt knowledge-plan: --no-prelim-search opt-out is documented"
assert_grep '[Ff]ail-soft' "$PLAN" "prelim-search-04-scan-fail-soft knowledge-plan: the scan is fail-soft"
assert_grep 'rides framing' "$PLAN" "prelim-search-05-scan-rides-framing-s knowledge-plan: the scan rides framing's engage decision (opt-in, no new decision point)"
# The scan must not fire on the non-interactive paths — one stable phrase anchors
# the whole "sharp topic / --no-framing / --dry-run" sentence (--no-prelim-search
# is asserted separately above).
assert_grep 'never runs on a sharp topic' "$PLAN" "prelim-search-06-scan-never-fires-sharp knowledge-plan: the scan never fires on a sharp topic / --no-framing / --dry-run"

# --- the WebSearch loosening must NOT erode the WebFetch ban ---------------
# Out of scope used to flatly forbid both; it now allows the opt-in scan but
# keeps WebFetch forbidden outright.
assert_not_grep 'Does NOT call WebSearch or WebFetch' "$PLAN" "prelim-search-07-flat-no-websearch-webfetch knowledge-plan: the flat 'no WebSearch or WebFetch' forbiddance is replaced (scan is now allowed)"
# Match the semantic contract, not the markdown emphasis, so a reword that drops
# the bold doesn't silently break the guard.
assert_grep 'WebSearch.*by default' "$PLAN" "prelim-search-08-websearch-forbidden-only-default knowledge-plan: WebSearch is forbidden only by default (the scan is the exception)"
assert_grep '[Nn]ever.*calls WebFetch' "$PLAN" "prelim-search-09-webfetch-forbidden-outright knowledge-plan: WebFetch is still forbidden outright"

# --- topic-framing playbook: the scan move is wired in ---------------------
assert_grep 'Step 0.2b' "$FRAMING" "prelim-search-10-step-0-2-b-preliminary topic-framing: has the Step 0.2b preliminary scan move"
assert_grep 'ground.*scan.*sharpen' "$FRAMING" "prelim-search-11-spine-updated-ground-scan topic-framing: spine updated to ground → scan → sharpen"
assert_grep '[Pp]reliminary scoping scan' "$FRAMING" "prelim-search-12-names-preliminary-scoping-scan topic-framing: names the preliminary scoping scan"
assert_grep 'no-prelim-search' "$FRAMING" "prelim-search-13-documents-no-prelim-search topic-framing: documents the --no-prelim-search opt-out"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
