#!/usr/bin/env python3
"""check-case-id-pairing.py — case-id pairing guard.

A case is addressable when `mutation-check.sh --case <id>` can watch it go RED
under a mutation and GREEN when the mutation is reverted. That needs BOTH arms
to be printable. A `FAIL: <id>` arm with no reachable same-id `PASS:`/`ok:` arm
emits nothing on a green run, so the harness reports `case_not_found` on a
genuinely red run and the guard it was meant to check proves nothing.

`cogni-knowledge/tests/README.md` rule 7 states the property in prose. This
guard is its mechanical floor. The class had been found and hand-fixed twice off
manual censuses before it existed.

WHY A SAME-LINE LITERAL SCAN IS NOT ENOUGH
------------------------------------------
The sibling `check-result-line-plainness.py` decides per line, because the shape
it hunts lands on one line. Case ids do not. The dominant emission shape in this
tree puts the LABEL in a helper definition and the ID at the call site:

    fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }
    ...
    fail "A0 contract inputs are readable"

A same-line scan sees `$1` — never `A0` — and would ship green and dead over the
~15 suites built this way, plus every suite whose green arm is labelled `ok:`
rather than `PASS:`. So this guard resolves ONE level of helper indirection.

The id is collected WHEREVER IT IS LITERALLY SPELLED. That single rule covers
all three shapes in the tree, and it is why classification comes before
collection:

  * definition carries both labels  -> PAIRED emitter. Its call sites are
    self-pairing by construction and contribute nothing. (`check() { ... green
    "PASS: $1" ... red "FAIL: $1" ... }`)
  * definition carries one label, id DEFERRED to an argument -> the CALL SITES
    are the emissions; the id is the first token of $1. (`fail`/`pass` above)
  * definition carries one label with a LITERAL id -> the DEFINITION is the
    emission and the id is fixed, so its call sites contribute nothing.
    (`run_score_ok() { ... red "FAIL: wcov-01 $label ..." ... }`)

THE EXEMPTION KEYS ON SCOPE, NOT ON ABORT
-----------------------------------------
Rule 7 exempts "a preflight guard with no green state worth reporting — a
not-found check that aborts, where execution does not continue so a PASS could
never print", then qualifies it: aborting ALONE does not earn the exemption.
That qualification is not syntactically decidable, so this guard uses SCOPE as
the decidable proxy:

    a fail-only arm is exempt only when it aborts AND sits at script scope.

Aborting inside a loop or a function is NOT exempt, because execution plainly
does continue for the other iterations or the other callers — which is exactly
the `klib-01` shape rule 7 names as owing a twin, and exactly what a
script-scope test cannot be widened to swallow.

This proxy is deliberately WEAKER than rule 7's stated bar. The exempt
population is reported on every run as `summary.script_scope_aborts_exempt` —
100 at the time this shipped — so the number stays measured rather than
restated, and nothing downstream has to be edited when it moves. Narrowing the exemption to non-aborting-only would flag all of
them at once. Whether those are an accepted convention or a real backlog is a
policy question recorded on the PR that introduced this guard, not settled here.
If it is settled toward "backlog", the `unpaired_abort_in_loop` arm below is
deleted rather than adjusted, and every aborting fail-only arm becomes a finding.

STATED RECALL FLOOR
-------------------
Under-detection is the chosen direction. This runs as a BLOCKING CI gate over
every plugin's suites, so one false positive blocks the whole ecosystem while a
false negative costs one undetected case. These are floors on purpose:

  * ONE level of indirection only. A helper defined outside the two globs —
    `cogni-knowledge/tests/fixtures/test_helpers.sh` is one path segment too
    deep for `*/tests/*.sh` — is an unknown call, not an emission. Those helpers
    are structurally self-pairing today, so this is the correct answer now; it
    is not a proof that it always will be.
  * An id token that is ENTIRELY a variable expansion (`$failures`, `${x}`) or
    entirely a printf placeholder (`%s`) is skipped: it can never be a `--case`
    target. This is what keeps trailing rollup lines such as
    `printf '%s\n' "FAIL: $failures arc-reference-sync test(s) failed."` clean
    without any rule about id vocabulary.
  * COMMENT LINES AND HEREDOC BODIES ARE SKIPPED, and the heredoc skip is
    required by construction: `tests/test_check_result_line_plainness.sh` writes
    dirty fixtures through heredocs whose bodies contain unpaired `FAIL:` arms
    on purpose. A suite that emits from inside a heredoc fed to `bash -s` is
    therefore undetected, knowingly.
  * A label counts only IN COMMAND POSITION — the enclosing simple command's
    command word must be a classified emitter or `printf`/`echo`. Segmentation
    is QUOTE-AWARE, which is load-bearing in two directions, both witnessed:
    `test_plain_result_emitters.sh` carries `bash -c '...; red "FAIL: probe-red"'`
    whose command word is `bash` (that string is the file's own subject matter
    and cannot be remediated), and re-read shapes such as
    `grep '^FAIL: A1 ...'` have command word `grep`. Neither is an emission.

Widening the emitter set, or relaxing either conjunct of command position, needs
its own negative-shape witness first — the discipline the sibling guard states.

Discovery reuses the plainness guard's two non-recursive globs, copied rather
than shared for the reason stated there. Non-recursive is load-bearing: a suite
one path segment deeper is out of reach by construction, which is why this file
names no directory and ships no exclusion list, allowlist, skip marker or
baseline. The invariant is a clean zero, not a ratchet.

Zero discovery is a failure, not a pass: this repo always ships suites, so
finding none means the globs stopped matching.

stdlib only; runs under any python3. Exit 0 = clean, 1 = violation(s),
2 = script error.
"""

