#!/usr/bin/env bash
#
# test-brief-to-outline.sh — suite for
# cogni-workspace/skills/story-to-slides/scripts/brief-to-outline.py.
#
# Exports libraries/EXAMPLE_BRIEF.md twice (default and --include-internal) and
# grades the outline against the library that owns the layout-to-type mapping.
# No committed fixtures: the real brief is the corpus.
#
# The shared predicates live in ONE place — $TMPROOT/outline_probe.py, written
# below — and every case imports them. They were originally inlined per case,
# which put three copies of the "walk the slide_points block" scanner in the
# file and, worse, gave bo06 its OWN copy of the predicate it exists to falsify:
# a later edit to bo05's copy alone would have left bo06 green while proving
# teeth for a predicate no longer under test.
#
# Mutation recipe (the discriminator is bo07-slide-points-max-four):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/skills/story-to-slides/scripts/brief-to-outline.py \
#     --expr 's{MAX_SLIDE_POINTS = 4}{MAX_SLIDE_POINTS = 9}' \
#     --test 'bash cogni-workspace/tests/test-brief-to-outline.sh' \
#     --case bo07-slide-points-max-four
#
# Verdict: guard_verified. The search text occurs exactly once. Nine of the
# thirteen slides carry more than four on-slide leaves, so raising the cap to 9
# emits five-or-more slide_points lines on those sections and bo07 goes red.

set -u

# Several cases import the exporter via spec_from_file_location. Without this,
# CPython writes a __pycache__/ next to the source inside the plugin tree, which
# test-relocated-skill-hygiene.sh P2 then flags as an unresolvable
# ${CLAUDE_PLUGIN_ROOT} reference — a suite polluting the tree it grades.
export PYTHONDONTWRITEBYTECODE=1

failures=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BTO="$ROOT/cogni-workspace/skills/story-to-slides/scripts/brief-to-outline.py"
EXB="$ROOT/cogni-workspace/libraries/EXAMPLE_BRIEF.md"
LIB="$ROOT/cogni-workspace/libraries/presentation-intent.md"
PPTX="$ROOT/cogni-workspace/libraries/pptx-layouts.md"

OUT="$TMPROOT/presentation-outline.md"
INC="$TMPROOT/with-internal.md"

cat > "$TMPROOT/outline_probe.py" <<'PYEOF'
"""Shared predicates for test-brief-to-outline.sh. Defined once, imported by
every case, so a case that falsifies a predicate falsifies THE predicate."""
import os
import re

BRIEF = open(os.environ['EXB'], encoding='utf-8').read()


def slides_of(brief=None):
    """(headline, body) per `## Slide N:` block in the brief."""
    text = BRIEF if brief is None else brief
    out = []
    for block in re.split(r'^## Slide \d+: ', text, flags=re.M)[1:]:
        head, _, body = block.partition('\n')
        out.append((head.strip(), body))
    return out


def slide_point_blocks(outline):
    """Every `slide_points:` block in an outline, as lists of raw lines."""
    blocks, current = [], None
    for line in outline.splitlines():
        if line.startswith('slide_points:'):
            current = []
            blocks.append(current)
            continue
        if current is not None:
            if line.startswith('- '):
                current.append(line[2:])
            else:
                current = None
    return blocks


def offenders(outline):
    """slide_points lines that are NOT verbatim substrings of the brief.

    Citation markers are reduced to `[N]` by the exporter, so they are stripped
    again here before the comparison. Copy is frozen: a line the renderer would
    read must appear in the brief exactly.
    """
    bad = []
    for block in slide_point_blocks(outline):
        for raw in block:
            stripped = re.sub(r'\[\d+\]', '', raw).strip()
            if stripped and stripped not in BRIEF:
                bad.append(stripped)
    return bad


def section_of(outline, headline):
    """The outline text belonging to one `## <headline>` section."""
    after = outline.split('## ' + headline, 1)[1]
    return after.split('\n## ', 1)[0]


def type_of(outline, headline):
    return re.search(r'^type: (.+)$', section_of(outline, headline), re.M).group(1)
PYEOF

python3 "$BTO" --brief "$EXB" --out "$OUT" > "$TMPROOT/default.json" 2>"$TMPROOT/default.err"
python3 "$BTO" --brief "$EXB" --out "$INC" --include-internal > "$TMPROOT/inc.json" 2>"$TMPROOT/inc.err"

