#!/usr/bin/env python3
"""Guard that every .github/workflows file still loads, and still declares jobs.

Why this exists
---------------
A workflow file that GitHub Actions cannot parse runs none of its jobs. It does
not fail one step loudly -- it removes every check that file would have posted
from the pull request entirely, leaving a red zero-second run buried in the
Actions list and a check surface that looks clean. A single unquoted plain
scalar carrying a colon followed by a space is enough to do it:

    - name: Assert zero retired-plugin dispatches in live surfaces (set: scripts/x.json)

YAML reads the second colon-space as a mapping separator inside a value that is
already a scalar, and the load fails. Every gate job in that file goes quiet.

This guard reports two violation kinds:

    plain_scalar_colon_space  an unquoted plain-scalar mapping value carrying a
                              colon-space, i.e. the shape above
    no_jobs                   a file that parses but declares no jobs, which
                              posts no checks either -- the same user-visible
                              outcome as a load failure

Dependency decision -- why this is a scanner and not a parser
-------------------------------------------------------------
The obvious implementation is yaml.safe_load. PyYAML is not in the standard
library, nothing in this repository imports it, there is no requirements.txt,
Pipfile or pyproject.toml anywhere in the tree, and no CI runner installs
anything beyond the runner image. The repository convention is bash plus
python3 with no pip dependencies. Adding a package manager to the build to
satisfy one guard is a larger and more invasive change than the guard itself,
so this ships a bounded standard-library scanner instead.

That is a real trade, and these are its limits. This is NOT a YAML parser and
must not be trusted as one:

  - It detects the two shapes named above. A file it passes is not thereby
    proven valid YAML; other malformations (bad indentation, duplicate keys,
    unterminated quotes) are not modelled.
  - A GitHub Actions ${{ }} expression whose body legitimately contains a
    colon-space -- format('a: b', x) -- is reported as a violation. Quote the
    value to silence it, which is also what makes it unambiguous to YAML.
  - Multi-line plain scalars, anchors, aliases, tags and multi-document streams
    are not understood. Values opening with &, * or ! are skipped rather than
    interpreted.
  - A quoted KEY containing a colon-space ("a: b": c) is misread as a plain
    value. No workflow in this repository uses that shape.

Why a per-line regex alone would not work
-----------------------------------------
No indentation-agnostic pattern can separate an unquoted mapping value carrying
a colon-space from a line inside a `run: |` block body that happens to carry
one. Both are indented text under a key-shaped line; they are textually
identical. A count-based heuristic passes this tree today only by coincidence --
the block bodies here print key/value diagnostics constantly and simply happen
not to put two colon-spaces on one line.

So the scanner tracks block-scalar state by indent column instead, and strips
comments, quoted values and flow collections before testing what remains --
all three legitimately carry a colon-space on the real tree. See `scan_lines`
for the mechanism.

Discovery -- a deliberate deviation from the sibling guards
-----------------------------------------------------------
check-breadcrumbs.py and check-external-dispatch.py discover through
`git ls-files` so that stale copies scattered under worktrees and plugin caches
cannot be mistaken for live files. That rationale is about files spread across
the tree. This guard reads one fixed directory at a known path, where no such
ambiguity exists, so it lists the directory instead. The listing is also what
makes the zero-file case testable at all: the suite's fixtures live in a
temporary directory that is not a git repository, and a discovery path that only
speaks git could not be exercised there.

Discovering nothing is a FAILURE, never a pass. A guard that silently finds no
files to check reports green forever and is worse than no guard, because it
reads as evidence. Both the empty-directory and the missing-directory cases are
discovery failures, and they are distinct code paths.

Self-reference limitation
-------------------------
This guard cannot certify the workflow file that hosts it. If the workflow
running this script fails to load, the job never starts and nothing is reported.
That is why it lives in its own workflow file rather than alongside the other
gates: the two files then cover each other, with this guard scanning lint.yml
and lint.yml's test-suite job running this guard's own suite.

That mutual coverage inherits the limits above, and the point is easy to
over-read. Both directions run this same scanner, so they cover each other only
for the two shapes it models -- not for loadability in general. And a change
that breaks both files in one commit is not catchable from inside the
repository at all.

There is deliberately no inline allow marker, unlike the breadcrumb and
external-dispatch guards. Those enforce conventions, which have legitimate
exceptions. This one enforces loadability, which has none -- a file carrying
this shape is broken, so an escape hatch could only let a broken workflow
through.

Output contract matches the sibling guards: a single JSON envelope
{"success": bool, "data": {...}, "error": str} on stdout, all narration on
stderr afterwards, exit 0 clean / 1 violations / 2 script error.
"""

