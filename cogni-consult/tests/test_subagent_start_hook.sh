#!/usr/bin/env bash
# Regression test for cogni-consult/hooks/ — the SubagentStart hook that carries
# the interaction language and the output register into the four consult-* agents.
#
# The failure this guards is silent by construction: the hook script always exits
# 0, and a matcher that never matches produces no error anywhere, so a dead hook
# looks exactly like a healthy one from the outside. The only observable is the
# envelope on stdout and the regex itself — both asserted here.
#
# The matcher is read back out of hooks.json rather than hardcoded, so widening
# the alternation cannot drift from what this test believes it says.
#
# Coverage:
#   1  declaration   exactly one SubagentStart entry, type `command` (required by
#                    Claude Code since 2.1.142), command file present + executable
#   2  bare names    the matcher fullmatches all four bare agent names
#   3  qualified     the matcher fullmatches all four `cogni-consult:`-qualified
#                    names — the form a plugin-supplied agent is dispatched under
#   4  near-misses   a foreign qualification, a suffix near-miss and a bare prefix
#                    are all rejected
#   5  drift guard   the alternation and cogni-consult/agents/ agree in both
#                    directions
#   6  envelope      the hook script emits a valid SubagentStart envelope whose
#                    additionalContext carries the language block and the contract
#
# Usage: bash cogni-consult/tests/test_subagent_start_hook.sh
# Exits non-zero on any assertion failure.

# `set -u` only — `set -e` would abort on the first failing assertion.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
export HOOKS_JSON="$PLUGIN_DIR/hooks/hooks.json"
HOOK_SCRIPT="$PLUGIN_DIR/hooks/on-subagent-start.sh"

if [ ! -f "$HOOKS_JSON" ]; then
  echo "FAIL: hooks.json not found at $HOOKS_JSON" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf 'OK   %s\n' "$1"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

# Derived from disk, never hardcoded: a fifth consult-* agent added to both
# agents/ and the matcher would keep the drift guard green while loops 2 and 3
# silently kept exercising only the original four — the same invisible-drift
# class this file exists to catch, one layer up.
AGENTS="$(cd "$PLUGIN_DIR/agents" && ls consult-*.md 2>/dev/null | sed 's/\.md$//' | tr '\n' ' ')"
if [ -z "${AGENTS// /}" ]; then
  echo "FAIL: no consult-*.md agents found under $PLUGIN_DIR/agents" >&2
  exit 1
fi

# 1 declaration
python3 -c '
import json, os, sys
d = json.load(open(os.environ["HOOKS_JSON"]))
entries = d.get("hooks", {}).get("SubagentStart", [])
if len(entries) != 1:
    sys.exit("expected exactly 1 SubagentStart entry, got %d" % len(entries))
inner = entries[0].get("hooks", [])
if len(inner) != 1:
    sys.exit("expected exactly 1 inner hook, got %d" % len(inner))
if inner[0].get("type") != "command":
    sys.exit("hook type must be command, got %r" % inner[0].get("type"))
if "on-subagent-start.sh" not in (inner[0].get("command") or ""):
    sys.exit("command does not point at on-subagent-start.sh: %r" % inner[0].get("command"))
' && pass "declaration: one command-type SubagentStart entry" \
  || fail "declaration" "hooks.json shape wrong (see above)"

if [ -f "$HOOK_SCRIPT" ] && [ -x "$HOOK_SCRIPT" ]; then
  pass "declaration: hook script present and executable"
else
  fail "declaration" "hook script missing or not executable: $HOOK_SCRIPT"
fi

# Pull the matcher out of hooks.json once; every regex assertion below uses it.
MATCHER="$(python3 -c '
import json, os
print(json.load(open(os.environ["HOOKS_JSON"]))["hooks"]["SubagentStart"][0]["matcher"])
')"

