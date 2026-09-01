#!/usr/bin/env bash
# test_resolve_wiki_scripts.sh - behaviour test for the shared wiki-engine resolver.
#
# Resolution is VENDORED-ONLY. cogni-knowledge ships the engine in-tree under
# scripts/vendor/cogni-wiki/; the plugin that tree was copied from is retired
# (absent from .claude-plugin/marketplace.json, registered in
# scripts/retired-plugins.json), so there is no external engine source. The
# former sibling-checkout and marketplace-cache probe branches were removed:
# resolving a stale, unversioned external copy would silently run an engine
# older than the plugin that called it, which is worse than failing loudly
# against the versioned copy that ships here.
#
# Cases 05/06/08 below are the standing ANTI-REGRESSION guard for that removal.
# They keep the external-layout fixtures on purpose and assert the resolver
# REFUSES them. Do not read them as support for a fallback — they exist to prove
# one cannot come back. (Before the removal these same fixtures asserted the
# opposite: F26's `sort -V` cache ranking and the sibling short-circuit. Both
# branches, and the ranking rule with them, are gone.)
#
# The resolver lives in ONE shared snippet (scripts/resolve-wiki-scripts.sh)
# that the knowledge-* flows source — there is no inline copy to drift. This
# test asserts the shared snippet defines the resolver; DERIVES the set of flows
# that call it by scanning skills/*/SKILL.md, rather than reading a list kept by
# hand; asserts per FENCE that a calling fence sources the snippet first; and
# drives the snippet body directly through the behaviour cases below.
#
# Cases (against the shared snippet body):
#   1. external marketplace-cache layout only        -> non-zero (refused)
#   2. external dev-repo sibling layout only         -> non-zero (refused)
#   3. nothing installed                             -> non-zero
#   4. partial vendor beside a COMPLETE sibling      -> non-zero (no fallthrough)
#   5. complete vendor                               -> the vendored dir wins
#   6. CLAUDE_PLUGIN_ROOT unset                      -> root derived from the
#      snippet's own sourced location (bash, system /bin/bash 3.2, zsh)
#
# bash 3.2 + stdlib only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# The scan root is overridable so the resolve-wiki-14 liveness arm is reachable:
# point it at an empty dir and the derived set is empty, which must go RED.
SKILLS_DIR="${RESOLVE_WIKI_SKILLS_DIR:-$PLUGIN_ROOT/skills}"
RESOLVER_SNIPPET="$PLUGIN_ROOT/scripts/resolve-wiki-scripts.sh"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# The behavioural cases exercise the SHIPPED code by sourcing the one shared
# snippet directly — no extraction from a SKILL.md, no hand-maintained copy.
extract_resolver() {
  cat "$RESOLVER_SNIPPET"
}

# -----------------------------------------------------------------------------
# Part 1: contract — the shared snippet defines a VENDORED-ONLY resolver, and
#         every DERIVED call site sources it rather than carrying an inline copy
#         (the de-duplication invariant: one source of truth).
#
#         Comments are stripped before the external-probe scan: the snippet
#         documents the removal in a "do not reintroduce a sibling or
#         marketplace-cache probe" warning, so a raw scan would red the moment
#         that warning was made concrete. Case 12 of
#         test_knowledge_wiki_probe.sh strips for the same reason.
# -----------------------------------------------------------------------------

if [ ! -f "$RESOLVER_SNIPPET" ]; then
  red "FAIL: resolve-wiki-01 shared resolver snippet not found: $RESOLVER_SNIPPET"; errors=$((errors + 1))
elif ! grep -qE 'resolve_wiki_scripts\(\) \{' "$RESOLVER_SNIPPET"; then
  red "FAIL: resolve-wiki-01 shared snippet missing resolve_wiki_scripts() definition"; errors=$((errors + 1))
elif sed 's/#.*//' "$RESOLVER_SNIPPET" | grep -qE '\.\./cogni-wiki|sort -V'; then
  red "FAIL: resolve-wiki-01 shared snippet carries an external cogni-wiki probe (sibling path or version-ranking glob) — resolution must be vendored-only"; errors=$((errors + 1))
else
  green "PASS: resolve-wiki-01 shared snippet defines a vendored-only resolver with no external cogni-wiki probe"
