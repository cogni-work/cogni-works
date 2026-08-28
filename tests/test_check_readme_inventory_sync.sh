#!/usr/bin/env bash
# test_check_readme_inventory_sync.sh — self-test for the root-README inventory guard.
#
# The guard binds every per-plugin count claim in the ROOT README — the prose
# sentence, the "Plugins at a glance" table row, and the roll-up total — to
# counts globbed from disk at run time. Cases:
#   1. Consistent fixture -> exit 0, zero violations.
#   2. Prose / table / roll-up mismatches each -> exit 1 with their own code.
#   3. Grammar: the singular "1 skill and 1 agent." parses as a claim. Without
#      this arm a plugin shipping exactly one skill is silently unguarded.
#   4. A claim line that ALSO carries a mid-sentence count phrase yields exactly
#      one claim, taking the sentence-final numbers. The real README has such a
#      line, so a phrase-blind regex would double-match it.
#   5. Scope: a per-plugin README is never opened, and a linked table row
#      OUTSIDE the glance section is not a claim. The second property is why the
#      guard scopes to H2 sections rather than scanning the file.
#   6. Failing loudly: a renamed anchor heading, and a README with no claim at
#      all, both exit non-zero rather than reporting a clean zero.
#   7. Real repo at branch head -> exit 0, and each of the three real claim
#      sites reverted independently -> exit 1.
#
# bash 3.2 + stdlib python3 only. No arguments, no network.
#
# Result-line ids: every emitted PASS:/FAIL: line carries a first-token id
# (risNN), unique PER EMITTED LINE rather than per logical case, so
# `mutation-check.sh --case <id>` addresses exactly one assertion. The id is
# followed by a SPACE, never a colon abutting it — the harness matches the
# case whole-token, so a colon-abutting id returns case_not_found. A new
# assertion takes the next free id rather than renumbering its neighbours.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-readme-inventory-sync.py"

# Plain text on purpose — result lines are machine-read; tooling anchors a
# literal PASS:/FAIL: prefix. Emit unconditionally, never probe the environment.
red()   { printf '%s\n' "$1"; }
green() { printf '%s\n' "$1"; }

FAILED=0
check() {  # check <label> <condition-exit-code>
  if [ "$2" -eq 0 ]; then
    green "PASS: $1"
  else
    red "FAIL: $1"
    FAILED=1
  fi
}

