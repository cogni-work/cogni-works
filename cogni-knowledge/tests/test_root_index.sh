#!/usr/bin/env bash
# test_root_index.sh — deterministic-renderer test for root_index.py.
#
# root_index.py is the root-portal sibling of sub_index.py: it renders the root
# wiki/index.md as a curated MAP (an overview-narrative intro + one section per
# real theme, each linking the per-type sub-indexes WITH counts) instead of a
# flat per-page bullet dump. The vendored wiki_index_update.py is never touched
# (Option A), so test_vendored_engine_parity.sh stays green.
#
# Asserts:
#   1. render rewrites a legacy bulleted root into a curated MAP: ROOT-INDEX
#      ownership marker + intro, and the envelope reports changed:true.
#   2. Per-theme count-link line shows each per-type sub-index WITH its count
#      (Sources (2), Concepts (1), …) and links to wiki/<type>/index.md.
#   3. NO per-page `- [[slug]]` source bullets remain on the root (they live in
#      the sub-indexes now).
#   4. A carried PORTAL-LEADIN machine span survives a re-render byte-for-byte
#      (date and all — never regenerated).
#  4b. A theme that carries NO lead-in is seeded a deterministic engine-owned
#      default PORTAL-LEADIN span (the legibility default, mirroring the
#      perspectives facet defaults); an authored lead-in is not clobbered.
#   5. The non-theme container headings (## Categories, ## Syntheses) are dropped
#      (no page carries them as a theme_label); a synthesis appears as
#      Syntheses (n) inside its backing-source theme instead.
#   6. The OVERVIEW-NARRATIVE block folded into index.md (via overview_update.py
#      --target-file index.md) is carried into the curated intro.
#   7. BYTE-IDEMPOTENT: re-rendering an unchanged wiki reports changed:false.
#   8. reflow/collapse-STABLE: wiki_index_update.py --reflow-only + --collapse-only
#      on the curated MAP is a byte-for-byte no-op (the Step 10.5 lint --fix=all
#      gate ordering), and a following re-render stays changed:false.
#   9. TRANSIENT BULLETS: a freshly re-filed `- [[slug]]` bullet (next ingest) is
#      dropped on the next render (the curated MAP is the resting state).
#  10. counts subcommand on sub_index.py returns {theme: n} per type.
#  11. overview_update.py narrative-splice --target-file default is overview.md
#      (back-compat); index.md is opt-in.
#  12. HUMAN-PAGE: a hand-authored index.md (no ## heading, no MACHINE-OWNED span)
#      is skipped, not clobbered.
#  13. python3.9 floor: root_index.py carries `from __future__ import annotations`
#      and parses cleanly under ast.parse.
#  14. render stamps last_rendered_engine_version (= plugin version) into
#      config.json so health.py can flag render-engine lag after an upgrade.
#
# bash 3.2 + stdlib python3 only. Posix only (render uses fcntl.flock via
# cogni-wiki's _wiki_lock).

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOT_SCRIPT="$PLUGIN_ROOT/scripts/root_index.py"
SUB_SCRIPT="$PLUGIN_ROOT/scripts/sub_index.py"
OVR_SCRIPT="$PLUGIN_ROOT/scripts/overview_update.py"
WSD="$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"
errors=0

if [ ! -f "$WSD/_wikilib.py" ]; then
  red "SKIP: cogni-wiki _wikilib not found at $WSD (render needs _wiki_lock)"
  exit 0
fi

WIKI="$(mktemp -d)"
trap 'rm -rf "$WIKI" "$PROSE" "$BEFORE" 2>/dev/null || true' EXIT
mkdir -p "$WIKI/wiki/sources" "$WIKI/wiki/concepts" "$WIKI/wiki/questions" \
         "$WIKI/wiki/syntheses" "$WIKI/.cogni-wiki"

