#!/usr/bin/env bash
# Wiki namespace-sync guard: no bundled wiki page may name a plugin that no
# longer exists.
#
# Why this exists. The bundled wiki is read directly — a reader points Claude
# at its `wiki/index.md`, and the answer draws only on the pages it lists and
# cites every claim with a [[wikilink]]. That contract is only as good as the
# wiki's freshness, and nothing else enforces it — scripts/check-external-dispatch.py
# deliberately excludes both wiki trees (EXCLUDE_SEGMENTS / EXCLUDE_TOPLEVEL),
# because a wiki mirror may legitimately quote a retired dispatch as page content.
# So a plugin can be absorbed or archived, its pages linger, and answers keep
# citing them confidently. This suite is the wiki-side check that closes that gap.
#
# Contract under test:
#   - the allowed namespace set is DERIVED AT RUNTIME from plugins[].name in
#     .claude-plugin/marketplace.json — never a denylist of retired names
#   - a page whose filename encodes an off-roster namespace fails, and the
#     offending filename is printed
#   - BOTH wiki trees are scanned, and each arm is independently provable
#   - non-namespaced page families (concept-, arch-, workflow-, lint-,
#     ecosystem-overview) are never flagged
#   - the real trees are clean
#
# Roster-derived, not a denylist — deliberately. A "never mention <retired-plugin>"
# grep encodes one historical event and catches nothing at the next absorption.
# Deriving the allowed set from the marketplace roster is the same durable
# invariant scripts/check-plugin-inventory.py argues for: it catches the next
# carve-out without being told any names. Note the asymmetry, though — that guard
# asserts a bijection, while this one is deliberately a subset check: it flags a
# page for a plugin that is gone, but does not demand a page for every roster
# plugin. cogni-knowledge and cogni-consult are on the roster with no pages in
# either tree, so requiring the reverse direction would be red on arrival, and the
# only ways to green it are authoring the missing pages or keeping an exemption
# list — the very hand-maintained list this design rejects. A stale page makes
# the assistant answer wrongly; a missing page only makes it answer less. Guarding the
# wrong-answer direction first is the intended sequencing.
#
# Namespace matching is boundary-aware, and that is load-bearing. A page stem
# matches roster entry `p` only when it equals `p` or begins with `p-`. Plain
# substring/startswith matching would silently bless every `cogni-consulting-*`
# page, because the live roster entry `cogni-consult` is a strict prefix of the
# retired `cogni-consulting`. The same boundary keeps skill-cogni-help-cogni-issues.md
# attributed to `cogni-help` rather than to a phantom `cogni-issues` plugin.
#
# Out-of-marketplace namespaces: cogni-docs and cogni-service are real plugins
# hosted in a DIFFERENT marketplace, so they are legitimately absent from this
# repo's marketplace.json. They are allowed via the explicit EXTRA_ALLOWED
# constant below rather than flagged. Neither tree carries a page for them today,
# so case C7 is the only thing exercising that allowlist — it is forward-looking
# policy, not dead config. Silence here would have been a latent wrong answer the
# first time someone wrote such a page.
#
# Case-label shape is "PASS: <label>" / "FAIL: <label>", the shape every discovered
# suite in this repo now carries. The cogni-service mutation harness classifies a case
# GREEN only on ^[[:space:]]*(ok|PASS):[[:space:]]+<case> and RED on the matching
# FAIL: form. Neither "OK   " nor "OK:" is in that vocabulary, so a mutation replay
# against a suite using them reports case_not_found instead of a verdict. Case ids are
# C-prefixed and never bare numerals, which is what keeps the final summary line
# ("FAIL: <n> wiki-namespace-sync test(s) failed.") from being read as a case's RED
# line — a hazard the colon form creates and every suite here has to answer.
#
# bash-3.2 portable (stock macOS /bin/bash is 3.2.57): no declare -A / typeset -A,
# no mapfile / readarray, no ${var^^} / ${var,,}. The roster is carried as a
# plain space-separated string and matched one element at a time with `case`,
# which is the house alternative to an associative array.
#
# stdlib-only: bash + coreutils + python3 (json parsing), no pip deps, no network.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$WS_ROOT/.." && pwd)"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

