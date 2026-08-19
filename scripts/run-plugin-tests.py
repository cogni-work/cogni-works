#!/usr/bin/env python3
"""run-plugin-tests.py — discover and run every bash test suite in the repo.

The repo ships ~100 standalone bash suites: one `tests/` directory per plugin
plus four at the repo root covering the `scripts/check-*.py` guards that
`.github/workflows/lint.yml` already runs. Until this runner existed, nothing
executed any of them — they ran only when a human remembered. A test nothing
runs is documentation, not a guard, and two suites had in fact drifted out of
agreement with their code without anything reporting it.

The suite contract
------------------

A discovered suite must satisfy exactly three properties. These are the ones
every suite in the tree genuinely shares — nothing more is assumed:

  1. It exits non-zero when any assertion fails, zero otherwise.
  2. It runs as `bash <path>` with no arguments, from any working directory.
     Suites self-locate via `TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"`.
  3. It needs no network, no credentials, and writes only under its own
     `mktemp -d`.

Note what is deliberately NOT assumed. Many suites open with `set -u` and keep
a pass/fail counter, but that convention holds for a minority of the corpus and
the counter names are not uniform, so this runner never parses stdout to decide
an outcome. Exit status is the whole signal. Suites are invoked via `bash` and
never executed directly, because a handful lack the executable bit while
carrying a valid shebang.

Discovery
---------

Two NON-recursive globs relative to `--root`:

    tests/*.sh
    */tests/*.sh

The non-recursion is load-bearing, not an optimisation: matching exactly one
directory level is what keeps dead suites parked under an `_archive/` tree and
sourced-only helper libraries under `tests/fixtures/` out of the run without
enumerating either. Both sit one level deeper than the globs reach. A recursive
walk would sweep them in — the fixtures helpers define functions for a sibling
to source and break if executed directly.

The second glob is `*/tests/*.sh` rather than `cogni-*/tests/*.sh` on purpose.
Both match the identical set today, but the narrower form would silently skip a
future non-`cogni-` component that ships suites, and report a green sweep while
doing it — the same class of silent gap this runner exists to close. `glob`
skips dot-directories, so `.github/` and friends stay out for free.

Usage
-----

    python3 scripts/run-plugin-tests.py                 # run the full sweep
    python3 scripts/run-plugin-tests.py --list          # discover only
    python3 scripts/run-plugin-tests.py --filter trends # substring-match paths
    python3 scripts/run-plugin-tests.py --timeout 60    # per-suite seconds

Emits the repo-standard `{"success", "data", "error"}` envelope on stdout and
human-readable progress on stderr, so the JSON stays machine-parseable when the
two are redirected apart. Exits non-zero if any suite fails, times out, or the
discovery itself comes back empty. A `--filter` that narrows a real discovery
down to nothing is an empty query rather than a broken one, so it exits 0 with
`total: 0` — the floor is keyed on what discovery found, before any filtering.
"""

import argparse
import glob
import json
import os
import subprocess
import sys
import time

DEFAULT_TIMEOUT = 300


def repo_root(explicit):
    """Resolve the repo root: --root if given, else the script's parent."""
    if explicit:
        return os.path.abspath(explicit)
    return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))


def discover(root):
    """Return sorted repo-relative paths of every runnable suite.

    Two non-recursive globs — see the module docstring on why the shape of the
    discovery is itself the exclusion mechanism.
    """
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


def run_suite(root, rel_path, timeout):
    """Run one suite and return its result record.

    Invoked as `bash <path>` rather than executed directly: some suites are not
    marked executable, and all carry a valid shebang. The outcome is the exit
    status and nothing else.
    """
    started = time.time()
    try:
        proc = subprocess.run(
            ["bash", os.path.join(root, rel_path)],
            cwd=root,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout,
        )
        rc = proc.returncode
        output = proc.stdout.decode("utf-8", errors="replace")
        timed_out = False
    except subprocess.TimeoutExpired as exc:
        rc = None
        partial = exc.stdout or b""
        output = partial.decode("utf-8", errors="replace")
        timed_out = True

    return {
        "suite": rel_path,
        "passed": (not timed_out) and rc == 0,
        "returncode": rc,
        "timed_out": timed_out,
        "duration_seconds": round(time.time() - started, 2),
        "output": output,
    }


