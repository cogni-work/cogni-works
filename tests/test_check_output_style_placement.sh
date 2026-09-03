#!/usr/bin/env bash
# test_check_output_style_placement.sh -- suite for the output-style placement guard.
#
# Case labels are `<id> <description>` -- an id token followed by a SPACE, never
# a colon abutting the id. A mutation harness matches
# `^[[:space:]]*FAIL:[[:space:]]+<case>([[:space:]]|$)` whole-token, so a
# trailing colon would match neither arm and report case_not_found.
#
# FIXTURE TREES, NOT THE LIVE REPO. The guard derives its repo root as the
# PARENT of its own directory, so every fixture is a throwaway tree carrying a
# copy of the script at `<fixture>/scripts/`. That keeps the suite from grading
# the live tree, whose contents change with every plugin added.
#
# ZERO DISCOVERY IS EXIT 2. Any fixture meant to grade exit 0 or 1 must contain
# at least one plugin root AND at least one output-styles directory. Without
# both, the case would silently be grading the empty-sweep path instead of the
# arm it names.
#
# FOREIGN OUTPUT BY SHAPE. Assertions on the guard are on its own emitted text
# (own-emitter, safe to match literally) and on exit status. Nothing here greps
# a bash or coreutils diagnostic, whose wording is locale-dependent.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$SCRIPT_DIR/../scripts/check-output-style-placement.py"

FAILURES=0

pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; FAILURES=$((FAILURES + 1)); }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# new_tree <name> -- fixture root carrying a copy of the guard.
new_tree() {
  local t="$WORK/$1"
  mkdir -p "$t/scripts"
  cp "$GUARD" "$t/scripts/"
  printf '%s' "$t"
}

# add_plugin <tree> <name>
add_plugin() {
  mkdir -p "$1/$2/.claude-plugin"
  printf '{"name":"%s","version":"0.1.0"}\n' "$2" > "$1/$2/.claude-plugin/plugin.json"
}

# add_style <tree> <dir> <file> -- a well-formed register.
add_style() {
  mkdir -p "$1/$2"
  cat > "$1/$2/$3" <<'STYLE'
---
name: Fixture Register
description: A fixture register
---

Body.
STYLE
}

run_guard() { python3 "$1/scripts/check-output-style-placement.py" >/dev/null 2>"$1/.err"; }

# assert_case <id> <expected_rc> <needle_or_-> <tree> <desc>
assert_case() {
  local id="$1" want="$2" needle="$3" tree="$4" desc="$5"
  run_guard "$tree"
  local rc=$?
  if [ "$rc" -ne "$want" ]; then
    fail "$id $desc -- expected exit $want, got $rc"
    return
  fi
  if [ "$needle" != "-" ] && ! grep -qF "$needle" "$tree/.err"; then
    fail "$id $desc -- exit $want but stderr lacks '$needle'"
    return
  fi
  pass "$id $desc"
}

# --- 01  a clean tree is green ------------------------------------------------
T="$(new_tree clean)"
add_plugin "$T" cogni-alpha
add_style "$T" cogni-alpha/output-styles good.md
assert_case "output-style-placement-01-clean" 0 - "$T" \
  "root-level register with complete frontmatter passes"

# --- 02  the original defect: a nested output-styles directory ----------------
T="$(new_tree nested)"
add_plugin "$T" cogni-alpha
add_style "$T" cogni-alpha/output-styles good.md
add_style "$T" cogni-alpha/assets/output-styles buried.md
assert_case "output-style-placement-02-nested" 1 "[placement]" "$T" \
  "output-styles nested under assets/ is reported"

# --- 03  frontmatter: description missing -------------------------------------
T="$(new_tree nodesc)"
add_plugin "$T" cogni-alpha
mkdir -p "$T/cogni-alpha/output-styles"
cat > "$T/cogni-alpha/output-styles/thin.md" <<'STYLE'
---
name: Thin
---

Body.
STYLE
assert_case "output-style-placement-03-no-description" 1 "[frontmatter]" "$T" \
  "style without description: is reported"

# --- 04  frontmatter: name missing --------------------------------------------
T="$(new_tree noname)"
add_plugin "$T" cogni-alpha
mkdir -p "$T/cogni-alpha/output-styles"
cat > "$T/cogni-alpha/output-styles/thin.md" <<'STYLE'
---
description: Nameless
---

