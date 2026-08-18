#!/usr/bin/env bash
# Regression test for the shared theme-value guard (scripts/sanitize-theme.py)
# and its wiring into the workspace-dashboard renderer.
#
# Contract under test: an operator-supplied --design-variables
# value carrying a stylesheet/markup breakout (e.g. "#000000</style><script>...")
# must be rejected before it reaches the generated <style> block, with the
# renderer falling back to its built-in palette for that key.
#
# stdlib-only: bash + python3, no pip deps, per the repo-wide script
# convention — no file pointer here, so this comment cannot dangle.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
GUARD="$WS_ROOT/scripts/sanitize-theme.py"
RENDERER="$WS_ROOT/skills/workspace-dashboard/scripts/generate-dashboard.py"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

# assert_py "<label>" "<python expr, True to pass>" — the guard is bound as `g`
# and the renderer as `r`, so an assertion can check the guard against the real
# shipped DEFAULT_THEME instead of a synthetic stand-in. Both are import-safe
# (the renderer guards its entry point behind __main__).
assert_py() {
  local label="$1" expr="$2"
  if python3 - "$GUARD" "$RENDERER" <<PY
import importlib.util, sys
def _load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m); return m
g = _load("g", sys.argv[1])
r = _load("r", sys.argv[2])
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
# Discriminating probe: rgba(...) is rejected by strict but accepted by the two
# relaxed profiles, so this pins "falls back to *strict*". A markup-breakout
# probe would not — every profile's denylist rejects that, so it would still
# pass if the fallback were changed to font-aware.
assert_py "1h unknown profile falls back to strict" 'g.is_safe_value("rgba(0,0,0,0.1)", "nope") is False'

echo "=== font-aware profile ==="
# The exact DEFAULT_THEME value this plugin's own renderer ships (184 chars) —
# over strict's 120 cap, which is why import-aware could not reuse the bound.
DEF_IMPORT="@import url('https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&family=Outfit:wght@300;400;500;600;700&display=swap');"
assert_py "1i shipped default @import accepted" \
  "g.is_safe_value('''$DEF_IMPORT''', 'import-aware') is True"
assert_py "1j rgba shadow accepted" \
  'g.is_safe_value("0 1px 3px rgba(0,0,0,0.04), 0 1px 2px rgba(0,0,0,0.06)", "font-aware") is True'
assert_py "1k font stack accepted" \
  "g.is_safe_value(\"'Segoe UI', Roboto\", 'font-aware') is True"
# Forward-compat with cogni-visual/enrich-report, which normalizes a bare URL
# into an @import — the profile must not be hostile to the pre-normalized shape.
assert_py "1l bare https URL accepted" \
  'g.is_safe_value("https://fonts.googleapis.com/css2?family=Outfit:wght@400;500&display=swap", "import-aware") is True'
assert_py "1m radius accepted" 'g.is_safe_value("12px", "font-aware") is True'

# The defect this profile split exists to close. The shape gate has to tolerate
# '@' and ';' inside a URL (wght@400;500), so wiring it to a profile covering raw
# declaration values re-admits declaration chaining under the guise of a bare URL.
# font-aware must therefore carry NO shape gate at all.
INJ_URL="https://a.example/x;background:red;position:fixed"
assert_py "1ma bare-URL declaration chaining rejected under font-aware" \
  "g.is_safe_value('$INJ_URL', 'font-aware') is False"
assert_py "1mb shape gate absent from font-aware (shipped @import rejected)" \
  "g.is_safe_value('''$DEF_IMPORT''', 'font-aware') is False"
# A URL needing the gate (it carries '@' and ';') has no acceptance path left in
# font-aware. A plain URL with none of the forbidden characters still passes the
# denylist there, which is harmless — it cannot break out of the declaration.
assert_py "1mc gate-dependent URL rejected under font-aware" \
  'g.is_safe_value("https://fonts.googleapis.com/css2?family=Outfit:wght@400;500", "font-aware") is False'
# ...and the payload must not sneak through the section policy either.
assert_py "1md fonts section rejects the injection payload" \
  "g.sanitize_section('fonts', {'body':'$INJ_URL'}, {'body':'Roboto'}) == ({'body':'Roboto'}, ['body'])"
