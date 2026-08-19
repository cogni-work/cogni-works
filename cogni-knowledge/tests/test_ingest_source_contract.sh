#!/usr/bin/env bash
# test_ingest_source_contract.sh — grep-based contract assertions for the
# standalone single-source ingest surface: the knowledge-ingest-source skill.
#
# Per tests/README.md §"Contract tests": for pure LLM skills, regression
# coverage is SKILL.md content invariants. These checks catch the most likely
# failure mode — a path, flag, or step silently disappearing from the contract.
# They do NOT assert LLM behaviour.
#
# Coverage:
#   - knowledge-ingest-source: deposits ONE source directly (no research run,
#     no fetch-manifest.json), reusing the research write path — populates the
#     fetch-cache via fetch-cache.py store (webfetch), dedups via
#     wiki-grounding.py rank (diff-before-write on collision), dispatches the
#     unchanged source-ingester via Task, and runs the same backlink_audit.py +
#     wiki_index_update.py + config_bump.py post-write lockstep as
#     knowledge-ingest Step 4. Writes wiki/sources/<slug>.md (type: source).
#   - Input modes: the surface accepts a URL, a local file (.docx/.html/.txt),
#     pasted text, a local PDF, and a local interview note. Local inputs deposit
#     via fetch-method direct (the additive non-web method, now live); .docx/
#     .html/.txt normalize via the vendored convert_to_md.py; queue mode via the
#     vendored wiki_queue.py; an interview note lands as type: interview in
#     wiki/interviews/ via the source-ingester PAGE_TYPE param.
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- knowledge-ingest-source SKILL.md ------------------------------------
SRC="$PLUGIN_ROOT/skills/knowledge-ingest-source/SKILL.md"
if [ ! -f "$SRC" ]; then
  red "FAIL: ingest-source-00-skills-knowledge-ingest-source skills/knowledge-ingest-source/SKILL.md not found"
  exit 1
fi

# Domain-prefixed generic name (the repo convention: 'ingest' must carry the
# plugin's 'knowledge-' prefix) — the exact-name assert proves it.
assert_grep 'name: knowledge-ingest-source' "$SRC" "ingest-source-01-frontmatter-name-domain-prefixed knowledge-ingest-source: frontmatter name (domain-prefixed)"

# Standalone posture: NO research-pipeline scaffold.
assert_grep 'no research run' "$SRC" "ingest-source-02-states-no-research-run knowledge-ingest-source: states the no-research-run standalone posture"
assert_not_grep 'reads .*fetch-manifest.json' "$SRC" "ingest-source-03-does-not-consume-fetch knowledge-ingest-source: does NOT consume a fetch-manifest (that is the batch knowledge-ingest path)"

# Binding + wiki-root resolution, same pre-flight as knowledge-ingest.
assert_grep 'knowledge-binding.py read' "$SRC" "ingest-source-04-reads-binding-knowledge-py knowledge-ingest-source: reads the binding via knowledge-binding.py"
assert_grep '[Pp]robe.*cogni-wiki' "$SRC" "ingest-source-05-probes-cogni-wiki knowledge-ingest-source: probes cogni-wiki"
assert_grep 'resolve_wiki_scripts' "$SRC" "ingest-source-06-resolves-wiki-ingest-script knowledge-ingest-source: resolves the wiki-ingest script dir via the resolve_wiki_scripts probe"

# Cache population — fetch-cache.py store with the required flags.
assert_grep 'fetch-cache.py store' "$SRC" "ingest-source-07-populates-cache-fetch-py knowledge-ingest-source: populates the cache via fetch-cache.py store"
assert_grep 'knowledge-root' "$SRC" "ingest-source-08-store-passes-knowledge-root knowledge-ingest-source: store passes --knowledge-root"
assert_grep 'fetch-method webfetch' "$SRC" "ingest-source-09-store-uses-honest-fetch knowledge-ingest-source: store uses the honest --fetch-method webfetch for a URL"
# Local inputs deposit honestly via the additive non-web --fetch-method direct
# (ratified in fetch-cache.py VALID_FETCH_METHODS) — never as a webfetch lie.
assert_grep 'fetch-method direct' "$SRC" "ingest-source-10-local-inputs-store-honest knowledge-ingest-source: local inputs store via the honest --fetch-method direct"

