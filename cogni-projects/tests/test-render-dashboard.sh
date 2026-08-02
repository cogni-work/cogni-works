#!/usr/bin/env bash
# Test render-dashboard.py — the partner-meeting portfolio dashboard renderer.
#
# Covers the three acceptance criteria:
#   AC-1: every project is listed with fill status + a health flag,
#   AC-2: an aggregate portfolio value/impact summary is shown,
#   AC-3: a missing field / role-label mismatch degrades to a partial snapshot
#         (success stays true, a warning surfaces) rather than hard-failing.
#
# stdlib-only (bash + python3, no pytest/pip), matching the house convention.
#
# Usage: bash cogni-projects/tests/test-render-dashboard.sh
# Exits non-zero on any assertion failure.

set -u  # NOT -e: a failing assertion must not abort the per-fixture counter.

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/render-dashboard.py"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: render-dashboard.py not found at $SCRIPT" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf 'OK   %s\n' "$1"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

# assert_json <label> <python-bool-expr over `d`> — pipes the last stdout line
# (the envelope) into python3 and checks the expression is truthy.
assert_json() {
  local label="$1" expr="$2"
  if printf '%s' "$LAST_JSON" | python3 -c "import json,sys
d = json.loads(sys.stdin.read())
sys.exit(0 if ($expr) else 1)" 2>/dev/null; then
    pass "$label"
  else
    fail "$label" "expr false: $expr | json=$LAST_JSON"
  fi
}

assert_html() {
  local label="$1" needle="$2" file="$3"
  if grep -qF "$needle" "$file"; then
    pass "$label"
  else
    fail "$label" "HTML missing needle: $needle ($file)"
  fi
}

# The negative counterpart — used by every "this must not have been injected"
# check, which would otherwise be hand-rolled per fixture.
assert_html_lacks() {
  local label="$1" needle="$2" file="$3"
  if grep -qF "$needle" "$file"; then
    fail "$label" "HTML unexpectedly contains: $needle ($file)"
  else
    pass "$label"
  fi
}

# Every "the renderer degraded instead of crashing" fixture needs this, and the
# crash signature belongs in one place — widening it later should be one edit.
assert_no_traceback() {
  local label="$1" file="$2"
  if grep -qF 'Traceback' "$file"; then
    fail "$label" "traceback present: $(head -3 "$file")"
  else
    pass "$label"
  fi
}

seed_portfolio() {
  # $1 = portfolio dir. Seeds a manifest + entity subdirs.
  local pf="$1"
  mkdir -p "$pf"/{consultants,projects,assignments,.metadata}
  cat > "$pf/projects-portfolio.json" <<'EOF'
{"slug":"test","name":"Test Portfolio","language":"en","consultants":[],"projects":[],"assignments":[],"created":"2026-01-01","updated":"2026-01-01"}
EOF
}

write_entity() { # $1 = path, $2 = frontmatter body (heredoc'd by caller)
  cat > "$1"
}

# run [args...] — invoke the renderer with any arguments (including none) and
# capture the last stdout line, which is the envelope, into LAST_JSON.
run() {
  LAST_JSON="$(python3 "$SCRIPT" "$@" 2>/dev/null | tail -n 1)"
}

# ---------------------------------------------------------------------------
# Fixture 1 — happy path: two projects, one partly staffed, one unstaffed.
# AC-1 (fill + health) and AC-2 (value aggregate).
# ---------------------------------------------------------------------------
PF1="$TMPROOT/happy"
seed_portfolio "$PF1"
write_entity "$PF1/projects/nordic-erp.md" <<'EOF'
---
type: project
slug: nordic-erp
name: Nordic Retail ERP
client: Nordic Retail
strategic_impact: 5
status: active
open_roles: [erp-lead, integration-architect, change-lead]
---
# Nordic Retail ERP
EOF
write_entity "$PF1/projects/small-audit.md" <<'EOF'
---
type: project
slug: small-audit
name: Compliance Audit
client: FinCo
strategic_impact: 2
status: active
open_roles: [auditor]
---
# Compliance Audit
EOF
write_entity "$PF1/consultants/mara.md" <<'EOF'
---
type: consultant
slug: mara
name: Mara Lindqvist
seniority: principal
skills: [erp, integration]
allocation_pct: 80
---
# Mara
EOF
write_entity "$PF1/assignments/mara--nordic-erp.md" <<'EOF'
---
type: assignment
slug: mara--nordic-erp
consultant: mara
project: nordic-erp
role: erp-lead
start_date: 2026-02-01
end_date: 2026-08-01
status: active
---
# assignment
EOF

