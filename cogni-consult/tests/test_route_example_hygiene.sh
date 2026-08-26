#!/usr/bin/env bash
# Guard: the `Route:` worked examples in consult-action-fields name a real,
# live skill slug — never a plugin name, never a retired one, never the default.
#
# Label vocabulary is the shape every suite in this directory carries. The
# shared mutation harness classifies a case by matching `FAIL: <case>` (red) and
# `ok: <case>` / `PASS: <case>` (green), each requiring whitespace or
# end-of-line immediately after the case token. So a case id is a single
# whitespace-free token and any detail is separated with " - ", never a glued
# colon: `PASS: goes-red: ...` would match neither pattern, and a recipe
# recorded against this suite would return case_not_found instead of a verdict.
#
# Which mutation reddens which case. Two recipes are recorded in the pull
# request — one drives the second case, one drives the fifth against the
# plugin-root README.md; the retired names they substitute are deliberately not
# spelled here, so this file introduces no new mention of a retired plugin.
#   route-examples-found         deleting both `Route:` example lines
#   route-example-slug-resolves  rewriting the route token to any prefix listed
#                                in scripts/retired-plugins.json (the recorded recipe)
#   route-example-non-default    rewriting the route token to consult-design-thinking
#   route-example-parity         changing the route token at one site only
#   no-retired-plugin-name       planting any retired prefix in any scanned body
#                                (the recorded README recipe)
#
# RELATIONSHIP TO scripts/check-external-dispatch.py. That repo-level guard reads
# the SAME registry and already scans this subject file, so this suite is not a
# second copy of it — it fills a gap the colon in that guard's pattern leaves
# open. It compiles `\b(?:<prefix>):`, matching only colon-bearing dispatch
# tokens, because the colon is what separates a dispatch from a noun or a
# filesystem path; widening it to bare names would flag ~100 legitimate prose
# and path mentions repo-wide. The discriminator between "retired plugin named
# as a route" and "retired plugin name used as a directory" only exists near the
# site, which is why this half of the property is guarded per-plugin here rather
# than repo-wide there.
#
# DIRECTORY-VS-DISPATCH CARVE-OUT. Case 5 keeps the BARE-NAME match; the colon
# anchor above cannot be reused here. The README row this case exists to catch
# named a retired plugin in a Dependencies table with no colon at all, so a
# colon-anchored match would be permanently green against exactly the content
# the case guards — vacuous, and unfalsifiable by the recorded recipe. What is
# excluded instead is an occurrence immediately followed by `/`: that is what a
# filesystem path looks like, and a directory that happens to be named after a
# retired plugin is not a route. The carve-out is load-bearing rather than
# decorative — two sites in the scanned subject exercise it, the
# `<prefix>/claims.json` path mentions in CLAUDE.md and in
# references/publish-routing.md — so the case is green with it and red without
# it, which is what the second recorded recipe falsifies.
#
# THE PREFIX FILTER MIRRORS THAT GUARD'S load_registry CONTRACT deliberately.
# A colon-bearing entry would pass a bare truthiness filter and then be handed to
# a `grep` that could never match the bare-name form this case exists for — case
# 5 would keep printing PASS while guarding nothing. Rejecting those entries here
# keeps the vacuity visible rather than silent.
#
# EXTRACTION SCOPE. The extraction class deliberately excludes `<` and `>`, so
# the placeholder shape line `Route: <deliverable> · <producing_route>` is NOT
# collected. Widening the class to admit it would make the resolution case
# permanently red against correct text, since a placeholder resolves nowhere.
#
# THE TWO FIELDS ARE NOT THE SAME KIND OF TOKEN. Each example is
# `<deliverable> · <producing_route>`; only the SECOND field is a skill slug.
# The first is a deliverable id — `gtm-onepager` resolves to no
# `*/skills/gtm-onepager/SKILL.md` anywhere — so cases 2 and 3 key on the second
# field alone. A case resolving both tokens would be red even after a correct
# fix, and this guard would block its own change.
#
# RESOLUTION IS MARKETPLACE-ANCHORED ON PURPOSE. Case 2 resolves a slug against
# the plugins the manifest lists, not against whatever `*/skills/` trees happen
# to sit on disk. "Published" is the stronger claim and the one a reader of the
# example depends on: a route naming a real directory in an unlisted tree is
# still a route nobody can run. Do not simplify it to a glob.
#
# SCOPE OF EACH CASE. Cases 1-4 pin the `Route:` note, which is defined in one
# file, so they key on that file. Case 5's predicate is plugin-wide — a retired
# name is wrong in any authored prose the plugin ships — so it scans an
# ENUMERATED subject: every `skills/**/SKILL.md`, the plugin-root `README.md`
# and `CLAUDE.md`, and every `references/**/*.md`.
#
# What that subject leaves out, and why it is enumerated rather than globbed.
# `scripts/` and `tests/` are excluded because no lexical carve-out clears them
# on a CORRECT tree: one retired prefix is also a live workspace directory name,
# and after the trailing-slash carve-out 11 legitimate occurrences across three
# files still match — 8 of the form `mkdir -p "$VAR/<prefix>"`, where the path
# separator precedes the name and the line ends right after it; 2 that assemble
# the path across string-literal boundaries via `os.path.join`, so no separator
# sits adjacent in the source at all; and 1 bare mention in a comment. Including
# those trees would make the case permanently red against a correct tree, which
# is the failure this enumeration exists to avoid. `agents/` and
# `output-styles/` are authored prose too and are simply not covered yet.
# A whole-tree glob over `$PLUGIN_DIR` is also deliberately avoided: engagement
# directories live under `$PLUGIN_DIR/{slug}/`, so a glob would scan a user's
# own engagement content as if it were plugin source.
#
# Each case below is gated only on its OWN predicate and emits exactly one
# result line per run, so every `FAIL` arm has a reachable same-id green twin
# (cogni-knowledge/tests/README.md rule 7). Cases that iterate accumulate a
# per-case flag and report after the loop rather than emitting per iteration.

