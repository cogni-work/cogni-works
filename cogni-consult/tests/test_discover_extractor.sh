#!/usr/bin/env bash
# Regression test for cogni-consult/scripts/_discover_extractor.py — specifically
# the additive `last_activity` key precomputed from each engagement's
# .metadata/execution-log.json.
#
# Fixtures are heredoc'd inline — no committed JSON blobs to maintain. Each fixture
# builds a minimal engagement in a temp directory and asserts on extract()'s dict.
#
# Coverage:
#   M1   newest-not-last     transitions[] stored out of chronological order →
#                            the newest stamp wins (this is the mutation
#                            falsifier: max() vs transitions[-1])
#   M2   tier b, empty       "transitions": [] → root `updated`
#   M3   tier b, no log      execution-log.json absent → root `updated`
#   M4   tier c              no consult-project.json and no log → "" (key
#                            PRESENT, a str, never None)
#   M5   malformed           invalid JSON bytes → no raise, falls back
#   M6   malformed           "transitions" is an object, not a list → no raise
#   M7   malformed           an entry is a bare string, not a dict → valid
#                            sibling entry still wins
#   M8   malformed           an entry is missing `timestamp` → valid sibling wins
#   M9   malformed           an entry's `timestamp` is not a string → valid
#                            sibling wins
#   M10  isolation           valid consult-project.json + corrupt log → slug /
#                            name / key_question / scope_state still carry their
#                            file-derived values (proves the log read has its own
#                            try/except rather than sharing the existing one)
#   M11  raw shape           a transition-sourced value keeps its full ISO
#                            datetime — no truncation, no normalization
#   M12  raw shape           an `updated`-sourced value keeps its bare ISO date
#   M14  empty stamp        an empty-string timestamp must not shadow the root
#                            `updated` fallback
#   M13  end-to-end          discover-projects.sh --json carries last_activity
#                            through the cogni-workspace host's json.dumps
#
# Usage: bash cogni-consult/tests/test_discover_extractor.sh
# Exits non-zero on any assertion failure.

# `set -u` only — `set -e` would abort on the first failing assertion and defeat
# the per-fixture failure counter below.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/_discover_extractor.py"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: _discover_extractor.py not found at $SCRIPT" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0

# Label shape deviates from the sibling suites' `OK   <name>` / `FAIL <name>:` on
# purpose. cogni-service/scripts/mutation-check.sh classifies a case by scanning
# output for `^[ \t]*FAIL:[ \t]+<case>([ \t]|$)` (RED) and
# `^[ \t]*(ok|PASS):[ \t]+<case>([ \t]|$)` (GREEN) — the inherited shape matches
# neither, so a mutation recipe naming a case here would return case_not_found.
# The match is whole-token, so --case M1 never matches an M10 line — which is
# also why the detail is separated from the case-id by a SPACE and not a colon:
# `FAIL: M1: detail` puts a colon where the harness requires whitespace-or-EOL,
# and a genuinely red case would be misreported as case_not_found.
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

# assert_extract <case> <dir> <python-bool-expr over variable d>
# One interpreter per case: it loads the module by path exactly as the
# cogni-workspace host wrapper does, runs extract(), and evaluates the expression
# over the returned dict in the same process.
#
# Empty stdout means extract() raised — reported as a failure, never silently
# passed. That branch is what proves the "a malformed log never breaks discovery"
# claim rather than merely asserting it.
assert_extract() {
  local case_id="$1" dir="$2" expr="$3"
  local out
  out="$(python3 -c "
import importlib.util, json, sys
spec = importlib.util.spec_from_file_location('extractor', sys.argv[1])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
d = mod.extract(sys.argv[2])
print('PASS' if ($expr) else 'FAIL ' + json.dumps(d))
" "$SCRIPT" "$dir" 2>/dev/null)"
  case "$out" in
    PASS) pass "$case_id" ;;
    "FAIL "*) fail "$case_id" "assertion failed over: ${out#FAIL }" ;;
    *) fail "$case_id" "extract() raised or produced no output for $dir" ;;
  esac
}

# seed_project <dir> [updated] — minimal valid consult-project.json.
seed_project() {
  local dir="$1" updated="${2:-2026-06-21}"
  mkdir -p "$dir"
  cat > "$dir/consult-project.json" <<EOF
{
  "slug": "fixture-engagement",
  "name": "Fixture Engagement",
  "language": "de",
  "key_question": "Wie skalieren wir den Vertrieb?",
  "action_fields": [{"slug": "diagnostic-as-is"}],
  "workflow_state": {"scope": "complete"},
  "plugin_refs": {},
  "updated": "$updated"
}
EOF
}

