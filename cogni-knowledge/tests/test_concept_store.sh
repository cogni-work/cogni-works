#!/usr/bin/env bash
# test_concept_store.sh — smoke test for concept-store.py (Phase 4.5, #336).
#
# Asserts:
#   1. init creates an empty distill-manifest.json (schema 0.1.1), idempotent.
#   2. merge CREATE: a concept + an entity page land on disk with the expected
#      frontmatter (wiki:// sources, distilled_claims, status: distilled),
#      MACHINE-OWNED sentinels, and bare [[source-slug]] backlinks in the body.
#   3. merge UPDATE (cross-run compounding): a second run on the same slug with
#      an EXACT-same-text claim from a NEW source unions the backlink onto the
#      existing claim (one line, not a duplicate), appends a genuinely-new claim,
#      bumps `updated:` but NOT `created:`, unions distilled_from_research, and
#      preserves the human ## Notes region byte-for-byte.
#   4. CLAIM-ID NAMESPACING: two sources BOTH carrying `clm-001` but asserting
#      DIFFERENT facts produce TWO distinct claims (no false merge on bare id).
#   5. BYTE-STABLE re-run: merging identical records twice leaves the page
#      byte-identical and reports every concept `unchanged`.
#   6. FAIL-SAFE: a near-but-distinct claim (sim < 0.85) is kept, not over-merged.
#   7. FOUNDATION collision → skipped (reason: foundation_collision).
#   8. NO-SENTINEL human page at the target slug → skipped (reason:
#      no_sentinels_human_page); the page is left untouched.
#   9. The manifest carries claims_attached_total / claims_deduped_total.
#
# bash 3.2 + stdlib python3 only. Posix only (concept-store uses fcntl.flock via
# cogni-wiki's _wiki_lock).

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/concept-store.py"
WSD="$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: concept-store-00-script-present concept-store.py not found at $SCRIPT"
  exit 1
fi
if [ ! -d "$WSD" ]; then
  red "FAIL: concept-store-00-wiki-scripts-present cogni-wiki wiki-ingest scripts not found at $WSD"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
errors=0

WIKI="$WORK/wiki-root"
PROJ="$WORK/project"
mkdir -p "$WIKI/wiki/sources" "$WIKI/wiki/concepts" "$WIKI/wiki/entities" "$WIKI/.cogni-wiki" "$PROJ/.metadata"
echo '{"schema_version":"0.0.6","entries_count":0}' > "$WIKI/.cogni-wiki/config.json"
for s in src-a src-b src-c; do
  printf -- '---\nid: %s\ntype: source\n---\n# x\n' "$s" > "$WIKI/wiki/sources/$s.md"
done

# Tiny envelope-field reader.
field() { python3 -c 'import sys,json;d=json.load(sys.stdin);print(eval("d"+sys.argv[1]))' "$1"; }

# --- 1. init -----------------------------------------------------------------
OUT=$(python3 "$SCRIPT" init --project-path "$PROJ")
if [ "$(echo "$OUT" | field '["success"]')" = "True" ] && [ -f "$PROJ/.metadata/distill-manifest.json" ]; then
  green "PASS: concept-store-01-init-creates-distill-manifest init creates distill-manifest.json"
else
  red "FAIL: concept-store-01-init-creates-distill-manifest init"; errors=$((errors+1))
fi
OUT=$(python3 "$SCRIPT" init --project-path "$PROJ")
[ "$(echo "$OUT" | field '["data"]["created"]')" = "False" ] && green "PASS: concept-store-02-init-idempotent init idempotent" || { red "FAIL: concept-store-02-init-idempotent init not idempotent"; errors=$((errors+1)); }

# --- 2. merge CREATE ---------------------------------------------------------
cat > "$PROJ/.metadata/rec1.txt" <<'EOF'
- title: Annex III Categories
  type: concept
  summary: Categories of high-risk AI systems.
  related: conformity-assessment
  claim: src-a#clm-003 | Annex III lists eight categories of high-risk AI systems.
  claim: src-a#clm-007 | Providers must register high-risk systems in the EU database.
- title: European Commission
  type: entity
  summary: The EU executive body.
  claim: src-b#clm-002 | The European Commission published the GPAI Code of Practice.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ/.metadata/rec1.txt" --wiki-root "$WIKI" --project-path "$PROJ" --project-slug proj-1 --wiki-scripts-dir "$WSD")