# --- pages: two sources + a concept + a question + a synthesis, theme "Scope" ---
cat > "$WIKI/wiki/sources/src-a.md" <<'EOF'
---
id: src-a
title: Source A
type: source
theme_label: Scope
sources: ["https://example.com/a"]
pre_extracted_claims:
  - id: clm-1
    text: A claim about scope.
---
Body A.
EOF
cat > "$WIKI/wiki/sources/src-b.md" <<'EOF'
---
id: src-b
title: Source B
type: source
theme_label: Scope
sources: ["https://example.com/b"]
pre_extracted_claims:
  - id: clm-1
    text: Another scope claim.
---
Body B.
EOF
# --- a source under a NON-ASCII theme ("KI Bußgelder") to prove the deep-link
#     anchor matches the rendered `## <theme>` heading (lowercase + space→hyphen,
#     ß preserved) and NOT slugify's transliterated form (`ki-bussgelder`). ---
cat > "$WIKI/wiki/sources/src-pen.md" <<'EOF'
---
id: src-pen
title: Source Pen
type: source
theme_label: KI Bußgelder
sources: ["https://example.com/pen"]
pre_extracted_claims:
  - id: clm-1
    text: A claim about penalties.
---
Body Pen.
EOF
# --- a source whose theme_label carries a DOUBLE internal space + trailing
#     whitespace ("AI  Liability ") — the A1 false-filtering drift case (#933).
#     The renderer collapses theme whitespace to a single space at the producer
#     sites, so the heading reads `## AI Liability` and root_index._heading_anchor
#     ( \s+ → %20 ) yields `#AI%20Liability`, which MATCHES the rendered heading.
#     Without the collapse the heading would keep the double space (`## AI  Liability`)
#     while the anchor still collapsed to a single %20 → silent page-top landing. ---
cat > "$WIKI/wiki/sources/src-drift.md" <<'EOF'
---
id: src-drift
title: Source Drift
type: source
theme_label: "AI  Liability "
sources: ["https://example.com/drift"]
pre_extracted_claims:
  - id: clm-1
    text: A claim about AI liability.
---
Body Drift.
EOF
cat > "$WIKI/wiki/concepts/high-risk.md" <<'EOF'
---
id: high-risk
title: High-risk system
type: concept
sources:
  - wiki://src-a
distilled_claims:
  - claim_id: dcl-1
    text: High-risk definition.
---
<!-- MACHINE-OWNED:SUMMARY:START -->
A high-risk AI system.
<!-- MACHINE-OWNED:SUMMARY:END -->
EOF
cat > "$WIKI/wiki/questions/q-scope.md" <<'EOF'
---
id: q-scope
title: What is in scope?
type: question
theme_label: Scope
---
## Findings
- [[src-a]]
EOF
cat > "$WIKI/wiki/syntheses/scope-synth.md" <<'EOF'
---
id: scope-synth
title: Scope synthesis
type: synthesis
sources:
  - wiki://src-a
  - wiki://src-b
---
A synthesis of scope.
EOF

# --- legacy bulleted root (what wiki_index_update.py produces) with a
#     ## Categories container, a themed section + PORTAL-LEADIN, and a fixed
#     ## Syntheses heading ---
LEADIN_LINE='<!-- MACHINE-OWNED:PORTAL-LEADIN:START refreshed:2026-06-01 bullets:3 -->'
cat > "$WIKI/wiki/index.md" <<EOF
# Test Knowledge Base

_Curated front door. The overview narrative lives in wiki/overview.md._

## Categories

<!-- MACHINE-OWNED:PORTAL-LEADIN:START refreshed:2026-01-01 bullets:0 -->
_Theme map pending._
<!-- MACHINE-OWNED:PORTAL-LEADIN:END -->

## Scope

$LEADIN_LINE
Framing for the scope theme.
<!-- MACHINE-OWNED:PORTAL-LEADIN:END -->

- [[src-a]] — A claim about scope.
- [[src-b]] — Another scope claim.
- [[q-scope]] — What is in scope?

## Syntheses

- [[scope-synth]] — Scope synthesis
EOF