import argparse
import glob
import json
import os
import re
import sys

# Emitter names in use across the repo's suites, plus the two raw builtins a
# suite can emit through directly. This list gates COMMAND POSITION, so keeping
# it tight is what keeps `grep`/`bash`/assertion helpers from reading as
# emitters. Names discovered per file (see classify_definitions) are added on
# top of it.
BUILTIN_EMITTERS = {"red", "green", "pass", "fail", "ok", "warn", "info",
                    "note", "die", "skip", "printf", "echo"}

DEFN_RE = re.compile(r"^[ \t]*(?:function[ \t]+)?([A-Za-z_][A-Za-z0-9_]*)[ \t]*\(\)[ \t]*\{?[ \t]*$")
DEFN_INLINE_RE = re.compile(r"^[ \t]*(?:function[ \t]+)?([A-Za-z_][A-Za-z0-9_]*)[ \t]*\(\)[ \t]*\{(.*)\}[ \t]*$")
HEREDOC_RE = re.compile(r"<<-?[ \t]*([\"']?)([A-Za-z_][A-Za-z0-9_]*)\1")

# Shell keywords that may precede the real command word inside one segment.
LEADING_KEYWORDS = {"if", "then", "else", "elif", "do", "while", "until",
                    "!", "{", "(", "time"}

DO_RE = re.compile(r"(^|[ \t;])do([ \t;]|$)")
DONE_RE = re.compile(r"(^|[ \t;])done([ \t;]|$)")
CONTEXT_LIMIT = 140
ABORT_LOOKAHEAD = 6


def repo_root_default():
    """Parent of scripts/ — the same anchor run-plugin-tests.py resolves."""
    return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))


def discover(root):
    """Two non-recursive globs, relative and sorted — see the module docstring."""
    patterns = [
        os.path.join(root, "tests", "*.sh"),
        os.path.join(root, "*", "tests", "*.sh"),
    ]
    found = set()
    for pattern in patterns:
        for abs_path in glob.glob(pattern):
            if os.path.isfile(abs_path):
                found.add(os.path.relpath(abs_path, root))
    return sorted(found)


def split_segments(line):
    """Split one line into simple commands, ignoring separators inside quotes.

    Quote awareness is the whole point: a `;` inside a single-quoted `bash -c`
    payload must NOT start a new command, or the emitter call inside that
    payload reads as a real emission.
    """
    segments = []
    buf = []
    quote = None
    i = 0
    while i < len(line):
        ch = line[i]
        if quote:
            buf.append(ch)
            if ch == "\\" and quote == '"' and i + 1 < len(line):
                buf.append(line[i + 1])
                i += 2
                continue
            if ch == quote:
                quote = None
            i += 1
            continue
        if ch in "'\"":
            quote = ch
            buf.append(ch)
            i += 1
            continue
        if ch == "\\" and i + 1 < len(line):
            buf.append(ch)
            buf.append(line[i + 1])
            i += 2
            continue
        if ch in ";|&":
            run = 1
            while i + run < len(line) and line[i + run] == ch:
                run += 1
            segments.append("".join(buf))
            buf = []
            i += run
            continue
        buf.append(ch)
        i += 1
    segments.append("".join(buf))
    return segments