CPAGE="$WIKI/wiki/concepts/annex-iii-categories.md"
EPAGE="$WIKI/wiki/entities/european-commission.md"
[ "$(echo "$OUT" | field '["data"]["n_created"]')" = "2" ] && green "PASS: concept-store-03-merge-created-2-pages merge created 2 pages" || { red "FAIL: concept-store-03-merge-created-2-pages n_created != 2"; errors=$((errors+1)); }
[ -f "$CPAGE" ] && [ -f "$EPAGE" ] && green "PASS: concept-store-04-concept-entity-pages-disk concept + entity pages on disk" || { red "FAIL: concept-store-04-concept-entity-pages-disk pages missing"; errors=$((errors+1)); }
assert_grep 'type: concept' "$CPAGE" "concept-store-05-concept-page-type concept page: type"
assert_grep 'status: distilled' "$CPAGE" "concept-store-06-concept-page-status-distilled concept page: status distilled"
assert_grep 'wiki://src-a' "$CPAGE" "concept-store-07-concept-page-wiki-source concept page: wiki:// source provenance"
assert_grep 'MACHINE-OWNED:CLAIMS:START' "$CPAGE" "concept-store-08-concept-page-machine-owned concept page: machine-owned sentinels"
assert_grep '\[\[src-a\]\]' "$CPAGE" "concept-store-09-concept-page-bare-source concept page: bare [[source-slug]] backlink (link-graph edge)"
assert_grep 'distilled_from_research' "$CPAGE" "concept-store-10-concept-page-distilled-from concept page: distilled_from_research"
# Reader-facing engine-owned type line directly under the H1 (#931).
assert_grep '^Type: Concept · distilled$' "$CPAGE" "concept-store-11-concept-page-type-concept concept page: Type: Concept · distilled line under H1"
assert_grep '^Type: Entity · distilled$' "$EPAGE" "concept-store-12-entity-page-type-entity entity page: Type: Entity · distilled line under H1"
# The type line sits immediately below the H1 (one blank line between).
python3 - "$CPAGE" <<'PY' && green "PASS: concept-store-13-concept-page-type-line concept page type line is immediately below the H1" || { red "FAIL: concept-store-13-concept-page-type-line type line not directly under H1"; errors=$((errors+1)); }
import sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
h1 = next(i for i, l in enumerate(lines) if l.startswith("# "))
# next non-empty line after the H1 must be the type line
nxt = next(l for l in lines[h1+1:] if l.strip())
sys.exit(0 if nxt == "Type: Concept · distilled" else 1)
PY

# --- 2b. cross-parser no-drift (#343/#356 review #5) -------------------------
# The read-before-web coverage scorer reads these pages with
# _knowledge_lib.parse_distilled_claims (text only). Feed the pages concept-store
# JUST WROTE to that reader and assert the text set round-trips — this is the
# true no-drift guard between the writer (_render_distilled_claims) and the
# coverage-side reader, beyond concept-store's own private round-trip self-check.
python3 - "$PLUGIN_ROOT/scripts" "$CPAGE" "$EPAGE" <<'PY' && green "PASS: concept-store-14-lib-parse-distilled-claims lib parse_distilled_claims round-trips concept-store's actual output (no drift)" || { red "FAIL: concept-store-14-lib-parse-distilled-claims lib parser drifted from concept-store writer"; errors=$((errors+1)); }
import sys
sys.path.insert(0, sys.argv[1])
import _knowledge_lib as kl
cpage = open(sys.argv[2], encoding="utf-8").read()
epage = open(sys.argv[3], encoding="utf-8").read()
cclaims = kl.parse_distilled_claims(cpage)
eclaims = kl.parse_distilled_claims(epage)
ctexts = {c["text"] for c in cclaims}
assert ctexts == {
    "Annex III lists eight categories of high-risk AI systems.",
    "Providers must register high-risk systems in the EU database.",
}, ctexts
assert all(set(c) == {"text"} for c in cclaims), cclaims  # writer metadata ignored
assert {c["text"] for c in eclaims} == {
    "The European Commission published the GPAI Code of Practice.",
}, eclaims
PY

# --- 3. merge UPDATE (cross-run compounding) ---------------------------------
printf '\nHuman note: this list is contested.\n' >> "$CPAGE"
cat > "$PROJ/.metadata/rec2.txt" <<'EOF'
- title: Annex III Categories
  type: concept
  claim: src-c#clm-003 | Annex III lists eight categories of high-risk AI systems.
  claim: src-c#clm-011 | The Commission may amend Annex III by delegated act.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ/.metadata/rec2.txt" --wiki-root "$WIKI" --project-path "$PROJ" --project-slug proj-2 --wiki-scripts-dir "$WSD")
[ "$(echo "$OUT" | field '["data"]["n_updated"]')" = "1" ] && green "PASS: concept-store-15-merge-updated-existing-concept merge updated the existing concept" || { red "FAIL: concept-store-15-merge-updated-existing-concept n_updated != 1"; errors=$((errors+1)); }
[ "$(echo "$OUT" | field '["data"]["claims_deduped_total"]')" = "1" ] && green "PASS: concept-store-16-exact-norm-key-dedup exact-norm_key dedup counted (1)" || { red "FAIL: concept-store-16-exact-norm-key-dedup deduped_total != 1"; errors=$((errors+1)); }
python3 - "$CPAGE" <<'PY' && green "PASS: concept-store-17-cross-run-update-assertions cross-run update assertions" || { echo "FAIL: concept-store-17-cross-run-update-assertions cross-run update"; exit 1; }
import sys, re
t = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r'claim_id: dcl-001.*?backlinks: (\[.*?\])', t, re.DOTALL)
assert m and "src-a" in m.group(1) and "src-c" in m.group(1), "backlink union failed: " + (m.group(1) if m else "no dcl-001")
assert "delegated act" in t, "new claim not appended"
assert "Human note: this list is contested." in t, "HUMAN REGION CLOBBERED"
assert "proj-1" in t and "proj-2" in t, "distilled_from union failed"
assert t.count("claim_id: dcl-") == 3, "expected 3 distinct claims, got %d" % t.count("claim_id: dcl-")
PY
[ $? -eq 0 ] || errors=$((errors+1))

