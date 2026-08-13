#!/usr/bin/env bash
# Skill trigger-phrase collision guard: no two cogni-workspace skills may
# advertise the same verbatim trigger phrase.
#
# Why this exists. A skill's frontmatter `description:` is the router's only
# input — the host picks a skill by matching the user's words against those
# descriptions. When two skills quote the same phrase, the router has no
# tiebreaker, and which one fires is not a property of the repo at all. Nothing
# else in CI looks at description *content*: check-skill-names.sh checks the
# `name:` field, check-frontmatter.sh checks that required keys exist, and
# plugin-validator checks structure. A duplicated phrase is well-formed by every
# one of those and still broken.
#
# The failure is silent in the worst way. Both skills load, both look correct in
# isolation, and the only symptom is that a user asking the shared phrase
# sometimes lands in the wrong skill. There is no error, no log line, and no
# reproduction that holds still. That is precisely the class of defect a
# deterministic guard is for.
#
# This matters most while capability is being consolidated. Folding a retiring
# skill's material into a surviving one means moving its advertised phrases too,
# and the natural mistake is to add them to the absorbing skill while the
# original still claims them. Within one plugin this guard catches it. Across
# plugins it deliberately does not — see the scope note below.
#
# Contract under test:
#   - phrases are the double-quoted strings inside the frontmatter
#     `description:` block, and nowhere else in the file
#   - a phrase claimed by two different skills fails, and the phrase plus both
#     skill names are printed
#   - a phrase repeated inside ONE description is not a collision
#   - matching is case-insensitive and whitespace-trimmed, so "What Does X Do"
#     and "what does x do" collide
#   - quoted strings in the skill BODY are ignored — bodies are full of quoted
#     examples and would produce constant false positives
#   - every YAML scalar style in the tree (>-, |, "...", '...') yields the same
#     phrases, with the scalar's own delimiters unwrapped first
#   - the real cogni-workspace tree is clean
#   - an empty or missing skills directory fails rather than reporting clean
#
# Scoped to one plugin on purpose. The obvious generalization — scan every
# plugin at once — is wrong here: `cogni-portfolio:markets` and
# `cogni-trends:trends-catalog` may both legitimately quote "show the catalog",
# because the user reaches them through different projects and the host
# disambiguates by plugin. Only phrases competing INSIDE one plugin's skill set
# are unambiguously a defect. A cross-plugin version of this check would need a
# hand-maintained exemption list, which is the thing this design rejects.
#
# The extractor takes the description block as everything from `description:` up
# to the next top-level frontmatter key. Both YAML block styles in the tree
# (`>-` and `|`) fold into that same shape, so neither needs special handling —
# but a phrase must not be quoted in a *disclaimer* either ("read-only requests
# such as \"show X\" route elsewhere" still reads as a claim to this guard, and
# to the router). Say it without the quotes.
#
# bash-3.2 portable (stock macOS /bin/bash is 3.2.57): no declare -A / typeset -A,
# no mapfile / readarray, no ${var^^} / ${var,,}. Phrase-to-skill accumulation
# runs through a temp file and `sort`/`uniq`, which is the house alternative to
# an associative array.
#
# Case labels are "PASS: <case>" / "FAIL: <case>" to match the sibling suite
# test-wiki-namespace-sync.sh — the cogni-service mutation harness classifies a
# case GREEN only on that vocabulary. Case ids are C-prefixed and never bare
# numerals, so the final summary line is not read as a case result.
#
# stdlib-only: bash + coreutils + python3 (frontmatter parsing), no pip deps,
# no network.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

# ---------------------------------------------------------------------------
# The checker. Fixture cases and the real-tree case drive this same function —
# the extractor is never reimplemented in a case body, so pointing a case at a
# broken extractor turns that case red.
# ---------------------------------------------------------------------------

