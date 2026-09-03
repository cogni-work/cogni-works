#!/usr/bin/env python3
"""Report Swiss-ss spellings sitting in ß positions across one engagement's corpus.

The register states the German orthography rule as prose — canonical section (a) in
cogni-workspace, which references/user-facing-output.md section (a) points at rather
than restating — and prose loses to data: an engagement whose stored files are written in
Swiss ss teaches every later turn to keep writing it, because that corpus reaches the
model as in-context evidence while the rule is a paragraph read once. This scan makes
that drift visible so it stops reinforcing itself silently.

Detection is a CURATED-LIST HEURISTIC WITH BOUNDED RECALL. Only the pairs listed in
SWISS_PAIRS are found; any Swiss form not on the list is missed by design, and
genuinely ambiguous spellings are left off on purpose to keep precision high. A
zero-finding report is therefore NOT proof that the corpus is ß-correct — it means
nothing on the list appeared. "ß position" cannot be derived from spelling alone,
because correct German uses ss freely (dass, muss, Prozess), so a bare `ss` match
would be all false positives.

PRECISION IS BOUNDED THE SAME WAY, by the completeness of the per-entry guard lists
(_ENTRY_GUARDS / _ENTRY_LEFT_GUARDS) rather than of SWISS_PAIRS. Where an entry can sit
inside a correct-German word — the ss straddling a morpheme boundary, as in
Beweis+sicherung — only a listed guard stem suppresses it, so an unlisted one reports as
drift with a suggestion that is wrong. Proper nouns are the other known false-positive
class and the guards do not cover them at all: a surname like Weiss or Strasser reports
confidently and wrongly, on exactly the stakeholder text an engagement corpus carries.
Recall and precision are both curated here; a finding is a prompt to look, not a verdict.

Read-only. Nothing under the engagement root is opened for writing, and there is no
repair mode: finding drift and fixing it are separate concerns.

SCANNED SET. Everything under the engagement root ending in .md or .json is scanned,
including dot-directories such as .metadata/ — decision-log.json lives there and carries
prose. Only .git is skipped by path. sources/ and output/ ARE scanned deliberately:
sources/ is the verbatim third-party inbox and may legitimately be Swiss, and output/ is
a deliverable surface, but both are files a consultant can edit, so drift in either is
worth seeing — an exclusion would have to be justified by provenance the scan cannot
verify. The one exclusion is by content, not path: a generated echo — in practice the
engagement-root README.md and assumptions.md, written by generate-engagement-readme.py and
register-generator.py — is skipped when it carries those generators' own footer sentinel
(see GENERATED_MARKER_SENTINEL below), which is what the generators themselves treat as
authoritative. Naming the two files is not the same as excluding them by path: a
marker-less README.md is hand-authored and IS scanned, which is the point.

Each finding carries a coordinate as well as a line: markdown findings carry a 1-based
`column`, JSON findings a 0-based `value_offset` into the decoded value. Without one, two
occurrences of the same form on a line are byte-identical objects, and several hits
inside one long JSON value all collapse onto that value's start line.

Finding drift is a SUCCESSFUL scan — it exits 0 with a non-zero data.total_findings.
Consumers branch on data.total_findings, never on the exit code. A non-zero exit means
the scan could not run at all.

Usage:
  python3 orthography-drift-scan.py <engagement-dir>

Output: single-line JSON envelope {"success": bool, "data": {...}, "error": str}.
"""

import json
import os
import re
import sys

# --- swiss-pairs-begin ---
# The single machine-readable home of the pair list. Each entry maps a Swiss ss
# spelling to its standard-German ß form. Matching is stem/substring, so a bare
# entry also reports inside a compound (Grösse -> Messgrösse).
SWISS_PAIRS = (
    ("Grösse", "Größe"),
    ("grösser", "größer"),
    ("grösste", "größte"),
    ("Massnahme", "Maßnahme"),
    ("Strasse", "Straße"),
    ("heisst", "heißt"),
    ("heissen", "heißen"),
    ("schliesslich", "schließlich"),
    ("ausserhalb", "außerhalb"),
    ("draussen", "draußen"),
    ("gemäss", "gemäß"),
    ("weiss", "weiß"),
)
# --- swiss-pairs-end ---

