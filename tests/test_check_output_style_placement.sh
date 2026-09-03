#!/usr/bin/env bash
# test_check_output_style_placement.sh -- suite for the output-style placement guard.
#
# Case labels are `<id> <description>` -- an id token followed by a SPACE, never
# a colon abutting the id. A mutation harness matches
# `^[[:space:]]*FAIL:[[:space:]]+<case>([[:space:]]|$)` whole-token, so a
# trailing colon would match neither arm and report case_not_found.
#
# FIXTURE TREES, NOT THE LIVE REPO, except case 11 which grades the live tree on
# purpose. The guard takes `--root`, so every fixture is a throwaway tree the
# SHIPPED script is pointed at -- never a copy of it. A suite that copies the
# script into each fixture grades a copy: the day the guard grows a sibling
# import or a baseline read, the copies diverge from the file CI runs and the
# suite goes green against code that is not under test.
#
# ZERO DISCOVERY IS EXIT 2. Any fixture meant to grade exit 0 or 1 must contain
# at least one plugin root, at least one output-styles directory AND at least
# one style file. Without all three, the case would silently be grading the
# empty-sweep path instead of the arm it names.
#
# THE GUARD'S STDERR IS NEVER REPLAYED VERBATIM. Its finding lines begin with
# `FAIL: [placement]`, which matches the harness's result-line shape while
# carrying no case id and repeating once per finding. Case 11 prefixes them.
#
# FOREIGN OUTPUT BY SHAPE. Assertions on the guard are on its own emitted text
# (own-emitter, safe to match literally) and on exit status. Nothing here greps
# a bash or coreutils diagnostic, whose wording is locale-dependent.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$SCRIPT_DIR/../scripts/check-output-style-placement.py"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FAILURES=0

pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; FAILURES=$((FAILURES + 1)); }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

OUT="$WORK/out.json"
ERR="$WORK/out.err"

# new_tree <name> -- an empty fixture root. The guard is pointed at it with
# --root, so nothing is copied in.
new_tree() {
  local t="$WORK/$1"
  mkdir -p "$t"
  printf '%s' "$t"
}

# add_plugin <tree> <name>
add_plugin() {
  mkdir -p "$1/$2/.claude-plugin"
  printf '{"name":"%s","version":"0.1.0"}\n' "$2" > "$1/$2/.claude-plugin/plugin.json"
}

# write_style <tree> <relpath> -- body on stdin.
write_style() {
  mkdir -p "$(dirname "$1/$2")"
  cat > "$1/$2"
}

# add_style <tree> <dir> <file> -- a well-formed register.
add_style() {
  write_style "$1" "$2/$3" <<'STYLE'
---
name: Fixture Register
description: A fixture register
---

Body.
STYLE
}

run_guard() { python3 "$GUARD" --root "$1" > "$OUT" 2>"$ERR"; }

# assert_case <id> <expected_rc> <needle_or_-> <tree> <desc>
assert_case() {
  local id="$1" want="$2" needle="$3" tree="$4" desc="$5"
  local label="$id $desc"
  run_guard "$tree"
  local rc=$?
  if [ "$rc" -ne "$want" ]; then
    fail "$label -- expected exit $want, got $rc"
    return
  fi
  if [ "$needle" != "-" ] && ! grep -qF "$needle" "$ERR"; then
    fail "$label -- exit $want but stderr lacks '$needle'"
    return
  fi
  if ! python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$OUT" 2>/dev/null; then
    fail "$label -- exit $want but stdout is not the JSON envelope every script owes"
    return
  fi
  pass "$label"
}

