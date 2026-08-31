#!/usr/bin/env bash
# test_knowledge_wiki_probe.sh - guards the VENDORED-ONLY pre-flight shape
# across every cogni-knowledge skill.
#
# The wiki engine ships in-tree under scripts/vendor/cogni-wiki/. The plugin it
# was copied from is retired (absent from .claude-plugin/marketplace.json,
# listed in scripts/retired-plugins.json), so an external install can only be a
# stale, unversioned copy: resolving one would silently run an engine older than
# the plugin that called it, which is worse than failing loudly against the
# versioned copy that ships here.
#
# The invariant is ABSENCE, not order. It used to be order — a skill was allowed
# to fall back to an external cogni-wiki provided it probed the vendored engine
# first, and this suite's fingerprint was the INDENTATION of that fallback
# (`^probe_plugin cogni-wiki` at column 0 meant an unswept, install-only gate).
# With the fallback removed, any `probe_plugin cogni-wiki` at any indentation is
# a defect, so case 01 below scans for it unanchored — a strictly stronger
# assertion than the column-0 fingerprint it replaces, and one that cannot pass
# vacuously now that no legitimate occurrence remains.
#
# Cases 10-12 carry the removal's own contract: no message names the retired
# plugin as the missing artifact (10), every missing-engine message gives a
# reinstall remedy (11), and neither resolver carries an external probe branch
# (12). Each keys on an affirmative call site, never on prose — both resolvers
# document the removal in comments naming the very branches that are gone.
#
# bash 3.2 + stdlib only. Reads only; writes nothing.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS="$PLUGIN_ROOT/skills"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

if [ ! -d "$SKILLS" ]; then
  red "FAIL: knowledge-wiki-probe-01-no-external-probe skills/ directory not found"
  exit 1
fi

# --- 01: no skill probes an external cogni-wiki at all ----------------------
# Set-level scan, UNANCHORED: cogni-wiki is retired, so a fallback probe at any
# indentation is a defect, not just an unswept column-0 one. The match is on
# `probe_plugin cogni-wiki` specifically — knowledge-refresh legitimately probes
# `probe_plugin cogni-workspace` for the claims dispatch and must not be caught.

