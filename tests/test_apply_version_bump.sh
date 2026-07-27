#!/usr/bin/env bash
# test_apply_version_bump.sh — self-test for the post-merge version bumper.
#
# The bumper rewrites TWO manifests per plugin: `<plugin>/.claude-plugin/plugin.json`
# and that plugin's entry inside the single shared root `.claude-plugin/marketplace.json`.
# The shared file is the risk: an unscoped regex could rewrite a sibling entry or the
# root `metadata.version`. Cases:
#   1. Single-plugin bump -> both manifests advance, together.
#   2. Digit carry 0.0.9 -> 0.0.10 (the byte-growth case that shifts later spans).
#   3. Version collision -> two plugins share a version string; only the touched
#      one moves. This is the test an unscoped regex fails.
#   4. metadata.version immunity -> root metadata carries the same version string
#      as a bumped plugin and must not move.
#   5. Multi-plugin merge -> three plugins in one run, spans re-derived after each
#      edit so a carry in plugin #1 cannot misplace plugin #3's edit.
#   6. Non-numeric tail -> skipped as a warning, exit 0, nothing written.
#   7. Mirror drift -> skipped as an error, exit 1, that plugin untouched, but a
#      co-touched healthy plugin still bumps (partial progress, loud failure).
#   8. Untouched plugin -> never bumped.
#   9. --dry-run -> computes and verifies, writes nothing.
#  10. Formatting + non-ASCII preserved byte-for-byte (no json.dump round-trip).
#  11. Real tree, --dry-run, empty touched set -> clean no-op.
#
# bash 3.2 + stdlib python3 only. No git required (the touched set is passed in).

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
BUMPER="$REPO_ROOT/scripts/apply-version-bump.py"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

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

check "case 1/5: multi-plugin run exits 0" "$([ "$MULTI_RC" -eq 0 ] && echo 0 || echo 1)"
check "case 1: alpha 1.0.70 -> 1.0.71 in both manifests" \
  "$([ "$(version_of "$R" alpha)" = "1.0.71|1.0.71" ] && echo 0 || echo 1)"
check "case 2: beta carry 0.0.9 -> 0.0.10 in both manifests" \
  "$([ "$(version_of "$R" beta)" = "0.0.10|0.0.10" ] && echo 0 || echo 1)"
check "case 3: gamma (collides with beta on 0.0.9) -> 0.0.10 in both manifests" \
  "$([ "$(version_of "$R" gamma)" = "0.0.10|0.0.10" ] && echo 0 || echo 1)"
check "case 4: root metadata.version stays 0.0.9" \
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
check "case 10: exactly 2 changed lines in marketplace.json (one -, one +)" \
  "$([ "$DIFF_LINES" -eq 2 ] && echo 0 || echo 1)"
check "case 10: non-ASCII description preserved verbatim" \
  "$(grep -q 'Größe, Prüfung, ä ö ü ß, é è ê ç' "$R2/.claude-plugin/marketplace.json" && echo 0 || echo 1)"
check "case 10: keywords array untouched" \
  "$(grep -q '"keywords": \["gamma", "incubating"\]' "$R2/.claude-plugin/marketplace.json" && echo 0 || echo 1)"
check "case 8: untouched alpha still 1.0.70" \
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
check "case 6: non-numeric tail exits 0" "$([ "$NN_RC" -eq 0 ] && echo 0 || echo 1)"
check "case 6: non-numeric tail skipped as warning" \
  "$([ "$NN_SEV" = "warning" ] && echo 0 || echo 1)"
check "case 6: nothing written for the skipped plugin" \
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
check "case 7: mirror drift exits 1" "$([ "$DRIFT_RC" -eq 1 ] && echo 0 || echo 1)"
check "case 7: mirror drift skipped as error" \
  "$([ "$DRIFT_SEV" = "error" ] && echo 0 || echo 1)"
check "case 7: drifted alpha left untouched" \
  "$([ "$(version_of "$R4" alpha)" = "1.0.69|1.0.70" ] && echo 0 || echo 1)"
check "case 7: co-touched healthy beta still bumped" \
  "$([ "$(version_of "$R4" beta)" = "0.0.10|0.0.10" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# Case 9: --dry-run writes nothing.
# ---------------------------------------------------------------------------
R5="$WORK/dry"
make_fixture "$R5"
python3 "$BUMPER" --root "$R5" --changed alpha/file.md --dry-run >/dev/null 2>&1
check "case 9: --dry-run leaves both manifests untouched" \
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
check "case 11: real tree, no plugin touched -> exit 0, zero bumps" \
  "$([ "$REAL_RC" -eq 0 ] && [ "$REAL_N" -eq 0 ] && echo 0 || echo 1)"

echo
if [ "$FAILED" -eq 0 ]; then
  green "All apply-version-bump tests passed."
else
  red "$FAILED test(s) failed."
  exit 1
fi
