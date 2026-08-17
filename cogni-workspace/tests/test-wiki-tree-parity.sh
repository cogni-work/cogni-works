#!/usr/bin/env bash
# Wiki two-tree parity guard: each tree must be internally consistent, and any
# page that exists in only one tree must carry a recorded decision.
#
# Why this exists. insight-wave ships the wiki twice — `wiki/` is the editing
# surface, `cogni-workspace/wiki/` is the vendored copy that reaches users. The
# two are allowed to differ between releases, so a tree-wide equality check would
# be wrong. What is NOT allowed is a tree that misdescribes itself, or a
# one-sided page nobody decided on. Nothing enforced either before this suite:
#   - test-wiki-namespace-sync.sh compares filename stems against the marketplace
#     roster, so it never looks inside a page or at either config
#   - test-layering-claim-reconciled.sh pins eight named pages to byte-identity
#     and scans for retired wording, so it is silent on every other page
# Both would stay green while a config overstated its tree by nine pages and a
# page linked to something that had been deleted out from under it. That is the
# gap this closes.
#
# Contract under test:
#   - each tree's .cogni-wiki/config.json entries_count equals a LIVE count of
#     that same tree's pages — derived, never hardcoded, one call per arm
#   - every wiki reference in a tree resolves within that SAME tree, with that
#     tree's pages AND its top-level *.md (index / log / overview) scanned as
#     link SOURCES, not merely resolved as link targets
#   - every page present in only one tree is named in the decisions record at
#     cogni-workspace/references/wiki-tree-reconciliation.md
#   - an empty, missing or config-less arm fails rather than reporting clean
#
# The third item is the one that makes the record load-bearing rather than
# decorative: adding a page to one tree, or promoting one across, goes red until
# a decision for it is written down. Reversing that check is what lets the two
# trees drift apart again silently.
#
# Deliberately NOT asserted: that the trees are equal. They are not, and by
# design — the decisions record explains each surviving difference.
#
# Case-label shape follows test-wiki-namespace-sync.sh: "PASS: <id> <label>" /
# "FAIL: <id> <label>", ids W-prefixed and never bare numerals. The cogni-service
# mutation harness classifies a case GREEN only on ^[[:space:]]*(ok|PASS):[[:space:]]+<case>
# and RED on the matching FAIL: form, so a replay against an "OK   " label would
# report case_not_found instead of a verdict. Do not restyle these labels.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RECORD_REL="cogni-workspace/references/wiki-tree-reconciliation.md"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

PASSED=0
FAILED=0
pass() { echo "PASS: $1"; PASSED=$((PASSED + 1)); }
fail() { echo "FAIL: $1"; FAILED=$((FAILED + 1)); }

# ---------------------------------------------------------------------------
# The checkers. Fixture cases and the real-repo cases drive these same
# functions, so pointing a case at a broken checker turns that case red.
# ---------------------------------------------------------------------------

# count_pages <tree_root> -> prints the number of *.md directly under wiki/pages.
count_pages() {
  find "$1/wiki/pages" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' '
}

# check_count <tree_root> <label> -> 0 when entries_count matches the live count.
check_count() {
  local root="$1" label="$2" cfg recorded actual
  cfg="$root/.cogni-wiki/config.json"

  if [ ! -f "$cfg" ]; then
    echo "ERROR [$label] config not found: $cfg"
    return 1
  fi
  if [ ! -d "$root/wiki/pages" ]; then
    echo "ERROR [$label] pages directory not found: $root/wiki/pages"
    return 1
  fi

  actual="$(count_pages "$root")"
  # Liveness floor, same reasoning as the sibling suite: an arm pointed at an
  # empty directory would otherwise compare 0 against 0 and report clean.
  if [ "$actual" -eq 0 ]; then
    echo "ERROR [$label] no .md pages found under $root/wiki/pages"
    return 1
  fi

  recorded="$(python3 -c '
import json, sys
with open(sys.argv[1]) as fh:
    print(json.load(fh).get("entries_count", "MISSING"))
' "$cfg")" || return 1

  if [ "$recorded" != "$actual" ]; then
    echo "COUNT-DRIFT [$label] entries_count=$recorded but $actual pages on disk"
    return 1
  fi
  return 0
}

