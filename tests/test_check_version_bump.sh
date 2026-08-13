#!/usr/bin/env bash
# test_check_version_bump.sh — self-test for the version-bump gate.
#
# The gate makes two assertions: a git-independent MIRROR invariant (plugin.json
# version == its marketplace.json entry version) and a git-anchored TOUCH check
# (pr mode: untouched vs the fork point / post-merge mode: strictly greater).
# Cases:
#   1. pr, plugin touched but version untouched -> clean, exit 0.
#   2. pr, version touched -> version-touched, exit 1.
#   3. pr, stale-below-main -> CLEAN. The branch never touched the version but
#      main advanced past it after the fork. This is the merge-base-anchoring
#      regression test: a base-TIP anchor would false-flag this, and since main's
#      version now advances on every merge it would false-flag most real PRs.
#   4. pr, ^bump/ branch -> exempt, clean.
#   5. post-merge, incremented -> clean, exit 0.
#   6. post-merge, not incremented -> version-not-incremented, exit 1.
#   7. post-merge, regressed -> version-regressed, exit 1.
#   8. mirror drift -> version-mirror-desync in BOTH modes.
#   9. degraded (no origin/main) -> status degraded, exit 0 — and a mirror
#      violation is STILL reported, proving the mirror half needs no git.
#  10. Real tree -> clean (the repo is in sync today).
#
# bash 3.2 + stdlib python3 + git.

set -eu

# The gate resolves the branch for its ^bump/ exemption from VERSION_BUMP_BRANCH,
# then GITHUB_HEAD_REF, and only then the checked-out branch. Under GitHub
# Actions GITHUB_HEAD_REF is set to the PR's own head branch, which would be
# read in place of each fixture repo's branch — case 4 puts its fixture on
# bump/auto-abc123 and would be judged against the ambient PR branch instead,
# losing the exemption it exists to assert. Clear both so every fixture case
# exercises the checked-out-branch fallback, identically everywhere.
unset VERSION_BUMP_BRANCH GITHUB_HEAD_REF || true

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GATE="$REPO_ROOT/scripts/check-version-bump.py"

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

# run_gate <root> [args...] -> prints "<exit>|<status>|<comma-separated checks>"
run_gate() {
  local root="$1"; shift
  local out rc
  set +e
  out="$(cd "$root" && python3 "$GATE" --root "$root" "$@" 2>/dev/null)"
  rc=$?
  set -e
  printf '%s|%s' "$rc" "$(printf '%s' "$out" | python3 -c '
import json, sys
d = json.load(sys.stdin)["data"]
codes = ",".join(sorted({v["check"] for v in d["violations"]})) or "EMPTY"
print("%s|%s" % (d["status"], codes))
')"
}

# Two plugins; alpha is the one under test.
make_repo() {
  local root="$1"
  mkdir -p "$root/.claude-plugin" "$root/alpha/.claude-plugin" "$root/beta/.claude-plugin"
  cat > "$root/.claude-plugin/marketplace.json" <<'JSON'
{
  "name": "fixture",
  "plugins": [
    {
      "name": "alpha",
      "source": "./alpha",
      "version": "1.0.70"
    },
    {
      "name": "beta",
      "source": "./beta",
      "version": "0.0.9"
    }
  ]
}
JSON
  printf '{\n  "name": "alpha",\n  "version": "1.0.70"\n}\n' \
    > "$root/alpha/.claude-plugin/plugin.json"
  printf '{\n  "name": "beta",\n  "version": "0.0.9"\n}\n' \
    > "$root/beta/.claude-plugin/plugin.json"
  : > "$root/alpha/file.md"
  (cd "$root" && $GIT init -q -b main && $GIT add -A && $GIT commit -qm base \
     && $GIT update-ref refs/remotes/origin/main HEAD)
}

set_version() {  # set_version <root> <plugin> <old> <new> [both|plugin-only]
  python3 - "$1" "$2" "$3" "$4" "${5:-both}" <<'PY'
import pathlib, sys
root, plugin, old, new, scope = (sys.argv[1], sys.argv[2], sys.argv[3],
                                 sys.argv[4], sys.argv[5])
root = pathlib.Path(root)
p = root / plugin / ".claude-plugin" / "plugin.json"
p.write_text(p.read_text().replace('"version": "%s"' % old,
                                   '"version": "%s"' % new, 1))
if scope == "both":
    m = root / ".claude-plugin" / "marketplace.json"
    t = m.read_text()
    i = t.index('"name": "%s"' % plugin)
    j = t.find('"name": "', i + 10)
    j = j if j != -1 else len(t)
    m.write_text(t[:i] + t[i:j].replace('"version": "%s"' % old,
                                        '"version": "%s"' % new, 1) + t[j:])
PY
}

# --- case 1: touched, version untouched ------------------------------------
R1="$WORK/r1"; make_repo "$R1"
(cd "$R1" && echo x >> alpha/file.md && $GIT commit -aqm touch)
check "case 1: pr, touched but version untouched -> clean" \
  "$([ "$(run_gate "$R1")" = "0|ok|EMPTY" ] && echo 0 || echo 1)"

