#!/usr/bin/env bash
#
# test-parse-brief.sh — suite for cogni-workspace/scripts/parse-brief.py.
#
# Parses the real brief (libraries/EXAMPLE_BRIEF.md) plus two authored fixtures
# under tests/fixtures/brief/, which sit one directory below the runner's
# non-recursive globs and so are never discovered as suites themselves.
#
# Mutation recipe (the discriminator is pb26-fixture-41-parses-clean):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/tests/fixtures/brief/valid-slides-4.1.md \
#     --expr 's{  integrity: pass\n\x60\x60\x60\n}{  integrity: pass\n}' \
#     --test 'bash cogni-workspace/tests/test-parse-brief.sh' \
#     --case pb26-fixture-41-parses-clean
#
# Verdict: guard_verified. The search text occurs exactly once, and its closing
# fence is the fixture's LAST fence, so deleting it leaves the Generation
# Metadata block unclosed at EOF. The parser then returns success:false and
# pb26 goes red. \x60 is a backtick, written as an escape because the recipe is
# quoted inside a fenced block in the PR body.

set -u

failures=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PB="$ROOT/cogni-workspace/scripts/parse-brief.py"
EXB="$ROOT/cogni-workspace/libraries/EXAMPLE_BRIEF.md"
F41="$ROOT/cogni-workspace/tests/fixtures/brief/valid-slides-4.1.md"
F40="$ROOT/cogni-workspace/tests/fixtures/brief/unfenced-slides-4.0.md"

python3 "$PB" --brief "$EXB" --emit slide-data > "$TMPROOT/sd.json" 2>"$TMPROOT/sd.err"
python3 "$PB" --brief "$EXB" --emit outline    > "$TMPROOT/ol.json" 2>/dev/null
python3 "$PB" --brief "$EXB" --emit metadata   > "$TMPROOT/md.json" 2>/dev/null
python3 "$PB" --brief "$F41" --emit slide-data > "$TMPROOT/f41.json" 2>/dev/null
python3 "$PB" --brief "$F41" --emit metadata   > "$TMPROOT/f41m.json" 2>/dev/null
python3 "$PB" --brief "$F40" --emit slide-data > "$TMPROOT/f40.json" 2>/dev/null

# A structurally broken brief: an unclosed fence, built here rather than
# committed, because a deliberate corruption is not a corpus artifact.
{
  printf -- '---\n'
  printf 'type: presentation-brief\n'
  printf 'version: "4.1"\n'
  printf -- '---\n\n'
  printf '## Slide 1: Diese Folie wird nie geschlossen\n\n'
  printf '```yaml\n'
  printf 'Layout: title-slide\n'
  printf 'Title: Ohne schliessende Einfassung\n'
} > "$TMPROOT/broken.md"
python3 "$PB" --brief "$TMPROOT/broken.md" --emit slide-data > "$TMPROOT/broken.json" 2>"$TMPROOT/broken.err"

# --- pb01
if [ -f "$PB" ]; then
  echo "PASS: pb01-script-exists"
else
  echo "FAIL: pb01-script-exists parse-brief.py is missing"
  failures=$((failures + 1))
fi

# --- pb02
if ! grep -nE '^(import|from) ' "$PB" | grep -qvE '^[0-9]+:(import|from) (argparse|json|re|sys)\b'; then
  echo "PASS: pb02-stdlib-only-imports"
else
  echo "FAIL: pb02-stdlib-only-imports a non-stdlib import is present"
  failures=$((failures + 1))
fi

# --- pb03
if [ -f "$F41" ]; then
  echo "PASS: pb03-fixture-41-exists"
else
  echo "FAIL: pb03-fixture-41-exists valid-slides-4.1.md is missing"
  failures=$((failures + 1))
fi

# --- pb04
if [ -f "$F40" ]; then
  echo "PASS: pb04-fixture-40-exists"
else
  echo "FAIL: pb04-fixture-40-exists unfenced-slides-4.0.md is missing"
  failures=$((failures + 1))
fi

# --- pb05
if python3 -c "import json,sys; d=json.load(open('$TMPROOT/sd.json')); sys.exit(0 if d['success'] else 1)"; then
  echo "PASS: pb05-example-brief-envelope-success"
else
  echo "FAIL: pb05-example-brief-envelope-success EXAMPLE_BRIEF.md did not parse"
  failures=$((failures + 1))
fi

# --- pb06
python3 "$PB" --brief "$EXB" --emit bogus > "$TMPROOT/bad.json" 2>"$TMPROOT/bad.err"
if python3 -c "import json,sys; d=json.load(open('$TMPROOT/bad.json')); sys.exit(0 if d['success'] is False and d['error'] else 1)"; then
  echo "PASS: pb06-bad-emit-value-yields-envelope"
