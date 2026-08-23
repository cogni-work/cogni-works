#!/usr/bin/env bash
# Regression test for the workspace-dashboard Health Snapshot's MCP Servers row
# (resolve_mcp_servers + health_snapshot's MCP arm in
# skills/workspace-dashboard/scripts/generate-dashboard.py).
#
# Contract under test: the row's status is derived from what the MCP registry actually
# CONTAINS, not from a count comparison that both sides can satisfy at zero. The registry is
# a cross-file producer (references/mcp-git-registry.json) whose shape nothing else verifies,
# so every way it can drift has to reach a distinguishable non-ok row:
#
#   registry not found      no file, unparseable, or a literal JSON null
#   registry unreadable     parsed, but not the shape this dashboard reads
#   no servers configured   `servers` present, well-formed, and empty
#   n/m installed           at least one entry
#
# The row must be FALSIFIABLE. A reader that renders a constant "0/0 installed" satisfies any
# label-only assertion, so the healthy directions below pin the TOTAL as well: M14 asserts
# 0/2 (not 0/0) for a registry whose servers are all absent, which is the single strongest
# falsifier of the "0/0 forever" defect.
#
# SHAPE ONLY, NEVER HOST AVAILABILITY -- the same discipline as D9 in the sibling suite
# test-dashboard-dependency-counts.sh. No case may depend on what is installed under the
# real ~/.claude/mcp-servers. That is host-dependent, so this suite exports CLAUDE_MCP_DIR to
# an empty fixture tree under $TMPROOT before any case runs: the probe resolves its base from
# that variable (the same spelling install-mcp.sh and patch-desktop-config.py honour), so no
# case can reach the developer's live install directory and determinism is STRUCTURAL rather
# than a naming convention. A case needing a populated base overrides the export explicitly
# and restores it afterwards. Fixtures otherwise use entries whose status is deterministic on
# every host: type "native" with no `platforms` key resolves to "manual", and type "git" with a
# key that cannot exist resolves to "missing".
#
# Cases drive the PRODUCTION read path -- resolve_mcp_servers(root) against a real on-disk
# fixture, or the CLI end to end. Hand-building the server list and calling health_snapshot
# directly would never execute the registry read and would stay green against the unfixed
# reader, which is exactly the vacuity this suite exists to avoid.
#
# Case ids are zero-padded to a uniform width so no id is a prefix of another: the mutation
# harness matches --case as a whole token, and M1 vs M10 is that collision class.
#
# Paths are self-located from $0, never the working directory: the repo runner invokes suites
# with cwd=<repo root> and the mutation harness with cwd=$ROOT, so a cwd-relative path here
# would be a latent false result.
#
# stdlib-only: bash + python3, no pip deps, per the repo-wide script convention.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$WS_ROOT/.." && pwd)"
RENDERER="$WS_ROOT/skills/workspace-dashboard/scripts/generate-dashboard.py"
SECTIONS="$WS_ROOT/skills/workspace-dashboard/references/dashboard-sections.md"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

# Every case probes an EMPTY fixture base by default, so no present or future case can read
# the developer's live ~/.claude/mcp-servers. Cases that need a populated base export over
# this and restore it immediately after their assertion.
MCP_EMPTY="$TMPROOT/mcp-empty"
mkdir -p "$MCP_EMPTY"
export CLAUDE_MCP_DIR="$MCP_EMPTY"

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

# new_root <name> [json] -- build a temp workspace root holding a registry at the exact
# relative path load_mcp_registry derives, and echo the root. Omit the json argument to build
# a root with NO registry file at all.
new_root() {
  local name="$1"
  local root="$TMPROOT/$name"
  mkdir -p "$root/cogni-workspace/references"
  if [ "$#" -ge 2 ]; then
    printf '%s' "$2" > "$root/cogni-workspace/references/mcp-git-registry.json"
  fi
  printf '%s' "$root"
}

# new_mcp_base <name> <relpath-to-start.sh> -- build a temp MCP base directory containing
# exactly one installed wrapper at <relpath>, and echo the base. Used by the cases that pin
# which directory name the probe resolves; the file is touched, never executed.
new_mcp_base() {
  local name="$1" rel="$2"
  local base="$TMPROOT/mcp-$name"
  mkdir -p "$base/$(dirname "$rel")"
  touch "$base/$rel"
  printf '%s' "$base"
}

