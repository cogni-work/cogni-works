#!/usr/bin/env bash
# test_portal_store.sh — #491 curated-portal auto-refresh (option 4b) APPLY-path
# invariants, driving the REAL cogni-wiki wiki_index_update.py --set-leadin /
# --get-leadin primitive + the _knowledge_lib overview-splice helpers exactly as
# knowledge-finalize Step 10.5 sub-step 3.5 does. The portal-narrator LLM agent
# is not run in CI — this exercises the deterministic engine beneath it.
#
# Asserts:
#   1. --set-leadin on an engine-owned (sentineled) section refreshes ONLY the
#      machine span; a human (non-sentineled) lead-in on another theme + all
#      bullets survive byte-for-byte.
#   2. --set-leadin on a section with a human lead-in is REFUSED
#      (skipped_human_leadin) — the engine never clutters human framing.
#   3. --set-leadin on a no-lead-in bullets-only section inserts a span above the
#      bullets.
#   4. The overview narrative splice (_knowledge_lib.upsert_machine_block) inserts
#      on first run, replaces on later runs, and preserves ## Recent syntheses.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KNOWLEDGE_SCRIPTS="$PLUGIN_ROOT/scripts"
UPDATE="$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts/wiki_index_update.py"

WORKDIR="$(mktemp -d)"
WIKI="$WORKDIR/test-wiki"
INDEX="$WIKI/wiki/index.md"
OVERVIEW="$WIKI/wiki/overview.md"

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

. "$(dirname "$0")/fixtures/test_helpers.sh"
errors=0
# Counts instead of exiting, so a later case still reports when an earlier one reds.
# MUST return 0: `fail` is the last command of each assert_* helper's failing branch,
# so its status becomes that helper's status, and the helpers are called bare under
# `set -e` -- a non-zero return would silently re-arm fail-fast at the first red case.
# The trailing plain assignment guarantees status 0 -- never `((errors++))`, whose
# value is the pre-increment 0 (status 1) on the first call.
# The index dump is deferred to the summary: now that every case reports instead of
# the run exiting at the first failure, dumping per call would repeat one fixture
# once per red case and bury the FAIL: id lines this scheme exists to make greppable.
fail() {
  red "FAIL: $1"
  errors=$((errors + 1))
}

if [ ! -f "$UPDATE" ]; then
  red "FAIL: portal-store-00-engine-present cogni-wiki wiki_index_update.py not found at $UPDATE (sibling checkout required)"
  exit 1
fi

HUMAN_LEADIN="Human-curated framing for the questions theme — the engine must never touch this."

mkdir -p "$WIKI/wiki"
cat > "$INDEX" <<EOF
# Test Base — Knowledge Portal

> One entry point.

## Syntheses

<!-- MACHINE-OWNED:PORTAL-LEADIN:START refreshed:2026-01-01 bullets:2 -->
Old engine framing for syntheses.
<!-- MACHINE-OWNED:PORTAL-LEADIN:END -->

- [[alpha-synthesis]] — first
- [[omega-synthesis]] — last

## Questions

$HUMAN_LEADIN

- [[q-one]] — a human-led theme

## Sources

- [[src-a]] — a source
- [[src-b]] — another source
EOF

has_line() { grep -qF "$1" "$INDEX"; }
# One label argument feeds both arms, so a case's pass and fail ids can never diverge.
# assert_rc is the status-taking sibling, for a case whose condition is a pipeline or
# a heredoc that cannot be passed as an argument: capture the status, then label once.
assert_line()    { if has_line "$1"; then green "PASS: $2"; else fail "$2"; fi; }
assert_no_line() { if has_line "$1"; then fail "$2"; else green "PASS: $2"; fi; }
assert_rc()      { if [ "$1" -eq 0 ];  then green "PASS: $2"; else fail "$2"; fi; }
count_pat() { grep -cE "$1" "$INDEX" || true; }

# === 1. refresh an engine-owned span; human + bullets survive ============
printf 'New engine framing for syntheses, run N.' | python3 "$UPDATE" \
  --wiki-root "$WIKI" --set-leadin --category "Syntheses" --leadin-file - \
  --refreshed-date 2026-06-05 >/dev/null

assert_line "New engine framing for syntheses, run N." \
  "portal-store-01-refreshed-span refreshed engine span present"
assert_no_line "Old engine framing for syntheses." \
  "portal-store-02-old-span-gone old engine span did not linger"
