#!/usr/bin/env bash
# Structural guard for the Step 0 register block duplicated across every
# consult-* skill.
#
# The block is mandated in all nine SKILL.md files, so it cannot be deduplicated
# away — the constraints stay inline where the model always reads them, and
# references/user-facing-output.md (f) owns them so a maintainer has one place
# to edit. That arrangement is only safe if the copies provably still match:
# byte-identity turns a silent nine-way drift into a failing test, and a
# presence check turns a silently thinned copy into one too.
#
# Assertions run against the shipped tree by default. `--root <dir>` points them
# at a different plugin directory, which is what lets the negative fixture prove
# the guard actually goes red.
#
# Coverage:
#   1  glob-count        skills/consult-*/SKILL.md resolves to exactly 9 files
#   2  anchor-once-<skill>-description / anchor-once-<skill>-register
#                        each carries exactly one description- and one
#                        register-paragraph anchor line (18 lines, 9 skills)
#   3  description-same-<skill>
#                        the description paragraph is byte-identical in all 9
#   4  register-same-<skill>
#                        the register paragraph is byte-identical in all 9
#   5  ladder-same-<skill>
#                        the ladder paragraph is byte-identical in all 9
#   6  specifics-inline-<n>  (1..5)
#                        every specific (f) owns is still stated in all 9
#   7  owner-present-<n>  (1..3)
#                        user-facing-output.md carries (f), the 6-word cap and
#                        the worked pair
#   7b canonical-basis / canonical-constraints
#                        the canonical (f) list in cogni-workspace and this
#                        plugin's overlay carry the same constraints, audience
#                        noun folded (sibling checkout only)
#   8  goes-red-drifted / goes-red-thinned / goes-red-canonical
#                        a mutated block, a thinned block and a canonical-side
#                        edit each fail the guard
#
# The emitted first token is the addressable id: each case emits the id shown
# above — with its per-skill or per-index suffix substituted — as the first
# token of its result line, so --case names one line and never a sibling.
#
# Usage: bash cogni-consult/tests/test_step0_register_block.sh [--root <dir>]
# Exits non-zero on any assertion failure.

# `set -u` only — `set -e` would abort on the first failing assertion.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
NESTED=0
CANONICAL_ARG=""
CANONICAL_OVERRIDE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      PLUGIN_DIR="$2"
      # A nested run grades a fixture tree, so it must not build its own.
      NESTED=1
      shift 2
      ;;
    --canonical)
      # Point the 7b comparison at a specific canonical file. This is what lets
      # goes-red-canonical prove that arm discriminates: a nested run normally
      # skips 7b for want of a sibling, so without an override the arm could
      # only ever be observed green.
      CANONICAL_ARG="$2"
      CANONICAL_OVERRIDE=1
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

OWNER="$PLUGIN_DIR/references/user-facing-output.md"

DESCRIPTION_ANCHOR='^The `description` of a Bash tool call'
REGISTER_ANCHOR='^The register that output follows'
LADDER_ANCHOR='^Before any user-facing output, resolve the'

# Each string is a specific (f) owns and the block states inline. `at most 6`
# rather than `6 words` on purpose: the prose wraps as "at most 6\nwords", so a
# `6 words` search would match zero times and pass vacuously. (f) keeps
# `6 words` unbroken on one line for assertion 7.
SPECIFICS='at most 6
no script, file, or skill names
never derived from the
Discover cogni-consult engagements
Laufende Engagements holen'

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s - %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

# Extract the paragraph starting at the line matching $2, from file $1.
# A paragraph ends at the first blank line, which is what makes the comparison
# whitespace-exact rather than a fuzzy grep.
paragraph() {
  awk -v pat="$2" '$0 ~ pat {f = 1} f {if ($0 == "") exit; print}' "$1"
}

# --- 1  glob-count ---------------------------------------------------------

skills=()
for f in "$PLUGIN_DIR"/skills/consult-*/SKILL.md; do
  [ -f "$f" ] && skills+=("$f")
done

if [ "${#skills[@]}" -eq 9 ]; then
  pass "glob-count - 9 consult-* SKILL.md found"
else
  fail "glob-count" "expected 9 consult-*/SKILL.md, found ${#skills[@]}"
fi

if [ "${#skills[@]}" -eq 0 ]; then
  echo "$failures assertion(s) failed" >&2
  exit 1
fi

# --- 2  anchor-once --------------------------------------------------------

for f in "${skills[@]}"; do
  name="$(basename "$(dirname "$f")")"
  for pair in "description:$DESCRIPTION_ANCHOR" "register:$REGISTER_ANCHOR"; do
    label="${pair%%:*}"
    anchor="${pair#*:}"
    n="$(grep -c "$anchor" "$f")"
    if [ "$n" -eq 1 ]; then
      pass "anchor-once-$name-$label - exactly one anchor"
    else
      fail "anchor-once-$name-$label" "$n anchors, expected 1"
    fi
  done
