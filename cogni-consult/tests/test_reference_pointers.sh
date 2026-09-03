#!/usr/bin/env bash
# Guard: every absolute reference pointer in cogni-consult resolves, the extracted
# rendering contracts stay extracted, and neither can be silently re-inlined.
#
# Label vocabulary is the shape every suite in this directory now carries. The
# shared mutation harness classifies a case by matching `FAIL: <case>` (red) and
# `ok: <case>` / `PASS: <case>` (green), each requiring whitespace or end-of-line
# immediately after the case token. So a case id is a single whitespace-free
# token and any detail is separated with " - ", never a glued colon: `PASS:
# goes-red: ...` would match neither pattern, and a recipe recorded against this
# suite would return case_not_found instead of a verdict.
#
# Scope note: the pointer scan keys ONLY on the absolute
# `$CLAUDE_PLUGIN_ROOT/references/...` form. A bare-relative `references/...`
# mention predates this guard elsewhere in the plugin; keying on those would make
# this suite red for reasons unrelated to whether a pointer resolves.
#
# Case 1 resolves the FILE a pointer names; case 6 resolves the SECTION LETTER a
# citation names inside it. They are separate defect classes - a file can resolve
# while the section it is cited for has moved to another plugin - and case 1
# cannot see the second by construction.

set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
NESTED=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) PLUGIN_DIR="$2"; NESTED=1; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s - %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

LIST_REF="references/engagement-list-rendering.md"
DASH_REF="references/engagement-dashboard-rendering.md"
RESUME_SKILL="skills/consult-resume/SKILL.md"

# --- case 1: pointers-resolve ------------------------------------------------
# Every absolute pointer resolves. A token ending in "/" is a directory target.
pointer_tokens() {
  grep -rho --include='*.md' --include='*.sh' --include='*.json' \
    '\$CLAUDE_PLUGIN_ROOT/references/[A-Za-z0-9._/-]*' \
    "$PLUGIN_DIR/skills" "$PLUGIN_DIR/agents" "$PLUGIN_DIR/references" \
    "$PLUGIN_DIR/hooks" "$PLUGIN_DIR/output-styles" 2>/dev/null \
    | sed 's/[.,;:)]*$//' | sort -u
}

tokens="$(pointer_tokens)"
if [ -z "$tokens" ]; then
  # A vacuous scan must never read as success — it would make this case pass by
  # finding nothing to check.
  fail "pointers-resolve" "no absolute reference pointers found under $PLUGIN_DIR (vacuous scan)"
else
  dangling=""
  while IFS= read -r tok; do
    rest="${tok#\$CLAUDE_PLUGIN_ROOT/}"
    [ -e "$PLUGIN_DIR/$rest" ] || dangling="$dangling $rest"
  done <<< "$tokens"
  if [ -n "$dangling" ]; then
    fail "pointers-resolve" "dangling:$dangling"
  else
    pass "pointers-resolve"
  fi
fi

# --- case 2: pointers-absolute ----------------------------------------------
# In the extracted contracts and in the skill body they were extracted from,
# every references/ mention uses the absolute form — so the relocation cannot
# erode back toward relative paths in the files it actually touched.
before=$failures
for rel in "$LIST_REF" "$DASH_REF" "$RESUME_SKILL"; do
  f="$PLUGIN_DIR/$rel"
  if [ ! -f "$f" ]; then
    fail "pointers-absolute" "missing $rel"
    continue
  fi
  all="$(grep -o 'references/' "$f" 2>/dev/null | wc -l)"
  abs="$(grep -o 'CLAUDE_PLUGIN_ROOT/references/' "$f" 2>/dev/null | wc -l)"
  [ "$all" -ne "$abs" ] &&
    fail "pointers-absolute" "$rel has $all references/ mentions but only $abs absolute"
done
[ "$failures" -eq "$before" ] && pass "pointers-absolute"

# --- case 3: reference-anchored ---------------------------------------------
# An extracted contract nobody points at is orphaned prose. Scoped to skill
# bodies on purpose: a reference cited only by another reference is still orphaned
# from the default path.
before=$failures
for rel in "$LIST_REF" "$DASH_REF"; do
  grep -rq "\$CLAUDE_PLUGIN_ROOT/$rel" "$PLUGIN_DIR/skills" 2>/dev/null ||
    fail "reference-anchored" "$rel is not pointed at by any skill body"
done
[ "$failures" -eq "$before" ] && pass "reference-anchored"

# --- case 4: contract-relocated ---------------------------------------------
# The rendering contracts must live in the references, not back in the skill
# body. The subject is derived, not sampled: every non-empty line of every fenced
# example in the two references must be absent from the skill body, so
# re-inlining any part of either rendered table fails CI.
fenced_lines() { awk '/^```/ { inf = !inf; next } inf && NF' "$1"; }

