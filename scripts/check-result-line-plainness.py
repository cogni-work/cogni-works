#!/usr/bin/env python3
"""check-result-line-plainness.py — result-line plainness guard.

A result line is the line a suite emits. Run a colouring emitter and it prints
an escape sequence immediately before the PASS:/FAIL: label, which defeats the
mutation harness match `^[[:space:]]*FAIL:[[:space:]]+<case>` and turns a
genuinely red case into `case_not_found` — a real failure read as a missing one.

A guard cannot execute every suite to watch what it emits, so this one decides
by rule, from source: it flags the constructs that would produce such a line.
That is why detection is not a single-source-line match. In every emitter shape
in this repo the escape sits in the definition body while the label arrives as
the call-site argument, so the two are far apart in source even though they end
up adjacent once emitted.

Two disjoint arms, one line loop:

  escape_literal     an escape literal anywhere in a discovered suite, on a
                     line that is not an emitter definition.
  emitter_not_plain  an emitter definition whose body carries one. Fires even
                     when every call-site label line is clean, which is the
                     copy-an-emitter-into-a-new-suite path this exists to close.

The arms are disjoint on purpose: the first skips definition lines. Were the
second a subset of the first, killing the second would leave the first still
firing on the same file, and a mutation check could not tell a live arm from a
dead one.

The second arm keys on the escape, not on a canonical emitter body. Suites here
legitimately vary — some emit through `printf`, some through `echo`, some label
their passes `ok:` — so requiring one blessed body shape would fail dozens of
clean files while proving nothing about what they emit.

Detection keys on the source literal, not a raw escape byte. The carriers in
this tree hold it as source text, so a byte-only scan finds nothing and ships
green and dead. The raw byte is covered additively, never as a substitute.

Discovery uses the two non-recursive globs `tests/*.sh` and `*/tests/*.sh`,
which are the same two run-plugin-tests.py uses today. The globs are copied
rather than shared on purpose: that runner selects files to EXECUTE and must
never reach sourced-only helper libraries, while this guard selects files to
READ and may one day want them. Sharing one selection would couple a set that
must stay narrow to one that may widen. Non-recursive is load-bearing. A suite
parked one path segment
deeper is out of reach by construction, which is why this file names no
directory and ships no exclusion list, allowlist, skip marker or baseline —
the invariant is a clean zero, not a ratchet. An exemption someone must
remember to delete is the bandaid this guard replaces. `glob` also does not
match a leading dot at any segment, so nested full-repo copies under
dot-directories stay out of the population.

A multi-line emitter definition needs no special handling: the escape then
lands on a line the definition pattern does not match, and the first arm
catches it.

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

# Source spellings of an escape introducer, plus the raw byte as an additive
# case. Assembled from alternatives rather than one broad class so each shape
# stays readable in a finding's `match` field.
ESC_RE = re.compile(r"\\0?33|\\x1[bB]|\\e\[|\x1b")

# Emitter names in use across the repo's suites. This list decides ARM
# ATTRIBUTION, not coverage: the two arms partition every line between them, so
# a definition this list does not name simply falls through to the first arm and
# is reported as escape_literal instead. Coverage is therefore unaffected by how
# broad the list is — do not grow it on the theory that a missing name lets a
# violation through, because that turns it into the inclusion list this guard
# exists to avoid. It is kept broad only so the second arm's liveness counter
# stays meaningful across plugin suites, which label their helpers pass/fail/ok
# rather than red/green.
EMITTER_NAMES = "red|green|pass|fail|ok|warn|info|note|die|skip"
DEFN_RE = re.compile(r"^\s*(?:function\s+)?(" + EMITTER_NAMES + r")\s*\(\)\s*\{?(.*)$")

CONTEXT_LIMIT = 140


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


def scan_file(root, rel_path, counters):
    """Walk one suite, running whichever arm applies to each line."""
    abs_path = os.path.join(root, rel_path)
    try:
        with open(abs_path, "r", encoding="utf-8", errors="replace") as handle:
            lines = handle.read().splitlines()
    except OSError as exc:
        raise RuntimeError("could not read %s: %s" % (rel_path, exc))

    # Both liveness counters advance before any arm condition is evaluated, so
    # a dead arm cannot disguise itself by collapsing the population it was
    # supposed to have examined.
    counters["files_scanned"] += 1

    findings = []
    for number, line in enumerate(lines, 1):
        defn = DEFN_RE.match(line)
        defn_body = defn.group(2) if defn else ""
        if defn:
            counters["definitions_inspected"] += 1
        if defn and ESC_RE.search(defn_body):
            hit = ESC_RE.search(defn_body)
            findings.append({
                "file": rel_path,
                "line": number,
                "arm": "emitter_not_plain",
                "match": hit.group(0),
                "context": line.strip()[:CONTEXT_LIMIT],
            })
        elif not defn:
            for m in ESC_RE.finditer(line):
                findings.append({
                    "file": rel_path,
                    "line": number,
                    "arm": "escape_literal",
                    "match": m.group(0),
                    "context": line.strip()[:CONTEXT_LIMIT],
                })
    return findings


def collect(root):
    suites = discover(root)
    if not suites:
        raise RuntimeError(
            "no test suites discovered under %s — check --root; this repo always "
            "ships suites, so an empty sweep means the globs stopped matching" % root
        )
    counters = {"files_scanned": 0, "definitions_inspected": 0}
    findings = []
    for rel_path in suites:
        findings.extend(scan_file(root, rel_path, counters))
    return suites, findings, counters


def main(argv):
    parser = argparse.ArgumentParser(description="result-line plainness guard")
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
                "definitions_inspected": counters["definitions_inspected"],
            },
        },
        "error": "",
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if findings:
        print("", file=sys.stderr)
        for finding in findings:
            print("FAIL: %s:%d [%s] %s" % (
                finding["file"], finding["line"], finding["arm"], finding["context"],
            ), file=sys.stderr)
        print("", file=sys.stderr)
        print("Rewrite the emitter so it writes its argument verbatim, e.g. "
              "printf '%s\\n' \"$1\". Do not gate it on a capability probe: that "
              "makes a result line parsable in one place and not another, and the "
              "colour comes back under a pty.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