done

# --- 3 description-same / 4 register-same / 5 ladder-same ------------------

check_identical() {
  label="$1"
  anchor="$2"
  reference=""
  reference_name=""
  for f in "${skills[@]}"; do
    name="$(basename "$(dirname "$f")")"
    block="$(paragraph "$f" "$anchor")"
    if [ -z "$block" ]; then
      fail "$label-$name" "no paragraph matching $anchor"
      continue
    fi
    if [ -z "$reference" ]; then
      reference="$block"
      reference_name="$name"
      continue
    fi
    if [ "$block" = "$reference" ]; then
      pass "$label-$name - matches $reference_name"
    else
      fail "$label-$name" "diverges from $reference_name"
    fi
  done
}

check_identical "description-same" "$DESCRIPTION_ANCHOR"
check_identical "register-same" "$REGISTER_ANCHOR"
check_identical "ladder-same" "$LADDER_ANCHOR"

# --- 6  specifics-inline ---------------------------------------------------

# Byte-identity alone cannot catch a specific dropped from all nine at once.
# This asserts each one is still there, so thinning the block in favour of the
# reference fails rather than passing quietly.
# The case id is positional: adding, removing or reordering a SPECIFICS entry
# renumbers every case after it, and nothing goes red to announce that.
i=0
while IFS= read -r needle; do
  i=$((i + 1))
  missing=""
  for f in "${skills[@]}"; do
    grep -qF "$needle" "$f" || missing="$missing $(basename "$(dirname "$f")")"
  done
  if [ -z "$missing" ]; then
    pass "specifics-inline-$i - '$needle' present in all 9"
  else
    fail "specifics-inline-$i" "'$needle' missing from:$missing"
  fi
done <<EOF
$SPECIFICS
EOF

# --- 7  owner-present ------------------------------------------------------

if [ ! -f "$OWNER" ]; then
  fail "owner-present-file" "user-facing-output.md not found at $OWNER"
else
  pass "owner-present-file" "user-facing-output.md present at $OWNER"
  # Positional id, as above — reordering these needles renumbers the cases.
  j=0
  for needle in '## (f) Tool-call descriptions' '6 words' 'Discover cogni-consult engagements'; do
    j=$((j + 1))
    if grep -qF "$needle" "$OWNER"; then
      pass "owner-present-$j - '$needle'"
    else
      fail "owner-present-$j" "'$needle' missing from user-facing-output.md"
    fi
  done
fi

# --- 7b  canonical ---------------------------------------------------------

# The five (f) constraints live in three tiers once the register is split:
# the canonical file in cogni-workspace, this plugin's overlay, and the nine
# Step 0 blocks. Assertion 7 pins the overlay and assertions 3-6 pin the nine,
# so without this arm the tier the overlay itself names as edit-first is the one
# tier no assertion reads - a canonical edit would leave eleven downstream
# copies stale with CI green.
#
# The comparison NORMALIZES rather than demanding byte-equality, deliberately.
# Canonical (f) is written for any plugin and says "user"; this plugin's copies
# say "consultant". That difference is correct, so an equality arm would redden a
# tree that is behaving properly and force either churn or an exemption - the
# same trap a keywords-equality arm would be elsewhere in this repo. What must
# match is the substance: the same count of constraints, in the same order, with
# the audience noun folded.
#
# Basis: the canonical file is reached as a monorepo sibling. That resolves in a
# checkout and in CI but not in an installed plugin, and the --root fixtures do
# not carry it either - so a nested run skips this arm rather than reddening for
# a missing basis, and a non-nested run with no sibling fails as un-based rather
# than passing vacuously.
CANONICAL_REL="../cogni-workspace/references/user-facing-output.md"
if [ "$CANONICAL_OVERRIDE" -eq 1 ]; then
  CANONICAL="$CANONICAL_ARG"
else
  CANONICAL="$PLUGIN_DIR/$CANONICAL_REL"
fi

# Emit the numbered constraint list under "## (f)", one per line, audience noun
# folded and whitespace collapsed so a rewrap is not a diff.
fold_constraints() {
  SRC="$1" python3 - <<'PY'
import os, re, sys
text = open(os.environ["SRC"], encoding="utf-8").read()
m = re.search(r"(?m)^##\s+\(f\)[^\n]*\n(.*?)(?=^##\s|\Z)", text, re.S)
if not m:
    sys.exit(3)
body = m.group(1)
items = re.findall(r"(?m)^\d+\.\s+(.*?)(?=^\d+\.\s|\n\n|\Z)", body, re.S)
for it in items:
    one = " ".join(it.split())
    one = one.replace("consultant", "user")
    sys.stdout.write(one + "\n")
PY
}

