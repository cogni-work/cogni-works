#!/usr/bin/env bash
# Layering-claim guard: no surface may reassert that cogni-workspace is the
# foundation layer every other plugin depends on.
#
# Why this exists. references/absorption-roadmap.md Decision 1 replaced the
# LAYERING claim (cogni-workspace is the layer everything depends on) with a
# SCOPE claim (it is the horizontal layer; each vertical business plugin keeps
# its own project lifecycle). The claim was asserted in 19 places across docs/,
# both wiki trees, a since-retired plugin and cogni-workspace, and reconciling
# them by hand is only durable if something notices when one comes back. Nothing
# did:
# test-wiki-namespace-sync.sh checks filename stems against the marketplace
# roster and never reads page prose, and no suite anywhere compares the two wiki
# trees against each other. A regenerated doc or a re-imported wiki page could
# reintroduce the claim silently.
#
# Contract under test:
#   - none of the FORBIDDEN literals appears anywhere outside the excluded paths
#   - every one of those literals is actually caught when present (no dead config)
#   - a literal under an excluded path is NOT flagged
#   - the eight pages this reconciliation touched are byte-identical across the
#     two wiki trees
#   - a scan pointed at a missing or empty tree fails rather than reporting clean
#
# Literals, not a regex over "foundation". `foundation` alone has many legitimate
# hits (cogni-portfolio prose, cogni-narrative, the theme-system migration guide),
# and `four layers` collides with cogni-visual's four-layer validation gate and
# cogni-trends' Foundations dimension. Each literal below is a phrase that was
# measured present-and-wrong on the pre-reconciliation base, so each one is a
# claim about this repo rather than a guess.
#
# The first two literals measured ZERO on the base — an earlier PR had already
# removed them, which is why the issue's own acceptance criterion citing them was
# vacuous. They are retained here anyway, and case L2 plants each one in a
# fixture, so the scanner is proven to catch each phrase.
#
# What L2 does and does not prove. L2 reads the literals from FORBIDDEN, plants
# each in a fixture, and scans with FORBIDDEN — so it proves the SCANNER catches
# a planted phrase, but it cannot detect a literal being *reworded*: a
# substitution changes the planted text and the needle together, leaving L2
# green. The count floor below is what protects the set — dropping an entry takes
# l2_n under the floor and turns L2 red. Do not read L2 as a regression guard
# against editing a literal's wording; for a mutation that a change can actually
# flip, target the parity checker (see L4).
#
# Phrase-level survivors. These lines keep foundation vocabulary on purpose and
# must NOT be caught. Each says something about the workspace *state* other
# plugins read, never about the plugin's position in a dependency order, so none
# is falsified by the scope claim. Each is cited by its quoted text rather than
# by a line number: the quote is the locator, so an edit above it cannot rot the
# citation the way a number does.
#
#   - manage-workspace/SKILL.md — "An insight-wave workspace is the shared
#     foundation that all marketplace plugins depend on" (subject is the
#     workspace, not cogni-workspace)
#   - workspace-dashboard/SKILL.md — "the foundation that every other plugin
#     reads from" (reads from, not depends on)
#
# Two further entries once sat in this list, and a third such citation in the
# paragraph below, quoting course and workflow prose from a plugin since retired
# from the marketplace roster. All three are dropped rather than repointed: the
# files they named are gone from the tree, and the phrases they quoted survive
# nowhere else, so no page is left to point at. This inventory is a claim about
# what is standing in the current tree, so it may only name things that exist —
# the retired paths stay recorded in the historical tables of
# references/absorption-roadmap.md, whose Decision 8 states the reasoning.
#
# This list is why the shared-foundation literal below is prefixed with the
# plugin name: the bare "is the shared foundation" also matches the first entry,
# so an unprefixed literal would make this suite red on arrival against a line
# that is deliberately standing.
#
# The list is ILLUSTRATIVE, not exhaustive. It names the lines that shaped a
# literal's wording, not every surviving use of "foundation". More exist — the
# manage-workspace description propagates verbatim into its own frontmatter
# (:4, :10), into the [[skill-cogni-workspace-manage-workspace]] bullet under
# the cogni-workspace skills heading of each wiki tree's index.md (identified
# by wikilink rather than line number: the two trees number that bullet
# differently, so no single line number is right for both), and into both
# skill-cogni-workspace-manage-workspace.md:16. Those are
# all the same compatible claim about workspace state, and no literal here
# targets them. Grepping "foundation" will surface hits this block does not
# account for; that is expected, and the test is whether the sentence asserts a
# DEPENDENCY ORDER among plugins, not whether it uses the word.
#
# Path exclusions, each with a reason:
#   - this file (it necessarily contains every literal it forbids)
#   - references/absorption-roadmap.md — the decisions record quotes the retired
#     claim by design, as the historical inventory of what was reconciled
#   - wiki/log.md and the bundled copy — a dated ingest log; rewriting history is
#     not reconciliation
#   - wiki/pages/lint-2026-04-20.md — a dated lint note, and root-tree-only, so
#     editing it would also break the per-page parity assertion below
#   - cogni-visual/libraries/ — "Foundation Layer" there is an ASCII-art fill
#     label in a diagram legend, unrelated to the claim
#   - .git/ and .claude/worktrees/ — nested checkouts of this same repo that
#     local tooling leaves in the tree. Untracked, so `grep_hits` already skips
#     them on the real repo; these entries only cover the filesystem fallback.
#
# No manifest is exempt. cogni-workspace's own plugin.json and the root
# marketplace.json were the retired claim's last upstream source and carried a
# temporary exemption while the reconciliation's scope boundary kept manifest
# edits out of its diff; both descriptions now assert the horizontal-layer scope
# claim, so the exemption is gone and the scan covers them like any other file.
#
# Never re-add a bare `.claude-plugin/` fragment in their place. `is_excluded`
# matches by SUBSTRING, so that one fragment would exempt all 15 files under
# every plugin's manifest directory — any OTHER plugin could then reintroduce
# the claim invisibly, a gap far wider than the two files it would read as
# covering. Case L9 is what keeps that revert red.
#
# Parity is per-page, never tree-wide, and that is load-bearing. The two trees
# legitimately differ (the root tree carries lint-2026-04-20.md and the bundled
# one does not), and scripts/release-bundle-wiki.sh states that drift between
# releases is acceptable. A tree-wide diff would be red on arrival and would
# pressure someone into running that rsync --delete sync, which sweeps unrelated
# drift. Naming the eight pages this change touched keeps the assertion true and
# useful at the same time. Four are the layering-claim pages; the other four are
# the group-B workflow pages back-ported bundle -> root, pinned here so the
# sections that once existed only in the bundle cannot drift back out of the
# root tree unnoticed.
#
# Case-label shape matches test-wiki-namespace-sync.sh on purpose: "PASS: <case>"
# / "FAIL: <case>", because the cogni-service mutation harness classifies a case
# GREEN only on ^[[:space:]]*(ok|PASS):[[:space:]]+<case> and RED on the matching
# FAIL: form. Case ids are L-prefixed and never bare numerals, so the summary line
# is not read as a case's RED line.
#
# bash-3.2 portable (stock macOS /bin/bash is 3.2.57): no declare -A, no mapfile,
# no ${var^^}. stdlib-only: bash + coreutils, no pip deps, no network.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$WS_ROOT/.." && pwd)"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

