#!/usr/bin/env bash
# test_refresh_resweep_contract.sh — contract assertions for the v0.1.97
# knowledge-refresh --resweep NATIVE inline re-orchestration.
#
# Per tests/README.md §"Contract tests": knowledge-refresh is a pure LLM
# orchestrator with no script to execute, so regression coverage is SKILL.md
# content invariants. These catch the most likely failure mode — the opt-in
# resweep flag, its pass-throughs, or the inline orchestration silently
# regressing back to a cogni-wiki: dispatch.
#
# The re-orchestration: --resweep no longer dispatches
# cogni-wiki:wiki-claims-resweep. It runs the vendored wiki-claims-resweep
# scripts (extract_page_claims.py + resweep_planner.py) in-tree and dispatches
# cogni-workspace:claims submit/verify for the live-source re-check — dropping the
# residual cogni-wiki: dispatch (archival parity grep-guard) while keeping the
# public --resweep* flags unchanged. The vendored scripts are resolved
# vendored-first via resolve_wiki_scripts(), mirroring knowledge-dashboard.
#
# bash 3.2 + grep + awk.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

REFRESH="$PLUGIN_ROOT/skills/knowledge-refresh/SKILL.md"
if [ ! -f "$REFRESH" ]; then
  red "FAIL: refresh-resweep-00-skills-knowledge-refresh-skill skills/knowledge-refresh/SKILL.md not found"
  exit 1
fi

# --- 1) Parameters table documents --resweep + the four pass-throughs ------
# The public interface is stable across the re-home — the flags table is unchanged.
assert_grep '`--resweep`' "$REFRESH" "refresh-resweep-01-resweep-documented-parameters-table knowledge-refresh: --resweep documented in Parameters table"
assert_grep '`--resweep-page' "$REFRESH" "refresh-resweep-02-resweep-page-pass-through knowledge-refresh: --resweep-page pass-through documented"
assert_grep '`--resweep-stale-only`' "$REFRESH" "refresh-resweep-03-resweep-stale-only-pass knowledge-refresh: --resweep-stale-only pass-through documented"
assert_grep '`--resweep-days' "$REFRESH" "refresh-resweep-04-resweep-days-pass-through knowledge-refresh: --resweep-days pass-through documented"
assert_grep '`--resweep-dry-run`' "$REFRESH" "refresh-resweep-05-resweep-dry-run-pass knowledge-refresh: --resweep-dry-run pass-through documented"

# --- 2) Workflow has a dedicated resweep section ---------------------------
assert_grep '### 2. Resweep' "$REFRESH" "refresh-resweep-06-workflow-2-resweep-section knowledge-refresh: Workflow has a '### 2. Resweep' section"

# --- 3) The resweep is NATIVE: vendored scripts + cogni-workspace, no cogni-wiki dispatch ---
assert_not_grep 'Skill("cogni-wiki:wiki-claims-resweep"' "$REFRESH" "refresh-resweep-07-resweep-no-longer-dispatches knowledge-refresh: --resweep no longer dispatches cogni-wiki:wiki-claims-resweep"
assert_grep 'extract_page_claims.py' "$REFRESH" "refresh-resweep-08-resweep-runs-vendored-extract knowledge-refresh: --resweep runs vendored extract_page_claims.py"
assert_grep 'resweep_planner.py' "$REFRESH" "refresh-resweep-09-resweep-runs-vendored-planner knowledge-refresh: --resweep runs vendored resweep_planner.py"
assert_grep 'Skill("cogni-workspace:claims"' "$REFRESH" "refresh-resweep-10-resweep-dispatches-cogni-workspace knowledge-refresh: --resweep dispatches cogni-workspace:claims for live-source re-verification"
assert_grep 'resolve_wiki_scripts wiki-claims-resweep' "$REFRESH" "refresh-resweep-11-resweep-resolves-vendored-scripts knowledge-refresh: --resweep resolves vendored scripts vendored-first via resolve_wiki_scripts()"
# Against the bound wiki, never a duplicated cadence pointer.
assert_grep 'binding.wiki_path' "$REFRESH" "refresh-resweep-12-resweep-targets-binding-wiki knowledge-refresh: resweep targets binding.wiki_path"

# --- 4) Opt-in / never-auto-run discipline ---------------------------------
assert_grep 'opt-in' "$REFRESH" "refresh-resweep-13-resweep-documented-opt knowledge-refresh: resweep documented as opt-in"
assert_grep 'never auto-run\|Never auto-runs\|never auto-dispatch' "$REFRESH" "refresh-resweep-14-resweep-documented-never-auto knowledge-refresh: resweep documented as never-auto-run"

# --- 5) Out of scope names the synthesis-extractor underyield --------------
assert_grep 'underyield' "$REFRESH" "refresh-resweep-15-out-scope-documents-synthesis knowledge-refresh: Out of scope documents synthesis-page underyield"