# seed_log <dir> <raw-body> — write .metadata/execution-log.json verbatim.
seed_log() {
  local dir="$1"
  mkdir -p "$dir/.metadata"
  cat > "$dir/.metadata/execution-log.json"
}

# --- M1: newest transition is NOT the last entry -----------------------------
# The mutation falsifier. Order matters: swapping max(stamps) for stamps[-1]
# returns the 2026-06-28 stamp and this case must go red.
D="$TMPROOT/m1"; seed_project "$D"
seed_log "$D" <<'EOF'
{"transitions": [
  {"action_field": "a", "deliverable": "x", "to": "in-progress", "timestamp": "2026-07-02T09:00:00Z"},
  {"action_field": "a", "deliverable": "y", "to": "complete",    "timestamp": "2026-07-13T08:30:00Z"},
  {"action_field": "a", "deliverable": "z", "to": "in-progress", "timestamp": "2026-06-28T17:00:00Z"}
]}
EOF
assert_extract M1 "$D" "d['last_activity'] == '2026-07-13T08:30:00Z'"

# --- M2: tier (b) — transitions is empty -------------------------------------
# The hot path: engagement-init.sh seeds every new engagement with {"transitions": []}.
D="$TMPROOT/m2"; seed_project "$D" "2026-06-11"
seed_log "$D" <<'EOF'
{"transitions": []}
EOF
assert_extract M2 "$D" "d['last_activity'] == '2026-06-11'"

# --- M3: tier (b) — no execution-log.json at all ------------------------------
D="$TMPROOT/m3"; seed_project "$D" "2026-05-02"
assert_extract M3 "$D" "d['last_activity'] == '2026-05-02'"

# --- M4: tier (c) — no consult-project.json and no log ------------------------
# project['updated'] does not exist on this path, so a project['updated'] lookup
# would KeyError here; the key must still be present and a str.
D="$TMPROOT/m4"; mkdir -p "$D"
assert_extract M4 "$D" "'last_activity' in d and d['last_activity'] == '' and isinstance(d['last_activity'], str)"