if [ "$NESTED" -eq 1 ] && [ "$CANONICAL_OVERRIDE" -eq 0 ]; then
  pass "canonical-basis - nested run, sibling basis not expected"
  pass "canonical-constraints - nested run, comparison skipped"
elif [ ! -f "$CANONICAL" ]; then
  fail "canonical-basis" "canonical register not found at $CANONICAL_REL"
  fail "canonical-constraints" "no basis to compare against"
else
  pass "canonical-basis - canonical register found at $CANONICAL_REL"
  own="$(fold_constraints "$OWNER")"
  can="$(fold_constraints "$CANONICAL")"
  if [ -z "$own" ] || [ -z "$can" ]; then
    fail "canonical-constraints" "could not extract the (f) constraint list from one side"
  elif [ "$own" = "$can" ]; then
    n="$(printf '%s\n' "$own" | wc -l | tr -d ' ')"
    pass "canonical-constraints - $n constraints match the canonical file"
  else
    fail "canonical-constraints" "overlay (f) diverges from canonical (f)"
  fi
fi

# --- 8  goes-red -----------------------------------------------------------

# A guard only ever seen green proves nothing about its ability to catch drift.
# Build a throwaway copy of the plugin, break it in each of the two ways this
# guard exists to catch, and require a non-zero exit from each.
if [ "$NESTED" -eq 0 ]; then
  TMPROOT="$(mktemp -d)"
  trap 'rm -rf "$TMPROOT"' EXIT

  fixture() {
    dest="$TMPROOT/$1"
    mkdir -p "$dest/skills" "$dest/references"
    cp -R "$PLUGIN_DIR"/skills/consult-* "$dest/skills/"
    cp "$OWNER" "$dest/references/"
    printf '%s' "$dest"
  }

  # 8a — one register paragraph drifts by a single word.
  drifted="$(fixture drifted)"
  victim="$drifted/skills/consult-setup/SKILL.md"
  sed 's/not an exemption\./not an exception./' "$victim" > "$victim.new" \
    && mv "$victim.new" "$victim"
  if grep -q 'not an exception\.' "$victim"; then
    if bash "$0" --root "$drifted" >/dev/null 2>&1; then
      fail "goes-red-drifted" "a drifted register paragraph did not fail the guard"
    else
      pass "goes-red-drifted - a drifted register paragraph fails the guard"
    fi
  else
    fail "goes-red-drifted" "could not build the drifted fixture"
  fi

  # 8b — a pinned specific is thinned out of every copy.
  thinned="$(fixture thinned)"
  for f in "$thinned"/skills/consult-*/SKILL.md; do
    sed 's/, at most 6$//' "$f" > "$f.new" && mv "$f.new" "$f"
  done
  if ! grep -q 'at most 6' "$thinned/skills/consult-setup/SKILL.md"; then
    if bash "$0" --root "$thinned" >/dev/null 2>&1; then
      fail "goes-red-thinned" "a thinned specific did not fail the guard"
    else
      pass "goes-red-thinned - a thinned specific fails the guard"
    fi
  else
    fail "goes-red-thinned" "could not build the thinned fixture"
  fi

  # 8c - a canonical-side edit nobody mirrored. The real canonical file is never
  # mutated: a copy is, and it reaches the nested run through --canonical while
  # the plugin tree graded alongside it is the real one, so the canonical copy is
  # the only difference from the green run. Skipped when this run was itself
  # given an override, which would make the mutation compare against a mutation.
  if [ "$CANONICAL_OVERRIDE" -eq 1 ]; then
    pass "goes-red-canonical - override run, self-comparison skipped"
  elif [ ! -f "$PLUGIN_DIR/$CANONICAL_REL" ]; then
    fail "goes-red-canonical" "canonical register absent, cannot prove the arm"
  else
    mutcan="$TMPROOT/canonical-mutated.md"
    sed 's/At most 6 words/At most 8 words/' \
      "$PLUGIN_DIR/$CANONICAL_REL" > "$mutcan"
    if ! cmp -s "$mutcan" "$PLUGIN_DIR/$CANONICAL_REL"; then
      if bash "$0" --root "$PLUGIN_DIR" --canonical "$mutcan" >/dev/null 2>&1; then
        fail "goes-red-canonical" "a canonical-side edit did not fail the guard"
      else
        pass "goes-red-canonical - a canonical-side edit fails the guard"
      fi
    else
      fail "goes-red-canonical" "could not build the mutated canonical fixture"
    fi
  fi
fi

if [ "$failures" -gt 0 ]; then
  echo "$failures assertion(s) failed" >&2
  exit 1
fi
echo "All step0-register-block assertions passed"
