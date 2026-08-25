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
# Which mutation reddens which case:
#   route-examples-found         deleting both `Route:` example lines
#   route-example-slug-resolves  s/narrative-adapt/cogni-visual/g  (the recorded recipe)
#   route-example-non-default    s/narrative-adapt/consult-design-thinking/g
#   route-example-parity         changing the route token at one site only
#   no-retired-plugin-name       reintroducing any prefix from retired-plugins.json
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
# name is wrong in any skill body — so it scans every skill in the plugin.
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
# No retired plugin prefix may appear in any skill body in this plugin, in a
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

skill_bodies="$(find "$PLUGIN_DIR/skills" -name SKILL.md -type f 2>/dev/null | sort)"

if [ -z "$retired_prefixes" ]; then
  fail "no-retired-plugin-name" "no usable retired_prefixes[] readable from $RETIRED (vacuous scan)"
elif [ -z "$skill_bodies" ]; then
  fail "no-retired-plugin-name" "no SKILL.md found under $PLUGIN_DIR/skills (vacuous scan)"
else
  present=""
  for prefix in $retired_prefixes; do
    hits="$(printf '%s\n' "$skill_bodies" | while IFS= read -r body; do
      grep -l -- "$prefix" "$body" 2>/dev/null || true
    done)"
    [ -n "$hits" ] && present="$present $prefix"
  done
  if [ -n "$present" ]; then
    fail "no-retired-plugin-name" "retired plugin prefix(es) present in a $PLUGIN_DIR skill body:$present"
  else
    pass "no-retired-plugin-name"
  fi
fi

[ "$failures" = "0" ]