# Deliberately NOT entries, so the scan stays trustworthy rather than noisy:
#   Masse  — ambiguous homograph. "Masse" (mass/crowd) is correct standard German;
#            only "Maße" (measurements) is the ß form. Spelling cannot disambiguate.
#   Busse  — ambiguous homograph. "Busse" (buses) is correct; "Buße" (penance) is not.
#   gross / fuss — bare stems too short to match safely; they would fire inside
#            correct words. The inflected forms that are safe appear above instead.
# Correct short-vowel ss words (dass, muss, Prozess, Einfluss) are simply never
# entries, which is why they cannot be reported.

# Per-entry exceptions, keyed to the entry that needs them so the guard can never
# widen to a neighbouring form. "weiss" is the only entry with a correct-German
# right-extension: "weissagen" / "Weissagung" keep their ss.
_ENTRY_GUARDS = {"weiss": ("weissag",)}

# Left-side counterpart, keyed identically so it can never widen to another entry. Here
# the ss is not one morpheme's but two: a "-weis" stem meets a second element opening in
# s (Beweis+sicherung, Beweis+stück, Ausweis+stelle). That is correct standard German and
# there is no ß form to suggest, so the match is dropped rather than reported.
# The stems are the bound forms of the -weisen verbs, which is what makes the list
# extensible rather than anecdotal: each is a real first element that can take an
# s-initial second element. Adding one costs no recall, because no Swiss form contains a
# -weis stem followed by ss.
# "reis" is deliberately absent: "weiss" cannot match inside a Reis/Reiß word at all (no
# w), so the stem would suppress nothing that is ever matched.
# A bare "is the preceding character a letter?" test would be shorter and wrong: it would
# also suppress schneeweiss, a genuine Swiss compound whose ß form is schneeweiß.
_ENTRY_LEFT_GUARDS = {
    "weiss": (
        "beweis",
        "ausweis",
        "nachweis",
        "hinweis",
        "verweis",
        "anweis",
        "abweis",
        "erweis",
        "zuweis",
        "einweis",
        "überweis",
        "unterweis",
    )
}

# Prose-bearing JSON keys, per references/data-model.md. Every other value in these
# files is an engine token (state, dt_stage, slugs, ids, kind, verdict) and is never
# read, so a token that happens to contain an ss cannot produce a finding.
PROSE_KEYS = (
    "title",
    "framing",
    "name",
    "rationale",
    "decision",
    "question",
    "summary",
    "intent",
    "key_question",
)

# Generated echoes restate prose sourced elsewhere, so a finding in one points at a
# symptom rather than the file a consultant would edit. Identified by the footer
# sentinel the generators themselves write and key their overwrite guards on
# (generate-engagement-readme.py, register-generator.py), NOT by a hardcoded path
# list: those same guards treat a marker-less file as hand-authored, so excluding a
# path outright would silently blind the scan to a file the consultant does own.
GENERATED_MARKER_SENTINEL = "_Auto-generated"

_JSON_STRING = r'"((?:[^"\\]|\\.)*)"'


def _flip_first(form):
    """Return the form with its first character's case flipped, or None if unchanged.

    Two variants per entry — as-written plus sentence-initial — is the precise set
    German casing produces for these forms. Case-INSENSITIVE matching would be wrong:
    uppercase German renders ß as SS, so MASSNAHME and GRÖSSE in an all-caps heading
    are correct orthography with no valid ß suggestion to offer.
    """
    flipped = form[:1].swapcase() + form[1:]
    return flipped if flipped != form else None