# check_links <tree_root> <label> -> 0 when every reference resolves in-tree.
check_links() {
  local root="$1" label="$2" out rc

  if [ ! -d "$root/wiki/pages" ]; then
    echo "ERROR [$label] pages directory not found: $root/wiki/pages"
    return 1
  fi

  out="$(python3 -c '
import os, re, sys

root, label = sys.argv[1], sys.argv[2]
pages_dir = os.path.join(root, "wiki", "pages")
wiki_dir = os.path.join(root, "wiki")

page_names = [n for n in os.listdir(pages_dir) if n.endswith(".md")]
# index / log / overview live one level up, beside pages/. They are link targets
# AND link sources: a catalogue that points at a page it no longer has is the
# same defect as a page doing it. The isfile filter keeps a directory named
# *.md from raising IsADirectoryError when it is opened below.
top_names = [n for n in os.listdir(wiki_dir)
             if n.endswith(".md") and os.path.isfile(os.path.join(wiki_dir, n))]

# Both arms are floored, and each floor has a case behind it. Flooring only the
# pages arm would leave the top-level arm able to scan nothing and still report
# clean -- which is the pages-only blindness this scan was widened to remove.
if not page_names:
    print("ERROR [%s] no pages to scan under %s" % (label, pages_dir))
    sys.exit(1)
if not top_names:
    print("ERROR [%s] no top-level files to scan under %s" % (label, wiki_dir))
    sys.exit(1)

# stems is DERIVED from sources rather than accumulated alongside it, so the two
# halves cannot drift apart. Blinding the scan to an arm also removes that arm
# from the resolvable set, which turns any surviving reference to it dangling
# instead of quietly unchecked.
sources = [(pages_dir, n) for n in sorted(page_names)] + [(wiki_dir, n) for n in sorted(top_names)]
stems = set(n[:-3] for _, n in sources)

pattern = re.compile(r"\[\[([^\]]+)\]\]")
offenders = 0
for d, name in sources:
    with open(os.path.join(d, name), encoding="utf-8") as fh:
        body = fh.read()
    for raw in pattern.findall(body):
        # Strip a display alias and an in-page anchor before resolving.
        target = raw.split("|", 1)[0].split("#", 1)[0].strip()
        if not target:
            continue
        if target not in stems:
            print("DANGLING [%s] %s -> [[%s]]" % (label, name, target))
            offenders += 1

sys.exit(1 if offenders else 0)
' "$root" "$label" 2>&1)"
  rc=$?
  [ -n "$out" ] && echo "$out"
  return "$rc"
}

# check_recorded <repo_root> -> 0 when every one-sided page is named in the record.
#
# The set difference is computed at runtime in BOTH directions, so this never
# encodes today's seven-and-one split as a constant.
check_recorded() {
  local root="$1" record out rc
  record="$root/$RECORD_REL"

  if [ ! -f "$record" ]; then
    echo "ERROR decisions record not found: $record"
    return 1
  fi

  out="$(python3 -c '
import os, sys

root, record = sys.argv[1], sys.argv[2]
a = os.path.join(root, "wiki", "wiki", "pages")
b = os.path.join(root, "cogni-workspace", "wiki", "wiki", "pages")
for d in (a, b):
    if not os.path.isdir(d):
        print("ERROR pages directory not found: %s" % d)
        sys.exit(1)

def stems(d):
    return set(n[:-3] for n in os.listdir(d) if n.endswith(".md"))

sa, sb = stems(a), stems(b)
if not sa or not sb:
    print("ERROR an arm has no pages; refusing to report clean")
    sys.exit(1)

with open(record, encoding="utf-8") as fh:
    text = fh.read()

missing = 0
for stem in sorted((sa - sb) | (sb - sa)):
    if stem not in text:
        side = "root-only" if stem in sa else "bundled-only"
        print("UNRECORDED [%s] %s is in one tree only and is not named in the record" % (side, stem))
        missing += 1
sys.exit(1 if missing else 0)
' "$root" "$record" 2>&1)"
  rc=$?
  [ -n "$out" ] && echo "$out"
  return "$rc"
}

# ---------------------------------------------------------------------------
# Harness
# ---------------------------------------------------------------------------

RC=0
OUT=""

run_count()    { OUT="$(check_count "$1" "$2" 2>&1)"; RC=$?; }
run_links()    { OUT="$(check_links "$1" "$2" 2>&1)"; RC=$?; }
run_recorded() { OUT="$(check_recorded "$1" 2>&1)"; RC=$?; }