run "$PF1"
HTML1="$PF1/output/dashboard.html"
assert_json "1a envelope success"        "d['success'] is True"
assert_json "1b two projects counted"    "d['data']['projects'] == 2"
assert_json "1c not partial (clean)"     "d['data']['partial'] is False"
assert_json "1d no warnings"             "d['data']['warnings'] == []"
assert_json "1e open roles = 3"          "d['data']['open_roles'] == 3"
assert_html "1f AC-1 lists project"      "Nordic Retail ERP" "$HTML1"
assert_html "1g AC-1 lists other project" "Compliance Audit" "$HTML1"
assert_html "1h AC-1 fill status shown"  "1/3" "$HTML1"
assert_html "1i AC-1 health flag shown"  "unstaffed" "$HTML1"
assert_html "1j AC-2 value section"      "strategic impact" "$HTML1"
# Narrate-step envelope fields: projects_detail + value_by_impact are surfaced
# on stdout so the skill can name at-risk projects and the impact grouping
# without parsing the HTML. json.dumps stringifies the int impact keys.
assert_json "1k envelope carries projects_detail"        "len(d['data']['projects_detail']) == 2"
assert_json "1l projects_detail carries per-project health" "all('health_label' in p and 'health_sev' in p for p in d['data']['projects_detail'])"
assert_json "1m envelope carries value_by_impact"        "d['data']['value_by_impact']['5'] == 1 and d['data']['value_by_impact']['2'] == 1"

# ---------------------------------------------------------------------------
# Fixture 2 — idempotent re-render: running twice rewrites the same file and
# stays successful (no accumulation, no state mutation).
# ---------------------------------------------------------------------------
run "$PF1"
assert_json "2a re-render success"       "d['success'] is True"
assert_json "2b re-render still 2 projects" "d['data']['projects'] == 2"
# The manifest must not have been touched by the read-only render.
if grep -qF '"consultants":[]' "$PF1/projects-portfolio.json"; then
  pass "2c manifest untouched (read-only)"
else
  fail "2c manifest untouched (read-only)" "manifest changed"
fi

# ---------------------------------------------------------------------------
# Fixture 3 — AC-3 graceful degradation: a project missing strategic_impact and
# an assignment whose role does not match any open_roles label. The render must
# still succeed with a partial snapshot and surfaced warnings.
# ---------------------------------------------------------------------------
PF3="$TMPROOT/partial"
seed_portfolio "$PF3"
write_entity "$PF3/projects/broken.md" <<'EOF'
---
type: project
slug: broken
name: Broken Project
client: X
status: active
open_roles: [ERP Lead]
---
# broken (no strategic_impact; open_roles label differs in case)
EOF
write_entity "$PF3/consultants/ana.md" <<'EOF'
---
type: consultant
slug: ana
name: Ana Ström
seniority: senior
skills: [erp]
---
# Ana
EOF
write_entity "$PF3/assignments/ana--broken.md" <<'EOF'
---
type: assignment
slug: ana--broken
consultant: ana
project: broken
role: erp-lead
start_date: 2026-02-01
end_date: 2026-08-01
status: active
---
# assignment (role erp-lead != open_roles "ERP Lead")
EOF

run "$PF3"
assert_json "3a AC-3 still succeeds"     "d['success'] is True"
assert_json "3b AC-3 marked partial"     "d['data']['partial'] is True"
assert_json "3c AC-3 has warnings"       "len(d['data']['warnings']) >= 2"
assert_json "3d AC-3 warns on missing impact" \
  "any('strategic_impact' in w for w in d['data']['warnings'])"
assert_json "3e AC-3 warns on label mismatch" \
  "any('label mismatch' in w for w in d['data']['warnings'])"
assert_html "3f AC-3 warnings rendered"  "partial snapshot" "$PF3/output/dashboard.html"

# ---------------------------------------------------------------------------
# Fixture 4 — missing manifest is a clean failure envelope, not a traceback.
# ---------------------------------------------------------------------------
PF4="$TMPROOT/no-manifest"
mkdir -p "$PF4"
run "$PF4"
assert_json "4a missing manifest fails cleanly" "d['success'] is False"
assert_json "4b failure names the manifest"     "'manifest' in d['error']"

