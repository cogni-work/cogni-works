#!/usr/bin/env bash
# test_probe_plugin_fence.sh - population-derived, per-fence probe_plugin guard.
#
# A skill's fenced Bash blocks do not share shell state. A fence that CALLS
# probe_plugin must therefore define it -- or source a file that does -- inside
# that same fence, or the call is a standalone exit-127 at run time. One suite
# already asserts that property, but only for the single file it names by hand.
# This one derives the graded population from the tree instead: every
# skills/*/SKILL.md is scanned, and a skill enters the set by calling
# probe_plugin inside a fence. A newly-calling skill is graded on its first run
# with no edit here, which is the drift a hand-named subject cannot survive.
#
# Three scanning properties are load-bearing, each for a stated reason:
#
#   - The fence opener tolerates leading whitespace. A fence nested under a
#     numbered step is indented, and an anchored opener would stop toggling
#     there and grade the rest of the file as one flat blob.
#
#   - The call detector matches ANY in-fence line naming probe_plugin, not just
#     a bare-literal first argument. A detector keyed on an alphabetic argument
#     misses the quoted-variable form, which is precisely the next consumer a
#     derived population is supposed to catch for free.
#
#     That widening removes the property that would otherwise let the definition
#     rule fall through: `probe_plugin() {` also names probe_plugin. So the
#     definition rule ends in `next`, keeping a def-only fence out of the call
#     set. Without it, hasdef would always imply hascall, the orphan branch
#     would be unreachable for every possible input, and case 03's FAIL arm
#     would be dead while both arms stayed statically present -- which the
#     case-id pairing guard cannot see.
#
#   - An inline definition SHORT-CIRCUITS the source path. Both the no-source
#     and the sourced verdicts are gated on `hascall && !hasdef`, so a fence
#     that defines probe_plugin inline is clean and its source lines are never
#     resolved. The sole live consumer sources a wiki-engine resolver that does
#     not define probe_plugin; adjudicating on that source would red this suite
#     against a correct tree.
#
# Case 01 is a vacuity floor on the SCANNED count only. It deliberately does
# NOT red on a zero call count, unlike the sibling suite it is modelled on: that
# sibling grades a thirteen-skill population, where zero callers can only mean a
# broken scan, whereas the population here is one, and a legitimate removal of
# the sole consumer must not force an edit to this file. The scan-is-broken
# direction is case 04's job instead, and it keys off the tree: a skill whose
# text names probe_plugin while yielding no derived call site is graded by
# nothing, which is the failure a shrinking population actually produces.
#
# Cases 05-09 drive the SAME scan_file() against synthetic fixtures, so a
# self-test can never diverge from what grades the tree. They are what proves
# the detector discriminates rather than always agreeing.
#
# bash 3.2 + stdlib only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# The scan root is overridable so case 01's liveness arm is reachable: point it
# at an empty dir and the derived set is empty, which must go RED.
SKILLS_DIR="${PROBE_PLUGIN_FENCE_SKILLS_DIR:-$PLUGIN_ROOT/skills}"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# The fence-scoped pass. Emits only BARE records -- never a PASS:/FAIL: label --
# so every result line in this suite still originates at a red/green call and
# stays visible to scripts/check-case-id-pairing.py:
#   CALL   <skill>                     once per file with any fenced call
#   NODEF  <skill>:<fence-open-line>   calling fence, no def, no source at all
#   SRC    <skill>:<fence-open-line> <token>
#                                      calling fence, no def, one record per
#                                      buffered source token for the shell to
#                                      adjudicate
#   ORPHAN <skill>:<fence-open-line>   fence defines probe_plugin, never calls it
#
# Rule ORDER is load-bearing and the two `next` statements are not optional --
# see the header. Rule 4 is the catch-all, reached only by lines rules 2 and 3
# did not consume.
scan_file() {
  awk -v skill="$2" '
    /^[ \t]*```/ {
      if (inf) {
        if (hascall) {
          calls = 1
          if (!hasdef) {
            if (nsrc == 0) print "NODEF " skill ":" fl
            else for (i = 1; i <= nsrc; i++) print "SRC " skill ":" fl " " src[i]
          }
        } else if (hasdef) {
          print "ORPHAN " skill ":" fl
        }
      }
      inf = !inf
      if (inf) { hasdef = 0; hascall = 0; nsrc = 0; fl = NR }
      next
    }
    inf && /probe_plugin\(\)[ \t]*\{/ { hasdef = 1; next }
    inf && /^[ \t]*(\.|source)[ \t]+/ {
      for (i = 1; i <= NF; i++) {
        if ($i == "." || $i == "source") { nsrc = nsrc + 1; src[nsrc] = $(i + 1); break }
      }
      next
    }
    inf && /probe_plugin/ { hascall = 1 }
    END { if (calls) print "CALL " skill }
  ' "$1"
}

# Does the file a buffered source token names define probe_plugin? The token
# arrives as awk read it, so surrounding quotes and a CLAUDE_PLUGIN_ROOT prefix
# are still on it. An unresolvable path is deliberately NOT satisfying: a fence
# whose only vouching source cannot be read is vouched for by nothing.
src_defines_probe() {
  sp_path=$(printf '%s' "$1" | tr -d "\"'" | sed -e "s|[\$]{CLAUDE_PLUGIN_ROOT}|$2|g" -e "s|[\$]CLAUDE_PLUGIN_ROOT|$2|g")
  [ -f "$sp_path" ] || return 1
  grep -qE 'probe_plugin\(\)[ \t]*\{' "$sp_path"
}

# Turn one file's scan into space-joined offender tokens for case 02: every
# NODEF fence, plus every sourced fence where no buffered source resolves to a
# file defining probe_plugin.
adjudicate_nodef() {
  an_scan=$1
  an_root=$2
  printf '%s\n' "$an_scan" | sed -n 's/^NODEF /  /p' | tr '\n' ' '
  an_keys=$(printf '%s\n' "$an_scan" | sed -n 's/^SRC \([^ ]*\) .*/\1/p' | LC_ALL=C sort -u)
  for an_key in $an_keys; do
    an_ok=no
    for an_tok in $(printf '%s\n' "$an_scan" | awk -v k="$an_key" '$1 == "SRC" && $2 == k { print $3 }'); do
      if src_defines_probe "$an_tok" "$an_root"; then
        an_ok=yes
      fi
    done
    if [ "$an_ok" = no ]; then
      printf '  %s ' "$an_key"
    fi
  done
}

# -----------------------------------------------------------------------------
# Part 1: the derived population.
#
# Per tests/README.md rule 7 this is collect-then-pair: offenders accumulate
# across the loop and a single same-id if/else fires after it closes. Emitting
# per-file would collide several fences of one skill onto one id.
# -----------------------------------------------------------------------------

scanned_count=0
calling_count=0
nodef_offenders=""
orphan_offenders=""
uncovered_offenders=""

for skill_file in "$SKILLS_DIR"/*/SKILL.md; do
  [ -f "$skill_file" ] || continue
  skill_dir=${skill_file%/SKILL.md}
  name=${skill_dir##*/}
  scanned_count=$((scanned_count + 1))

  scan=$(scan_file "$skill_file" "$name")

  file_calls=no
  case "$scan" in *"CALL $name"*) file_calls=yes ;; esac
  if [ "$file_calls" = yes ]; then
    calling_count=$((calling_count + 1))
  fi

  # Appending the empty string is a no-op, so this needs no emptiness guard.
  nodef_offenders="$nodef_offenders$(adjudicate_nodef "$scan" "$PLUGIN_ROOT")"
  orphan_offenders="$orphan_offenders$(printf '%s\n' "$scan" | sed -n 's/^ORPHAN /  /p' | tr '\n' ' ')"

  if [ "$file_calls" = no ] && grep -q 'probe_plugin' "$skill_file"; then
    uncovered_offenders="$uncovered_offenders $name"
  fi
done

# A scan that discovers no file at all exits green while grading nothing, which
# is the green-and-dead shape this suite exists to prevent. Scanned-count only --
# see the header for why a zero CALL count is deliberately not red here.
if [ "$scanned_count" -eq 0 ]; then
  red "FAIL: probe-plugin-fence-01 no SKILL.md found under $SKILLS_DIR — the scan graded nothing"; errors=$((errors + 1))
else
  green "PASS: probe-plugin-fence-01 scanned $scanned_count SKILL.md file(s), deriving $calling_count with a fenced probe_plugin call"
fi

if [ -n "$nodef_offenders" ]; then
  red "FAIL: probe-plugin-fence-02 fence(s) call probe_plugin without defining it, or sourcing a file that defines it, in that same fence (skill:fence-open-line):$nodef_offenders"; errors=$((errors + 1))
else
  green "PASS: probe-plugin-fence-02 every derived calling fence defines probe_plugin, or sources a file that does, in that same fence"
fi

if [ -n "$orphan_offenders" ]; then
  red "FAIL: probe-plugin-fence-03 fence(s) define probe_plugin but never call it in that same fence (skill:fence-open-line):$orphan_offenders"; errors=$((errors + 1))
else
  green "PASS: probe-plugin-fence-03 no fence defines probe_plugin without calling it"
fi

if [ -n "$uncovered_offenders" ]; then
  red "FAIL: probe-plugin-fence-04 skill(s) name probe_plugin but contributed no derived fenced call site, so they are graded by nothing:$uncovered_offenders"; errors=$((errors + 1))
else
  green "PASS: probe-plugin-fence-04 every skill naming probe_plugin contributes at least one derived fenced call site"
fi

# -----------------------------------------------------------------------------
# Part 2: self-tests. These drive the SAME scan_file() and adjudicate_nodef() the
#         loop above uses, so a detector that stops discriminating cannot pass
#         here while still reporting the live tree clean.
# -----------------------------------------------------------------------------

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# A snippet that DOES define probe_plugin, and one that does not.
cat > "$WORK/defines.sh" <<'SNIPPET'
probe_plugin() {
  return 1
}
SNIPPET
cat > "$WORK/silent.sh" <<'SNIPPET'
resolve_something() {
  return 1
}
SNIPPET

# Fixture 05: calls with a QUOTED VARIABLE argument, no definition. This is also
# what proves the widened call detector -- a bare-literal-argument detector
# would not match this line at all, and the case would go green while blind.
cat > "$WORK/fx05.md" <<'FIXTURE'
Prose above the fence.

```
probe_plugin "$plugin" claims && OK=yes || OK=no
```
FIXTURE

# Fixture 06: defines, never calls.
cat > "$WORK/fx06.md" <<'FIXTURE'
```
probe_plugin() {
  return 1
}
```
FIXTURE

# Fixture 07: defines and calls in one fence, indented under a numbered step so
# the whitespace-tolerant fence opener is exercised too.
cat > "$WORK/fx07.md" <<'FIXTURE'
1. Do the thing:

   ```
   probe_plugin() {
     return 1
   }
   probe_plugin cogni-workspace claims && OK=yes || OK=no
   ```
FIXTURE

# Fixture 08: calls, does not define, sources a snippet that DOES define.
cat > "$WORK/fx08.md" <<'FIXTURE'
```
source "${CLAUDE_PLUGIN_ROOT}/defines.sh"
probe_plugin cogni-workspace claims && OK=yes || OK=no
```
FIXTURE

# Fixture 09: calls, does not define, sources a file that does NOT define.
cat > "$WORK/fx09.md" <<'FIXTURE'
```
source "${CLAUDE_PLUGIN_ROOT}/silent.sh"
probe_plugin cogni-workspace claims && OK=yes || OK=no
```
FIXTURE

fx05=$(scan_file "$WORK/fx05.md" fx05)
case "$fx05" in
  *"NODEF fx05:"*)
    green "PASS: probe-plugin-fence-05 a fence calling probe_plugin with a quoted-variable argument and no definition is reported" ;;
  *)
    red "FAIL: probe-plugin-fence-05 quoted-variable call with no definition was not reported (got: $fx05)"; errors=$((errors + 1)) ;;
esac

fx06=$(scan_file "$WORK/fx06.md" fx06)
case "$fx06" in
  *"ORPHAN fx06:"*)
    green "PASS: probe-plugin-fence-06 a fence defining probe_plugin without calling it is reported as an orphan" ;;
  *)
    red "FAIL: probe-plugin-fence-06 orphan definition was not reported — the definition line is likely also setting the call flag (got: $fx06)"; errors=$((errors + 1)) ;;
esac

fx07=$(scan_file "$WORK/fx07.md" fx07)
fx07_bad=$(printf '%s\n' "$fx07" | grep -c '^NODEF\|^ORPHAN\|^SRC' || true)
case "$fx07" in
  *"CALL fx07"*)
    if [ "$fx07_bad" -eq 0 ]; then
      green "PASS: probe-plugin-fence-07 an indented fence defining and calling probe_plugin yields one call site and no offender"
    else
      red "FAIL: probe-plugin-fence-07 indented define-and-call fence produced $fx07_bad offender record(s) (got: $fx07)"; errors=$((errors + 1))
    fi ;;
  *)
    red "FAIL: probe-plugin-fence-07 indented define-and-call fence derived no call site — the fence opener is not whitespace-tolerant (got: $fx07)"; errors=$((errors + 1)) ;;
esac

fx08=$(scan_file "$WORK/fx08.md" fx08)
fx08_off=$(adjudicate_nodef "$fx08" "$WORK")
if [ -z "$fx08_off" ]; then
  green "PASS: probe-plugin-fence-08 a calling fence sourcing a snippet that defines probe_plugin is accepted"
else
  red "FAIL: probe-plugin-fence-08 a calling fence sourcing a defining snippet was reported as an offender:$fx08_off"; errors=$((errors + 1))
fi

fx09=$(scan_file "$WORK/fx09.md" fx09)
fx09_off=$(adjudicate_nodef "$fx09" "$WORK")
if [ -n "$fx09_off" ]; then
  green "PASS: probe-plugin-fence-09 a calling fence sourcing a file that does not define probe_plugin is reported"
else
  red "FAIL: probe-plugin-fence-09 a calling fence sourcing a non-defining file was accepted"; errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "probe_plugin per-fence co-location contract holds across the derived population."