assert_py "1me shadows section rejects the injection payload" \
  "g.sanitize_section('shadows', {'sm':'$INJ_URL'}, {'sm':'0 1px 3px rgba(0,0,0,0.04)'}) == ({'sm':'0 1px 3px rgba(0,0,0,0.04)'}, ['sm'])"
assert_py "1mf radius section rejects the injection payload" \
  "g.sanitize_section('radius', '$INJ_URL', '12px') == ('12px', ['radius'])"
# Isolates the '@' clause of the font-aware denylist. 1mb and 1mc both feed
# payloads carrying a ';' too, so the ';' clause alone accounts for their
# rejection and neither would notice '@' going missing. This payload shares
# exactly one character with the denylist, so it fails iff '@' is dropped.
assert_py "1mg font-aware rejects a bare @ carrying no other denylisted character" \
  'g.is_safe_value("@import url(https://evil.example/x.css)", "font-aware") is False'
# Generalises 1mg to the whole table: "a" + c shares exactly one character with
# the profile's denylist, so it is rejected iff that character is still listed.
# Hardcoded on purpose — reading the sets from g._PROFILES would walk the table
# a mutation edits, so a removed character would silently stop being tested.
# Two-char payloads clear every max_len, and import-aware's shape gate (anchored
# on '@import url(' / 'https://') cannot match a value starting with 'a'.
# Pins removals only: a character or profile ADDED to _PROFILES is not covered.
assert_py "1mh every denylist character is independently rejected" \
  'all(g.is_safe_value("a" + c, p) is False for p, cs in {"strict": "<>{}();@\\", "font-aware": "<>{};@\\", "import-aware": "<>{};@\\"}.items() for c in cs)'
assert_py "1n style breakout still rejected" \
  'g.is_safe_value("</style><script>alert(1)</script>", "font-aware") is False'
assert_py "1o declaration injection rejected" \
  'g.is_safe_value("red; background-image: url(https://evil.example/b.png)", "font-aware") is False'
assert_py "1p rule-block injection rejected" \
  'g.is_safe_value("red} body{background:red", "font-aware") is False'
# The shape-gate rejections now belong to import-aware, the only profile that
# carries the gate. Every one must still fail closed after the move — a gate that
# relocated but stopped rejecting would be strictly worse than the original bug.
assert_py "1q data: scheme rejected" \
  "g.is_safe_value(\"@import url('data:text/css,body{color:red}');\", 'import-aware') is False"
assert_py "1r http: scheme rejected" \
  "g.is_safe_value(\"@import url('http://a.example/x.css');\", 'import-aware') is False"
assert_py "1s protocol-relative rejected" \
  "g.is_safe_value(\"@import url('//a.example/x.css');\", 'import-aware') is False"
assert_py "1t chained @import rejected" \
  "g.is_safe_value(\"@import url('https://a.example/x.css');@import url('https://b.example/y.css');\", 'import-aware') is False"
assert_py "1u media-qualified @import rejected" \
  "g.is_safe_value(\"@import url('https://a.example/x.css') screen;\", 'import-aware') is False"
# The shape gate is anchored ^...\Z with no trailing \s* — anything after the
# statement fails closed. Both details are load-bearing: \Z alone still accepts a
# trailing newline if a \s* precedes it, and plain $ accepts one outright.
assert_py "1v @import with trailing declaration rejected" \
  "g.is_safe_value(\"@import url('https://a.example/x.css'); body{color:red}\", 'import-aware') is False"
assert_py "1w @import with trailing newline rejected" \
  "g.is_safe_value(\"@import url('https://a.example/x.css');\n\", 'import-aware') is False"
assert_py "1x @import with trailing space rejected" \
  "g.is_safe_value(\"@import url('https://a.example/x.css'); \", 'import-aware') is False"
assert_py "1y over-length rejected" \
  'g.is_safe_value("https://a.example/" + "a"*300, "import-aware") is False'
# The breakout family must stay rejected under import-aware too — the gate adds
# an acceptance path, it must not subtract any denylist coverage.
assert_py "1ya style breakout rejected under import-aware" \
  'g.is_safe_value("</style><script>alert(1)</script>", "import-aware") is False'