fi

# The graded population is DERIVED from the tree, never enumerated here: every
# skills/*/SKILL.md is scanned, and a skill enters the set by calling
# resolve_wiki_scripts inside a fenced block. A newly-calling skill is therefore
# graded on its first run with no edit to this file — the hand-maintained list
# this replaced had drifted to 8 names while 13 skills called the resolver.
#
# The sourcing decision is per FENCE, not per file. A source line only vouches
# for the fence it sits in, so a file that sources in one fence and calls in
# another is an offender — that whole-file read is what let a broken fence pass.
# Three details are load-bearing:
#   - the fence opener tolerates leading whitespace, because a fence nested under
#     a numbered step is indented (knowledge-index indents its resolver fence);
#   - the call detector keys on the UNDERSCORE spelling resolve_wiki_scripts,
#     while the source line names the HYPHENATED resolve-wiki-scripts.sh, so a
#     sourcing line can never satisfy itself as its own call site;
#   - nothing outside a fence is inspected, so a backtick-quoted mention in a
#     prose sentence is not graded as a call.
#
# Per tests/README.md rule 7 this is collect-then-pair: offenders accumulate
# across the loop and a single same-id if/else fires after it closes. Emitting
# per-file would collide knowledge-refresh's three calling fences (and
# knowledge-distill's two) onto one id.

scanned_count=0
calling_count=0
nosrc_offenders=""
inline_def_offenders=""
uncovered_offenders=""