# Assert the matcher fullmatches (or not) a candidate subagent name.
# Args: <name> <candidate> <want: yes|no>
assert_match() {
  local name="$1" candidate="$2" want="$3"
  MATCHER="$MATCHER" CANDIDATE="$candidate" WANT="$want" python3 -c '
import os, re, sys
got = "yes" if re.fullmatch(os.environ["MATCHER"], os.environ["CANDIDATE"]) else "no"
sys.exit(0 if got == os.environ["WANT"] else 1)
' && pass "$name" || fail "$name" "matcher=$MATCHER candidate=$candidate want=$want"
}

# 2 bare names
for a in $AGENTS; do
  assert_match "bare: $a" "$a" yes
done

# 3 plugin-qualified names — the regression this test exists for
for a in $AGENTS; do
  assert_match "qualified: cogni-consult:$a" "cogni-consult:$a" yes
done

# 4 near-misses
assert_match "reject: foreign qualification" "cogni-portfolio:consult-persona-challenger" no
assert_match "reject: suffix near-miss" "consult-dashboard-refresherX" no
assert_match "reject: prefix alone" "cogni-consult:" no

# 5 drift guard — the alternation and agents/ agree in both directions.
# The agent-name group is the LAST alternation group, not the first: the matcher
# opens with an optional `(cogni-consult:)?` prefix group, so a naive
# split-every-alternation-member parse would yield `cogni-consult:` and fail.
MATCHER="$MATCHER" AGENTS_DIR="$PLUGIN_DIR/agents" python3 -c '
import os, re, sys
matcher = os.environ["MATCHER"]
groups = re.findall(r"\(([^)]*)\)", matcher)
names = set(groups[-1].split("|"))
on_disk = {
    f[:-3]
    for f in os.listdir(os.environ["AGENTS_DIR"])
    if f.startswith("consult-") and f.endswith(".md")
}
missing_file = sorted(n for n in names if n not in on_disk)
missing_matcher = sorted(n for n in on_disk if n not in names)
if missing_file or missing_matcher:
    sys.exit("in matcher but no agent file: %r; agent file but not matched: %r"
             % (missing_file, missing_matcher))
' && pass "drift guard: matcher alternation matches agents/" \
  || fail "drift guard" "matcher and agents/ disagree (see above)"

# 6 envelope — run the hook the way Claude Code does.
# CLAUDE_PLUGIN_ROOT must be the real plugin dir: the script swallows a missing
# references/subagent-output-contract.md with a bare `except IOError: pass`, so a
# wrong root yields a truncated envelope and the heading assertions below would
# fail for the wrong reason. PROJECT_AGENTS_OPS_ROOT is unset and cwd is an empty
# temp dir so a developer's real workspace cannot leak into the result.
#
# Assert on the envelope, never the exit status: the script hardcodes exit 0 on
# every path by design, so an exit-code check can never fail.
ENVELOPE="$(cd "$TMPROOT" && env -u PROJECT_AGENTS_OPS_ROOT \
  CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" bash "$HOOK_SCRIPT" 2>/dev/null)"

ENVELOPE="$ENVELOPE" python3 -c '
import json, os, sys
raw = os.environ["ENVELOPE"]
if not raw.strip():
    sys.exit("hook emitted nothing")
d = json.loads(raw)
out = d.get("hookSpecificOutput", {})
if out.get("hookEventName") != "SubagentStart":
    sys.exit("hookEventName=%r" % out.get("hookEventName"))
ctx = out.get("additionalContext") or ""
for heading in ("# Interaction language and output register",
                "## Language (workspace default)",
                "## Audience",
                "## Register"):
    if heading not in ctx:
        sys.exit("additionalContext missing %r" % heading)
' && pass "envelope: valid SubagentStart payload with language block and contract" \
  || fail "envelope" "hook output wrong (see above)"

if [ "$failures" -gt 0 ]; then
  echo "$failures assertion(s) failed" >&2
  exit 1
fi
echo "All SubagentStart hook assertions passed"