assert_py "1yb rule-block injection rejected under import-aware" \
  'g.is_safe_value("red} body{background:red", "import-aware") is False'
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
# The \$ here used to be escaped, so both sides compared the *literal* string
# "\$DEF_IMPORT" and the assertion held without ever exercising an import value.
assert_py "2j scalar import accepted" \
  "g.sanitize_section('google_fonts_import', '''$DEF_IMPORT''', '') == ('''$DEF_IMPORT''', [])"
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

# google_fonts_import is emitted immediately before ':root {', so a value that is
# not a self-terminating at-rule lets CSS error recovery swallow the whole :root
# block — every theme variable silently lost. Both non-terminating shapes the
# gate accepts are normalized to one canonical statement.
assert_py "2o bare URL normalized into a terminated @import" \
  "g.sanitize_section('google_fonts_import', 'https://fonts.googleapis.com/css2?family=Outfit', '') == (\"@import url('https://fonts.googleapis.com/css2?family=Outfit');\", [])"
assert_py "2p semicolon-less @import normalized" \
  "g.sanitize_section('google_fonts_import', \"@import url('https://a.example/x.css')\", '') == (\"@import url('https://a.example/x.css');\", [])"
# (2j above already pins the canonical import round-tripping byte-identically.)
# Passes the denylist but is no kind of import — no valid rendering in that slot.
assert_py "2r non-import scalar falls back to default" \
  "g.sanitize_section('google_fonts_import', 'Roboto', '') == ('', ['google_fonts_import'])"
assert_py "2s normalize_font_import returns None on a non-import" \
  'g.normalize_font_import("Roboto") is None'

# _URL's character class is the load-bearing safety property of the normalizer:
# it is what makes re-wrapping the captured URL in url('...') provably
# well-formed. Nothing else pins it — widening it to https://[^\s]+ leaves every
# other assertion in this file green while making the guard inject a live rule
# (the URL closes its own wrapper, terminates the at-rule, and opens a block).
# One assertion per excluded character class, so a partial widening is caught too.
assert_py "2t quote in URL rejected (would close the url('...') wrapper)" \
  "g.is_safe_value(\"https://a.example/x');}body{background:red\", 'import-aware') is False"
assert_py "2u normalize refuses a quote-bearing URL" \
  "g.normalize_font_import(\"https://a.example/x')\") is None"
assert_py "2w backslash in URL rejected" \
  "g.is_safe_value('https://a.example/x\\\\y', 'import-aware') is False"
assert_py "2x angle bracket in URL rejected" \
  "g.is_safe_value('https://a.example/x<style>', 'import-aware') is False"
assert_py "2y brace in URL rejected" \
  "g.is_safe_value('https://a.example/x{y}', 'import-aware') is False"
# Parens and whitespace are NOT in the denylist (font-aware needs parens for
# rgba(...)), so these pass is_safe_value and are stopped at the emission
# boundary instead — the acceptance-is-not-sufficiency property. Asserting them
# on is_safe_value would be asserting the wrong thing; assert where it bites.
assert_py "2v paren in URL never emitted" \
  "g.normalize_font_import('https://a.example/x)') is None"
assert_py "2z whitespace in URL never emitted" \
  "g.normalize_font_import('https://a.example/x y') is None"
assert_py "2v2 paren-bearing import falls back to default" \
  "g.sanitize_section('google_fonts_import', 'https://a.example/x)', '') == ('', ['google_fonts_import'])"
# The same payload must not survive the section policy either.
assert_py "2za wrapper-closing payload falls back to default" \
  "g.sanitize_section('google_fonts_import', \"https://a.example/x');}body{background:red\", '') == ('', ['google_fonts_import'])"
# An import-aware profile forced onto a dict section must not smuggle the gate
# back into a declaration slot — the per-key path cannot normalize.
assert_py "2zb import-aware forced on a dict section does not accept a gate-shaped value" \
  "g.sanitize_section('fonts', {'body':'$INJ_URL'}, {'body':'Roboto'}, 'import-aware') == ({'body':'Roboto'}, ['body'])"
# Unknown sections fail closed rather than raising, matching _profile.
assert_py "2zc unknown section falls back to strict instead of raising" \
  "g.sanitize_section('gradients', {'a':'rgba(0,0,0,0.1)'}, {'a':'none'}) == ({'a':'none'}, ['a'])"