def _build_matchers():
    """Compile one matcher per curated form, plus its first-character-case variant.

    No \\b anchors: a whole-word matcher would miss Messgrösse, the issue's own
    headline example. Longest form first so overlapping entries (grösse inside
    grösser) resolve to the more specific one.
    """
    matchers = []
    for swiss, correct in SWISS_PAIRS:
        for form, suggestion in ((swiss, correct), (_flip_first(swiss), _flip_first(correct))):
            if form is None or suggestion is None:
                continue
            matchers.append((re.compile(re.escape(form)), form, suggestion))
    matchers.sort(key=lambda m: len(m[1]), reverse=True)
    return matchers


MATCHERS = _build_matchers()


def _guarded(text, start, form):
    """True when this match opens a correct-German word that keeps its ss.

    Scoped to the matched form's own guards, and anchored at the match offset, so a
    guard can never suppress a different entry that merely sits nearby. Both sides are
    checked: a right-extension keeps its ss (weissagen), and a left stem can put the two
    s characters on either side of a morpheme boundary (Beweis+sicherung).
    """
    key = form.lower()
    right_stems = _ENTRY_GUARDS.get(key, ())
    left_stems = _ENTRY_LEFT_GUARDS.get(key, ())
    # Only one entry carries guards, so bail before lowering the text: this runs once per
    # match of every form, and lowering unconditionally makes the guard O(matches × file).
    if not right_stems and not left_stems:
        return False
    lowered = text.lower()
    for stem in right_stems:
        if lowered.startswith(stem, start):
            return True
    # The entry's own final s belongs to the second element, so the stem ends one
    # character before the match does. Bounded endswith rather than a prefix slice, which
    # would copy up to the whole file per match.
    cut = start + len(form) - 1
    for stem in left_stems:
        if lowered.endswith(stem, 0, cut):
            return True
    return False


def _scan_text(text):
    """Return [(offset, form, suggestion)] for the longest match at each position."""
    hits = []
    for pattern, form, suggestion in MATCHERS:
        for m in pattern.finditer(text):
            start, end = m.start(), m.end()
            if _guarded(text, start, form):
                continue
            # Longest-match-wins: a shorter entry overlapping an already-claimed span
            # is the same occurrence, not a second finding. MATCHERS is longest-first,
            # so the more specific entry claims the span before the shorter one runs.
            if any(start < c_end and end > c_start for c_start, c_end, _, _ in hits):
                continue
            hits.append((start, end, form, suggestion))
    hits.sort(key=lambda h: h[0])
    return [(start, form, suggestion) for start, _, form, suggestion in hits]


def _line_of(text, offset):
    return text.count("\n", 0, offset) + 1


def _column_of(text, offset):
    """1-based column of offset. rfind returns -1 on the first line, which is correct."""
    return offset - text.rfind("\n", 0, offset)


def _scan_markdown(text):
    return [
        {
            "line": _line_of(text, off),
            "column": _column_of(text, off),
            "form": form,
            "suggestion": suggestion,
        }
        for off, form, suggestion in _scan_text(text)
    ]


PROSE_KEY_MATCHERS = tuple(
    (key, re.compile(r'"' + re.escape(key) + r'"\s*:\s*' + _JSON_STRING))
    for key in PROSE_KEYS
)


def _scan_json(text):
    """Scan only the string values of prose-bearing keys, by key name.

    The captured group is JSON-escaped source text, so it is decoded before matching:
    a file written with the default ensure_ascii=True carries `Gr\\u00f6sse`, which no
    pair-list entry matches. Without the decode, every non-ASCII entry silently
    reports nothing — the worst failure shape for a lint, since it hides inside a
    successful zero-finding scan. Line numbers still resolve from the raw offset
    because a JSON string can never contain a literal newline.
    """
    findings = []
    for key, key_pattern in PROSE_KEY_MATCHERS:
        for m in key_pattern.finditer(text):
            try:
                value = json.loads('"' + m.group(1) + '"')
            except ValueError:
                value = m.group(1)
            # Anchored on where the value starts, not start+off: after decoding, the
            # offset indexes the decoded string, and a JSON string holds no literal
            # newline, so every match inside it is on the value's own line anyway.
            line = _line_of(text, m.start(1))
            for off, form, suggestion in _scan_text(value):
                findings.append(
                    {
                        "line": line,
                        # 0-based offset INTO THE DECODED VALUE, not into the file: the
                        # raw span is escaped, so a file offset would not survive the
                        # decode. It is what distinguishes several hits sharing a line.
                        "value_offset": off,
                        "form": form,
                        "suggestion": suggestion,
                        "json_key": key,
                    }
                )
    findings.sort(key=lambda f: (f["line"], f["value_offset"], f["form"]))
    return findings