else
  echo "FAIL: pb06-bad-emit-value-yields-envelope an unlisted --emit did not answer with an envelope"
  failures=$((failures + 1))
fi

# --- pb07
python3 "$PB" --brief "$TMPROOT/does-not-exist.md" --emit slide-data > "$TMPROOT/miss.json" 2>"$TMPROOT/miss.err"
if python3 -c "import json,sys; d=json.load(open('$TMPROOT/miss.json')); sys.exit(0 if d['success'] is False else 1)"; then
  echo "PASS: pb07-missing-brief-yields-envelope"
else
  echo "FAIL: pb07-missing-brief-yields-envelope a missing --brief did not answer with an envelope"
  failures=$((failures + 1))
fi

# --- pb08
if python3 -c "import json,sys; d=json.load(open('$TMPROOT/broken.json')); e=d.get('error') or ''; sys.exit(0 if d['success'] is False and any(c.isdigit() for c in e) else 1)"; then
  echo "PASS: pb08-broken-fence-names-a-line"
else
  echo "FAIL: pb08-broken-fence-names-a-line an unclosed fence did not return a line number"
  failures=$((failures + 1))
fi

# --- pb09
if ! grep -q 'Traceback' "$TMPROOT/sd.err" "$TMPROOT/bad.err" "$TMPROOT/miss.err" "$TMPROOT/broken.err"; then
  echo "PASS: pb09-no-traceback-on-any-path"
else
  echo "FAIL: pb09-no-traceback-on-any-path a traceback reached stderr"
  failures=$((failures + 1))
fi

# --- pb10
if grep -q -- '--brief' "$PB" && grep -q -- '--emit' "$PB" && grep -q -- '--output' "$PB"; then
  echo "PASS: pb10-three-flags-present"
else
  echo "FAIL: pb10-three-flags-present a documented flag is missing"
  failures=$((failures + 1))
fi

# --- pb11
python3 "$PB" --brief "$EXB" --emit slide-data --output "$TMPROOT/out.json" > "$TMPROOT/out.stdout" 2>/dev/null
if [ -s "$TMPROOT/out.json" ] && python3 -c "import json,sys; d=json.load(open('$TMPROOT/out.stdout')); sys.exit(0 if d['success'] else 1)"; then
  echo "PASS: pb11-output-writes-and-stdout-keeps-envelope"
else
  echo "FAIL: pb11-output-writes-and-stdout-keeps-envelope --output suppressed the envelope or wrote nothing"
  failures=$((failures + 1))
fi

# --- pb12
if python3 -c "
import importlib.util, io, sys
buf = io.StringIO(); saved = sys.stdout; sys.stdout = buf
spec = importlib.util.spec_from_file_location('pb', '$PB')
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
sys.stdout = saved
model = mod.parse_brief('$EXB')
sys.exit(0 if buf.getvalue() == '' and len(model['slides']) == 13 else 1)"; then
  echo "PASS: pb12-spec-load-is-silent"
else
  echo "FAIL: pb12-spec-load-is-silent importing the module printed or did not expose parse_brief"
  failures=$((failures + 1))
fi

# --- pb13
if python3 -c "import json,sys; d=json.load(open('$TMPROOT/sd.json')); sys.exit(0 if len(d['data']['slides']) == 13 else 1)"; then
  echo "PASS: pb13-example-brief-has-13-slides"
else
  echo "FAIL: pb13-example-brief-has-13-slides the slide count does not match the headings"
  failures=$((failures + 1))
fi

# --- pb14
if python3 -c "
import json, sys
s = json.load(open('$TMPROOT/sd.json'))['data']['slides'][3]
hero = s['fields']['Hero-Stat-Box']; ctx = s['fields']['Context-Box']
sys.exit(0 if str(hero['Number']) == '688' and len(ctx['Bullets']) == 3 and all(isinstance(b, str) for b in ctx['Bullets']) else 1)"; then
  echo "PASS: pb14-hero-number-and-context-bullets-intact"
else
  echo "FAIL: pb14-hero-number-and-context-bullets-intact the 688 stat or its context bullets were altered"
  failures=$((failures + 1))
fi

# --- pb15
python3 -c "
import json
print(json.load(open('$TMPROOT/sd.json'))['data']['slides'][3]['speaker_notes'], end='')" > "$TMPROOT/notes.actual"
sed -n '268,282p' "$EXB" > "$TMPROOT/notes.expected"
if cmp -s "$TMPROOT/notes.actual" "$TMPROOT/notes.expected"; then
  echo "PASS: pb15-speaker-notes-byte-equal"
else
  echo "FAIL: pb15-speaker-notes-byte-equal the block scalar was trimmed, re-wrapped or re-indented"
  failures=$((failures + 1))
fi