# Dedup via the shared wiki-grounding primitive, with diff-before-write.
assert_grep 'wiki-grounding.py rank' "$SRC" "ingest-source-11-dedups-shared-wiki-grounding knowledge-ingest-source: dedups via the shared wiki-grounding.py rank primitive"
assert_grep 'diff-before-write' "$SRC" "ingest-source-12-routes-collision-diff-before knowledge-ingest-source: routes a collision to the diff-before-write update path"

# Reuse the unchanged source-ingester via Task (NOT a Skill dispatch).
assert_grep 'Task(source-ingester' "$SRC" "ingest-source-13-dispatches-unchanged-source-ingester knowledge-ingest-source: dispatches the unchanged source-ingester via Task"
assert_not_grep 'Skill("cogni-knowledge:source-ingester' "$SRC" "ingest-source-14-no-skill-cogni-knowledge knowledge-ingest-source: no Skill('cogni-knowledge:source-ingester) — agents go through Task"
assert_grep 'wiki/sources/' "$SRC" "ingest-source-15-lands-type-source-page knowledge-ingest-source: lands a type: source page in wiki/sources/"

# Post-write lockstep — same three helpers as knowledge-ingest Step 4.
assert_grep 'backlink_audit.py' "$SRC" "ingest-source-16-backlink-lockstep-audit-py knowledge-ingest-source: backlink lockstep via backlink_audit.py"
assert_grep 'apply-plan' "$SRC" "ingest-source-17-writes-backlinks-apply-plan knowledge-ingest-source: writes backlinks via --apply-plan"
assert_grep 'wiki_index_update.py' "$SRC" "ingest-source-18-index-update-wiki-py knowledge-ingest-source: index update via wiki_index_update.py"
assert_grep 'max-summary' "$SRC" "ingest-source-19-passes-max-summary-clamp knowledge-ingest-source: passes the --max-summary clamp backstop"
assert_grep 'sanitize_summary' "$SRC" "ingest-source-20-sanitizes-index-one-liner knowledge-ingest-source: sanitizes the index one-liner before the index update"
assert_grep 'config_bump.py' "$SRC" "ingest-source-21-bumps-entries-count-config knowledge-ingest-source: bumps entries_count via config_bump.py"
assert_grep 'entries_count' "$SRC" "ingest-source-22-references-entries-count knowledge-ingest-source: references entries_count"

# PDF posture: Read-tool page loop only, no homegrown parser.
assert_grep 'is_pdf_response' "$SRC" "ingest-source-23-detects-pdfs-pdf-response knowledge-ingest-source: detects PDFs via is_pdf_response"
assert_grep 'Read tool' "$SRC" "ingest-source-24-reads-pdfs-read-tool knowledge-ingest-source: reads PDFs via the Read tool page loop"
assert_grep 'pdf_render_unavailable' "$SRC" "ingest-source-25-honest-pdf-render-unavailable knowledge-ingest-source: honest pdf_render_unavailable reason on a render failure"
assert_grep 'text-layer extractor\|pdf-extract.py\|pdf_extract_text' "$SRC" "ingest-source-26-documents-optional-pypdf-text knowledge-ingest-source: documents the optional pypdf text-layer fallback (#583)"
# The skill must not call out to a compiled PDF library — the optional
# pure-Python `pypdf` (lowercase) is the only permitted parser, so
# pdfplumber/pdfminer/poppler stay blocked (the assert is case-sensitive, so
# lowercase 'pypdf' never matched 'PyPDF'; 'PyPDF' is dropped from the set).
assert_not_grep 'pdfplumber\|pdfminer\|poppler' "$SRC" "ingest-source-27-no-compiled-pdf-parser knowledge-ingest-source: no compiled PDF-parser dependency"

# Input modes: the surface accepts a URL OR a local input — exactly one of
# --url / --file / --paste / --interview.
assert_grep '\-\-file' "$SRC" "ingest-source-28-accepts-local-file knowledge-ingest-source: accepts a local file via --file"
assert_grep '\-\-paste' "$SRC" "ingest-source-29-accepts-pasted-text-paste knowledge-ingest-source: accepts pasted text via --paste"
assert_grep '\-\-interview' "$SRC" "ingest-source-30-accepts-local-interview-note knowledge-ingest-source: accepts a local interview note via --interview"