# --- 4. claim-id namespacing -------------------------------------------------
PROJ2="$WORK/project2"; mkdir -p "$PROJ2/.metadata"
cat > "$PROJ2/.metadata/recns.txt" <<'EOF'
- title: Namespacing Probe
  type: concept
  claim: src-a#clm-001 | Member states must designate a national supervisory authority.
  claim: src-b#clm-001 | The penalty ceiling is thirty five million euros.
EOF
python3 "$SCRIPT" merge --records "$PROJ2/.metadata/recns.txt" --wiki-root "$WIKI" --project-path "$PROJ2" --project-slug proj-ns --wiki-scripts-dir "$WSD" >/dev/null
NS="$WIKI/wiki/concepts/namespacing-probe.md"
N=$(grep -c 'claim_id: dcl-' "$NS" 2>/dev/null || echo 0)
[ "$N" = "2" ] && green "PASS: concept-store-18-two-sources-both-clm two sources both clm-001 (different facts) -> 2 distinct claims" || { red "FAIL: concept-store-18-two-sources-both-clm namespacing collapsed clm-001 (got $N claims)"; errors=$((errors+1)); }

# --- 5. byte-stable re-run ---------------------------------------------------
BEFORE=$(cat "$NS")
OUT=$(python3 "$SCRIPT" merge --records "$PROJ2/.metadata/recns.txt" --wiki-root "$WIKI" --project-path "$PROJ2" --project-slug proj-ns --wiki-scripts-dir "$WSD")
AFTER=$(cat "$NS")
[ "$BEFORE" = "$AFTER" ] && green "PASS: concept-store-19-identical-re-run-byte identical re-run is byte-stable" || { red "FAIL: concept-store-19-identical-re-run-byte re-run changed the page"; errors=$((errors+1)); }
echo "$OUT" | grep -q '"action": "unchanged"' && green "PASS: concept-store-20-re-run-reports-unchanged re-run reports unchanged" || { red "FAIL: concept-store-20-re-run-reports-unchanged re-run not reported unchanged"; errors=$((errors+1)); }

# --- 6. FAIL-SAFE: near-but-distinct claims are KEPT, not over-merged --------
PROJ3="$WORK/project3"; mkdir -p "$PROJ3/.metadata"
cat > "$PROJ3/.metadata/recsafe.txt" <<'EOF'
- title: Fail Safe Probe
  type: concept
  claim: src-a#clm-020 | Member states must designate a national supervisory authority.
  claim: src-b#clm-021 | The penalty ceiling is thirty five million euros.
EOF
python3 "$SCRIPT" merge --records "$PROJ3/.metadata/recsafe.txt" --wiki-root "$WIKI" --project-path "$PROJ3" --project-slug proj-safe --wiki-scripts-dir "$WSD" >/dev/null
FS="$WIKI/wiki/concepts/fail-safe-probe.md"
N=$(grep -c 'claim_id: dcl-' "$FS" 2>/dev/null || echo 0)
[ "$N" = "2" ] && green "PASS: concept-store-21-two-distinct-facts-sim two distinct facts (sim < 0.85) kept as 2 claims (fail-safe keep-both)" || { red "FAIL: concept-store-21-two-distinct-facts-sim distinct claims over-merged (got $N)"; errors=$((errors+1)); }

# --- 6b. orphan-source guard: a malformed (empty-text) claim's slug must NOT --
# leak into sources:/## Sources, and must be COUNTED as rejected.
cat > "$PROJ3/.metadata/reorph.txt" <<'EOF'
- title: Orphan Guard
  type: concept
  claim: src-a#clm-030 | A real attached claim.
  claim: src-orphan#clm-031 |
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ3/.metadata/reorph.txt" --wiki-root "$WIKI" --project-path "$PROJ3" --project-slug proj-safe --wiki-scripts-dir "$WSD")
OG="$WIKI/wiki/concepts/orphan-guard.md"
grep -q 'src-orphan' "$OG" && { red "FAIL: concept-store-22-malformed-claim-source-added malformed claim's source leaked into the page"; errors=$((errors+1)); } || green "PASS: concept-store-22-malformed-claim-source-added malformed-claim source not added to sources/backlinks"
echo "$OUT" | grep -q '"claims_rejected_total": 1' && green "PASS: concept-store-23-malformed-claim-counted-claims malformed claim counted in claims_rejected_total" || { red "FAIL: concept-store-23-malformed-claim-counted-claims rejected claim not counted"; errors=$((errors+1)); }

# --- 7b. slug-type collision: same title as concept AND entity -> 2nd skipped -
cat > "$PROJ3/.metadata/recdual.txt" <<'EOF'
- title: Data Protection Authority
  type: concept
  claim: src-a#clm-040 | The authority enforces the regulation.
- title: Data Protection Authority
  type: entity
  claim: src-b#clm-041 | The authority is an independent body.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ3/.metadata/recdual.txt" --wiki-root "$WIKI" --project-path "$PROJ3" --project-slug proj-safe --wiki-scripts-dir "$WSD")