# --- pb16
if python3 -c "
import json, sys, re
slides = json.load(open('$TMPROOT/sd.json'))['data']['slides']
bad = [k for s in slides for k in s['fields'] if re.match(r'^Q[1-9][0-9]*\$', k)]
sys.exit(0 if not bad else 1)"; then
  echo "PASS: pb16-no-q-alias-survives"
else
  echo "FAIL: pb16-no-q-alias-survives a Q1..Q4 key is still present in fields"
  failures=$((failures + 1))
fi

# --- pb17
if python3 -c "
import json, sys
s = json.load(open('$TMPROOT/sd.json'))['data']['slides'][2]
quads = [s['fields'].get('Quadrant-%d' % i) for i in range(1, 5)]
ok = all(isinstance(q, dict) and 'Label' in q and 'Sublabel' in q and 'Bullets' in q for q in quads)
sys.exit(0 if ok else 1)"; then
  echo "PASS: pb17-normalized-quadrants-keep-their-subkeys"
else
  echo "FAIL: pb17-normalized-quadrants-keep-their-subkeys normalization dropped a sub-key"
  failures=$((failures + 1))
fi

# --- pb18
if python3 -c "
import json, sys
s = json.load(open('$TMPROOT/f41.json'))['data']['slides'][1]
quads = [s['fields'].get('Quadrant-%d' % i) for i in range(1, 5)]
sys.exit(0 if all(isinstance(q, dict) and 'Number' not in q for q in quads) else 1)"; then
  echo "PASS: pb18-alias-normalization-invents-no-number"
else
  echo "FAIL: pb18-alias-normalization-invents-no-number a Number was synthesized for an alias that carried none"
  failures=$((failures + 1))
fi

# --- pb19
if python3 -c "
import json, sys
s = json.load(open('$TMPROOT/sd.json'))['data']['slides'][5]
got = [s['fields']['Quadrant-%d' % i]['Number'] for i in range(1, 5)]
sys.exit(0 if [str(g) for g in got] == ['688', '42%', '156%', '€2.8M'] else 1)"; then
  echo "PASS: pb19-canonical-quadrant-numbers-not-coerced"
else
  echo "FAIL: pb19-canonical-quadrant-numbers-not-coerced an opaque Number value was coerced or altered"
  failures=$((failures + 1))
fi

# --- pb20
if python3 -c "
import json, sys
s = json.load(open('$TMPROOT/sd.json'))['data']['slides'][3]
want = [{'n': 1, 'url': 'https://www.eba.bund.de/sicherheitsbericht-2024'},
        {'n': 2, 'url': 'https://www.bka.de/kriminalstatistik'}]
sys.exit(0 if s['citations'] == want else 1)"; then
  echo "PASS: pb20-citations-carry-number-and-url-in-order"
else
  echo "FAIL: pb20-citations-carry-number-and-url-in-order a citation number or url was dropped"
  failures=$((failures + 1))
fi

# --- pb21
if python3 -c "
import json, sys
s = json.load(open('$TMPROOT/sd.json'))['data']['slides'][12]
sys.exit(0 if s['citations'] == [] else 1)"; then
  echo "PASS: pb21-bare-sup-marker-is-not-a-citation"
else
  echo "FAIL: pb21-bare-sup-marker-is-not-a-citation a superscript without a url became a citation"
  failures=$((failures + 1))
fi

# --- pb22
if python3 -c "
import json, sys
import importlib.util
spec = importlib.util.spec_from_file_location('pb', '$PB')
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
keys = set(mod.SLIDE_KEYS)
slides = json.load(open('$TMPROOT/sd.json'))['data']['slides']
sys.exit(0 if len(keys) == 13 and all(set(s.keys()) == keys for s in slides) else 1)"; then
  echo "PASS: pb22-every-slide-carries-all-thirteen-keys"
else
  echo "FAIL: pb22-every-slide-carries-all-thirteen-keys a key was omitted instead of being null"
  failures=$((failures + 1))
fi

# --- pb23
if python3 -c "
import json, sys
slides = json.load(open('$TMPROOT/sd.json'))['data']['slides']
declared = [s for s in slides if 'Bottom-Banner' in s['fields']]
undeclared = [s for s in slides if 'Bottom-Banner' not in s['fields']]
ok = all(s['bottom_banner'] for s in declared) and all(s['bottom_banner'] is None for s in undeclared)
sys.exit(0 if ok and declared else 1)"; then
  echo "PASS: pb23-bottom-banner-surfaces-at-top-level"
else
  echo "FAIL: pb23-bottom-banner-surfaces-at-top-level a declared banner did not reach the slide top level"
  failures=$((failures + 1))
fi

