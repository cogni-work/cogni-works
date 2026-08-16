#!/usr/bin/env bash
#
# Self-test for scripts/release-bundle-wiki.sh's pre-sync destruction gate.
#
# Cases:
#   RBW1  a bundle-only page makes a bare sync refuse, and writes no bytes
#   RBW2  the refusal is one JSON object naming the path in data.would_delete
#   RBW3  a bundled copy holding lines the source lacks is refused as would_overwrite
#   RBW4  a bundle that is a strict subset of source still syncs bare (no over-refusal)
#   RBW5  an already-identical bundle still syncs bare (the empty-count regression)
#   RBW6  --force performs the destructive sync the bare run refused
#   RBW7  --help prints the whole header and nothing below it
#   RBW8  an unknown argument still yields the error envelope and exit 1
#   RBW9  a bundled tree that is absent, or present but holding no pages, still
#         syncs bare — there is nothing there to destroy
#
# Satisfies the runner's three-property contract: it exits non-zero on failure
# and zero otherwise, runs as `bash <path>` with no arguments from any working
# directory, and needs no network or credentials, writing only inside its own
# mktemp -d.
#
# Every sync-mode case runs against a mktemp fixture, never the repository's own
# wiki/ and cogni-workspace/wiki/ trees. That is not merely hygiene here: a bare
# sync against the real trees is precisely the data loss this guard exists to
# prevent, so a suite that reached for them would destroy seven pages to prove
# they should not be destroyed.
#
# The fixture copies the REAL scripts/release-bundle-wiki.sh rather than
# vendoring a replica, so the suite cannot keep passing against a frozen
# snapshot while the script drifts — and so a mutation applied to the script
# actually reaches the code under test. The script derives both tree paths from
# `dirname $0/..`, so running the copy from <fixture>/scripts/ is what makes
# both roots resolve inside the fixture; there is no path-override flag.
#
# Mutation recipe (proves RBW1's refusal assertion can go red):
#
#   bash cogni-service/scripts/mutation-check.sh \
#     --root "$REPO_ROOT" \
#     --file scripts/release-bundle-wiki.sh \
#     --expr 's/DESTRUCTIVE_COUNT" -gt 0/DESTRUCTIVE_COUNT" -lt 0/' \
#     --test 'bash tests/test_release_bundle_wiki.sh' \
#     --case RBW1
#
# DESTRUCTIVE_COUNT is a sum of two non-negative counts, so `-lt 0` is
# unconditionally false: the gate can never fire, the bare run proceeds to the
# real rsync --delete, and RBW1 goes red on both of its assertions. The
# replacement shares no substring with the matched literal, so it cannot be a
# no-op. Note the harness applies --expr through `perl -0pi` in slurp mode with
# no /g, so it rewrites only the FIRST occurrence in the file — the literal
# `DESTRUCTIVE_COUNT" -gt 0` must therefore appear exactly once in the script,
# on the `if` line. A comment restating the comparison would absorb the mutation
# and leave the guard intact, reporting a false green.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/release-bundle-wiki.sh"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Plain, uncoloured result lines — unconditionally, matching the harness-parsable
# suites elsewhere in the repo. A result line must start with the literal `PASS:` /
# `FAIL:` so a mutation harness can classify it with `^[[:space:]]*FAIL:[[:space:]]+`;
# an ANSI escape sequence precedes the label and defeats that match. Deciding by
# `[ -t 1 ]` instead would make parsability environment-dependent.
red()   { printf '%s\n' "$1"; }
green() { printf '%s\n' "$1"; }

FAILED=0

check() {
  # check <label> <condition-description-already-evaluated:0|1>
  if [ "$2" -eq 0 ]; then
    green "PASS: $1"
  else
    red "FAIL: $1"
    FAILED=$((FAILED + 1))
  fi
}

check_eq() {
  # check_eq <label> <expected> <actual>
  if [ "$2" = "$3" ]; then
    green "PASS: $1"
  else
    red "FAIL: $1 (expected [$2], got [$3])"
    FAILED=$((FAILED + 1))
  fi
}

# Build a fixture tree holding a real copy of the script plus a source and a
# bundled wiki. Mirrors the repo layout the script assumes.
make_fixture() {
  FIX="$WORK/$1"
  mkdir -p "$FIX/scripts" \
           "$FIX/wiki/.cogni-wiki" \
           "$FIX/wiki/wiki/pages" \
           "$FIX/cogni-workspace/wiki/.cogni-wiki" \
           "$FIX/cogni-workspace/wiki/wiki/pages"
  cp "$SCRIPT" "$FIX/scripts/release-bundle-wiki.sh"
  printf '{"name": "fixture"}\n' > "$FIX/wiki/.cogni-wiki/config.json"
  printf '{"name": "fixture"}\n' > "$FIX/cogni-workspace/wiki/.cogni-wiki/config.json"
  printf 'shared page\n' > "$FIX/wiki/wiki/pages/shared.md"
  printf 'shared page\n' > "$FIX/cogni-workspace/wiki/wiki/pages/shared.md"
}