export TMPROOT ROOT BTO EXB LIB PPTX OUT INC PYTHONPATH="$TMPROOT"

# --- bo01
if python3 -c "
import json, os, re, sys
from outline_probe import BRIEF
data = json.load(open(os.environ['TMPROOT'] + '/default.json'))['data']
total = len(re.findall(r'^## Slide \d+:', BRIEF, re.M))
internal = len(re.findall(r'^Slide-Kind: internal-prep\s*\$', BRIEF, re.M))
sections = len(re.findall(r'^## ', open(os.environ['OUT'], encoding='utf-8').read(), re.M))
sys.exit(0 if (sections == total - internal == data['sections'] and internal > 0) else 1)"; then
  echo "ok: bo01-default-section-count-derived"
else
  echo "FAIL: bo01-default-section-count-derived section count is not slides-minus-internal-prep"
  failures=$((failures + 1))
fi

# --- bo02
if python3 -c "
import json, os, re, sys
from outline_probe import BRIEF
total = len(re.findall(r'^## Slide \d+:', BRIEF, re.M))
inc = json.load(open(os.environ['TMPROOT'] + '/inc.json'))['data']
sections = len(re.findall(r'^## ', open(os.environ['INC'], encoding='utf-8').read(), re.M))
sys.exit(0 if sections == total == inc['sections'] else 1)"; then
  echo "ok: bo02-include-internal-emits-every-slide"
else
  echo "FAIL: bo02-include-internal-emits-every-slide --include-internal did not emit every slide"
  failures=$((failures + 1))
fi

# --- bo03
if python3 -c "
import os, re, sys
from outline_probe import slides_of
default = open(os.environ['OUT'], encoding='utf-8').read()
inc = open(os.environ['INC'], encoding='utf-8').read()
titles = [h for h, body in slides_of() if re.search(r'^Slide-Kind: internal-prep\s*\$', body, re.M)]
ok = bool(titles)
ok = ok and all(('## ' + t) not in default for t in titles)
ok = ok and all(('## ' + t) in inc for t in titles)
sys.exit(0 if ok else 1)"; then
  echo "ok: bo03-internal-prep-excluded-by-default"
else
  echo "FAIL: bo03-internal-prep-excluded-by-default an internal-prep slide leaked into the default outline"
  failures=$((failures + 1))
fi

# --- bo04
if python3 -c "
import importlib.util, os, re, sys
spec = importlib.util.spec_from_file_location('_bto', os.environ['BTO'])
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
tags = mod.load_type_map(os.environ['LIB'])['tags']
used = re.findall(r'^type: (.+)\$', open(os.environ['INC'], encoding='utf-8').read(), re.M)
# The library's own clause-3 vocabulary is eight tags; a wrapped clause silently
# yielding seven is the bug this length check pins.
sys.exit(0 if len(tags) == 8 and used and all(u in tags for u in used) else 1)"; then
  echo "ok: bo04-every-type-in-library-vocabulary"
else
  echo "FAIL: bo04-every-type-in-library-vocabulary a section carries a tag the library does not define"
  failures=$((failures + 1))
fi

# --- bo05
if python3 -c "
import os, sys
from outline_probe import offenders, slide_point_blocks
out = open(os.environ['INC'], encoding='utf-8').read()
blocks = slide_point_blocks(out)
sys.exit(0 if blocks and any(blocks) and not offenders(out) else 1)"; then
  echo "ok: bo05-slide-points-verbatim"
else
  echo "FAIL: bo05-slide-points-verbatim a slide_points line is not a substring of the brief"
  failures=$((failures + 1))
fi

# --- bo06
if python3 -c "
import os, sys
from outline_probe import offenders
out = open(os.environ['INC'], encoding='utf-8').read()
# Alter exactly one slide_points line; THE predicate bo05 ran must reject it.
altered, done = [], False
for line in out.splitlines():
    if not done and line.startswith('- '):
        altered.append(line + ' PARAPHRASED-BY-THE-RENDERER')
        done = True
    else:
        altered.append(line)
sys.exit(0 if done and offenders('\n'.join(altered)) else 1)"; then
  echo "ok: bo06-verbatim-check-rejects-an-altered-line"
else
  echo "FAIL: bo06-verbatim-check-rejects-an-altered-line the verbatim predicate passed an altered outline"
  failures=$((failures + 1))
fi

