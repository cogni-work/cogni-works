#!/usr/bin/env bash
# Guard: every story arc the narrative skill ships is one v2 contract file of a fixed
# shape, and nothing else.
#
# WHAT THIS PINS
#   skills/narrative/references/story-arc/{arc}/arc-definition.md is the single authority
#   for an arc: its headings, its composition, its four elements and its own validation
#   rules. Before this contract existed the same facts lived in three layers that
#   disagreed with each other — the arc definition, a phase-4b workflow file and four
#   pattern files no workflow ever read. This suite is what keeps the authority single:
#   it asserts the contract's frontmatter, its heading set AND order, the four element
#   sections with their six subfields, and that no second layer has grown back beside it.
#
# THE RATCHET
#   Migration is incremental. UNMIGRATED lists the arcs still on the old three-layer
#   shape; for those, SKILL.md Phase 3 follows the phase-4b file instead of the contract's
#   ## Elements. The list is shrink-only in both directions (U1): an entry naming an arc
#   that is no longer upstream turns the suite red, and so does an entry naming an arc
#   whose contract now carries `contract: 2`. A migrated arc must also carry no pattern
#   file and no phase-4b file (C4). Adding an arc to UNMIGRATED to silence C1-C4 inverts
#   the guard's purpose.
#
# THE ARC COUNT IS NEVER PINNED. The directory set and the `contract: 2` subset are both
#   enumerated at run time. The one written-down list is UNMIGRATED, sanctioned only
#   because U1 asserts it shrink-only.
#
# NON-VACUITY. V1 fails when the story-arc root holds no arc directory, so a moved or
#   renamed root cannot yield an all-green empty pass. The root is overridable by env var
#   solely so V1 and M1 can be exercised against a copy under mktemp -d.
#
# THE NEGATIVE CASE IS SELF-HOSTED (M1). It copies the whole story-arc tree into this
#   run's own mktemp -d, deletes the `## Headings` heading from a runtime-selected migrated
#   contract, re-invokes this same file against the mutant behind a recursion guard, and
#   asserts both a non-zero exit and a `FAIL: C1` line naming that arc. It never writes to
#   a tracked path. M1 also pins ALL_CASES against the ids the child run emitted, both
#   directions, so a case cannot be added or removed without registering it here.
#
# CASE LABEL SHAPE: `PASS: <id>` / `FAIL: <id>` with a single-token id; the summary line
#   begins `RESULT:` so it is never read as a case verdict. stdlib-only: bash + coreutils
#   + python3. No network. Writes only under its own mktemp -d.

set -u
export LC_ALL=C

HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$HERE/.." && pwd)"
ARC_DIR="${ARC_CONTRACT_STORY_ARC_DIR:-$PLUGIN_DIR/skills/narrative/references/story-arc}"
PHASE_DIR="${ARC_CONTRACT_PHASE_DIR:-$PLUGIN_DIR/skills/narrative/references/phase-workflows}"
REGISTRY="${ARC_CONTRACT_REGISTRY:-$ARC_DIR/arc-registry.md}"

# Arcs still on the three-layer shape. Shrink-only — see THE RATCHET above.
UNMIGRATED=""

# The contract shape, stated once. Order matters for C1; the six subfields for C2.
HEADINGS="Intent Selection Headings Composition Elements Validation See_Also"
SUBFIELDS="Purpose|Evidence sought|Argument move|Techniques|Hard rules|Failure modes"

ALL_CASES="V1 C1 C2 C3 C4 C5 U1 M1 M2"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

finish() {
  echo ""
  if [ "$failures" -gt 0 ]; then
    echo "RESULT: $failures arc-contract-shape case(s) failed."
    exit 1
  fi
  echo "RESULT: all arc-contract-shape cases passed."
  exit 0
}

in_list() { case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# ---------------------------------------------------------------------------- V1
arcs="$(find "$ARC_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort)"
if [ -z "$arcs" ]; then
  fail "V1 story-arc root yielded no arc directory at $ARC_DIR"
  for c in C1 C2 C3 C4 C5 U1; do fail "$c not evaluated — non-vacuity guard failed"; done
  finish
fi
pass "V1 story-arc root yielded $(printf '%s\n' "$arcs" | wc -l | tr -d ' ') arc directory/ies"

