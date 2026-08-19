#!/usr/bin/env bash
# test_apply_version_bump.sh — self-test for the post-merge version bumper.
#
# The bumper rewrites TWO manifests per plugin: `<plugin>/.claude-plugin/plugin.json`
# and that plugin's entry inside the single shared root `.claude-plugin/marketplace.json`.
# The shared file is the risk: an unscoped regex could rewrite a sibling entry or the
# root `metadata.version`. Cases:
#   1. Single-plugin bump -> both manifests advance, together.  [avb02]
#   2. Digit carry 0.0.9 -> 0.0.10 (the byte-growth case that shifts later spans).  [avb03]
#   3. Version collision -> two plugins share a version string; only the touched
#      one moves. This is the test an unscoped regex fails.  [avb04]
#   4. metadata.version immunity -> root metadata carries the same version string
#      as a bumped plugin and must not move.  [avb05]
#   5. Multi-plugin merge -> three plugins in one run, spans re-derived after each
#      edit so a carry in plugin #1 cannot misplace plugin #3's edit.  [avb01]
#   6. Non-numeric tail -> skipped as a warning, exit 0, nothing written.  [avb10-avb12]
#   7. Mirror drift -> skipped as an error, exit 1, that plugin untouched, but a
#      co-touched healthy plugin still bumps (partial progress, loud failure).  [avb13-avb16]
#   8. Untouched plugin -> never bumped.  [avb09]
#   9. --dry-run -> computes and verifies, writes nothing.  [avb17]
#  10. Formatting + non-ASCII preserved byte-for-byte (no json.dump round-trip).  [avb06-avb08]
#  11. Real tree, --dry-run, empty touched set -> clean no-op.  [avb18]
#
# bash 3.2 + stdlib python3 only. No git required (the touched set is passed in).
#
# Result-line ids: every emitted PASS:/FAIL: line carries a first-token id
# (avbNN), unique PER EMITTED LINE rather than per logical case, so
# `mutation-check.sh --case <id>` addresses exactly one assertion. The id is
# followed by a SPACE, never a colon abutting it — the harness matches the
# case whole-token, so a colon-abutting id returns case_not_found. A new
# assertion takes the next free id rather than renumbering its neighbours.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
BUMPER="$REPO_ROOT/scripts/apply-version-bump.py"

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

# Builds a fixture repo at $1. Three plugins:
#   alpha  1.0.70  — ordinary
#   beta   0.0.9   — carry case, and shares its version string with gamma
#   gamma  0.0.9   — collision partner; description carries non-ASCII
# Root metadata.version is also 0.0.9, so it collides too (case 4).
make_fixture() {
  local root="$1"
  mkdir -p "$root/.claude-plugin" "$root/alpha/.claude-plugin" \
           "$root/beta/.claude-plugin" "$root/gamma/.claude-plugin"
  cat > "$root/.claude-plugin/marketplace.json" <<'JSON'
{
  "name": "fixture",
  "metadata": {
    "description": "fixture marketplace",
    "version": "0.0.9"
  },
  "plugins": [
    {
      "name": "alpha",
      "source": "./alpha",
      "version": "1.0.70",
      "maturity": "released",
      "description": "Alpha — plain ASCII.",
      "keywords": ["alpha", "released"]
    },
    {
      "name": "beta",
      "source": "./beta",
      "version": "0.0.9",
      "maturity": "incubating",
      "description": "Beta — carry case.",
      "keywords": ["beta", "incubating"]
    },
    {
      "name": "gamma",
      "source": "./gamma",
      "version": "0.0.9",
      "maturity": "incubating",
      "description": "Gamma — Größe, Prüfung, ä ö ü ß, é è ê ç.",
      "keywords": ["gamma", "incubating"]
    }
  ]
}
JSON
  printf '{\n  "name": "alpha",\n  "version": "1.0.70",\n  "description": "Alpha"\n}\n' \
    > "$root/alpha/.claude-plugin/plugin.json"
  printf '{\n  "name": "beta",\n  "version": "0.0.9",\n  "description": "Beta"\n}\n' \
    > "$root/beta/.claude-plugin/plugin.json"
  printf '{\n  "name": "gamma",\n  "version": "0.0.9",\n  "description": "Gamma — ä ö ü ß"\n}\n' \
    > "$root/gamma/.claude-plugin/plugin.json"
  : > "$root/alpha/file.md"
  : > "$root/beta/file.md"
  : > "$root/gamma/file.md"
}