def _emit(success, data, error):
    print(json.dumps({"success": success, "data": data, "error": error}, ensure_ascii=False))
    sys.exit(0 if success else 1)


def _scan_engagement(root):
    findings = []
    excluded = []
    skipped = []
    by_file = {}
    files_scanned = 0

    for dirpath, dirnames, filenames in os.walk(root):
        # Only .git is skipped. .metadata/ and every other dot-directory IS scanned —
        # decision-log.json lives there and carries prose.
        dirnames[:] = sorted(d for d in dirnames if d != ".git")
        for filename in sorted(filenames):
            if not filename.endswith((".md", ".json")):
                continue
            abs_path = os.path.join(dirpath, filename)
            rel_path = os.path.relpath(abs_path, root)
            try:
                with open(abs_path, "r", encoding="utf-8") as handle:
                    text = handle.read()
            except (OSError, UnicodeDecodeError) as exc:
                skipped.append({"path": rel_path, "reason": str(exc)})
                continue

            if GENERATED_MARKER_SENTINEL in text:
                excluded.append(rel_path)
                continue

            if filename.endswith(".json"):
                try:
                    json.loads(text)
                except ValueError as exc:
                    skipped.append({"path": rel_path, "reason": "unparseable json: %s" % exc})
                    continue
                hits = _scan_json(text)
            else:
                hits = _scan_markdown(text)

            files_scanned += 1
            if hits:
                by_file[rel_path] = len(hits)
            for hit in hits:
                entry = {"path": rel_path}
                entry.update(hit)
                findings.append(entry)

    return {
        "engagement": os.path.basename(os.path.normpath(root)),
        "files_scanned": files_scanned,
        "total_findings": len(findings),
        "findings": findings,
        "by_file": by_file,
        "excluded": sorted(excluded),
        "skipped": skipped,
        "detection": (
            "curated-list heuristic with bounded recall: only SWISS_PAIRS forms are "
            "reported, and inside JSON only the values of PROSE_KEYS are read, so a "
            "zero-finding result is not proof the corpus is ß-correct"
        ),
    }


def main(argv):
    # argv is hand-parsed rather than handed to argparse, so that no exit path can
    # print usage text to stdout instead of the JSON envelope a caller parses.
    if len(argv) < 1:
        _emit(False, {"failed_check": "usage"}, "usage: orthography-drift-scan.py <engagement-dir>")
    if len(argv) > 1:
        _emit(
            False,
            {"failed_check": "unexpected_argument", "arguments": argv[1:]},
            "this scan is read-only and takes exactly one argument: <engagement-dir>",
        )

    root = argv[0]
    if not os.path.exists(root):
        _emit(False, {"failed_check": "engagement_missing", "path": root}, "engagement not found: %s" % root)
    if not os.path.isdir(root):
        _emit(False, {"failed_check": "not_a_directory", "path": root}, "not a directory: %s" % root)
    # os.walk swallows a permission error on the root and simply yields nothing, so
    # without this the scan would report a clean corpus it never actually read — the one
    # failure a caller cannot distinguish from a real zero. Checked here rather than via
    # os.walk(onerror=...) so the envelope fails loudly instead of reporting a partial.
    if not os.access(root, os.R_OK | os.X_OK):
        _emit(
            False,
            {"failed_check": "engagement_unreadable", "path": root},
            "engagement not readable: %s" % root,
        )

    _emit(True, _scan_engagement(root), "")


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001 - one envelope on every exit path
        _emit(False, {"failed_check": "unexpected_error"}, "%s: %s" % (type(exc).__name__, exc))
