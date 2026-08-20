#!/usr/bin/env bash
# test_setup_seed_contract.sh — knowledge-setup Step 3.5 (seed the curated
# wiki-output layout for NEW wikis) contract assertions.
#
# Step 3.5 turns the schema_version 0.0.9 curated layout the SKILL's contract
# section declares into the actual seeded shape for a fresh wiki. It is an
# LLM-executed Bash recipe (the skill has no Write tool), so the only thing CI
# can guard is that the recipe's load-bearing invariants stay present in the
# SKILL prose. This file is the sibling of test_finalize_contract.sh /
# test_ingest_contract.sh — content-invariant grep tests over the SKILL.
#
# The invariants intentionally pin the points that already drifted once between
# the PR description and the merged code (overview.md kept, not removed) and the
# robustness choices in the heredoc seeds (quoted vs unquoted delimiters).
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

SETUP="$PLUGIN_ROOT/skills/knowledge-setup/SKILL.md"
if [ ! -f "$SETUP" ]; then
  red "FAIL: setup-seed-00-skills-knowledge-setup-skill skills/knowledge-setup/SKILL.md not found"
  exit 1
fi
# The verbatim Step 3.5(b) three-heredoc seed payload (wiki/index.md +
# wiki/overview.md + SCHEMA.md) was offloaded to a reference file for progressive
# disclosure. Assertions targeting the heredoc payload (opener lines + seed-body
# contract text) grep $SETUPREF; assertions on the imperative Step-3.5 body prose
# still grep $SETUP.
SETUPREF="$PLUGIN_ROOT/references/curated-layout-seed.md"
if [ ! -f "$SETUPREF" ]; then
  red "FAIL: setup-seed-01-references-curated-layout-seed references/curated-layout-seed.md not found"
  exit 1
fi

# --- Step 3.5 exists + is gated to the fresh-wiki branch -----------------
assert_grep '### 3.5 Seed the curated wiki-output layout' "$SETUP" "setup-seed-02-step-3-5-heading-present knowledge-setup: Step 3.5 heading present"
assert_grep 'only on the fresh-wiki branch' "$SETUP" "setup-seed-03-step-3-5-runs-only knowledge-setup: Step 3.5 runs only on the fresh-wiki branch"
assert_grep 'Skip it' "$SETUP" "setup-seed-04-step-3-5-documents-skip knowledge-setup: Step 3.5 documents the skip path (existing wiki / --reframe)"

# --- (a) per-type sub-index stubs via the canonical renderer -------------
# Delegated to sub_index.py — NOT hand-authored markers (no-duplicate-upstream).
assert_grep 'resolve_wiki_scripts wiki-ingest' "$SETUP" "setup-seed-05-resolves-wiki-ingest-scripts knowledge-setup: resolves WIKI_INGEST_SCRIPTS (mirrors knowledge-finalize Step 0)"
assert_grep 'sub_index.py' "$SETUP" "setup-seed-06-seeds-type-stubs-sub knowledge-setup: (a) seeds per-type stubs via sub_index.py render"
assert_grep 'concepts entities people sources questions syntheses' "$SETUP" "setup-seed-07-loops-all-six-page knowledge-setup: (a) loops all six page types"
assert_grep 'MACHINE-OWNED:<TYPE>-INDEX' "$SETUP" "setup-seed-08-documents-type-ownership-marker knowledge-setup: (a) documents the per-type ownership marker the renderer writes"

# --- (b) curated root files: index.md (curated MAP + narrative intro) +
#     overview.md (stub) — the curated-root layout folds the overview narrative
#     into the index.md intro and retires overview.md as the narrative home.
assert_grep 'wiki/index.md' "$SETUP" "setup-seed-09-b-seeds-wiki-index knowledge-setup: (b) seeds wiki/index.md (curated portal front door)"
assert_grep 'wiki/overview.md' "$SETUP" "setup-seed-10-b-seeds-wiki-overview knowledge-setup: (b) seeds wiki/overview.md (stub)"
assert_grep 'MACHINE-OWNED:ROOT-INDEX' "$SETUP" "setup-seed-11-index-md-carries-root knowledge-setup: index.md carries the ROOT-INDEX ownership marker"
assert_grep 'MACHINE-OWNED:OVERVIEW-NARRATIVE' "$SETUP" "setup-seed-12-overview-narrative-block-seeded knowledge-setup: OVERVIEW-NARRATIVE block is seeded (now in the index.md intro)"
assert_grep 'narrative now lives in' "$SETUPREF" "setup-seed-13-overview-md-stub-pointing knowledge-setup: overview.md is a stub pointing at the curated map (narrative moved to index.md)"
# The curated MAP carries no per-page bullet line, so the vendored
# strip_seed_placeholder has nothing to strip — assert the contract is documented.
assert_grep 'strip_seed_placeholder' "$SETUP" "setup-seed-14-documents-strip-seed-placeholder knowledge-setup: documents the strip_seed_placeholder self-clean contract"
assert_grep 'narrative-splice --target-file index.md' "$SETUP" "setup-seed-15-documents-overview-narrative-redirect knowledge-setup: documents the OVERVIEW-NARRATIVE redirect into the index.md intro"

