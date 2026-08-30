#!/usr/bin/env bash
# test-check-contrast.sh — suite for cogni-workspace/scripts/check-contrast.py
#
# The AA-boundary cases are the point of this suite, and the assertion AXIS is
# load-bearing. On #FFFFFF: #767676 = 4.5422 and #777777 = 4.4781 straddle the
# 4.5:1 normal-text threshold, but BOTH clear the 3:1 large-text threshold — so
# asserting that pair on passes_aa_large returns two identical verdicts and
# grades nothing. Symmetrically #949494 = 3.0335 and #959595 = 2.9953 straddle
# 3:1 while BOTH fail 4.5:1. Each boundary pair is therefore asserted on its own
# field only, and every fixture also pins its ratio so a constant-return mutant
# cannot satisfy a verdict by accident.
#
# Mutation recipe (the discriminator is cc07-below-aa-normal):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/scripts/check-contrast.py \
#     --expr 's{return \(lighter \+ 0\.05\) / \(darker \+ 0\.05\)}{return 21.0}' \
#     --test 'bash cogni-workspace/tests/test-check-contrast.sh' \
#     --case cc07-below-aa-normal
#
# Under the mutant every ratio reports 21.0, so the below-AA fixture flips to
# passes_aa_normal true and cc07 goes RED. This is the cogni-service harness,
# not the different scripts/mutation-check.sh that cogni-consult and
# cogni-portfolio each ship; the repo root has no such script.
#
# Second recipe, for the role-vocabulary arm (the discriminator is
# cc22-danger-is-evaluated):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/scripts/check-contrast.py \
#     --expr 's{^    "danger",\n}{}m' \
#     --test 'bash cogni-workspace/tests/test-check-contrast.sh' \
#     --case cc22-danger-is-evaluated
#
# Dropping the canonical status role from LARGE_UI_ROLES restores the exact
# defect this suite exists to pin: danger parses as valid hex, so it reaches
# neither the pair set nor data.unparsed, and the audit reports clean with the
# status colour ungraded. One role per line in the vocabulary tuples is what
# makes that a single-line, single-occurrence anchor.
#
# Third recipe, for the narrow --pair arm (the discriminator is
# cc28-unclassified-survives-the-pair-path):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/scripts/check-contrast.py \
#     --expr 's{"unclassified": sorted\(set\(usable\) - CLASSIFIED_ROLES\)}{"unclassified": [] if requested else sorted(set(usable) - CLASSIFIED_ROLES)}' \
#     --test 'bash cogni-workspace/tests/test-check-contrast.sh' \
#     --case cc28-unclassified-survives-the-pair-path
#
# The mutant computes data.unclassified in a full-palette-only branch, which is
# exactly the refactor the emission property is meant to survive. cc22-cc25 all
# stay GREEN under it, because every one of them runs the default route where
# requested is empty -- which is why the narrow path needed a case of its own.
#
# Fourth recipe, for the null arm (the discriminator is
# cc33-null-arm-is-reachable-above-sqrt21):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/scripts/check-contrast.py \
#     --expr 's{^    return None$}{    return "#000000"}m' \
#     --test 'bash cogni-workspace/tests/test-check-contrast.sh' \
#     --case cc33-null-arm-is-reachable-above-sqrt21
#
# The mutant turns the null arm into a constant return, so the discriminator
# reads '#000000' instead of None. The anchor is single-occurrence:
# check-contrast.py carries three `return None`, and only suggest_hex's is
# four-space indented -- parse_hex's two are eight-space, which the `^    `
# anchor excludes. The discriminator has to be a DIRECT call (cc33), because the
# arm is no longer reachable through the palette CLI at all: both thresholds it
# exposes sit below sqrt(21) (see section F). cc13/cc14 stay GREEN because the
# BELOW_45 walk returns early, cc15 stays GREEN because a passing pair never
# calls suggest_hex, and cc31 now stays GREEN too -- post-fix it returns from the
# endpoint branch and never reaches the mutated line. cc33 is the only case that
# reads it, which is why the arm needed a direct-call case of its own.
#
# Fifth recipe, for the endpoint evaluation itself (the discriminator is
# cc31-endpoint-suggestion-is-present-and-black):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/scripts/check-contrast.py \
#     --expr 's{return to_hex\(endpoint\)}{pass}' \
#     --test 'bash cogni-workspace/tests/test-check-contrast.sh' \
#     --case cc31-endpoint-suggestion-is-present-and-black
#
# The mutant scores the endpoint but never returns it, which is exactly the
# pre-fix behaviour, so the witness falls back to None and cc31 reads
# (True, None, 1). The anchor is single-occurrence: the only other
# `to_hex(endpoint)` is inside `parse_hex(to_hex(endpoint))`, which the
# `return ` prefix excludes. `pass` is a valid statement in that block, so the
# mutant stays syntactically valid.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
SCRIPT="$WS_ROOT/scripts/check-contrast.py"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