# Which arcs are migrated: frontmatter carries `contract: 2`.
migrated=""
for arc in $arcs; do
  f="$ARC_DIR/$arc/arc-definition.md"
  [ -f "$f" ] || continue
  if awk 'NR==1 && $0!="---" {exit 1} NR>1 && $0=="---" {exit 0} /^contract: *2 *$/ {found=1} END {exit found?0:1}' "$f"; then
    migrated="$migrated $arc"
  fi
done
migrated="${migrated# }"

# ---------------------------------------------------------------------------- C1 / C2 / C3
c1_bad="" c2_bad="" c3_bad=""
for arc in $migrated; do
  f="$ARC_DIR/$arc/arc-definition.md"
  # C1: the seven H2s, exactly, in order.
  got="$(grep -E '^## ' "$f" | sed 's/^## //; s/ /_/g' | tr '\n' ' ' | sed 's/ *$//')"
  [ "$got" = "$HEADINGS" ] || c1_bad="$c1_bad $arc"
  # C2: exactly four `### N.` sections inside ## Elements, each with all six subfields.
  if ! python3 - "$f" "$SUBFIELDS" <<'PY'
import re, sys
path, subfields = sys.argv[1], sys.argv[2].split("|")
text = open(path, encoding="utf-8").read()
m = re.search(r"^## Elements\n(.*?)(?=^## )", text, flags=re.S | re.M)
if not m:
    sys.exit(1)
body = m.group(1)
heads = re.findall(r"^### (\d+)\. ", body, flags=re.M)
if heads != ["1", "2", "3", "4"]:
    sys.exit(1)
parts = re.split(r"^### \d+\. .*$", body, flags=re.M)[1:]
for part in parts:
    for sf in subfields:
        if not re.search(r"^\*\*%s:\*\*" % re.escape(sf), part, flags=re.M):
            sys.exit(1)
sys.exit(0)
PY
  then c2_bad="$c2_bad $arc"; fi
  # C3: ## Headings carries EN and DE columns and exactly four rows of non-empty cells whose
  # DE cells carry real umlauts rather than an ASCII digraph where one is expected. The contract
  # is the single heading authority; there is no second file to compare against.
  if ! python3 - "$f" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
m = re.search(r"^## Headings\n(.*?)(?=^## )", text, flags=re.S | re.M)
if not m:
    sys.exit(1)
rows = [l for l in m.group(1).splitlines() if l.strip().startswith("|")]
if len(rows) < 3:
    sys.exit(1)
header = [c.strip() for c in rows[0].strip().strip("|").split("|")]
if "EN" not in header or "DE" not in header:
    sys.exit(1)
data = [[c.strip() for c in r.strip().strip("|").split("|")] for r in rows[2:]]
if len(data) != 4:
    sys.exit(1)
en, de = header.index("EN"), header.index("DE")
for r in data:
    if not r[en] or not r[de]:
        sys.exit(1)
    # A DE cell spelling a real umlaut word with a digraph is the ASCII substitution the
    # copywriter's runtime read would then propagate; the same words with real umlauts are
    # what every contract carries today. Stems are matched as PREFIXES (word start, no end
    # anchor, case-insensitive) so inflected forms — Möglichkeiten, Lösungen, nächste,
    # verläuft, Geschäftliche — are caught, not only the uninflected stem.
    if re.search(r"(?i)\b(?:fuer|ueber|aenderung|veraenderung|kraefte|fuehrung|moeglich|loesung|ueberzeugung|glaubwuerdig|einfluesse|begruendung|naechste|verlaeuft|schliess|geschaeft|fruehindikator|ansaetze|wettbewerbsuebersicht|prioritaet|staerke|zurueck|gegenueber|waehrend|koennen|muessen|groesst|hoehe|voellig|schluessel|verfuegbar|gefuehrt|bewaehrt|gruende|wuerde|dafuer|veraendert|entscheidungstraeger|einfuehrung)", r[de]):
        sys.exit(1)
sys.exit(0)
PY
  then c3_bad="$c3_bad $arc"; fi
done