def main(argv):
    parser = argparse.ArgumentParser(
        description="Discover and run every plugin and repo-root bash test suite."
    )
    parser.add_argument("--root", help="repo root (default: the parent of scripts/)")
    parser.add_argument("--list", action="store_true",
                        help="list discovered suites without running them")
    parser.add_argument("--filter",
                        help="only include suites whose path contains this substring")
    parser.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT,
                        help="per-suite timeout in seconds (default: %d)" % DEFAULT_TIMEOUT)
    args = parser.parse_args(argv)

    root = repo_root(args.root)
    if not os.path.isdir(root):
        print(json.dumps({
            "success": False,
            "data": {},
            "error": "root is not a directory: %s" % root,
        }, indent=2, ensure_ascii=False))
        return 2

    discovered = discover(root)
    suites = discovered
    if args.filter:
        suites = [s for s in discovered if args.filter in s]

    if args.list:
        print(json.dumps({
            "success": True,
            "data": {"root": root, "total": len(suites), "suites": suites},
            "error": "",
        }, indent=2, ensure_ascii=False))
        return 0

    if not discovered:
        # Two questions hide behind an empty list and only one of them is a
        # defect, so the floor keys on the PRE-filter population. Finding
        # nothing before filtering means the globs stopped matching — the repo
        # always ships suites — and that stays a hard failure, including when a
        # --filter was supplied, which is why the test is `discovered` and not
        # `args.filter`. An empty POST-filter list is the other question: a
        # query that legitimately matched nothing. It falls through to the
        # reporting path below, which already emits a zero-suite success.
        print(json.dumps({
            "success": False,
            "data": {"root": root, "total": 0, "suites": []},
            "error": "no test suites discovered — check --root; the globs matched nothing",
        }, indent=2, ensure_ascii=False))
        print("FAIL: no test suites discovered under %s" % root, file=sys.stderr)
        return 1

    print("Running %d test suite(s) under %s" % (len(suites), root), file=sys.stderr)
    results = []
    failed = []
    for index, rel in enumerate(suites, start=1):
        print("  [%d/%d] %s ... " % (index, len(suites), rel), end="", file=sys.stderr)
        sys.stderr.flush()
        record = run_suite(root, rel, args.timeout)
        # A suite's captured output is echoed to stderr below when it fails and
        # is never serialised, so it leaves the record here rather than being
        # carried through the envelope and stripped at the end.
        output = record.pop("output")
        results.append(record)
        if record["timed_out"]:
            status = "TIMEOUT (%ds)" % args.timeout
        elif record["passed"]:
            status = "ok (%.1fs)" % record["duration_seconds"]
        else:
            status = "FAIL (rc=%s)" % record["returncode"]
        if not record["passed"]:
            failed.append((record, output))
        print(status, file=sys.stderr)

    print(json.dumps({
        "success": not failed,
        "data": {
            "root": root,
            "total": len(results),
            "passed": len(results) - len(failed),
            "failed": len(failed),
            "failed_suites": [r["suite"] for r, _ in failed],
            "suites": results,
        },
        "error": "" if not failed else "%d suite(s) failed" % len(failed),
    }, indent=2, ensure_ascii=False))

    if failed:
        print("\nFAIL: %d of %d suite(s) failed:" % (len(failed), len(results)),
              file=sys.stderr)
        for record, output in failed:
            reason = "timed out after %ds" % args.timeout if record["timed_out"] \
                else "exit %s" % record["returncode"]
            print("\n--- %s (%s) ---" % (record["suite"], reason), file=sys.stderr)
            print(output.rstrip() or "(no output)", file=sys.stderr)
        return 1

    print("\nAll %d suite(s) passed." % len(results), file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