# palette <name> <json> -> writes $TMPROOT/<name>.json and echoes the path
palette() {
  printf '%s' "$2" > "$TMPROOT/$1.json"
  printf '%s' "$TMPROOT/$1.json"
}

# field <palette-path> <jq-ish python expr over data> [extra args...]
field() {
  local pal="$1"; shift
  local expr="$1"; shift
  python3 "$SCRIPT" "$pal" "$@" 2>/dev/null | python3 -c "
import json, sys
try:
    payload = json.load(sys.stdin)
except Exception:
    print('PARSE_ERROR'); raise SystemExit(0)
data = payload.get('data') or {}
print($expr)
" 2>/dev/null
}

assert_eq() {
  local case_id="$1" expected="$2" actual="$3"
  if [ "$actual" = "$expected" ]; then
    pass "$case_id"
  else
    fail "$case_id"
    printf '  expected %s, got %s\n' "$expected" "$actual"
  fi
}

# assert_ratio <case-id> <expected> <actual> — equal to 3 decimal places
assert_ratio() {
  local case_id="$1" expected="$2" actual="$3"
  local verdict
  verdict="$(python3 -c "
import sys
try:
    print('ok' if abs(float(sys.argv[1]) - float(sys.argv[2])) < 1e-3 else 'no')
except Exception:
    print('no')
" "$expected" "$actual" 2>/dev/null)"
  if [ "$verdict" = "ok" ]; then
    pass "$case_id"
  else
    fail "$case_id"
    printf '  expected ratio ~%s, got %s\n' "$expected" "$actual"
  fi
}

echo "=== A. script surface ==="

if [ -f "$SCRIPT" ]; then
  pass "cc01-script-exists"
else
  fail "cc01-script-exists"
  echo "  $SCRIPT is missing; the remaining cases cannot run."
  echo "$failures test(s) failed."
  exit 1
fi

WHITE_ON_BLACK="$(palette wob '{"fg":"#FFFFFF","bg":"#000000"}')"

ENVELOPE="$(python3 "$SCRIPT" "$WHITE_ON_BLACK" 2>/dev/null | python3 -c "
import json, sys
try:
    payload = json.load(sys.stdin)
except Exception:
    print('unparseable'); raise SystemExit(0)
keys = sorted(payload)
print('ok' if keys == ['data', 'error', 'success'] and payload['error'] == '' else repr(keys))
" 2>/dev/null)"
assert_eq "cc02-envelope-shape" "ok" "$ENVELOPE"

THIRD_PARTY="$(python3 - "$SCRIPT" <<'PY' 2>/dev/null
import ast, sys, pathlib
STDLIB = {"argparse", "colorsys", "json", "re", "sys", "pathlib", "math", "os"}
tree = ast.parse(pathlib.Path(sys.argv[1]).read_text())
bad = []
for node in ast.walk(tree):
    if isinstance(node, ast.Import):
        bad += [a.name.split(".")[0] for a in node.names if a.name.split(".")[0] not in STDLIB]
    elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
        root = node.module.split(".")[0]
        if root not in STDLIB:
            bad.append(root)