IDX="$WIKI/wiki/index.md"
PROSE=""; BEFORE=""

# === 1. render → curated MAP ===
OUT="$(python3 "$ROOT_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")"
echo "$OUT" | grep -q '"changed": true' \
  && green "PASS: root-index-01-1-1-render-reports 1-1 render reports changed:true" \
  || { red "FAIL: root-index-01-1-1-render-reports 1-1 render not changed:true ($OUT)"; errors=$((errors+1)); }
assert_grep "MACHINE-OWNED:ROOT-INDEX" "$IDX" "root-index-02-1-2-root-index 1-2 ROOT-INDEX ownership marker present"
assert_grep "Curated map of this knowledge base" "$IDX" "root-index-03-1-3-curated-intro 1-3 curated intro line present"
# AC#3 (no-fabrication half): the source fixture index carried no
# OVERVIEW-NARRATIVE block, so the renderer must NOT invent a placeholder one.
assert_not_grep "MACHINE-OWNED:OVERVIEW-NARRATIVE" "$IDX" "root-index-04-1b-narrative-span-fabricated 1b no narrative span fabricated when none authored"

# === 1c. the 5W1H intent spine is a PRIMARY front-door entry (R8) ===
# Promoted from a secondary italic "_See also:_" line to a bold primary
# wayfinding entry leading with the intent spine.
assert_grep "Start here — browse by intent:" "$IDX" "root-index-05-1c-1-intent-spine 1c-1 intent spine promoted to a primary front-door line (R8)"
assert_grep "Perspectives (5W1H) →](perspectives.md)" "$IDX" "root-index-06-1c-2-spine-links 1c-2 spine links the 5W1H perspectives overlay (R8)"
assert_not_grep "_See also: \[Perspectives (5W1H)\](perspectives.md)" "$IDX" "root-index-07-1c-3-old-secondary 1c-3 old secondary 'See also' framing is gone (R8)"
# === 1d. secondary-view labels (R10) + overview-stub signpost (R11) ===
assert_grep "Other views:" "$IDX" "root-index-08-1d-1-secondary-view 1d-1 secondary-view labels render on the root portal (R10)"
assert_grep "\[Recent syntheses\](overview.md)" "$IDX" "root-index-09-1d-2-overview-stub 1d-2 overview stub signposted from the spine — Recent syntheses (R11)"

# === 2. per-theme count-links with counts AND theme-scoped deep-link anchors ===
# The link now deep-links into the theme's `## <theme>` section of each
# sub-index (`<type>/index.md#<anchor>`), not the bare unfiltered sub-index.
# Obsidian resolves a heading link by the heading's literal text: the anchor
# preserves case (theme "Scope" → `## Scope` → #Scope), spaces → %20.
assert_grep "Sources (2)](sources/index.md#Scope)" "$IDX" "root-index-10-2-1-sources-2 2-1 Sources (2) deep-link to #Scope"
assert_grep "Concepts (1)](concepts/index.md#Scope)" "$IDX" "root-index-11-2-2-concepts-1 2-2 Concepts (1) deep-link to #Scope"
assert_grep "Questions (1)](questions/index.md#Scope)" "$IDX" "root-index-12-2-3-questions-1 2-3 Questions (1) deep-link to #Scope"
assert_grep "Syntheses (1)](syntheses/index.md#Scope)" "$IDX" "root-index-13-2-4-syntheses-1 2-4 Syntheses (1) deep-link to #Scope (folded into theme)"

