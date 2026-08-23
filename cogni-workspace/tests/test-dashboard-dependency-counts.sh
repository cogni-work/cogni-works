#!/usr/bin/env bash
# Regression test for the workspace-dashboard Health Snapshot's Dependencies row
# (_check_dependencies in skills/workspace-dashboard/scripts/generate-dashboard.py).
#
# Contract under test: the row's counts are derived from the payload
# check-dependencies.sh actually emits — data.dependencies[], one entry per tool,
# each {name, available, required, version} — partitioned on each entry's own
# `required` flag. The row must be FALSIFIABLE: a required tool reporting
# available:false has to surface a non-ok label and a truthful n/m with n < m.
# A row that renders a constant count is the defect this suite exists to catch,
# so the all-present direction is pinned to NON-ZERO totals as well: asserting
# only "ok" would pass against a permanently-0/0 reader.
#
# Every case drives the real renderer against a STUB emitter under its own temp
# root. That is deliberate and not a convenience: jq and python3 are present on
# any dev or CI host, so a case running the real script would render "2/2
# required, ok" and stay green against the broken reader too. No production seam
# is needed — _check_dependencies derives its script path from its own
# workspace_root argument, so pointing it at a temp tree is sufficient.
#
# Paths are self-located from $0, never the working directory: the repo runner
# invokes suites with cwd=<repo root> and the mutation harness with cwd=$ROOT,
# so a cwd-relative path here would be a latent false result.
#
# stdlib-only: bash + python3, no pip deps, per the repo-wide script convention.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
RENDERER="$WS_ROOT/skills/workspace-dashboard/scripts/generate-dashboard.py"
SECTIONS="$WS_ROOT/skills/workspace-dashboard/references/dashboard-sections.md"
EMITTER="$WS_ROOT/scripts/check-dependencies.sh"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

# new_root <name> — build a temp workspace root holding a stub emitter at the
# exact relative path _check_dependencies derives, and echo the root.
new_root() {
  local name="$1"
  local root="$TMPROOT/$name"
  mkdir -p "$root/cogni-workspace/scripts"
  cat > "$root/cogni-workspace/scripts/check-dependencies.sh" <<STUB
#!/usr/bin/env bash
cat "$root/fixture.json"
STUB
  printf '%s' "$root"
}

# assert_dep "<label>" "<root>" "<python expr, True to pass>" — the renderer is
# bound as \`r\` and the returned tuple as \`res\`. A raised exception exits the
# driver non-zero, so "does not raise" is asserted by the case passing at all.
assert_dep() {
  local label="$1" root="$2" expr="$3"
  if python3 - "$RENDERER" "$root" <<PY
import importlib.util, sys
def _load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m); return m
r = _load("r", sys.argv[1])
res = r._check_dependencies(sys.argv[2])
sys.exit(0 if ($expr) else 1)
PY
  then pass "$label"; else fail "$label"; fi
}

# assert_degrades "<label>" "<root>" — a malformed payload must come back as a
# warning tuple rather than raising. One definition, so tightening the
# degradation contract is a single edit rather than three that can diverge.
assert_degrades() {
  assert_dep "$1" "$2" 'isinstance(res, tuple) and len(res) == 2 and res[0] == "warning"'
}

# --- D1: all present. --------------------------------------------------------
D1ROOT="$(new_root d1)"
cat > "$D1ROOT/fixture.json" <<'JSON'
{"success": true, "data": {"dependencies": [
  {"name": "jq", "available": true, "required": true, "version": "jq-1.7.1"},
  {"name": "python3", "available": true, "required": true, "version": "Python 3.14.2"},
  {"name": "curl", "available": true, "required": false, "version": "curl 8.7.1"},
  {"name": "git", "available": true, "required": false, "version": "git 2.50.1"},
  {"name": "bc", "available": true, "required": false, "version": "bc 7.0.3"}
], "missing_required": 0, "missing_optional": 0}}
JSON
assert_dep "D1 all present renders ok with truthful non-zero totals" "$D1ROOT" \
  'res[0] == "ok" and res[1] == "2/2 required, 3/3 optional"'

# --- D2: THE discriminating case, and the recorded mutation --case target. ---
# Both operands are asserted, which is what a constant renderer cannot satisfy.
D2ROOT="$(new_root d2)"
cat > "$D2ROOT/fixture.json" <<'JSON'
{"success": false, "data": {"dependencies": [
  {"name": "jq", "available": false, "required": true, "version": null},
  {"name": "python3", "available": true, "required": true, "version": "Python 3.14.2"},
  {"name": "curl", "available": true, "required": false, "version": "curl 8.7.1"},
  {"name": "git", "available": true, "required": false, "version": "git 2.50.1"},
  {"name": "bc", "available": true, "required": false, "version": "bc 7.0.3"}
], "missing_required": 1, "missing_optional": 0}}
JSON
assert_dep "D2 absent required tool renders non-ok with a truthful n of m" "$D2ROOT" \
  'res[0] != "ok" and res[1] == "1/2 required, 3/3 optional"'