print(",".join(sorted(set(bad))) or "stdlib-only")
PY
)"
assert_eq "cc03-stdlib-only" "stdlib-only" "$THIRD_PARTY"

echo "=== B. anchor ratios ==="

assert_ratio "cc04-white-on-black-is-21" "21.0" \
  "$(field "$WHITE_ON_BLACK" "data['pairs'][0]['ratio']" --pair fg:bg)"

SAME="$(palette same '{"fg":"#FFFFFF","bg":"#FFFFFF"}')"
assert_ratio "cc05-identical-colours-are-1" "1.0" \
  "$(field "$SAME" "data['pairs'][0]['ratio']" --pair fg:bg)"

echo "=== C. the 4.5:1 normal-text boundary ==="
# Asserted on passes_aa_normal ONLY. Both fixtures clear 3:1, so an assertion
# on passes_aa_large would return true for both and grade nothing.

ABOVE_45="$(palette above45 '{"fg":"#767676","bg":"#FFFFFF"}')"
BELOW_45="$(palette below45 '{"fg":"#777777","bg":"#FFFFFF"}')"

assert_ratio "cc06-above-aa-normal-ratio" "4.5422" \
  "$(field "$ABOVE_45" "data['pairs'][0]['ratio']" --pair fg:bg)"
assert_eq "cc06-above-aa-normal" "True" \
  "$(field "$ABOVE_45" "data['pairs'][0]['passes_aa_normal']" --pair fg:bg)"

assert_ratio "cc07-below-aa-normal-ratio" "4.4781" \
  "$(field "$BELOW_45" "data['pairs'][0]['ratio']" --pair fg:bg)"
assert_eq "cc07-below-aa-normal" "False" \
  "$(field "$BELOW_45" "data['pairs'][0]['passes_aa_normal']" --pair fg:bg)"

echo "=== D. the 3:1 large-text boundary ==="
# Asserted on passes_aa_large ONLY. Both fixtures fail 4.5:1, so an assertion
# on passes_aa_normal would return false for both and grade nothing.

ABOVE_30="$(palette above30 '{"fg":"#949494","bg":"#FFFFFF"}')"
BELOW_30="$(palette below30 '{"fg":"#959595","bg":"#FFFFFF"}')"

assert_ratio "cc08-above-aa-large-ratio" "3.0335" \
  "$(field "$ABOVE_30" "data['pairs'][0]['ratio']" --large-pair fg:bg)"
assert_eq "cc08-above-aa-large" "True" \
  "$(field "$ABOVE_30" "data['pairs'][0]['passes_aa_large']" --large-pair fg:bg)"

assert_ratio "cc09-below-aa-large-ratio" "2.9953" \
  "$(field "$BELOW_30" "data['pairs'][0]['ratio']" --large-pair fg:bg)"
assert_eq "cc09-below-aa-large" "False" \
  "$(field "$BELOW_30" "data['pairs'][0]['passes_aa_large']" --large-pair fg:bg)"

echo "=== E. threshold semantics ==="

# The comparison is inclusive and runs against the unrounded ratio, so a pair
# landing marginally above 4.5 must not be rounded down into a failure.
assert_eq "cc10-threshold-is-inclusive" "True" \
  "$(field "$ABOVE_45" "data['pairs'][0]['passes']" --pair fg:bg)"

assert_eq "cc11-threshold-reported" "4.5" \
  "$(field "$BELOW_45" "data['pairs'][0]['threshold']" --pair fg:bg)"
assert_eq "cc12-large-threshold-reported" "3.0" \
  "$(field "$BELOW_30" "data['pairs'][0]['threshold']" --large-pair fg:bg)"

echo "=== F. suggested replacement hex ==="

SUGGESTED="$(field "$BELOW_45" "data['pairs'][0].get('suggested_hex')" --pair fg:bg)"
if [ -n "$SUGGESTED" ] && [ "$SUGGESTED" != "None" ]; then
  pass "cc13-failure-carries-suggestion"