# ---------------------------------------------------------------------------
# Fixture 5 — HTML-injection guard: an entity value with markup is escaped.
# ---------------------------------------------------------------------------
PF5="$TMPROOT/xss"
seed_portfolio "$PF5"
write_entity "$PF5/projects/evil.md" <<'EOF'
---
type: project
slug: evil
name: "<script>alert(1)</script>"
client: X
strategic_impact: 3
status: active
open_roles: [lead]
---
# evil
EOF
run "$PF5"
assert_json "5a injection render succeeds" "d['success'] is True"
assert_html_lacks "5b entity markup escaped" \
  '<script>alert(1)</script>' "$PF5/output/dashboard.html"

# ---------------------------------------------------------------------------
# Fixture 6 — genuinely malformed entities, not merely incomplete ones: a
# type-invalid strategic_impact, a project omitting open_roles entirely, and a
# non-UTF-8 entity file. Each must degrade to a warning while the valid project
# still renders. Fixture 3 covers only well-formed-but-incomplete data, which is
# why a decode failure could abort the whole render without tripping the suite.
# ---------------------------------------------------------------------------
PF6="$TMPROOT/malformed"
seed_portfolio "$PF6"
write_entity "$PF6/projects/good.md" <<'EOF'
---
type: project
slug: good
name: Valid Project
client: GoodCo
strategic_impact: 4
status: active
open_roles: [lead]
---
# good
EOF
write_entity "$PF6/projects/typed-wrong.md" <<'EOF'
---
type: project
slug: typed-wrong
name: Type Invalid
client: X
strategic_impact: high
status: active
open_roles: [lead]
---
# strategic_impact is a word, not 1..5
EOF
write_entity "$PF6/projects/no-roles.md" <<'EOF'
---
type: project
slug: no-roles
name: Roles Omitted
client: Y
strategic_impact: 4
status: active
---
# open_roles key absent entirely — staffing status is unknown, not zero
EOF
# The same unknown state reached by a different authoring shape: the key is
# present but carries no value. This must not read as "declares no roles".
write_entity "$PF6/projects/bare-roles.md" <<'EOF'
---
type: project
slug: bare-roles
name: Roles Blank
client: Y2
strategic_impact: 3
status: active
open_roles:
---
# open_roles present but empty — still unknown, not an assertion of zero
EOF
# A genuinely non-UTF-8 file: a latin-1 encoded byte that is invalid UTF-8.
# Written via python3 because bash printf parses a leading '---' as options.
python3 -c "
import sys
open(sys.argv[1], 'wb').write(
    '---\ntype: project\nslug: latin1\nname: Caf\xe9 Rollout\nstatus: active\n---\n'.encode('latin-1')
)" "$PF6/projects/latin1.md"

STDERR6="$TMPROOT/stderr6.txt"
LAST_JSON="$(python3 "$SCRIPT" "$PF6" 2>"$STDERR6" | tail -n 1)"

assert_json "6a malformed set still succeeds"  "d['success'] is True"
assert_json "6b marked partial"                "d['data']['partial'] is True"
# The undecodable file is skipped; the four parseable projects still render.
assert_json "6c valid projects still counted"  "d['data']['projects'] == 4"
assert_json "6d warns on non-numeric impact" \
  "any('strategic_impact' in w for w in d['data']['warnings'])"
# Both the absent key and the bare-scalar shape must reach the unknown state.
assert_json "6e warns on unknown staffing (both shapes)" \
  "sum('staffing status unknown' in w for w in d['data']['warnings']) == 2"
assert_json "6f warns on undecodable file" \
  "any('cannot read' in w and 'latin1' in w for w in d['data']['warnings'])"
assert_no_traceback "6g no traceback on stderr" "$STDERR6"
assert_html "6h unknown staffing flagged in HTML" \
  "staffing unknown" "$PF6/output/dashboard.html"

# A project omitting open_roles must NOT render with the same ok severity as a
# project that explicitly declares none — that collapse is what made an
# unstaffed project look healthy.
assert_html_lacks "6i absent roles not shown as 'no open roles'" \
  'no open roles' "$PF6/output/dashboard.html"

# ---------------------------------------------------------------------------
# Fixture 7 — the {success,data,error} envelope is printed on every path,
# including an argparse usage error (SystemExit is a BaseException and would
# otherwise escape the top-level handler, leaving stdout empty).
# ---------------------------------------------------------------------------
run
assert_json "7a no-args still prints envelope" "d['success'] is False"
assert_json "7b no-args error names usage"     "'usage' in d['error']"
assert_json "7c usage names the real argument" "'portfolio_dir' in d['error']"