# --- D3: an optional tool is absent. Required side is whole, so still ok. ----
D3ROOT="$(new_root d3)"
cat > "$D3ROOT/fixture.json" <<'JSON'
{"success": true, "data": {"dependencies": [
  {"name": "jq", "available": true, "required": true, "version": "jq-1.7.1"},
  {"name": "python3", "available": true, "required": true, "version": "Python 3.14.2"},
  {"name": "curl", "available": true, "required": false, "version": "curl 8.7.1"},
  {"name": "git", "available": false, "required": false, "version": null},
  {"name": "bc", "available": true, "required": false, "version": "bc 7.0.3"}
], "missing_required": 0, "missing_optional": 1}}
JSON
assert_dep "D3 absent optional tool stays ok and counts the optional miss" "$D3ROOT" \
  'res[0] == "ok" and res[1] == "2/2 required, 2/3 optional"'

# --- D4-D6: malformed payloads DEGRADE, they do not raise. -------------------
# The old reader could not raise because .get(..., {}) defaulted; the new read
# has to earn that back. An exception here exits the driver non-zero and fails
# the case, so "returns a 2-tuple without raising" is what is being asserted.
D4ROOT="$(new_root d4)"
cat > "$D4ROOT/fixture.json" <<'JSON'
{"success": true, "data": {"missing_required": 0, "missing_optional": 0}}
JSON
assert_degrades "D4 absent dependencies key degrades to a warning tuple" "$D4ROOT"

D5ROOT="$(new_root d5)"
cat > "$D5ROOT/fixture.json" <<'JSON'
{"success": true, "data": {"dependencies": {"jq": {"available": true, "required": true}}}}
JSON
assert_degrades "D5 dependencies as a mapping degrades to a warning tuple" "$D5ROOT"

D6ROOT="$(new_root d6)"
cat > "$D6ROOT/fixture.json" <<'JSON'
{"success": true, "data": {"dependencies": ["jq", null, "python3"]}}
JSON
assert_degrades "D6 non-mapping dependency entries degrade to a warning tuple" "$D6ROOT"

# --- D7: the wrong-key reads are gone from the renderer entirely. ------------
# grep -F, because both needles carry regex metacharacters.
if grep -qF 'data.get("required"' "$RENDERER" || grep -qF 'data.get("optional"' "$RENDERER"; then
  fail "D7 renderer no longer reads the keys the emitter never sets"
else
  pass "D7 renderer no longer reads the keys the emitter never sets"
fi

# --- D8: the documentation twin no longer describes the wrong shape. ---------
# Whole-file, not just the one edited line: a second mention elsewhere would let
# the next reader re-derive the bug from the docs.
if grep -qE 'data\.required|data\.optional' "$SECTIONS"; then
  fail "D8 sections reference documents the emitted shape"
elif grep -qF 'data.dependencies[]' "$SECTIONS"; then
  pass "D8 sections reference documents the emitted shape"
else
  fail "D8 sections reference documents the emitted shape"
fi

# --- D9: the emitter's own contract, pinned from the consumer side. ----------
# SHAPE ONLY, never availability. The real script's last statement is its
# heredoc, so it exits 0 on every host; a runner missing jq or bc merely flips an
# entry's `available`, which is why an availability assertion here would be
# environment-fragile while a shape assertion is not.
if python3 - "$EMITTER" <<'PY'
import json, subprocess, sys
proc = subprocess.run(["bash", sys.argv[1]], capture_output=True, text=True, timeout=30)
if proc.returncode != 0 or not proc.stdout.strip():
    sys.exit(1)
data = json.loads(proc.stdout).get("data", {})
deps = data.get("dependencies")
ok = (
    isinstance(deps, list)
    and len(deps) > 0
    and all(isinstance(d, dict) and {"name", "available", "required"} <= set(d) for d in deps)
    and any(d["required"] for d in deps)
    and any(not d["required"] for d in deps)
    and isinstance(data.get("missing_required"), int)
    and isinstance(data.get("missing_optional"), int)
)
sys.exit(0 if ok else 1)
PY
then pass "D9 emitter still emits the shape this reader depends on"
else fail "D9 emitter still emits the shape this reader depends on"; fi

# --- D10: the same fixture, end to end through the real renderer. ------------
# D1-D6 stop at the private function, which leaves two links unpinned: that
# health_snapshot still calls it, and that the label reaches the dot's CSS
# class. "Green dot forever" is a property of the rendered page, so one case
# asserts it there. Reuses D2's root, so no new fixture is needed.
D10OUT="$D2ROOT/out.html"
if python3 "$RENDERER" "$D2ROOT" --output "$D10OUT" >"$TMPROOT/d10-render.json" 2>"$TMPROOT/d10-render.err"; then
  if grep -qF '1/2 required, 3/3 optional' "$D10OUT" && grep -qF 'health-dot danger' "$D10OUT"; then
    pass "D10 rendered page shows the truthful count and a non-ok dot"
  else
    fail "D10 rendered page shows the truthful count and a non-ok dot"
  fi
else
  fail "D10 rendered page shows the truthful count and a non-ok dot"
fi

echo
if [ "$failures" -eq 0 ]; then
  echo "All dashboard dependency-count tests passed."
  exit 0
else
  echo "$failures test(s) failed."
  exit 1
fi