# Run the fixture's copy of the script, capturing stdout and exit code.
# Never `set -e`-fatal: the refusal path exits 1 by design.
run_fixture() {
  FIXDIR="$WORK/$1"
  shift
  set +e
  OUT=$(bash "$FIXDIR/scripts/release-bundle-wiki.sh" "$@" 2>/dev/null)
  CODE=$?
  set -e
}

# A stable manifest of the bundled tree: every path plus its sha, so "wrote no
# bytes" is asserted against content and not merely against file presence.
bundle_manifest() {
  ( cd "$WORK/$1/cogni-workspace/wiki" && find . -type f | LC_ALL=C sort | while IFS= read -r p; do
      printf '%s %s\n' "$p" "$(shasum "$p" | awk '{print $1}')"
    done )
}

json_field() {
  # json_field <json> <python-expression-over-d>
  printf '%s' "$1" | python3 -c "import json,sys; d=json.load(sys.stdin); print($2)"
}

# ---------------------------------------------------------------- RBW1 / RBW2
# A page in the bundle with no source counterpart is exactly what `rsync
# --delete` destroys silently.
make_fixture rbw1
printf 'only in the bundle\n' > "$WORK/rbw1/cogni-workspace/wiki/wiki/pages/bundle-only.md"
printf 'only in the source\n' > "$WORK/rbw1/wiki/wiki/pages/source-only.md"
BEFORE=$(bundle_manifest rbw1)
run_fixture rbw1
AFTER=$(bundle_manifest rbw1)

check_eq "RBW1 a bundle-only page makes a bare sync exit non-zero" "1" "$CODE"
[ "$BEFORE" = "$AFTER" ]; check "RBW1 the refusal writes no bytes to the bundled tree" "$?"
[ -f "$WORK/rbw1/cogni-workspace/wiki/wiki/pages/bundle-only.md" ]
check "RBW1 the bundle-only page survives the refusal" "$?"
[ ! -f "$WORK/rbw1/cogni-workspace/wiki/wiki/pages/source-only.md" ]
check "RBW1 no source-only page was added by the refused run" "$?"

printf '%s' "$OUT" | python3 -c 'import json,sys; json.load(sys.stdin)' >/dev/null 2>&1
check "RBW2 the whole refusal stdout parses as one JSON object" "$?"
check_eq "RBW2 refusal reports success false" "False" "$(json_field "$OUT" 'd["success"]')"
check_eq "RBW2 would_delete names the bundle-only page" "wiki/pages/bundle-only.md" \
  "$(json_field "$OUT" 'd["data"]["would_delete"][0]')"
check_eq "RBW2 destructive_path_count counts it" "1" \
  "$(json_field "$OUT" 'd["data"]["destructive_path_count"]')"
check_eq "RBW2 the error names the override flag" "True" \
  "$(json_field "$OUT" '"--force" in d["error"]')"

# ---------------------------------------------------------------------- RBW3
# The overwrite class: both sides hold the file, but the bundled copy carries
# content that exists nowhere else. A page-count check cannot see this, because
# overwriting does not change how many files there are.
make_fixture rbw3
printf 'shared page\n## Steps\nbundle-only section\n' \
  > "$WORK/rbw3/cogni-workspace/wiki/wiki/pages/shared.md"
BEFORE=$(bundle_manifest rbw3)
run_fixture rbw3
AFTER=$(bundle_manifest rbw3)

check_eq "RBW3 a bundled superset makes a bare sync exit non-zero" "1" "$CODE"
[ "$BEFORE" = "$AFTER" ]; check "RBW3 the overwrite refusal writes no bytes" "$?"
check_eq "RBW3 would_overwrite names the shared page" "wiki/pages/shared.md" \
  "$(json_field "$OUT" 'd["data"]["would_overwrite"][0]')"
check_eq "RBW3 would_delete stays empty for the overwrite class" "0" \
  "$(json_field "$OUT" 'len(d["data"]["would_delete"])')"

# ---------------------------------------------------------------------- RBW4
# The anti-over-refusal case. The source enriching a bundled file loses nothing,
# so it must not be blocked — otherwise --force becomes mandatory on every run
# and stops being read.
make_fixture rbw4
printf 'shared page\nnew line from source\n' > "$WORK/rbw4/wiki/wiki/pages/shared.md"
run_fixture rbw4