assert_line "refreshed:2026-06-05 bullets:2" \
  "portal-store-03-stamp-refreshed stamp refreshed"
assert_line "$HUMAN_LEADIN" \
  "portal-store-04-human-leadin-intact human lead-in on ## Questions undisturbed"
for b in alpha-synthesis omega-synthesis q-one src-a src-b; do
  assert_line "[[$b]]" "portal-store-05-bullet-$b bullet [[$b]] survived the refresh"
done

# === 2. set-leadin over a human lead-in is refused =======================
R2=$(printf 'Engine tries to clutter.' | python3 "$UPDATE" \
  --wiki-root "$WIKI" --set-leadin --category "Questions" --leadin-file - 2>/dev/null)
rc=0
echo "$R2" | python3 -c '
import json, sys
d = json.load(sys.stdin)
assert d["data"]["action"] == "skipped_human_leadin", d
print("OK")
' >/dev/null || rc=1
assert_rc "$rc" "portal-store-06-refusal-action set-leadin over a human lead-in refused"
assert_no_line "Engine tries to clutter." \
  "portal-store-07-no-engine-prose engine prose stayed out of a human section"
assert_line "$HUMAN_LEADIN" \
  "portal-store-08-human-leadin-preserved human lead-in survived a refused call"

# === 3. insert on a no-lead-in bullets-only section ======================
printf 'Engine framing for sources.' | python3 "$UPDATE" \
  --wiki-root "$WIKI" --set-leadin --category "Sources" --leadin-file - \
  --refreshed-date 2026-06-05 >/dev/null
assert_line "Engine framing for sources." \
  "portal-store-09-span-inserted span inserted under ## Sources"
# the span must precede the first bullet under ## Sources
rc=0
python3 - "$INDEX" <<'PY' || rc=1
import sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
in_sec = False; seen_span = False
for ln in lines:
    if ln.strip() == "## Sources":
        in_sec = True; continue
    if in_sec and ln.startswith("## "):
        break
    if in_sec and "PORTAL-LEADIN:START" in ln:
        seen_span = True
    if in_sec and ln.startswith("- [[") and not seen_span:
        # No FAIL: prefix -- the shell wrapper owns this case's single result line.
        print("bullet precedes the inserted span under ## Sources"); sys.exit(1)
sys.exit(0 if seen_span else 1)
PY
assert_rc "$rc" "portal-store-10-span-precedes-bullets span precedes the bullets under ## Sources"

# === 4. overview narrative splice (upsert) round-trip ====================
cat > "$OVERVIEW" <<'EOF'
# Overview

## Recent syntheses

- [2026-06-05] [[alpha-synthesis]] — first
EOF

rc=0
OVERVIEW="$OVERVIEW" KNOWLEDGE_SCRIPTS="$KNOWLEDGE_SCRIPTS" python3 -c '
import os, sys
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from _knowledge_lib import upsert_machine_block, extract_machine_block
p = os.environ["OVERVIEW"]
text = open(p, encoding="utf-8").read()
# first run: insert after the H1, above ## Recent syntheses
text = upsert_machine_block(text, "OVERVIEW-NARRATIVE", "State of the wiki, run 1.")
assert extract_machine_block(text, "OVERVIEW-NARRATIVE") == "State of the wiki, run 1.", text
assert text.index("OVERVIEW-NARRATIVE") < text.index("Recent syntheses"), text
assert text.startswith("# Overview"), repr(text[:40])
# later run: replace only the inner; Recent syntheses preserved
text2 = upsert_machine_block(text, "OVERVIEW-NARRATIVE", "State of the wiki, run 2.")
assert extract_machine_block(text2, "OVERVIEW-NARRATIVE") == "State of the wiki, run 2.", text2
assert "State of the wiki, run 1." not in text2
assert "## Recent syntheses" in text2 and "[[alpha-synthesis]]" in text2, text2
# idempotent: identical inner -> byte-identical text
assert upsert_machine_block(text2, "OVERVIEW-NARRATIVE", "State of the wiki, run 2.") == text2
print("OK")
' >/dev/null || rc=1
assert_rc "$rc" "portal-store-11-overview-roundtrip overview narrative splice inserts, replaces, preserves Recent syntheses, idempotent"

if [ "$errors" -eq 0 ]; then
  green "ALL TESTS PASS"
  exit 0
else
  printf -- '----- index.md -----\n'
  cat "$INDEX" 2>/dev/null || true
  red "$errors test(s) failed"
  exit 1
fi