# assert_mcp "<label>" "<root>" "<python expr, True to pass>" -- the renderer is bound as `r`,
# resolve_mcp_servers' return as `servers` / `status`, and the MCP row dict as `row`. A raised
# exception exits the driver non-zero, so "does not raise" is asserted by the case passing.
assert_mcp() {
  local label="$1" root="$2" expr="$3"
  if python3 - "$RENDERER" "$root" <<PY
import importlib.util, sys
def _load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m); return m
r = _load("r", sys.argv[1])
root = sys.argv[2]
servers, status = r.resolve_mcp_servers(root)
snapshot = r.health_snapshot(root, r.foundation_files(root), [], [], servers, status)
row = [x for x in snapshot if x["name"] == "MCP Servers"][0]
sys.exit(0 if ($expr) else 1)
PY
  then pass "$label"; else fail "$label"; fi
}

# assert_resolve "<label>" "<root>" "<python expr>" -- the resolver alone, with `servers` and
# `status` bound. Separate from assert_mcp because health_snapshot also builds the Dependencies
# row, which shells out to check-dependencies.sh whenever that script exists: a no-op on a temp
# fixture that has none, but a real subprocess on a case pointed at the repo root.
assert_resolve() {
  local label="$1" root="$2" expr="$3"
  if python3 - "$RENDERER" "$root" <<PY
import importlib.util, sys
def _load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m); return m
r = _load("r", sys.argv[1])
servers, status = r.resolve_mcp_servers(sys.argv[2])
sys.exit(0 if ($expr) else 1)
PY
  then pass "$label"; else fail "$label"; fi
}

# assert_cli "<label>" "<root>" <needle>... -- render the root through the real CLI and assert
# the page. A needle prefixed with '!' must be ABSENT. Every case asserts the same baseline:
# exit 0, a non-empty HTML file, and no traceback on stderr. That baseline is the point -- the
# malformed shapes below all RAISED before this fix, writing no HTML and printing no JSON,
# which contradicts the whole-file guarantee in references/dashboard-sections.md ("never error
# out without writing the file"). One helper, so the invocation and that baseline are a single
# edit and no case can quietly drop the traceback check by merging stderr into stdout.
assert_cli() {
  local label="$1" root="$2"; shift 2
  local out="$root/out.html" err="$root/err.txt" needle ok=1
  python3 "$RENDERER" "$root" --output "$out" >/dev/null 2>"$err" || ok=0
  [ -s "$out" ] || ok=0
  if grep -qF 'Traceback' "$err"; then ok=0; fi
  for needle in "$@"; do
    case "$needle" in
      '!'*) if grep -qF -- "${needle#!}" "$out"; then ok=0; fi ;;
      *)    grep -qF -- "$needle" "$out" || ok=0 ;;
    esac
  done
  if [ "$ok" -eq 1 ]; then pass "$label"; else fail "$label"; fi
}

# --- M01: healthy, and deterministic on every host. --------------------------
# type "native" with no `platforms` key resolves to ("manual", "") everywhere, so both
# operands are exact. Asserting the label alone would pass against a constant-0/0 reader.
M01ROOT="$(new_root m01 '{"version":"1.0.0","servers":{"alpha":{"type":"native"},"beta":{"type":"native"}}}')"
assert_mcp "M01 well-formed registry renders ok with a truthful non-zero total" "$M01ROOT" \
  'status == "ok" and len(servers) == 2 and row["label"] == "ok" and row["summary"] == "0/2 installed, 2 manual"'

# --- M02: THE discriminating case, and the recorded mutation --case target. ---
# The issue's own repro: `servers` renamed, so the registry parses but declares nothing this
# reader understands. Three operands in ONE case, so the recorded mutation flips exactly this
# case; the third is the one the mutation falsifies.
M02ROOT="$(new_root m02 '{"version":"1.0.0","description":"x","server_list":{"alpha":{"type":"native"}}}')"
assert_mcp "M02 shape-drifted registry renders non-ok and never 0/0 installed" "$M02ROOT" \
  'row["label"] != "ok" and row["summary"] != "0/0 installed" and row["summary"] == "registry unreadable"'

# --- M03: explicitly empty, which is well-formed but still not health. -------
M03ROOT="$(new_root m03 '{"version":"1.0.0","servers":{}}')"
assert_mcp "M03 registry declaring zero servers renders non-ok" "$M03ROOT" \
  'status == "empty" and row["label"] != "ok" and row["summary"] == "no servers configured"'

# --- M04: the pre-existing missing path, pinned so the refactor cannot move it. --
M04ROOT="$(new_root m04)"
assert_mcp "M04 absent registry file still renders the registry-not-found row" "$M04ROOT" \
  'status == "missing" and servers is None and row["label"] == "warning" and row["summary"] == "registry not found"'

