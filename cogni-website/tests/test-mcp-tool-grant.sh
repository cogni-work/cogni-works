#!/usr/bin/env bash
# MCP tool-grant guard (prose arm, cogni-website scope): an agent whose body
# documents driving an MCP server in prose must actually be granted at least one
# of that server's tools.
#
# Why this exists. An agent frontmatter `tools:` list and the agent body are
# written at different times, and nothing at runtime reconciles them. When the
# body walks an MCP flow the frontmatter never granted, the documented path is
# simply unreachable: the agent silently takes whatever fallback it defines,
# every render degrades, and nothing errors. The failure is invisible precisely
# because a missing grant and a working fallback look identical from outside.
#
# Two tiers, one owner per invariant. The repo-scope guard
# scripts/check-mcp-tool-grant.py owns the AFFIRMATIVE call-site arm (a literal
# mcp__<ns>__<tool> token in an agent body must be granted by that agent) and
# the registry `required_by` arm, for every plugin. This suite keeps the PROSE
# arm, and keeps it at cogni-website scope, because neither detector subsumes
# the other: hero-renderer documents driving Pencil in prose alone and carries
# no mcp__ token anywhere in its body, so no affirmative detector can ever see
# that shape — while the prose heuristic cannot go repo-wide, since agents
# elsewhere DISCLAIM a server in the same phrasing ("no Excalidraw MCP"). Do not
# "finish the migration" by deleting this arm: that silently drops the one class
# the repo guard is structurally blind to, with every case still green.
#
# The registry `required_by` arm formerly lived here and has moved to the repo
# guard. It asserted a property of cogni-workspace's registry file from
# cogni-website's suite — an ownership inversion that made a cogni-workspace
# edit able to turn cogni-website red while leaving the same invariant unguarded
# for every other plugin.
#
# Contract under test:
#   - Every cogni-website agent that declares a `tools:` key and whose body
#     names "<server> MCP" for a server in the git registry carries at least one
#     mcp__<server>__ token in that `tools:` list.
#   - The scan surface itself is non-empty, so an absence result means "clean"
#     rather than "looked at nothing".
#
# Server-name normalization: a registry key is not always the tool namespace
# (`mcp_excalidraw` registers tools as mcp__excalidraw__*). The registry already
# carries that mapping as data in `desktop_config_key`, which
# cogni-workspace/scripts/patch-desktop-config.py treats as canonical, so it is
# read rather than re-derived by stripping a prefix — a heuristic would agree
# with the data only coincidentally and would mis-normalize a future key.
#
# Scope, and what this guard does NOT claim. It scans cogni-website's own agents
# only, and its detector is calibrated to what that surface looks like: it reads
# grants from the `tools:` line itself (both the bracketed JSON-array form this
# plugin uses and the bare comma list used elsewhere sit on that one line, but a
# YAML block list would not — 15 agents elsewhere in the tree declare tools that
# way, which is one reason this arm stays plugin-scoped), and it infers "this
# agent drives server X" from the body prose "<X> MCP". That prose heuristic is
# sound here and is not repo-wide safe: elsewhere in the tree the same phrase
# appears in sentences that DISCLAIM the server ("no Excalidraw MCP"), which
# would read as an offender. The repo-wide invariant is therefore keyed on an
# affirmative call site instead, in scripts/check-mcp-tool-grant.py, which
# parses all three `tools:` forms — this file is not a copy of it and neither
# replaces the other.
#
# An agent with no `tools:` key inherits unrestricted tools and is reported as
# skipped, not as an offender. A grant naming a server absent from the git
# registry is skipped too — some servers (browser extensions) install manually
# and are deliberately unregistered.
#
# Mutation recipe. Strip the Pencil grants from the agent frontmatter while
# leaving the body's Pencil MCP prose in place — the exact shipped defect. The
# case must go red on the mutant and green on HEAD.
#
#   bash <newest managed-service cogni-service>/scripts/mutation-check.sh \
#     --root . \
#     --file cogni-website/agents/hero-renderer.md \
#     --expr 's/^tools: \[.*mcp__pencil__.*\]$/tools: ["Read", "Write", "Glob", "Bash"]/m' \
#     --test 'bash cogni-website/tests/test-mcp-tool-grant.sh test_agent_mcp_grants_match_body' \
#     --case test_agent_mcp_grants_match_body
#
# The expr is fed to `perl -0pi`, which slurps the whole file, so `/m` is
# required for `^` and `$` to bind to the frontmatter line rather than the
# buffer. The substitution is non-global, which is safe only because the target
# carries exactly one `^tools: [` line — case test_grant_surface_intact floors
# that invariant so a second such line cannot silently make the mutant a no-op.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