# emit_phrases <skills_dir> -> "<phrase>\t<skill-name>" per line, deduped within
# a skill. Reads ONLY the frontmatter description block.
emit_phrases() {
  python3 -c '
import os, re, sys

skills_dir = sys.argv[1]
try:
    entries = sorted(os.listdir(skills_dir))
except OSError:
    sys.exit(3)

found_any = False
for entry in entries:
    path = os.path.join(skills_dir, entry, "SKILL.md")
    if not os.path.isfile(path):
        continue
    found_any = True
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        continue
    fm = m.group(1)
    nm = re.search(r"^name:[ \t]*(\S+)", fm, re.M)
    name = nm.group(1) if nm else entry
    # description: through the next TOP-LEVEL key (column 0), or end of block.
    dm = re.search(r"^description:.*?(?=^[A-Za-z_][A-Za-z0-9_-]*:|\Z)", fm, re.M | re.S)
    if not dm:
        continue
    body = re.sub(r"^description:[ \t]*", "", dm.group(0), count=1)
    # Unwrap the YAML scalar BEFORE hunting for quoted phrases. On a
    # double-quoted scalar the outer quotes are syntax, not a trigger phrase —
    # leaving them in makes the whole description read as one giant phrase, so
    # that skill contributes nothing usable and its real phrases go unguarded.
    stripped = body.strip()
    if stripped[:1] in (">", "|"):
        stripped = stripped.split("\n", 1)[1] if "\n" in stripped else ""
    elif stripped[:1] == "\"" and stripped[-1:] == "\"":
        stripped = stripped[1:-1].replace("\\\"", "\"")
    elif stripped[:1] == chr(39) and stripped[-1:] == chr(39):
        stripped = stripped[1:-1].replace(chr(39) * 2, chr(39))
    seen = set()
    for phrase in re.findall(r"\"([^\"]+)\"", stripped):
        key = " ".join(phrase.split()).lower()
        if not key or key in seen:
            continue
        seen.add(key)
        print("%s\t%s" % (key, name))

if not found_any:
    sys.exit(4)
' "$1"
}

# scan_skills <skills_dir> -> 0 clean, 1 collision/unusable tree.
scan_skills() {
  local dir="$1"
  local raw="$TMPROOT/raw.$$" rc

  if [ ! -d "$dir" ]; then
    echo "ERROR skills directory not found: $dir"
    return 1
  fi

  emit_phrases "$dir" > "$raw" 2>/dev/null
  rc=$?
  if [ "$rc" -eq 4 ]; then
    # Liveness floor. Without it, a scan pointed at a directory holding no
    # SKILL.md reports clean, and a half-dead guard is indistinguishable from a
    # working one — the real tree is already clean, so nothing else would notice.
    echo "ERROR no SKILL.md files found under $dir"
    return 1
  elif [ "$rc" -ne 0 ]; then
    echo "ERROR could not read skills under $dir"
    return 1
  fi

  # A phrase collides when its distinct skill count exceeds 1. Sorting on the
  # phrase field and folding is the bash-3.2 stand-in for a dict of sets.
  local collisions=0 phrase owners
  while IFS= read -r phrase; do
    [ -n "$phrase" ] || continue
    owners="$(awk -F'\t' -v p="$phrase" '$1 == p { print $2 }' "$raw" | sort -u | tr '\n' ' ')"
    echo "COLLISION \"$phrase\" claimed by: $owners"
    collisions=$((collisions + 1))
  done <<EOF
$(cut -f1 "$raw" | sort | uniq -d)
EOF

  [ "$collisions" -eq 0 ] || return 1
  return 0
}

# ---------------------------------------------------------------------------
# Harness
# ---------------------------------------------------------------------------

RC=0
OUT=""
run_scan() { OUT="$(scan_skills "$1" 2>&1)"; RC=$?; }