echo "=== shipped defaults must survive their own profiles ==="
# Arity first, so the all()-loops below cannot pass vacuously on an empty dict.
assert_py "5a DEFAULT_THEME ships 4 shadows and 3 font stacks" \
  "len(r.DEFAULT_THEME['shadows']) == 4 and len(r.DEFAULT_THEME['fonts']) == 3"
assert_py "5b every shipped shadow passes font-aware" \
  "all(g.is_safe_value(v, 'font-aware') for v in r.DEFAULT_THEME['shadows'].values())"
assert_py "5c every shipped font stack passes font-aware (incl. the 91-char one)" \
  "all(g.is_safe_value(v, 'font-aware') for v in r.DEFAULT_THEME['fonts'].values())"
assert_py "5d shipped google_fonts_import passes import-aware" \
  "g.is_safe_value(r.DEFAULT_THEME['google_fonts_import'], 'import-aware')"
assert_py "5e shipped radius passes font-aware" \
  "g.is_safe_value(r.DEFAULT_THEME['radius'], 'font-aware')"

echo "=== CLI envelope ==="
cat > "$TMPROOT/dv-evil.json" <<'EOF'
{"colors": {"background": "#000000</style><script>alert(1)</script>", "primary": "#111111"}, "status": {"danger": "#f00"}}
EOF
python3 "$GUARD" "$TMPROOT/dv-evil.json" > "$TMPROOT/cli-evil.json"
assert_json "3a CLI reports rejected color key" "$TMPROOT/cli-evil.json" \
  'd["success"] and d["data"]["rejected"].get("colors")==["background"]' 
python3 "$GUARD" >/dev/null 2>&1 && fail "3b CLI no-arg errors" || pass "3b CLI no-arg errors"
# The --profile gate rejects only an unknown *forced* profile, so pin the
# rejecting branch on both its exit status and its envelope. 3fc already covers
# a valid --profile semantically; 3bc adds the exit-code-0 half no check had.
python3 "$GUARD" "$TMPROOT/dv-evil.json" --profile=bogus > "$TMPROOT/cli-bogus.json" 2>/dev/null \
  && fail "3ba CLI unknown profile errors" || pass "3ba CLI unknown profile errors"
assert_json "3bb CLI unknown profile still prints an envelope" "$TMPROOT/cli-bogus.json" \
  'd["success"] is False and d["data"] is None and "bogus" in d["error"]'
python3 "$GUARD" "$TMPROOT/dv-evil.json" --profile=strict >/dev/null 2>&1 \
  && pass "3bc CLI valid forced profile accepted" || fail "3bc CLI valid forced profile accepted"

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
# Paired with the checked count so this cannot hold vacuously: a pure negative
# ("not in rejected") would still pass if the CLI stopped walking those sections
# altogether. The fixture supplies 4 override values across 4 sections.
assert_json "3e CLI accepts legitimate shadow + radius" "$TMPROOT/cli-font-evil.json" \
  '"shadows" not in d["data"]["rejected"] and "radius" not in d["data"]["rejected"] and d["data"]["checked"]==4'
assert_json "3f CLI reports per-section profiles" "$TMPROOT/cli-font-evil.json" \
  'd["data"]["section_profiles"]["colors"]=="strict" and d["data"]["section_profiles"]["fonts"]=="font-aware"'
assert_json "3fa CLI reports import-aware for the import slot" "$TMPROOT/cli-font-evil.json" \
  'd["data"]["section_profiles"]["google_fonts_import"]=="import-aware"'
# Envelope back-compat: `profile` has always been a string. Reporting only what
# was *forced* would make it null by default — a type change on a field callers
# already read. The per-section detail rides on `section_profiles` instead.
assert_json "3fb CLI profile stays a string by default" "$TMPROOT/cli-font-evil.json" \
  'd["data"]["profile"]=="strict"'
python3 "$GUARD" "$TMPROOT/dv-font-evil.json" --profile=font-aware > "$TMPROOT/cli-forced.json"
assert_json "3fc forced profile reported and applied to every section" "$TMPROOT/cli-forced.json" \
  'd["data"]["profile"]=="font-aware" and set(d["data"]["section_profiles"].values())=={"font-aware"}'
