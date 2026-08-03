#!/usr/bin/env bash
# Regression test for the shared theme-value guard (scripts/sanitize-theme.py)
# and its wiring into the workspace-dashboard renderer.
#
# Contract under test: an operator-supplied --design-variables
# value carrying a stylesheet/markup breakout (e.g. "#000000</style><script>...")
# must be rejected before it reaches the generated <style> block, with the
# renderer falling back to its built-in palette for that key.
#
# stdlib-only: bash + python3, no pip deps. Mirrors the cogni conventions in
# cogni-projects/tests/test-render-dashboard.sh.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
GUARD="$WS_ROOT/scripts/sanitize-theme.py"
RENDERER="$WS_ROOT/skills/workspace-dashboard/scripts/generate-dashboard.py"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { echo "OK   $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }

# assert_py "<label>" "<python expr, True to pass>" — GUARD path is on sys.path.
assert_py() {
  local label="$1" expr="$2"
  if python3 - "$GUARD" <<PY
import importlib.util, sys
spec = importlib.util.spec_from_file_location("g", sys.argv[1])
g = importlib.util.module_from_spec(spec); spec.loader.exec_module(g)
sys.exit(0 if ($expr) else 1)
PY
  then pass "$label"; else fail "$label"; fi
}

# assert_json "<label>" "<json-file>" "<python expr over `d`, True to pass>" —
# `d` is the parsed document. Keeps the label in one place; open-coding the
# python3 -c ... && pass "L" || fail "L" form repeats it and lets a typo report
# the wrong test name.
assert_json() {
  local label="$1" file="$2" expr="$3"
  if python3 - "$file" <<PY
import json, sys
d = json.load(open(sys.argv[1]))
sys.exit(0 if ($expr) else 1)
PY
  then pass "$label"; else fail "$label"; fi
}

# assert_lacks "<label>" "<needle>" "<file>"
assert_lacks() {
  if [ -f "$3" ] && ! grep -qF "$2" "$3"; then pass "$1"; else fail "$1 (found '$2' or missing file)"; fi
}
# assert_has "<label>" "<needle>" "<file>"
assert_has() {
  if [ -f "$3" ] && grep -qF "$2" "$3"; then pass "$1"; else fail "$1 (missing '$2')"; fi
}

echo "=== guard unit behavior ==="
assert_py "1a hex color is safe"        'g.is_safe_value("#000000") is True'
assert_py "1b style breakout rejected"  'g.is_safe_value("#000000</style><script>alert(1)</script>") is False'
assert_py "1c url() beacon rejected"    'g.is_safe_value("url(https://evil.example/track.png)") is False'
assert_py "1d empty rejected"           'g.is_safe_value("") is False'
assert_py "1e non-string rejected"      'g.is_safe_value(123) is False'
assert_py "1f overlong rejected"        'g.is_safe_value("#" + "a"*200) is False'
assert_py "1g font stack single-quotes ok" "g.is_safe_value(\"'Segoe UI', Roboto\") is True"
assert_py "1h unknown profile falls back to strict" 'g.is_safe_value("#000000</style>", "nope") is False'

echo "=== font-aware profile ==="
# The exact DEFAULT_THEME value this plugin's own renderer ships (184 chars) —
# over strict's 120 cap, which is why font-aware could not reuse the bound.
DEF_IMPORT="@import url('https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&family=Outfit:wght@300;400;500;600;700&display=swap');"
assert_py "1i shipped default @import accepted" \
  "g.is_safe_value('''$DEF_IMPORT''', 'font-aware') is True"
assert_py "1j rgba shadow accepted" \
  'g.is_safe_value("0 1px 3px rgba(0,0,0,0.04), 0 1px 2px rgba(0,0,0,0.06)", "font-aware") is True'
assert_py "1k font stack accepted" \
  "g.is_safe_value(\"'Segoe UI', Roboto\", 'font-aware') is True"
# Forward-compat with cogni-visual/enrich-report, which normalizes a bare URL
# into an @import — the profile must not be hostile to the pre-normalized shape.
assert_py "1l bare https URL accepted" \
  'g.is_safe_value("https://fonts.googleapis.com/css2?family=Outfit:wght@400;500&display=swap", "font-aware") is True'
assert_py "1m radius accepted" 'g.is_safe_value("12px", "font-aware") is True'
assert_py "1n style breakout still rejected" \
  'g.is_safe_value("</style><script>alert(1)</script>", "font-aware") is False'
assert_py "1o declaration injection rejected" \
  'g.is_safe_value("red; background-image: url(https://evil.example/b.png)", "font-aware") is False'
assert_py "1p rule-block injection rejected" \
  'g.is_safe_value("red} body{background:red", "font-aware") is False'
assert_py "1q data: scheme rejected" \
  "g.is_safe_value(\"@import url('data:text/css,body{color:red}');\", 'font-aware') is False"
assert_py "1r http: scheme rejected" \
  "g.is_safe_value(\"@import url('http://a.example/x.css');\", 'font-aware') is False"
assert_py "1s protocol-relative rejected" \
  "g.is_safe_value(\"@import url('//a.example/x.css');\", 'font-aware') is False"
assert_py "1t chained @import rejected" \
  "g.is_safe_value(\"@import url('https://a.example/x.css');@import url('https://b.example/y.css');\", 'font-aware') is False"
assert_py "1u media-qualified @import rejected" \
  "g.is_safe_value(\"@import url('https://a.example/x.css') screen;\", 'font-aware') is False"
# The shape gate is anchored ^...\Z with no trailing \s* — anything after the
# statement fails closed. Both details are load-bearing: \Z alone still accepts a
# trailing newline if a \s* precedes it, and plain $ accepts one outright.
assert_py "1v @import with trailing declaration rejected" \
  "g.is_safe_value(\"@import url('https://a.example/x.css'); body{color:red}\", 'font-aware') is False"
assert_py "1w @import with trailing newline rejected" \
  "g.is_safe_value(\"@import url('https://a.example/x.css');\n\", 'font-aware') is False"
assert_py "1x @import with trailing space rejected" \
  "g.is_safe_value(\"@import url('https://a.example/x.css'); \", 'font-aware') is False"
assert_py "1y over-length rejected" \
  'g.is_safe_value("https://a.example/" + "a"*300, "font-aware") is False'
# Regression: the relaxations must not leak into strict, still the default
# profile for colors/status.
assert_py "1z strict still rejects rgba" 'g.is_safe_value("rgba(0,0,0,0.1)") is False'
assert_py "1za strict still rejects the shipped default @import" \
  "g.is_safe_value('''$DEF_IMPORT''') is False"

echo "=== sanitize_values fallback ==="
assert_py "2a rejected key keeps default" \
  'g.sanitize_values({"background":"#000000</style>"}, {"background":"#FAFAF8"})[0]["background"] == "#FAFAF8"'
assert_py "2b safe key applied" \
  'g.sanitize_values({"background":"#123456"}, {"background":"#FAFAF8"})[0]["background"] == "#123456"'
assert_py "2c rejected key reported" \
  'g.sanitize_values({"background":"#000000</style>"}, {"background":"#FAFAF8"})[1] == ["background"]'
assert_py "2d absent-in-defaults key ignored" \
  'g.sanitize_values({"rogue":"x"}, {"background":"#FAFAF8"})[0] == {"background":"#FAFAF8"}'
assert_py "2e font-aware profile keeps default for rejected shadow" \
  'g.sanitize_values({"sm":"red; background:url(https://evil.example/b.png)"}, {"sm":"0 1px 3px rgba(0,0,0,0.04)"}, "font-aware")[0]["sm"] == "0 1px 3px rgba(0,0,0,0.04)"'
assert_py "2f font-aware profile applies legitimate rgba shadow" \
  'g.sanitize_values({"sm":"0 2px 6px rgba(0,0,0,0.08)"}, {"sm":"0 1px 3px rgba(0,0,0,0.04)"}, "font-aware")[0]["sm"] == "0 2px 6px rgba(0,0,0,0.08)"'
# render_css indexes theme['fonts'][...] directly, so a partial override must
# come back with every key backfilled or the render raises KeyError.
assert_py "2g partial fonts override backfills missing keys" \
  'sorted(g.sanitize_values({"body":"Inter"}, {"headers":"Outfit","body":"Roboto","mono":"JetBrains Mono"}, "font-aware")[0]) == ["body","headers","mono"]'

echo "=== sanitize_section (section -> profile policy) ==="
# The policy lives in the guard, not in each renderer: a caller names the section
# and gets the right profile and shape without restating either.
assert_py "2h colors section resolves to strict" \
  'g.sanitize_section("colors", {"background":"rgba(0,0,0,0.1)"}, {"background":"#FAFAF8"}) == ({"background":"#FAFAF8"}, ["background"])'
assert_py "2i fonts section resolves to font-aware" \
  'g.sanitize_section("fonts", {"body":"0 1px rgba(0,0,0,0.1)"}, {"body":"Roboto"})[0]["body"] == "0 1px rgba(0,0,0,0.1)"'
assert_py "2j scalar import accepted" \
  "g.sanitize_section('google_fonts_import', '''\$DEF_IMPORT''', '') == ('''\$DEF_IMPORT''', [])"
assert_py "2k scalar breakout falls back to default" \
  'g.sanitize_section("google_fonts_import", "</style><script>x</script>", "") == ("", ["google_fonts_import"])'
# Empty means "no override", not "unsafe" — the renderer and the CLI report must
# agree on this, or a valid theme warns in one path and reads clean in the other.
assert_py "2l empty scalar is not an override" \
  'g.sanitize_section("radius", "", "12px") == ("12px", [])'
assert_py "2m absent scalar is not an override" \
  'g.sanitize_section("radius", None, "12px") == ("12px", [])'
assert_py "2n explicit profile overrides section default" \
  "g.sanitize_section('fonts', {'body':'rgba(0,0,0,0.1)'}, {'body':'Roboto'}, 'strict') == ({'body':'Roboto'}, ['body'])"

echo "=== CLI envelope ==="
cat > "$TMPROOT/dv-evil.json" <<'EOF'
{"colors": {"background": "#000000</style><script>alert(1)</script>", "primary": "#111111"}, "status": {"danger": "#f00"}}
EOF
python3 "$GUARD" "$TMPROOT/dv-evil.json" > "$TMPROOT/cli-evil.json"
assert_json "3a CLI reports rejected color key" "$TMPROOT/cli-evil.json" \
  'd["success"] and d["data"]["rejected"].get("colors")==["background"]' 
python3 "$GUARD" >/dev/null 2>&1 && fail "3b CLI no-arg errors" || pass "3b CLI no-arg errors"

# The CLI walks font/shadow/@import/radius too, each under its renderer's profile.
cat > "$TMPROOT/dv-font-evil.json" <<'EOF'
{"fonts": {"body": "X; background-image: url(https://evil.example/b.png)"},
 "shadows": {"sm": "0 1px 3px rgba(0,0,0,0.04)"},
 "google_fonts_import": "</style><script>alert(1)</script>",
 "radius": "12px"}
EOF
python3 "$GUARD" "$TMPROOT/dv-font-evil.json" > "$TMPROOT/cli-font-evil.json"
assert_json "3c CLI reports rejected font key" "$TMPROOT/cli-font-evil.json" \
  'd["data"]["rejected"].get("fonts")==["body"]'
assert_json "3d CLI reports rejected scalar section" "$TMPROOT/cli-font-evil.json" \
  'd["data"]["rejected"].get("google_fonts_import")==["google_fonts_import"]'
assert_json "3e CLI accepts legitimate shadow + radius" "$TMPROOT/cli-font-evil.json" \
  '"shadows" not in d["data"]["rejected"] and "radius" not in d["data"]["rejected"]'
assert_json "3f CLI reports per-section profiles" "$TMPROOT/cli-font-evil.json" \
  'd["data"]["section_profiles"]["colors"]=="strict" and d["data"]["section_profiles"]["fonts"]=="font-aware"' 
# An absent/empty scalar is not an override: never counted, never rejected.
cat > "$TMPROOT/dv-empty-import.json" <<'EOF'
{"colors": {"background": "#123456"}, "google_fonts_import": ""}
EOF
python3 "$GUARD" "$TMPROOT/dv-empty-import.json" > "$TMPROOT/cli-empty.json"
assert_json "3g CLI skips empty scalar section" "$TMPROOT/cli-empty.json" \
  'd["data"]["rejected"]=={} and d["data"]["checked"]==1' 

echo "=== wired renderer end-to-end ==="
WS="$TMPROOT/ws"; mkdir -p "$WS"
run_render() { python3 "$RENDERER" "$WS" --design-variables "$1" --output "$WS/out.html" >/tmp/render-out.json 2>/tmp/render-err.txt; }

# Malicious color value must not reach the output; renderer must still succeed.
run_render "$TMPROOT/dv-evil.json"
assert_json "4a malicious render succeeds" /tmp/render-out.json 'd.get("status")=="ok"'
assert_lacks "4b </style><script> not in output" '</style><script>' "$WS/out.html"
assert_has   "4c built-in background applied instead" '#FAFAF8' "$WS/out.html"
assert_json "4d rejection surfaced as warning" /tmp/render-out.json 'd.get("theme_warnings")'

# Safe theme still applies, and the legitimate @import url(...) font path is untouched.
cat > "$TMPROOT/dv-safe.json" <<'EOF'
{"colors": {"background": "#123456"}, "google_fonts_import": "@import url('https://fonts.googleapis.com/css2?family=Outfit&display=swap');"}
EOF
run_render "$TMPROOT/dv-safe.json"
assert_has "4e safe color applied" '#123456' "$WS/out.html"
assert_has "4f legitimate @import url() font preserved" "@import url('https://fonts.googleapis.com" "$WS/out.html"

# A breakout in google_fonts_import lands at the TOP of the <style> block, before
# :root — the most exposed slot, and the one that was unguarded until font-aware.
run_render "$TMPROOT/dv-font-evil.json"
assert_json "4g font-evil render succeeds" /tmp/render-out.json 'd.get("status")=="ok"'
assert_lacks "4h @import breakout not in output" '<script>alert(1)</script>' "$WS/out.html"
assert_lacks "4i font declaration injection not in output" 'background-image: url(https://evil.example' "$WS/out.html"
assert_json "4j font rejection surfaced as warning" /tmp/render-out.json 'd.get("theme_warnings")'
# Legitimate rgba shadow and radius from the same fixture must survive.
assert_has "4k legitimate rgba shadow preserved" 'rgba(0,0,0,0.04)' "$WS/out.html"

# An empty google_fonts_import means "no import" — a valid theme, so no warning.
run_render "$TMPROOT/dv-empty-import.json"
assert_json "4l empty import produces no warning" /tmp/render-out.json 'not d.get("theme_warnings")'

# Partial fonts override used to KeyError in render_css (it indexes headers/body/mono).
cat > "$TMPROOT/dv-partial-fonts.json" <<'EOF'
{"fonts": {"body": "'Inter', sans-serif"}}
EOF
run_render "$TMPROOT/dv-partial-fonts.json"
assert_json "4m partial fonts override renders" /tmp/render-out.json 'd.get("status")=="ok"'
assert_has "4n header font backfilled from defaults" "'Bricolage Grotesque'" "$WS/out.html"
assert_has "4o overridden body font still applied" "'Inter', sans-serif" "$WS/out.html"

echo
if [ "$failures" -eq 0 ]; then
  echo "All sanitize-theme tests passed."
  exit 0
else
  echo "$failures test(s) failed."
  exit 1
fi