CASE_ARM_RE = re.compile(r"^[ \t]*[^()]+\)[ \t]+")


def strip_case_arm(segment):
    """Drop a leading `pattern)` so a case arm's command word is reachable.

    `*"default: false"*) pass <id> "..."` is a real emission; without this the
    command word reads as the glob pattern and the arm is silently skipped.
    Patterns carrying `(` are left alone so a subshell is never mistaken for one.
    """
    return CASE_ARM_RE.sub("", segment, count=1)


def command_word(segment):
    """First token of a segment, past any leading shell keywords."""
    tokens = strip_case_arm(segment).strip().split()
    for token in tokens:
        bare = token.strip("{}()")
        if not bare:
            continue
        if bare in LEADING_KEYWORDS:
            continue
        if "=" in bare and not bare.startswith("$"):
            # A leading VAR=value assignment prefix.
            continue
        return bare
    return ""


def extract_id(text, match_end):
    """Take the case-id token that follows a label, balancing `$( ... )`.

    `klib-01-$(case_slug "$f")` carries a space inside the substitution, so a
    plain whitespace split would truncate it mid-token and report a mangled id.
    """
    rest = text[match_end:]
    token = []
    depth = 0
    for ch in rest:
        if ch == "(" and token and token[-1] == "$":
            depth += 1
        elif ch == ")" and depth:
            depth -= 1
        elif not depth and (ch.isspace() or ch in '"\'' or ch == "\\"):
            # A backslash ends the token: an emitter's format string is
            # `'PASS: %s\\n'`, and keeping the escape made the id read as
            # `%s\\n` rather than `%s` — so the helper looked like it carried a
            # LITERAL id, its call sites were never graded, and every case in
            # those suites reported unpaired. Breaking here is what keeps a
            # printf directive recognisable as deferred.
            break
        token.append(ch)
    return "".join(token).strip()


DEFERRED_RE = re.compile(r"^(?:\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*|\$[0-9@*#?]|%[-0-9.]*[a-zA-Z])$")


def is_deferred(case_id):
    """True when the id is entirely an expansion or a printf placeholder."""
    return not case_id or bool(DEFERRED_RE.match(case_id))


def argument_tail(segment, word):
    """Everything after the command word `word` in `segment`.

    Located by position, not by slicing `len(word)` off the segment: a segment
    routinely opens with `{ ` or a case-arm pattern, and slicing from the start
    chops the wrong characters — which reported `il` as a case id from
    `{ fail "$tname" ...`.
    """
    stripped = strip_case_arm(segment)
    match = re.search(r"(?:^|[ \t;{}(])" + re.escape(word) + r"(?=[ \t]|$)", stripped)
    if not match:
        return ""
    return stripped[match.end():].strip()


def quoted_literals(text):
    """Yield each quoted run's contents, plus the unquoted remainder.

    Quote nesting follows shell rules — a `'` inside a double-quoted run is
    literal content, not a quote. That is what separates a real emission from a
    diagnostic that merely QUOTES one, e.g.
    `printf '%s\n' "  mutant run exit=$rc; expected a 'FAIL: A1 ...' line"`.
    The label there sits mid-sentence inside one double-quoted run, so the run
    does not start with a label and nothing is collected.
    """
    out = []
    buf = []
    quote = None
    for ch in text:
        if quote:
            if ch == quote:
                out.append("".join(buf))
                buf = []
                quote = None
            else:
                buf.append(ch)
            continue
        if ch in "'\"":
            if buf:
                out.append("".join(buf))
            buf = []
            quote = ch
            continue
        buf.append(ch)
    if buf:
        out.append("".join(buf))
    return out