echo "$OUT" | grep -q 'slug_type_collision' && green "PASS: concept-store-24-concept-entity-same-slug concept+entity same slug -> 2nd skipped (slug_type_collision)" || { red "FAIL: concept-store-24-concept-entity-same-slug slug_type_collision not enforced"; errors=$((errors+1)); }
[ -f "$WIKI/wiki/concepts/data-protection-authority.md" ] && [ ! -f "$WIKI/wiki/entities/data-protection-authority.md" ] && green "PASS: concept-store-25-only-one-page-exists only ONE page exists for the colliding slug" || { red "FAIL: concept-store-25-only-one-page-exists duplicate slug across type dirs"; errors=$((errors+1)); }

# --- 7. foundation collision (slug must match slugify(title)) ----------------
cat > "$WIKI/wiki/concepts/risk-management-system.md" <<'EOF'
---
id: risk-management-system
title: Risk Management System
type: concept
foundation: true
created: 2026-01-01
updated: 2026-01-01
---
# Risk Management System
Curated.
EOF
cat > "$PROJ2/.metadata/recfound.txt" <<'EOF'
- title: Risk Management System
  type: concept
  claim: src-a#clm-050 | A risk management system must run across the lifecycle.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ2/.metadata/recfound.txt" --wiki-root "$WIKI" --project-path "$PROJ2" --project-slug proj-ns --wiki-scripts-dir "$WSD")
echo "$OUT" | grep -q 'foundation_collision' && green "PASS: concept-store-26-foundation-page-refused-foundation foundation page refused (foundation_collision)" || { red "FAIL: concept-store-26-foundation-page-refused-foundation foundation not refused"; errors=$((errors+1)); }
grep -q 'src-a' "$WIKI/wiki/concepts/risk-management-system.md" && { red "FAIL: concept-store-27-foundation-page-untouched foundation page was modified"; errors=$((errors+1)); } || green "PASS: concept-store-27-foundation-page-untouched foundation page untouched"

# --- 8. no-sentinel human page ----------------------------------------------
cat > "$WIKI/wiki/concepts/hand-authored.md" <<'EOF'
---
id: hand-authored
title: Hand Authored
type: concept
created: 2026-01-01
updated: 2026-01-01
---
# Hand Authored
A human wrote this with no sentinels.
EOF
HASH_BEFORE=$(cksum "$WIKI/wiki/concepts/hand-authored.md")
cat > "$PROJ2/.metadata/rechand.txt" <<'EOF'
- title: Hand Authored
  type: concept
  claim: src-a#clm-099 | Some new claim.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ2/.metadata/rechand.txt" --wiki-root "$WIKI" --project-path "$PROJ2" --project-slug proj-ns --wiki-scripts-dir "$WSD")
echo "$OUT" | grep -q 'no_sentinels_human_page' && green "PASS: concept-store-28-no-sentinel-human-page-skipped no-sentinel human page skipped" || { red "FAIL: concept-store-28-no-sentinel-human-page-skipped no-sentinel page not skipped"; errors=$((errors+1)); }
[ "$(cksum "$WIKI/wiki/concepts/hand-authored.md")" = "$HASH_BEFORE" ] && green "PASS: concept-store-29-no-sentinel-page-left-untouched no-sentinel page left untouched" || { red "FAIL: concept-store-29-no-sentinel-page-left-untouched no-sentinel page modified"; errors=$((errors+1)); }

# --- 9. manifest read --------------------------------------------------------
OUT=$(python3 "$SCRIPT" read --project-path "$PROJ")
echo "$OUT" | grep -q 'claims_attached_total' && green "PASS: concept-store-30-manifest-carries-claims-attached manifest carries claims_attached_total" || { red "FAIL: concept-store-30-manifest-carries-claims-attached manifest missing dedup totals"; errors=$((errors+1)); }

# --- 10. #340 observable title→slug tripwire --------------------------------
# A new project proposes a title that's title-similar (>= 0.65) but slugifies
# DIFFERENTLY from a page already on disk. The page must still be CREATED
# (no auto-merge), but the result envelope must carry near_existing_slug and the
# manifest must aggregate near_existing_total / near_existing_slugs[].
# "Annex III Categories" already exists from Step 2 (slug annex-iii-categories).
# "Annex III Risk Categories" slugifies to annex-iii-risk-categories — DIFFERENT
# slug, but `claim_similarity` scores ~0.80 (above the 0.65 threshold) because
# the discriminative tokens (annex/categori) overlap with weight.
PROJ4="$WORK/project4"; mkdir -p "$PROJ4/.metadata"
cat > "$PROJ4/.metadata/recnear.txt" <<'EOF'
- title: Annex III Risk Categories
  type: concept
  claim: src-a#clm-080 | The Annex enumerates several high-risk categories.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ4/.metadata/recnear.txt" --wiki-root "$WIKI" --project-path "$PROJ4" --project-slug proj-near --wiki-scripts-dir "$WSD")