else
  fail "cc13-failure-carries-suggestion"
  printf '  expected a suggested_hex on a below-AA pair, got %s\n' "$SUGGESTED"
fi

# The suggestion must itself clear the threshold when fed back through the
# script — otherwise the advice is a guess wearing a script's clothes.
ROUNDTRIP_VERDICT="no-suggestion"
if [ -n "$SUGGESTED" ] && [ "$SUGGESTED" != "None" ]; then
  ROUNDTRIP="$(palette roundtrip "{\"fg\":\"$SUGGESTED\",\"bg\":\"#FFFFFF\"}")"
  ROUNDTRIP_VERDICT="$(field "$ROUNDTRIP" "data['pairs'][0]['passes_aa_normal']" --pair fg:bg)"
fi
if [ "$ROUNDTRIP_VERDICT" = "True" ]; then
  pass "cc14-suggestion-round-trips"
else
  fail "cc14-suggestion-round-trips"
  printf '  suggested %s did not clear 4.5:1 on re-check (got %s)\n' "$SUGGESTED" "$ROUNDTRIP_VERDICT"
fi

assert_eq "cc15-passing-pair-has-no-suggestion" "None" \
  "$(field "$ABOVE_45" "data['pairs'][0].get('suggested_hex')" --pair fg:bg)"

# This pair fails 4.5 (ratio 2.7422) and its clearing shade is an ENDPOINT.
# suggest_hex used to return None here, and not because the hue was unreachable:
# the -1 walk never cleared (best 4.4883 UNSNAPPED near #030303, which itself
# re-scores 4.4762 once snapped), and the +1 walk cleared unsnapped at lightness
# 0.99 (4.5084) only to be rejected by the module's own snapped re-verification
# (#FCFCFC re-scores 4.4910). Both true endpoints clear -- #000000 = 4.5578,
# #FFFFFF = 4.6075 -- but the accumulating `candidate_lightness += direction *
# step` terminates at -3.1e-17 and 1.0000000000000007, so the range guard broke
# one step short of pure black and pure white and neither was ever scored.
# Scoring the endpoints is what turned this case from present-and-null into
# present-and-black; the pre-fix fixture comment pre-declared that red as an
# intentional behaviour change.
#
# Two consequences worth recording here, because this block is where they are
# observable.
#
# (1) Direction tie-break. -1 is scored before +1, so the black endpoint now
#     wins a tie it used to lose by never being reached. Over the same
#     46,656-pair sweep the issue itself used -- 6 levels per channel,
#     {0,51,102,153,204,255}, 216 colours, all ordered fg/bg pairs -- 21 pairs
#     go None -> a hex at 4.5 (0 at 3.0), reproducing the issue's own count,
#     and a further 194 of 38,594 below-AA pairs at 4.5 (0.503%) plus 300 of
#     31,652 at 3.0 (0.948%) that ALREADY had a suggestion now get a different
#     one -- always becoming #000000, displacing a near-white shade at 4.5
#     (e.g. fg #050505 on bg #757575 goes #FFFFFF -> #000000) and a
#     mid-lightness one at 3.0 (lowest observed #B2B300, L=0.351). Every such
#     answer is still re-verified after snapping, so what changed is which of
#     two clearing shades is offered, not whether it clears. BELOW_45 (cc13/cc14) is
#     unaffected: #747474 before and after.
#
# (2) Reachability of the None arm. For any background the two endpoint ratios
#     multiply to 21 in exact arithmetic -- ((L+0.05)/0.05) * (1.05/(L+0.05)) --
#     so the larger is always at least sqrt(21) ~= 4.583. Both thresholds this
#     CLI exposes (AA_NORMAL 4.5, AA_LARGE 3.0) sit below that, so no palette
#     run can reach the arm. It is NOT dead code: threshold is a parameter, and
#     a value strictly above ~4.583 still reaches it, which is what cc33 pins.
#     Strictly above -- at exactly sqrt(21) the `>=` comparison still clears.
# NULL_SUGGESTION and the nullsuggestion slug keep their names on purpose: this
# fg/bg pair IS the None-arm pair, the one cc33 drives at threshold 21.0 to reach
# the arm. Renaming it for the 4.5 answer below would sever that cc31-cc33 link
# and retire the token a later concept-grep would search the arm by.
NULL_SUGGESTION="$(palette nullsuggestion '{"fg":"#333333","bg":"#757575"}')"