# Local-file normalization via the vendored convert_to_md.py, queue mode via the
# vendored wiki_queue.py — both resolved through the existing wiki-ingest probe.
assert_grep 'convert_to_md.py' "$SRC" "ingest-source-31-normalizes-local-files-vendored knowledge-ingest-source: normalizes local files via the vendored convert_to_md.py"
assert_grep 'wiki_queue.py' "$SRC" "ingest-source-32-queue-mode-vendored-wiki knowledge-ingest-source: queue mode via the vendored wiki_queue.py"

# Interview page type → wiki/interviews/ via the source-ingester PAGE_TYPE param.
assert_grep 'type: interview' "$SRC" "ingest-source-33-interview-note-lands-type knowledge-ingest-source: an interview note lands as type: interview"
assert_grep 'wiki/interviews/' "$SRC" "ingest-source-34-interview-note-lands-wiki knowledge-ingest-source: an interview note lands in wiki/interviews/"
assert_grep 'PAGE_TYPE' "$SRC" "ingest-source-35-threads-page-type-source knowledge-ingest-source: threads PAGE_TYPE to the source-ingester dispatch"

# .docx normalization is the OPTIONAL external markitdown tool — its absence must
# degrade to an honest error, never a fabricated body / crash.
assert_grep 'markitdown' "$SRC" "ingest-source-36-names-markitdown-optional-external knowledge-ingest-source: names markitdown as the optional external .docx normalizer"

# allowed-tools must include WebFetch (URL fetch), Task (source-ingester), and
# Bash (the script calls). Must NOT include Skill (agents go through Task).
assert_grep 'allowed-tools:.*WebFetch' "$SRC" "ingest-source-37-allowed-tools-includes-webfetch knowledge-ingest-source: allowed-tools includes WebFetch"
assert_grep 'allowed-tools:.*Task' "$SRC" "ingest-source-38-allowed-tools-includes-task knowledge-ingest-source: allowed-tools includes Task"
assert_grep 'allowed-tools:.*Bash' "$SRC" "ingest-source-39-allowed-tools-includes-bash knowledge-ingest-source: allowed-tools includes Bash"
assert_not_grep 'allowed-tools:.*Skill' "$SRC" "ingest-source-40-allowed-tools-excludes-skill knowledge-ingest-source: allowed-tools excludes Skill (agents go through Task)"

# --- source-ingester: additive PAGE_TYPE param ---------------------------
# The standalone surface reuses the research write path with PAGE_TYPE=source as
# the byte-identical default; the agent gained an additive PAGE_TYPE param that
# routes interview → wiki/interviews/. The source default literals must survive.
INGESTER="$PLUGIN_ROOT/agents/source-ingester.md"
assert_grep 'type: source' "$INGESTER" "ingest-source-41-emits-type-source-page source-ingester: still emits type: source (PAGE_TYPE=source is the byte-identical default)"
assert_grep 'PAGE_TYPE' "$INGESTER" "ingest-source-42-gained-additive-page-type source-ingester: gained the additive PAGE_TYPE param"
assert_grep 'wiki/interviews/' "$INGESTER" "ingest-source-43-page-type-interview-routes source-ingester: PAGE_TYPE=interview routes to wiki/interviews/"

# --- Step 5.4 evidence-aware refresh signal (synthesis-impact) -----------
# A new source may outdate an existing synthesis built on related evidence; the
# post-write lockstep scans for that and persists refresh candidates, surfaced in
# the Step-6 summary. Pure observability, fail-soft — must not roll back the page.
assert_grep 'synthesis-impact.py scan' "$SRC" "ingest-source-44-step-5-4-scans-dependent knowledge-ingest-source: Step 5.4 scans dependent syntheses via synthesis-impact.py"
assert_grep 'add-refresh-candidates' "$SRC" "ingest-source-45-persists-refresh-candidates-knowledge knowledge-ingest-source: persists refresh candidates via knowledge-binding.py add-refresh-candidates"
assert_grep '\-\-related' "$SRC" "ingest-source-46-reuses-step-3-dedup knowledge-ingest-source: reuses the Step-3 dedup neighborhood as --related"
assert_grep 'may be outdated by this source' "$SRC" "ingest-source-47-step-6-surfaces-dependent knowledge-ingest-source: Step 6 surfaces the dependent-synthesis warning line"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