# Labels the shared harness classifies. Red is `FAIL:`; green is `ok:` or
# `PASS:` — both spellings ship in this tree, so both must count or every
# `ok:`-labelled suite reads as red-only. Anchored, because position inside the
# emitted string is what separates an emission from prose (see find_labels).
RED_AT_START_RE = re.compile(r"^[ \t]*FAIL:[ \t]+")
GREEN_AT_START_RE = re.compile(r"^[ \t]*(?:PASS|ok):[ \t]+")


def find_labels(segment):
    """Yield (polarity, case_id) for every label that OPENS an emitted string.

    Position inside the string is the discriminator, and it mirrors the harness:
    `mutation-check.sh` anchors on `^[[:space:]]*FAIL:`, so a label that is not
    at the start of the emitted line is not something the harness can key on
    either. Requiring it here is what keeps prose diagnostics and re-read
    patterns from reading as emissions.
    """
    out = []
    for literal in quoted_literals(segment):
        match = RED_AT_START_RE.match(literal)
        if match:
            out.append(("red", extract_id(literal, match.end())))
            continue
        match = GREEN_AT_START_RE.match(literal)
        if match:
            out.append(("green", extract_id(literal, match.end())))
    return out


def strip_comment(line):
    """Drop a trailing comment, respecting quotes."""
    quote = None
    for i, ch in enumerate(line):
        if quote:
            if ch == quote:
                quote = None
            continue
        if ch in "'\"":
            quote = ch
            continue
        if ch == "#" and (i == 0 or line[i - 1] in " \t"):
            return line[:i]
    return line


LEADING_QUOTE_RE = re.compile(r"^[ \t]*(['\"])")


def shed_dangling_quote(text):
    """Drop a leading quote that CLOSES a run opened on an earlier line.

    A multi-line payload ends like `' && green "PASS: <id> ..."`. Read on its
    own that opening `'` inverts the quote state for the whole rest of the
    line, so the command word reads as `'` and the emission is missed. When the
    unit both starts with a quote and carries an ODD number of that character,
    the quote is a closer with no partner here — shedding it restores the rest.

    Cross-line quote STATE was tried instead and reverted: one nested construct
    (`"$(grep -nE 'Skill\\("?cogni-wiki:' "$f")"` is the live witness) desyncs
    the scanner, and with state carried forward that local mis-parse blacked out
    a 125-line span and silently dropped two real findings. A guard that stops
    detecting is worse than one that joins less, so joining is now limited to
    the unambiguous backslash continuation plus this local repair.
    """
    match = LEADING_QUOTE_RE.match(text)
    if match and text.count(match.group(1)) % 2 == 1:
        cut = match.end()
        return text[:cut - 1] + text[cut:]
    return text


def logical_units(lines):
    """Yield (start_index, end_index, joined_text), heredoc bodies removed.

    Units join across physical lines on a `\\` continuation only — the one
    unambiguous signal. This is load-bearing: the tree's most common assertion
    shape puts the two arms of ONE case on two physical lines,

        introspect '...multi-line python...' && green "PASS: <id> ..." \\
          || { red "FAIL: <id> ..."; errors=$((errors+1)); }

    so a strictly per-line scanner sees the red, never the green, and reports a
    correctly-paired case as unpaired.
    """
    pending_heredoc = None
    start = None
    buf = []
    for index, raw in enumerate(lines):
        if pending_heredoc is not None:
            if raw.strip() == pending_heredoc:
                pending_heredoc = None
            continue
        text = strip_comment(raw)
        if start is None:
            start = index
        continues = text.rstrip().endswith("\\")
        buf.append(text.rstrip()[:-1] if continues else text)
        if not continues:
            joined = shed_dangling_quote(" ".join(buf))
            if joined.strip():
                yield start, index, joined
            match = HEREDOC_RE.search(joined)
            if match:
                pending_heredoc = match.group(2)
            buf = []
            start = None
    if buf and start is not None:
        joined = shed_dangling_quote(" ".join(buf))
        if joined.strip():
            yield start, len(lines) - 1, joined


def attribute_line(lines, start, end, needle):
    """Physical line within [start, end] that actually carries `needle`."""
    for index in range(start, min(end + 1, len(lines))):
        if needle and needle in lines[index]:
            return index + 1
    return start + 1