# --- bo07
if python3 -c "
import os, sys
from outline_probe import slide_point_blocks
blocks = slide_point_blocks(open(os.environ['INC'], encoding='utf-8').read())
sys.exit(0 if blocks and max(len(b) for b in blocks) <= 4 else 1)"; then
  echo "ok: bo07-slide-points-max-four"
else
  echo "FAIL: bo07-slide-points-max-four a section emitted more than four on-slide lines"
  failures=$((failures + 1))
fi

# --- bo08
if python3 -c "
import json, os, re, sys
figures = json.load(open(os.environ['TMPROOT'] + '/default.json'))['data']['key_figures']
marked = [f for f in figures if f.startswith('688')]
ok = len(marked) == 1 and re.search(r'^688 \(src: \[\d+\]\)\$', marked[0]) is not None
ok = ok and any(f.startswith('156%') and 'src:' not in f for f in figures)
sys.exit(0 if ok else 1)"; then
  echo "ok: bo08-key-figure-688-carries-provenance"
else
  echo "FAIL: bo08-key-figure-688-carries-provenance 688 lost its (src: [N]) marker or an uncited figure gained one"
  failures=$((failures + 1))
fi

# --- bo09
if python3 -c "
import importlib.util, os, re, sys
spec = importlib.util.spec_from_file_location('_bto', os.environ['BTO'])
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
# Independent re-extraction: this case never calls the exporter's loader to
# build its expectation, and grounds the layout set in a SECOND file.
lib = open(os.environ['LIB'], encoding='utf-8').read()
section = lib.split('## Layout to type mapping', 1)[1]
rows = {}
for line in section.splitlines():
    cells = [c.strip() for c in line.strip().strip('|').split('|')] if line.strip().startswith('|') else []
    if len(cells) >= 2 and cells[0].startswith('\`'):
        rows[cells[0].strip('\`')] = [p.strip().strip('\`') for p in cells[1].split('/') if p.strip()]
pptx = open(os.environ['PPTX'], encoding='utf-8').read()
declared = re.findall(r'^## Layout \d+: (\S+)\s*\$', pptx, re.M)
loaded = mod.load_type_map(os.environ['LIB'])['layouts']
ok = len(declared) == 11 and set(declared) == set(rows) == set(loaded)
ok = ok and all(rows[name] == loaded[name] for name in rows)
sys.exit(0 if ok else 1)"; then
  echo "ok: bo09-layout-type-parity-with-library"
else
  echo "FAIL: bo09-layout-type-parity-with-library the exporter and the library disagree on the layout mapping"
  failures=$((failures + 1))
fi

# --- bo10
if python3 -c "
import os, re, sys
from outline_probe import slides_of, type_of
out = open(os.environ['INC'], encoding='utf-8').read()
refs = [(h, b) for h, b in slides_of() if re.search(r'^Slide-Kind: references\s*\$', b, re.M)]
if len(refs) != 1:
    sys.exit(1)
head, body = refs[0]
layout = re.search(r'^Layout: (\S+)\s*\$', body, re.M).group(1)
sys.exit(0 if layout == 'two-columns-equal' and type_of(out, head) == 'table' else 1)"; then
  echo "ok: bo10-references-slide-types-as-table"
else
  echo "FAIL: bo10-references-slide-types-as-table the references slide took its Layout tag instead of the references tag"
  failures=$((failures + 1))
fi

# --- bo11
if python3 -c "
import os, re, sys
from outline_probe import slides_of, type_of
out = open(os.environ['INC'], encoding='utf-8').read()
modes = {}
for head, body in slides_of():
    if not re.search(r'^Layout: four-quadrants\s*\$', body, re.M):
        continue
    stat = bool(re.search(r'^\s+Number: ', body, re.M))
    modes[stat] = type_of(out, head)
sys.exit(0 if len(modes) == 2 and modes[True] == 'metric' and modes[False] == 'roles' else 1)"; then
  echo "ok: bo11-quadrant-mode-resolution"
else
  echo "FAIL: bo11-quadrant-mode-resolution four-quadrants did not resolve stat mode to metric and text mode to roles"
  failures=$((failures + 1))
fi