Body.
STYLE
assert_case "output-style-placement-04-no-name" 1 "[frontmatter]" "$T" \
  "style without name: is reported"

# --- 05  a frontmatter key quoted in the BODY does not satisfy the requirement -
# The scan reads the leading --- block only. A register documenting its own
# format routinely writes `name:` in prose; a file-wide scan would read that as
# compliance and ship a style the picker cannot render.
T="$(new_tree bodykey)"
add_plugin "$T" cogni-alpha
mkdir -p "$T/cogni-alpha/output-styles"
cat > "$T/cogni-alpha/output-styles/prose.md" <<'STYLE'
---
name: Prose
---

Every style declares description: followed by one line.
STYLE
assert_case "output-style-placement-05-body-key-not-counted" 1 "[frontmatter]" "$T" \
  "description: in the body does not satisfy the frontmatter requirement"

# --- 06  an unresolvable CLAUDE_PLUGIN_ROOT reference -------------------------
T="$(new_tree badref)"
add_plugin "$T" cogni-alpha
mkdir -p "$T/cogni-alpha/output-styles"
cat > "$T/cogni-alpha/output-styles/ref.md" <<'STYLE'
---
name: Ref
description: Points at a file that is not here
---

The register lives in `$CLAUDE_PLUGIN_ROOT/references/absent.md`.
STYLE
assert_case "output-style-placement-06-unresolvable-ref" 1 "[resolution]" "$T" \
  "CLAUDE_PLUGIN_ROOT reference missing from its own plugin is reported"

# --- 07  a resolvable reference is green --------------------------------------
T="$(new_tree goodref)"
add_plugin "$T" cogni-alpha
mkdir -p "$T/cogni-alpha/output-styles" "$T/cogni-alpha/references"
printf 'present\n' > "$T/cogni-alpha/references/present.md"
cat > "$T/cogni-alpha/output-styles/ref.md" <<'STYLE'
---
name: Ref
description: Points at a file that exists
---

The register lives in `$CLAUDE_PLUGIN_ROOT/references/present.md`.
STYLE
assert_case "output-style-placement-07-resolvable-ref" 0 - "$T" \
  "CLAUDE_PLUGIN_ROOT reference that resolves in its own plugin passes"

# --- 08  a prose mention outside a code span is not a reference ---------------
# This is the false-positive class the code-span requirement exists to exclude:
# the convention itself is discussed in prose across this repo.
T="$(new_tree prosemention)"
add_plugin "$T" cogni-alpha
mkdir -p "$T/cogni-alpha/output-styles"
cat > "$T/cogni-alpha/output-styles/prose.md" <<'STYLE'
---
name: Prose
description: Discusses the convention without citing a path
---

A path written as $CLAUDE_PLUGIN_ROOT/references/whatever.md in running prose is
being discussed, not dereferenced.
STYLE
assert_case "output-style-placement-08-prose-mention-ignored" 0 - "$T" \
  "bare CLAUDE_PLUGIN_ROOT prose mention is not treated as a reference"

# --- 09  zero discovery: no plugin roots at all -------------------------------
T="$(new_tree noplugins)"
assert_case "output-style-placement-09-zero-plugins" 2 "zero discovery" "$T" \
  "a tree with no plugin roots exits 2 rather than reporting a clean sweep"

# --- 10  zero discovery: plugins present, no output-styles anywhere -----------
T="$(new_tree nostyles)"
add_plugin "$T" cogni-alpha
add_plugin "$T" cogni-beta
assert_case "output-style-placement-10-zero-style-dirs" 2 "zero discovery" "$T" \
  "plugins with no output-styles directory exits 2, not 0"

# --- 11  the live repo is clean ------------------------------------------------
# The guard is a hard clean zero, so the tree it ships in must pass it.
if python3 "$GUARD" >/dev/null 2>"$WORK/live.err"; then
  pass "output-style-placement-11-live-tree-clean the repository passes its own guard"
else
  fail "output-style-placement-11-live-tree-clean the repository fails its own guard"
  cat "$WORK/live.err" >&2
fi

printf '%s\n' "---"
if [ "$FAILURES" -eq 0 ]; then
  printf '%s\n' "All cases passed."
  exit 0
fi
printf '%s\n' "$FAILURES case(s) failed."
exit 1