ext_probe=""
for f in "$SKILLS"/*/SKILL.md; do
  [ -f "$f" ] || continue
  if grep -q 'probe_plugin cogni-wiki' "$f"; then
    ext_probe="$ext_probe $(basename "$(dirname "$f")")"
  fi
done

if [ -n "$ext_probe" ]; then
  red "FAIL: knowledge-wiki-probe-01-no-external-probe external cogni-wiki fallback probe (the plugin is retired) in:$ext_probe"
  errors=$((errors + 1))
else
  green "PASS: knowledge-wiki-probe-01-no-external-probe no skill probes an external cogni-wiki (vendored-only)"
fi

# --- 02: knowledge-plan carries no wiki probe -------------------------------
# It decomposes the topic into plan.json and resolves no wiki engine.

assert_not_grep 'probe_plugin' "$SKILLS/knowledge-plan/SKILL.md" \
  "knowledge-wiki-probe-02-plan-no-probe knowledge-plan: carries no wiki probe (resolves no wiki engine)" \
  || errors=$((errors + 1))

# --- 03: knowledge-fetch carries no wiki probe ------------------------------
# It works from candidates.json / fetch-manifest.json / the fetch cache and
# touches no path under the bound wiki/ tree.

assert_not_grep 'probe_plugin' "$SKILLS/knowledge-fetch/SKILL.md" \
  "knowledge-wiki-probe-03-fetch-no-probe knowledge-fetch: carries no wiki probe (touches no wiki/ path)" \
  || errors=$((errors + 1))

# --- 04: curate / compose / verify carry no wiki probe ----------------------
# All three reach the wiki only through cogni-knowledge's own scripts, which
# resolve the engine internally; their real gate is the binding read plus the
# .cogni-wiki/config.json + wiki/ existence checks.

no_probe_residue=""
for name in knowledge-curate knowledge-compose knowledge-verify; do
  f="$SKILLS/$name/SKILL.md"
  if [ ! -f "$f" ]; then
    no_probe_residue="$no_probe_residue $name(missing)"
  elif grep -q 'probe_plugin' "$f"; then
    no_probe_residue="$no_probe_residue $name"
  fi
done

if [ -n "$no_probe_residue" ]; then
  red "FAIL: knowledge-wiki-probe-04-curate-compose-verify-no-probe wiki probe still present in:$no_probe_residue"
  errors=$((errors + 1))
else
  green "PASS: knowledge-wiki-probe-04-curate-compose-verify-no-probe curate/compose/verify carry no wiki probe"
fi

# --- 05: no live surface sends the reader to a marketplace install ----------
# cogni-wiki is retired, so a marketplace-install instruction is a dead end.
# _archive/ is excluded: it is a historical record, per the same exclusion
# test_skill_contracts.sh's M11 audit uses.

marketplace_hits=$(grep -rlF 'Install via the marketplace' \
  "$SKILLS" "$PLUGIN_ROOT/agents" "$PLUGIN_ROOT/references" "$PLUGIN_ROOT/README.md" \
  2>/dev/null | grep -v '/_archive/' || true)

if [ -n "$marketplace_hits" ]; then
  red "FAIL: knowledge-wiki-probe-05-no-marketplace-install-string 'Install via the marketplace' survives in: $(echo "$marketplace_hits" | tr '\n' ' ')"
  errors=$((errors + 1))
else
  green "PASS: knowledge-wiki-probe-05-no-marketplace-install-string no live surface directs the reader to install cogni-wiki from the marketplace"
fi

# --- 05b: no phase skill refers to the deleted standard message -------------
# 'Install via the marketplace' was DEFINED once, in knowledge-plan, and six
# phase skills referred to it as "the standard missing-plugin message". Deleting
# the definition orphans those references, so they must go too. Scoped to the
# eight phase skills on purpose: knowledge-refresh legitimately keeps the phrase
# for its cogni-workspace abort, and cogni-workspace is a live plugin.

orphaned=""
for name in knowledge-plan knowledge-curate knowledge-fetch knowledge-ingest \
            knowledge-compose knowledge-verify knowledge-finalize knowledge-distill; do
  f="$SKILLS/$name/SKILL.md"
  [ -f "$f" ] || continue
  if grep -qF 'standard missing-plugin message' "$f"; then
    orphaned="$orphaned $name"
  fi
done

if [ -n "$orphaned" ]; then
  red "FAIL: knowledge-wiki-probe-06-no-orphaned-message-reference reference to the deleted 'standard missing-plugin message' survives in:$orphaned"
  errors=$((errors + 1))
else
  green "PASS: knowledge-wiki-probe-06-no-orphaned-message-reference no phase skill refers to the deleted standard missing-plugin message"
fi

# --- 07: every retained probe names an engine that EXISTS -------------------
# The trap this suite exists to make impossible: wiki-setup was never vendored,
# so a `test -d .../skills/wiki-setup/scripts` is permanently false and silently
# falls through to the plugin probe, leaving the defect live behind code that
# LOOKS vendored-first.

missing_engine=""
for f in "$SKILLS"/*/SKILL.md; do
  [ -f "$f" ] || continue
  for engine in $(grep -o 'vendor/cogni-wiki/skills/[a-z-]*' "$f" | sed 's|.*/||' | sort -u); do
    if [ ! -d "$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/$engine/scripts" ]; then
      missing_engine="$missing_engine $(basename "$(dirname "$f")"):$engine"
    fi
  done
done

if [ -n "$missing_engine" ]; then
  red "FAIL: knowledge-wiki-probe-07-vendored-engine-exists SKILL.md names a vendored engine with no scripts/ dir on disk (an always-false probe):$missing_engine"
  errors=$((errors + 1))
else
  green "PASS: knowledge-wiki-probe-07-vendored-engine-exists every vendored engine named in a SKILL.md exists on disk"
fi

# --- 08: a retained probe's engine matches what the body resolves -----------
# The keep-in-sync invariant knowledge-lint states: the early-abort gate and the
# authoritative resolver must share one precedence.

