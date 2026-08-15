#!/usr/bin/env bash
# Relocated-skill hygiene guard for the two skills cogni-workspace adopted from
# cogni-help: cogni-issues and troubleshoot.
#
# Why this exists. Two properties of those trees are load-bearing and nothing
# else in the repo enforces either one:
#
#   - No `cogni-help:` dispatch token may survive in the adopted copies. The
#     obvious candidate guard, scripts/check-external-dispatch.py, reaches only
#     part of that surface: its globs cover SKILL.md, agents, commands, hooks,
#     while a skill's own scripts/, evals/ and references/ files match none of
#     them. P1 below walks every file in both trees instead — the gap is one of
#     file-type coverage, not of what scripts/retired-plugins.json carries.
#   - Every `${CLAUDE_PLUGIN_ROOT}`-relative path documented in those trees must
#     resolve under cogni-workspace. Most such paths are skill-relative and
#     survive relocation untouched, but a plugin-root-relative one silently
#     retargets: the source tree documented `${CLAUDE_PLUGIN_ROOT}/scripts/
#     course-status.sh`, which resolves to a cogni-workspace path that does not
#     exist and will not, because that script belongs to the course-delivery
#     system being retired. Nothing would have reported it.
#
# Scope. Every assertion reads the cogni-workspace tree ONLY. The properties
# under test belong to the destination copies, so no source tree is an input to
# any of them: this suite reads the same and passes the same whether or not a
# cogni-help tree exists anywhere in the repo. That independence is the point —
# relocation hygiene is checked where the relocated files actually live.
#
# Deliberately NOT asserted: counterpart-completeness against cogni-help. An
# assertion reading a tree this plugin does not own breaks whenever that tree
# changes or disappears — a guard a later change must remember to rewrite.
#
# Case-label shape is "PASS: <case>" / "FAIL: <case>", matching
# test-layering-claim-reconciled.sh and test-wiki-namespace-sync.sh, because the
# cogni-service mutation harness classifies a case green only on the PASS: form
# and red on the matching FAIL: form — printing only the failure line would leave
# every case unclassifiable as green. Case ids are P-prefixed and never bare
# numerals, so the trailing summary line is not read as a case's red line.
#
# Contract: runs as `bash <path>` with no arguments, from any cwd, touches no
# network, needs nothing beyond bash + coreutils, and exits non-zero on failure.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"

TREES="
$WS_ROOT/skills/cogni-issues
$WS_ROOT/skills/troubleshoot
"

failures=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

# ---------------------------------------------------------------------------
# Case P1 — no `cogni-help:` dispatch token in either adopted tree.
#
# The colon form is deliberate. Broadening to a bare `cogni-help` would be red on
# arrival against content carried unchanged on purpose: references/known-issues.md
# documents the cogni-teacher -> cogni-help progress-file rename, and the
# troubleshoot evals assert exactly that diagnosis. Those are prose about another
# plugin, not a dispatch surface. The qualified form is the one that would break
# at runtime.
# ---------------------------------------------------------------------------
p1_hits=""
p1_scanned=0
for tree in $TREES; do
  if [ ! -d "$tree" ]; then
    fail "P1 adopted tree missing: $tree"
    continue
  fi
  while IFS= read -r f; do
    p1_scanned=$((p1_scanned + 1))
    if grep -Fq 'cogni-help:' "$f" 2>/dev/null; then
      p1_hits="$p1_hits $f"
    fi
  done <<EOF
$(find "$tree" -type f)
EOF
done

if [ "$p1_scanned" -eq 0 ]; then
  # Liveness floor: a broken walk must not report clean.
  fail "P1 scanned zero files — the adopted trees are missing or unreadable"
elif [ -n "$p1_hits" ]; then
  for h in $p1_hits; do
    echo "  cogni-help: dispatch token in ${h#"$WS_ROOT"/}"
  done
  fail "P1 adopted trees must contain no 'cogni-help:' dispatch token"
else
  pass "P1 no 'cogni-help:' dispatch token in the adopted trees ($p1_scanned files scanned)"
fi

# ---------------------------------------------------------------------------
# Case P2 — every ${CLAUDE_PLUGIN_ROOT}-relative path resolves under cogni-workspace.
#
# A reference ending in `/` is a directory reference and is resolved as one; every
# other reference is resolved as a file. The directory arm is load-bearing, not
# defensive: cogni-issues/SKILL.md documents the scripts directory itself as
# `${CLAUDE_PLUGIN_ROOT}/skills/cogni-issues/scripts/`, so a file-only check would
# be red on arrival.
# ---------------------------------------------------------------------------
p2_bad=""
p2_scanned=0
for tree in $TREES; do
  [ -d "$tree" ] || continue
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    p2_scanned=$((p2_scanned + 1))
    rel="${ref#\$\{CLAUDE_PLUGIN_ROOT\}}"
    target="$WS_ROOT$rel"
    case "$ref" in
      */)
        [ -d "$target" ] || p2_bad="$p2_bad $ref"
        ;;
      *)
        [ -f "$target" ] || p2_bad="$p2_bad $ref"
        ;;
    esac
  done <<EOF
$(grep -rho '\${CLAUDE_PLUGIN_ROOT}[A-Za-z0-9_./-]*' "$tree" 2>/dev/null | sort -u)
EOF
done

if [ "$p2_scanned" -eq 0 ]; then
  # Liveness floor: the adopted cogni-issues skill documents its script paths, so
  # zero extracted references means the extractor broke, not that the trees are clean.
  fail "P2 extracted zero \${CLAUDE_PLUGIN_ROOT} references — the extractor is broken"
elif [ -n "$p2_bad" ]; then
  for b in $p2_bad; do
    echo "  does not resolve under cogni-workspace: $b"
  done
  fail "P2 every \${CLAUDE_PLUGIN_ROOT} reference must resolve under cogni-workspace"
else
  pass "P2 all $p2_scanned \${CLAUDE_PLUGIN_ROOT} references resolve under cogni-workspace"
fi

# ---------------------------------------------------------------------------

if [ "$failures" -gt 0 ]; then
  echo
  echo "FAIL: $failures relocated-skill hygiene test(s) failed."
  exit 1
fi

echo
echo "OK: relocated-skill hygiene checks passed."
