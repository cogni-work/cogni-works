#!/usr/bin/env bash
# test_context_brief.sh — smoke test for rebuild_context_brief.py (#219, v0.0.29).
#
# 1. Copies the legacy fixture and runs migrate_layout.py to land on the
#    per-type layout the script requires.
# 2. Invokes rebuild_context_brief.py and asserts:
#    - exit success and JSON contract
#    - wiki/context_brief.md exists
#    - file is ≤ 8192 bytes (the hard cap is 8000; CR/LF wiggle accepted)
#    - all six section headers are present
# 3. Re-runs the script and asserts the same invariants (idempotent).
# 4. Probes a pre-migration wiki and asserts the standard hard-fail message.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
WORKDIR="$(mktemp -d)"
WIKI="$WORKDIR/test-wiki"

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

red() { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
fail() { red "FAIL: $1"; exit 1; }

assert_success_json() {
  local label="$1" out="$2" ok
  ok=$(printf '%s' "$out" | python3 -c 'import json, sys; d=json.loads(sys.stdin.read()); print("yes" if d.get("success") else "no")' 2>/dev/null || echo "parse-error")
  if [ "$ok" != "yes" ]; then
    red "FAIL ($label): expected success:true"
    printf '%s\n' "$out"
    exit 1
  fi
}

# ---------- prepare a migrated fixture ----------
cp -R "$FIXTURES/legacy-wiki" "$WIKI"
python3 "$PLUGIN_ROOT/skills/wiki-setup/scripts/migrate_layout.py" \
  --wiki-root "$WIKI" --apply >/dev/null
green "fixture migrated to per-type layout"

# ---------- 1) first run ----------
OUT=$(python3 "$PLUGIN_ROOT/skills/wiki-ingest/scripts/rebuild_context_brief.py" \
  --wiki-root "$WIKI")
assert_success_json "rebuild_context_brief.py first run" "$OUT"

BRIEF="$WIKI/wiki/context_brief.md"
[ -f "$BRIEF" ] || fail "context_brief.md not created"

BYTES=$(wc -c < "$BRIEF" | tr -d ' ')
if [ "$BYTES" -gt 8192 ]; then
  fail "context_brief.md is $BYTES bytes (hard cap is 8000, ≤8192 with newline slack)"
fi
green "context_brief.md created, $BYTES bytes (≤ 8192)"

# Header sanity — every canonical section must be present.
for HDR in '^# Context brief' '^## Type counts' '^## Top entities' \
           '^## Recent activity' '^## Open lints' '^## Health snapshot'; do
  if ! grep -q "$HDR" "$BRIEF"; then
    fail "missing header: $HDR"
  fi
done
green "all six section headers present"

# JSON payload sanity.
SECTIONS=$(printf '%s' "$OUT" | python3 -c 'import json, sys; d=json.loads(sys.stdin.read()); print(",".join(d["data"]["sections"]))')
EXPECTED="header,type_counts,top_entities,recent,lints,health"
if [ "$SECTIONS" != "$EXPECTED" ]; then
  fail "sections payload: got [$SECTIONS], expected [$EXPECTED]"
fi
green "JSON sections payload matches"

# ---------- 2) idempotent re-run ----------
OUT=$(python3 "$PLUGIN_ROOT/skills/wiki-ingest/scripts/rebuild_context_brief.py" \
  --wiki-root "$WIKI")
assert_success_json "rebuild_context_brief.py re-run" "$OUT"
BYTES2=$(wc -c < "$BRIEF" | tr -d ' ')
if [ "$BYTES2" -gt 8192 ]; then
  fail "context_brief.md is $BYTES2 bytes after re-run (cap 8192)"
fi
green "idempotent re-run: $BYTES2 bytes"

# ---------- 3) pre-migration probe ----------
cp -R "$FIXTURES/legacy-wiki" "$WORKDIR/legacy-wiki"
OUT=$(python3 "$PLUGIN_ROOT/skills/wiki-ingest/scripts/rebuild_context_brief.py" \
  --wiki-root "$WORKDIR/legacy-wiki" 2>/dev/null || true)
RESULT=$(printf '%s' "$OUT" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())
print("ok" if (not d.get("success")) and ("pre-migration" in d.get("error", "")) else "bad")
' 2>/dev/null || echo "parse-error")
if [ "$RESULT" != "ok" ]; then
  fail "pre-migration probe: expected success:false with pre-migration message; got: $OUT"
fi
green "rebuild_context_brief.py hard-fails on legacy layout"

green "ALL TESTS PASS"