# version_of <root> <plugin>  -> "<plugin.json version>|<marketplace version>"
version_of() {
  python3 - "$1" "$2" <<'PY'
import json, sys, pathlib
root, plugin = pathlib.Path(sys.argv[1]), sys.argv[2]
pj = json.loads((root / plugin / ".claude-plugin" / "plugin.json").read_text())["version"]
mk = json.loads((root / ".claude-plugin" / "marketplace.json").read_text())
mv = [e for e in mk["plugins"] if e["name"] == plugin][0]["version"]
print("%s|%s" % (pj, mv))
PY
}

meta_version_of() {
  python3 -c "import json,sys;print(json.load(open(sys.argv[1]+'/.claude-plugin/marketplace.json'))['metadata']['version'])" "$1"
}

# ---------------------------------------------------------------------------
# Cases 1–5: a three-plugin run exercising carry, collision, metadata immunity
# and span re-derivation all at once.
# ---------------------------------------------------------------------------
R="$WORK/multi"
make_fixture "$R"
set +e
python3 "$BUMPER" --root "$R" --changed alpha/file.md beta/file.md gamma/file.md \
  > "$WORK/multi.json" 2>/dev/null
MULTI_RC=$?
set -e

check "avb01-multi-plugin-exit0 multi-plugin run exits 0" "$([ "$MULTI_RC" -eq 0 ] && echo 0 || echo 1)"
check "avb02-alpha-mirror alpha 1.0.70 -> 1.0.71 in both manifests" \
  "$([ "$(version_of "$R" alpha)" = "1.0.71|1.0.71" ] && echo 0 || echo 1)"
check "avb03-beta-carry beta carry 0.0.9 -> 0.0.10 in both manifests" \
  "$([ "$(version_of "$R" beta)" = "0.0.10|0.0.10" ] && echo 0 || echo 1)"
check "avb04-gamma-carry-collision gamma (collides with beta on 0.0.9) -> 0.0.10 in both manifests" \
  "$([ "$(version_of "$R" gamma)" = "0.0.10|0.0.10" ] && echo 0 || echo 1)"
check "avb05-root-metadata-untouched root metadata.version stays 0.0.9" \
  "$([ "$(meta_version_of "$R")" = "0.0.9" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# Case 10: formatting and non-ASCII survive — only version VALUES may differ.
# ---------------------------------------------------------------------------
R2="$WORK/fmt"
make_fixture "$R2"
cp "$R2/.claude-plugin/marketplace.json" "$WORK/marketplace.before"
python3 "$BUMPER" --root "$R2" --changed gamma/file.md >/dev/null 2>&1
DIFF_LINES="$(diff "$WORK/marketplace.before" "$R2/.claude-plugin/marketplace.json" \
  | grep -c '^[<>]' || true)"
check "avb06-changed-line-count exactly 2 changed lines in marketplace.json (one -, one +)" \
  "$([ "$DIFF_LINES" -eq 2 ] && echo 0 || echo 1)"
check "avb07-nonascii-description-verbatim non-ASCII description preserved verbatim" \
  "$(grep -q 'Größe, Prüfung, ä ö ü ß, é è ê ç' "$R2/.claude-plugin/marketplace.json" && echo 0 || echo 1)"
check "avb08-keywords-untouched keywords array untouched" \
  "$(grep -q '"keywords": \["gamma", "incubating"\]' "$R2/.claude-plugin/marketplace.json" && echo 0 || echo 1)"
check "avb09-untouched-alpha-unchanged untouched alpha still 1.0.70" \
  "$([ "$(version_of "$R2" alpha)" = "1.0.70|1.0.70" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# Case 6: non-numeric version tail -> warning skip, exit 0, nothing written.