set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) PLUGIN_DIR="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

REPO_ROOT="$(cd "$PLUGIN_DIR/.." && pwd)"
SUBJECT="$PLUGIN_DIR/skills/consult-action-fields/SKILL.md"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
RETIRED="$REPO_ROOT/scripts/retired-plugins.json"

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s - %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

# The separator is U+00B7 MIDDLE DOT, matching the table cells it sits beside.
examples="$(grep -o 'Route: [A-Za-z0-9._-]* · [A-Za-z0-9._-]*' "$SUBJECT" 2>/dev/null || true)"
example_count="$(printf '%s\n' "$examples" | grep -c .)"

# Second field of each example — the producing_route slug.
route_tokens="$(printf '%s\n' "$examples" | sed 's/.* · //')"

# --- case 1: route-examples-found --------------------------------------------
# A vacuous scan must never read as success: with nothing extracted, cases 2-4
# would each pass by checking an empty set.
if [ "$example_count" -ge 2 ]; then
  pass "route-examples-found"
else
  fail "route-examples-found" "expected at least 2 Route: examples in $SUBJECT, found $example_count (vacuous scan)"
fi

# --- case 2: route-example-slug-resolves -------------------------------------
# Every route token resolves to a real skill under a marketplace-listed plugin.
plugin_dirs="$(python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as fh:
    data = json.load(fh)
for entry in data.get("plugins", []):
    source = entry.get("source")
    if not isinstance(source, str):
        continue
    cleaned = source.strip()
    if cleaned.startswith("./"):
        cleaned = cleaned[2:]
    cleaned = cleaned.rstrip("/")
    # Reject anything the repo-relative join below could not honour.
    if not cleaned or cleaned.startswith("/") or ":" in cleaned or ".." in cleaned:
        continue
    print(cleaned)
' "$MARKETPLACE" 2>/dev/null || true)"

if [ -z "$plugin_dirs" ]; then
  fail "route-example-slug-resolves" "no usable plugins[].source entries readable from $MARKETPLACE"
else
  unresolved=""
  for token in $route_tokens; do
    found=0
    for plugin in $plugin_dirs; do
      if [ -f "$REPO_ROOT/$plugin/skills/$token/SKILL.md" ]; then
        found=1
        break
      fi
    done
    [ "$found" -eq 1 ] || unresolved="$unresolved $token"
  done
  if [ -n "$unresolved" ]; then
    fail "route-example-slug-resolves" "route token(s) resolve to no */skills/<slug>/SKILL.md under any marketplace-listed plugin:$unresolved"
  else
    pass "route-example-slug-resolves"
  fi
fi

# --- case 3: route-example-non-default ---------------------------------------
# The Route: note is written only when producing_route DIFFERS from the default,
# so an example naming the default contradicts its own stated precondition.
defaulted=""
for token in $route_tokens; do
  [ "$token" = "consult-design-thinking" ] && defaulted="$defaulted $token"
done
if [ -n "$defaulted" ]; then
  fail "route-example-non-default" "Route: example names the default producing_route, which the note's own precondition excludes:$defaulted"
