#!/usr/bin/env bash
# test_check_retirement_ledger.sh — self-test for the retirement-ledger gate.
#
# The gate asserts one invariant: when a branch DELETES a
# cogni-workspace/skills/<name>/SKILL.md, every trigger phrase that file
# advertised at the MERGE BASE must be accounted for at HEAD — re-claimed by a
# surviving live skill, or recorded in the retirement ledger with a non-empty
# reason.
#
# Cases:
#   1. delete a skill, write no ledger row -> retirement-row-missing, exit 1.
#      [retirement-ledger-01-missing-row]  <- the mutation-recipe target
#   2. delete a skill, all phrases recorded retired with reasons -> clean, 0.
#      [retirement-ledger-02-recorded-retired]
#   3. delete a skill whose phrases a SURVIVING skill re-quotes -> clean, 0.
#      [retirement-ledger-03-reclaimed-by-survivor]
#   4. a branch that deletes no skill at all -> clean, 0.
#      [retirement-ledger-04-no-deletion]
#   5. no refs/remotes/origin/main -> status degraded, exit 0. A guard that
#      cannot see the baseline must not block every PR on a shallow runner.
#      [retirement-ledger-05-degraded-no-origin]
#   6. main advanced past the fork and deleted a skill of its OWN; the branch
#      deleted nothing -> clean. This is the merge-base-anchoring regression
#      test: a base-TIP anchor would read main's deletion as the branch's and
#      false-flag it. [retirement-ledger-06-merge-base-anchoring]
#   7. two phrases, one recorded and one not -> exactly ONE violation, exit 1.
#      Proves the guard reports per phrase, not per file.
#      [retirement-ledger-07-partial-accounting]
#   8. a ledger row exists but its reason is empty -> does NOT account, exit 1.
#      The documented remedy is recording the retirement WITH a justification.
#      [retirement-ledger-08-empty-reason]
#   9. the deleted skill used a `>-` block scalar -> its phrases are still
#      extracted and still demanded, proving the YAML unwrap runs before the
#      quote hunt. [retirement-ledger-09-block-scalar]
#  10. --emit-phrases spawns no git subprocess, so C11 cannot redden the shallow
#      plugin-test-suites job. [retirement-ledger-10-emit-phrases-no-git]
#  11. the deleted skill could not be PARSED at the merge base -- no frontmatter
#      block (arm a), and a block with no `description:` key (arm b). Both must
#      raise base-blob-unparseable and exit 1, never a silent zero-phrase skip
#      that reports clean. [retirement-ledger-11-unparseable-base-blob]
#  12. one deletion of each kind in one branch -> both codes report together.
#      [retirement-ledger-12-mixed-violation-kinds]
#
# bash 3.2 + stdlib python3 + git. No network.
#
# Every case builds its OWN git fixture repo — no case runs the gate against the
# real checked-out tree, so the deliberately shallow plugin-test-suites job
# (.github/workflows/lint.yml) cannot redden on a missing base ref.
#
# Result-line ids: every emitted PASS:/FAIL: line carries a first-token id in the
# repo-root <suite-slug>-<NN>[-<discriminator>] shape documented in CLAUDE.md —
# deliberately NOT the compact cvb01 form the sibling suite happens to use, and
# not the C-prefixed convention local to
# cogni-workspace/tests/test-skill-trigger-phrases.sh. The id is followed by a
# SPACE, never a colon abutting it, so a harness matching the whole token
# resolves it. Both arms of a case receive the same id from one argument, so
# they cannot drift apart.

set -eu

# The gate reads its base ref from RETIREMENT_LEDGER_BASE_REF before falling back
# to origin/main. Under CI an ambient value would be read in place of each
# fixture's own ref, so every case would grade against the wrong baseline. Clear
# it once, here, so the fixtures exercise the default identically everywhere.
unset RETIREMENT_LEDGER_BASE_REF || true

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GATE="$REPO_ROOT/scripts/check-retirement-ledger.py"

# Plain text on purpose — result lines are machine-read; tooling anchors a
# literal PASS:/FAIL: prefix. Emit unconditionally, never probe the environment.
red()   { printf '%s\n' "$1"; }
green() { printf '%s\n' "$1"; }

