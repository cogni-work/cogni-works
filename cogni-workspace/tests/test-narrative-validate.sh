#!/usr/bin/env bash
# Guard: the narrative skill's deterministic Phase 5 gates are real gates.
#
# WHAT THIS PINS
#   skills/narrative/scripts/validate-narrative.py reads a finished narrative and the
#   arc contract it claims, and reports the mechanical gates from
#   skills/narrative/references/validation.md. This suite proves two things about it:
#   a conforming narrative passes every gate, and each gate can go red on a narrative
#   that breaks precisely the rule it names. A validator that only ever sees a healthy
#   fixture is indistinguishable from one that cannot fail.
#
#   Every mutation is generated into this run's own mktemp -d from the tracked fixture
#   at tests/fixtures/narrative-output/corporate-visions-en.md; no tracked file is
#   written. The mutations are the replayable form of the mutation recipes the narrative
#   issues ask for: drop a Sources entry, add a fifth `##`, rename a heading, and so on.
#
# CASE LABEL SHAPE: `PASS: <id>` / `FAIL: <id>` with a single-token id, summary line
#   `RESULT:`. Ids are NV-prefixed so no summary line is read as a case verdict.
#
# Contract: runs as `bash <path>` with no arguments, from any cwd, touches no network,
# needs bash + coreutils + python3, and exits non-zero on failure.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$HERE/.." && pwd)"
VALIDATOR="$PLUGIN_DIR/skills/narrative/scripts/validate-narrative.py"
FIXTURE="$PLUGIN_DIR/tests/fixtures/narrative-output/corporate-visions-en.md"
CONTRACT="$PLUGIN_DIR/skills/narrative/references/story-arc/corporate-visions/arc-definition.md"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

for f in "$VALIDATOR" "$FIXTURE" "$CONTRACT"; do
  if [ ! -f "$f" ]; then
    fail "NV0 inputs readable — missing $f"
    printf '%s\n' "RESULT: 1 narrative-validate case(s) failed."
    exit 1
  fi
done
pass "NV0 inputs readable"

# run <narrative> -> sets OUT (json) and RC
run() {
  OUT="$(python3 "$VALIDATOR" --narrative "$1" --contract "$CONTRACT" --json 2>&1)"
  RC=$?
}

# gate_status <json> <gate id> -> pass|fail|absent
gate_status() {
  printf '%s' "$1" | python3 -c '
import json, sys
gid = sys.argv[1]
try:
    data = json.load(sys.stdin)
except Exception:
    print("unparseable"); sys.exit(0)
for g in data.get("data", {}).get("gates", []):
    if g["id"] == gid:
        print(g["status"]); sys.exit(0)
print("absent")
' "$2"
}

# ---------------------------------------------------------------- NV1 the fixture passes
run "$FIXTURE"
if [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -q '"success": true'; then
  pass "NV1 the conforming fixture passes every gate"
else
  printf '%s\n' "$OUT" | sed 's/^/    /'
  fail "NV1 the conforming fixture passes every gate (exit $RC)"
fi

# expect_red <id> <gate> <mutant path> — the mutant must exit non-zero AND name the gate red
expect_red() {
  run "$3"
  status="$(gate_status "$OUT" "$2")"
  if [ "$RC" -ne 0 ] && [ "$status" = "fail" ]; then
    pass "$1 mutant turns $2 red"
  else
    printf '%s\n' "    exit=$RC gate=$2 status=$status"
    fail "$1 mutant turns $2 red"
  fi
}

# ---------------------------------------------------------------- NV2 fifth `##` -> S1
python3 - "$FIXTURE" "$TMPROOT/fifth.md" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8").read()
open(dst, "w", encoding="utf-8").write(text.rstrip("\n") + "\n\n## Appendix\n\nExtra section.\n")
PY
expect_red NV2 S1 "$TMPROOT/fifth.md"

# ---------------------------------------------------------------- NV3 renamed heading -> S2
sed 's/^## Why Now: Forcing Functions$/## Why Now: The Closing Window/' "$FIXTURE" > "$TMPROOT/renamed.md"
expect_red NV3 S2 "$TMPROOT/renamed.md"

# ---------------------------------------------------------------- NV4 body far under band -> C1
python3 - "$FIXTURE" "$TMPROOT/short.md" <<'PY'
import sys, re
src, dst = sys.argv[1], sys.argv[2]
lines = open(src, encoding="utf-8").read().splitlines()
out, in_pay = [], False
for line in lines:
    if line.startswith("## Why Pay"):
        in_pay = True
        out.append(line)
        out.append("")
        out.append("Short.")
        continue
    if in_pay:
        continue
    out.append(line)
open(dst, "w", encoding="utf-8").write("\n".join(out) + "\n")
PY
expect_red NV4 C1 "$TMPROOT/short.md"

# ---------------------------------------------------------------- NV5 arc_id mismatch -> C3
sed 's/^arc_id: "corporate-visions"$/arc_id: "jtbd-portfolio"/' "$FIXTURE" > "$TMPROOT/arcid.md"
expect_red NV5 C3 "$TMPROOT/arcid.md"

# ---------------------------------------------------------------- NV6 citations stripped -> E1
sed -E 's#<sup>\[[0-9]+\]\([^)]*\)</sup>##g' "$FIXTURE" > "$TMPROOT/nocites.md"
expect_red NV6 E1 "$TMPROOT/nocites.md"

# ---------------------------------------------------------------- NV7 numbering gap -> E2
sed 's#<sup>\[2\](source-02-vdma.md)</sup>#<sup>[30](source-02-vdma.md)</sup>#g' "$FIXTURE" > "$TMPROOT/gap.md"
expect_red NV7 E2 "$TMPROOT/gap.md"

# ---------------------------------------------------------------- NV8 DE ASCII fallback -> L1
# Switch the language flag to `de` and plant one digraph. S2 goes red too (the headings are
# English), which is why the assertion is on L1 by name rather than on the exit code alone.
sed -e 's/^language: "en"$/language: "de"/' -e 's/The cost of delay compounds\./Die Kosten fuer Verzoegerung steigen./' "$FIXTURE" > "$TMPROOT/ascii.md"
expect_red NV8 L1 "$TMPROOT/ascii.md"

# ---------------------------------------------------------------- NV9 TL;DR over band -> T1
python3 - "$FIXTURE" "$TMPROOT/longtldr.md" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
lines = open(src, encoding="utf-8").read().splitlines()
out, seen_sub = [], False
for line in lines:
    out.append(line)
    if line.startswith("*") and line.endswith("*") and not seen_sub:
        seen_sub = True
        out.append("")
        out.append(" ".join(["Padding sentence number %d adds words to the opening." % i for i in range(1, 9)]))
open(dst, "w", encoding="utf-8").write("\n".join(out) + "\n")
PY
expect_red NV9 T1 "$TMPROOT/longtldr.md"

# ---------------------------------------------------------------- NV10 TL;DR cites a number the body lacks -> T2
# The TL;DR's second citation is rewritten to a number no body sentence carries. Only the
# first occurrence (which is in the TL;DR) is touched, so the body stays intact.
python3 - "$FIXTURE" "$TMPROOT/orphan.md" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding="utf-8").read()
needle = "<sup>[1](source-01-fraunhofer.md)</sup>, so the constraint"
if needle not in t:
    sys.exit(1)