assert_rc() {
  [ "$RC" -eq "$1" ] && return 0
  echo "     expected rc=$1, got rc=$RC; output:"
  echo "$OUT" | sed 's/^/       /'
  return 1
}
assert_out_has() {
  case "$OUT" in *"$1"*) return 0 ;; esac
  echo "     expected output to contain: $1"
  echo "$OUT" | sed 's/^/       /'
  return 1
}
assert_out_lacks() {
  case "$OUT" in *"$1"*) echo "     expected output NOT to contain: $1"; return 1 ;; esac
  return 0
}

# mk_skill <skills_dir> <name> <description-body> [body-text]
mk_skill() {
  local dir="$1/$2"
  mkdir -p "$dir"
  {
    printf -- '---\n'
    printf -- 'name: %s\n' "$2"
    printf -- 'description: >-\n'
    printf -- '  %s\n' "$3"
    printf -- 'allowed-tools: Read\n'
    printf -- '---\n\n'
    printf -- '# %s\n\n%s\n' "$2" "${4:-fixture body.}"
  } > "$dir/SKILL.md"
}

# ---------------------------------------------------------------------------
# C1 — the real cogni-workspace tree is clean (asserted here, not only in
# fixtures).
# ---------------------------------------------------------------------------
run_scan "$WS_ROOT/skills"
if assert_rc 0; then
  pass "C1 real cogni-workspace skills claim no duplicate trigger phrase"
else
  fail "C1 real cogni-workspace skills claim no duplicate trigger phrase"
fi

# ---------------------------------------------------------------------------
# C2 — the core case: one phrase, two skills. This is the mutation the issue
# names ("what does cogni-X do" added to a second skill).
# ---------------------------------------------------------------------------
F2="$TMPROOT/c2/skills"
mk_skill "$F2" ask 'Answer questions. Trigger on "what does cogni-X do" or "ask the wiki".'
mk_skill "$F2" cheatsheet 'Quick cards. Trigger on "what does cogni-X do" or "tldr cogni-X".'
run_scan "$F2"
if assert_rc 1 \
  && assert_out_has 'what does cogni-x do' \
  && assert_out_has 'ask' \
  && assert_out_has 'cheatsheet'; then
  pass "C2 one phrase claimed by two skills fails and names both"
else
  fail "C2 one phrase claimed by two skills fails and names both"
fi

# ---------------------------------------------------------------------------
# C3 — a phrase repeated INSIDE one description is not a collision. Without the
# per-skill dedupe this would false-fail, and every rewritten description that
# restates its own trigger would turn the guard red.
# ---------------------------------------------------------------------------
F3="$TMPROOT/c3/skills"
mk_skill "$F3" ask 'Trigger on "ask the wiki". Say "ask the wiki" to start. Also "ask insight-wave".'
mk_skill "$F3" other 'Unrelated. Trigger on "something else".'
run_scan "$F3"
if assert_rc 0; then
  pass "C3 a phrase repeated within one description is not a collision"
else
  fail "C3 a phrase repeated within one description is not a collision"
fi

# ---------------------------------------------------------------------------
# C4 — case and whitespace normalization. Two skills quoting the same phrase in
# different casing compete for the same invocation just as surely.
# ---------------------------------------------------------------------------
F4="$TMPROOT/c4/skills"
mk_skill "$F4" alpha 'Trigger on "Show Market Coverage".'
mk_skill "$F4" beta  'Trigger on "show market   coverage".'
run_scan "$F4"
if assert_rc 1 && assert_out_has 'show market coverage'; then
  pass "C4 collisions are detected across casing and internal whitespace"
else
  fail "C4 collisions are detected across casing and internal whitespace"
fi

# ---------------------------------------------------------------------------
# C5 — quoted strings in the BODY are ignored. Skill bodies quote examples
# constantly; counting them would make the guard unusable.
# ---------------------------------------------------------------------------
F5="$TMPROOT/c5/skills"
mk_skill "$F5" alpha 'Trigger on "alpha phrase".' 'Example: the user says "shared body quote" here.'
mk_skill "$F5" beta  'Trigger on "beta phrase".'  'Also documents "shared body quote" as an example.'
run_scan "$F5"
if assert_rc 0 && assert_out_lacks 'shared body quote'; then
  pass "C5 quoted strings in the skill body are not treated as trigger phrases"