AGENTS_DIR="$PLUGIN_DIR/agents"
REGISTRY="$REPO_ROOT/cogni-workspace/references/mcp-git-registry.json"

failures=0
pass() { printf '%s\n' "PASS: $1 ${2:-}"; }
fail() { printf '%s\n' "FAIL: $1 ${2:-}"; failures=$((failures + 1)); }

# Emits one `key=value` line per fact. Reads only the registry and the agent
# files; asserts nothing itself, so every verdict below is made in bash against
# numeric counts and our own values, never against foreign tool wording.
scan() {
  AGENTS_DIR="$AGENTS_DIR" REGISTRY="$REGISTRY" python3 - <<'PY'
import json, os, re, sys, glob

agents_dir = os.environ["AGENTS_DIR"]
registry_path = os.environ["REGISTRY"]

try:
    with open(registry_path, encoding="utf-8") as fh:
        registry = json.load(fh)
except (OSError, ValueError):
    registry = None

servers = registry.get("servers", registry) if isinstance(registry, dict) else None
if not isinstance(servers, dict):
    print("registry_ok=0")
    print("servers=0")
    sys.exit(0)

print("registry_ok=1")
print("servers=%d" % len(servers))

# The set of registered tool namespaces — this suite's server-name vocabulary,
# and nothing more. The registry carries the key -> namespace mapping as data in
# desktop_config_key; read it rather than re-deriving it from the key's
# spelling. The required_by VALUES are deliberately not read here: that arm
# moved to scripts/check-mcp-tool-grant.py, and keeping the plugin lists alive
# would make this suite look like it still asserts on cogni-workspace's data.
namespaces = {(entry.get("desktop_config_key") or key) for key, entry in servers.items()}

paths = sorted(glob.glob(os.path.join(agents_dir, "*.md")))
print("agents_scanned=%d" % len(paths))

body_mentions = 0
grant_tokens = 0
skipped_no_tools = 0
skipped_unregistered = 0
max_tools_lines = 0

for path in paths:
    try:
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
    except OSError:
        continue

    lines = text.split("\n")
    tools_idx = [i for i, ln in enumerate(lines) if ln.startswith("tools:")]
    max_tools_lines = max(max_tools_lines, len(tools_idx))
    name = os.path.basename(path)

    if not tools_idx:
        skipped_no_tools += 1
        print("skip_no_tools=%s" % name)
        continue

    tools_line = lines[tools_idx[0]]
    # One scan feeds both the offender set and the liveness counter that guards
    # it, so the two can never be widened out of step.
    granted_tokens = re.findall(r"mcp__([A-Za-z0-9_-]+?)__[A-Za-z0-9_-]+", tools_line)
    granted = set(granted_tokens)
    grant_tokens += len(granted_tokens)

    # Body is everything after the closing frontmatter fence, so a description
    # naming the server does not by itself count as the body documenting a call.
    fence = [i for i, ln in enumerate(lines) if ln.strip() == "---"]
    body = "\n".join(lines[fence[1] + 1:]) if len(fence) >= 2 else text
    body_lower = body.lower()

    for ns in sorted(namespaces):
        if re.search(r"\b%s\s+mcp\b" % re.escape(ns.lower()), body_lower):
            body_mentions += 1
            if ns not in granted:
                print("offender_grant=%s:%s" % (name, ns))

    for ns in sorted(granted):
        if ns not in namespaces:
            skipped_unregistered += 1
            print("skip_unregistered=%s:%s" % (name, ns))

print("body_mentions=%d" % body_mentions)
print("grant_tokens=%d" % grant_tokens)
print("skipped_no_tools=%d" % skipped_no_tools)
print("skipped_unregistered=%d" % skipped_unregistered)
print("max_tools_lines=%d" % max_tools_lines)
PY
}