# Phrases that assert the retired layering claim. One per line; matched
# case-insensitively as fixed strings, never as regexes.
FORBIDDEN='every other plugin depends
every other cogni-x plugin depends
no upward dependencies
foundation layer
higher layers depend
depend on lower layers
depends on lower layers
depends on nothing
foundation for all
foundation-layer plugin
the foundation the others depend on
cogni-workspace is the shared foundation
foundation: cogni-workspace
span four tiers'

# Repo-relative path fragments exempt from the scan. See the header for why each
# one is here.
#
# The two cogni-workspace/libraries/ entries are the adopted copies of the files
# `cogni-visual/libraries/` is already exempt for, and they are here for the same
# reason: both carry `Foundation Layer` as a label inside an ASCII-art diagram,
# naming a z-order layer in a drawing rather than making any claim about plugin
# layering. They are listed by exact path rather than as a directory prefix, so a
# future file added to that tree still has to answer to this guard — the incumbent
# cogni-visual entry is a directory only because the source tree is retired
# wholesale in a later stage.
EXCLUDED='cogni-workspace/tests/test-layering-claim-reconciled.sh
cogni-workspace/references/absorption-roadmap.md
wiki/wiki/log.md
wiki/wiki/pages/lint-2026-04-20.md
cogni-visual/libraries/
cogni-workspace/libraries/excalidraw-patterns.md
cogni-workspace/libraries/svg-patterns.md
.git/
.claude/worktrees/'