# Created (no auto-merge): the page lives at the NEW slug.
NEAR="$WIKI/wiki/concepts/annex-iii-risk-categories.md"
[ -f "$NEAR" ] && green "PASS: concept-store-31-near-title-creates-new near-title creates a NEW page (no auto-merge)" || { red "FAIL: concept-store-31-near-title-creates-new near-title did not create page"; errors=$((errors+1)); }
# near_existing_total >= 1 in manifest + return envelope.
echo "$OUT" | grep -q '"near_existing_total": 1' && green "PASS: concept-store-32-near-existing-total-counted near_existing_total counted (1)" || { red "FAIL: concept-store-32-near-existing-total-counted near_existing_total != 1"; errors=$((errors+1)); }
# The per-concept envelope carries near_existing_slug with the existing match.
echo "$OUT" | grep -q '"near_slug": "annex-iii-categories"' && green "PASS: concept-store-33-near-existing-slug-points near_existing_slug points at the cross-run match" || { red "FAIL: concept-store-33-near-existing-slug-points near_existing_slug not surfaced"; errors=$((errors+1)); }
echo "$OUT" | grep -q '"near_type": "concept"' && green "PASS: concept-store-34-near-existing-slug-carries-type near_existing_slug carries the type" || { red "FAIL: concept-store-34-near-existing-slug-carries-type near_existing_slug type missing"; errors=$((errors+1)); }
# Same-type near-match (concept→concept) is NOT a cross-type mis-type (#600).
python3 -c 'import json,sys;d=json.loads(sys.argv[1])["data"];assert d["mistyped_total"]==0,d;assert d["near_existing_slugs"][0]["type_mismatch"] is False,d' "$OUT" && green "PASS: concept-store-35-same-type-near-match same-type near-match → type_mismatch False, mistyped_total 0 (#600 no false alarm)" || { red "FAIL: concept-store-35-same-type-near-match same-type near-match wrongly flagged as mis-typed"; errors=$((errors+1)); }
# The schema bumped from 0.1.0 → 0.1.1 because the manifest gained two fields.
python3 -c 'import json,sys;d=json.load(open(sys.argv[1]));assert d["schema_version"]=="0.1.1";assert d["near_existing_total"]==1;assert len(d["near_existing_slugs"])==1;assert d["mistyped_total"]==0' "$PROJ4/.metadata/distill-manifest.json" && green "PASS: concept-store-36-manifest-schema-bumped-tripwire manifest schema bumped + tripwire fields aggregated" || { red "FAIL: concept-store-36-manifest-schema-bumped-tripwire manifest schema/fields wrong"; errors=$((errors+1)); }

# --- 10b. #600 cross-type tripwire: new concept shadows an existing entity ---
# The reported bug: the distiller files a NAMED INSTANCE as type:concept when it
# should be an entity. Deterministic observability backstop: a new type:concept
# whose title near-matches an existing type:ENTITY page must surface
# type_mismatch=true on its entry and mistyped_total>=1 in the aggregate. The
# page is still CREATED (observability only — never blocks a write).
PROJ4b="$WORK/project4b"; mkdir -p "$PROJ4b/.metadata"
cat > "$PROJ4b/.metadata/recent.txt" <<'EOF'
- title: DT Cyber Defense Center
  type: entity
  claim: src-a#clm-090 | DT operates a global cyber defense center headquartered in Bonn.
EOF
python3 "$SCRIPT" merge --records "$PROJ4b/.metadata/recent.txt" --wiki-root "$WIKI" --project-path "$PROJ4b" --project-slug proj-ent --wiki-scripts-dir "$WSD" >/dev/null
[ -f "$WIKI/wiki/entities/dt-cyber-defense-center.md" ] && green "PASS: concept-store-37-entity-page-deposited-cross entity page deposited for cross-type test" || { red "FAIL: concept-store-37-entity-page-deposited-cross entity page not created"; errors=$((errors+1)); }
# New project proposes a CONCEPT whose title near-matches the entity (plural →
# distinct slug dt-cyber-defense-centers, so no slug_type_collision; created).
PROJ4c="$WORK/project4c"; mkdir -p "$PROJ4c/.metadata"
cat > "$PROJ4c/.metadata/recmistype.txt" <<'EOF'
- title: DT Cyber Defense Centers
  type: concept
  claim: src-b#clm-091 | The defense centers coordinate regional SOCs worldwide.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ4c/.metadata/recmistype.txt" --wiki-root "$WIKI" --project-path "$PROJ4c" --project-slug proj-mistype --wiki-scripts-dir "$WSD")
[ -f "$WIKI/wiki/concepts/dt-cyber-defense-centers.md" ] && green "PASS: concept-store-38-cross-type-near-match cross-type near-match still CREATES the page (observability only)" || { red "FAIL: concept-store-38-cross-type-near-match cross-type case did not create the concept page"; errors=$((errors+1)); }
python3 -c '
import json,sys
d=json.loads(sys.argv[1])["data"]
assert d["mistyped_total"]>=1, d
m=[s for s in d["near_existing_slugs"] if s.get("type_mismatch")]
assert m and m[0]["near_type"]=="entity", d
' "$OUT" && green "PASS: concept-store-39-cross-type-tripwire #600 cross-type tripwire flags new concept shadowing existing entity (type_mismatch + mistyped_total)" || { red "FAIL: concept-store-39-cross-type-tripwire #600 cross-type tripwire not flagged"; red "  got: $OUT"; errors=$((errors+1)); }

