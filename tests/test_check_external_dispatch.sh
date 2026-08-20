#!/usr/bin/env bash
# test_check_external_dispatch.sh — self-test for the external-dispatch guard.
#
# The guard asserts a HARD clean-zero: no live-dispatch surface
# (*/skills/*/SKILL.md, */agents/*.md, */commands/*.md, */hooks/**) may carry a
# dispatch token for a prefix listed in scripts/retired-plugins.json. Cases:
#   1. Negative controls (bare noun "cogni-research" with no colon) -> exit 0.
#   2. Dispatch-laden fixture (cogni-wiki: + cogni-research:) -> exit 1, naming
#      the file + line + match.
#   3. Inline-allow escape hatch -> the flagged line is skipped.
#   4. Path exclusions (cogni-knowledge/ history, */wiki/ mirror) skipped in
#      discover mode -> exit 0 even though the token is present.
#   5. Real tree -> exit 0 (clean-zero today).
#
# Registry-loading cases (the retired set is data, not source):
#   R1. Missing registry     -> exit 2, never a silent clean-zero.
#   R2. Malformed JSON       -> exit 2.
#   R3. Empty prefix list    -> exit 2.
#   R4. Non-string / blank / padded / colon-bearing entry -> exit 2.
#   R5. A prefix added to the registry makes a planted dispatch fire -> exit 1.
#   R6. --registry REPLACES the default file rather than unioning with it.
#
# R1-R4 are the anti-vacuity trio-plus-one: each asserts a NON-ZERO exit on an
# input where a guard that ignored the registry would exit 0, so none of them can
# pass against an implementation that does not actually load it. They reach that
# state by staging a COPY of the guard with (or without) a sibling registry rather
# than by passing --registry, precisely so the assertion is behavioural — a
# --registry-based case would go red merely because an older argparse rejects the
# unknown flag, which proves nothing about the load path.
#
# bash 3.2 + stdlib python3 only (+ git for the discover-mode exclusion case).
#
# Result-line ids: every emitted PASS:/FAIL: line carries a first-token id,
# unique PER EMITTED LINE rather than per logical case, so
# `mutation-check.sh --case <id>` addresses exactly one assertion. Every id in
# this file is `edNN`: `ed01`-`ed09` for cases 1-5, `ed10`-`ed19` for the
# registry cases R1-R6 (R1 -> ed10/ed11, R2 -> ed12/ed13, R3 -> ed14,
# R4 -> ed15, R5 -> ed16/ed17, R6 -> ed18/ed19). `R1`-`R6` remain the names of
# the LOGICAL case groups in the header notes and the section dividers below;
# they are not ids and must never be emitted as one. Never introduce an
# `R<n><letter>` id here: tests/test_check_mcp_tool_grant.sh already emits
# `R1a`, `R2a`, `R3a`, `R4a` and `R6a` among its own result lines, so an
# `R`-stemmed id in this file would be ambiguous in any harness run whose
# `--test` captures both suites. The whole-token matching rule the ids depend
# on is stated once, with the regex, above the registry cases below. A new
# assertion takes the next free id — `ed20` onward — never a renumbering and
# never an `R`-stemmed id.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-external-dispatch.py"

# Plain, uncoloured result lines — unconditionally, matching the harness-parsable
# suites elsewhere in the repo. A result line must start with the literal `PASS:` /
# `FAIL:` so a mutation harness can classify it with `^[[:space:]]*FAIL:[[:space:]]+`;
# an ANSI escape sequence precedes the label and defeats that match. Deciding by
# `[ -t 1 ]` instead would make parsability environment-dependent — run the suite
# under a pty and the colour, and the failure, come back.
red()   { printf '%s\n' "$1"; }
green() { printf '%s\n' "$1"; }

FAILED=0
check() {  # check <label> <condition-exit-code>
  if [ "$2" -eq 0 ]; then
    green "PASS: $1"
  else
    red "FAIL: $1"
    FAILED=1
  fi
}