else
  fail "C5 quoted strings in the skill body are not treated as trigger phrases"
fi

# ---------------------------------------------------------------------------
# C6 — the extractor stops at the next top-level frontmatter key. A phrase
# quoted in a later key must not be attributed to the description.
# ---------------------------------------------------------------------------
F6="$TMPROOT/c6/skills"
mkdir -p "$F6/alpha" "$F6/beta"
printf -- '---\nname: alpha\ndescription: >-\n  Trigger on "alpha only".\nargument-hint: pass "shared later key" here\n---\n\n# alpha\n' > "$F6/alpha/SKILL.md"
printf -- '---\nname: beta\ndescription: >-\n  Trigger on "beta only".\nargument-hint: pass "shared later key" here\n---\n\n# beta\n' > "$F6/beta/SKILL.md"
run_scan "$F6"
if assert_rc 0 && assert_out_lacks 'shared later key'; then
  pass "C6 the description block ends at the next top-level frontmatter key"
else
  fail "C6 the description block ends at the next top-level frontmatter key"
fi

# ---------------------------------------------------------------------------
# C7 — YAML scalar styles. All four in-tree styles must yield the same phrases.
# The double-quoted case is the trap: leave the outer quotes on and the entire
# description reads as one phrase, so that skill contributes nothing and its
# real triggers go unguarded — silently, because one giant unique string never
# collides with anything.
# ---------------------------------------------------------------------------
F7="$TMPROOT/c7-styles/skills"
mkdir -p "$F7/blockfold" "$F7/blockliteral" "$F7/dquoted" "$F7/squoted"
printf -- '---\nname: blockfold\ndescription: >-\n  Trigger on \"shared style phrase\".\n---\n\n# blockfold\n' > "$F7/blockfold/SKILL.md"
printf -- '---\nname: blockliteral\ndescription: |\n  Unrelated trigger \"literal only\".\n---\n\n# blockliteral\n' > "$F7/blockliteral/SKILL.md"
printf -- '---\nname: dquoted\ndescription: "Trigger on \\"shared style phrase\\" here."\n---\n\n# dquoted\n' > "$F7/dquoted/SKILL.md"
printf -- "---\nname: squoted\ndescription: 'Unrelated trigger \"squoted only\".'\n---\n\n# squoted\n" > "$F7/squoted/SKILL.md"
run_scan "$F7"
if assert_rc 1 \
  && assert_out_has 'shared style phrase' \
  && assert_out_has 'blockfold' \
  && assert_out_has 'dquoted' \
  && assert_out_lacks 'trigger on' \
  && assert_out_lacks 'unrelated trigger'; then
  pass "C7 phrases are found under every YAML scalar style, quotes unwrapped"
else
  fail "C7 phrases are found under every YAML scalar style, quotes unwrapped"
fi

# ---------------------------------------------------------------------------
# C8 — the liveness floor itself. Without this the floor is an unfalsifiable
# branch, and a scan silently pointed at nothing would report clean.
# ---------------------------------------------------------------------------
c8_ok=1
mkdir -p "$TMPROOT/c8/empty"
run_scan "$TMPROOT/c8/empty"
assert_rc 1 && assert_out_has "no SKILL.md files found" || c8_ok=0
run_scan "$TMPROOT/c8/does-not-exist"
assert_rc 1 && assert_out_has "skills directory not found" || c8_ok=0
if [ "$c8_ok" -eq 1 ]; then
  pass "C8 an empty or missing skills tree fails rather than reporting clean"
else
  fail "C8 an empty or missing skills tree fails rather than reporting clean"
fi

# ---------------------------------------------------------------------------
if [ "$failures" -gt 0 ]; then
  echo ""
  echo "FAIL: $failures skill-trigger-phrase test(s) failed."
  exit 1
fi
echo ""
echo "All skill-trigger-phrase tests passed."