# --- pb24
if python3 -c "
import json, sys
slides = json.load(open('$TMPROOT/sd.json'))['data']['slides']
declared = [s for s in slides if 'Diagram' in s['fields']]
undeclared = [s for s in slides if 'Diagram' not in s['fields']]
ok = all(s['diagram_mermaid'] and '\n' in s['diagram_mermaid'] for s in declared)
ok = ok and all(s['diagram_mermaid'] is None for s in undeclared)
sys.exit(0 if ok and len(declared) >= 2 else 1)"; then
  echo "PASS: pb24-diagram-retains-its-newlines"
else
  echo "FAIL: pb24-diagram-retains-its-newlines a mermaid block was collapsed or lost"
  failures=$((failures + 1))
fi

# --- pb25
if python3 -c "
import json, sys
s = json.load(open('$TMPROOT/f41.json'))['data']['slides'][2]
steps = [k for k in s['fields'] if k.startswith('Step-')]
sys.exit(0 if steps == ['Step-1', 'Step-2', 'Step-10'] else 1)"; then
  echo "PASS: pb25-step-keys-sort-numerically"
else
  echo "FAIL: pb25-step-keys-sort-numerically Step-10 did not follow Step-2"
  failures=$((failures + 1))
fi

# --- pb26
if python3 -c "import json,sys; d=json.load(open('$TMPROOT/f41.json')); sys.exit(0 if d['success'] else 1)"; then
  echo "PASS: pb26-fixture-41-parses-clean"
else
  echo "FAIL: pb26-fixture-41-parses-clean the 4.1 fixture did not parse"
  failures=$((failures + 1))
fi

# --- pb27
if python3 -c "
import json, sys
o = json.load(open('$TMPROOT/ol.json'))['data']['entries']
s = json.load(open('$TMPROOT/sd.json'))['data']['slides']
ok = len(o) == len(s) and [e['number'] for e in o] == [x['number'] for x in s]
ok = ok and all('headline' in e and 'fields' not in e and 'speaker_notes' not in e for e in o)
sys.exit(0 if ok else 1)"; then
  echo "PASS: pb27-outline-is-an-ordered-summary"
else
  echo "FAIL: pb27-outline-is-an-ordered-summary the outline lost order or is a slide-data dump"
  failures=$((failures + 1))
fi

# --- pb28
if python3 -c "
import json, sys
m = json.load(open('$TMPROOT/md.json'))['data']
fm = m['frontmatter']
ok = m['generation_metadata'] is None and 'generation_metadata' in m
ok = ok and isinstance(fm.get('design'), dict) and isinstance(fm.get('key_figures'), list)
sys.exit(0 if ok else 1)"; then
  echo "PASS: pb28-metadata-degrades-without-a-generation-block"
else
  echo "FAIL: pb28-metadata-degrades-without-a-generation-block metadata errored or flattened the frontmatter"
  failures=$((failures + 1))
fi

# --- pb29
if python3 -c "
import json, sys
m = json.load(open('$TMPROOT/f41m.json'))['data']
gm = m['generation_metadata']
sys.exit(0 if isinstance(gm, dict) and gm.get('validation', {}).get('integrity') == 'pass' else 1)"; then
  echo "PASS: pb29-metadata-populated-when-the-block-is-present"
else
  echo "FAIL: pb29-metadata-populated-when-the-block-is-present a present Generation Metadata block was not read"
  failures=$((failures + 1))
fi

# --- pb30
if python3 -c "
import json, sys
d = json.load(open('$TMPROOT/f40.json'))
ok = d['success'] and any('unfenced' in w for w in d['data']['warnings'])
sys.exit(0 if ok else 1)"; then
  echo "PASS: pb30-unfenced-40-parses-with-a-warning"
else
  echo "FAIL: pb30-unfenced-40-parses-with-a-warning the 4.0 shape did not parse or warned about nothing"
  failures=$((failures + 1))
fi

# --- pb31
if python3 -c "
import json, sys
s = json.load(open('$TMPROOT/sd.json'))['data']['slides'][0]
sys.exit(0 if s['fields'].get('Metadata') == 'Deutsche Bahn AG | TechVision Solutions | Februar 2026' else 1)"; then
  echo "PASS: pb31-pipes-in-a-scalar-stay-prose"
else
  echo "FAIL: pb31-pipes-in-a-scalar-stay-prose a value containing a pipe was read as a block scalar"
  failures=$((failures + 1))
fi

# --- pb32
if python3 -c "
import json, sys
m = json.load(open('$TMPROOT/md.json'))['data']
sys.exit(0 if m['unowned_sections'] == ['Key Differences from v2.0/v3.0'] else 1)"; then
  echo "PASS: pb32-unfenced-trailing-section-is-not-parsed"
else
  echo "FAIL: pb32-unfenced-trailing-section-is-not-parsed a trailing markdown section was claimed as yaml"
  failures=$((failures + 1))
fi

if [ "$failures" -eq 0 ]; then
  echo "All parse-brief tests passed."
  exit 0
else
  echo "$failures test(s) failed."
  exit 1
fi