# ---------------------------------------------------------------------------
# Fixture 8 — a design-variables value that would break out of the <style>
# block is rejected in favour of the built-in palette rather than interpolated.
# ---------------------------------------------------------------------------
PF8="$TMPROOT/theme"
seed_portfolio "$PF8"
write_entity "$PF8/projects/plain.md" <<'EOF'
---
type: project
slug: plain
name: Plain Project
client: Z
strategic_impact: 3
status: active
open_roles: [lead]
---
# plain
EOF
cat > "$TMPROOT/evil-theme.json" <<'EOF'
{"bg": "#000</style><script>alert(1)</script>", "accent": "#ff0000"}
EOF
run "$PF8" --design-variables "$TMPROOT/evil-theme.json"
assert_json "8a themed render succeeds" "d['success'] is True"
assert_html_lacks "8b unsafe theme value rejected" \
  '<script>alert(1)</script>' "$PF8/output/dashboard.html"
assert_html "8c safe theme value still applied" "#ff0000" "$PF8/output/dashboard.html"

# A url() value is CSS-valid but would make the self-contained HTML fetch an
# external resource (phone-home beacon) on open. Parentheses are denied, so it
# is rejected in favour of the built-in palette rather than interpolated.
cat > "$TMPROOT/beacon-theme.json" <<'EOF'
{"bg": "url(https://evil.example/track.png)", "accent": "#00ff88"}
EOF
run "$PF8" --design-variables "$TMPROOT/beacon-theme.json"
assert_json "8d beacon render succeeds" "d['success'] is True"
assert_html_lacks "8e url() beacon theme value rejected" \
  'evil.example' "$PF8/output/dashboard.html"
assert_html "8f safe accent still applied alongside rejected url()" \
  "#00ff88" "$PF8/output/dashboard.html"

# Fixture 9 — a closed project's declared roles are not open demand. The closed
# project stays visible in the table with its flag (9g/9h); only the headline
# figure drops it, so a shrinking total is not a vanished project. 9c and 9f are
# a pair because the envelope and the HTML tile are separate call sites in the
# renderer — fixing one alone would ship a dashboard that disagrees with itself,
# so asserting only one of them would let that regression through.
PF9="$TMPROOT/closed"
seed_portfolio "$PF9"
write_entity "$PF9/projects/live-crm.md" <<'EOF'
---
type: project
slug: live-crm
name: Live CRM Rollout
client: Northwind
strategic_impact: 4
status: active
open_roles: [crm-lead]
---
# Live CRM Rollout
EOF
write_entity "$PF9/projects/legacy-migration.md" <<'EOF'
---
type: project
slug: legacy-migration
name: Legacy Migration
client: Northwind
strategic_impact: 3
status: closed
open_roles: [migration-lead, data-engineer]
---
# Legacy Migration
EOF
run "$PF9"
HTML9="$PF9/output/dashboard.html"
assert_json "9a closed-portfolio render succeeds" "d['success'] is True"
assert_json "9b closed project still counted as a project" "d['data']['projects'] == 2"
assert_json "9c open roles exclude the closed project" "d['data']['open_roles'] == 1"
assert_json "9d closed project emits no warning" "d['data']['warnings'] == []"
assert_json "9e clean snapshot" "d['data']['partial'] is False"
assert_html "9f tile agrees with the envelope" \
  '<div class="n">1</div><div class="l">Open roles</div>' "$HTML9"
assert_html "9g closed project still listed" "Legacy Migration" "$HTML9"
assert_html "9h closed health flag still rendered" ">closed</span>" "$HTML9"