else
  pass "route-example-non-default"
fi

# --- case 4: route-example-parity --------------------------------------------
# The German render and the English convention example are defined as the same
# unlocalized Route: note line, so every extracted example must be identical.
# `-le 1` not `-eq 1`: an empty set is case 1's finding to report, not this one's.
if [ "$(printf '%s\n' "$examples" | sort -u | grep -c .)" -le 1 ]; then
  pass "route-example-parity"
else
  fail "route-example-parity" "Route: examples diverge; every occurrence must render identically to '$(printf '%s\n' "$examples" | head -n 1)'"
fi

# --- case 5: no-retired-plugin-name ------------------------------------------
# No retired plugin prefix may appear in any scanned body in this plugin — skill
# bodies, the plugin-root README.md and CLAUDE.md, and references/**/*.md — in a
# Route: note or in prose. An unreadable, empty, or malformed registry fails
# rather than passing silently.
retired_prefixes="$(python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as fh:
    data = json.load(fh)
prefixes = data.get("retired_prefixes")
if not isinstance(prefixes, list):
    sys.exit(1)
for prefix in prefixes:
    # Mirrors load_registry in scripts/check-external-dispatch.py: a blank,
    # padded, or colon-bearing entry cannot match the bare-name form this case
    # checks, so dropping it silently would make the case vacuous.
    if not isinstance(prefix, str) or not prefix.strip():
        sys.exit(1)
    if prefix != prefix.strip() or ":" in prefix:
        sys.exit(1)
    print(prefix)
' "$RETIRED" 2>/dev/null || true)"

# Every path derives from $PLUGIN_DIR, never a hardcoded one, so --root (above)
# still redirects the whole subject. Keep this list and $scan_desc below in step.
# The suite runs under `set -u` only — there is no `set -e` and no pipefail — so
# a find over a missing directory is inert here; do not add `set -e` without
# revisiting this.
scan_desc='skills/**/SKILL.md, README.md, CLAUDE.md, references/**/*.md'
scan_bodies="$({
  find "$PLUGIN_DIR/skills" -name SKILL.md -type f
  find "$PLUGIN_DIR/references" -name '*.md' -type f
  [ -f "$PLUGIN_DIR/README.md" ] && printf '%s\n' "$PLUGIN_DIR/README.md"
  [ -f "$PLUGIN_DIR/CLAUDE.md" ] && printf '%s\n' "$PLUGIN_DIR/CLAUDE.md"
} 2>/dev/null | sort)"

# A newly covered surface that has silently vanished must not read as success:
# the scan would narrow back toward the pre-widening subject and still print
# PASS. Each arm below names the missing surface. They stay in ONE if/elif chain
# so the case still emits exactly one result line per run.
missing_surface=""
[ -f "$PLUGIN_DIR/README.md" ] || missing_surface="$missing_surface README.md"
[ -f "$PLUGIN_DIR/CLAUDE.md" ] || missing_surface="$missing_surface CLAUDE.md"
[ -d "$PLUGIN_DIR/references" ] || missing_surface="$missing_surface references/"

if [ -z "$retired_prefixes" ]; then
  fail "no-retired-plugin-name" "no usable retired_prefixes[] readable from $RETIRED (vacuous scan)"
elif [ -n "$missing_surface" ]; then
  fail "no-retired-plugin-name" "scanned surface(s) absent under $PLUGIN_DIR:$missing_surface (vacuous scan of a newly covered surface)"
elif [ -z "$scan_bodies" ]; then
  fail "no-retired-plugin-name" "no scannable body found under $PLUGIN_DIR ($scan_desc) (vacuous scan)"
else
  present=""
  for prefix in $retired_prefixes; do
    # Bare-name match minus the directory-path carve-out: an occurrence
    # immediately followed by `/` is a filesystem path, not a route. See
    # DIRECTORY-VS-DISPATCH CARVE-OUT in the header for why the colon anchor
    # scripts/check-external-dispatch.py uses cannot be reused here.
    hits="$(printf '%s\n' "$scan_bodies" | tr '\n' '\0' \
      | xargs -0 grep -lE -- "$prefix"'([^/]|$)' 2>/dev/null || true)"
    [ -n "$hits" ] && present="$present $prefix"
  done
  if [ -n "$present" ]; then
    fail "no-retired-plugin-name" "retired plugin prefix(es) present in a $PLUGIN_DIR scanned body ($scan_desc):$present"
  else
    pass "no-retired-plugin-name"
  fi
fi

[ "$failures" = "0" ]