# --- bo12
if python3 -c "
import os, re, sys
from outline_probe import slides_of, section_of
out = open(os.environ['INC'], encoding='utf-8').read()
# The split is structural: any '>>'-prefixed line opens a section, taken
# ordinally. Matching language-specific literals instead would emit an empty
# talk_track on every slide of this German corpus.
#
# Asserting only 'talk_track is non-empty' is NOT enough and was measured to be
# vacuous: when the prefix stops matching, split_notes falls back to putting the
# WHOLE notes block into talk_track, which is still non-empty. So this case
# pins the split itself — both sections populated, and neither carrying the
# '>>' header lines that only survive the fallback.
expected = 0
for head, body in slides_of():
    sections = re.findall(r'^\s*>>.*\$', body, re.M)
    if len(sections) < 2:
        continue
    expected += 1
    block = section_of(out, head)
    talk = re.search(r'^talk_track:\n((?:(?!^\w+:).*\n)*)', block, re.M)
    notes = re.search(r'^notes:\n((?:(?!^\w+:).*\n)*)', block, re.M)
    if not (talk and talk.group(1).strip()):
        sys.exit(1)
    if not (notes and notes.group(1).strip()):
        sys.exit(1)
    if '>>' in talk.group(1) or '>>' in notes.group(1):
        sys.exit(1)
sys.exit(0 if expected >= 1 else 1)"; then
  echo "ok: bo12-speaker-notes-sections-split-structurally"
else
  echo "FAIL: bo12-speaker-notes-sections-split-structurally a slide with speaker notes produced an empty talk_track"
  failures=$((failures + 1))
fi

# --- bo13
if python3 -c "
import json, os, subprocess, sys
bto, tmp = os.environ['BTO'], os.environ['TMPROOT']
def envelope(args):
    proc = subprocess.run([sys.executable, bto] + args, capture_output=True, text=True)
    try:
        payload = json.loads(proc.stdout)
    except ValueError:
        return None
    return payload if set(payload) == {'success', 'data', 'error'} else None
missing = envelope(['--brief', tmp + '/does-not-exist.md'])
noargs = envelope([])
ok = missing is not None and missing['success'] is False
ok = ok and noargs is not None and noargs['success'] is False
ok = ok and 'Traceback' not in (missing['error'] + noargs['error'])
# The happy path must also be silent on stderr — captured at export time above.
ok = ok and os.path.getsize(tmp + '/default.err') == 0
ok = ok and os.path.getsize(tmp + '/inc.err') == 0
sys.exit(0 if ok else 1)"; then
  echo "ok: bo13-error-paths-emit-one-envelope"
else
  echo "FAIL: bo13-error-paths-emit-one-envelope an error path printed something other than the JSON envelope"
  failures=$((failures + 1))
fi

# --- bo14
if python3 -c "
import os, sys
out = open(os.environ['OUT'], encoding='utf-8').read()
wanted = [
    'note: copy is frozen — reproduce every line verbatim',
    'note: render citations as footnotes and keep the URLs',
    'note: attach theme.md only when no organization design system is configured',
]
sys.exit(0 if all(w in out for w in wanted) else 1)"; then
  echo "ok: bo14-trailing-meta-instructions-present"
else
  echo "FAIL: bo14-trailing-meta-instructions-present a trailing note: meta-instruction is missing"
  failures=$((failures + 1))
fi

# --- bo15
if python3 -c "
import json, os, re, sys
# The outline asserts 'copy is frozen', so on-slide copy the cap could not carry
# must be REPORTED, never dropped in silence. bo05 is a substring check and an
# omission passes it trivially; this is the missing no-line-lost guard.
data = json.load(open(os.environ['TMPROOT'] + '/inc.json'))['data']
capped = [w for w in data['warnings'] if w.startswith('slide_points capped at')]
if len(capped) != 1:
    sys.exit(1)
named = set(int(n) for n in re.findall(r'slide (\d+) \(-\d+\)', capped[0]))
sys.exit(0 if named else 1)"; then
  echo "ok: bo15-capped-copy-is-reported-not-dropped"
else
  echo "FAIL: bo15-capped-copy-is-reported-not-dropped on-slide copy was dropped without a warning naming the slides"
  failures=$((failures + 1))
fi