FAILED=0
check() {  # check <label> <condition-exit-code>
  if [ "$2" -eq 0 ]; then
    green "PASS: $1"
  else
    red "FAIL: $1"
    FAILED=$((FAILED + 1))
  fi
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

GIT="git -c user.email=t@test -c user.name=test -c commit.gpgsign=false"

SKILLS="cogni-workspace/skills"
LEDGER="cogni-workspace/references/retired-trigger-phrases.tsv"

# write_skill <root> <dir> <name> <phrase...> — a plain double-quoted scalar.
write_skill() {
  local root="$1" dir="$2" name="$3"; shift 3
  local body="" p
  for p in "$@"; do body="$body \\\"$p\\\""; done
  mkdir -p "$root/$SKILLS/$dir"
  cat > "$root/$SKILLS/$dir/SKILL.md" <<EOF
---
name: $name
description: "Use this skill when the user says$body."
---

# $name
EOF
}

# write_block_skill <root> <dir> <name> <phrase...> — a \`>-\` block scalar, so
# the unwrap-before-quote-hunt path is exercised rather than the quoted one.
write_block_skill() {
  local root="$1" dir="$2" name="$3"; shift 3
  local body="" p
  for p in "$@"; do body="$body \"$p\""; done
  mkdir -p "$root/$SKILLS/$dir"
  cat > "$root/$SKILLS/$dir/SKILL.md" <<EOF
---
name: $name
description: >-
  Use this skill when the user says$body.
---

# $name
EOF
}

# The two helpers below write the two shapes the extractor cannot read a
# description out of. They hit SEPARATE returns in phrases_from_skill_text, so
# both are needed; one helper taking a mode flag would let a typo at a call site
# silently write the other fixture and grade one path twice.

# write_no_frontmatter_skill <root> <dir> — no frontmatter block at all.
write_no_frontmatter_skill() {
  local root="$1" dir="$2"
  mkdir -p "$root/$SKILLS/$dir"
  cat > "$root/$SKILLS/$dir/SKILL.md" <<EOF
# $dir

No frontmatter block at all.
EOF
}

# write_no_description_skill <root> <dir> — a well-formed block, no
# \`description:\` key.
write_no_description_skill() {
  local root="$1" dir="$2"
  mkdir -p "$root/$SKILLS/$dir"
  cat > "$root/$SKILLS/$dir/SKILL.md" <<EOF
---
name: $dir
allowed-tools: [Read]
---

# $dir
EOF
}

# write_ledger <root> [row...] — each row is a literal tab-separated line.
write_ledger() {
  local root="$1"; shift
  mkdir -p "$root/cogni-workspace/references"
  {
    printf '# fixture ledger\n'
    printf '# phrase_key\tstatus\towner\treason\n'
    local r
    for r in "$@"; do printf '%s\n' "$r"; done
  } > "$root/$LEDGER"
}

# make_repo <root> — two skills plus a ledger, committed on main, with
# refs/remotes/origin/main pointing at that base commit.
make_repo() {
  local root="$1"
  mkdir -p "$root"
  write_skill "$root" alpha alpha "alpha one" "alpha two"
  write_skill "$root" beta beta "beta one"
  write_ledger "$root" "$(printf 'legacy phrase\tretired\t-\tfixture seed row')"
  (cd "$root" && $GIT init -q -b main && $GIT add -A && $GIT commit -qm base \
     && $GIT update-ref refs/remotes/origin/main HEAD)
}

# run_gate <root> [args...] -> "<exit>|<status>|<comma-separated checks>|<count>"
run_gate() {
  local root="$1"; shift
  local out rc
  set +e
  out="$(cd "$root" && python3 "$GATE" --root "$root" "$@" 2>/dev/null)"
  rc=$?
  set -e
  printf '%s|%s' "$rc" "$(printf '%s' "$out" | python3 -c '
import json, sys
d = json.load(sys.stdin)["data"] or {}
codes = ",".join(sorted({v["check"] for v in d.get("violations", [])})) or "EMPTY"
print("%s|%s|%s" % (d.get("status"), codes, d.get("count")))
')"
}

# ---------------------------------------------------------------------------
# 1. delete a skill, write no ledger row.
R="$WORK/c1"; make_repo "$R"
(cd "$R" && $GIT rm -rq "$SKILLS/alpha" && $GIT commit -qm "retire alpha")
GOT="$(run_gate "$R")"
check "retirement-ledger-01-missing-row a deleted skill with no ledger row fails (got: $GOT)" \
  "$([ "$GOT" = "1|ok|retirement-row-missing|2" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 2. delete a skill, record every phrase retired with a reason.
R="$WORK/c2"; make_repo "$R"
(cd "$R" && $GIT rm -rq "$SKILLS/alpha")
write_ledger "$R" \
  "$(printf 'legacy phrase\tretired\t-\tfixture seed row')" \
  "$(printf 'alpha one\tretired\t-\tfolded away, no successor')" \
  "$(printf 'alpha two\tretired\t-\tfolded away, no successor')"
(cd "$R" && $GIT add -A && $GIT commit -qm "retire alpha, record rows")
GOT="$(run_gate "$R")"
check "retirement-ledger-02-recorded-retired a recorded retirement passes (got: $GOT)" \
  "$([ "$GOT" = "0|ok|EMPTY|0" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 3. delete a skill whose phrases a SURVIVING skill re-quotes.
R="$WORK/c3"; make_repo "$R"
(cd "$R" && $GIT rm -rq "$SKILLS/alpha")
write_skill "$R" beta beta "beta one" "alpha one" "alpha two"
(cd "$R" && $GIT add -A && $GIT commit -qm "fold alpha into beta")
GOT="$(run_gate "$R")"
check "retirement-ledger-03-reclaimed-by-survivor a re-claimed phrase needs no row (got: $GOT)" \
  "$([ "$GOT" = "0|ok|EMPTY|0" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 4. a branch that deletes no skill at all — the overwhelmingly normal case.
R="$WORK/c4"; make_repo "$R"
(cd "$R" && printf 'docs\n' > README.md && $GIT add -A && $GIT commit -qm docs)
GOT="$(run_gate "$R")"
check "retirement-ledger-04-no-deletion a branch deleting no skill passes (got: $GOT)" \
  "$([ "$GOT" = "0|ok|EMPTY|0" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 5. no refs/remotes/origin/main -> degraded, exit 0 (never a block).
R="$WORK/c5"; make_repo "$R"
(cd "$R" && $GIT rm -rq "$SKILLS/alpha" && $GIT commit -qm "retire alpha" \
   && $GIT update-ref -d refs/remotes/origin/main)
GOT="$(run_gate "$R")"
check "retirement-ledger-05-degraded-no-origin an unresolvable base ref degrades to exit 0 (got: $GOT)" \
  "$([ "$GOT" = "0|degraded|EMPTY|0" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 6. main advanced past the fork and deleted a skill of its own; this branch
#    deleted nothing. A base-TIP anchor would blame the branch for main's work.
R="$WORK/c6"; make_repo "$R"
(cd "$R" && $GIT checkout -q -b feature \
   && printf 'docs\n' > README.md && $GIT add -A && $GIT commit -qm "branch work" \
   && $GIT checkout -q main \
   && $GIT rm -rq "$SKILLS/beta" && $GIT commit -qm "main retires beta" \
   && $GIT update-ref refs/remotes/origin/main HEAD \
   && $GIT checkout -q feature)
GOT="$(run_gate "$R")"
check "retirement-ledger-06-merge-base-anchoring main's own later deletion is not the branch's (got: $GOT)" \
  "$([ "$GOT" = "0|ok|EMPTY|0" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 7. two phrases, exactly one recorded -> exactly ONE violation.
R="$WORK/c7"; make_repo "$R"
(cd "$R" && $GIT rm -rq "$SKILLS/alpha")
write_ledger "$R" \
  "$(printf 'legacy phrase\tretired\t-\tfixture seed row')" \
  "$(printf 'alpha one\tretired\t-\trecorded, but its sibling was forgotten')"
(cd "$R" && $GIT add -A && $GIT commit -qm "retire alpha, record one of two")
GOT="$(run_gate "$R")"
check "retirement-ledger-07-partial-accounting one unrecorded phrase of two is one violation (got: $GOT)" \
  "$([ "$GOT" = "1|ok|retirement-row-missing|1" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 8. rows exist for both phrases but one reason is empty -> still a violation.
R="$WORK/c8"; make_repo "$R"
(cd "$R" && $GIT rm -rq "$SKILLS/alpha")
write_ledger "$R" \
  "$(printf 'legacy phrase\tretired\t-\tfixture seed row')" \
  "$(printf 'alpha one\tretired\t-\tfolded away, no successor')" \
  "$(printf 'alpha two\tretired\t-\t')"
(cd "$R" && $GIT add -A && $GIT commit -qm "retire alpha, one reason blank")
GOT="$(run_gate "$R")"
check "retirement-ledger-08-empty-reason an empty-reason row does not account for its phrase (got: $GOT)" \
  "$([ "$GOT" = "1|ok|retirement-row-missing|1" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 9. the deleted skill used a `>-` block scalar. If the unwrap did not run
#    before the quote hunt, its phrases would be extracted differently (or not
#    at all) and this case would pass vacuously with zero violations.
R="$WORK/c9"; make_repo "$R"
write_block_skill "$R" gamma gamma "gamma one" "gamma two"
(cd "$R" && $GIT add -A && $GIT commit -qm "add gamma" \
   && $GIT update-ref refs/remotes/origin/main HEAD)
(cd "$R" && $GIT rm -rq "$SKILLS/gamma" && $GIT commit -qm "retire gamma")
GOT="$(run_gate "$R")"
check "retirement-ledger-09-block-scalar a block-scalar description still yields its phrases (got: $GOT)" \
  "$([ "$GOT" = "1|ok|retirement-row-missing|2" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 10. --emit-phrases must spawn no git subprocess: C11 calls it from a suite
#     that runs in the shallow plugin-test-suites job. Proved by running it in a
#     directory that is not a git repository at all — a git call there would
#     fail or emit to stderr; the mode must still print phrases and exit 0.
R="$WORK/c10"
mkdir -p "$R"
write_skill "$R" delta delta "delta one" "delta two"
set +e
EP_OUT="$(cd "$R" && python3 "$GATE" --emit-phrases "$R/$SKILLS" 2>"$WORK/c10.err")"
EP_RC=$?
set -e
EP_LINES="$(printf '%s\n' "$EP_OUT" | grep -c . || true)"
EP_ERR_LINES="$(grep -c . "$WORK/c10.err" || true)"
check "retirement-ledger-10-emit-phrases-no-git parity mode runs outside a git repo, silent on stderr (rc=$EP_RC lines=$EP_LINES err=$EP_ERR_LINES)" \
  "$([ "$EP_RC" -eq 0 ] && [ "$EP_LINES" -eq 2 ] && [ "$EP_ERR_LINES" -eq 0 ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 11. the deleted skill cannot be PARSED at the merge base. Before the sentinel,
#     phrases_from_skill_text returned ([], name) from both silent arms, so the
#     loop recorded phrases: 0, raised no violation, and the run exited 0 with
#     stderr claiming "every trigger phrase accounted for" -- the guard
#     asserting full accounting for a file it never parsed. Both arms carry the
#     SAME id from one argument, so neither can report green alone.
UNPARSEABLE_RC=0
UNPARSEABLE_GOT=""
for ARM in write_no_frontmatter_skill write_no_description_skill; do
  R="$WORK/c11-$ARM"; make_repo "$R"
  "$ARM" "$R" alpha
  (cd "$R" && $GIT add -A && $GIT commit -qm "alpha becomes unparseable" \
     && $GIT update-ref refs/remotes/origin/main HEAD)
  (cd "$R" && $GIT rm -rq "$SKILLS/alpha" && $GIT commit -qm "retire alpha")
  GOT="$(run_gate "$R")"
  UNPARSEABLE_GOT="$UNPARSEABLE_GOT ${ARM#write_}=$GOT"
  [ "$GOT" = "1|ok|base-blob-unparseable|1" ] || UNPARSEABLE_RC=1
done
check "retirement-ledger-11-unparseable-base-blob an unreadable base-side frontmatter is a violation, not a silent zero (both arms:$UNPARSEABLE_GOT)" \
  "$UNPARSEABLE_RC"

# ---------------------------------------------------------------------------
# 12. one deletion of each kind in ONE branch -> BOTH violation codes, count 2.
#     Cases 1-11 each yield a single code, so nothing else pins that the two
#     classes co-report; a summary path that handled only one shape would stay
#     green across the whole suite and break on the first real mixed retirement.
R="$WORK/c12"; make_repo "$R"
write_no_frontmatter_skill "$R" gamma
(cd "$R" && $GIT add -A && $GIT commit -qm "add unparseable gamma" \
   && $GIT update-ref refs/remotes/origin/main HEAD)
(cd "$R" && $GIT rm -rq "$SKILLS/alpha" "$SKILLS/gamma" \
   && $GIT commit -qm "retire alpha and gamma")
GOT="$(run_gate "$R")"
check "retirement-ledger-12-mixed-violation-kinds an unparseable and an unaccounted deletion both report (got: $GOT)" \
  "$([ "$GOT" = "1|ok|base-blob-unparseable,retirement-row-missing|3" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
if [ "$FAILED" -gt 0 ]; then
  printf '%s\n' "$FAILED failing case(s)"
  exit 1
fi
printf '%s\n' "all cases passed"