# ---------------------------------------------------------------------------
# Fixture 10 — a status that is not text. The frontmatter parser coerces an
# all-digit scalar to an int before any enum check runs, so `status: 2026`
# reached a str method and raised, and the module-level catch-all then threw
# away every warning collected so far — one hand-edited record cost the whole
# dashboard. 10c and 10d are a pair: `2026` used to crash while `0` is *falsy*
# and used to normalize silently to "unknown", so a guard keyed on truthiness
# rather than on None would pass one and fail the other.
# ---------------------------------------------------------------------------
PF10="$TMPROOT/nonstring-status"
seed_portfolio "$PF10"
write_entity "$PF10/projects/numeric-status.md" <<'EOF'
---
type: project
slug: numeric-status
name: Numeric Status
client: NumCo
strategic_impact: 3
status: 2026
open_roles: [lead]
---
# Numeric Status
EOF
write_entity "$PF10/projects/zero-status.md" <<'EOF'
---
type: project
slug: zero-status
name: Zero Status
client: ZeroCo
strategic_impact: 2
status: 0
open_roles: [lead]
---
# Zero Status
EOF
write_entity "$PF10/projects/sound.md" <<'EOF'
---
type: project
slug: sound
name: Sound Delivery
client: SoundCo
strategic_impact: 4
status: active
open_roles: [architect]
---
# Sound Delivery
EOF
# `project: sound` must name a real project — _compute filters on the project
# before it reads an assignment's status, so an orphan assignment would never
# reach the coercion and the fixture would pass against the unfixed script.
write_entity "$PF10/assignments/numeric-assignment.md" <<'EOF'
---
type: assignment
slug: rena--sound
consultant: rena
project: sound
role: architect
start_date: 2026-02-01
end_date: 2026-08-01
status: 1
---
# assignment
EOF

# The shared run() helper discards stderr, so invoke directly the way Fixture 6
# does — 10g asserts on the absence of a traceback.
STDERR10="$TMPROOT/stderr10.txt"
LAST_JSON="$(python3 "$SCRIPT" "$PF10" 2>"$STDERR10" | tail -n 1)"

assert_json "10a non-string status still succeeds" "d['success'] is True"
assert_json "10b marked partial"                   "d['data']['partial'] is True"
assert_json "10c falsy int status still warns" \
  "any('non-string status' in w and 'Zero Status' in w for w in d['data']['warnings'])"
assert_json "10d project surfaced by name" \
  "any('non-string status' in w and 'Numeric Status' in w for w in d['data']['warnings'])"
# The assignment is named by its relative path — _read_entities sets _file on
# every kept entity, while slug is optional frontmatter. Counted for the same
# reason 11c/11d are: this read sits inside _compute's per-project slug filter,
# and hoisting it out would warn once per project while `any(...)` stayed green.
assert_json "10e assignment surfaced by file, exactly once" \
  "sum('non-string status' in w and 'numeric-assignment.md' in w for w in d['data']['warnings']) == 1"
assert_json "10f every project still counted"      "d['data']['projects'] == 3"
assert_no_traceback "10g no traceback on stderr" "$STDERR10"
# A needle without quote characters: warnings reach the HTML through _esc, which
# rewrites the quotes %r puts around a value.
assert_html "10h healthy project still rendered" \
  "Sound Delivery" "$PF10/output/dashboard.html"