def classify_definitions(lines):
    """Map each function name to how it emits: paired, single-arm, or neither.

    Returns ({name: {"polarity", "deferred", "start", "end"}}, [(start, end)]).
    A name absent from the map is not an emitter, so calling it is an ordinary
    command. The second value is EVERY function's span, emitter or not, and it
    is what the scope test reads.

    Those must be two different sets. Scope asks "does execution continue past
    this abort for other callers", which is true of any enclosing function —
    but a function is only an *emitter* when its body spells a label, and the
    dominant shape here (`fail <id> "..."`) spells none. Keying scope on the
    emitter map therefore exempted an aborting fail-only arm inside an ordinary
    test function while flagging the byte-equivalent arm inside one that
    happened to inline its label, which is the opposite of a rule.
    """
    defs = {}
    spans = []
    i = 0
    while i < len(lines):
        # Strip the trailing comment first: `run_score_ok() {  # <usage>` is the
        # resident shape, and matching the raw line missed it — leaving the
        # helper unclassified and every one of its call sites ungraded.
        raw = strip_comment(lines[i]).rstrip()
        inline = DEFN_INLINE_RE.match(raw)
        if inline:
            spans.append((inline.group(1), i, i, inline.group(2)))
            i += 1
            continue
        opener = DEFN_RE.match(raw)
        if opener and ("{" in raw or (i + 1 < len(lines) and lines[i + 1].strip() == "{")):
            start = i
            depth = raw.count("{") - raw.count("}")
            j = i + 1
            if depth == 0 and j < len(lines) and strip_comment(lines[j]).strip() == "{":
                depth = 1
                j += 1
            body = []
            while j < len(lines) and depth > 0:
                body.append(lines[j])
                depth += lines[j].count("{") - lines[j].count("}")
                j += 1
            spans.append((opener.group(1), start, j - 1, "\n".join(body)))
            i = j
            continue
        i += 1

    func_spans = [(start + 1, end + 1) for _n, start, end, _b in spans]
    for name, start, end, body in spans:
        polarities = set()
        deferred = True
        body_text = " ; ".join(strip_comment(bl) for bl in body.split("\n"))
        for segment in split_segments(body_text):
            for polarity, case_id in find_labels(segment):
                polarities.add(polarity)
                if not is_deferred(case_id):
                    deferred = False
        if not polarities:
            continue
        defs[name] = {
            "polarity": "both" if len(polarities) == 2 else polarities.pop(),
            "deferred": deferred,
            "start": start + 1,
            "end": end + 1,
        }
    return defs, func_spans


def aborts(lines, index):
    """True when the branch holding line `index` terminates in `exit`."""
    for line in lines[index:index + ABORT_LOOKAHEAD]:
        stripped = strip_comment(line).strip()
        if not stripped:
            continue
        for segment in split_segments(stripped):
            word = command_word(segment)
            if word == "exit":
                return True
            if word in ("fi", "else", "elif", "done", "}", "esac"):
                return False
    return False