assert_json() {  # assert_json <label> <json> <python-asserts>
  set +e
  printf '%s' "$2" | python3 -c "$3"
  local _code=$?
  set -e
  check "$1" "$_code"
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------------------
# Case 1 — negative control: a bare "cogni-research" noun (no colon) is fine.
# ---------------------------------------------------------------------------
mkdir -p "$WORK/clean/cogni-demo/skills/demo"
cat > "$WORK/clean/cogni-demo/skills/demo/SKILL.md" <<'EOF'
---
name: demo
---
Modeled on the cogni-research verify-report skill, scoped to demo data.
This plugin dispatches cogni-knowledge:knowledge-query, not the retired engines.
EOF

set +e
OUT=$(python3 "$GUARD" --root "$WORK/clean" "cogni-demo/skills/demo/SKILL.md" 2>/dev/null)
CODE=$?
set -e
check "ed01 bare-noun negative control exits 0" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "ed02 negative control reports zero violations" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
"

# ---------------------------------------------------------------------------
# Case 2 — dispatch-laden fixture: must fail, naming file + line + match.
# ---------------------------------------------------------------------------
mkdir -p "$WORK/dirty/cogni-bad/agents"
cat > "$WORK/dirty/cogni-bad/agents/bad.md" <<'EOF'
First the agent dispatches Skill("cogni-wiki:wiki-query") to read the base.
Then it falls back to cogni-research:section-researcher for fresh web work.
EOF

set +e
OUT=$(python3 "$GUARD" --root "$WORK/dirty" "cogni-bad/agents/bad.md" 2>/dev/null)
CODE=$?
set -e
check "ed03 dispatch fixture exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ed04 dispatch fixture names both tokens with correct file+line" "$OUT" "
import json,sys
d=json.load(sys.stdin)
v=d['data']['violations']
got={(x['match'],x['line']) for x in v}
want={('cogni-wiki:',1),('cogni-research:',2)}
missing=want-got
assert not missing, 'missing: %r (got %r)' % (missing, got)
assert all(x['file']=='cogni-bad/agents/bad.md' for x in v), v
assert d['success'] is False, d
"

# ---------------------------------------------------------------------------
# Case 3 — inline-allow escape hatch skips an otherwise-flagged line.
# ---------------------------------------------------------------------------
mkdir -p "$WORK/allow/cogni-x/commands"
cat > "$WORK/allow/cogni-x/commands/c.md" <<'EOF'
Historical note: this menu mirrors cogni-research:verify-report's Next steps.  # external-dispatch-guard:allow
EOF

set +e
OUT=$(python3 "$GUARD" --root "$WORK/allow" "cogni-x/commands/c.md" 2>/dev/null)
CODE=$?
set -e
check "ed05 inline-allow line exits 0" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "ed06 inline-allow suppresses the dispatch token" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['data']['summary']['total']==0, d['data']['summary']
"

# ---------------------------------------------------------------------------
# Case 4 — discover-mode path exclusions: a token under cogni-knowledge/ (FMO
# history) or */wiki/ (generated mirror) must NOT trip the guard.
# ---------------------------------------------------------------------------
EXC="$WORK/exclude"
mkdir -p "$EXC"
git -C "$EXC" init -q
git -C "$EXC" config user.email t@t.test
git -C "$EXC" config user.name test
mkdir -p "$EXC/cogni-knowledge/skills/k" "$EXC/cogni-foo/wiki/concepts" "$EXC/cogni-foo/skills/s"
# cogni-knowledge legitimately NAMES the retired engines as history:
printf -- '---\nname: k\n---\nDelegation history: this once dispatched cogni-wiki:wiki-ingest.\n' \
  > "$EXC/cogni-knowledge/skills/k/SKILL.md"
# a generated wiki mirror page may quote a retired dispatch as page content:
printf -- '---\nname: x\n---\nThe source quoted cogni-research:section-researcher.\n' \
  > "$EXC/cogni-foo/wiki/concepts/SKILL.md"
# a genuinely-clean live surface in the same repo:
printf -- '---\nname: s\n---\nDispatches cogni-knowledge:knowledge-compose only.\n' \
  > "$EXC/cogni-foo/skills/s/SKILL.md"
git -C "$EXC" add -A >/dev/null 2>&1
git -C "$EXC" commit -qm init >/dev/null 2>&1

set +e
OUT=$(python3 "$GUARD" --root "$EXC" 2>/dev/null)
CODE=$?
set -e
check "ed07 discover-mode exclusions pass (cogni-knowledge/ + */wiki/ skipped)" \
  "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "ed08 exclusions report zero violations" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
"

# ---------------------------------------------------------------------------
# Case 5 — real tree: the guard passes clean-zero today.
# ---------------------------------------------------------------------------
set +e
python3 "$GUARD" >/dev/null 2>&1
CODE=$?
set -e
check "ed09 real tree passes clean-zero" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"

# ===========================================================================
# Registry-loading cases (R1-R6; emitted ids ed10-ed19).
#
# Case labels below are `<id> <description>` — an id token followed by a SPACE,
# never a colon abutting the id. The mutation harness matches
# `^[[:space:]]*FAIL:[[:space:]]+<case>([[:space:]]|$)` (and the ok|PASS twin)
# whole-token, so `--case ed14` matches `FAIL: ed14 empty ...` while `--case 'ed14:'`
# would match neither line and return case_not_found instead of a verdict.
# ===========================================================================

# stage_guard <name> — copy the REAL guard into "$WORK/<name>/" and echo the path.
# A copy, taken at run time, is what makes these cases meaningful under mutation:
# a vendored snippet would keep testing a frozen implementation while the actual
# script drifted. The staged copy's registry default resolves to its own sibling
# "$WORK/<name>/retired-plugins.json", which the caller writes (or deliberately
# omits) per case.
stage_guard() {
  mkdir -p "$WORK/$1"
  cp "$GUARD" "$WORK/$1/check-external-dispatch.py"
  printf '%s' "$WORK/$1/check-external-dispatch.py"
}

# run_reg <name> <registry-json|NONE> <rel-file> [extra guard args...] — stage a
# guard copy, give it (or deny it) a sibling registry, run it, and leave the result
# in $OUT / $CODE. Each case keeps its own check/assert_json label, so the per-case
# `<id> <description>` targeting above is unaffected.
run_reg() {
  local g; g=$(stage_guard "$1")
  [ "$2" = NONE ] || printf '%s' "$2" > "$WORK/$1/retired-plugins.json"
  local rel="$3"; shift 3
  set +e
  OUT=$(python3 "$g" "$@" --root "$REG_TREE" "$rel" 2>/dev/null)
  CODE=$?
  set -e
}

# A clean live surface plus a planted one, shared by R1-R6. The clean file
# deliberately carries an ordinary word-colon token (`name: demo` frontmatter):
# under the empty-registry mutant the compiled alternation degenerates to
# `\b(?:):`, which matches exactly that shape — so R3 goes red because the mutant
# demonstrably fires, not incidentally because nothing was scanned.
REG_TREE="$WORK/regtree"
mkdir -p "$REG_TREE/cogni-demo/agents"
cat > "$REG_TREE/cogni-demo/agents/clean.md" <<'EOF'
---
name: demo
---
Dispatches cogni-knowledge:knowledge-query only.
EOF
cat > "$REG_TREE/cogni-demo/agents/planted.md" <<'EOF'
---
name: planted
---
First the agent dispatches cogni-demo:demo-skill to read the base.
EOF
CLEAN_REL="cogni-demo/agents/clean.md"
PLANTED_REL="cogni-demo/agents/planted.md"

# --- R1: missing registry -> exit 2, never a silent clean-zero -------------
# Also proves the default registry path follows __file__ and not --root: --root
# points at REG_TREE, which has no registry, and the staged dir has none either.
run_reg r1 NONE "$CLEAN_REL"
check "ed10 missing registry exits 2 (base exits 0 here)" \
  "$([ "$CODE" -eq 2 ] && echo 0 || echo 1)"
assert_json "ed11 missing registry reports success:false and names the path" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
assert d['error'], d
assert 'retired-plugins.json' in d['error'], d['error']
"

# --- R2: malformed JSON -> exit 2 ------------------------------------------
run_reg r2 '{"retired_prefixes": ["cogni-wiki",' "$CLEAN_REL"
check "ed12 malformed registry JSON exits 2 (base exits 0 here)" \
  "$([ "$CODE" -eq 2 ] && echo 0 || echo 1)"
assert_json "ed13 malformed registry reports success:false with a non-empty error" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
assert d['error'], d
"

# --- R3: empty prefix list -> exit 2 ---------------------------------------
# Kept as its own case rather than folded into R4's table: the recorded mutation
# recipe targets `--case ed14`, which needs a separately-labelled line.
run_reg r3 '{"retired_prefixes": []}' "$CLEAN_REL"
check "ed14 empty registry exits 2 and never 0 (base exits 0 here)" \
  "$([ "$CODE" -eq 2 ] && echo 0 || echo 1)"

# --- R4: wrong type / non-string / blank / padded / colon-bearing -> exit 2 -
# The padded variant is the subtlest of the set: it survives the non-empty test
# (it strips to a real prefix) but re.escape would compile the UNSTRIPPED text
# into `\ \ cogni\-demo\ \ :`, which matches nothing — a clean-zero exit 0 from a
# registry that looks populated. Rejecting mirrors the colon-bearing entry rather
# than quietly repairing it.
R4_FAILED=0
R4_N=0
for BAD in \
  '{"retired_prefixes": "cogni-wiki"}' \
  '{"retired_prefixes": ["cogni-wiki", 7]}' \
  '{"retired_prefixes": ["cogni-wiki", "   "]}' \
  '{"retired_prefixes": ["cogni-wiki", "  cogni-demo  "]}' \
  '{"retired_prefixes": ["cogni-wiki:"]}' \
  '{"nothing_here": true}'
do
  R4_N=$((R4_N + 1))
  run_reg "r4_$R4_N" "$BAD" "$CLEAN_REL"
  [ "$CODE" -eq 2 ] || R4_FAILED=1
done
check "ed15 degenerate registry entries all exit 2 ($R4_N variants)" "$R4_FAILED"

# --- R5: a prefix added to the registry makes a planted dispatch fire -------
# The data-driven proof: base's hardcoded regex knows nothing of cogni-demo.
run_reg r5 '{"retired_prefixes": ["cogni-wiki", "cogni-research", "cogni-demo"]}' \
  "$PLANTED_REL"
check "ed16 registry-added prefix fires on a planted dispatch (exit 1)" \
  "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ed17 registry-added prefix reports match cogni-demo: with file+line" "$OUT" "
import json,sys
d=json.load(sys.stdin)
v=d['data']['violations']
assert d['success'] is False, d
got={(x['match'],x['line'],x['file']) for x in v}
assert ('cogni-demo:',4,'cogni-demo/agents/planted.md') in got, got
"

# --- R6: --registry REPLACES the default file, never unions with it ---------
# The staged copy's sibling registry lists cogni-demo; the override does not.
# Doubles as the negative control that the compiled alternation is not over-broad.
mkdir -p "$WORK/r6"
printf '%s' '{"retired_prefixes": ["cogni-wiki", "cogni-research"]}' \
  > "$WORK/r6/override.json"
run_reg r6 '{"retired_prefixes": ["cogni-wiki", "cogni-research", "cogni-demo"]}' \
  "$PLANTED_REL" --registry "$WORK/r6/override.json"
check "ed18 --registry replaces the default set rather than unioning (exit 0)" \
  "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "ed19 override set reports zero violations on the planted file" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
"

echo ""
if [ "$FAILED" -eq 0 ]; then
  green "All external-dispatch-guard tests passed."
  exit 0
else
  red "Some external-dispatch-guard tests failed."
  exit 1
fi