# --- 11. CLEAN-RUN BASELINE: no near match → empty tripwire ------------------
# A title with no overlap against any existing concept/entity must yield
# near_existing_total = 0 (no false alarms on clean runs).
PROJ5="$WORK/project5"; mkdir -p "$PROJ5/.metadata"
cat > "$PROJ5/.metadata/recclean.txt" <<'EOF'
- title: Maritime Surveillance Protocol
  type: concept
  claim: src-a#clm-090 | Vessels must transmit identifying telemetry.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ5/.metadata/recclean.txt" --wiki-root "$WIKI" --project-path "$PROJ5" --project-slug proj-clean --wiki-scripts-dir "$WSD")
echo "$OUT" | grep -q '"near_existing_total": 0' && green "PASS: concept-store-40-unrelated-title-near-existing unrelated title → near_existing_total=0 (no false alarm)" || { red "FAIL: concept-store-40-unrelated-title-near-existing false alarm on unrelated title"; errors=$((errors+1)); }
echo "$OUT" | grep -q '"near_existing_slugs": \[\]' && green "PASS: concept-store-41-clean-run-leaves-near clean run leaves near_existing_slugs empty" || { red "FAIL: concept-store-41-clean-run-leaves-near near_existing_slugs not empty on clean run"; errors=$((errors+1)); }

# --- 12. tripwire NEVER fires on the `updated` path --------------------------
# Same title as Step 3's update -> action=updated, near_existing_slug must be {}.
# (An updated page's slug IS one of the existing slugs, so warning about its own
# near-self would be circular noise.)
PROJ6="$WORK/project6"; mkdir -p "$PROJ6/.metadata"
cat > "$PROJ6/.metadata/recupd.txt" <<'EOF'
- title: Annex III Categories
  type: concept
  claim: src-a#clm-095 | A third source contributes an Annex III statement.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ6/.metadata/recupd.txt" --wiki-root "$WIKI" --project-path "$PROJ6" --project-slug proj-upd --wiki-scripts-dir "$WSD")
echo "$OUT" | grep -q '"near_existing_total": 0' && green "PASS: concept-store-42-updated-path-never-fires updated path never fires the tripwire" || { red "FAIL: concept-store-42-updated-path-never-fires tripwire fired on update"; errors=$((errors+1)); }

# --- 13. QUOTED frontmatter title parses correctly ---------------------------
# Hand-place a page whose `title:` value is JSON-double-quoted (the writer's
# own format, but here pre-seeded directly so we explicitly cover the
# _unquote_scalar path through _read_page_title — not just the implicit
# round-trip from Step 2's merge-created page). A proposal whose title shares
# discriminative tokens must trip, AND the manifest's near_title must carry
# the UNQUOTED value (proving the parser stripped the quotes — if it didn't,
# the warning text in Step 9 of the SKILL would print the literal `"Regulatory
# Sandbox"` with quotes).
cat > "$WIKI/wiki/concepts/regulatory-sandbox.md" <<'EOF'
---
id: regulatory-sandbox
title: "Regulatory Sandbox"
type: concept
created: 2026-01-01
updated: 2026-01-01
---
# Regulatory Sandbox
EOF
PROJ7="$WORK/project7"; mkdir -p "$PROJ7/.metadata"
cat > "$PROJ7/.metadata/recquoted.txt" <<'EOF'
- title: Regulatory Sandbox Pilot
  type: concept
  claim: src-a#clm-100 | The sandbox pilot runs for twelve months.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ7/.metadata/recquoted.txt" --wiki-root "$WIKI" --project-path "$PROJ7" --project-slug proj-quoted --wiki-scripts-dir "$WSD")
echo "$OUT" | grep -q '"near_existing_total": 1' && green "PASS: concept-store-43-quoted-title-parsed-tripwire quoted title parsed — tripwire fires" || { red "FAIL: concept-store-43-quoted-title-parsed-tripwire quoted title not parsed (tripwire silent)"; errors=$((errors+1)); }
echo "$OUT" | grep -q '"near_title": "Regulatory Sandbox"' && green "PASS: concept-store-44-quoted-title-round-trips quoted title round-trips UNQUOTED in manifest" || { red "FAIL: concept-store-44-quoted-title-round-trips near_title kept literal quotes"; errors=$((errors+1)); }
echo "$OUT" | grep -q '"near_slug": "regulatory-sandbox"' && green "PASS: concept-store-45-quoted-title-near-slug quoted title near_slug points at the pre-seeded page" || { red "FAIL: concept-store-45-quoted-title-near-slug near_slug wrong on quoted title"; errors=$((errors+1)); }