def scan_file(root, rel_path, counters):
    """Collect this suite's red and green case ids, then pair them."""
    abs_path = os.path.join(root, rel_path)
    try:
        with open(abs_path, "r", encoding="utf-8", errors="replace") as handle:
            lines = handle.read().splitlines()
    except OSError as exc:
        raise RuntimeError("could not read %s: %s" % (rel_path, exc))

    # Liveness bookkeeping advances before any arm condition is evaluated, so a
    # dead arm cannot disguise itself by collapsing the population it was
    # supposed to have examined.
    counters["files_scanned"] += 1

    defs, func_spans = classify_definitions(lines)
    counters["emitters_classified"] += len(defs)
    emitter_names = BUILTIN_EMITTERS | set(defs)

    depth = 0
    reds = []
    green_ids = set()

    def record(polarity, case_id, start, end):
        """Bank one emission. The two collection arms share this tail so they
        cannot drift on the counter, the attribution or the context slice."""
        counters["emissions_inspected"] += 1
        if is_deferred(case_id):
            return
        if polarity == "green":
            green_ids.add(case_id)
            return
        hit = attribute_line(lines, start, end, case_id)
        reds.append({
            "id": case_id, "line": hit, "depth": depth,
            "context": lines[hit - 1].strip()[:CONTEXT_LIMIT],
            "index": hit - 1,
        })

    for start, end, text in logical_units(lines):
        for segment in split_segments(text):
            word = command_word(segment)
            if word in emitter_names:
                for polarity, case_id in find_labels(segment):
                    record(polarity, case_id, start, end)
            # A single-arm emitter that DEFERS its id makes each call site an
            # emission; one that fixes a literal id was already collected above.
            info = defs.get(word)
            if info and info["deferred"] and info["polarity"] != "both" and not any(
                    d["start"] <= start + 1 <= d["end"] for d in defs.values()):
                # Shed the argument's opening quote BEFORE extracting: the id
                # token scan stops at a quote, so `fail "owner-present-file" ...`
                # otherwise yields "" — which reads as deferred and drops a real
                # emission on the floor.
                rest = argument_tail(segment, word).lstrip("\"'")
                record(info["polarity"], extract_id(rest, 0).strip("\"'"), start, end)

        # Block depth AFTER the line is classified, so an emission on a `do`
        # line still reads at the depth it executes in.
        if DO_RE.search(text):
            depth += 1
        if DONE_RE.search(text):
            depth = max(0, depth - 1)

    findings = []
    for red in reds:
        red_id = red["id"]
        if red_id in green_ids:
            continue
        in_block = red["depth"] > 0 or any(
            start <= red["line"] <= end for start, end in func_spans
        )
        if aborts(lines, red["index"]):
            if not in_block:
                # Script-scope aborting preflight — rule 7's exempt shape.
                counters["script_scope_aborts_exempt"] += 1
                continue
            arm = "unpaired_abort_in_loop"
        else:
            arm = "unpaired_fail_id"
        findings.append({
            "file": rel_path,
            "line": red["line"],
            "arm": arm,
            "case_id": red_id,
            "context": red["context"],
        })
    return findings


def collect(root):
    suites = discover(root)
    if not suites:
        raise RuntimeError(
            "no test suites discovered under %s — check --root; this repo always "
            "ships suites, so an empty sweep means the globs stopped matching" % root
        )
    counters = {"files_scanned": 0, "emitters_classified": 0,
                "emissions_inspected": 0, "script_scope_aborts_exempt": 0}
    findings = []
    for rel_path in suites:
        findings.extend(scan_file(root, rel_path, counters))
    return suites, findings, counters


def main(argv):
    parser = argparse.ArgumentParser(description="case-id pairing guard")
    parser.add_argument(
        "--root",
        default=None,
        help="tree to scan; discovery and reported paths are relative to it",
    )
    args = parser.parse_args(argv)
    root = os.path.abspath(args.root) if args.root else repo_root_default()

    try:
        suites, findings, counters = collect(root)
    except RuntimeError as exc:
        print(json.dumps({"success": False, "data": {}, "error": str(exc)},
                         indent=2, ensure_ascii=False))
        return 2

    by_arm = {}
    for finding in findings:
        by_arm[finding["arm"]] = by_arm.get(finding["arm"], 0) + 1

    result = {
        "success": not findings,
        "data": {
            "root": root,
            "violations": findings,
            "summary": {
                "total": len(findings),
                "by_arm": by_arm,
                "files_affected": len({f["file"] for f in findings}),
                "files_discovered": len(suites),
                "files_scanned": counters["files_scanned"],
                "emitters_classified": counters["emitters_classified"],
                "emissions_inspected": counters["emissions_inspected"],
                "script_scope_aborts_exempt": counters["script_scope_aborts_exempt"],
            },
        },
        "error": "",
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if findings:
        print("", file=sys.stderr)
        for finding in findings:
            print("FAIL: %s:%d [%s] %s -- %s" % (
                finding["file"], finding["line"], finding["arm"],
                finding["case_id"], finding["context"],
            ), file=sys.stderr)
        print("", file=sys.stderr)
        print("Give the case a reachable same-id green arm gated on that case's "
              "own predicate: an if/else pair, or — for a loop — accumulate "
              "offenders and emit one fixed-id if/else after the loop closes "
              "(plain-emit-03 is the resident model). A PASS gated on the shared "
              "errors accumulator is NOT reachable and does not count.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
