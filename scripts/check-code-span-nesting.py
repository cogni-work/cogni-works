#!/usr/bin/env python3
"""check-code-span-nesting.py — code-span nesting guard.

Markdown has no nesting for single-backtick code spans. When an outer single-backtick
pair is wrapped around a phrase that already backticks a bare word, CommonMark does not
render one code span inside a sentence — it pairs the delimiters left to right and
produces two broken spans with the bare word stranded as plain text between them. The
same parity shift happens when a single-backtick span's own content contains a literal
backtick: the span closes early, and every later delimiter on that paragraph pairs one
position out of step.

This guard flags that class. It had been retired point-wise three times before this
script existed, each time found by a human who happened to read the file.

The rule
--------
Per paragraph, pair backtick runs left to right the way CommonMark does: an opening run
of length N pairs with the next run of exactly length N, and the text between them is
that span's content. Flag two ADJACENT resolved spans when all of these hold:

  * both delimiter runs are NESTING_DELIM_LEN long (single-backtick spans only —
    a deliberate double-backtick span is the documented escape for content that
    itself contains a backtick, and must never be flagged);
  * the first span's content ENDS with a space;
  * the second span's content BEGINS with a space;
  * the literal text strictly between the two spans is non-empty and contains no
    whitespace — a single bare token.

That conjunction is what separates the defect from the well-formed shapes this repo
writes constantly. It is deliberately narrow: it describes what the broken render
actually looks like, not merely "a line with four backticks on it".

Three properties are load-bearing, each adopted on measurement rather than taste:

  * PARAGRAPH-scoped, not line-scoped. A CommonMark code span may cross a newline
    inside a paragraph, so a line-scoped scan reads a continuation line's first
    backtick as an opener when it is really a closer, and reports the rest of that
    line as nested. Scoping to the paragraph removes that whole false-positive class.
  * NO backslash-escape handling for backtick runs. CommonMark does not honour a
    backslash escape inside a code span, so honouring one here desynchronises the
    pairing from what a renderer actually does and manufactures findings.
  * Fenced blocks are skipped, tracking both backtick and tilde fences. Fence bodies
    are not inline contexts, and they are where this repo quotes broken markdown on
    purpose in order to describe it.

Two narrower rules were measured and rejected. Dropping the space requirement — keying
only on "a bare token between two spans" — floods: the adjacent-spans-separated-by-
punctuation shape is pervasive house style here. Keeping the space requirement but
scoping to the line rather than the paragraph still reports the multi-line-span class
described above. The counts behind both are reported by the falsifier suite rather than
frozen into this docstring, so a reader can reproduce them instead of trusting them.

Scope: tracked *.md only. Argued on its own merits, not by precedent:

  1. This is a RENDERING defect. It exists only where something applies CommonMark
     inline parsing. The tracked markdown set is exactly what this repo renders on
     GitHub and loads as skill and agent prose.
  2. On a non-markdown surface a backtick is an ordinary character. Inside a Python
     string literal, a shell heredoc or a YAML comment nothing pairs it, so a finding
     there would be a false positive by construction.
  3. Covering non-*.md surfaces that embed markdown prose would need a per-language
     extractor deciding which byte ranges are rendered — a parser per language, each
     its own false-positive surface, for a class that measures a handful of
     occurrences repo-wide.
  4. YAML frontmatter inside a *.md file needs no special case: it is inside a scanned
     file already, and produced no false positive in the measured run.
  5. Widening later is one pathspec. *.md is the reversible choice, not a fence.

Hard clean zero — no baseline, allowlist, exclusion list or skip marker. The invariant
is a clean tree, not a ratchet; the fix for a finding is to promote the OUTER delimiter
to a double-backtick pair, never to exempt the line. Discovering zero markdown files is
a failure, not a clean sweep: this repo always ships markdown, so an empty sweep means
discovery stopped matching.

stdlib only; runs under any python3. Exit 0 = clean, 1 = violation(s), 2 = script error.
"""

import argparse
import json
import os
import subprocess
import sys

# The delimiter run length this guard pairs on. Single-backtick spans are the only
# ones that carry the defect; a double-backtick span is the documented escape. Both
# delimiter comparisons in the flag predicate read through this constant, so changing
# it is a real mutation of the detection core rather than a cosmetic edit.
NESTING_DELIM_LEN = 1

CONTEXT_LIMIT = 140


def repo_root_default():
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def discover(root):
    """Tracked *.md, via the git index — not a filesystem walk.

    The pathspec is passed as its own argv element, never through a shell, so it
    reaches git as a pathspec instead of being glob-expanded against the CWD.
    """
    try:
        out = subprocess.check_output(
            ["git", "-C", root, "ls-files", "-z", "--", "*.md"],
            stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, OSError) as exc:
        raise RuntimeError("git ls-files failed under %s: %s" % (root, exc))
    return sorted(p for p in out.decode("utf-8", "replace").split("\x00") if p)


def fence_run(line):
    """Return (char, length) when the line opens or closes a fence, else None."""
    stripped = line.lstrip(" ")
    if len(line) - len(stripped) > 3:
        return None
    for ch in ("`", "~"):
        if stripped.startswith(ch * 3):
            n = 0
            while n < len(stripped) and stripped[n] == ch:
                n += 1
            return (ch, n)
    return None