import argparse
import json
import os
import re
import sys

# The detection literal, pinned on its own line at column 0 so a mutation run can
# target it precisely. Do not reproduce this assignment at column 0 elsewhere.
COLON_SPACE = ": "

WORKFLOW_DIR = os.path.join(".github", "workflows")
WORKFLOW_SUFFIXES = (".yml", ".yaml")

# A block-scalar indicator: | or > with an optional explicit indent digit and an
# optional chomping modifier -- |, |-, |+, >2, |2- and so on.
BLOCK_SCALAR_RE = re.compile(r"^[|>][0-9]*[+-]?$")

# Values that are not plain scalars and so cannot carry the defect: flow
# collections, and anchors, aliases and tags.
NON_PLAIN_OPENERS = ("[", "{", "&", "*", "!")

CONTEXT_LIMIT = 140


def strip_comment(line):
    """Remove a trailing YAML comment, respecting quotes.

    A `#` only opens a comment when it starts the content or follows
    whitespace, so `foo#bar` is left alone. A `#` inside a quoted run is
    literal text.
    """
    in_single = False
    in_double = False
    for idx, char in enumerate(line):
        if char == "'" and not in_double:
            in_single = not in_single
        elif char == '"' and not in_single:
            in_double = not in_double
        elif char == "#" and not in_single and not in_double:
            if idx == 0 or line[idx - 1] in " \t":
                return line[:idx]
    return line


def indent_of(line):
    return len(line) - len(line.lstrip(" "))


def is_quoted(value):
    """True when the whole value is one quoted scalar."""
    if len(value) < 2:
        return False
    return (value[0] == '"' and value[-1] == '"') or (
        value[0] == "'" and value[-1] == "'"
    )


def value_of(content):
    """Return a mapping line's value, or None when it is not a mapping entry.

    A line ending in a bare colon opens a nested mapping and carries no value,
    which is returned as an empty string -- distinct from None, since callers
    rely on that to tell "a key with children" from "not a key at all".
    """
    body = content.strip()
    if not body:
        return None
    if body.startswith("- "):
        body = body[2:].lstrip()
    elif body == "-":
        return None
    if body.endswith(":"):
        return ""
    sep = body.find(COLON_SPACE)
    if sep == -1:
        return None
    return body[sep + len(COLON_SPACE):].strip()


def scan_lines(lines, rel_path):
    """Scan one workflow file's lines, returning violation records."""
    violations = []
    block_indent = None

    for lineno, raw in enumerate(lines, start=1):
        line = raw.rstrip("\n")

        if block_indent is not None:
            if not line.strip():
                continue
            if indent_of(line) > block_indent:
                # Still inside the block scalar body. Never scanned.
                continue
            # Dedented out of the block. Fall through and re-process this very
            # line as ordinary YAML rather than consuming it.
            block_indent = None

        content = strip_comment(line)
        if not content.strip():
            continue

        value = value_of(content)
        if not value:
            continue

        if BLOCK_SCALAR_RE.match(value):
            block_indent = indent_of(content)
            continue

        if is_quoted(value) or value[0] in NON_PLAIN_OPENERS:
            continue

        if COLON_SPACE in value:
            violations.append(
                {
                    "kind": "plain_scalar_colon_space",
                    "file": rel_path,
                    "line": lineno,
                    "match": value,
                    "context": line.strip()[:CONTEXT_LIMIT],
                }
            )

    return violations