assert_ratio "cc31-endpoint-suggestion-ratio" "2.7422" \
  "$(field "$NULL_SUGGESTION" "data['pairs'][0]['ratio']" --pair fg:bg)"

# Present-and-BLACK, NOT the absent key cc15 pins: evaluate_pair sets
# suggested_hex only when the pair fails, so post-fix a bare .get() would already
# discriminate here -- '#000000' present against None absent. The membership test
# is co-asserted anyway so that an evaluate_pair regression which stops emitting
# the key names itself (False in the tuple) rather than surfacing as an
# empty capture: field() indexes directly, so a missing key raises KeyError and
# prints nothing. data['evaluated'] is co-asserted as in cc28.
assert_eq "cc31-endpoint-suggestion-is-present-and-black" "(True, '#000000', 1)" \
  "$(field "$NULL_SUGGESTION" "('suggested_hex' in data['pairs'][0], data['pairs'][0]['suggested_hex'], data['evaluated'])" --pair fg:bg)"

# A failing pair with a suggestion is data, not an error. This deliberately bypasses field(),
# which reads payload.get('data') and DISCARDS payload['success'] -- same
# inline-python idiom as cc17, keeping --pair fg:bg so all three assertions
# grade the same invocation.
assert_eq "cc31-endpoint-suggestion-envelope-succeeds" "(True, True)" \
  "$(python3 "$SCRIPT" "$NULL_SUGGESTION" --pair fg:bg 2>/dev/null | python3 -c "
import json, sys
payload = json.load(sys.stdin)
print((payload['success'], 'fg on bg' in payload['data']['failures']))" 2>/dev/null)"