# --- M5: malformed — invalid JSON bytes ---------------------------------------
D="$TMPROOT/m5"; seed_project "$D" "2026-04-01"
seed_log "$D" <<'EOF'
{not json at all
EOF
assert_extract M5 "$D" "isinstance(d['last_activity'], str) and d['last_activity'] == '2026-04-01'"

# --- M6: malformed — transitions is an object, not a list ---------------------
D="$TMPROOT/m6"; seed_project "$D" "2026-04-02"
seed_log "$D" <<'EOF'
{"transitions": {"nope": true}}
EOF
assert_extract M6 "$D" "isinstance(d['last_activity'], str) and d['last_activity'] == '2026-04-02'"

# --- M7: malformed — an entry is a bare string, not a dict --------------------
D="$TMPROOT/m7"; seed_project "$D" "2026-04-03"
seed_log "$D" <<'EOF'
{"transitions": [
  "not-a-dict",
  {"timestamp": "2026-07-20T10:00:00Z"}
]}
EOF
assert_extract M7 "$D" "d['last_activity'] == '2026-07-20T10:00:00Z'"

# --- M8: malformed — an entry is missing `timestamp` --------------------------
D="$TMPROOT/m8"; seed_project "$D" "2026-04-04"
seed_log "$D" <<'EOF'
{"transitions": [
  {"action_field": "a", "to": "complete"},
  {"timestamp": "2026-07-21T11:00:00Z"}
]}
EOF
assert_extract M8 "$D" "d['last_activity'] == '2026-07-21T11:00:00Z'"

# --- M9: malformed — an entry's `timestamp` is not a string -------------------
D="$TMPROOT/m9"; seed_project "$D" "2026-04-05"
seed_log "$D" <<'EOF'
{"transitions": [
  {"timestamp": 12345},
  {"timestamp": "2026-07-22T12:00:00Z"}
]}
EOF
assert_extract M9 "$D" "d['last_activity'] == '2026-07-22T12:00:00Z'"

# --- M10: a corrupt log must not suppress the consult-project.json fields -----
# Proves the log read has its OWN try/except. If it were folded into the existing
# block, these four keys would be missing.
D="$TMPROOT/m10"; seed_project "$D" "2026-03-09"
seed_log "$D" <<'EOF'
{"transitions": [ truncated
EOF
assert_extract M10 "$D" "d['slug'] == 'fixture-engagement' and d['name'] == 'Fixture Engagement' and d['key_question'] == 'Wie skalieren wir den Vertrieb?' and d['scope_state'] == 'complete'"

# --- M11: raw shape — a transition-sourced value keeps its full ISO datetime ---
D="$TMPROOT/m11"; seed_project "$D" "2026-06-11"
seed_log "$D" <<'EOF'
{"transitions": [{"timestamp": "2026-07-13T08:30:00Z"}]}
EOF
assert_extract M11 "$D" "d['last_activity'] == '2026-07-13T08:30:00Z'"

# --- M12: raw shape — an `updated`-sourced value keeps its bare ISO date -------
D="$TMPROOT/m12"; seed_project "$D" "2026-06-11"
assert_extract M12 "$D" "d['last_activity'] == '2026-06-11'"

# --- M14: an empty-string timestamp must not shadow the fallback ---------------
# Pins the truthiness arm of the entry filter. Without it max([""]) returns ""
# and the engagement renders as "no activity" despite having a root `updated`.
D="$TMPROOT/m14"; seed_project "$D" "2026-06-11"
seed_log "$D" <<'EOF'
{"transitions": [{"timestamp": ""}]}
EOF
assert_extract M14 "$D" "d['last_activity'] == '2026-06-11'"

# --- M13: end-to-end through the cogni-workspace discovery host ----------------
# Three hermeticity pins, each load-bearing:
#   --root      → only the fixture tree is walked
#   --registry  → the helper's flag loop takes the LAST --registry, so this beats
#                 the wrapper's hardcoded $HOME/.claude/cogni-consult-projects.json;
#                 without it the developer's real engagements join the result and
#                 the count is unstable. The file need not pre-exist.
#   WORKSPACE_PLUGIN_ROOT → the wrapper otherwise prefers an installed
#                 $HOME/.claude/plugins/cache/... copy over the in-repo sibling,
#                 so a stale cache and CI would exercise different code.
# The fixture sits at <root>/cogni-consult/<slug>/ because the wrapper pins
# --find "consult-project.json:*/cogni-consult/*:1" — a flatter layout discovers
# ZERO engagements and every "each entry has last_activity" assertion would pass
# vacuously. The count is asserted first for exactly that reason.
WRAPPER="$PLUGIN_DIR/scripts/discover-projects.sh"
WS_ROOT="$(cd "$PLUGIN_DIR/.." && pwd)/cogni-workspace"
if [ ! -f "$WRAPPER" ]; then
  fail M13 "discover-projects.sh not found at $WRAPPER"
elif [ ! -f "$WS_ROOT/scripts/discover-plugin-projects.sh" ]; then
  printf 'SKIP  M13 (cogni-workspace host not found at %s)\n' "$WS_ROOT"
else
  E2E="$TMPROOT/e2e"
  seed_project "$E2E/cogni-consult/alpha" "2026-01-05"
  seed_log "$E2E/cogni-consult/alpha" <<'EOF'
{"transitions": [
  {"timestamp": "2026-07-02T09:00:00Z"},
  {"timestamp": "2026-08-01T06:15:00Z"},
  {"timestamp": "2026-06-28T17:00:00Z"}
]}
EOF
  seed_project "$E2E/cogni-consult/beta" "2026-02-09"
  e2e_json="$(WORKSPACE_PLUGIN_ROOT="$WS_ROOT" bash "$WRAPPER" \
    --json --root "$E2E" --registry "$TMPROOT/empty-registry.json" 2>/dev/null)"
  if [ -z "$e2e_json" ]; then
    fail M13 "discover-projects.sh --json produced no output"
  else
    verdict="$(printf '%s' "$e2e_json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
ps = d.get('projects', [])
ok = (
    len(ps) == 2
    and all(isinstance(p.get('last_activity'), str) for p in ps)
    and {p['slug']: p['last_activity'] for p in ps}.get('fixture-engagement') is not None
    and sorted(p['last_activity'] for p in ps) == ['2026-02-09', '2026-08-01T06:15:00Z']
)
print('PASS' if ok else 'FAIL')
" 2>/dev/null)"
    if [ "$verdict" = "PASS" ]; then
      pass M13
    else
      fail M13 "envelope did not carry the expected last_activity values: $e2e_json"
    fi
  fi
fi

# --- Summary ------------------------------------------------------------------
if [ "$failures" -eq 0 ]; then
  echo "All _discover_extractor.py tests passed."
  exit 0
else
  echo "$failures assertion(s) failed." >&2
  exit 1
fi