def check_jobs(lines, rel_path):
    """Report a file that parses but declares no jobs.

    `line` is the 1-based line of the `jobs:` key when the key is present but
    childless, and null when the key is absent entirely -- a fabricated line 1
    would point a reader at an unrelated line.
    """
    jobs_line = None
    for lineno, raw in enumerate(lines, start=1):
        content = strip_comment(raw.rstrip("\n"))
        if content.startswith("jobs:") and indent_of(content) == 0:
            jobs_line = lineno
            break

    if jobs_line is None:
        return [
            {
                "kind": "no_jobs",
                "file": rel_path,
                "line": None,
                "match": "jobs:",
                "context": "no top-level jobs key",
            }
        ]

    for raw in lines[jobs_line:]:
        content = strip_comment(raw.rstrip("\n"))
        if not content.strip():
            continue
        if indent_of(content) == 0:
            break
        if value_of(content) is not None:
            return []

    return [
        {
            "kind": "no_jobs",
            "file": rel_path,
            "line": jobs_line,
            "match": "jobs:",
            "context": lines[jobs_line - 1].strip()[:CONTEXT_LIMIT],
        }
    ]


def read_lines(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return handle.read().splitlines()
    except (OSError, UnicodeDecodeError) as exc:
        raise RuntimeError("cannot read %s: %s" % (path, exc))


def discover(root):
    """List every workflow file under <root>/.github/workflows, sorted.

    Raises DiscoveryError when the directory is missing or holds no workflow
    file -- both are discovery failures, not clean runs.
    """
    directory = os.path.join(root, WORKFLOW_DIR)
    try:
        entries = os.listdir(directory)
    except FileNotFoundError:
        raise DiscoveryError(
            "no workflow directory found at %s — nothing was checked, which is "
            "a discovery failure rather than a pass" % WORKFLOW_DIR
        )
    except OSError as exc:
        raise RuntimeError("cannot list %s: %s" % (directory, exc))

    found = sorted(
        name for name in entries if name.endswith(WORKFLOW_SUFFIXES)
    )
    if not found:
        raise DiscoveryError(
            "no workflow files discovered under %s — nothing was checked, which "
            "is a discovery failure rather than a pass" % WORKFLOW_DIR
        )
    return [os.path.join(WORKFLOW_DIR, name) for name in found]


class DiscoveryError(Exception):
    """Nothing was found to check, which must never read as a clean result."""


def main():
    parser = argparse.ArgumentParser(
        description="Assert every .github/workflows file parses and declares jobs."
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="explicit workflow paths, relative to --root; overrides discovery",
    )
    parser.add_argument(
        "--root",
        default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        help="repository root (default: the parent of scripts/)",
    )
    args = parser.parse_args()

    root = os.path.abspath(args.root)

    try:
        targets = args.files if args.files else discover(root)

        violations = []
        for rel_path in targets:
            lines = read_lines(os.path.join(root, rel_path))
            violations.extend(scan_lines(lines, rel_path))
            violations.extend(check_jobs(lines, rel_path))

        by_kind = {}
        for item in violations:
            by_kind[item["kind"]] = by_kind.get(item["kind"], 0) + 1

        result = {
            "success": not violations,
            "data": {
                "root": root,
                "scanned": targets,
                "violations": violations,
                "summary": {
                    "total": len(violations),
                    "by_kind": by_kind,
                    "files_scanned": len(targets),
                },
            },
            "error": "",
        }
        print(json.dumps(result, indent=2, ensure_ascii=False))

        if violations:
            for item in violations:
                where = item["file"] if item["line"] is None else "%s:%s" % (
                    item["file"],
                    item["line"],
                )
                print("FAIL: %s %s" % (item["kind"], where), file=sys.stderr)
            print(
                "Fix: quote the value, or reword it so the plain scalar carries "
                "no colon followed by a space.",
                file=sys.stderr,
            )
            return 1
        return 0

    except DiscoveryError as exc:
        print(
            json.dumps(
                {
                    "success": False,
                    "data": {"root": root, "scanned": [], "violations": []},
                    "error": str(exc),
                },
                indent=2,
                ensure_ascii=False,
            )
        )
        print("FAIL: %s" % exc, file=sys.stderr)
        return 1

    except Exception as exc:  # noqa: BLE001 - envelope, never a traceback
        print(
            json.dumps(
                {"success": False, "data": {}, "error": str(exc)},
                indent=2,
                ensure_ascii=False,
            )
        )
        print("FAIL: %s" % exc, file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