# An absent/empty scalar is not an override: never counted, never rejected.
cat > "$TMPROOT/dv-empty-import.json" <<'EOF'
{"colors": {"background": "#123456"}, "google_fonts_import": ""}
EOF
python3 "$GUARD" "$TMPROOT/dv-empty-import.json" > "$TMPROOT/cli-empty.json"
assert_json "3g CLI skips empty scalar section" "$TMPROOT/cli-empty.json" \
  'd["data"]["rejected"]=={} and d["data"]["checked"]==1' 

echo "=== wired renderer end-to-end ==="
WS="$TMPROOT/ws"; mkdir -p "$WS"
# Result sinks live under the per-run temp root rather than a fixed shared path, so two
# concurrent runs of this suite cannot overwrite each other's documents mid-assertion.
run_render() { python3 "$RENDERER" "$WS" --design-variables "$1" --output "$WS/out.html" >"$TMPROOT/render-out.json" 2>"$TMPROOT/render-err.txt"; }

# Malicious color value must not reach the output; renderer must still succeed.
run_render "$TMPROOT/dv-evil.json"
assert_json "4a malicious render succeeds" "$TMPROOT/render-out.json" 'd.get("status")=="ok"'
assert_lacks "4b </style><script> not in output" '</style><script>' "$WS/out.html"
assert_has   "4c built-in background applied instead" '#FAFAF8' "$WS/out.html"
assert_json "4d rejection surfaced as warning" "$TMPROOT/render-out.json" 'd.get("theme_warnings")'

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
assert_json "4g font-evil render succeeds" "$TMPROOT/render-out.json" 'd.get("status")=="ok"'
assert_lacks "4h @import breakout not in output" '<script>alert(1)</script>' "$WS/out.html"
assert_lacks "4i font declaration injection not in output" 'background-image: url(https://evil.example' "$WS/out.html"
assert_json "4j font rejection surfaced as warning" "$TMPROOT/render-out.json" 'd.get("theme_warnings")'
# Legitimate rgba shadow and radius from the same fixture must survive.
assert_has "4k legitimate rgba shadow preserved" 'rgba(0,0,0,0.04)' "$WS/out.html"

# An empty google_fonts_import means "no import" — a valid theme, so no warning.
run_render "$TMPROOT/dv-empty-import.json"
assert_json "4l empty import produces no warning" "$TMPROOT/render-out.json" 'not d.get("theme_warnings")'
# ...and "no import" must mean no import, not a silent fall back to DEFAULT_THEME's
# hard-coded Google Fonts URL. Without this the absence is indistinguishable in
# the output from the default having been applied.
assert_lacks "4l2 no google-fonts fallback on empty import" 'fonts.googleapis.com' "$WS/out.html"

# End-to-end proof for the profile split: a bare URL carrying chained declarations
# must never reach :root, while the rest of the theme still applies.
cat > "$TMPROOT/dv-font-url-injection.json" <<'EOF'
{"colors": {"background": "#123456"},
 "fonts": {"body": "https://a.example/x;background:red;position:fixed"}}
EOF
run_render "$TMPROOT/dv-font-url-injection.json"
assert_json "4p url-injection render succeeds" "$TMPROOT/render-out.json" 'd.get("status")=="ok"'
assert_json "4q url-injection surfaced as warning" "$TMPROOT/render-out.json" 'd.get("theme_warnings")'
assert_lacks "4r injected declaration not in output" 'a.example' "$WS/out.html"
assert_has   "4s theming otherwise intact" '#123456' "$WS/out.html"

# A bare-URL import is normalized to a terminated @import, so the following
# :root block survives instead of being swallowed by CSS error recovery.
cat > "$TMPROOT/dv-bare-import.json" <<'EOF'
{"colors": {"background": "#123456"},
 "google_fonts_import": "https://fonts.googleapis.com/css2?family=Outfit&display=swap"}
EOF
run_render "$TMPROOT/dv-bare-import.json"
assert_json "4t bare-import render succeeds" "$TMPROOT/render-out.json" 'd.get("status")=="ok"'
assert_has "4u bare URL normalized into a terminated @import" \
  "@import url('https://fonts.googleapis.com/css2?family=Outfit&display=swap');" "$WS/out.html"
assert_has "4v :root not swallowed — theme variable still applied" '#123456' "$WS/out.html"

