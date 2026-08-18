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
#   8  goes-red-drifted / goes-red-thinned
#                        a mutated block and a thinned block each fail the guard
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

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      PLUGIN_DIR="$2"
      # A nested run grades a fixture tree, so it must not build its own.
      NESTED=1
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
fi

if [ "$failures" -gt 0 ]; then
  echo "$failures assertion(s) failed" >&2
  exit 1
fi
echo "All step0-register-block assertions passed"