# Pages that must stay byte-identical between the two wiki trees. Scoped to what
# this reconciliation touched — see the header on why this is not tree-wide.
#
# plugin-cogni-portfolio.md joins the list with the bare-prose sweep: it carried
# four off-roster names across two lines, both copies were rewritten, and unlike
# its siblings here it had no byte-identity arm of its own. The roster-derived
# body scan now covers off-roster plugin names on both trees, so that class no
# longer rests on this entry alone. The entry stays regardless: a name scan sees
# only names, while byte-identity still catches arbitrary one-tree-only drift on
# that page — a reworded sentence, a dropped section, a changed link.
#
# concept-slug-based-lookups.md joins on the same grounds: its shared bullet named a
# manifest no plugin writes, both copies were rewritten identically, and no other arm
# here pins the two copies to each other. The roster-derived scan does not reach it
# either: that bullet named a MANIFEST, not a plugin, so a roster of plugin names
# never sees it.
PAGE_PARITY='plugin-cogni-workspace.md
workflow-install-to-infographic.md
arch-er-diagram.md
concept-four-layer-architecture.md
workflow-portfolio-to-website.md
workflow-content-pipeline.md
workflow-portfolio-to-pitch.md
workflow-trends-to-solutions.md
plugin-cogni-portfolio.md
concept-slug-based-lookups.md'

# ---------------------------------------------------------------------------
# The checkers. Fixture cases and the real-repo cases drive these same two
# functions, so pointing a case at a broken checker turns that case red.
# ---------------------------------------------------------------------------

# is_excluded <repo-relative-path> -> 0 when the path is exempt.
is_excluded() {
  local path="$1" frag
  while IFS= read -r frag; do
    [ -n "$frag" ] || continue
    case "$path" in
      *"$frag"*) return 0 ;;
    esac
  done <<EOF
$EXCLUDED
EOF
  return 1
}

# scan_literals <root> <label> -> 0 clean, 1 offenders found or root unusable.
# Prints one "OFFENDER <path>: <literal>" line per hit.
# Enumerate files under $1 containing the literal $2.
#
# Inside a git work tree, restrict the search to TRACKED files. The retired claim
# is an assertion about repo content, and the filesystem under this root also
# holds content git deliberately ignores — skill eval workspaces (`*-workspace/`)
# and nested worktree checkouts of this same repo. Scanning those makes the
# verdict depend on which branches and evals a developer happens to have on disk:
# green in CI, where none of it exists, and red on a working machine for reasons
# no reader can act on. `git grep` searches the working tree, so uncommitted edits
# to tracked files are still scanned — which is what a pre-commit guard needs.
#
# Outside a git work tree (the synthetic fixtures below) fall back to a plain
# recursive grep. The root must be the work tree's top level; `git grep` from a
# subdirectory scopes itself to that subdirectory, which would silently narrow
# the scan.
grep_hits() {
  local root="$1" lit="$2" top
  top="$(git -C "$root" rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -n "$top" ] && [ "$top" = "$(cd "$root" && pwd -P)" ]; then
    git -C "$root" grep -IliF -- "$lit" 2>/dev/null || true
  else
    grep -RIliF -- "$lit" "$root" 2>/dev/null || true
  fi
}

scan_literals() {
  local root="$1" label="$2"
  local offenders=0 scanned=0 lit hit path

  if [ ! -d "$root" ]; then
    echo "ERROR [$label] scan root not found: $root"
    return 1
  fi

  while IFS= read -r lit; do
    [ -n "$lit" ] || continue
    scanned=$((scanned + 1))
    # -R follows no symlinks by design; -I skips binaries; -l gives one path per file.
    while IFS= read -r hit; do
      [ -n "$hit" ] || continue
      path="${hit#$root/}"
      if is_excluded "$path"; then continue; fi
      echo "OFFENDER $path: $lit"
      offenders=$((offenders + 1))
    done <<EOF
$(grep_hits "$root" "$lit")
EOF
  done <<EOF
$FORBIDDEN
EOF

  # Liveness floor: a scan that examined no literals is not evidence of a clean
  # tree, it is evidence of a broken constant. Same half-dead-arm failure
  # test-wiki-namespace-sync.sh guards with its own empty-tree case.
  if [ "$scanned" -eq 0 ]; then
    echo "ERROR [$label] no literals scanned — FORBIDDEN is empty"
    return 1
  fi
  [ "$offenders" -eq 0 ]
}