# --- 14. MISSING title key silently degrades to "" ---------------------------
# Regression guard against the dropped stem-fallback (review-cycle fix in
# be870e2f). A page with no `title:` key in frontmatter must yield `""` from
# _read_page_title — claim_similarity("", anything) == 0.0, so the page is
# silently excluded from the tripwire. If the fallback ever comes back (e.g.
# `title or page_path.stem`), this test trips because the slug `quantum-research`
# folds to tokens that share `quantum`+`research` with the proposal — i.e. a
# false-positive warning against a broken page.
cat > "$WIKI/wiki/concepts/quantum-research.md" <<'EOF'
---
id: quantum-research
type: concept
created: 2026-01-01
updated: 2026-01-01
---
# (no title key in frontmatter)
EOF
PROJ8="$WORK/project8"; mkdir -p "$PROJ8/.metadata"
cat > "$PROJ8/.metadata/recnotitle.txt" <<'EOF'
- title: Quantum Research Methods
  type: concept
  claim: src-a#clm-110 | Quantum research methods include lattice simulation.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ8/.metadata/recnotitle.txt" --wiki-root "$WIKI" --project-path "$PROJ8" --project-slug proj-notitle --wiki-scripts-dir "$WSD")
echo "$OUT" | grep -q '"near_existing_total": 0' && green "PASS: concept-store-46-missing-title-key-silently missing title key silently excluded from tripwire" || { red "FAIL: concept-store-46-missing-title-key-silently missing title fell through to slug fallback (false positive)"; errors=$((errors+1)); }

# --- 15. CROSS-TYPE matching (concept proposal trips on entity page) ---------
# The title index spans BOTH concepts/ and entities/, so a new concept whose
# title is similar to an existing ENTITY (or vice versa) must trip. Reuses the
# `european-commission` entity created at Step 2. A new concept "European
# Commission Procedures" shares european+commission (score > 0.65), so the
# tripwire must fire AND `near_type` must report "entity" — proving cross-type
# coverage isn't a concept-only or entity-only blind spot.
PROJ9="$WORK/project9"; mkdir -p "$PROJ9/.metadata"
cat > "$PROJ9/.metadata/reccross.txt" <<'EOF'
- title: European Commission Procedures
  type: concept
  claim: src-a#clm-120 | The Commission publishes procedural rules for delegated acts.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ9/.metadata/reccross.txt" --wiki-root "$WIKI" --project-path "$PROJ9" --project-slug proj-cross --wiki-scripts-dir "$WSD")
echo "$OUT" | grep -q '"near_existing_total": 1' && green "PASS: concept-store-47-cross-type-match-concept cross-type match (concept → entity) trips" || { red "FAIL: concept-store-47-cross-type-match-concept cross-type tripwire silent"; errors=$((errors+1)); }
echo "$OUT" | grep -q '"near_type": "entity"' && green "PASS: concept-store-48-cross-type-near-type cross-type near_type reports entity" || { red "FAIL: concept-store-48-cross-type-near-type near_type not 'entity' on cross-type match"; errors=$((errors+1)); }
echo "$OUT" | grep -q '"near_slug": "european-commission"' && green "PASS: concept-store-49-cross-type-near-slug cross-type near_slug points at the entity page" || { red "FAIL: concept-store-49-cross-type-near-slug cross-type near_slug wrong"; errors=$((errors+1)); }

# --- 16. CROSS-LINGUAL candidate gate + crossmerge (#345) --------------------
# Build a concept page carrying a German claim and its English twin that share
# the article-number anchor `99` (the only DE↔EN bridge) plus an unrelated DE
# claim. xlingual-candidates must flag EXACTLY the DE↔EN pair; crossmerge must
# UNION the twin's provenance onto the survivor (3 claims → 2) and drop NO ref.
PROJX="$WORK/projectX"; mkdir -p "$PROJX/.metadata"
cat > "$PROJX/.metadata/recxl.txt" <<'EOF'
- title: Sanctions Regime
  type: concept
  summary: Penalty rules.
  claim: src-a#clm-200 | Verstöße gegen Artikel 99 werden mit Bußgeldern geahndet.
  claim: src-b#clm-201 | Infringements under Article 99 are punished with administrative fines.
  claim: src-c#clm-202 | Die nationale Aufsichtsbehörde überwacht die Marktteilnehmer.
EOF
python3 "$SCRIPT" merge --records "$PROJX/.metadata/recxl.txt" --wiki-root "$WIKI" --project-path "$PROJX" --project-slug proj-xl --wiki-scripts-dir "$WSD" >/dev/null
XLPAGE="$WIKI/wiki/concepts/sanctions-regime.md"
CAND=$(python3 "$SCRIPT" xlingual-candidates --wiki-root "$WIKI" --slugs "sanctions-regime" --wiki-scripts-dir "$WSD")
NC=$(echo "$CAND" | field '["data"]["n_candidates"]')
[ "$NC" = "1" ] && green "PASS: concept-store-50-xlingual-candidates-flags-exactly xlingual-candidates flags exactly the DE↔EN twin pair" || { red "FAIL: concept-store-50-xlingual-candidates-flags-exactly expected 1 candidate, got $NC"; errors=$((errors+1)); }
echo "$CAND" | grep -q '"shared_anchors"' && echo "$CAND" | grep -q '"99"' && green "PASS: concept-store-51-candidate-carries-shared-article candidate carries the shared article-number anchor 99" || { red "FAIL: concept-store-51-candidate-carries-shared-article candidate missing anchor 99"; errors=$((errors+1)); }