before=$failures
for rel in "$LIST_REF" "$DASH_REF"; do
  [ -f "$PLUGIN_DIR/$rel" ] || continue
  while IFS= read -r line; do
    grep -qF -- "$line" "$PLUGIN_DIR/$RESUME_SKILL" 2>/dev/null &&
      fail "contract-relocated" "rendered example line re-inlined into $RESUME_SKILL: $line"
  done <<< "$(fenced_lines "$PLUGIN_DIR/$rel")"
done
# Explicit presence half, which the derived check above cannot make: grep -F pins
# the umlauts, so an ASCII-folded copy of a relocated rule fails to match.
for tok in 'Weitere' 'TT.MM.JJJJ' 'Nächstes Deliverable' 'Schlüsselfrage:' 'Fortschritt'; do
  grep -qF -- "$tok" "$PLUGIN_DIR/$LIST_REF" "$PLUGIN_DIR/$DASH_REF" 2>/dev/null ||
    fail "contract-relocated" "token absent from both reference files: $tok"
done
[ "$failures" -eq "$before" ] && pass "contract-relocated"

# --- case 6: sections-resolve -----------------------------------------------
# A pointer can resolve as a FILE and still name a section that is not in it.
# That is its own defect class and the one the register split introduced: the
# table contract and the announcement budgets moved to cogni-workspace, so every
# citation naming them by letter against a cogni-consult path went dangling
# while case 1 stayed green, because case 1 tests `[ -e <file> ]` and nothing
# about the letter. This case resolves the letter too.
#
# Three citation shapes are recognized, all of them in use here:
#   A  `$CLAUDE_PLUGIN_ROOT/references/<f>` (x)   path then letter
#   B  section (x) of `$CLAUDE_PLUGIN_ROOT/references/<f>`   letter then path
#   C  canonical (x)                              letter, canonical file
# An anaphoric citation ("(e) of that same register") names no target and is
# deliberately out of scope: it has no path to resolve against, and inventing
# one from the previous sentence is guesswork.
#
# The letter class is [a-z], not [a-h]: a citation to a letter no register has
# is exactly the typo this case exists to catch, so the pattern must be able to
# match one.
#
# Shape C is checked only in a non-nested run. It resolves against the sibling
# plugin, which the --root fixtures do not carry, so a nested run would redden
# for a missing basis rather than a missing section.
CANONICAL_REL="../cogni-workspace/references/user-facing-output.md"
CANONICAL="$PLUGIN_DIR/$CANONICAL_REL"