# === 2b. distinct per-theme anchors + non-ASCII heading-anchor (Obsidian convention) ===
assert_grep '^## KI Bußgelder' "$IDX" "root-index-14-2b-1-non-ascii 2b-1 non-ASCII theme heading kept verbatim"
# The deep link is the Obsidian heading-text anchor for `## KI Bußgelder`:
# literal text, space → %20, case + ß preserved verbatim (#KI%20Bußgelder) —
# distinct from the Scope theme's #Scope (so per-theme Explore lines differ).
assert_grep "Sources (1)](sources/index.md#KI%20Bußgelder)" "$IDX" "root-index-15-2b-2-non-ascii 2b-2 non-ASCII theme deep-links to #KI%20Bußgelder"
# Regression: NOT the GFM slug form, and NOT slugify's transliterated form
# (neither resolves to the heading in Obsidian).
assert_not_grep "sources/index.md#ki-bußgelder)" "$IDX" "root-index-16-2b-3-anchor-gfm 2b-3 anchor is NOT the GFM slug form #ki-bußgelder"
assert_not_grep "sources/index.md#ki-bussgelder)" "$IDX" "root-index-17-2b-4-anchor-transliterated 2b-4 anchor is NOT the transliterated slugify form #ki-bussgelder"

# === 2c. A1 false-filtering fix (#933): theme-label whitespace is normalized so
#         the rendered `## <theme>` heading and the count-link anchor AGREE. ===
# The fixture theme_label is "AI  Liability " (double internal space + trailing).
# The producer-site _collapse normalizes it to "AI Liability", so the heading is
# single-space and the anchor is the matching single-%20 fragment.
assert_grep '^## AI Liability' "$IDX" "root-index-18-2c-1-double-space 2c-1 double-space theme heading collapsed to single space"
assert_not_grep '^## AI  Liability' "$IDX" "root-index-19-2c-2-heading-does 2c-2 heading does NOT keep the double space (the drift)"
assert_grep "Sources (1)](sources/index.md#AI%20Liability)" "$IDX" "root-index-20-2c-3-count-link 2c-3 count-link anchors to the single-%20 fragment that matches the heading"
# Regression: the heading↔anchor MUST agree — the drift would have rendered the
# double-space heading while the anchor collapsed, landing the click at page top.
assert_not_grep "sources/index.md#AI%20%20Liability)" "$IDX" "root-index-21-2c-4-anchor-un 2c-4 anchor is NOT the un-collapsed double-%20 form"

# === 3. no per-page source bullets remain on the root ===
assert_not_grep '^- \[\[src-a\]\]' "$IDX" "root-index-22-3-1-per-page 3-1 per-page src-a bullet dropped from root"
assert_not_grep '^- \[\[scope-synth\]\]' "$IDX" "root-index-23-3-2-per-page 3-2 per-page synthesis bullet dropped from root"

# === 4. carried PORTAL-LEADIN span (verbatim, date intact) ===
assert_grep "refreshed:2026-06-01 bullets:3" "$IDX" "root-index-24-4-1-portal-leadin 4-1 PORTAL-LEADIN carried with original date"
assert_grep "Framing for the scope theme." "$IDX" "root-index-25-4-2-portal-leadin 4-2 PORTAL-LEADIN inner prose carried"

# === 4b. seeded default lead-in for a theme that carries none (#946) ===
# KI Bußgelder has NO authored lead-in in the legacy root, so the renderer seeds a
# deterministic engine-owned PORTAL-LEADIN span that names the theme — the
# legibility default, mirroring the perspectives facet defaults. AC1.
assert_grep "grouped under the \*\*KI Bußgelder\*\* theme" "$IDX" "root-index-26-4b-1-lead-theme 4b-1 no-lead-in theme seeded a default PORTAL-LEADIN one-liner"
# AC2 (no clobber): the Scope theme's authored span is NOT replaced by the default.
assert_not_grep "grouped under the \*\*Scope\*\* theme" "$IDX" "root-index-27-4b-2-authored-lead 4b-2 authored lead-in not clobbered by the seeded default"

# === 5. container headings dropped ===
assert_not_grep '^## Categories' "$IDX" "root-index-28-5-1-categories-container 5-1 ## Categories container heading dropped"
assert_not_grep '^## Syntheses' "$IDX" "root-index-29-5-2-syntheses-fixed 5-2 ## Syntheses fixed heading dropped (folded per-theme)"
assert_grep '^## Scope' "$IDX" "root-index-30-5-3-real-theme 5-3 real theme heading kept"