# C5: the registry carries one declarative block per arc directory, with all six fields.
c5_bad=""
if [ -f "$REGISTRY" ]; then
  for arc in $arcs; do
    [ -f "$ARC_DIR/$arc/arc-definition.md" ] || continue
    block="$(awk -v a="### $arc" '$0==a{f=1; next} /^### |^## /{f=0} f' "$REGISTRY")"
    [ -n "$block" ] || { c5_bad="$c5_bad $arc(no-block)"; continue; }
    for field in question best_for signals anti_signals distinguish_from fallback_priority; do
      printf '%s\n' "$block" | grep -Eq "^\- \*\*$field:\*\* *[^ ]" || c5_bad="$c5_bad $arc($field)"
    done
  done
else
  c5_bad=" registry-missing"
fi

if [ -z "$migrated" ]; then
  fail "C1 no migrated contract found — nothing carries contract: 2"
  fail "C2 no migrated contract found — nothing carries contract: 2"
  fail "C3 no migrated contract found — nothing carries contract: 2"
else
  [ -z "$c1_bad" ] && pass "C1 every migrated contract carries the seven headings in order" || fail "C1 heading set or order wrong in:$c1_bad"
  [ -z "$c2_bad" ] && pass "C2 every migrated contract carries four ### N. elements with six subfields" || fail "C2 element sections incomplete in:$c2_bad"
  [ -z "$c3_bad" ] && pass "C3 every migrated contract's ## Headings has EN and DE columns, four rows, real umlauts" || fail "C3 headings table wrong in:$c3_bad"
fi
if [ -z "$c5_bad" ]; then
  pass "C5 the registry carries a six-field declarative block for every arc directory"
else
  fail "C5 registry block missing or incomplete:$c5_bad"
fi

