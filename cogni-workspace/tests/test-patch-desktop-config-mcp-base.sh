#!/usr/bin/env bash
# Regression test for the MCP base directory that patch-desktop-config.py resolves
# (resolve_wrapper_path + build_mcp_entry's git branch in scripts/patch-desktop-config.py).
#
# Contract under test: the base override falls back to $HOME/.claude/mcp-servers when it is
# unset OR set-but-empty, and is honoured VERBATIM otherwise -- including a whitespace-only
# value. That is the same semantics as install-mcp.sh's ${...:-...} and the dashboard probe's
# `or` form; neither trims, so this reader must not either. A bare os.environ.get(VAR, default)
# fires only on unset, and the empty case is what it gets wrong.
#
# The empty case is SILENT, which is why it needs its own pin: an empty base makes
# Path(mcp_base)/name/"start.sh" a CWD-RELATIVE path, resolve_wrapper_path is exists()-gated
# so it returns None, and build_mcp_entry's git branch returns None in turn -- an installed
# server just vanishes from the written config with no error anywhere.
#
# ASSERT THE POSITIVE PATH, NEVER A NEGATIVE SHAPE. The broken value is the relative
# "<name>/start.sh", never an absolute "/<name>/start.sh", so a case phrased as "not
# /<name>/" would be green against the unfixed reader and pin nothing. Every case below
# compares against a controlled fixture path by equality.
#
# SHAPE ONLY, NEVER HOST AVAILABILITY -- the same discipline as the sibling suite
# test-dashboard-mcp-counts.sh. No case may depend on what is installed under the real
# ~/.claude/mcp-servers: $HOME is overridden to a fixture tree for every case, so the
# default-base cases resolve inside $TMPROOT and determinism is STRUCTURAL rather than a
# naming convention. Each case also runs with cwd pinned to an empty fixture directory,
# because the broken value is cwd-relative -- a stray directory under the runner's working
# directory would otherwise decide the result.
#
# Cases drive the PRODUCTION read path -- the real module is loaded and its own functions
# called. Re-implementing the resolution expression in the test, or hand-building an entry
# and asserting on that, would never execute the changed line and would stay green against
# the unfixed reader, which is exactly the vacuity this suite exists to avoid.
#
# Case ids are zero-padded to a uniform width so no id is a prefix of another: the mutation
# harness matches --case as a whole token, and P1 vs P10 is that collision class.
#
# Paths are self-located from $0, never the working directory: the repo runner invokes suites
# with cwd=<repo root> and the mutation harness with cwd=$ROOT, so a cwd-relative path here
# would be a latent false result.
#
# stdlib-only: bash + python3, no pip deps, per the repo-wide script convention.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
PATCHER="$WS_ROOT/scripts/patch-desktop-config.py"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

# A fixture $HOME, a fixture non-default base, and an empty directory to run from. The two
# wrapper files are REAL because resolve_wrapper_path is exists()-gated -- a case that only
# sets the environment would be red at every revision, not just the broken one. They are
# touched, never executed.
FAKE_HOME="$TMPROOT/home"
DEFAULT_BASE="$FAKE_HOME/.claude/mcp-servers"
ALT_BASE="$TMPROOT/alt-base"
EMPTY_CWD="$TMPROOT/empty-cwd"
SRV="fixture-git-server"
mkdir -p "$DEFAULT_BASE/$SRV" "$ALT_BASE/$SRV" "$EMPTY_CWD"
touch "$DEFAULT_BASE/$SRV/start.sh" "$ALT_BASE/$SRV/start.sh"

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

# assert_patcher "<label>" "<expected path>" "<python expr, True to pass>" -- the module is
# bound as `p`, the server name as `name`, and the expected path as `expected`. The heredoc
# delimiter is unquoted so $expr expands, so the body carries no other $, backtick or
# backslash sequence. HOME is set per-invocation rather than exported once, so nothing here
# can leak into the rest of the suite.
assert_patcher() {
  local label="$1" expected="$2" expr="$3"
  if ( cd "$EMPTY_CWD" && HOME="$FAKE_HOME" python3 - "$PATCHER" "$SRV" "$expected" <<PY
import importlib.util, os, sys

def _load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m); return m

p = _load("p", sys.argv[1])
name = sys.argv[2]
expected = sys.argv[3]
resolved = p.resolve_wrapper_path(name)
sys.exit(0 if ($expr) else 1)
PY
  ); then pass "$label"; else fail "$label"; fi
}

# --- P01: an UNSET override resolves under the default base. ----------------------------
# The unset arm is pinned separately from the empty arm so the fix for one cannot regress
# the other. The explicit unset is not redundant: anyone who has run install-mcp exports
# this variable, and without it P01 would read that live base and fail on their machine.
unset CLAUDE_MCP_DIR
assert_patcher "P01 an unset override resolves the wrapper under the default base" \
  "$DEFAULT_BASE/$SRV/start.sh" \
  'resolved == expected'

# --- P02: a NON-EMPTY override replaces the base. ----------------------------------------
export CLAUDE_MCP_DIR="$ALT_BASE"
assert_patcher "P02 a non-empty override resolves the wrapper under that base" \
  "$ALT_BASE/$SRV/start.sh" \
  'resolved == expected'

# --- P03: an EMPTY override falls back to the default base. ------------------------------
# The discriminating case. Against a bare os.environ.get(VAR, default) the base is the empty
# string, so the wrapper is the cwd-relative "fixture-git-server/start.sh"; cwd is the empty
# fixture directory, nothing creates that path there, and resolve_wrapper_path returns None.
export CLAUDE_MCP_DIR=""
assert_patcher "P03 an empty override falls back to the default base, not an empty one" \
  "$DEFAULT_BASE/$SRV/start.sh" \
  'resolved == expected'

# --- P04: a WHITESPACE-ONLY override stays SET. ------------------------------------------
# Green both before and after the fix -- it pins an invariant, not the change. Neither
# ${...:-...} nor `or` trims, so a .strip() added here would make this reader fall back where
# its two siblings do not, and this case is what goes red for it. The exists() conjunct is
# the anti-vacuity half: without it, `resolved is None` would also hold if the default
# fixture were simply missing.
export CLAUDE_MCP_DIR=" "
assert_patcher "P04 a whitespace-only override stays set and does not fall back" \
  "$DEFAULT_BASE/$SRV/start.sh" \
  'resolved is None and os.path.exists(expected)'

# --- P05: an EMPTY override still yields an entry, rather than omitting the server. -------
# The user-visible symptom, end to end: the git branch of build_mcp_entry returns None for an
# unresolvable wrapper, so the server disappears from the written config. Asserting the whole
# entry pins the omission rather than the resolution alone.
export CLAUDE_MCP_DIR=""
assert_patcher "P05 an empty override still yields a git server entry rather than omitting it" \
  "$DEFAULT_BASE/$SRV/start.sh" \
  'p.build_mcp_entry({"type": "git", "name": name}, "cli") == {"type": "stdio", "command": "bash", "args": [expected], "env": {}}'

unset CLAUDE_MCP_DIR

echo
if [ "$failures" -eq 0 ]; then
  echo "All patch-desktop-config MCP-base tests passed."
  exit 0
else
  echo "$failures test(s) failed."
  exit 1
fi