assert_rc() { # <expected-rc>
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

# mk_page <path> [body] — a minimal but schema-shaped fixture page.
mk_page() {
  mkdir -p "$(dirname "$1")"
  printf -- '---\nid: %s\ntitle: fixture\ntype: fixture\n---\n\n%s\n' \
    "$(basename "$1" .md)" "${2:-fixture page.}" > "$1"
}

# mk_config <tree_root> <entries_count>
mk_config() {
  mkdir -p "$1/.cogni-wiki"
  printf '{\n  "version": "0.1.0",\n  "entries_count": %s,\n  "last_lint": "2026-01-01"\n}\n' \
    "$2" > "$1/.cogni-wiki/config.json"
}

# mk_tree <tree_root> <entries_count> — one self-consistent arm with two pages.
mk_tree() {
  mk_page "$1/wiki/pages/alpha.md"
  mk_page "$1/wiki/pages/beta.md"
  # Every real tree has a top-level catalogue, and check_links now requires one,
  # so a fixture without it would fail on its floor rather than on its subject.
  mk_page "$1/wiki/index.md" 'fixture catalogue.'
  mk_config "$1" "$2"
}

# mk_fixture_repo <root> — a two-armed stand-in whose arms agree, plus a record.
mk_fixture_repo() {
  local root="$1"
  mk_tree "$root/wiki" 2
  mk_tree "$root/cogni-workspace/wiki" 2
  mkdir -p "$root/$(dirname "$RECORD_REL")"
  printf '# fixture record\n\nNo one-sided pages.\n' > "$root/$RECORD_REL"
}

# ---------------------------------------------------------------------------
# W1 / W2 — the real trees describe themselves correctly. Two separate calls, so
# deleting either arm turns exactly one of these red.
# ---------------------------------------------------------------------------
run_count "$REPO_ROOT/wiki" "root"
if assert_rc 0; then
  pass "W1 root wiki tree entries_count matches its page count"
else
  fail "W1 root wiki tree entries_count matches its page count"
fi

run_count "$REPO_ROOT/cogni-workspace/wiki" "workspace"
if assert_rc 0; then
  pass "W2 workspace wiki tree entries_count matches its page count"
else
  fail "W2 workspace wiki tree entries_count matches its page count"
fi

# ---------------------------------------------------------------------------
# W3 — a planted count mismatch fails and names the arm.
# ---------------------------------------------------------------------------
F3="$TMPROOT/w3"
mk_fixture_repo "$F3"
mk_config "$F3/wiki" 99
run_count "$F3/wiki" "root"
if assert_rc 1 && assert_out_has "COUNT-DRIFT" && assert_out_has "[root]"; then
  pass "W3 a planted entries_count mismatch fails and names the arm"
else
  fail "W3 a planted entries_count mismatch fails and names the arm"
fi

# ---------------------------------------------------------------------------
# W4 / W5 — no reference in either real tree points at a page that tree lacks.
# ---------------------------------------------------------------------------
run_links "$REPO_ROOT/wiki" "root"
if assert_rc 0; then
  pass "W4 every reference in the root tree resolves within that tree"
else
  fail "W4 every reference in the root tree resolves within that tree"
fi

run_links "$REPO_ROOT/cogni-workspace/wiki" "workspace"
if assert_rc 0; then
  pass "W5 every reference in the workspace tree resolves within that tree"
else
  fail "W5 every reference in the workspace tree resolves within that tree"
fi

# ---------------------------------------------------------------------------
# W6 — a planted unresolvable reference fails and names both file and target.
# ---------------------------------------------------------------------------
F6="$TMPROOT/w6"
mk_fixture_repo "$F6"
mk_page "$F6/wiki/wiki/pages/alpha.md" 'see [[gamma-not-here]] for more.'
run_links "$F6/wiki" "root"
if assert_rc 1 && assert_out_has "DANGLING" && assert_out_has "gamma-not-here"; then
  pass "W6 a planted unresolvable reference fails and names the target"
else
  fail "W6 a planted unresolvable reference fails and names the target"
fi

# ---------------------------------------------------------------------------
# W7 — every page present in only one real tree is named in the decisions record.
# This is what makes the record load-bearing: promote or add a page without
# writing down a decision and this goes red.
# ---------------------------------------------------------------------------
run_recorded "$REPO_ROOT"
if assert_rc 0; then
  pass "W7 every one-sided page is named in the decisions record"
else
  fail "W7 every one-sided page is named in the decisions record"
fi

# ---------------------------------------------------------------------------
# W8 — an unrecorded one-sided page fails, and an empty or config-less arm fails
# rather than reporting clean. Both halves are the liveness floor: without them a
# half-dead guard is indistinguishable from a working one.
# ---------------------------------------------------------------------------
W8_A=1
F8="$TMPROOT/w8"
mk_fixture_repo "$F8"
mk_page "$F8/cogni-workspace/wiki/wiki/pages/orphan-page.md"
mk_config "$F8/cogni-workspace/wiki" 3
run_recorded "$F8"
if [ "$RC" -eq 1 ]; then
  case "$OUT" in *"UNRECORDED"*) W8_A=0 ;; esac