# check_parity <root> <label> -> 0 when every PAGE_PARITY page matches across trees.
check_parity() {
  local root="$1" label="$2"
  local a="$root/wiki/wiki/pages" b="$root/cogni-workspace/wiki/wiki/pages"
  local mismatches=0 compared=0 page

  if [ ! -d "$a" ] || [ ! -d "$b" ]; then
    echo "ERROR [$label] one or both wiki page trees not found"
    return 1
  fi

  while IFS= read -r page; do
    [ -n "$page" ] || continue
    if [ ! -f "$a/$page" ] || [ ! -f "$b/$page" ]; then
      echo "MISSING $page absent from one tree"
      mismatches=$((mismatches + 1))
      continue
    fi
    compared=$((compared + 1))
    if ! cmp -s "$a/$page" "$b/$page"; then
      echo "DRIFT $page differs between the two wiki trees"
      mismatches=$((mismatches + 1))
    fi
  done <<EOF
$PAGE_PARITY
EOF

  if [ "$compared" -eq 0 ] && [ "$mismatches" -eq 0 ]; then
    echo "ERROR [$label] no pages compared — PAGE_PARITY is empty"
    return 1
  fi
  [ "$mismatches" -eq 0 ]
}

# --- harness ---------------------------------------------------------------
LAST_OUT=""; LAST_RC=0
run_scan()   { LAST_OUT="$(scan_literals "$1" "$2" 2>&1)"; LAST_RC=$?; }
run_parity() { LAST_OUT="$(check_parity  "$1" "$2" 2>&1)"; LAST_RC=$?; }
assert_rc()      { [ "$LAST_RC" -eq "$1" ] || { echo "  expected rc=$1 got rc=$LAST_RC"; echo "$LAST_OUT" | sed 's/^/  | /'; return 1; }; }
assert_out_has() { case "$LAST_OUT" in *"$1"*) return 0 ;; esac; echo "  expected output to contain: $1"; echo "$LAST_OUT" | sed 's/^/  | /'; return 1; }
assert_out_lacks(){ case "$LAST_OUT" in *"$1"*) echo "  expected output NOT to contain: $1"; echo "$LAST_OUT" | sed 's/^/  | /'; return 1 ;; esac; return 0; }

# ---------------------------------------------------------------------------
# L1 — the real repo is clean.
# ---------------------------------------------------------------------------
run_scan "$REPO_ROOT" "repo"
if assert_rc 0; then
  pass "L1 the real repo asserts no retired layering claim outside the excluded paths"
else
  fail "L1 the real repo asserts no retired layering claim outside the excluded paths"
fi

# ---------------------------------------------------------------------------
# L2 — every forbidden literal is caught when planted, and the set has not
# shrunk. The scan proves the two zero-on-base literals are wired to a working
# scanner; the count floor below is what stops one being dropped unnoticed. See
# the header on what this case cannot prove.
# ---------------------------------------------------------------------------
l2_ok=1
l2_n=0
while IFS= read -r lit; do
  [ -n "$lit" ] || continue
  l2_n=$((l2_n + 1))
  d="$TMPROOT/l2/$l2_n/docs"
  mkdir -p "$d"
  printf 'Some prose that says %s in passing.\n' "$lit" > "$d/page.md"
  run_scan "$TMPROOT/l2/$l2_n" "planted"
  assert_rc 1 && assert_out_has "docs/page.md" || l2_ok=0
done <<EOF
$FORBIDDEN
EOF
if [ "$l2_n" -lt 14 ]; then
  echo "  expected at least 14 literals, found $l2_n"
  l2_ok=0
fi
if [ "$l2_ok" -eq 1 ]; then
  pass "L2 every forbidden literal is caught when planted"
else
  fail "L2 every forbidden literal is caught when planted"
fi

# ---------------------------------------------------------------------------
# L3 — a literal under an excluded path is not flagged.
# ---------------------------------------------------------------------------
l3_ok=1
mkdir -p "$TMPROOT/l3/cogni-visual/libraries" \
         "$TMPROOT/l3/cogni-workspace/references" \
         "$TMPROOT/l3/wiki/wiki/pages"