# === 6. OVERVIEW-NARRATIVE fold carried into intro ===
PROSE="$(mktemp)"; printf 'This base maps scope for SMEs.' > "$PROSE"
python3 "$OVR_SCRIPT" narrative-splice --wiki-root "$WIKI" --prose-file "$PROSE" \
  --target-file index.md --wiki-scripts-dir "$WSD" >/dev/null
python3 "$ROOT_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" >/dev/null
assert_grep "MACHINE-OWNED:OVERVIEW-NARRATIVE" "$IDX" "root-index-31-6-1-overview-narrative 6-1 OVERVIEW-NARRATIVE block in index.md"
assert_grep "This base maps scope for SMEs." "$IDX" "root-index-32-6-2-overview-narrative 6-2 overview narrative prose in intro"

# === 7. idempotent re-render ===
OUT2="$(python3 "$ROOT_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")"
echo "$OUT2" | grep -q '"changed": false' \
  && green "PASS: root-index-33-7-re-render-byte 7 re-render is byte-identical no-op (changed:false)" \
  || { red "FAIL: root-index-33-7-re-render-byte 7 re-render not idempotent ($OUT2)"; errors=$((errors+1)); }

# === 7b. AC#3 (verbatim-preservation half): a real OVERVIEW-NARRATIVE survives
#         another re-render byte-for-byte (section 6 authored it; re-render again
#         and confirm the prose is still carried verbatim, not reset/placeheld). ===
python3 "$ROOT_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" >/dev/null
assert_grep "This base maps scope for SMEs." "$IDX" "root-index-34-7b-real-overview-narrative 7b real OVERVIEW-NARRATIVE preserved verbatim across re-render"

# === 8. reflow/collapse stability ===
BEFORE="$(mktemp)"; cp "$IDX" "$BEFORE"
python3 "$WSD/wiki_index_update.py" --wiki-root "$WIKI" --reflow-only >/dev/null 2>&1 || true
python3 "$WSD/wiki_index_update.py" --wiki-root "$WIKI" --collapse-only >/dev/null 2>&1 || true
if diff -q "$BEFORE" "$IDX" >/dev/null 2>&1; then
  green "PASS: root-index-35-8-1-curated-map 8-1 curated MAP byte-stable under reflow-only + collapse-only"
else
  red "FAIL: root-index-35-8-1-curated-map 8-1 curated MAP drifted under reflow/collapse"; diff "$BEFORE" "$IDX" || true; errors=$((errors+1))
fi
OUT3="$(python3 "$ROOT_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")"
echo "$OUT3" | grep -q '"changed": false' \
  && green "PASS: root-index-36-8-2-re-render 8-2 re-render after reflow/collapse stays changed:false" \
  || { red "FAIL: root-index-36-8-2-re-render 8-2 re-render after fixers not idempotent ($OUT3)"; errors=$((errors+1)); }

# === 9. transient bullets: a freshly re-filed bullet is dropped next render ===
python3 - "$IDX" <<'PY'
import sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
# simulate the next ingest re-filing a source bullet under ## Scope
t = t.replace("## Scope\n", "## Scope\n\n- [[src-c]] — a freshly ingested source\n", 1)
open(p, "w", encoding="utf-8").write(t)
PY
assert_grep '\[\[src-c\]\]' "$IDX" "root-index-37-9-1-transient-bullet 9-1 transient bullet present before render"
python3 "$ROOT_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" >/dev/null
assert_not_grep '\[\[src-c\]\]' "$IDX" "root-index-38-9-2-transient-bullet 9-2 transient bullet dropped on next render"

# === 10. counts subcommand ===
CNT="$(python3 "$SUB_SCRIPT" counts --type sources --wiki-root "$WIKI")"
echo "$CNT" | grep -q '"Scope": 2' \
  && green "PASS: root-index-39-10-counts-subcommand-returns 10 counts subcommand returns {theme: n}" \
  || { red "FAIL: root-index-39-10-counts-subcommand-returns 10 counts wrong ($CNT)"; errors=$((errors+1)); }

