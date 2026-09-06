#!/usr/bin/env bash
#
# test-slide-grammar.sh — binds the schema-4.1 presentation-brief slide grammar
# to the three surfaces that carry live grammar samples:
#
#   cogni-workspace/libraries/EXAMPLE_BRIEF.md                          (13 slides)
#   cogni-workspace/skills/story-to-slides/references/07-output-template.md  (8)
#   cogni-workspace/skills/story-to-slides/references/08b-references-slide.md (1)
#
# Why this exists alongside test-check-brief.sh: check-brief.py already enforces
# no-color-fields and deck-references-last, and cb01 / cb04 / pb05 already run it
# against EXAMPLE_BRIEF.md. What nothing bound before this suite are the two
# TEMPLATE surfaces. Those are fragments, not briefs — no frontmatter,
# {placeholder} headlines, slide numbers written N / N+1 / N+2 — so the grammar
# they document could drift with nothing noticing. The parser rationale, the
# traps it is shaped around and the required-key table it grades live in
# fixtures/slide-grammar/slide_grammar.py; this file does not restate them.
#
# The parser sits under fixtures/ rather than beside this file because the
# runner's discovery glob is a non-recursive tests/*.sh — a helper at tests/
# level would be discovered and run as a second suite.
#
# Every case id has both a PASS and a FAIL arm, structurally: expect_green and
# expect_red each take the id once and own both arms, so the two can never
# drift apart. The sgNN-mutant-* cases corrupt a mktemp copy and assert the
# matching check goes red, so no assertion can rot into a tautology unnoticed.
# Mutants address their target through the parser's `locate` op rather than by
# absolute line number; no mutant is ever committed.
#
# ## Mutation recipe
#
# Harness: ~/GitHub/dev/managed-service/cogni-service/scripts/mutation-check.sh
# Run with:
#   --root . --file cogni-workspace/tests/fixtures/slide-grammar/slide_grammar.py
#   --test 'bash cogni-workspace/tests/test-slide-grammar.sh'
#
#   --expr 's{Slide\\s\+\(\\S\+\)}{Slide\\s+(\\d+)}'   --case sg03-heading-counts
#   --expr 's{in COLOUR_FIELDS}{in set()}'              --case sg15-mutant-bare-role-flagged
#   --expr 's{if not hits:}{if False:}'                 --case sg17-mutant-missing-role-fails-closed
#   --expr 's{if n != 1}{if False}'                     --case sg19-mutant-missing-required-subkey
#   --expr 's{"Mood"}{"Mood", "Bogus"}'                 --case sg18-colour-fields-match-check-brief
#
# Verdict at authoring: guard_verified for all five — each search text occurs
# exactly once in slide_grammar.py and each named case went red under its recipe,
# replayed against the literal harness path above exactly as written. The first
# is the load-bearing one: it reinstates the digits-only regex that is this
# suite's central failure mode.

set -u

# Keep CPython from dropping a __pycache__/ into the plugin tree —
# test-relocated-skill-hygiene.sh P2 flags it as an unresolvable
# ${CLAUDE_PLUGIN_ROOT} path.
export PYTHONDONTWRITEBYTECODE=1

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GRAM="$ROOT/cogni-workspace/tests/fixtures/slide-grammar/slide_grammar.py"

BRIEF="$ROOT/cogni-workspace/libraries/EXAMPLE_BRIEF.md"
TEMPLATE="$ROOT/cogni-workspace/skills/story-to-slides/references/07-output-template.md"
REFSLIDE="$ROOT/cogni-workspace/skills/story-to-slides/references/08b-references-slide.md"
CHECK_BRIEF="$ROOT/cogni-workspace/scripts/check-brief.py"

failures=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

# Run one check against the real corpus.
clean() { python3 "$GRAM" "$1" "brief=$BRIEF" "template=$TEMPLATE" "refslide=$REFSLIDE" >/dev/null 2>&1; }

# Run one check against a staged (mutated) copy. Roles are passed explicitly, so
# the deliberately different filenames here cannot make a check self-skip.
mutant() { python3 "$GRAM" "$2" "brief=$1/brief.md" "template=$1/template.md" "refslide=$1/refslide.md" >/dev/null 2>&1; }

# expect_green <case-id> <check> <failure-sentence>
expect_green() { if clean "$2"; then pass "$1"; else fail "$1 $3"; fi; }

# expect_red <case-id> <staged-dir> <check> <failure-sentence>
expect_red() { if mutant "$2" "$3"; then fail "$1 $4"; else pass "$1"; fi; }

# Stage a fresh copy of all three surfaces and echo the directory. All three are
# copied even when one is mutated, so `mutant` can always pass every role.
stage() {
  local d="$TMPROOT/$1"
  mkdir -p "$d"
  cp "$BRIEF" "$d/brief.md"
  cp "$TEMPLATE" "$d/template.md"
  cp "$REFSLIDE" "$d/refslide.md"
  printf '%s\n' "$d"
}

# mutate <staged-dir> <role> <selector> <del|set|ins> [text]
# The selector is resolved by the parser, so a corpus edit above the target
# cannot silently re-aim the mutation at a neighbouring line.
mutate() {
  local d="$1" role="$2" sel="$3" op="$4" txt="${5-}" doc idx
  case "$role" in
    brief) doc="brief.md" ;;
    template) doc="template.md" ;;
    refslide) doc="refslide.md" ;;
    *) printf 'unknown role %s\n' "$role" >&2; return 1 ;;
  esac
  idx="$(python3 "$GRAM" locate "$role=$d/$doc" "$sel")" || return 1
  python3 - "$d/$doc" "$idx" "$op" "$txt" <<'PY'