mismatch=""
for name in knowledge-ingest knowledge-finalize knowledge-distill; do
  f="$SKILLS/$name/SKILL.md"
  if [ ! -f "$f" ]; then
    mismatch="$mismatch $name(missing)"
    continue
  fi
  grep -qF 'vendor/cogni-wiki/skills/wiki-ingest/scripts' "$f" \
    && grep -qF 'resolve_wiki_scripts wiki-ingest' "$f" \
    || mismatch="$mismatch $name"
done

if [ -n "$mismatch" ]; then
  red "FAIL: knowledge-wiki-probe-08-retained-engine-match retained probe does not gate on the engine its body resolves in:$mismatch"
  errors=$((errors + 1))
else
  green "PASS: knowledge-wiki-probe-08-retained-engine-match ingest/finalize/distill gate on wiki-ingest, the engine each body resolves"
fi

# --- 09: knowledge-distill still degrades rather than blocking --------------
# distill is optional. A missing engine must warn and exit 0, never abort.

DISTILL="$SKILLS/knowledge-distill/SKILL.md"
if [ ! -f "$DISTILL" ]; then
  red "FAIL: knowledge-wiki-probe-09-distill-warns-exit-0 skills/knowledge-distill/SKILL.md not found"
  errors=$((errors + 1))
elif grep -qF 'warn and exit cleanly' "$DISTILL"; then
  green "PASS: knowledge-wiki-probe-09-distill-warns-exit-0 knowledge-distill warns and exits cleanly on a missing engine"
else
  red "FAIL: knowledge-wiki-probe-09-distill-warns-exit-0 knowledge-distill no longer warns-and-exits-cleanly on a missing engine (distill is optional and must not block the pipeline)"
  errors=$((errors + 1))
fi

# --- 10: no abort/warn names cogni-wiki as the missing artifact -------------
# cogni-wiki is retired, so a message naming it points the operator at something
# they cannot obtain, with no remedy. Every resolver abort and fail-soft warn
# must name the VENDORED artifact and give a reinstall-cogni-knowledge remedy.
# This is the mutation-addressable case for that contract: revert any one site
# to the bare `abort "cogni-wiki <engine> scripts not found"` shape and it reds.

bare_msg=""
for f in "$SKILLS"/*/SKILL.md; do
  if grep -qE '(abort "cogni-wiki |⚠ cogni-wiki )' "$f"; then
    bare_msg="$bare_msg $(basename "$(dirname "$f")")"
  fi
done
if [ -n "$bare_msg" ]; then
  red "FAIL: knowledge-wiki-probe-10-no-bare-cogni-wiki-message an abort/warn names the retired cogni-wiki as the missing artifact in:$bare_msg"
  errors=$((errors + 1))
else
  green "PASS: knowledge-wiki-probe-10-no-bare-cogni-wiki-message no abort or warn names cogni-wiki as the missing artifact"
fi

# --- 11: every resolver abort/warn carries a reinstall remedy ---------------
# Naming the vendored artifact is half the contract; the operator also needs to
# be told what to do. Each line that reports a missing engine must say so.

# The abort prose wraps across two lines (message line, then remedy line) while
# the shell abort string is one line, so the remedy is accepted on the message
# line OR the one after it.
#
# Only lines that EMIT a message are graded: a shell `abort "`/`echo "` string,
# or a `> ` blockquote line. A prose bullet that merely cross-references "the
# standard missing-vendored-scripts message (Step 0 pre-flight)" is a pointer,
# not a message — the block it points at is graded at its own site, and grading
# the pointer too would demand a remedy be restated at every mention.
no_remedy=""
for f in "$SKILLS"/*/SKILL.md; do
  hits=$(grep -nE '^\s*(>|.*abort "|.*echo ")' "$f" | grep -F "scripts are missing" | cut -d: -f1 || true)
  for n in $hits; do
    window=$(sed -n "${n},$((n + 1))p" "$f")
    case "$window" in
      *[Rr]einstall\ cogni-knowledge*) ;;
      *) no_remedy="$no_remedy $(basename "$(dirname "$f")"):${n}" ;;
    esac
  done