# (No M05: pairwise distinctness of the three non-ok summaries is entailed by M02, M03 and M04
# each asserting its own exact literal, so a separate case adds no falsifier. The id is left
# unused rather than renumbering, which would invalidate the recorded mutation --case.)

# --- M06-M08: the shapes that used to RAISE now degrade, end to end. ---------
M06ROOT="$(new_root m06 '[1,2]')"
assert_cli "M06 a registry whose root is not an object degrades without raising" "$M06ROOT" 'health-dot warning'

M07ROOT="$(new_root m07 '{"servers":[1,2]}')"
assert_cli "M07 a servers key holding a list degrades without raising" "$M07ROOT" 'health-dot warning'

M08ROOT="$(new_root m08 '{"servers":{"alpha":"not-a-mapping"}}')"
assert_cli "M08 a non-mapping server entry degrades without raising" "$M08ROOT" 'health-dot warning'

# --- M09: no-regression for the missing path, through the real renderer. -----
# M04 stops at the private function; this pins that render_mcp's placeholder still reaches the
# page. A fix that collapsed the None and [] states into one sentinel would lose it.
assert_cli "M09 absent registry still emits the Section 4 placeholder and a non-ok dot" \
  "$M04ROOT" 'MCP registry not found in this workspace.' 'health-dot warning'

# --- M10: the drifted fixture, end to end through the real renderer. ---------
# Two operands like the sibling's D10: the negative alone would pass against an empty or
# never-written page. "Green dot forever" is a property of the rendered page, so it is
# asserted there and not only at the function boundary.
assert_cli "M10 rendered page shows the drift summary and never a 0/0 count" \
  "$M02ROOT" 'registry unreadable' 'health-dot warning' '!0/0 installed'

# --- M11: the documentation twin describes the states the code emits. -------
# Positive and negative, whole-file: a second mention of the old model elsewhere would let the
# next reader re-derive the bug from the docs. grep -F, the strings carry no metacharacters.
m11_ok=1
for needle in 'registry not found' 'registry unreadable' 'no servers configured' 'installed'; do
  grep -qF "$needle" "$SECTIONS" || m11_ok=0
done
if grep -qF -e '- MCPs: count from Section 4' "$SECTIONS"; then m11_ok=0; fi
if [ "$m11_ok" -eq 1 ]; then
  pass "M11 sections reference documents the four rendered states"
else
  fail "M11 sections reference documents the four rendered states"
fi

# --- M12: the unguarded inline read has not come back. -----------------------
# Asserted as an ABSENCE only. The presence of a particular call spelling is deliberately not
# asserted: that pins an implementation detail a rename would falsely red, while the behaviour
# it stands for is already covered by M06-M08. The needle is the WHOLE loop line, not the bare
# registry.get("servers", {}) substring, because the recorded mutation reintroduces that
# substring and would otherwise make this case's failure indistinguishable from the mutation's
# own footprint.
if grep -qF 'for key, server in registry.get("servers", {}).items()' "$RENDERER"; then
  fail "M12 the unguarded inline registry read is absent from the renderer"
else
  pass "M12 the unguarded inline registry read is absent from the renderer"
fi

# --- M13: the live registry's own shape, pinned from the consumer side. ------
# The counterpart of the sibling's D9. SHAPE ONLY: the installed COUNT is deliberately not
# asserted, because it depends on what the host has installed. What this pins is that the
# repo's real registry is still one this reader classifies `ok` -- which is the whole of what
# this change could break for the shipped file.
assert_resolve "M13 the repo's own registry is still a shape this reader accepts" "$REPO_ROOT" \
  'status == "ok" and servers is not None and len(servers) > 0'

# --- M14: a registry whose servers are all absent still reports a real total. --
# The direct analogue of the sibling's D2 and the strongest falsifier of "0/0 forever": a
# reader rendering a constant 0/0 fails here on the TOTAL, not merely on the label. These
# entries declare no name, so the probe falls back to their map keys and looks for alpha/ and
# beta/ under the exported empty fixture base -- determinism comes from that base, not from
# the spelling of the keys.
M14ROOT="$(new_root m14 '{"servers":{"alpha":{"type":"git"},"beta":{"type":"git"}}}')"
assert_mcp "M14 a fully-uninstalled registry reports a truthful two-server total" "$M14ROOT" \
  'status == "ok" and row["label"] != "ok" and row["summary"] == "0/2 installed"'