check_eq "RBW4 a source-enriched bundle syncs bare, without --force" "0" "$CODE"
check_eq "RBW4 that sync reports success" "True" "$(json_field "$OUT" 'd["success"]')"
grep -q 'new line from source' "$WORK/rbw4/cogni-workspace/wiki/wiki/pages/shared.md"
check "RBW4 the source content reached the bundle" "$?"

# ---------------------------------------------------------------------- RBW5
# Regression guard. Deriving the counts with `wc -l` reports 1 for an empty
# value, which would make the gate refuse a perfectly in-sync bundle and render
# the script unusable on its documented pre-publish path.
make_fixture rbw5
run_fixture rbw5

check_eq "RBW5 an already-identical bundle syncs bare" "0" "$CODE"
check_eq "RBW5 that sync reports success" "True" "$(json_field "$OUT" 'd["success"]')"

# ---------------------------------------------------------------------- RBW6
# The opt-in must be a real override, not a no-op.
make_fixture rbw6
printf 'only in the bundle\n' > "$WORK/rbw6/cogni-workspace/wiki/wiki/pages/bundle-only.md"
printf 'only in the source\n' > "$WORK/rbw6/wiki/wiki/pages/source-only.md"
run_fixture rbw6 --force

check_eq "RBW6 --force performs the sync the bare run refused" "0" "$CODE"
check_eq "RBW6 the forced sync reports success" "True" "$(json_field "$OUT" 'd["success"]')"
[ ! -f "$WORK/rbw6/cogni-workspace/wiki/wiki/pages/bundle-only.md" ]
check "RBW6 --force really deleted the bundle-only page" "$?"
[ -f "$WORK/rbw6/cogni-workspace/wiki/wiki/pages/source-only.md" ]
check "RBW6 --force really added the source-only page" "$?"

# ---------------------------------------------------------------------- RBW7
# The help range is a hand-maintained line number and the header just grew, so
# pin it at BOTH ends: too narrow truncates the usage text, too wide leaks the
# code below into --help.
make_fixture rbw7
run_fixture rbw7 --help

check_eq "RBW7 --help exits 0" "0" "$CODE"
printf '%s' "$OUT" | grep -q -- '--force'
check "RBW7 --help documents the --force opt-in" "$?"
printf '%s' "$OUT" | grep -q -- '--check'
check "RBW7 --help still documents --check" "$?"
printf '%s' "$OUT" | grep -q 'error'
check "RBW7 --help reaches the last header line" "$?"
! printf '%s' "$OUT" | grep -q 'set -eu'
check "RBW7 --help does not run past the header into the code" "$?"

# ---------------------------------------------------------------------- RBW8
# The new arms must sit before the catch-all, or every flag becomes "unknown".
make_fixture rbw8
run_fixture rbw8 --definitely-not-a-flag

check_eq "RBW8 an unknown argument exits 1" "1" "$CODE"
check_eq "RBW8 an unknown argument reports success false" "False" \
  "$(json_field "$OUT" 'd["success"]')"
check_eq "RBW8 the error names the offending argument" "True" \
  "$(json_field "$OUT" '"--definitely-not-a-flag" in d["error"]')"

# ---------------------------------------------------------------------------- RBW9
# Nothing in the bundle means nothing to destroy, so the gate must stay out of
# the way. Two shapes: the bundled tree missing entirely (a first-ever publish),
# and present but holding no pages. Both are the bootstrap path, and a gate that
# refused here would make the bundle impossible to create in the first place.
make_fixture rbw9a
rm -rf "$WORK/rbw9a/cogni-workspace/wiki"
run_fixture rbw9a

check_eq "RBW9 an absent bundled tree syncs bare" "0" "$CODE"
check_eq "RBW9 that bootstrap sync reports success" "True" "$(json_field "$OUT" 'd["success"]')"
[ -f "$WORK/rbw9a/cogni-workspace/wiki/wiki/pages/shared.md" ]
check "RBW9 the bootstrap sync populated the bundled tree" "$?"

make_fixture rbw9b
rm -f "$WORK/rbw9b/cogni-workspace/wiki/wiki/pages/shared.md"
run_fixture rbw9b

check_eq "RBW9 an empty bundled page set syncs bare" "0" "$CODE"
check_eq "RBW9 that sync reports success" "True" "$(json_field "$OUT" 'd["success"]')"
[ -f "$WORK/rbw9b/cogni-workspace/wiki/wiki/pages/shared.md" ]
check "RBW9 the empty bundled tree was populated" "$?"

# ----------------------------------------------------------------------------
if [ "$FAILED" -eq 0 ]; then
  green "All release-bundle-wiki gate checks passed."
  exit 0
else
  red "$FAILED release-bundle-wiki gate check(s) failed."
  exit 1
fi