SCAN_OUT="$(scan)"

field() { printf '%s\n' "$SCAN_OUT" | grep "^$1=" | head -n 1 | cut -d= -f2- ; }
collect() { printf '%s\n' "$SCAN_OUT" | grep -c "^$1=" ; }
list_of() { printf '%s\n' "$SCAN_OUT" | grep "^$1=" | cut -d= -f2- | tr '\n' ' ' ; }

REGISTRY_OK="$(field registry_ok)"
AGENTS_SCANNED="$(field agents_scanned)"
SERVERS="$(field servers)"
BODY_MENTIONS="$(field body_mentions)"
GRANT_TOKENS="$(field grant_tokens)"
MAX_TOOLS_LINES="$(field max_tools_lines)"

# An unset field means the scanner died before emitting it; treat as zero so a
# broken scan reds through the liveness floors rather than skipping silently.
: "${REGISTRY_OK:=0}" "${AGENTS_SCANNED:=0}" "${SERVERS:=0}"
: "${BODY_MENTIONS:=0}" "${GRANT_TOKENS:=0}" "${MAX_TOOLS_LINES:=0}"

test_agent_mcp_grants_match_body() {
  local case_id="test_agent_mcp_grants_match_body"
  if [ "$AGENTS_SCANNED" -lt 1 ] || [ "$BODY_MENTIONS" -lt 1 ]; then
    fail "$case_id" "scan surface broken — agents=$AGENTS_SCANNED body_mentions=$BODY_MENTIONS"
    return
  fi
  local offenders
  offenders="$(collect offender_grant)"
  if [ "$offenders" -ne 0 ]; then
    fail "$case_id" "agent documents an MCP server it grants no tool for: $(list_of offender_grant)"
  else
    pass "$case_id" "$BODY_MENTIONS documented server reference(s) all backed by a grant"
  fi
}

test_grant_surface_intact() {
  local case_id="test_grant_surface_intact"
  local broken=""
  [ "$REGISTRY_OK" -eq 1 ] || broken="$broken registry_unreadable"
  [ "$AGENTS_SCANNED" -ge 1 ] || broken="$broken no_agent_files"
  [ "$SERVERS" -ge 1 ] || broken="$broken no_registry_servers"
  [ "$BODY_MENTIONS" -ge 1 ] || broken="$broken no_documented_server_reference"
  [ "$GRANT_TOKENS" -ge 1 ] || broken="$broken no_grant_tokens"
  [ "$MAX_TOOLS_LINES" -le 1 ] || broken="$broken multiple_tools_lines_in_one_agent"
  if [ -n "$broken" ]; then
    fail "$case_id" "non-vacuity floor breached —$broken"
  else
    pass "$case_id" "agents=$AGENTS_SCANNED servers=$SERVERS mentions=$BODY_MENTIONS grants=$GRANT_TOKENS skipped=$(field skipped_no_tools)/$(field skipped_unregistered)"
  fi
}

ALL_TESTS="test_agent_mcp_grants_match_body test_grant_surface_intact"

run_one() {
  case " $ALL_TESTS " in
    *" $1 "*) "$1" ;;
    *) printf '%s\n' "unknown case: $1"; exit 2 ;;
  esac
}

if [ "$#" -gt 0 ]; then
  for requested in "$@"; do run_one "$requested"; done
else
  for t in $ALL_TESTS; do "$t"; done
fi

printf '%s\n' "$failures failed"
[ "$failures" -eq 0 ] || exit 1