fi

W8_B=1
F8B="$TMPROOT/w8b"
mk_fixture_repo "$F8B"
rm -f "$F8B/wiki/.cogni-wiki/config.json"
run_count "$F8B/wiki" "root"
[ "$RC" -eq 1 ] && W8_B=0

W8_C=1
F8C="$TMPROOT/w8c"
mk_fixture_repo "$F8C"
rm -f "$F8C/wiki/wiki/pages"/*.md
run_count "$F8C/wiki" "root"
[ "$RC" -eq 1 ] && W8_C=0

if [ "$W8_A" -eq 0 ] && [ "$W8_B" -eq 0 ] && [ "$W8_C" -eq 0 ]; then
  pass "W8 an unrecorded page, a missing config and an empty arm each fail"
else
  fail "W8 an unrecorded page, a missing config and an empty arm each fail"
fi

# ---------------------------------------------------------------------------
# W9 - a dangling reference in a top-level index.md fails and names index.md.
# The pages arm is left clean on purpose, so the red can only come from the
# top-level source arm. Without that arm this case reports rc 0 and proves
# nothing: both real trees carried twelve such references for the whole
# lifetime of the retired-plugin cleanup with W4/W5 green throughout.
# ---------------------------------------------------------------------------
F9="$TMPROOT/w9"
mk_fixture_repo "$F9"
mk_page "$F9/wiki/wiki/index.md" 'catalog entry: [[delta-not-here]].'
run_links "$F9/wiki" "root"
if assert_rc 1 && assert_out_has "DANGLING" && assert_out_has "index.md" && assert_out_has "delta-not-here"; then
  pass "W9 a dangling reference in a top-level index.md fails and names index.md"
else
  fail "W9 a dangling reference in a top-level index.md fails and names index.md"
fi

# ---------------------------------------------------------------------------
# W10 - the new arm does not cry wolf: a valid top-level index.md referencing
# both pages and another top-level file still scans clean.
# ---------------------------------------------------------------------------
F10="$TMPROOT/w10"
mk_fixture_repo "$F10"
mk_page "$F10/wiki/wiki/log.md" 'no references here.'
mk_page "$F10/wiki/wiki/index.md" 'catalog: [[alpha]] and [[beta]], history in [[log]].'
run_links "$F10/wiki" "root"
if assert_rc 0; then
  pass "W10 a valid top-level index.md scans clean and resolves top-level targets"
else
  fail "W10 a valid top-level index.md scans clean and resolves top-level targets"
fi

# ---------------------------------------------------------------------------
# W11 - the empty-arm floor survives the widening. Making index.md scannable
# also makes it a stem, so a guard keyed on the stem set alone would now be
# satisfied by index.md while pages/ sits empty. This pins the floor to the
# pages enumeration instead.
# ---------------------------------------------------------------------------
F11="$TMPROOT/w11"
mk_fixture_repo "$F11"
rm -f "$F11/wiki/wiki/pages"/*.md
mk_page "$F11/wiki/wiki/index.md" 'catalog with no pages behind it.'
run_links "$F11/wiki" "root"
if assert_rc 1 && assert_out_has "no pages to scan"; then
  pass "W11 an emptied pages arm still fails even when a top-level index.md is scannable"
else
  fail "W11 an emptied pages arm still fails even when a top-level index.md is scannable"
fi

# ---------------------------------------------------------------------------
# W12 - the top-level arm has a floor of its own. Without it a tree whose
# catalogue is renamed or deleted scans pages only and reports clean, which is
# exactly the blindness this widening removed. The pages arm cannot stand in
# for this: the bundled tree has no page referencing [[index]], so losing its
# catalogue would take the source arm offline with every case still green.
# ---------------------------------------------------------------------------
F12="$TMPROOT/w12"
mk_fixture_repo "$F12"
rm -f "$F12/wiki/wiki"/*.md
run_links "$F12/wiki" "root"
if assert_rc 1 && assert_out_has "no top-level files to scan"; then
  pass "W12 a tree with no top-level file fails rather than scanning pages only"
else
  fail "W12 a tree with no top-level file fails rather than scanning pages only"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
if [ "$FAILED" -gt 0 ]; then
  echo "FAIL: $FAILED wiki-tree-parity test(s) failed."
  exit 1
fi
echo "All wiki-tree-parity tests passed. ($PASSED cases)"
exit 0