# Plugins that legitimately live outside this repo's marketplace. See the header.
EXTRA_ALLOWED="cogni-docs cogni-service"

# ---------------------------------------------------------------------------
# The checker. Fixture cases and the real-tree case drive these same two
# functions — the matcher is never reimplemented in a case body, so pointing a
# case at a broken matcher turns that case red.
# ---------------------------------------------------------------------------

# roster_from <marketplace.json> -> space-padded allowed-namespace string.
# Reads ONLY plugins[].name. The file's top-level "name" is the marketplace
# itself ("insight-wave") and "owner" is an object carrying a human name; a
# generic walk for any "name" key would pick both up as phantom namespaces.
roster_from() {
  local mf="$1" names
  [ -f "$mf" ] || { echo "ERROR marketplace manifest not found: $mf"; return 1; }
  names="$(python3 -c '
import json, sys
with open(sys.argv[1]) as fh:
    data = json.load(fh)
print(" ".join(p["name"] for p in data["plugins"]))
' "$mf")" || return 1
  echo " $names $EXTRA_ALLOWED "
}

# scan_tree <pages_dir> <label> <roster> -> 0 clean, 1 offenders/unusable tree.
scan_tree() {
  local dir="$1" label="$2" roster="$3"
  local offenders=0 total=0
  local f stem rest p matched

  if [ ! -d "$dir" ]; then
    echo "ERROR [$label] pages directory not found: $dir"
    return 1
  fi

  for f in "$dir"/*.md; do
    [ -e "$f" ] || continue
    total=$((total + 1))
    stem="${f##*/}"; stem="${stem%.md}"
    # Only the three namespaced families carry a plugin name. Everything else
    # (concept-, arch-, workflow-, lint-, ecosystem-overview, index, log) is
    # structurally out of scope rather than special-cased away.
    case "$stem" in
      plugin-*) rest="${stem#plugin-}" ;;
      skill-*)  rest="${stem#skill-}" ;;
      agent-*)  rest="${stem#agent-}" ;;
      *) continue ;;
    esac
    matched=0
    for p in $roster; do
      # Boundary-aware: exact stem, or the roster name followed by "-".
      case "$rest" in
        "$p"|"$p"-*) matched=1; break ;;
      esac
    done
    if [ "$matched" -eq 0 ]; then
      echo "OFF-ROSTER [$label] $stem.md"
      offenders=$((offenders + 1))
    fi
  done

  # Per-arm liveness floor. Without it, an arm pointed at a missing or empty
  # directory reports clean, and a half-dead guard is indistinguishable from a
  # working one — the workspace tree is already clean, so nothing else would
  # notice its scan had stopped running.
  if [ "$total" -eq 0 ]; then
    echo "ERROR [$label] no .md pages found under $dir"
    return 1
  fi

  [ "$offenders" -eq 0 ] || return 1
  return 0
}

# scan_repo <repo_root> -> 0 clean, 1 otherwise. Scans BOTH trees; each arm is a
# separate call so either can be independently neutralised by a mutation.
scan_repo() {
  local root="$1" roster rc=0
  roster="$(roster_from "$root/.claude-plugin/marketplace.json")" || return 1
  scan_tree "$root/wiki/wiki/pages" "root" "$roster" || rc=1
  scan_tree "$root/cogni-workspace/wiki/wiki/pages" "workspace" "$roster" || rc=1
  return "$rc"
}

# ---------------------------------------------------------------------------
# Harness
# ---------------------------------------------------------------------------

RC=0
OUT=""

run_scan_repo() { OUT="$(scan_repo "$1" 2>&1)"; RC=$?; }
run_scan_tree() { OUT="$(scan_tree "$1" "$2" "$3" 2>&1)"; RC=$?; }

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
assert_out_lacks() {
  case "$OUT" in *"$1"*) echo "     expected output NOT to contain: $1"; return 1 ;; esac
  return 0
}

# mk_page <path> — a minimal but schema-shaped fixture page.
mk_page() {
  mkdir -p "$(dirname "$1")"
  printf -- '---\nid: %s\ntitle: fixture\ntype: fixture\n---\n\nfixture page.\n' \
    "$(basename "$1" .md)" > "$1"
}