# cc32/cc33 need a DIRECT call: the None arm's reachability is not observable
# through a palette run at all, for the reason recorded in section F above, and
# the white endpoint's decisiveness -- though observable there -- cannot be
# ISOLATED from the stepped walk by one. Loading the module by path is safe --
# check-contrast.py guards its entry point behind __main__ --
# and uses the same spec_from_file_location idiom as test-sanitize-theme.sh. The
# verdict still routes through assert_eq, so each case emits a paired PASS/FAIL
# id for scripts/check-case-id-pairing.py rather than a one-armed fail.
suggest_call() {
  python3 - "$SCRIPT" "$1" "$2" "$3" <<'PYX' 2>/dev/null
import importlib.util, sys
spec = importlib.util.spec_from_file_location("cc", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
print(mod.suggest_hex(mod.parse_hex(sys.argv[2]), mod.parse_hex(sys.argv[3]), float(sys.argv[4])))
PYX
}

# The L=1.0 endpoint IS decisive at the CLI thresholds -- neither endpoint is
# privileged. By section F (2) whichever one fails, the other necessarily clears,
# and it is often white that does: fg #000033 on bg #3366FF at 4.5 answers
# #FFFFFF, black scoring 4.4853 and FAILING where white scores 4.682. What a
# palette run cannot do is ISOLATE that endpoint from the stepped walk preceding
# it. A direct call can: against a BLACK background only pure white reaches 21.0,
# and the walk's best snapped candidate there is 20.4689 at #FCFCFC (measured),
# so a threshold of 21.0 isolates the exact endpoint and nothing else. Pre-fix
# this returned None, so the case is genuinely red at base rather than vacuously
# green.
assert_eq "cc32-white-endpoint-is-suggested" "#FFFFFF" \
  "$(suggest_call '#333333' '#000000' 21.0)"

# The None arm is still reachable, so retiring it would have removed live code.
# Against #757575 the endpoints score 4.5578 and 4.6075, both far below 21, so
# the arm is genuinely reached. This case is green at base AND post-fix by
# design: it pins the arm's continued reachability, not the endpoint fix, and its
# teeth come from the fourth mutation recipe above rather than from this
# assertion flipping.
assert_eq "cc33-null-arm-is-reachable-above-sqrt21" "None" \
  "$(suggest_call '#333333' '#757575' 21.0)"

echo "=== G. palette handling ==="

# A tier-0 theme's palette is hand-built from theme.md prose, so the script has
# to work from an arbitrary flat map with no manifest and no tokens file.
TIER0="$(palette tier0 '{"primary":"#111111","background":"#FAFAF8","surface":"#FFFFFF","text":"#111111","text-muted":"#6B7280"}')"
EVALUATED="$(field "$TIER0" "data['evaluated']")"
if [ "$EVALUATED" -gt 0 ] 2>/dev/null; then
  pass "cc16-tier0-palette-evaluated"
else
  fail "cc16-tier0-palette-evaluated"
  printf '  expected at least one default pair, got %s\n' "$EVALUATED"
fi

# The shipped _template palette is all #HEXHEX placeholders. That is not an
# error — it is a theme the user has not filled in yet.
PLACEHOLDER="$(palette placeholder '{"primary":"#HEXHEX","background":"#HEXHEX"}')"
assert_eq "cc17-placeholder-palette-is-not-an-error" "True" \
  "$(python3 "$SCRIPT" "$PLACEHOLDER" 2>/dev/null | python3 -c "
import json, sys
print(json.load(sys.stdin)['success'])" 2>/dev/null)"
assert_eq "cc18-placeholder-palette-reports-unparsed" "2" \
  "$(field "$PLACEHOLDER" "len(data['unparsed'])")"

echo "=== H. error paths ==="

python3 "$SCRIPT" "$TMPROOT/definitely-absent.json" >/dev/null 2>&1
if [ "$?" -ne 0 ]; then
  pass "cc19-missing-palette-exits-nonzero"
else
  fail "cc19-missing-palette-exits-nonzero"
  echo "  a missing palette should be an operational failure"
fi

python3 "$SCRIPT" "$TIER0" --pair nosuchrole:background >/dev/null 2>&1
if [ "$?" -ne 0 ]; then
  pass "cc20-unknown-role-exits-nonzero"
else
  fail "cc20-unknown-role-exits-nonzero"
  echo "  a pair naming an absent role should be an operational failure"
fi

# A below-AA finding is data, not an error: the run still succeeds.
python3 "$SCRIPT" "$BELOW_45" --pair fg:bg >/dev/null 2>&1
if [ "$?" -eq 0 ]; then
  pass "cc21-below-aa-is-a-finding-not-an-error"
else
  fail "cc21-below-aa-is-a-finding-not-an-error"
  echo "  a failing contrast pair must not make the run exit non-zero"
fi

echo "=== I. role vocabulary and the no-silent-drop contract ==="
# The vocabulary has to track the role names this repo's themes actually carry.
# A role the palette defines but the vocabulary does not classify forms no
# default pair, parses as valid hex so it never reaches data.unparsed, and
# leaves data.evaluated non-zero -- so without data.unclassified a partial
# audit is indistinguishable from a clean one.

STATUS="$(palette status '{"danger":"#D32F2F","bg":"#FAFAF8","text":"#111111"}')"
assert_eq "cc22-danger-is-evaluated" "True" \
  "$(field "$STATUS" "'danger' in [p['foreground'] for p in data['pairs']]")"

CUSTOM="$(palette custom '{"brand-blurple":"#5865F2","bg":"#FFFFFF","text":"#111111"}')"
assert_eq "cc23-unknown-role-surfaces" "(True, False)" \
  "$(field "$CUSTOM" "('brand-blurple' in data['unclassified'], 'brand-blurple' in [p['foreground'] for p in data['pairs']])")"

# 'error' was in the vocabulary and in no theme artifact in this repo; 'danger'
# is the canonical status role. Pin the removal so it cannot drift back.
PHANTOM="$(palette phantom '{"error":"#D32F2F","bg":"#FFFFFF"}')"
assert_eq "cc24-error-is-not-a-role" "True" \
  "$(field "$PHANTOM" "'error' in data['unclassified']")"

# The regression pin: every role of the repo's own shipped theme must classify.
# A role added to that palette without reconciling the vocabulary reds this.
CANONICAL="$WS_ROOT/themes/cogni-work/tokens/colors.json"
if [ -f "$CANONICAL" ]; then
  LEFTOVER="$(field "$CANONICAL" "data['unclassified']")"
  if [ "$LEFTOVER" = "[]" ]; then
    pass "cc25-canonical-theme-fully-classified"
  else
    fail "cc25-canonical-theme-fully-classified"
    printf '  shipped theme carries roles the vocabulary does not classify: %s\n' "$LEFTOVER"
  fi
else
  fail "cc25-canonical-theme-fully-classified"
  printf '  expected the shipped theme palette at %s\n' "$CANONICAL"
fi

# The property above must hold on the narrow --pair path too, not just the
# default full-palette route every case so far has taken. The asserted role is
# deliberately NOT the one being graded: asserting on the graded role would be
# satisfiable by the request itself rather than by unconditional emission.
# data['evaluated'] is co-asserted, and indexed directly rather than via .get,
# so a run that formed no pair at all cannot read as a pass.
assert_eq "cc28-unclassified-survives-the-pair-path" "(True, 1)" \
  "$(field "$CUSTOM" "('brand-blurple' in data.get('unclassified', []), data['evaluated'])" --pair text:bg)"

# Two spellings that normalise onto one role: the survivor is reported, and so
# is every key it supersedes. Ids cc28-cc30 land here rather than after section
# J's cc26/cc27 to keep them beside the contract they pin -- the pairing guard
# matches red ids against a set of green ids and mutation-check.sh anchors on
# the printed label, so neither reads file order. Do not renumber.
COLLIDE="$(palette collide '{"Text":"#111111","text":"#EEEEEE","bg":"#FFFFFF","Brand X":"#5865F2","brand x":"#NOTHEX"}')"

assert_eq "cc29-normalisation-collision-is-surfaced" "[('text', 'text', '#EEEEEE', 'Text'), ('brand x', 'brand x', '#NOTHEX', 'Brand X')]" \
  "$(field "$COLLIDE" "[(c['role'], c['superseded_key'], c['superseded_value'], c['kept_key']) for c in data['collisions']]")"

# The cross-dict shape: 'Brand X' parses, 'brand x' does not. Before the group
# pass the role appeared in BOTH buckets at once, so the envelope contradicted
# itself. One group now assigns to exactly one dict.
assert_eq "cc30-usable-and-unparsed-are-disjoint" "(True, False)" \
  "$(field "$COLLIDE" "('brand x' in data['roles'], 'brand x' in data['unparsed'])")"

echo "=== J. luminance is reported, never used to filter ==="

assert_eq "cc26-pair-carries-luminances" "(1.0, 0.0)" \
  "$(field "$WHITE_ON_BLACK" "(data['pairs'][0]['fg_luminance'], data['pairs'][0]['bg_luminance'])" --pair fg:bg)"

# Dark text on a dark surface is a pairing the theme does not intend, but the
# script does not know that and must not guess: the pair is still evaluated and
# still reported as a failure. Judging intent belongs to the caller.
SAME_POLARITY="$(palette samepolarity '{"text":"#111111","surface-dark":"#111111"}')"
assert_eq "cc27-same-polarity-failure-is-reported" "True" \
  "$(field "$SAME_POLARITY" "'text on surface-dark' in data['failures']")"

echo
if [ "$failures" -eq 0 ]; then
  echo "All check-contrast tests passed."
  exit 0
else
  echo "$failures test(s) failed."
  exit 1
fi