def backtick_runs(text):
    """Every maximal run of backticks, as (offset, length).

    No backslash handling: CommonMark does not honour an escape inside a code span,
    so honouring one here would desynchronise this scan from the renderer.
    """
    runs = []
    i = 0
    n = len(text)
    while i < n:
        if text[i] == "`":
            j = i
            while j < n and text[j] == "`":
                j += 1
            runs.append((i, j - i))
            i = j
        else:
            i += 1
    return runs


def resolve_spans(text):
    """Pair runs left to right; return each resolved span as a dict."""
    runs = backtick_runs(text)
    spans = []
    k = 0
    while k < len(runs):
        start, length = runs[k]
        m = k + 1
        while m < len(runs) and runs[m][1] != length:
            m += 1
        if m < len(runs):
            close_at = runs[m][0]
            spans.append(
                {
                    "open_at": start,
                    "len": length,
                    "close_at": close_at,
                    "content": text[start + length:close_at],
                }
            )
            k = m + 1
        else:
            k += 1
    return spans


def nested_pairs(text):
    """Adjacent resolved spans matching the flag predicate."""
    spans = resolve_spans(text)
    hits = []
    for first, second in zip(spans, spans[1:]):
        if first["len"] != NESTING_DELIM_LEN or second["len"] != NESTING_DELIM_LEN:
            continue
        a = first["content"]
        b = second["content"]
        if not a or not b:
            continue
        if not a[-1].isspace() or not b[0].isspace():
            continue
        between = text[first["close_at"] + first["len"]:second["open_at"]]
        if between and not any(c.isspace() for c in between):
            hits.append((first["open_at"], between))
    return hits, len(spans)


def scan_file(rel_path, text):
    """Return (findings, spans_paired) for one markdown file's body."""
    findings = []
    paired = 0
    lines = text.split("\n")
    in_fence = False
    fence_char = None
    fence_len = 0
    buf = []
    buf_start = 0

    def flush():
        nonlocal paired
        if not buf:
            return
        joined = "\n".join(buf)
        hits, n_spans = nested_pairs(joined)
        paired += n_spans
        for offset, between in hits:
            line_no = buf_start + joined[:offset].count("\n")
            findings.append(
                {
                    "file": rel_path,
                    "line": line_no,
                    "between": between,
                    "context": lines[line_no - 1].strip()[:CONTEXT_LIMIT],
                }
            )

    for number, line in enumerate(lines, 1):
        fence = fence_run(line)
        if fence is not None:
            char, length = fence
            if not in_fence:
                flush()
                del buf[:]
                in_fence = True
                fence_char = char
                fence_len = length
            elif char == fence_char and length >= fence_len:
                in_fence = False
                fence_char = None
                fence_len = 0
            continue
        if in_fence:
            continue
        if not line.strip():
            flush()
            del buf[:]
            continue
        if not buf:
            buf_start = number
        buf.append(line)
    flush()
    return findings, paired


def collect(root):
    discovered = discover(root)
    if not discovered:
        raise RuntimeError(
            "discovered no markdown under %s -- this repo always ships markdown, "
            "so an empty sweep means discovery stopped matching" % root
        )
    findings = []
    scanned = 0
    paired = 0
    for rel_path in discovered:
        abs_path = os.path.join(root, rel_path)
        try:
            with open(abs_path, encoding="utf-8", errors="replace") as handle:
                text = handle.read()
        except OSError:
            continue
        # Counted before any flag condition is evaluated, so a dead predicate cannot
        # collapse the population this guard claims to have examined.
        scanned += 1
        file_findings, file_paired = scan_file(rel_path, text)
        paired += file_paired
        findings.extend(file_findings)
    return discovered, findings, scanned, paired


def main():
    parser = argparse.ArgumentParser(description="Code-span nesting guard.")
    parser.add_argument("--root", default=repo_root_default())
    args = parser.parse_args()
    root = os.path.abspath(args.root)

    try:
        discovered, findings, scanned, paired = collect(root)
    except RuntimeError as exc:
        print(json.dumps({"success": False, "data": {}, "error": str(exc)},
                         indent=2, ensure_ascii=False))
        return 2

    result = {
        "success": not findings,
        "data": {
            "root": root,
            "violations": findings,
            "summary": {
                "total": len(findings),
                "files_affected": len({f["file"] for f in findings}),
                "files_discovered": len(discovered),
                "files_scanned": scanned,
                "code_spans_paired": paired,
            },
        },
        "error": "",
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if findings:
        for f in findings:
            sys.stderr.write(
                "FAIL: %s:%d %s %s\n" % (f["file"], f["line"], f["between"], f["context"])
            )
        sys.stderr.write(
            "\nPromote the OUTER delimiter of the offending span to a double-backtick "
            "pair. Do not add a skip marker -- this guard has none.\n"
            "One stray backtick inside a single-backtick span shifts pairing parity for "
            "the REST of its paragraph, so several findings on one line commonly share "
            "ONE root cause and one promotion clears them all. Fix the earliest finding "
            "in a paragraph first, then re-run before touching the later ones.\n"
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