for skill_file in "$SKILLS_DIR"/*/SKILL.md; do
  [ -f "$skill_file" ] || continue
  skill_dir=${skill_file%/SKILL.md}
  name=${skill_dir##*/}
  scanned_count=$((scanned_count + 1))

  # The fence-scoped pass. It emits only BARE records — never a PASS:/FAIL:
  # label — so every result line in this suite still originates at a red/green
  # call and stays visible to scripts/check-case-id-pairing.py:
  #   CALL  <skill>                    once per file that has any fenced call
  #   NOSRC <skill>:<fence-open-line>  once per calling fence with no earlier
  #                                    in-fence source of the shared snippet
  scan=$(awk -v skill="$name" '
    /^[ \t]*```/ {
      inf = !inf
      if (inf) { hassource = 0; reported = 0; fl = NR }
      next
    }
    inf && /^[ \t]*(\.|source)[ \t]+.*resolve-wiki-scripts\.sh/ { hassource = 1; next }
    inf && /resolve_wiki_scripts/ {
      calls = 1
      if (!hassource && !reported) { reported = 1; print "NOSRC " skill ":" fl }
    }
    END { if (calls) print "CALL " skill }
  ' "$skill_file")

  file_calls=no
  case "$scan" in *"CALL $name"*) file_calls=yes ;; esac
  if [ "$file_calls" = yes ]; then
    calling_count=$((calling_count + 1))
  fi

  # Appending the empty string is a no-op, so this needs no emptiness guard.
  nosrc_offenders="$nosrc_offenders$(printf '%s\n' "$scan" | sed -n 's/^NOSRC /  /p' | tr '\n' ' ')"

  if grep -qE 'resolve_wiki_scripts\(\) \{' "$skill_file"; then
    inline_def_offenders="$inline_def_offenders $name"
  fi

  # A file that names the resolver but yields no derived call site is graded by
  # nothing — the silent-shrink failure a derived population can still suffer.
  if [ "$file_calls" = no ] && grep -q 'resolve_wiki_scripts' "$skill_file"; then
    uncovered_offenders="$uncovered_offenders $name"
  fi
done

# A scan that discovers nothing exits green while grading nothing, which is the
# same green-and-dead shape this suite exists to prevent. This is a pure vacuity
# check against ZERO, deliberately not a minimum count: a floor would be the
# hand-maintained census this file just deleted, compressed into one number, and
# would red a legitimate consolidation that is not a defect. The anti-shrink
# direction is resolve-wiki-17's job, and it keys off the tree rather than a
# literal.
if [ "$scanned_count" -eq 0 ]; then
  red "FAIL: resolve-wiki-14 no SKILL.md found under $SKILLS_DIR — the scan graded nothing"; errors=$((errors + 1))
elif [ "$calling_count" -eq 0 ]; then
  red "FAIL: resolve-wiki-14 scanned $scanned_count SKILL.md file(s) but derived no call site at all — the scan is broken, not the tree"; errors=$((errors + 1))
else
  green "PASS: resolve-wiki-14 derived $calling_count calling skill(s) from $scanned_count SKILL.md file(s)"
fi

if [ -n "$nosrc_offenders" ]; then
  red "FAIL: resolve-wiki-15 fence(s) call resolve_wiki_scripts with no source of resolve-wiki-scripts.sh earlier in that same fence (skill:fence-open-line):$nosrc_offenders"; errors=$((errors + 1))
else
  green "PASS: resolve-wiki-15 every derived calling fence sources the shared snippet earlier in that same fence"
fi

if [ -n "$inline_def_offenders" ]; then
  red "FAIL: resolve-wiki-16 skill(s) still carry an inline resolve_wiki_scripts() definition instead of sourcing the snippet:$inline_def_offenders"; errors=$((errors + 1))
else
  green "PASS: resolve-wiki-16 no skill carries an inline resolve_wiki_scripts() definition"
fi

if [ -n "$uncovered_offenders" ]; then
  red "FAIL: resolve-wiki-17 skill(s) name resolve_wiki_scripts but contributed no derived call site, so they are graded by nothing:$uncovered_offenders"; errors=$((errors + 1))
else
  green "PASS: resolve-wiki-17 every skill naming resolve_wiki_scripts contributes at least one derived fenced call site"
fi

# -----------------------------------------------------------------------------
# Part 2: behaviour — run the shared snippet body against synthetic layouts.
# -----------------------------------------------------------------------------

# The shared snippet is the single source of truth every derived call site
# sources, so the behaviour cases below drive its body directly.
INGEST_BODY=$(extract_resolver)
if [ -z "$INGEST_BODY" ]; then
  red "FAIL: resolve-wiki-04 could not read resolve_wiki_scripts() body from the shared snippet"
  errors=$((errors + 1))
else
  green "PASS: resolve-wiki-04 read the resolve_wiki_scripts() body from the shared snippet"
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Multi-version marketplace cache + two stray non-numeric dirs. CLAUDE_PLUGIN_ROOT
# points at $WORK/cache/cogni-knowledge/0.1.1; siblings at
# $WORK/cache/cogni-wiki/<dir>/skills/wiki-ingest/scripts.
mkdir -p "$WORK/cache/cogni-knowledge/0.1.1"
for v in 0.0.9 0.0.16 0.0.45 main latest; do
  mkdir -p "$WORK/cache/cogni-wiki/$v/skills/wiki-ingest/scripts"
done

# Dev-repo sibling layout.
mkdir -p "$WORK/devrepo/cogni-knowledge"
mkdir -p "$WORK/devrepo/cogni-wiki/skills/wiki-ingest/scripts"

# Nothing installed.
mkdir -p "$WORK/missing/cogni-knowledge"

RESOLVE_BODY="$INGEST_BODY
if resolve_wiki_scripts wiki-ingest; then exit 0; else exit 1; fi"

run_resolve() {
  CLAUDE_PLUGIN_ROOT="$1" bash -c "$RESOLVE_BODY"
}

# Case 1 (INVERTED — anti-regression): an external marketplace-cache layout,
# multi-version and complete, must be REFUSED. Before the removal this asserted
# F26's `sort -V` ranking picked 0.0.45; a stale cached engine is now never
# preferable to failing loudly against the versioned vendored copy.
if OUT=$(run_resolve "$WORK/cache/cogni-knowledge/0.1.1" 2>&1); then
  red "FAIL: resolve-wiki-05 external marketplace-cache layout resolved — the removed cache probe is back"
  red "  got: $OUT"; errors=$((errors + 1))
else
  green "PASS: resolve-wiki-05 external marketplace-cache layout is refused (vendored-only)"
fi

# Case 2 (INVERTED — anti-regression): an external dev-repo sibling layout
# (<CPR>/../cogni-wiki/skills/...) must be REFUSED. Before the removal this
# asserted the sibling branch won and short-circuited the cache glob.
if OUT=$(run_resolve "$WORK/devrepo/cogni-knowledge" 2>&1); then
  red "FAIL: resolve-wiki-06 external dev-repo sibling layout resolved — the removed sibling probe is back"
  red "  got: $OUT"; errors=$((errors + 1))
else
  green "PASS: resolve-wiki-06 external dev-repo sibling layout is refused (vendored-only)"
fi

# Case 3: nothing installed -> non-zero exit.
if run_resolve "$WORK/missing/cogni-knowledge" >/dev/null 2>&1; then
  red "FAIL: resolve-wiki-07 resolver returned success with no vendored engine present"; errors=$((errors + 1))
else
  green "PASS: resolve-wiki-07 resolver returns non-zero when the vendored engine is absent"
fi

# -----------------------------------------------------------------------------
# Part 3: entry-point existence — the VENDOR INTEGRITY guard. With the optional
#         2nd arg the probe wins ONLY when the expected entry-point script is
#         present, so a partial vendor (dir copied, script missed) is caught here
#         rather than surfacing as a missing-script error deep in a run. With no
#         fallback branch left this is the ONLY probe hardening, so it is
#         load-bearing. Drives the SAME extracted ingest body, two-arg form.
# -----------------------------------------------------------------------------

RESOLVE_BODY_EP="$INGEST_BODY
if resolve_wiki_scripts wiki-ingest backlink_audit.py; then exit 0; else exit 1; fi"

run_resolve_ep() { CLAUDE_PLUGIN_ROOT="$1" bash -c "$RESOLVE_BODY_EP"; }

# Case 4 (INVERTED — anti-regression): a partial vendor (dir present,
# backlink_audit.py ABSENT) next to a COMPLETE external sibling must return
# non-zero. Before the removal the sibling won here. Now a broken vendor fails
# loudly rather than silently handing the run a stale external engine — this is
# the case that proves the entry-point guard did NOT survive as a fallthrough.
PART="$WORK/partial"
mkdir -p "$PART/cogni-knowledge/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"  # vendor: no script
mkdir -p "$PART/cogni-wiki/skills/wiki-ingest/scripts"                                  # sibling...
: > "$PART/cogni-wiki/skills/wiki-ingest/scripts/backlink_audit.py"                     # ...with the script
if OUT=$(run_resolve_ep "$PART/cogni-knowledge" 2>&1); then
  red "FAIL: resolve-wiki-08 partial vendor fell through to the external sibling — the removed fallthrough is back"
  red "  got: $OUT"; errors=$((errors + 1))
else
  green "PASS: resolve-wiki-08 partial vendor beside a complete external sibling returns non-zero (no fallthrough)"
fi

# Case 5: complete vendor (dir + entry-point present) -> vendor wins.
COMPLETE="$WORK/complete"
mkdir -p "$COMPLETE/cogni-knowledge/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"
: > "$COMPLETE/cogni-knowledge/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts/backlink_audit.py"
if OUT=$(run_resolve_ep "$COMPLETE/cogni-knowledge"); then
  case "$OUT" in
    */scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts)
      green "PASS: resolve-wiki-09 complete vendor (dir + entry-point) wins the probe" ;;
    *)
      red "FAIL: resolve-wiki-09 complete vendor did not win (got: $OUT)"; errors=$((errors + 1)) ;;
  esac
else
  red "FAIL: resolve-wiki-09 complete-vendor resolver returned non-zero"; errors=$((errors + 1))
fi

# Case 6: vendor dir + sibling dir present but NEITHER carries the script ->
# non-zero (the partial-everything case the dir-only probe would have masked).
NONE="$WORK/partialnone"
mkdir -p "$NONE/cogni-knowledge/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"
mkdir -p "$NONE/cogni-wiki/skills/wiki-ingest/scripts"
if run_resolve_ep "$NONE/cogni-knowledge" >/dev/null 2>&1; then
  red "FAIL: resolve-wiki-10 entry-point resolver returned success when no dir carries the script"; errors=$((errors + 1))
else
  green "PASS: resolve-wiki-10 no dir carrying the entry-point -> resolver returns non-zero"
fi

# -----------------------------------------------------------------------------
# Part 4: unset CLAUDE_PLUGIN_ROOT — the resolver derives the plugin root from
#         its own sourced location (_RESOLVE_WIKI_SCRIPTS_ROOT, captured at
#         SOURCE time from BASH_SOURCE[0]:-$0). Nested-skill Bash blocks do not
#         inherit the env var, so this derivation is load-bearing and survives
#         the fallback removal untouched. The snippet must be sourced BY FILE
#         PATH here: a `bash -c` inlined body (Parts 2-3) has an empty
#         BASH_SOURCE, which would mask the derivation.
#
#         The fixture is a VENDORED tree under the derived root. It used to be a
#         marketplace-cache layout, which no longer resolves at all.
# -----------------------------------------------------------------------------

UNSET_ROOT="$WORK/unset-root/cogni-knowledge"
mkdir -p "$UNSET_ROOT/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"
cp "$RESOLVER_SNIPPET" "$UNSET_ROOT/scripts/resolve-wiki-scripts.sh"

# Case 7: bash, CLAUDE_PLUGIN_ROOT unset -> source-location root, vendored dir.
if OUT=$(env -u CLAUDE_PLUGIN_ROOT bash -c ". '$UNSET_ROOT/scripts/resolve-wiki-scripts.sh'; resolve_wiki_scripts wiki-ingest"); then
  case "$OUT" in
    */scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts)
      green "PASS: resolve-wiki-11 unset CLAUDE_PLUGIN_ROOT derives the root from the script's own location" ;;
    *)
      red "FAIL: resolve-wiki-11 unset-env run resolved the wrong dir"
      red "  got: $OUT"; errors=$((errors + 1)) ;;
  esac
else
  red "FAIL: resolve-wiki-11 resolver returned non-zero with CLAUDE_PLUGIN_ROOT unset (source-location derivation did not engage)"; errors=$((errors + 1))
fi

# Case 7b: the snippet must parse + resolve under the SYSTEM bash (macOS ships
# /bin/bash 3.2, whose parser rejects closing-paren-only case patterns inside
# $(...) — the suite's plain `bash` resolves to a newer Homebrew bash, which
# masked exactly that regression). Runs only where /bin/bash exists.
if [ -x /bin/bash ]; then
  if OUT=$(env -u CLAUDE_PLUGIN_ROOT /bin/bash -c ". '$UNSET_ROOT/scripts/resolve-wiki-scripts.sh'; resolve_wiki_scripts wiki-ingest" 2>&1); then
    case "$OUT" in
      */scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts)
        green "PASS: resolve-wiki-12 system /bin/bash (3.2 on macOS) parses and resolves the snippet" ;;
      *)
        red "FAIL: resolve-wiki-12 system /bin/bash run produced unexpected output"
        red "  got: $OUT"; errors=$((errors + 1)) ;;
    esac
  else
    red "FAIL: resolve-wiki-12 system /bin/bash could not source/resolve the snippet (3.2 parser regression?): $OUT"; errors=$((errors + 1))
  fi
else
  green "PASS: resolve-wiki-12 /bin/bash not present on this host — system-bash case skipped"
fi

# Case 8: same shape under zsh — the originally-reported failure environment
# (zsh aborts a sourced block on an unmatched glob). Runs only where zsh exists.
if command -v zsh >/dev/null 2>&1; then
  if OUT=$(env -u CLAUDE_PLUGIN_ROOT zsh -c ". '$UNSET_ROOT/scripts/resolve-wiki-scripts.sh'; resolve_wiki_scripts wiki-ingest" 2>&1); then
    case "$OUT" in
      */scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts)
        green "PASS: resolve-wiki-13 zsh + unset CLAUDE_PLUGIN_ROOT resolves without aborting" ;;
      *)
        red "FAIL: resolve-wiki-13 zsh unset-env run produced unexpected output"
        red "  got: $OUT"; errors=$((errors + 1)) ;;
    esac
  else
    red "FAIL: resolve-wiki-13 zsh aborted with CLAUDE_PLUGIN_ROOT unset (the reported bug): $OUT"; errors=$((errors + 1))
  fi
else
  green "PASS: resolve-wiki-13 zsh not available on this host — zsh case skipped (bash case 7 covers the derivation)"
fi

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "resolve_wiki_scripts vendored-only contract and behaviour all pass."