assert_json() {  # assert_json <label> <json> <python-asserts>
  set +e
  printf '%s' "$2" | python3 -c "$3"
  local _code=$?
  set -e
  check "$1" "$_code"
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# make_plugin <fixture-root> <name> <n-skills> <n-agents>
make_plugin() {
  local root="$1" name="$2" nskills="$3" nagents="$4" i=1
  mkdir -p "$root/$name/.claude-plugin"
  printf '{\n  "name": "%s",\n  "version": "0.0.1"\n}\n' "$name" \
    > "$root/$name/.claude-plugin/plugin.json"
  while [ "$i" -le "$nskills" ]; do
    mkdir -p "$root/$name/skills/skill-$i"
    printf 'skill %s\n' "$i" > "$root/$name/skills/skill-$i/SKILL.md"
    i=$((i + 1))
  done
  i=1
  while [ "$i" -le "$nagents" ]; do
    mkdir -p "$root/$name/agents"
    printf 'agent %s\n' "$i" > "$root/$name/agents/agent-$i.md"
    i=$((i + 1))
  done
}

# make_marketplace <fixture-root> <name>...
make_marketplace() {
  local root="$1"; shift
  mkdir -p "$root/.claude-plugin"
  {
    printf '{\n  "name": "fixture",\n  "plugins": [\n'
    local first=1
    for n in "$@"; do
      [ $first -eq 1 ] || printf ',\n'
      first=0
      printf '    {"name": "%s", "source": "./%s", "version": "0.0.1"}' "$n" "$n"
    done
    printf '\n  ]\n}\n'
  } > "$root/.claude-plugin/marketplace.json"
}

# begin_readme <fixture-root>
begin_readme() {
  printf '# Fixture\n\n## What the plugins do\n\n' > "$1/README.md"
}

# add_prose <fixture-root> <name> <skills-phrase> <agents-phrase> [lead-in]
add_prose() {
  local root="$1" name="$2" sk="$3" ag="$4" lead="${5:-}"
  printf '[%s](%s/README.md) does things. %s%s and %s.\n\n' \
    "$name" "$name" "$lead" "$sk" "$ag" >> "$root/README.md"
}

# begin_table <fixture-root>
begin_table() {
  {
    printf '## Plugins at a glance\n\n'
    printf '| Plugin | Capability | Skills | Agents | What it does |\n'
    printf '|--------|-----------|--------|--------|--------------|\n'
  } >> "$1/README.md"
}

# add_row <fixture-root> <name> <skills> <agents>
add_row() {
  printf '| [%s](%s/README.md) | Capability | %s | %s | Does things |\n' \
    "$2" "$2" "$3" "$4" >> "$1/README.md"
}

# add_rollup <fixture-root> <skills> <agents> <plugins>
add_rollup() {
  printf '\n**%s skills, %s agents** across the %s active plugins.\n' \
    "$2" "$3" "$4" >> "$1/README.md"
}

run_guard() {  # run_guard <root> -> sets OUT, CODE
  set +e
  OUT=$(python3 "$GUARD" --root "$1" 2>/dev/null)
  CODE=$?
  set -e
}

# consistent_fixture <root> — two plugins, every claim matching live counts.
consistent_fixture() {
  local root="$1"
  make_plugin "$root" cogni-alpha 3 2
  make_plugin "$root" cogni-beta 1 1
  make_marketplace "$root" cogni-alpha cogni-beta
  begin_readme "$root"
  add_prose "$root" cogni-alpha "3 skills" "2 agents"
  add_prose "$root" cogni-beta "1 skill" "1 agent"
  begin_table "$root"
  add_row "$root" cogni-alpha 3 2
  add_row "$root" cogni-beta 1 1
  add_rollup "$root" 4 3 2
}

# real_scratch <name> — a scratch root whose README is a COPY of the real one and
# whose plugin directories and manifest are SYMLINKS to the real tree, so the
# real README can be mutated without touching the repo. glob resolves a
# symlinked directory through an ordinary listdir (only the '*' component is
# expanded), so the live counts are identical to a run against REPO_ROOT.
real_scratch() {
  local dest="$WORK/$1"
  mkdir -p "$dest"
  cp "$REPO_ROOT/README.md" "$dest/README.md"
  ln -s "$REPO_ROOT/.claude-plugin" "$dest/.claude-plugin"
  for d in "$REPO_ROOT"/cogni-*; do
    [ -d "$d" ] || continue
    ln -s "$d" "$dest/$(basename "$d")"
  done
  printf '%s' "$dest"
}

# mutate <file> <old> <new> — python3, never `sed -i` (its in-place flag differs
# between GNU and BSD, so a sed form passes locally and breaks on the runner).
mutate() {
  OLD="$2" NEW="$3" python3 - "$1" <<'PY'
import io, os, sys
p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()
old, new = os.environ["OLD"], os.environ["NEW"]
assert s.count(old) == 1, (p, s.count(old), old)
io.open(p, "w", encoding="utf-8").write(s.replace(old, new))
PY
}

# ---------------------------------------------------------------- case 1
CONSISTENT="$WORK/consistent"
consistent_fixture "$CONSISTENT"
run_guard "$CONSISTENT"
check "ris01 consistent fixture exits 0" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "ris02 consistent fixture reports zero violations" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
assert d['data']['plugins_enumerated']==2, d['data']
assert d['data']['prose_claims']==2, d['data']
assert d['data']['table_claims']==2, d['data']
assert d['data']['rollup_present'] is True, d['data']
"

# The singular arm, asserted against the SAME consistent run above: cogni-beta
# ships exactly 1 skill and 1 agent, so its claim reads "1 skill and 1 agent." A
# plural-only regex would not match it and the plugin would report
# prose-claim-missing, so ris09 pins the property directly rather than leaving
# it implied by ris02's totals.
assert_json "ris09 singular one skill and one agent parses as a claim" "$OUT" "
import json,sys
d=json.load(sys.stdin)
missing=[x for x in d['data']['violations']
         if x['code'] in ('prose-claim-missing','table-claim-missing')]
assert missing==[], missing
assert d['data']['prose_claims']==2, d['data']
"

# ---------------------------------------------------------------- case 2
PROSE_BAD="$WORK/prose-mismatch"
consistent_fixture "$PROSE_BAD"
mutate "$PROSE_BAD/README.md" "does things. 3 skills and 2 agents." "does things. 9 skills and 2 agents."
run_guard "$PROSE_BAD"
check "ris03 prose count mismatch exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ris04 prose mismatch reports prose-count-mismatch naming the plugin" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
v=[x for x in d['data']['violations'] if x['code']=='prose-count-mismatch']
assert len(v)==1, d['data']['violations']
assert v[0]['plugin']=='cogni-alpha', v
"

# ---------------------------------------------------------------- case 3
TABLE_BAD="$WORK/table-mismatch"
consistent_fixture "$TABLE_BAD"
mutate "$TABLE_BAD/README.md" "| [cogni-alpha](cogni-alpha/README.md) | Capability | 3 | 2 |" \
                              "| [cogni-alpha](cogni-alpha/README.md) | Capability | 7 | 2 |"
run_guard "$TABLE_BAD"
check "ris05 table cell mismatch exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ris06 table mismatch reports table-count-mismatch naming the plugin" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
v=[x for x in d['data']['violations'] if x['code']=='table-count-mismatch']
assert len(v)==1, d['data']['violations']
assert v[0]['plugin']=='cogni-alpha', v
"

# ---------------------------------------------------------------- case 4
ROLLUP_BAD="$WORK/rollup-mismatch"
consistent_fixture "$ROLLUP_BAD"
mutate "$ROLLUP_BAD/README.md" "**4 skills, 3 agents**" "**5 skills, 3 agents**"
run_guard "$ROLLUP_BAD"
check "ris07 roll-up mismatch exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ris08 roll-up mismatch reports rollup-count-mismatch" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
v=[x for x in d['data']['violations'] if x['code']=='rollup-count-mismatch']
assert len(v)==1, d['data']['violations']
assert v[0]['plugin'] is None, v
"


# ---------------------------------------------------------------- case 6
# A claim line that ALSO carries a mid-sentence count phrase. The real README
# has one: a plugin paragraph opening "... 21 skills handle the full positioning
# lifecycle ..." and closing "21 skills and 20 agents." The line DOES match, once
# — asserting it does not match would pin the wrong property.
MIDSENT="$WORK/mid-sentence"
make_plugin "$MIDSENT" cogni-alpha 3 2
make_marketplace "$MIDSENT" cogni-alpha
begin_readme "$MIDSENT"
add_prose "$MIDSENT" cogni-alpha "3 skills" "2 agents" "9 skills handle the whole lifecycle. "
begin_table "$MIDSENT"
add_row "$MIDSENT" cogni-alpha 3 2
add_rollup "$MIDSENT" 3 2 1
run_guard "$MIDSENT"
assert_json "ris10 mid-sentence skills phrase yields exactly one claim with the final numbers" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['prose_claims']==1, d['data']
amb=[x for x in d['data']['violations'] if x['code']=='prose-claim-ambiguous']
assert amb==[], amb
"

# ---------------------------------------------------------------- case 7
NOAGENTS="$WORK/no-agents-dir"
make_plugin "$NOAGENTS" cogni-alpha 2 0
make_marketplace "$NOAGENTS" cogni-alpha
begin_readme "$NOAGENTS"
add_prose "$NOAGENTS" cogni-alpha "2 skills" "0 agents"
begin_table "$NOAGENTS"
add_row "$NOAGENTS" cogni-alpha 2 0
add_rollup "$NOAGENTS" 2 0 1
run_guard "$NOAGENTS"
assert_json "ris11 plugin with no agents directory counts zero without erroring" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['live_counts']['cogni-alpha']['agents']==0, d['data']['live_counts']
"

# ---------------------------------------------------------------- case 8
# A per-plugin README carrying a wrong claim must be invisible: the guard reads
# exactly one file, and asserting over both would put two guards on one claim
# and none on the other.
PLUGIN_README="$WORK/plugin-readme"
consistent_fixture "$PLUGIN_README"
printf '[cogni-alpha](cogni-alpha/README.md) does things. 99 skills and 99 agents.\n' \
  > "$PLUGIN_README/cogni-alpha/README.md"
run_guard "$PLUGIN_README"
check "ris12 per-plugin README claim is not discovered" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "ris13 no count from a per-plugin README reaches the result" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['data']['live_counts']['cogni-alpha']=={'skills':3,'agents':2}, d['data']['live_counts']
assert '99' not in json.dumps(d['data']['violations']), d['data']['violations']
assert d['data']['files_scanned']==['README.md'], d['data']['files_scanned']
"

# ---------------------------------------------------------------- case 9
NOCLAIMS="$WORK/no-claims"
make_plugin "$NOCLAIMS" cogni-alpha 3 2
make_marketplace "$NOCLAIMS" cogni-alpha
begin_readme "$NOCLAIMS"
printf 'Prose with no count claim at all.\n\n' >> "$NOCLAIMS/README.md"
begin_table "$NOCLAIMS"
run_guard "$NOCLAIMS"
check "ris14 README with no recognizable claim exits non-zero" "$([ "$CODE" -ne 0 ] && echo 0 || echo 1)"
assert_json "ris15 no-claim README reports no-claims-discovered" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
v=[x for x in d['data']['violations'] if x['code']=='no-claims-discovered']
assert len(v)==1, d['data']['violations']
"

# ---------------------------------------------------------------- case 10
NOREADME="$WORK/no-readme"
make_plugin "$NOREADME" cogni-alpha 1 1
make_marketplace "$NOREADME" cogni-alpha
run_guard "$NOREADME"
check "ris16 missing root README exits 2 not 1" "$([ "$CODE" -eq 2 ] && echo 0 || echo 1)"
assert_json "ris17 missing root README reports the error in the envelope" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
assert d['error'], d
assert d['data']=={}, d
"

# ---------------------------------------------------------------- case 11
# The table's row order and the manifest's plugins[] order genuinely differ in
# the real README, so rows must be keyed by their link text, never by index.
REORDERED="$WORK/reordered"
make_plugin "$REORDERED" cogni-alpha 3 2
make_plugin "$REORDERED" cogni-beta 1 1
make_marketplace "$REORDERED" cogni-alpha cogni-beta
begin_readme "$REORDERED"
add_prose "$REORDERED" cogni-alpha "3 skills" "2 agents"
add_prose "$REORDERED" cogni-beta "1 skill" "1 agent"
begin_table "$REORDERED"
add_row "$REORDERED" cogni-beta 1 1
add_row "$REORDERED" cogni-alpha 3 2
add_rollup "$REORDERED" 4 3 2
run_guard "$REORDERED"
assert_json "ris18 table order differing from marketplace order is keyed by name" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
"

# ---------------------------------------------------------------- case 12
REAL_CLEAN=$(real_scratch real-clean)
run_guard "$REAL_CLEAN"
check "ris19 real repo at HEAD exits 0" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "ris20 real repo reports zero violations across every marketplace plugin" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
n=d['data']['plugins_enumerated']
assert n>0, d['data']
assert d['data']['prose_claims']==n, d['data']
assert d['data']['table_claims']==n, d['data']
assert d['data']['rollup_present'] is True, d['data']
"

# ---------------------------------------------------------------- case 13
# The three real claim sites, reverted one at a time. Each must redden on its
# own: a guard that only notices one of them leaves the other two drifting.
REAL_PROSE=$(real_scratch real-prose-reverted)
mutate "$REAL_PROSE/README.md" "management. 24 skills and 26 agents." "management. 25 skills and 26 agents."
run_guard "$REAL_PROSE"
check "ris21 real README with the workspace prose count reverted exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ris22 reverted prose reports prose-count-mismatch naming cogni-workspace" "$OUT" "
import json,sys
d=json.load(sys.stdin)
v=[x for x in d['data']['violations'] if x['code']=='prose-count-mismatch']
assert len(v)==1, d['data']['violations']
assert v[0]['plugin']=='cogni-workspace', v
"

REAL_TABLE=$(real_scratch real-table-reverted)
mutate "$REAL_TABLE/README.md" "| Workspace Infrastructure | 24 | 26 |" "| Workspace Infrastructure | 25 | 26 |"
run_guard "$REAL_TABLE"
check "ris23 real README with the workspace table cell reverted exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"

REAL_ROLLUP=$(real_scratch real-rollup-reverted)
mutate "$REAL_ROLLUP/README.md" "**102 skills, 88 agents**" "**103 skills, 88 agents**"
run_guard "$REAL_ROLLUP"
check "ris24 real README with the roll-up total reverted exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"

# ---------------------------------------------------------------- case 14
# The singular arm against the real tree: one plugin's claim reads
# "1 skill and N agents." Pluralising it must redden, which proves the singular
# form was being read as a claim rather than skipped.
REAL_SINGULAR=$(real_scratch real-singular)
mutate "$REAL_SINGULAR/README.md" "pitches. 1 skill and 4 agents." "pitches. 2 skills and 4 agents."
run_guard "$REAL_SINGULAR"
check "ris25 real README with the singular claim pluralized exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"

# ---------------------------------------------------------------- case 15
# Section scoping. A pipe table OUTSIDE the glance section whose first cell is a
# markdown link must not be read as a claim: the real README carries such a
# table one formatting edit away from this shape, and a file-wide scan would
# redden a blocking gate on a change that has nothing to do with counts.
FOREIGN_TABLE="$WORK/foreign-table"
consistent_fixture "$FOREIGN_TABLE"
{
  printf '\n## Install\n\n'
  printf '| Server | Used by | What it enables |\n'
  printf '|--------|---------|-----------------|\n'
  printf '| [excalidraw](https://example.invalid/excalidraw) | [cogni-alpha](cogni-alpha/README.md) | Diagram rendering |\n'
} >> "$FOREIGN_TABLE/README.md"
run_guard "$FOREIGN_TABLE"
check "ris26 a linked table row outside the glance section is not discovered" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"

# ---------------------------------------------------------------- case 16
RENAMED="$WORK/renamed-heading"
consistent_fixture "$RENAMED"
mutate "$RENAMED/README.md" "## Plugins at a glance" "## The plugins, at a glance"
run_guard "$RENAMED"
assert_json "ris27 renaming the glance heading reports section-missing and fails" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
v=[x for x in d['data']['violations'] if x['code']=='section-missing']
assert len(v)==1, d['data']['violations']
"

# ---------------------------------------------------------------- case 17
# The count cells are located from the table's own header row, not pinned to a
# fixed offset. The generator that reassembles this README carries a different
# column set, so a fixed offset would read the wrong column the day one moves.
# ris28: a header naming neither count column fails loudly with its own code
# rather than reporting every row as unparsable cells.
NO_HEADER="$WORK/table-header-unrecognized"
make_plugin "$NO_HEADER" cogni-alpha 3 2
make_marketplace "$NO_HEADER" cogni-alpha
begin_readme "$NO_HEADER"
add_prose "$NO_HEADER" cogni-alpha "3 skills" "2 agents"
{
  printf '## Plugins at a glance\n\n'
  printf '| Plugin | Capability | Maturity | What it does |\n'
  printf '|--------|-----------|----------|--------------|\n'
  printf '| [cogni-alpha](cogni-alpha/README.md) | Capability | Preview | Does things |\n'
} >> "$NO_HEADER/README.md"
add_rollup "$NO_HEADER" 3 2 1
run_guard "$NO_HEADER"
assert_json "ris28 a table header naming no count column reports table-header-unrecognized" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
v=[x for x in d['data']['violations'] if x['code']=='table-header-unrecognized']
assert len(v)==1, d['data']['violations']
unparsable=[x for x in d['data']['violations'] if x['code']=='table-cell-unparsable']
assert unparsable==[], unparsable
"

# ris29: the same table with an EXTRA column inserted before Skills still reads
# the right cells. Under a fixed parts[3]/parts[4] offset this run reports the
# inserted column as a non-integer count instead of passing.
SHIFTED="$WORK/table-columns-shifted"
make_plugin "$SHIFTED" cogni-alpha 3 2
make_marketplace "$SHIFTED" cogni-alpha
begin_readme "$SHIFTED"
add_prose "$SHIFTED" cogni-alpha "3 skills" "2 agents"
{
  printf '## Plugins at a glance\n\n'
  printf '| Plugin | Capability | Maturity | Skills | Agents | What it does |\n'
  printf '|--------|-----------|----------|--------|--------|--------------|\n'
  printf '| [cogni-alpha](cogni-alpha/README.md) | Capability | Preview | 3 | 2 | Does things |\n'
} >> "$SHIFTED/README.md"
add_rollup "$SHIFTED" 3 2 1
run_guard "$SHIFTED"
check "ris29 a count column shifted by an inserted column is still read correctly" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"

echo
if [ "$FAILED" -eq 0 ]; then
  green "All README inventory-sync guard tests passed."
else
  red "Some README inventory-sync guard tests FAILED."
fi
exit "$FAILED"