printf '| Foundation Layer | fill |\n' > "$TMPROOT/l3/cogni-visual/libraries/svg-patterns.md"
printf 'The claim was: every other plugin depends on it.\n' > "$TMPROOT/l3/cogni-workspace/references/absorption-roadmap.md"
printf 'ingest: foundation layer\n' > "$TMPROOT/l3/wiki/wiki/log.md"
printf 'quoted `no upward dependencies` in a lint note\n' > "$TMPROOT/l3/wiki/wiki/pages/lint-2026-04-20.md"
run_scan "$TMPROOT/l3" "excluded"
assert_rc 0 || l3_ok=0
if [ "$l3_ok" -eq 1 ]; then
  pass "L3 a forbidden literal under an excluded path is not flagged"
else
  fail "L3 a forbidden literal under an excluded path is not flagged"
fi

# ---------------------------------------------------------------------------
# L4 — a PAGE_PARITY page that differs between the trees fails, and is named.
# ---------------------------------------------------------------------------
l4_ok=1
A="$TMPROOT/l4/wiki/wiki/pages"; B="$TMPROOT/l4/cogni-workspace/wiki/wiki/pages"
mkdir -p "$A" "$B"
while IFS= read -r page; do
  [ -n "$page" ] || continue
  printf 'same\n' > "$A/$page"
  printf 'same\n' > "$B/$page"
done <<EOF
$PAGE_PARITY
EOF
printf 'DIVERGED\n' > "$B/arch-er-diagram.md"
run_parity "$TMPROOT/l4" "drift"
assert_rc 1 && assert_out_has "arch-er-diagram.md" || l4_ok=0
if [ "$l4_ok" -eq 1 ]; then
  pass "L4 a touched page differing between the two trees fails and is named"
else
  fail "L4 a touched page differing between the two trees fails and is named"
fi

# ---------------------------------------------------------------------------
# L5 — a page outside PAGE_PARITY may differ without failing. This is what keeps
# the real trees' legitimate one-page delta from being red on arrival.
# ---------------------------------------------------------------------------
l5_ok=1
A="$TMPROOT/l5/wiki/wiki/pages"; B="$TMPROOT/l5/cogni-workspace/wiki/wiki/pages"
mkdir -p "$A" "$B"
while IFS= read -r page; do
  [ -n "$page" ] || continue
  printf 'same\n' > "$A/$page"
  printf 'same\n' > "$B/$page"
done <<EOF
$PAGE_PARITY
EOF
printf 'root-tree-only\n' > "$A/lint-2026-04-20.md"
run_parity "$TMPROOT/l5" "unlisted"
assert_rc 0 && assert_out_lacks "lint-2026-04-20" || l5_ok=0
if [ "$l5_ok" -eq 1 ]; then
  pass "L5 a page outside PAGE_PARITY may differ between the trees"
else
  fail "L5 a page outside PAGE_PARITY may differ between the trees"
fi

# ---------------------------------------------------------------------------
# L6 — liveness floor: a missing tree fails rather than reporting clean.
# ---------------------------------------------------------------------------
l6_ok=1
run_scan "$TMPROOT/l6/does-not-exist" "missing"
assert_rc 1 && assert_out_has "scan root not found" || l6_ok=0
run_parity "$TMPROOT/l6/does-not-exist" "missing"
assert_rc 1 && assert_out_has "wiki page trees not found" || l6_ok=0
if [ "$l6_ok" -eq 1 ]; then
  pass "L6 a missing tree fails rather than reporting clean"
else
  fail "L6 a missing tree fails rather than reporting clean"
fi

# ---------------------------------------------------------------------------
# L7 — the real repo's two wiki trees agree on every touched page.
# ---------------------------------------------------------------------------
run_parity "$REPO_ROOT" "repo"
if assert_rc 0; then
  pass "L7 the real wiki trees agree on every page this change touched"
else
  fail "L7 the real wiki trees agree on every page this change touched"
fi