# === 11. overview_update --target-file back-compat (default overview.md) ===
python3 "$OVR_SCRIPT" narrative-splice --wiki-root "$WIKI" --prose-file "$PROSE" \
  --wiki-scripts-dir "$WSD" >/dev/null
[ -f "$WIKI/wiki/overview.md" ] \
  && green "PASS: root-index-40-11-narrative-splice-default 11 narrative-splice default still writes wiki/overview.md" \
  || { red "FAIL: root-index-40-11-narrative-splice-default 11 default target did not write overview.md"; errors=$((errors+1)); }

# === 12. human-page skip ===
HWIKI="$(mktemp -d)"; mkdir -p "$HWIKI/wiki/sources" "$HWIKI/.cogni-wiki"
printf '# My hand-written portal\n\nJust prose, no headings, no markers.\n' > "$HWIKI/wiki/index.md"
HOUT="$(python3 "$ROOT_SCRIPT" render --wiki-root "$HWIKI" --wiki-scripts-dir "$WSD")"
echo "$HOUT" | grep -q '"skipped_human_page": true' \
  && green "PASS: root-index-41-12-1-hand-authored 12-1 hand-authored portal skipped" \
  || { red "FAIL: root-index-41-12-1-hand-authored 12-1 human page not skipped ($HOUT)"; errors=$((errors+1)); }
grep -q "hand-written portal" "$HWIKI/wiki/index.md" \
  && green "PASS: root-index-42-12-2-hand-authored 12-2 hand-authored portal left untouched" \
  || { red "FAIL: root-index-42-12-2-hand-authored 12-2 human page clobbered"; errors=$((errors+1)); }
rm -rf "$HWIKI"

# === 13. python3.9 floor ===
grep -q "from __future__ import annotations" "$ROOT_SCRIPT" \
  && green "PASS: root-index-43-13-1-root-index 13-1 root_index.py carries __future__ annotations" \
  || { red "FAIL: root-index-43-13-1-root-index 13-1 missing __future__ annotations"; errors=$((errors+1)); }
python3 -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$ROOT_SCRIPT" \
  && green "PASS: root-index-44-13-2-root-index 13-2 root_index.py parses under ast" \
  || { red "FAIL: root-index-44-13-2-root-index 13-2 ast.parse failed"; errors=$((errors+1)); }

# === 14. render stamps last_rendered_engine_version into config.json (#947) ===
# A live render records the producing engine version so health.py can flag a
# base whose curated indexes lag a plugin upgrade. The fixture above carries no
# config.json (the renderer does not require one), so seed a minimal one, render,
# and confirm the stamp landed and equals the plugin's current version.
printf '{"wiki_slug":"test","title":"Test","entries_count":0,"schema_version":"0.0.9"}\n' \
  > "$WIKI/.cogni-wiki/config.json"
python3 "$ROOT_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" >/dev/null
PLUGIN_VER="$(python3 -c "import json; print(json.load(open('$PLUGIN_ROOT/.claude-plugin/plugin.json'))['version'])")"
STAMP="$(python3 -c "import json; print(json.load(open('$WIKI/.cogni-wiki/config.json')).get('last_rendered_engine_version',''))")"
[ "$STAMP" = "$PLUGIN_VER" ] \
  && green "PASS: root-index-45-14-render-stamped-last 14 render stamped last_rendered_engine_version=$STAMP" \
  || { red "FAIL: root-index-45-14-render-stamped-last 14 stamp '$STAMP' != plugin version '$PLUGIN_VER'"; errors=$((errors+1)); }

echo
if [ "$errors" -eq 0 ]; then
  green "test_root_index.sh: ALL PASS"
else
  red "test_root_index.sh: $errors failure(s)"; exit 1
fi