# --- bo16
if python3 -c "
import importlib.util, os, sys
spec = importlib.util.spec_from_file_location('_bto', os.environ['BTO'])
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
parser = mod.load_parser()
model = parser.parse_brief(os.environ['EXB'])
# Selection must SPREAD across a slide's on-slide fields, not exhaust the budget
# on the first one. A positional truncation of a flat leaf list loses every
# later field: on the four-quadrant stat slide it kept two quadrants and dropped
# the other two entirely.
worst = None
for slide in model['slides']:
    groups = mod._field_lines(slide)
    if len(groups) >= mod.MAX_SLIDE_POINTS and sum(len(g) for g in groups) > mod.MAX_SLIDE_POINTS:
        points = mod.slide_points(slide)
        represented = sum(1 for g in groups if any(line in points for line in g))
        if worst is None or represented < worst:
            worst = represented
sys.exit(0 if worst is not None and worst >= mod.MAX_SLIDE_POINTS else 1)"; then
  echo "ok: bo16-slide-points-spread-across-fields"
else
  echo "FAIL: bo16-slide-points-spread-across-fields the cap was spent on one field instead of spread across them"
  failures=$((failures + 1))
fi

# --- bo17
if python3 -c "
import os, re, sys
from outline_probe import slide_point_blocks, BRIEF
out = open(os.environ['INC'], encoding='utf-8').read()
# A slide whose evidence lines carry citations must land at least one of them in
# slide_points, with the marker reduced to bare [N] and the URL dropped. Sharing
# one lane between a box's Headline and its Bullets let the headline win every
# time, so no cited line ever reached the outline on a slide whose field count
# already equalled the cap.
flat = [line for block in slide_point_blocks(out) for line in block]
cited = [line for line in flat if re.search(r'\[\d+\]', line)]
reduced_from_sup = [line for line in cited if 'sup>' not in line and 'http' not in line]
ok = bool(reduced_from_sup)
# and the reduction must be lossless in the other direction: no raw marker leaks
ok = ok and not any('<sup>' in line for line in flat)
sys.exit(0 if ok else 1)"; then
  echo "ok: bo17-cited-evidence-line-reaches-slide-points"
else
  echo "FAIL: bo17-cited-evidence-line-reaches-slide-points no citation-bearing on-slide line survived the cap"
  failures=$((failures + 1))
fi

# --- bo18
# Re-export from a copy of the brief whose FRONTMATTER climax: integer names a
# different slide. Asserting the shape of today's climax line cannot tell the
# two derivations apart: an implementation that reads the frontmatter integer
# and renders it in the same format passes any such assertion. Changing that
# integer and requiring the line NOT to move is what discriminates.
PROBE_BRIEF="$TMPROOT/climax-probe-brief.md"
PROBE_OUT="$TMPROOT/climax-probe.md"
export PROBE_BRIEF PROBE_OUT
python3 -c "
import os, re
brief = open(os.environ['EXB'], encoding='utf-8').read()
present = int(re.search(r'^climax: (\d+)\s*\$', brief, re.M).group(1))
numbers = [int(n) for n in re.findall(r'^## Slide (\d+):', brief, re.M)]
# another REAL slide, so the copy-through implementation still resolves a slide
# and fails on the value rather than on a lookup miss
other = next(n for n in numbers if n != present)
open(os.environ['PROBE_BRIEF'], 'w', encoding='utf-8').write(
    re.sub(r'^climax: \d+\s*\$', 'climax: {0}'.format(other), brief, count=1, flags=re.M))
" && python3 "$BTO" --brief "$PROBE_BRIEF" --out "$PROBE_OUT" > "$TMPROOT/probe.json" 2>&1
if python3 -c "
import os, re, sys
from outline_probe import BRIEF, slides_of
out = open(os.environ['OUT'], encoding='utf-8').read()
probe = open(os.environ['PROBE_OUT'], encoding='utf-8').read()
def climax_of(text):
    found = re.search(r'^climax: (.+)\$', text, re.M)
    return found.group(1).strip() if found else None
here, there = climax_of(out), climax_of(probe)
# the line must exist at all (return None drops it)
ok = here is not None
# INDEPENDENCE: moving the frontmatter integer must not move the emitted line
ok = ok and here == there
# and it must name a real slide rather than echo the integer or a constant
ok = ok and any(headline and headline in here for headline, _ in slides_of())
sys.exit(0 if ok else 1)"; then
  echo "ok: bo18-climax-derived-from-emphasis-not-frontmatter"
else
  echo "FAIL: bo18-climax-derived-from-emphasis-not-frontmatter the climax line is missing, tracks the frontmatter integer, or names no slide"
  failures=$((failures + 1))
fi