# --- heredoc-delimiter hygiene -------------------------------------------
# index.md + overview.md need NO shell expansion, so they use a QUOTED
# delimiter (<<'EOF') — protects a substituted <knowledge-title> containing a
# $ or backtick. The log heredoc (c) is the ONE place that stays unquoted
# because it relies on $(date). Both must hold for the recipe to be safe.
assert_grep "wiki/index.md <<'EOF'" "$SETUPREF" "setup-seed-16-index-md-heredoc-uses knowledge-setup: index.md heredoc uses a quoted delimiter (no accidental expansion of the title)"
assert_grep "wiki/overview.md <<'EOF'" "$SETUPREF" "setup-seed-17-overview-md-heredoc-uses knowledge-setup: overview.md heredoc uses a quoted delimiter"
assert_grep 'wiki/meta/log.md <<EOF' "$SETUP" "setup-seed-18-log-md-heredoc-stays knowledge-setup: log.md heredoc stays unquoted (relies on \$(date))"
assert_grep 'date +%Y-%m-%d' "$SETUP" "setup-seed-19-c-log-line-stamps knowledge-setup: (c) log line stamps the date via \$(date)"

# --- (c) control log under wiki/meta/, seeded directly -------------------
assert_grep 'wiki/meta/log.md' "$SETUP" "setup-seed-20-c-seeds-wiki-meta knowledge-setup: (c) seeds wiki/meta/log.md"
assert_grep 'mkdir -p <knowledge_root>/wiki/meta' "$SETUP" "setup-seed-21-c-creates-wiki-meta knowledge-setup: (c) creates the wiki/meta dir"
# Must be seeded DIRECTLY, not via control-path.py (which resolves to the flat
# legacy path until the meta file exists — the bootstrap caveat).
assert_grep 'not via `control-path.py log`' "$SETUP" "setup-seed-22-c-documents-why-log knowledge-setup: (c) documents why log.md is seeded directly (control-path.py bootstrap caveat)"

# --- (d) drop ONLY the flat log; KEEP overview.md ------------------------
# This is the invariant that drifted between PR description (which said
# "removes overview.md") and the merged code. Lock it down: the flat log is
# removed, overview.md is explicitly KEPT.
assert_grep 'rm -f <knowledge_root>/wiki/log.md' "$SETUP" "setup-seed-23-d-removes-flat-wiki knowledge-setup: (d) removes the flat wiki/log.md"
assert_grep 'Keep `wiki/overview.md`' "$SETUP" "setup-seed-24-d-explicitly-keeps-wiki knowledge-setup: (d) explicitly KEEPS wiki/overview.md (the narrative home)"
# Defence-in-depth: no instruction to delete overview.md anywhere in the step.
assert_not_grep 'rm -f <knowledge_root>/wiki/overview.md' "$SETUP" "setup-seed-25-never-removes-wiki-overview knowledge-setup: NEVER removes wiki/overview.md"

# --- (e) advertise schema_version 0.0.9 via the locked config_bump.py ----
assert_grep 'config_bump.py' "$SETUP" "setup-seed-26-e-bumps-schema-version knowledge-setup: (e) bumps schema_version via the locked config_bump.py"
assert_grep 'schema_version --set-string 0.0.9' "$SETUP" "setup-seed-27-e-sets-schema-version knowledge-setup: (e) sets schema_version to 0.0.9"

# --- Step 3 native scaffold (the cogni-wiki:wiki-setup re-home) ---------------
assert_grep '.cogni-wiki/config.json' "$SETUP" "setup-seed-28-step-3-writes-cogni knowledge-setup: Step 3 writes .cogni-wiki/config.json natively"
assert_grep '"schema_version": "0.0.7"' "$SETUP" "setup-seed-29-step-3-config-seeds knowledge-setup: Step 3 config seeds schema_version 0.0.7 (Step 3.5 bumps to 0.0.9)"
assert_not_grep 'Skill("cogni-wiki:wiki-setup' "$SETUP" "setup-seed-30-no-longer-dispatches-cogni knowledge-setup: no longer dispatches cogni-wiki:wiki-setup"

# --- the post-step invariant the future knowledge-health check will assert
assert_grep 'competing root file' "$SETUP" "setup-seed-31-invariant-holds-across-first knowledge-setup: invariant holds across the first knowledge-finalize (overview folded into index.md, root MAP re-rendered, no competing root file)"

if [ $errors -eq 0 ]; then
  green ""
  green "knowledge-setup Step 3.5 seed-layout contract: ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