# --- case 2: version touched ------------------------------------------------
set_version "$R1" alpha 1.0.70 1.0.71 both
(cd "$R1" && $GIT commit -aqm bump)
check "case 2: pr, version touched -> version-touched, exit 1" \
  "$([ "$(run_gate "$R1")" = "1|ok|version-touched" ] && echo 0 || echo 1)"

# --- case 5/6/7: post-merge polarity ----------------------------------------
check "case 5: post-merge, incremented -> clean" \
  "$([ "$(run_gate "$R1" --mode post-merge)" = "0|ok|EMPTY" ] && echo 0 || echo 1)"
set_version "$R1" alpha 1.0.71 1.0.70 both
(cd "$R1" && $GIT commit -aqm revert)
check "case 6: post-merge, not incremented -> version-not-incremented" \
  "$([ "$(run_gate "$R1" --mode post-merge)" = "1|ok|version-not-incremented" ] && echo 0 || echo 1)"
set_version "$R1" alpha 1.0.70 1.0.69 both
(cd "$R1" && $GIT commit -aqm regress)
check "case 7: post-merge, regressed -> version-regressed" \
  "$([ "$(run_gate "$R1" --mode post-merge)" = "1|ok|version-regressed" ] && echo 0 || echo 1)"

# --- case 3: stale-below-main (merge-base anchoring regression test) --------
# The branch touches alpha but never its version. Meanwhile main advances past
# it — exactly what the post-merge bump workflow now does on every merge. Head
# == fork point, so this must be CLEAN. Anchoring on the base TIP would report
# version-touched here and break nearly every honest PR.
R3="$WORK/r3"; make_repo "$R3"
BASE="$(cd "$R3" && $GIT rev-parse HEAD)"
(cd "$R3" && $GIT checkout -q -b feature && echo x >> alpha/file.md \
   && $GIT commit -aqm "feature: no version change")
(cd "$R3" && $GIT checkout -q -b mainline "$BASE")
set_version "$R3" alpha 1.0.70 1.0.71 both
(cd "$R3" && $GIT commit -aqm "bump(alpha): v1.0.71" \
   && $GIT update-ref refs/remotes/origin/main HEAD && $GIT checkout -q feature)
check "case 3: pr, stale-below-main -> clean (merge-base anchored)" \
  "$([ "$(run_gate "$R3")" = "0|ok|EMPTY" ] && echo 0 || echo 1)"

# --- case 4: ^bump/ exemption ----------------------------------------------
R4="$WORK/r4"; make_repo "$R4"
(cd "$R4" && $GIT checkout -q -b bump/auto-abc123 && echo x >> alpha/file.md)
set_version "$R4" alpha 1.0.70 1.0.71 both
(cd "$R4" && $GIT commit -aqm "bump(alpha)")
check "case 4: pr, ^bump/ branch -> exempt, clean" \
  "$([ "$(run_gate "$R4")" = "0|ok|EMPTY" ] && echo 0 || echo 1)"

# --- case 8/9: mirror drift, and drift surviving the degraded path ----------
R8="$WORK/r8"; make_repo "$R8"
set_version "$R8" alpha 1.0.70 1.0.71 plugin-only
(cd "$R8" && $GIT commit -aqm desync)
# Bumping only plugin.json trips BOTH halves: the touch check sees the version
# move vs the fork point, and the mirror check sees the pair disagree. Both are
# correct and both must be reported.
check "case 8: pr, mirror drift -> desync AND touched" \
  "$([ "$(run_gate "$R8")" = "1|ok|version-mirror-desync,version-touched" ] && echo 0 || echo 1)"
check "case 8: post-merge, mirror drift also reported" \
  "$(run_gate "$R8" --mode post-merge | grep -q 'version-mirror-desync' && echo 0 || echo 1)"
check "case 9: degraded base ref -> status degraded, drift STILL reported" \
  "$([ "$(run_gate "$R8" --base-ref origin/nope)" = "1|degraded|version-mirror-desync" ] && echo 0 || echo 1)"

R9="$WORK/r9"; make_repo "$R9"
check "case 9: degraded base ref, tree in sync -> clean, exit 0" \
  "$([ "$(run_gate "$R9" --base-ref origin/nope)" = "0|degraded|EMPTY" ] && echo 0 || echo 1)"

# --- case 10: the real tree -------------------------------------------------
set +e
python3 "$GATE" --root "$REPO_ROOT" > "$WORK/real.json" 2>/dev/null
REAL_RC=$?
set -e
REAL_CLEAN="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['data']['clean'])" "$WORK/real.json")"
check "case 10: real tree -> clean, exit 0" \
  "$([ "$REAL_RC" -eq 0 ] && [ "$REAL_CLEAN" = "True" ] && echo 0 || echo 1)"

echo
if [ "$FAILED" -eq 0 ]; then
  green "All check-version-bump tests passed."
else
  red "$FAILED test(s) failed."
  exit 1
fi