# --- bo19
if python3 -c "
import os, sys
from outline_probe import BRIEF
# The design: sub-block of a document's OWN frontmatter, as raw lines.
def design_pairs(text):
    head = text.split('---', 2)
    if len(head) < 3 or '\ndesign:\n' not in head[1]:
        return []
    pairs = []
    for line in head[1].split('\ndesign:\n', 1)[1].splitlines():
        if line.startswith('  ') and line.strip():
            pairs.append(line.rstrip())
        else:
            break
    return pairs
# Compare the outline's OWN frontmatter design block against the brief's rather
# than substring-scanning the whole file: a pair also appears in a slide_points
# or talk_track line, and anchoring on the block coming FIRST would redden on any
# reordering of design / key_figures / climax that preserves the property.
# Derived from the brief, so a sixth sub-key needs no edit here — the exporter
# iterates design.items() generically and this comparison follows it.
expected = design_pairs(BRIEF)
out = open(os.environ['OUT'], encoding='utf-8').read()
ok = len(expected) == 5
ok = ok and design_pairs(out) == expected
# The contract item is [fidelity: literal] and names its evidence as greping the
# emitted outline for EACH of the five pairs, so that check is kept alongside the
# stronger comparison above rather than being replaced by it.
ok = ok and all(pair in out for pair in expected)
sys.exit(0 if ok else 1)"; then
  echo "ok: bo19-design-block-emitted-verbatim"
else
  echo "FAIL: bo19-design-block-emitted-verbatim the outline frontmatter does not carry the brief's design block verbatim"
  failures=$((failures + 1))
fi

# --- bo20
if python3 -c "
import json, os, sys
default = json.load(open(os.environ['TMPROOT'] + '/default.json'))
inc = json.load(open(os.environ['TMPROOT'] + '/inc.json'))
# bo13 covers the two ERROR paths; the happy path was ungraded, so a run could
# report success while leaking a Python None into a section body.
ok = all(set(env) == {'success', 'data', 'error'} for env in (default, inc))
ok = ok and default['success'] is True and inc['success'] is True
ok = ok and not default['error'] and not inc['error']
# The brief carries zero occurrences of the literal, so any hit is a leak. Note
# imagery: none is lower-case and does not collide. Scanned per file rather than
# concatenated, so a hit is attributable and cannot straddle the join.
ok = ok and 'None' not in open(os.environ['OUT'], encoding='utf-8').read()
ok = ok and 'None' not in open(os.environ['INC'], encoding='utf-8').read()
sys.exit(0 if ok else 1)"; then
  echo "ok: bo20-happy-path-envelope-and-no-none-leak"
else
  echo "FAIL: bo20-happy-path-envelope-and-no-none-leak envelope is not a clean success, or a literal None reached the outline"
  failures=$((failures + 1))
fi

# --- bo21
if python3 -c "
import os, re, sys
from outline_probe import BRIEF, section_of
out = open(os.environ['OUT'], encoding='utf-8').read()
# Every brief slide carrying a Source: must have that value reach its section's
# notes. Derived from the brief at run time, so a corpus that gains a third
# Source-bearing slide is covered without editing this case. The teeth are the
# slide that has a Source: and NO Speaker-Notes — for a slide that has both, the
# notes block is non-empty either way, so only this one falsifies dropping the
# Source append.
blocks = re.split(r'^## Slide (\d+): ', BRIEF, flags=re.M)[1:]
witnesses, bare = [], 0
for number, rest in zip(blocks[0::2], blocks[1::2]):
    headline = rest.split('\n', 1)[0].strip()
    found = re.search(r'^Source:\s*(.+?)\s*\$', rest, re.M)
    if not found or re.search(r'^Slide-Kind: internal-prep\s*\$', rest, re.M):
        continue
    witnesses.append((headline, found.group(1).strip().strip('\"')))
    if 'Speaker-Notes' not in rest:
        bare += 1
ok = len(witnesses) >= 2 and bare >= 1
ok = ok and all(source in section_of(out, headline) for headline, source in witnesses)
sys.exit(0 if ok else 1)"; then
  echo "ok: bo21-source-travels-into-notes"
else
  echo "FAIL: bo21-source-travels-into-notes a slide's Source: value did not reach its section notes"
  failures=$((failures + 1))
fi

if [ "$failures" -eq 0 ]; then
  echo "All brief-to-outline tests passed."
  exit 0
else
  echo "$failures test(s) failed."
  exit 1
fi