t = t.replace(needle, "<sup>[99](source-09-nowhere.md)</sup>, so the constraint", 1)
open(dst, "w", encoding="utf-8").write(t)
PY
expect_red NV10 T2 "$TMPROOT/orphan.md"

# ---------------------------------------------------------------- NV11 cited entry dropped from Sources -> X1
# The replayable form of the Sources-block mutation recipe: drop one entry that the body
# still cites, re-run the deterministic gates, expect X1 red.
grep -v '^\[2\] ' "$FIXTURE" > "$TMPROOT/dropped.md"
expect_red NV11 X1 "$TMPROOT/dropped.md"

# ---------------------------------------------------------------- NV12 uncited entry added to Sources -> X1
{ cat "$FIXTURE"; echo '[9] source-09-nowhere.md — Nobody, "Uncited", 2026, https://example.org/uncited'; } > "$TMPROOT/uncited.md"
expect_red NV12 X1 "$TMPROOT/uncited.md"

# ---------------------------------------------------------------- NV13 a source carrying two numbers -> E3
# The last marker of source-02 is renumbered to a fresh 5, which keeps first-appearance order
# intact (1,2,3,4,5) so E2 stays green and E3 alone carries the finding.
python3 - "$FIXTURE" "$TMPROOT/twonums.md" <<'PY2'
import sys, re
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding="utf-8").read()
body, sep, rest = t.partition("\n**Sources**")
idx = body.rfind("<sup>[2](source-02-vdma.md)</sup>")
if idx < 0:
    sys.exit(1)
body = body[:idx] + "<sup>[5](source-02-vdma.md)</sup>" + body[idx + len("<sup>[2](source-02-vdma.md)</sup>"):]
open(dst, "w", encoding="utf-8").write(body + sep + rest)
PY2
expect_red NV13 E3 "$TMPROOT/twonums.md"

# ---------------------------------------------------------------- NV14 / NV15 the two end-to-end fixtures pass
for pair in "strategic-choice-en.md:strategic-choice:NV14" "consulting-problem-solving-de.md:consulting-problem-solving:NV15"; do
  f="${pair%%:*}"; rest="${pair#*:}"; arc="${rest%%:*}"; cid="${rest#*:}"
  OUT="$(python3 "$VALIDATOR" --narrative "$PLUGIN_DIR/tests/fixtures/narrative-output/$f" --contract "$PLUGIN_DIR/skills/narrative/references/story-arc/$arc/arc-definition.md" --json 2>&1)"
  RC=$?
  if [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -q '"success": true'; then
    pass "$cid end-to-end fixture $f passes every gate against the $arc contract"
  else
    printf '%s\n' "$OUT" | sed 's/^/    /'
    fail "$cid end-to-end fixture $f passes every gate against the $arc contract (exit $RC)"
  fi
done

# ---------------------------------------------------------------- summary
echo ""
if [ "$failures" -gt 0 ]; then
  echo "RESULT: $failures narrative-validate case(s) failed."
  exit 1
fi
echo "RESULT: all narrative-validate cases passed."
exit 0