# ---------------------------------------------------------------------------
# L8 — the git-tracked arm of grep_hits is live, and its narrowing is deliberate.
#
# Without this case the arm is untested. Every "caught when planted" fixture
# (L2, L3, L5) builds under mktemp, which is not a git work tree, so they all
# exercise the recursive-grep fallback; the only cases reaching the git arm are
# L1 and L7, and both assert CLEAN. Nothing would prove the arm can find
# anything — so if it ever returned empty (an edit, a sparse checkout, a flag an
# older git rejects) L1 would report PASS vacuously. That is the same half-dead
# arm the `scanned -eq 0` floor and L6 exist to prevent, and the arms were one
# code path until the scan was made git-aware.
#
# The second half pins the narrowing as intended rather than accidental: an
# untracked file carrying a literal is deliberately skipped, because the claim is
# an assertion about repo content and scanning ignored scratch made the verdict
# depend on a developer's local state. If the arm is ever swapped back to a
# filesystem walk, this half turns red and says so.
# ---------------------------------------------------------------------------
l8_ok=1
G="$TMPROOT/l8"
mkdir -p "$G/docs"
if ! git init -q "$G" >/dev/null 2>&1; then
  echo "  git init failed — cannot exercise the git-tracked arm"
  l8_ok=0
else
  printf 'Some prose that says foundation layer in passing.\n' > "$G/docs/tracked.md"
  git -C "$G" add docs/tracked.md >/dev/null 2>&1
  # commit.gpgsign is overridden too: it is a common personal global default, and
  # a signing failure here would red this case for a reason with nothing to do
  # with the arm under test — pointing a reader at the wrong code. CI is
  # unaffected, so this only bites the local pre-PR run, which is where the
  # suite's fastest signal is meant to come from.
  git -C "$G" -c user.email=guard@example.invalid -c user.name=Guard \
    -c commit.gpgsign=false \
    commit -q -m "fixture" >/dev/null 2>&1 || l8_ok=0

  # Tracked offender must be found, and named, by the git arm.
  run_scan "$G" "git-tracked"
  assert_rc 1 && assert_out_has "docs/tracked.md" || l8_ok=0

  # Untracked offender must NOT be found — the deliberate narrowing.
  printf 'Some prose that says foundation layer in passing.\n' > "$G/docs/untracked.md"
  run_scan "$G" "git-untracked"
  assert_rc 1 && assert_out_lacks "docs/untracked.md" || l8_ok=0
fi
if [ "$l8_ok" -eq 1 ]; then
  pass "L8 the git-tracked scan arm is live and skips untracked files"
else
  fail "L8 the git-tracked scan arm is live and skips untracked files"
fi

# ---------------------------------------------------------------------------
# L9 — no manifest is exempt: every `.claude-plugin` manifest is scanned.
#
# Same lesson as L8: without a case, the rule is asserted only in a comment.
# L1 cannot carry this one. Once the manifests were corrected, no manifest in
# the real repo holds a forbidden literal, so L1 is green whether EXCLUDED is
# empty of manifest entries or names them again — a re-added exemption, or a
# bare `.claude-plugin/` fragment re-opening all 15 files under every plugin's
# manifest directory, would slip in with every case still passing.
#
# This case makes both reverts red by planting the literal in three manifests
# that must ALL be caught: another plugin's, cogni-workspace's own (formerly
# exempt), and the root marketplace.json (which no case exercised before).
# ---------------------------------------------------------------------------
l9_ok=1
X="$TMPROOT/l9"
mkdir -p "$X/cogni-workspace/.claude-plugin" "$X/cogni-other/.claude-plugin" \
  "$X/.claude-plugin"
printf '{"description": "Foundation-layer plugin for insight-wave."}\n' \
  > "$X/cogni-workspace/.claude-plugin/plugin.json"
printf '{"description": "Foundation-layer plugin for insight-wave."}\n' \
  > "$X/cogni-other/.claude-plugin/plugin.json"
printf '{"description": "Foundation-layer plugin for insight-wave."}\n' \
  > "$X/.claude-plugin/marketplace.json"
run_scan "$X" "manifest-scope"
assert_rc 1 && assert_out_has "cogni-other/.claude-plugin/plugin.json" || l9_ok=0
assert_out_has "cogni-workspace/.claude-plugin/plugin.json" || l9_ok=0
assert_out_has ".claude-plugin/marketplace.json" || l9_ok=0
if [ "$l9_ok" -eq 1 ]; then
  pass "L9 no manifest is exempt — every .claude-plugin manifest is scanned"
else
  fail "L9 no manifest is exempt — every .claude-plugin manifest is scanned"
fi

# ---------------------------------------------------------------------------
if [ "$failures" -gt 0 ]; then
  echo ""
  echo "FAIL: $failures layering-claim test(s) failed."
  exit 1
fi
echo ""
echo "All layering-claim tests passed."