# ---------------------------------------------------------------------------
# Fixture 11 — a role label that is not text. The same parse-time int coercion
# that hit `status` reaches `role`, and lands harder: _compute sorts the
# covered-role set, and Python refuses to order a str against an int, so one
# `role: 2` next to any text role raised and cost the whole render.
#
# 11c and 11d are the truthy/falsy pair, mirroring 10c/10d — a guard keyed on
# truthiness rather than on None would let `role: 0` through unremarked.
#
# 11f, 11g and 11k are the symmetry guard, and they are the reason this fixture
# carries a second project. `open_roles` entries are coerced by the same parser,
# so stringifying only the assignment side would fix the crash and introduce
# something quieter: `symmetry`'s numeric role matches its numeric open_roles
# entry today, and would stop matching, reporting a filled role as open. With
# only one side coerced, 11f reads 1 instead of 0.
#
# The third project is clean throughout, and 11h/11l are its pair: they assert a
# bad record costs neither the project count nor the render of an untouched
# project — the same claim Fixture 10 makes with Sound Delivery at 10f/10h.
# Both of this fixture's other projects are bad-record demonstrations, so
# without it nothing here checks that resilience.
# ---------------------------------------------------------------------------
PF11="$TMPROOT/nonstring-role"
seed_portfolio "$PF11"
write_entity "$PF11/projects/mixed.md" <<'EOF'
---
type: project
slug: mixed
name: Mixed Roles
client: MixCo
strategic_impact: 3
status: active
open_roles: [lead]
---
# Mixed Roles
EOF
write_entity "$PF11/projects/symmetry.md" <<'EOF'
---
type: project
slug: symmetry
name: Symmetry Check
client: SymCo
strategic_impact: 2
status: active
open_roles: [2026]
---
# Symmetry Check
EOF
write_entity "$PF11/projects/clean.md" <<'EOF'
---
type: project
slug: clean
name: Clean Delivery
client: CleanCo
strategic_impact: 4
status: active
open_roles: [architect]
---
# Clean Delivery
EOF
# Every assignment names a project that exists — _compute filters on the
# project before it reads the role, so an orphan would never reach the
# coercion and the fixture would pass against the unfixed script. `active` is
# in ACTIVE_ASSIGNMENT_STATES, so these genuinely reach the role read.
write_entity "$PF11/assignments/numeric-role.md" <<'EOF'
---
type: assignment
slug: ada--mixed
consultant: ada
project: mixed
role: 2
start_date: 2026-02-01
end_date: 2026-08-01
status: active
---
# assignment
EOF
write_entity "$PF11/assignments/text-role.md" <<'EOF'
---
type: assignment
slug: bo--mixed
consultant: bo
project: mixed
role: lead
start_date: 2026-02-01
end_date: 2026-08-01
status: active
---
# assignment
EOF
write_entity "$PF11/assignments/zero-role.md" <<'EOF'
---
type: assignment
slug: cy--mixed
consultant: cy
project: mixed
role: 0
start_date: 2026-02-01
end_date: 2026-08-01
status: active
---
# assignment
EOF
write_entity "$PF11/assignments/symmetry-role.md" <<'EOF'
---
type: assignment
slug: di--symmetry
consultant: di
project: symmetry
role: 2026
start_date: 2026-02-01
end_date: 2026-08-01
status: active
---
# assignment
EOF
# Text role matching the declared open_roles entry, so `clean` contributes no
# open role and 11f/11k stay at 0 — the clean project has to be genuinely
# clean, or it would perturb the very counts the symmetry guard pins.
write_entity "$PF11/assignments/clean-role.md" <<'EOF'
---
type: assignment
slug: eli--clean
consultant: eli
project: clean
role: architect
start_date: 2026-02-01
end_date: 2026-08-01
status: active
---
# assignment
EOF

# Direct invoke for the same reason Fixture 10 does it — run() discards stderr
# and 11i asserts a traceback never reached it.
STDERR11="$TMPROOT/stderr11.txt"
LAST_JSON="$(python3 "$SCRIPT" "$PF11" 2>"$STDERR11" | tail -n 1)"
HTML11="$PF11/output/dashboard.html"

assert_json "11a non-string role still succeeds" "d['success'] is True"
assert_json "11b marked partial"                 "d['data']['partial'] is True"
# Counted, not merely present: the role read sits inside _compute's per-project
# slug filter, so each offending assignment must warn exactly once. Moving that
# read outside the filter would warn once per project iteration instead — a
# regression `any(...)` cannot see, because the warning is still there.
assert_json "11c non-string role surfaced by file, exactly once" \
  "sum('non-string role' in w and 'numeric-role.md' in w for w in d['data']['warnings']) == 1"
assert_json "11d falsy zero role still warns, exactly once" \
  "sum('non-string role' in w and 'zero-role.md' in w for w in d['data']['warnings']) == 1"
assert_json "11e non-string open_roles entry surfaced by project" \
  "any('non-string open_roles entry' in w and 'Symmetry Check' in w for w in d['data']['warnings'])"
assert_json "11f numeric role still fills its numeric open_role" \
  "d['data']['open_roles'] == 0"
# Scoped to Symmetry Check on purpose — Mixed Roles legitimately reports its
# coerced '0' and '2' roles as matching no open_roles label.
assert_json "11g symmetric match raises no mismatch warning" \
  "not any('matches no open_roles label' in w and 'Symmetry Check' in w for w in d['data']['warnings'])"
assert_json "11h every project still counted"    "d['data']['projects'] == 3"
assert_no_traceback "11i no traceback on stderr" "$STDERR11"
assert_html "11j symmetry project still rendered" "Symmetry Check" "$HTML11"
assert_html "11k open-roles tile agrees with the envelope" \
  '<div class="n">0</div><div class="l">Open roles</div>' "$HTML11"
assert_html "11l clean sibling project still rendered" "Clean Delivery" "$HTML11"

echo
if [ "$failures" -eq 0 ]; then
  echo "All render-dashboard tests passed."
  exit 0
fi
echo "$failures assertion(s) failed." >&2
exit 1