section_report() {
  PLUGIN_DIR="$PLUGIN_DIR" CANONICAL="$1" SCOPE_C="$2" python3 - <<'PY'
import os, re, sys

plugin = os.environ["PLUGIN_DIR"]
canonical = os.environ["CANONICAL"]
scope_c = os.environ["SCOPE_C"] == "1"

PATH_RE = r"\$CLAUDE_PLUGIN_ROOT/references/([A-Za-z0-9._/-]+?)\.md"
# The gap in SHAPE_B is load-bearing, not permissiveness for its own sake: the
# citations this class first appeared in read "section (d) of the register
# headed by `<path>`", so a form requiring the path immediately after "of"
# matches none of them and the guard ships green over the very defect it was
# written for. The gap therefore admits a short intervening clause, bounded so
# it cannot wander into an unrelated later path: no backtick, no sentence
# period, at most one newline.
GAP = r"(?:[^`.\n]{0,60}(?:\n[^`.\n]{0,60})?)?"
SHAPE_A = re.compile(r"`" + PATH_RE + r"`\s*\(([a-z])\)")
SHAPE_B = re.compile(r"section\s+\(([a-z])\)\s+of\s+" + GAP + r"`" + PATH_RE + r"`")
SHAPE_C = re.compile(r"canonical\s+\(([a-z])\)")
# A section cited by TITLE rather than by letter. The table contract is the most
# cited section by name in this plugin and the one the split moved, so the
# title lookup is derived from the canonical file's own headings rather than hardcoded.
SHAPE_D = re.compile(r"table contract in\s+" + GAP + r"`" + PATH_RE + r"`")

def headings(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return set(re.findall(r"(?m)^##\s+\(([a-z])\)", fh.read()))
    except OSError:
        return None

cache = {}
def has(path, letter):
    if path not in cache:
        cache[path] = headings(path)
    hs = cache[path]
    return None if hs is None else letter in hs

found = 0
bad = []
for root, dirs, files in os.walk(plugin):
    dirs[:] = [d for d in dirs if not d.startswith(".") and d != "tests"]
    for fn in files:
        if not fn.endswith(".md"):
            continue
        fp = os.path.join(root, fn)
        rel = os.path.relpath(fp, plugin)
        text = open(fp, encoding="utf-8").read()
        for m in SHAPE_A.finditer(text):
            found += 1
            target = os.path.join(plugin, "references", m.group(1) + ".md")
            if has(target, m.group(2)) is not True:
                bad.append("%s cites (%s) of %s.md" % (rel, m.group(2), m.group(1)))
        for m in SHAPE_B.finditer(text):
            found += 1
            target = os.path.join(plugin, "references", m.group(2) + ".md")
            if has(target, m.group(1)) is not True:
                bad.append("%s cites (%s) of %s.md" % (rel, m.group(1), m.group(2)))
        for m in SHAPE_D.finditer(text):
            found += 1
            target = os.path.join(plugin, "references", m.group(1) + ".md")
            if has(target, "d") is not True:
                bad.append("%s cites the table contract in %s.md, which has no (d)"
                           % (rel, m.group(1)))
        if scope_c:
            for m in SHAPE_C.finditer(text):
                found += 1
                if has(canonical, m.group(1)) is not True:
                    bad.append("%s cites canonical (%s)" % (rel, m.group(1)))

sys.stdout.write("count=%d\n" % found)
for b in sorted(set(bad)):
    sys.stdout.write("unresolved: %s\n" % b)
PY
}

if [ "$NESTED" -eq 0 ] && [ ! -f "$CANONICAL" ]; then
  # The canonical file is the basis for shape C. Absent, this case cannot make
  # its main assertion, and passing would be vacuous.
  fail "sections-resolve" "canonical register not found at $CANONICAL_REL (missing basis)"
else
  if [ "$NESTED" -eq 0 ]; then scope_c=1; else scope_c=0; fi
  report="$(section_report "$CANONICAL" "$scope_c")"
  cited="$(printf '%s\n' "$report" | sed -n 's/^count=//p')"
  unresolved="$(printf '%s\n' "$report" | sed -n 's/^unresolved: //p')"
  if [ -z "$cited" ] || [ "$cited" -eq 0 ]; then
    fail "sections-resolve" "no section citations found under $PLUGIN_DIR (vacuous scan)"
  elif [ -n "$unresolved" ]; then
    fail "sections-resolve" "$(printf '%s' "$unresolved" | tr '\n' ';')"
  else
    pass "sections-resolve - $cited section citations resolve"
  fi
fi

# --- case 5: goes-red -------------------------------------------------------
# Skipped under --root so the nested fixture runs cannot recurse.
if [ "$NESTED" -eq 0 ]; then
  TMPROOT="$(mktemp -d)"
  trap 'rm -rf "$TMPROOT"' EXIT

  build_fixture() {
    mkdir -p "$1"
    for d in skills agents references hooks output-styles; do
      [ -d "$PLUGIN_DIR/$d" ] && cp -R "$PLUGIN_DIR/$d" "$1/"
    done
  }

  # Each fixture gets its own tree named for the case it proves, so a botched
  # mutation cannot leak into the next case and turn it red for the wrong reason.
  expect_red() {
    case_id="$1"; shift
    fixture="$TMPROOT/$case_id"
    build_fixture "$fixture"
    "$@" "$fixture"
    if bash "$0" --root "$fixture" >/dev/null 2>&1; then
      fail "$case_id" "the mutated fixture did not fail the guard"
    else
      pass "$case_id"
    fi
  }

  mutate_dangle() {
    f="$1/$RESUME_SKILL"
    sed 's|references/engagement-list-rendering\.md|references/no-such-reference.md|g' \
      "$f" > "$f.new" && mv "$f.new" "$f"
  }

  mutate_reinline() {
    printf '\nWeitere 6 — sag „alle“ für die vollständige Liste.\n' >> "$1/$RESUME_SKILL"
  }

  # A citation whose FILE resolves but whose SECTION does not. Case 1 is blind
  # to this by construction, so it proves case 6 discriminates rather than
  # riding along on case 1's verdict.
  mutate_bad_section() {
    f="$1/$DASH_REF"
    sed 's|/user-facing-output\.md` (c)|/user-facing-output.md` (z)|g' \
      "$f" > "$f.new" && mv "$f.new" "$f"
  }

  expect_red goes-red mutate_dangle
  expect_red goes-red-reinline mutate_reinline
  expect_red goes-red-section mutate_bad_section
fi

if [ "$failures" -gt 0 ]; then
  echo "$failures assertion(s) failed" >&2
  exit 1
fi
echo "All reference-pointer assertions passed"