# --- 6) When/Never/References surfaces -------------------------------------
# When to run carries the opt-in resweep bullet.
if grep -qE 'live source URLs.*--resweep|--resweep.*live' "$REFRESH"; then
  green "PASS: refresh-resweep-16-when-run-surfaces-resweep knowledge-refresh: 'When to run' surfaces the --resweep opt-in"
else
  red "FAIL: refresh-resweep-16-when-run-surfaces-resweep knowledge-refresh: 'When to run' must surface the --resweep opt-in"
  errors=$((errors + 1))
fi
# Never-run-when names the missing-vendored-scripts abort (no longer a missing-plugin abort).
assert_grep 'vendored wiki-claims-resweep scripts are missing\|missing-vendored-scripts' "$REFRESH" "refresh-resweep-17-never-run-when-names knowledge-refresh: Never-run-when names the missing-vendored-scripts abort"
# References block lists the vendored scripts + the cogni-workspace dispatch target.
assert_grep 'wiki-claims-resweep/scripts/extract_page_claims.py' "$REFRESH" "refresh-resweep-18-references-lists-vendored-extract knowledge-refresh: References lists the vendored extract_page_claims.py"
assert_grep 'wiki-claims-resweep/scripts/resweep_planner.py' "$REFRESH" "refresh-resweep-19-references-lists-vendored-resweep knowledge-refresh: References lists the vendored resweep_planner.py"
assert_grep 'cogni-workspace:claims` SKILL.md' "$REFRESH" "refresh-resweep-20-references-lists-cogni-workspace knowledge-refresh: References lists cogni-workspace:claims as the live-source re-verification target"

# --- 7) Pre-flight probes the vendored scripts + cogni-workspace (not cogni-wiki) ---
assert_not_grep 'probe_plugin cogni-wiki wiki-claims-resweep' "$REFRESH" "refresh-resweep-21-pre-flight-no-longer knowledge-refresh: pre-flight no longer probes cogni-wiki wiki-claims-resweep"
assert_grep 'scripts/vendor/cogni-wiki/skills/wiki-claims-resweep/scripts' "$REFRESH" "refresh-resweep-22-pre-flight-tests-vendored knowledge-refresh: pre-flight tests the vendored wiki-claims-resweep scripts dir"
assert_grep 'probe_plugin cogni-workspace claims' "$REFRESH" "refresh-resweep-23-pre-flight-probes-cogni knowledge-refresh: pre-flight probes cogni-workspace when --resweep is passed"

# --- 8) Push-mode survives; pull-mode is removed (regression guard) --------
assert_not_grep 'Skill("cogni-wiki:wiki-lint"' "$REFRESH" "refresh-resweep-24-push-mode-lints-natively knowledge-refresh: push-mode lints natively on the vendored engine, not via a cogni-wiki:wiki-lint dispatch"
assert_grep 'lint_wiki.py' "$REFRESH" "refresh-resweep-25-push-mode-lints-vendored knowledge-refresh: push-mode still lints (vendored lint_wiki.py in-tree)"
assert_not_grep 'Skill("cogni-wiki:wiki-refresh"' "$REFRESH" "refresh-resweep-26-pull-mode-wiki-refresh knowledge-refresh: pull-mode wiki-refresh dispatch removed"
assert_not_grep 'from-research' "$REFRESH" "refresh-resweep-27-research-flag-removed-pull knowledge-refresh: --from-research flag removed with pull-mode"

# --- 9) probe_plugin definition and call share one fenced block -------------
# A flat assert_grep on the invocation literal is not enough: it stays green when
# `probe_plugin()` is defined in a DIFFERENT fenced block than the one calling it,
# which is the standalone-exit-127 defect this guards. The predicate is
# BIDIRECTIONAL, so it also rejects the duplicate-definition shortcut: a block
# that calls without defining is FAIL-NODEF, one that defines without calling is
# FAIL-ORPHANDEF.
fence_scope_result=$(awk '
  /^```/ {
    if (inf) {
      if (hascall) { sawcall = 1; if (!hasdef) nodef = 1 }
      else if (hasdef) orphan = 1
    }
    inf = !inf; hasdef = 0; hascall = 0; next
  }
  inf && /probe_plugin\(\)[ \t]*\{/ { hasdef = 1 }
  inf && /probe_plugin[ \t]+[A-Za-z]/ { hascall = 1 }
  END {
    if (!sawcall)    print "FAIL-NOBLOCK"
    else if (nodef)  print "FAIL-NODEF"
    else if (orphan) print "FAIL-ORPHANDEF"
    else             print "PASS"
  }
' "$REFRESH") || true

if [ "$fence_scope_result" = "PASS" ]; then
  green "PASS: refresh-resweep-28-probe-plugin-fence-scoped knowledge-refresh: probe_plugin is defined in the same fenced block that calls it"
else
  red "FAIL: refresh-resweep-28-probe-plugin-fence-scoped knowledge-refresh: probe_plugin definition/call are not fence-co-located ($fence_scope_result)"
  errors=$((errors + 1))
fi

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