# Partial fonts override used to KeyError in render_css (it indexes headers/body/mono).
cat > "$TMPROOT/dv-partial-fonts.json" <<'EOF'
{"fonts": {"body": "'Inter', sans-serif"}}
EOF
run_render "$TMPROOT/dv-partial-fonts.json"
assert_json "4m partial fonts override renders" "$TMPROOT/render-out.json" 'd.get("status")=="ok"'
assert_has "4n header font backfilled from defaults" "'Bricolage Grotesque'" "$WS/out.html"
assert_has "4o overridden body font still applied" "'Inter', sans-serif" "$WS/out.html"

echo "=== renderer degrades against a stale or absent guard ==="
# The guard is loaded by path from its home plugin, so an installed copy can
# predate `sanitize_section` yet import cleanly — the call is then an
# AttributeError at render time, which the import-time try/except cannot catch.
# That is strictly worse than no guard at all, so both degraded shapes are tested.
LEGACY="$TMPROOT/legacy"
mkdir -p "$LEGACY/scripts" "$LEGACY/skills/workspace-dashboard/scripts"
cp "$RENDERER" "$LEGACY/skills/workspace-dashboard/scripts/generate-dashboard.py"
# The renderer resolves ../../../scripts/sanitize-theme.py from its own __file__,
# so this stub is what the copied renderer loads. It exposes only the pre-PR
# surface: is_safe_value + sanitize_values, and no sanitize_section.
cat > "$LEGACY/scripts/sanitize-theme.py" <<'EOF'
"""Stand-in for a guard copy predating sanitize_section (base-commit surface)."""
_FORBIDDEN = set("<>{}();@\\")


def is_safe_value(value, profile="strict"):
    return isinstance(value, str) and 0 < len(value) <= 120 and not (_FORBIDDEN & set(value))


def sanitize_values(values, defaults, profile="strict"):
    clean, rejected = dict(defaults), []
    if isinstance(values, dict):
        for key in defaults:
            if key not in values:
                continue
            if is_safe_value(values[key], profile):
                clean[key] = values[key]
            else:
                rejected.append(key)
    return clean, sorted(rejected)
EOF
LEGACY_RENDERER="$LEGACY/skills/workspace-dashboard/scripts/generate-dashboard.py"
LWS="$TMPROOT/lws"; mkdir -p "$LWS"
# Same per-run temp-root discipline as the render helper above.
run_legacy() { python3 "$LEGACY_RENDERER" "$LWS" --design-variables "$1" --output "$LWS/out.html" >"$TMPROOT/legacy-out.json" 2>"$TMPROOT/legacy-err.txt"; }

run_legacy "$TMPROOT/dv-evil.json"
assert_json "6a stale guard still renders (no AttributeError)" "$TMPROOT/legacy-out.json" 'd.get("status")=="ok"'
assert_lacks "6b stale guard still blocks the colour breakout" '</style><script>' "$LWS/out.html"
assert_has   "6c stale guard falls back to the built-in palette" '#FAFAF8' "$LWS/out.html"
# render_css indexes fonts[headers|body|mono] directly, so the degraded path must
# still backfill or the render dies with a KeyError instead of an AttributeError.
run_legacy "$TMPROOT/dv-partial-fonts.json"
assert_json "6d stale guard handles a partial fonts override" "$TMPROOT/legacy-out.json" 'd.get("status")=="ok"'
assert_has   "6e stale guard backfills the omitted header font" "'Bricolage Grotesque'" "$LWS/out.html"

# And with no guard at all — the unguarded pass-through branch. It must still
# backfill: render_css indexes the fonts keys directly, so passing a partial
# override straight through raised KeyError and made theming a hard dependency
# in precisely the case the fallback exists to survive.
rm -f "$LEGACY/scripts/sanitize-theme.py"
run_legacy "$TMPROOT/dv-partial-fonts.json"
assert_json "6f absent guard still renders" "$TMPROOT/legacy-out.json" 'd.get("status")=="ok"'
assert_has   "6g absent guard backfills the omitted header font" "'Bricolage Grotesque'" "$LWS/out.html"
assert_has   "6h absent guard still applies the override" "'Inter', sans-serif" "$LWS/out.html"

echo
if [ "$failures" -eq 0 ]; then
  echo "All sanitize-theme tests passed."
  exit 0
else
  echo "$failures test(s) failed."
  exit 1
fi