# Confirm dcl-001 (DE survivor) absorbs dcl-002 (EN twin).
printf 'merge: sanctions-regime | dcl-001 | dcl-002\n' > "$PROJX/.metadata/xmrec.txt"
XM=$(python3 "$SCRIPT" crossmerge --records "$PROJX/.metadata/xmrec.txt" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")
echo "$XM" | grep -q '"claims_crossmerged_total": 1' && green "PASS: concept-store-52-crossmerge-reports-1-union crossmerge reports 1 union" || { red "FAIL: concept-store-52-crossmerge-reports-1-union crossmerge total != 1"; errors=$((errors+1)); }
NLEFT=$(grep -c 'claim_id: dcl-' "$XLPAGE")
[ "$NLEFT" = "2" ] && green "PASS: concept-store-53-crossmerge-collapsed-3-claims crossmerge collapsed 3 claims → 2 (absorbed dcl removed)" || { red "FAIL: concept-store-53-crossmerge-collapsed-3-claims expected 2 claims after crossmerge, got $NLEFT"; errors=$((errors+1)); }
# Survivor must carry BOTH source refs — no provenance dropped.
SURV=$(awk '/claim_id: dcl-001$/{f=1} f{print} /source_claim_refs:/{if(f){print; exit}}' "$XLPAGE")
echo "$SURV" | grep -q 'src-a#clm-200' && echo "$SURV" | grep -q 'src-b#clm-201' && green "PASS: concept-store-54-survivor-unions-both-de survivor unions both DE+EN source_claim_refs (no fact dropped)" || { red "FAIL: concept-store-54-survivor-unions-both-de survivor lost a provenance ref"; errors=$((errors+1)); }

# --- 16b. crossmerge BYTE-STABLE re-run (absorbed id already gone) -----------
BEFORE_XL=$(cat "$XLPAGE")
python3 "$SCRIPT" crossmerge --records "$PROJX/.metadata/xmrec.txt" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" >/dev/null
AFTER_XL=$(cat "$XLPAGE")
[ "$BEFORE_XL" = "$AFTER_XL" ] && green "PASS: concept-store-55-crossmerge-re-run-byte crossmerge re-run is byte-stable (absorbed id gone → claim_not_found)" || { red "FAIL: concept-store-55-crossmerge-re-run-byte crossmerge re-run changed the page"; errors=$((errors+1)); }

# --- 16c. crossmerge REJECTS a non-candidate proposal (LLM can't widen scope)
# dcl-001 (Artikel 99) vs dcl-003 (Aufsichtsbehörde, no shared anchor) are both
# real claims but NOT a candidate — crossmerge must skip reason=not_a_candidate
# and leave the page byte-unchanged.
BEFORE_NC=$(cat "$XLPAGE")
printf 'merge: sanctions-regime | dcl-001 | dcl-003\n' > "$PROJX/.metadata/xmbad.txt"
XB=$(python3 "$SCRIPT" crossmerge --records "$PROJX/.metadata/xmbad.txt" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")
echo "$XB" | grep -q '"reason": "not_a_candidate"' && green "PASS: concept-store-56-crossmerge-rejects-non-candidate crossmerge rejects a non-candidate pair (server-side gate)" || { red "FAIL: concept-store-56-crossmerge-rejects-non-candidate non-candidate not rejected"; errors=$((errors+1)); }
AFTER_NC=$(cat "$XLPAGE")
[ "$BEFORE_NC" = "$AFTER_NC" ] && green "PASS: concept-store-57-rejected-crossmerge-leaves-page rejected crossmerge leaves the page byte-unchanged" || { red "FAIL: concept-store-57-rejected-crossmerge-leaves-page rejected crossmerge mutated the page"; errors=$((errors+1)); }

# --- 16d. single-language page yields ZERO candidates (the auto-skip) --------
# Two English claims sharing anchor 99 but ALSO high overlap would auto-merge in
# Step 6; two SAME-language distinct claims sharing only a year are not anchors.
# Assert a same-language page with no shared article number → 0 candidates.
PROJY="$WORK/projectY"; mkdir -p "$PROJY/.metadata"
cat > "$PROJY/.metadata/recmono.txt" <<'EOF'
- title: Monolingual Probe
  type: concept
  claim: src-a#clm-300 | In 2025 providers must register high-risk systems.
  claim: src-b#clm-301 | National authorities supervise market participants closely.
EOF
python3 "$SCRIPT" merge --records "$PROJY/.metadata/recmono.txt" --wiki-root "$WIKI" --project-path "$PROJY" --project-slug proj-mono --wiki-scripts-dir "$WSD" >/dev/null
MC=$(python3 "$SCRIPT" xlingual-candidates --wiki-root "$WIKI" --slugs "monolingual-probe" --wiki-scripts-dir "$WSD" | field '["data"]["n_candidates"]')
[ "$MC" = "0" ] && green "PASS: concept-store-58-single-language-page-year single-language page (year 2025 not an anchor) → 0 candidates (auto-skip)" || { red "FAIL: concept-store-58-single-language-page-year expected 0 candidates on monolingual page, got $MC"; errors=$((errors+1)); }

echo ""
if [ "$errors" -eq 0 ]; then
  green "concept-store.py contract: all pass."
  exit 0
else
  red "concept-store.py contract: $errors failure(s)."
  exit 1
fi