import sys
path, idx, op, txt = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
lines = open(path, encoding="utf-8").read().split("\n")
if op == "del":
    del lines[idx]
elif op == "set":
    lines[idx] = txt
elif op == "ins":
    lines.insert(idx, txt)
else:
    raise SystemExit("unknown op %r" % op)
open(path, "w", encoding="utf-8").write("\n".join(lines))
PY
}

# ---------------------------------------------------------------- clean corpus

expect_green sg01-fences-balanced fences-balanced \
  "a bound surface has an unbalanced fence at EOF"
expect_green sg02-one-yaml-fence-per-slide one-yaml-fence-per-slide \
  "a slide heading is not followed by exactly one yaml fence"
expect_green sg03-heading-counts heading-counts \
  "a surface graded a different number of slides than 13/8/1, or disagreed with its own loose recount"
expect_green sg04-slide-kind-single slide-kind-single \
  "a slide carries zero or multiple Slide-Kind keys"
expect_green sg05-slide-kind-enum slide-kind-enum \
  "a Slide-Kind value is outside content/internal-prep/references"
expect_green sg06-references-slide-last references-slide-last \
  "the references slide is not the last slide of EXAMPLE_BRIEF.md"
expect_green sg07-no-colour-fields no-colour-fields \
  "a top-level colour field appears inside a slide yaml block"
expect_green sg08-required-41-subkeys required-4.1-subkeys \
  "a slide is missing its nested intent.role or visual.kind key"
expect_green sg09-non-numeric-slide-labels-graded non-numeric-slide-labels-graded \
  "the N / N+1 / N+2 headings were not graded"

# --------------------------------------------------------------------- mutants

d="$(stage m10)"; mutate "$d" brief fence-close:1 del
expect_red sg10-mutant-unbalanced-fence "$d" fences-balanced \
  "a dropped closing fence was not reported"

d="$(stage m11)"; mutate "$d" brief fence-open:1 set '```yml'
expect_red sg11-mutant-fence-retagged "$d" one-yaml-fence-per-slide \
  "a slide fence tagged yml instead of yaml was not reported"

d="$(stage m12)"; mutate "$d" brief kind-line:1 ins 'Slide-Kind: content'
expect_red sg12-mutant-duplicate-slide-kind "$d" slide-kind-single \
  "a second Slide-Kind key was not reported"

d="$(stage m13)"; mutate "$d" brief kind-line:1 set 'Slide-Kind: bogus'
expect_red sg13-mutant-slide-kind-out-of-enum "$d" slide-kind-enum \
  "an out-of-enum Slide-Kind value was not reported"

d="$(stage m14)"; mutate "$d" brief kind-line:last set 'Slide-Kind: content'
expect_red sg14-mutant-references-not-last "$d" references-slide-last \
  "a demoted references slide was not reported"

# The prohibitive half of the intent.role carve-out. sg07 proves the scan stays
# quiet on the prose mentions; this proves it still fires on a real bare key.
d="$(stage m15)"; mutate "$d" brief body-top:1 ins 'Role: emphasis'
expect_red sg15-mutant-bare-role-flagged "$d" no-colour-fields \
  "an injected top-level Role: key was not reported"

# The central regression: if the heading matcher ever narrows to (\d+), the three
# non-numeric labels leave the parsed set.
d="$(stage m16)"
python3 - "$d/template.md" <<'PY'
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = (text.replace("## Slide N: ", "## Slide 90: ")
            .replace("## Slide N+1: ", "## Slide 91: ")
            .replace("## Slide N+2: ", "## Slide 92: "))
open(path, "w", encoding="utf-8").write(text)
PY
expect_red sg16-mutant-non-numeric-labels-removed "$d" non-numeric-slide-labels-graded \
  "renumbering N/N+1/N+2 away was not reported"

# A role-scoped check handed no document for its role must go red rather than
# report green having graded nothing — the silent-skip failure this suite exists
# to prevent, applied to the suite's own plumbing.
if python3 "$GRAM" references-slide-last "template=$TEMPLATE" >/dev/null 2>&1; then
  fail "sg17-mutant-missing-role-fails-closed a check with no document for its role reported green"
else
  pass "sg17-mutant-missing-role-fails-closed"
fi

# The forbidden set is copied here rather than imported, to keep the fixture
# standalone. check-brief.py owns the live prohibition list and has already
# grown it twice, so a silently stale copy would narrow sg07 without any case
# going red — this is what makes the divergence visible instead.
if python3 - "$GRAM" "$CHECK_BRIEF" <<'PY'
import importlib.util, json, subprocess, sys
gram, check_brief = sys.argv[1], sys.argv[2]
spec = importlib.util.spec_from_file_location("check_brief", check_brief)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
ours = set(json.loads(subprocess.run([sys.executable, gram, "dump-colour-fields"],
                                     capture_output=True, text=True, check=True).stdout))
sys.exit(0 if ours == set(mod.COLOR_KEYS_SLIDES) else 1)
PY
then
  pass "sg18-colour-fields-match-check-brief"
else
  fail "sg18-colour-fields-match-check-brief the forbidden colour set has diverged from check-brief.py COLOR_KEYS_SLIDES"
fi

d="$(stage m19)"; mutate "$d" brief subkey:intent/1 del
expect_red sg19-mutant-missing-required-subkey "$d" required-4.1-subkeys \
  "a slide stripped of its nested intent.role key was not reported"

exit "$failures"