# ---------------------------------------------------------------------------
R3="$WORK/nonnumeric"
make_fixture "$R3"
python3 - "$R3" <<'PY'
import json, pathlib, sys, re
root = pathlib.Path(sys.argv[1])
for p in (root / "alpha/.claude-plugin/plugin.json",):
    p.write_text(p.read_text().replace('"1.0.70"', '"0.1.0-rc1"'))
m = root / ".claude-plugin/marketplace.json"
m.write_text(m.read_text().replace('"version": "1.0.70"', '"version": "0.1.0-rc1"'))
PY
set +e
python3 "$BUMPER" --root "$R3" --changed alpha/file.md > "$WORK/nn.json" 2>/dev/null
NN_RC=$?
set -e
NN_SEV="$(python3 -c "import json,sys;d=json.load(open(sys.argv[1]))['data'];print(d['skipped'][0]['severity'] if d['skipped'] else 'NONE')" "$WORK/nn.json")"
check "avb10-nonnumeric-exit0 non-numeric tail exits 0" "$([ "$NN_RC" -eq 0 ] && echo 0 || echo 1)"
check "avb11-nonnumeric-warning-skip non-numeric tail skipped as warning" \
  "$([ "$NN_SEV" = "warning" ] && echo 0 || echo 1)"
check "avb12-nonnumeric-nothing-written nothing written for the skipped plugin" \
  "$([ "$(version_of "$R3" alpha)" = "0.1.0-rc1|0.1.0-rc1" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# Case 7: mirror drift -> error skip, exit 1, but a co-touched healthy plugin
# still bumps. Partial progress, loud failure.
# ---------------------------------------------------------------------------
R4="$WORK/drift"
make_fixture "$R4"
python3 - "$R4" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1]) / "alpha/.claude-plugin/plugin.json"
p.write_text(p.read_text().replace('"1.0.70"', '"1.0.69"'))  # drift vs marketplace
PY
set +e
python3 "$BUMPER" --root "$R4" --changed alpha/file.md beta/file.md \
  > "$WORK/drift.json" 2>/dev/null
DRIFT_RC=$?
set -e
DRIFT_SEV="$(python3 -c "import json,sys;d=json.load(open(sys.argv[1]))['data'];print(d['skipped'][0]['severity'] if d['skipped'] else 'NONE')" "$WORK/drift.json")"
check "avb13-drift-exit1 mirror drift exits 1" "$([ "$DRIFT_RC" -eq 1 ] && echo 0 || echo 1)"
check "avb14-drift-error-severity mirror drift skipped as error" \
  "$([ "$DRIFT_SEV" = "error" ] && echo 0 || echo 1)"
check "avb15-drift-alpha-untouched drifted alpha left untouched" \
  "$([ "$(version_of "$R4" alpha)" = "1.0.69|1.0.70" ] && echo 0 || echo 1)"
check "avb16-drift-cotouched-beta-bumped co-touched healthy beta still bumped" \
  "$([ "$(version_of "$R4" beta)" = "0.0.10|0.0.10" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# Case 9: --dry-run writes nothing.
# ---------------------------------------------------------------------------
R5="$WORK/dry"
make_fixture "$R5"
python3 "$BUMPER" --root "$R5" --changed alpha/file.md --dry-run >/dev/null 2>&1
check "avb17-dry-run-untouched --dry-run leaves both manifests untouched" \
  "$([ "$(version_of "$R5" alpha)" = "1.0.70|1.0.70" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# Case 11: real tree, --dry-run, empty touched set -> clean no-op.
# ---------------------------------------------------------------------------
set +e
python3 "$BUMPER" --root "$REPO_ROOT" --changed README.md --dry-run \
  > "$WORK/real.json" 2>/dev/null
REAL_RC=$?
set -e
REAL_N="$(python3 -c "import json,sys;print(len(json.load(open(sys.argv[1]))['data']['bumped']))" "$WORK/real.json")"
check "avb18-real-tree-noop real tree, no plugin touched -> exit 0, zero bumps" \
  "$([ "$REAL_RC" -eq 0 ] && [ "$REAL_N" -eq 0 ] && echo 0 || echo 1)"

echo
if [ "$FAILED" -eq 0 ]; then
  green "All apply-version-bump tests passed."
else
  red "$FAILED test(s) failed."
  exit 1
fi