# ---------------------------------------------------------------------------- C4
c4_bad=""
for arc in $migrated; do
  if ls "$ARC_DIR/$arc"/*-patterns.md >/dev/null 2>&1; then c4_bad="$c4_bad $arc(patterns)"; fi
  if [ -f "$PHASE_DIR/phase-4b-synthesis-$arc.md" ]; then c4_bad="$c4_bad $arc(phase-4b)"; fi
  extra="$(ls "$ARC_DIR/$arc" | grep -v '^arc-definition.md$' | tr '\n' ',' | sed 's/,$//')"
  [ -z "$extra" ] || c4_bad="$c4_bad $arc(stray:$extra)"
done
if [ -z "$migrated" ]; then
  fail "C4 no migrated contract found — nothing carries contract: 2"
elif [ -z "$c4_bad" ]; then
  pass "C4 no migrated arc carries a second layer (pattern file, phase-4b file or stray file)"
else
  fail "C4 second layer found beside a migrated contract:$c4_bad"
fi

# ---------------------------------------------------------------------------- U1
u1_bad=""
for arc in $UNMIGRATED; do
  in_list "$arc" "$(printf '%s' "$arcs" | tr '\n' ' ')" || u1_bad="$u1_bad $arc(not-upstream)"
  in_list "$arc" "$migrated" && u1_bad="$u1_bad $arc(now-migrated)"
done
for arc in $arcs; do
  in_list "$arc" "$migrated" && continue
  in_list "$arc" "$UNMIGRATED" || u1_bad="$u1_bad $arc(unmigrated-but-unlisted)"
done
if [ -z "$u1_bad" ]; then
  pass "U1 UNMIGRATED lists exactly the arcs without contract: 2, all of them upstream"
else
  fail "U1 UNMIGRATED ratchet out of step:$u1_bad"
fi

# ---------------------------------------------------------------------------- M1
if [ "${ARC_CONTRACT_SHAPE_MUTANT:-0}" = "1" ]; then
  finish
fi

victim="$(printf '%s' "$migrated" | tr ' ' '\n' | head -n 1)"
if [ -z "$victim" ]; then
  fail "M1 no migrated contract available to mutate"
  finish
fi
cp -R "$ARC_DIR" "$TMPROOT/story-arc"
sed 's/^## Headings$/## Headlines/' "$ARC_DIR/$victim/arc-definition.md" > "$TMPROOT/story-arc/$victim/arc-definition.md"
mutant_out="$(ARC_CONTRACT_SHAPE_MUTANT=1 ARC_CONTRACT_STORY_ARC_DIR="$TMPROOT/story-arc" bash "$HERE/$(basename "$0")" 2>&1)"
mutant_rc=$?

printf '%s\n' "$mutant_out" | grep -E '^(PASS|FAIL): ' | awk '{print $2}' | sort -u > "$TMPROOT/emitted.txt"
for c in $ALL_CASES; do case "$c" in M1|M2) ;; *) echo "$c" ;; esac; done | sort -u > "$TMPROOT/expected.txt"
unregistered="$(comm -13 "$TMPROOT/expected.txt" "$TMPROOT/emitted.txt" | tr '\n' ' ')"
unemitted="$(comm -23 "$TMPROOT/expected.txt" "$TMPROOT/emitted.txt" | tr '\n' ' ')"
c1_line="$(printf '%s\n' "$mutant_out" | grep '^FAIL: C1 ' || true)"

if [ "$mutant_rc" -eq 0 ]; then
  fail "M1 renaming ## Headings in '$victim' left the suite GREEN — the guard is vacuous"
elif [ -n "${unregistered// /}" ]; then
  fail "M1 case(s) emitted but missing from ALL_CASES: $unregistered"
elif [ -n "${unemitted// /}" ]; then
  fail "M1 case id(s) in ALL_CASES never emitted: $unemitted"
elif printf '%s\n' "$c1_line" | grep -q "$victim"; then
  pass "M1 renaming ## Headings in '$victim' turns C1 red naming it (child exit $mutant_rc); registry matches"
else
  fail "M1 mutant exited $mutant_rc but not via C1 naming '$victim' — got: $(printf '%s' "$mutant_out" | grep '^FAIL:' | tr '\n' ';')"
fi

# ---------------------------------------------------------------------------- M2
# Second negative: transliterate the WHOLE DE column of the last migrated contract to ASCII
# digraphs (ä→ae, ö→oe, ü→ue, ß→ss) in a copy and require C3 to go red naming that arc. This
# is the exact corruption a prefix-anchored vocabulary has to catch on inflected headings.
m2_victim="$(printf '%s' "$migrated" | tr ' ' '\n' | tail -n 1)"
rm -rf "$TMPROOT/story-arc-m2"
cp -R "$ARC_DIR" "$TMPROOT/story-arc-m2"
python3 - "$ARC_DIR/$m2_victim/arc-definition.md" "$TMPROOT/story-arc-m2/$m2_victim/arc-definition.md" <<'PYM2'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8").read()
m = re.search(r"^## Headings\n(.*?)(?=^## )", text, flags=re.S | re.M)
if not m:
    sys.exit(1)
rows = m.group(1).splitlines()
header = [c.strip() for c in next(l for l in rows if l.strip().startswith("|")).strip().strip("|").split("|")]
de = header.index("DE")
table = {"ä": "ae", "ö": "oe", "ü": "ue", "Ä": "Ae", "Ö": "Oe", "Ü": "Ue", "ß": "ss"}
out = []
for l in rows:
    if l.strip().startswith("|") and not set(l.strip().strip("|").replace("|", "")) <= set("-: "):
        cells = l.strip().strip("|").split("|")
        if cells[0].strip() != header[0]:
            cells[de] = "".join(table.get(ch, ch) for ch in cells[de])
        l = "|" + "|".join(cells) + "|"
    out.append(l)
new = text[: m.start(1)] + "\n".join(out) + "\n" + text[m.end(1):]
if new == text:
    sys.exit(2)
open(dst, "w", encoding="utf-8").write(new)
PYM2
m2_prep=$?
if [ "$m2_prep" -ne 0 ]; then
  fail "M2 could not transliterate the DE headings of '$m2_victim' (prep exit $m2_prep)"
else
  m2_out="$(ARC_CONTRACT_SHAPE_MUTANT=1 ARC_CONTRACT_STORY_ARC_DIR="$TMPROOT/story-arc-m2" bash "$HERE/$(basename "$0")" 2>&1)"
  m2_rc=$?
  if [ "$m2_rc" -ne 0 ] && printf '%s\n' "$m2_out" | grep '^FAIL: C3 ' | grep -q "$m2_victim"; then
    pass "M2 transliterating the DE headings of '$m2_victim' to ASCII digraphs turns C3 red naming it (child exit $m2_rc)"
  else
    fail "M2 mutant exited $m2_rc but C3 did not go red naming '$m2_victim' — got: $(printf '%s' "$m2_out" | grep '^FAIL:' | tr '\n' ';')"
  fi
fi

finish