# mk_marketplace <path> <plugin-names...> — carries the same confusable shape as
# the real manifest: a top-level "name" and an "owner" object with its own name.
mk_marketplace() {
  local out="$1"; shift
  mkdir -p "$(dirname "$out")"
  python3 -c '
import json, sys
out = sys.argv[1]
names = sys.argv[2:]
doc = {
    "name": "fixture-marketplace",
    "owner": {"name": "Fixture Owner", "email": "fixture@example.invalid"},
    "plugins": [{"name": n, "source": "./" + n} for n in names],
}
with open(out, "w") as fh:
    json.dump(doc, fh, indent=2)
' "$out" "$@"
}

# mk_fixture_repo <root> — a two-armed stand-in. BOTH arms are populated with a
# valid on-roster page: the liveness floor fails an empty arm, so a one-armed
# fixture would false-fail every "exits 0" assertion.
mk_fixture_repo() {
  local root="$1"
  mk_marketplace "$root/.claude-plugin/marketplace.json" cogni-workspace cogni-consult cogni-help
  mk_page "$root/wiki/wiki/pages/plugin-cogni-workspace.md"
  mk_page "$root/cogni-workspace/wiki/wiki/pages/plugin-cogni-workspace.md"
}

# ---------------------------------------------------------------------------
# C1 — the real trees are clean (asserted here, not only in fixtures).
# ---------------------------------------------------------------------------
run_scan_repo "$REPO_ROOT"
if assert_rc 0; then
  pass "C1 real wiki trees carry no off-roster namespace pages"
else
  fail "C1 real wiki trees carry no off-roster namespace pages"
fi

# ---------------------------------------------------------------------------
# C2 — a planted off-roster page in the ROOT arm is caught and named.
# ---------------------------------------------------------------------------
F2="$TMPROOT/c2"
mk_fixture_repo "$F2"
mk_page "$F2/wiki/wiki/pages/plugin-cogni-nonexistent.md"
run_scan_repo "$F2"
if assert_rc 1 && assert_out_has "plugin-cogni-nonexistent.md" && assert_out_has "[root]"; then
  pass "C2 off-roster page in the root tree fails and is named"
else
  fail "C2 off-roster page in the root tree fails and is named"
fi

# ---------------------------------------------------------------------------
# C3 — the same plant in the WORKSPACE arm. C2 and C3 together are what prove
# both arms are live: delete either arm's scan_tree call and exactly one of
# these goes red.
# ---------------------------------------------------------------------------
F3="$TMPROOT/c3"
mk_fixture_repo "$F3"
mk_page "$F3/cogni-workspace/wiki/wiki/pages/agent-cogni-nonexistent-worker.md"
run_scan_repo "$F3"
if assert_rc 1 && assert_out_has "agent-cogni-nonexistent-worker.md" && assert_out_has "[workspace]"; then
  pass "C3 off-roster page in the workspace tree fails and is named"
else
  fail "C3 off-roster page in the workspace tree fails and is named"
fi

# ---------------------------------------------------------------------------
# C4 — prefix boundary. cogni-consult IS on the fixture roster and is a strict
# prefix of cogni-consulting. A startswith matcher passes this tree; the
# boundary matcher flags both consulting pages and neither consult page.
# ---------------------------------------------------------------------------
F4="$TMPROOT/c4/pages"
mk_page "$F4/plugin-cogni-consulting.md"
mk_page "$F4/skill-cogni-consulting-consulting-define.md"
mk_page "$F4/plugin-cogni-consult.md"
mk_page "$F4/skill-cogni-consult-consult-scope.md"
run_scan_tree "$F4" "boundary" " cogni-consult cogni-workspace "
if assert_rc 1 \
  && assert_out_has "plugin-cogni-consulting.md" \
  && assert_out_has "skill-cogni-consulting-consulting-define.md" \
  && assert_out_lacks "plugin-cogni-consult.md" \
  && assert_out_lacks "skill-cogni-consult-consult-scope.md"; then
  pass "C4 retired cogni-consulting flagged while live cogni-consult is not"
else
  fail "C4 retired cogni-consulting flagged while live cogni-consult is not"
fi

