#!/usr/bin/env bash
# test_knowledge_wiki_probe.sh - guards the vendored-first pre-flight shape
# across every cogni-knowledge skill.
#
# History: the wiki engine was vendored in-tree under scripts/vendor/cogni-wiki/,
# and the read/render skills plus knowledge-setup were swept onto a vendored-first
# probe with the plugin install demoted to a fallback layout. The eight
# inverted-pipeline phase skills were never swept — they kept a pre-vendoring
# probe that consulted ONLY the plugin-install layouts. Since cogni-wiki is
# retired (absent from .claude-plugin/marketplace.json, listed in
# scripts/retired-plugins.json), that probe failed deterministically on every
# stock install: seven phases aborted outright and knowledge-distill warned.
#
# Nothing detected the partial sweep, which is why it survived. This suite is
# that detector.
#
# The invariant is ORDER, not absence. A plugin probe is legitimate as a
# fallback; it is a defect only when it runs FIRST. The mechanical signature of
# the defect is indentation: a swept skill's probe sits inside an
# `if [ "$WIKI_OK" = "no" ]` branch and is therefore indented, while an
# install-only probe sits at column 0. So `^probe_plugin cogni-wiki` is the
# defect's fingerprint, and asserting zero of them covers every wiki-touching
# skill at once rather than a hardcoded list that a future skill could evade.
#
# bash 3.2 + stdlib only. Reads only; writes nothing.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS="$PLUGIN_ROOT/skills"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

if [ ! -d "$SKILLS" ]; then
  red "FAIL: knowledge-wiki-probe-01-install-only skills/ directory not found"
  exit 1
fi

# --- 01: no skill gates on an install-only probe ----------------------------
# Set-level scan. A column-0 `probe_plugin cogni-wiki` is by construction a probe
# that runs before any vendored test -d, i.e. an install-only gate.

install_only=""
for f in "$SKILLS"/*/SKILL.md; do
  [ -f "$f" ] || continue
  if grep -q '^probe_plugin cogni-wiki' "$f"; then
    install_only="$install_only $(basename "$(dirname "$f")")"
  fi
done

if [ -n "$install_only" ]; then
  red "FAIL: knowledge-wiki-probe-01-install-only install-only cogni-wiki probe (column 0, ahead of any vendored test -d) in:$install_only"
  errors=$((errors + 1))
else
  green "PASS: knowledge-wiki-probe-01-install-only no skill gates on an install-only cogni-wiki probe"
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

if [ $errors -gt 0 ]; then
  red "$errors invariant(s) failed."
  exit 1
fi

green ""
green "cogni-knowledge vendored-first pre-flight contract: ALL PASS"