done
if [ -n "$no_remedy" ]; then
  red "FAIL: knowledge-wiki-probe-11-missing-engine-names-remedy a missing-engine message offers no reinstall remedy in:$no_remedy"
  errors=$((errors + 1))
else
  green "PASS: knowledge-wiki-probe-11-missing-engine-names-remedy every missing-engine message directs the reader to reinstall cogni-knowledge"
fi

# --- 12: neither resolver carries an external cogni-wiki probe --------------
# The removal's anti-regression guard. A sibling checkout (../cogni-wiki/) or a
# marketplace-cache glob (../../cogni-wiki/*/) in either resolver would silently
# resolve a stale, unversioned engine in preference to failing loudly against
# the versioned vendored copy.
#
# The vendored path ITSELF contains the string "cogni-wiki", so matching the
# plugin name would flag the legitimate construction on day one. These patterns
# key on the markers unique to the REMOVED branches instead: the `../` escape
# out of the plugin root, the version-ranking glob and its `sort -V` / semver
# tuple, and the `base_dir` seam that existed only to test the cache branch.

# Detection keys on an affirmative CALL SITE, never on prose: both resolvers
# document the removal in a comment/docstring naming the very branches that are
# gone, so a name-matching scan would report them as offenders on day one. The
# shell file is comment-stripped; the Python function is parsed and its docstring
# dropped, so only executable code is scanned.

SHELL_RESOLVER="$PLUGIN_ROOT/scripts/resolve-wiki-scripts.sh"
PY_RESOLVER="$PLUGIN_ROOT/scripts/_knowledge_lib.py"
external=""

if [ ! -f "$SHELL_RESOLVER" ]; then
  external="$external resolve-wiki-scripts.sh:absent"
elif sed 's/#.*//' "$SHELL_RESOLVER" | grep -qE '\.\./cogni-wiki|sort -V'; then
  external="$external resolve-wiki-scripts.sh"
fi

if [ ! -f "$PY_RESOLVER" ]; then
  external="$external _knowledge_lib.py:absent"
else
  py_verdict=$(python3 - "$PY_RESOLVER" <<'PY'
import ast, sys
src = open(sys.argv[1], encoding="utf-8").read()
tree = ast.parse(src)
fn = next((n for n in ast.walk(tree)
           if isinstance(n, ast.FunctionDef) and n.name == "resolve_wiki_scripts"), None)
if fn is None:
    print("function-absent"); raise SystemExit(0)
# Drop the docstring: prose there names the removed branches on purpose.
body = fn.body[1:] if (fn.body and isinstance(fn.body[0], ast.Expr)
                       and isinstance(fn.body[0].value, ast.Constant)
                       and isinstance(fn.body[0].value.value, str)) else fn.body
code = "\n".join(ast.unparse(n) for n in body)
bad = []
if "base_dir" in {a.arg for a in fn.args.args} | {a.arg for a in fn.args.kwonlyargs}:
    bad.append("base_dir-seam")
if "parents[2]" in code or "repo_root" in code:
    bad.append("sibling-branch")
if ".glob(" in code or "_NUMERIC_VERSION_RE" in code:
    bad.append("versioned-cache-branch")
print(",".join(bad) if bad else "clean")
PY
)
  [ "$py_verdict" = "clean" ] || external="$external _knowledge_lib.py:${py_verdict}"
fi
if [ -n "$external" ]; then
  red "FAIL: knowledge-wiki-probe-12-resolvers-vendored-only an external cogni-wiki probe (sibling / versioned-cache) survives in:$external"
  errors=$((errors + 1))
else
  green "PASS: knowledge-wiki-probe-12-resolvers-vendored-only both resolvers are vendored-only, with no external cogni-wiki probe"
fi

if [ $errors -gt 0 ]; then
  red "$errors invariant(s) failed."
  exit 1
fi

green ""
green "cogni-knowledge vendored-only pre-flight contract: ALL PASS"