# ---------------------------------------------------------------------------
# C5 — false positives. Non-namespaced families and a valid namespaced page all
# pass. skill-cogni-help-cogni-issues.md is the trap: a matcher extracting any
# cogni-* substring reads a phantom "cogni-issues" namespace out of it.
# ---------------------------------------------------------------------------
F5="$TMPROOT/c5/pages"
mk_page "$F5/concept-agent-model-strategy.md"
mk_page "$F5/arch-plugin-anatomy.md"
mk_page "$F5/workflow-content-pipeline.md"
mk_page "$F5/ecosystem-overview.md"
mk_page "$F5/lint-2026-04-20.md"
mk_page "$F5/skill-cogni-help-cogni-issues.md"
mk_page "$F5/skill-cogni-workspace-ask.md"
run_scan_tree "$F5" "clean" " cogni-help cogni-workspace "
if assert_rc 0; then
  pass "C5 non-namespaced families and valid namespaced pages are not flagged"
else
  fail "C5 non-namespaced families and valid namespaced pages are not flagged"
fi

# ---------------------------------------------------------------------------
# C6 — roster source. The manifest's top-level name and owner.name must not leak
# into the allowed set; only plugins[].name counts.
# ---------------------------------------------------------------------------
F6="$TMPROOT/c6"
mkdir -p "$F6/.claude-plugin"
python3 -c '
import json, sys
out = sys.argv[1]
doc = {
    "name": "cogni-bogus",
    "owner": {"name": "cogni-owner", "email": "fixture@example.invalid"},
    "plugins": [{"name": "cogni-real", "source": "./cogni-real"}],
}
with open(out, "w") as fh:
    json.dump(doc, fh, indent=2)
' "$F6/.claude-plugin/marketplace.json"
mk_page "$F6/wiki/wiki/pages/plugin-cogni-real.md"
mk_page "$F6/wiki/wiki/pages/plugin-cogni-bogus.md"
mk_page "$F6/wiki/wiki/pages/plugin-cogni-owner.md"
mk_page "$F6/cogni-workspace/wiki/wiki/pages/plugin-cogni-real.md"
run_scan_repo "$F6"
if assert_rc 1 \
  && assert_out_has "plugin-cogni-bogus.md" \
  && assert_out_has "plugin-cogni-owner.md" \
  && assert_out_lacks "plugin-cogni-real.md"; then
  pass "C6 roster comes from plugins[].name, not the manifest or owner name"
else
  fail "C6 roster comes from plugins[].name, not the manifest or owner name"
fi

# ---------------------------------------------------------------------------
# C7 — out-of-marketplace allowlist. See EXTRA_ALLOWED and the header.
# ---------------------------------------------------------------------------
F7="$TMPROOT/c7/pages"
mk_page "$F7/plugin-cogni-docs.md"
mk_page "$F7/skill-cogni-service-service-resume.md"
mk_page "$F7/plugin-cogni-workspace.md"
run_scan_tree "$F7" "external" " cogni-workspace $EXTRA_ALLOWED "
if assert_rc 0; then
  pass "C7 plugins hosted in another marketplace are allowed, not flagged"
else
  fail "C7 plugins hosted in another marketplace are allowed, not flagged"
fi

# ---------------------------------------------------------------------------
# C8 — the liveness floor itself. Without this the floor is an unfalsifiable
# branch, and a scan silently pointed at nothing would report clean.
# ---------------------------------------------------------------------------
F8="$TMPROOT/c8/empty-pages"
mkdir -p "$F8"
c8_ok=1
run_scan_tree "$F8" "empty" " cogni-workspace "
assert_rc 1 && assert_out_has "no .md pages found" || c8_ok=0
run_scan_tree "$TMPROOT/c8/does-not-exist" "missing" " cogni-workspace "
assert_rc 1 && assert_out_has "pages directory not found" || c8_ok=0
if [ "$c8_ok" -eq 1 ]; then
  pass "C8 an empty or missing tree fails rather than reporting clean"
else
  fail "C8 an empty or missing tree fails rather than reporting clean"
fi

# ---------------------------------------------------------------------------
if [ "$failures" -gt 0 ]; then
  echo ""
  echo "FAIL: $failures wiki-namespace-sync test(s) failed."
  exit 1
fi
echo ""
echo "All wiki-namespace-sync tests passed."