# --- M15: the install directory is keyed on the registry name, not the config key. -------
# The positive falsifier, and RED AT BASE: the base probe read desktop_config_key AND
# hardcoded the real ~/.claude/mcp-servers, so it resolved to a path outside this fixture
# entirely and reported the server "missing". The fixture declares a name that DIFFERS from
# its desktop_config_key and installs the wrapper under the name only, so the two keys cannot
# both be right. The hint is asserted by exact equality, never a substring: "fixture/start.sh"
# is a substring of the name-keyed form and a containment check would pass against the wrong
# path.
M15BASE="$(new_mcp_base m15 mcp_fixture/start.sh)"
M15ROOT="$(new_root m15 '{"servers":{"mcp_fixture":{"type":"git","name":"mcp_fixture","desktop_config_key":"fixture"}}}')"
export CLAUDE_MCP_DIR="$M15BASE"
assert_mcp "M15 a git server installs under its registry name, not its config key" "$M15ROOT" \
  'status == "ok" and row["summary"] == "1/1 installed" and servers[0]["install_status"] == "installed" and servers[0]["install_hint"] == r.os.path.join(r.os.environ["CLAUDE_MCP_DIR"], "mcp_fixture", "start.sh")'
export CLAUDE_MCP_DIR="$MCP_EMPTY"

# --- M16: a directory named for the config key alone is NOT installed. -------------------
# The negative twin of M15, and the reason M15 alone is insufficient: a fix that probes BOTH
# <name>/ and <desktop_config_key>/ and accepts either would satisfy M15 while reintroducing a
# false "installed". This base carries ONLY the config-key directory and no mcp_fixture/ at
# all, so an either-path reader reports "installed" here and goes red. It needs its own base
# AND its own root -- reusing M15's would leave mcp_fixture/start.sh present and the case
# would assert nothing.
M16BASE="$(new_mcp_base m16 fixture/start.sh)"
M16ROOT="$(new_root m16 '{"servers":{"mcp_fixture":{"type":"git","name":"mcp_fixture","desktop_config_key":"fixture"}}}')"
export CLAUDE_MCP_DIR="$M16BASE"
assert_mcp "M16 a directory named for the config key alone does not count as installed" "$M16ROOT" \
  'status == "ok" and row["label"] != "ok" and row["summary"] == "0/1 installed" and servers[0]["install_status"] == "missing"'
export CLAUDE_MCP_DIR="$MCP_EMPTY"

# --- M17: the sections reference documents the derivation the code actually uses. --------
# The documentation twin, in the M11 style: two operands over the same file, both falsifiable
# at base (the name form was absent, the desktop_config_key form present on the install-status
# line). Without the negative operand a stale sentence could survive alongside a new one.
if grep -qF 'mcp-servers/<name>/start.sh' "$SECTIONS" \
   && ! grep -qF 'mcp-servers/<desktop_config_key>' "$SECTIONS"; then
  pass "M17 the sections reference keys the install directory on the server name"
else
  fail "M17 the sections reference keys the install directory on the server name"
  printf '%s\n' "  the install-status bullet must name <name>, not <desktop_config_key>"
fi

# --- M18: an EMPTY CLAUDE_MCP_DIR falls back to the default base. -----------------------
# Without this case nothing distinguishes the probe's `or` form from a bare
# os.environ.get(VAR, default): every other case exports a NON-empty base, so both spellings
# are green across the suite and a future "consistency" tidy-up to the bare-default form
# would silently reintroduce an empty base. The sibling reader patch-desktop-config.py is
# pinned the same way by tests/test-patch-desktop-config-mcp-base.sh.
# SHAPE ONLY: this asserts the derived PATH, never that anything is installed there. The name
# cannot exist on any host, so the status is "missing" everywhere and the case turns purely on
# where the probe decided to look.
M18ROOT="$(new_root m18 '{"servers":{"zz-not-installed-fallback":{"type":"git"}}}')"
export CLAUDE_MCP_DIR=""
assert_mcp "M18 an empty CLAUDE_MCP_DIR falls back to the default base, not an empty one" "$M18ROOT" \
  'servers[0]["install_hint"] == r.os.path.join(r.os.path.expanduser("~/.claude/mcp-servers"), "zz-not-installed-fallback", "start.sh")'
export CLAUDE_MCP_DIR="$MCP_EMPTY"

echo
if [ "$failures" -eq 0 ]; then
  echo "All dashboard MCP-count tests passed."
  exit 0
else
  echo "$failures test(s) failed."
  exit 1
fi