# assert_summary <id> <tree> <key> <expected> <desc> -- a counter must be load-bearing.
assert_summary() {
  local id="$1" tree="$2" key="$3" want="$4" desc="$5"
  local label="$id $desc"
  run_guard "$tree"
  local got
  got="$(python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
print(d.get('data', {}).get('summary', {}).get(sys.argv[2], 'ABSENT'))
" "$OUT" "$key" 2>/dev/null)"
  if [ "$got" != "$want" ]; then
    fail "$label -- summary.$key expected $want, got $got"
    return
  fi
  pass "$label"
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
write_style "$T" cogni-alpha/output-styles/thin.md <<'STYLE'
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
write_style "$T" cogni-alpha/output-styles/thin.md <<'STYLE'
---
description: Nameless
---

Body.
STYLE
assert_case "output-style-placement-04-no-name" 1 "[frontmatter]" "$T" \
  "style without name: is reported"

# --- 05  a frontmatter key at column 0 of the BODY does not satisfy the rule ---
# The scan reads the leading --- block only. A register documenting its own
# format routinely writes `name:` in prose; a file-wide scan would read that as
# compliance and ship a style the picker cannot render.
#
# The decoy sits at COLUMN 0, which is what makes this case discriminate. The
# guard's key regex is line-anchored, so a mid-sentence `description:` matches
# nothing under a file-wide scan either -- a fixture built that way stays green
# against a guard that has lost the property entirely.
T="$(new_tree bodykey)"
add_plugin "$T" cogni-alpha
write_style "$T" cogni-alpha/output-styles/prose.md <<'STYLE'
---
name: Prose
---

The second required key is written like this:

description: one line, rendered by the picker.
STYLE
assert_case "output-style-placement-05-body-key-not-counted" 1 "[frontmatter]" "$T" \
  "description: at column 0 of the body does not satisfy the frontmatter requirement"

# --- 06  an unresolvable CLAUDE_PLUGIN_ROOT reference -------------------------
T="$(new_tree badref)"
add_plugin "$T" cogni-alpha
write_style "$T" cogni-alpha/output-styles/ref.md <<'STYLE'
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
mkdir -p "$T/cogni-alpha/references"
printf 'present\n' > "$T/cogni-alpha/references/present.md"
write_style "$T" cogni-alpha/output-styles/ref.md <<'STYLE'
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
write_style "$T" cogni-alpha/output-styles/prose.md <<'STYLE'
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
# The guard is a hard clean zero, so the tree it ships in must pass it. Routed
# through assert_case like every other case, so its grading cannot drift from
# theirs, and its stderr is prefixed rather than replayed: the guard's own
# `FAIL: [placement] ...` lines would otherwise enter this suite's result stream
# carrying no case id.
run_guard "$REPO_ROOT"
if [ $? -eq 0 ]; then
  pass "output-style-placement-11-live-tree-clean the repository passes its own guard"
else
  fail "output-style-placement-11-live-tree-clean the repository passes its own guard"
  sed 's/^/    live-tree| /' "$ERR" >&2
fi

# --- 12  zero discovery: a style directory holding no register ----------------
# The floor counts scanned styles, not directories. A deletion that spares the
# directory, or a rename to .markdown, empties the population arms 2 and 3
# consume while a directory-only floor still reads as a clean sweep.
T="$(new_tree emptydir)"
add_plugin "$T" cogni-alpha
mkdir -p "$T/cogni-alpha/output-styles"
assert_case "output-style-placement-12-zero-styles" 2 "zero discovery" "$T" \
  "an output-styles directory holding no register exits 2, not 0"

# --- 13  a register outside every plugin root ---------------------------------
# The original defect was a register one level too deep. One level OUT -- at the
# repo root, or under docs/ -- has no plugin-root parent at all, which a walk
# scoped to plugin interiors cannot reach.
T="$(new_tree outside)"
add_plugin "$T" cogni-alpha
add_style "$T" cogni-alpha/output-styles good.md
add_style "$T" output-styles stray.md
assert_case "output-style-placement-13-outside-plugin" 1 "[placement]" "$T" \
  "an output-styles directory outside every plugin root is reported"

# --- 14  a register nested inside a compliant directory -----------------------
# Arm 1 skips the subdirectory (its basename is not output-styles), so unless
# arms 2 and 3 recurse, a per-language subdir is graded by nothing.
T="$(new_tree deepstyle)"
add_plugin "$T" cogni-alpha
add_style "$T" cogni-alpha/output-styles good.md
printf 'no frontmatter at all\n' > "$T/cogni-alpha/output-styles/de.md"
mkdir -p "$T/cogni-alpha/output-styles/de"
printf 'no frontmatter at all\n' > "$T/cogni-alpha/output-styles/de/workspace-de.md"
assert_case "output-style-placement-14-nested-register-scanned" 1 "[frontmatter]" "$T" \
  "a register one level deeper inside a compliant directory is still graded"

# --- 15  a reference escaping the plugin via .. -------------------------------
# The cross-plugin reference is the arm's own stated subject, and a bare
# existence test resolves it and passes.
T="$(new_tree traversal)"
add_plugin "$T" cogni-alpha
add_plugin "$T" cogni-beta
mkdir -p "$T/cogni-beta/references"
printf 'exists\n' > "$T/cogni-beta/references/other.md"
write_style "$T" cogni-alpha/output-styles/cross.md <<'STYLE'
---
name: Cross
description: Reaches into another plugin
---

See `$CLAUDE_PLUGIN_ROOT/../cogni-beta/references/other.md`.
STYLE
assert_case "output-style-placement-15-traversal-escape" 1 "[resolution]" "$T" \
  "a .. reference that resolves outside its own plugin is reported"

# --- 16  a code span carrying a command word or an argument -------------------
# The dominant runnable citation shape. An arm anchored on both backticks skips
# it and reports the same refs_checked as if the reference were absent, so the
# counter is asserted here rather than the exit status alone.
T="$(new_tree cmdspan)"
add_plugin "$T" cogni-alpha
write_style "$T" cogni-alpha/output-styles/cmd.md <<'STYLE'
---
name: Cmd
description: Cites scripts with their invocation
---

Run `bash $CLAUDE_PLUGIN_ROOT/scripts/missing.sh` and then
`python3 ${CLAUDE_PLUGIN_ROOT}/scripts/absent.py --json`.
STYLE
assert_case "output-style-placement-16-command-span-checked" 1 "[resolution]" "$T" \
  "a reference carrying a command word or an argument is still resolved"
assert_summary "output-style-placement-16b-command-span-counted" "$T" \
  plugin_root_refs_checked 2 \
  "both multi-token references are counted, not silently skipped"

# --- 17  a BOM does not make a valid register look empty ----------------------
# Windows editors and PowerShell redirection add one, and utf-8 decoding does
# not strip it. The guard ships no allowlist, so a false positive here has no
# escape but rewriting a valid file.
T="$(new_tree bom)"
add_plugin "$T" cogni-alpha
printf '\xef\xbb\xbf---\nname: Bommed\ndescription: Carries a byte-order mark\n---\n\nBody.\n' \
  > "$(mkdir -p "$T/cogni-alpha/output-styles"; printf '%s' "$T/cogni-alpha/output-styles/bom.md")"
assert_case "output-style-placement-17-bom-tolerated" 0 - "$T" \
  "a BOM-prefixed register with both keys present passes"

# --- 18  a space before the colon is valid YAML -------------------------------
T="$(new_tree spacedkey)"
add_plugin "$T" cogni-alpha
write_style "$T" cogni-alpha/output-styles/spaced.md <<'STYLE'
---
name : Spaced
description : A space before the colon, which pyyaml accepts
---

Body.
STYLE
assert_case "output-style-placement-18-spaced-colon-tolerated" 0 - "$T" \
  "name : value with a space before the colon passes"

# --- 19  a present key with an empty value ------------------------------------
# The picker renders a blank row, which is the discovered-but-unusable state the
# arm exists to prevent, reached by a quieter route than a missing key.
T="$(new_tree emptyvalue)"
add_plugin "$T" cogni-alpha
write_style "$T" cogni-alpha/output-styles/blank.md <<'STYLE'
---
name:
description:
---

Body.
STYLE
assert_case "output-style-placement-19-empty-value" 1 "[frontmatter]" "$T" \
  "frontmatter keys present with empty values are reported"

# --- 20  a non-UTF-8 register does not take the guard down --------------------
# A crash prints no JSON at all and exits 1, which is the guard's own findings
# code -- an environment error wearing a violation's clothes.
T="$(new_tree latin1)"
add_plugin "$T" cogni-alpha
mkdir -p "$T/cogni-alpha/output-styles"
printf -- '---\nname: DE\ndescription: Pr\xe4zise Sprache f\xfcr Qualit\xe4t\n---\n\nBody.\n' \
  > "$T/cogni-alpha/output-styles/latin1.md"
assert_case "output-style-placement-20-non-utf8-survives" 0 - "$T" \
  "a latin-1 register is decoded leniently rather than crashing the guard"

# --- 21  dot-prefixed directories are pruned ----------------------------------
# A workspace predating this rule keeps a retired copy at .claude/output-styles/,
# which the migration text tells the user to KEEP. Grading it reports a
# violation no contributor can fix in this repo.
T="$(new_tree dotdir)"
add_plugin "$T" cogni-alpha
add_style "$T" cogni-alpha/output-styles good.md
add_style "$T" cogni-alpha/.claude/output-styles legacy.md
assert_case "output-style-placement-21-dot-dirs-pruned" 0 - "$T" \
  "a retained register under .claude/ is not reported as misplaced"

# --- 22  the JSON envelope is the shape every script in this repo owes --------
T="$(new_tree envelope)"
add_plugin "$T" cogni-alpha
add_style "$T" cogni-alpha/output-styles good.md
run_guard "$T"
if python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
assert set(d) == {'success', 'data', 'error'}, sorted(d)
assert d['success'] is True
assert d['error'] == ''
s = d['data']['summary']
for k in ('total', 'plugins_discovered', 'style_dirs_discovered', 'styles_scanned',
          'plugin_root_refs_checked'):
    assert isinstance(s[k], int), k
assert s['styles_scanned'] == 1, s['styles_scanned']
" "$OUT" 2>/dev/null; then
  pass "output-style-placement-22-envelope-shape the JSON envelope carries success, data and error"
else
  fail "output-style-placement-22-envelope-shape the JSON envelope carries success, data and error"
fi

printf '%s\n' "---"
if [ "$FAILURES" -eq 0 ]; then
  printf '%s\n' "All cases passed."
  exit 0
fi
printf '%s\n' "$FAILURES case(s) failed."
exit 1
