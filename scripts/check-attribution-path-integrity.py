#!/usr/bin/env python3
"""Attribution-path integrity guard: every repo-relative path a LIVE attribution
surface claims must resolve in this repository's tracked index.

Why this exists. An attribution record that points at a path which does not
exist is not a typo — it is an attribution gap, in the one record the project
relies on to show third-party credit is intact. The motivating defect: `NOTICE`
named `cogni-visual/references/cartographic-data/...` from the first stage of an
absorption until the fourth repointed it, so for four stages the repo's
third-party attribution pointed at a path that was not there and nothing
reported it. The class recurs once per absorption and is invisible to CI by
construction, because the only signal was a human reading the file.

SCOPE DECISION
--------------
The unit is the LIVE ATTRIBUTION SURFACE class — the files this repo maintains
as a *current* record of third-party material. Discovery is the SURFACE_NAMES
class crossed with the SURFACE_LOCATIONS class below — those two tuples are the
single definition of the unit and the only place it is written down. No count is
quoted here on purpose: a number in prose drifts the moment a name or a location
is added, and the tuples are two lines away.

Both alternatives considered when this guard was scoped are rejected, and the
reasons are recorded here rather than in a pull-request body that disappears:

  * REPO-WIDE MARKDOWN-REFERENCE INTEGRITY — rejected on measurement, not
    preference. 310 of 748 repo-relative markdown links do not resolve on the
    tree this guard was written against, so a repo-wide check could only land
    behind the baseline or allowlist that this guard's whole point is to do
    without. It is also the wrong unit: link rot in narrative prose is an
    editorial problem, while a broken attribution path is a licensing-compliance
    problem, and only the second is a blocking gate's business.

  * "NOTICE PLUS ONE AUDIT DOC" — rejected as a bandaid. `NOTICE` is not
    special; it is one member of a class, and this guard covers the class. That
    is precisely why the root `LICENSE` and the six per-plugin `LICENSE` files
    are DISCOVERED even though they carry no path claims today: they are clean
    by CONTENT, not excluded by NAME, so the day one of them gains a `See:` line
    it is already covered with nothing to edit.

HOW A FUTURE SURFACE ENTERS SCOPE. By being placed at one of the SURFACE_LOCATIONS
under one of the SURFACE_NAMES — the naming convention IS the registration mechanism, so a new
plugin's `LICENSE`, or a new vendored `*/references/<asset>/LICENSE.md`, is
covered the moment it lands. A surface that cannot fit the convention enters by
adding a discovery pattern here TOGETHER WITH a suite case. There is no
allowlist, baseline or skip marker to edit, in either direction.

WHY THE FROZEN ATTESTATION IS OUT OF CLASS. `docs/relicensing/` holds a frozen
attestation which declares itself "Frozen attestation, not a maintained index"
and states that the repo-root `NOTICE`, not itself, is the live attribution
surface. This repo already settled the general rule in
`docs/contributing/plugin-absorption-slicing.md`: any surface that declares its
own "as of" date is out of scope, because a dated record does not describe the
tree now and correcting it destroys the one thing it is for. So the exclusion is
a CLASS rule that this guard implements STRUCTURALLY — the location class below
never descends into a documentation tree — and not a filename special-case. The
executable half of this file names no repository path, no filename outside the
surface name class, and no claim value at all; that is checkable by reading
SURFACE_NAMES and SURFACE_LOCATIONS, which is a stronger guarantee than any
sentence here. A guard that failed the build whenever that record aged would
force exactly the hand-patching the settled convention forbids.

EXTRACTION RULE
---------------
A line contributes a claim through one of two CARRIERS:

  (a) ASSERTION FIELD — the value of a key that names a location *in this
      repository*. The vocabulary is positive and extensible: ASSERTION_KEYS.
      Provenance keys (PROVENANCE_KEYS: `Packaging`, `Source`, `Underlying
      data`) are out of class by ROLE — they name where material came from
      upstream, never where it sits here. This is what excludes an upstream
      project slug such as an `owner/repo` reference carried by a `Packaging:`
      field, and it excludes it by field role rather than by matching its text:
      no claim VALUE is written anywhere in this file.

  (b) CODE SPAN OR MARKDOWN LINK TARGET — a path inside a backtick span or the
      target of a `[text](target)` link. This is the carrier the in-tree
      per-asset `LICENSE.md` uses, and without it that surface's only claim
      would go unchecked.

A candidate from either carrier is a CLAIM only if it contains `/` and does not
contain `://`. Those two tests are what exclude a URL and a bare filename with
no separator, again by shape rather than by value.

MEMBERSHIP IS THE ASSERTION, NEVER THE GATE. A tempting extra precondition —
"a claim's first segment must be a real tracked top-level entry" — is
deliberately NOT applied, because it is vacuous on the very defect this guard
exists to catch: when a plugin directory is absorbed away, a stale claim naming
it has no tracked first segment either, so that rule would reclassify the stale
claim as a non-claim and the guard would ship green on the regression. Tracked
membership is what gets CHECKED; it never decides what counts as a claim.

RESOLUTION READS THE TRACKED INDEX, NOT THE FILESYSTEM. CI runs on a
case-sensitive filesystem while a contributor's macOS clone is typically
case-insensitive, so a wrong-case path passes `os.path.exists` locally and fails
in CI. Resolving against `git ls-files` matches the exact tracked case and
closes that in both directions. It is also the honest property for an
attribution record: the path must resolve in a FRESH CLONE, so a claim pointing
at an untracked or gitignored file is a finding rather than a pass. This borrows
`check-breadcrumbs.py`'s tracked-content lookup and explicitly NOT its baseline
ratchet — those are two separate mechanisms, and only the first is wanted here.

Zero discovered surfaces is a HARD ERROR rather than a clean zero — this repo
always ships a root `NOTICE` and a root `LICENSE`, so an empty sweep means the
globs stopped matching, not that the tree is clean.

STATED RECALL FLOOR
-------------------
Under-detection is the chosen direction. This runs as a BLOCKING CI gate, so one
false positive blocks every pull request while a false negative costs one
unchecked claim. These are floors on purpose:

  * Only ASSERTION_KEYS are read as assertion fields. A surface that invents a
    new key for the same job goes unchecked until the key is added here.
  * Only the first whitespace-delimited token of an assertion value is taken, so
    a value carrying a path mid-sentence is not read as a claim.
  * A path in a code span that is genuinely an upstream slug rather than a local
    file WOULD be reported. This is the one known false-positive residual and it
    is named here rather than hidden; the remedy is to move such a reference
    behind a provenance field, not to add an allowlist.
  * A claim split across two lines is not reassembled.
  * DISCOVERY DEPTH is a floor, and the most consequential one. SURFACE_LOCATIONS
    is finite and non-recursive, so an attribution surface parked somewhere it
    does not reach is not scanned at all. The locations were chosen by measuring
    where such files actually live in this tree, and the two `references/` depths
    cover both the plugin-root and the far more common per-skill shape. A surface
    at a new depth is covered by adding a location here together with a suite
    case — never by an allowlist, of which this guard has none, in either
    direction. That bound is what lets the guard ship hard clean zero with no
    baseline and no skip marker.

stdlib only; runs under any python3. Exit 0 = clean, 1 = violation(s),
2 = script error.
"""

import argparse
import glob
import json
import os
import re
import subprocess
import sys

# Keys whose value names a location IN THIS REPOSITORY. Positive and extensible:
# adding a key here is how a new surface convention becomes checkable.
ASSERTION_KEYS_RAW = ("Location", "See")
ASSERTION_KEYS = ASSERTION_KEYS_RAW

# Keys that name upstream origin, never a local file. Listed so the role
# distinction is legible and testable, not to be matched against any value.
PROVENANCE_KEYS = ("Packaging", "Source", "Underlying data")

# The role distinction is only real if the two vocabularies cannot overlap: a key
# in both would be read as an assertion and silently defeat the exclusion. Assert
# it at import so the claim above is falsifiable rather than decorative.
assert not (set(ASSERTION_KEYS_RAW) & set(PROVENANCE_KEYS)), (
    "a key cannot be both an assertion and a provenance key"
)

ASSERTION_RE = re.compile(
    r"^\s*(?:\*\*)?(%s)(?:\*\*)?\s*:\s*(\S+)" % "|".join(
        re.escape(k) for k in ASSERTION_KEYS
    )
)
CODE_SPAN_RE = re.compile(r"`([^`\n]+)`")
LINK_TARGET_RE = re.compile(r"\]\(([^)\s]+)\)")

# Discovery is a NAME CLASS crossed with a BOUNDED LOCATION CLASS, not a file
# list. Every name is looked for at every location, so the extension a surface
# happens to use never decides whether it is checked — an asymmetry the earlier
# shape had, where a bare LICENSE was reachable at the root but a LICENSE.md was
# not. The location class is deliberately finite rather than recursive: the
# bound IS the exclusion mechanism (see the recall floor below), which is what
# lets this guard ship with no allowlist.
SURFACE_NAMES = ("NOTICE", "LICENSE", "LICENSE.md")
SURFACE_LOCATIONS = (
    "",
    os.path.join("*", ""),
    os.path.join("*", "references", "*", ""),
    os.path.join("*", "skills", "*", "references", "*", ""),
)
DISCOVERY_PATTERNS = tuple(
    location + name for location in SURFACE_LOCATIONS for name in SURFACE_NAMES
)

CONTEXT_LIMIT = 140


def repo_root_default():
    """Parent of scripts/ — the same anchor run-plugin-tests.py resolves."""
    return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))


def discover(root):
    """Five non-recursive globs, relative and sorted — see the module docstring."""
    found = set()
    for pattern in DISCOVERY_PATTERNS:
        for abs_path in glob.glob(os.path.join(root, pattern)):
            if os.path.isfile(abs_path):
                found.add(os.path.relpath(abs_path, root))
    return sorted(found)


def tracked_paths(root):
    """Every path in the index, exact-case. RuntimeError if this is not a repo."""
    try:
        proc = subprocess.run(
            ["git", "-C", root, "ls-files", "-z"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except OSError as exc:
        raise RuntimeError("could not run git under %s: %s" % (root, exc))
    if proc.returncode != 0:
        raise RuntimeError(
            "git ls-files failed under %s (not a git repository?): %s"
            % (root, proc.stderr.decode("utf-8", "replace").strip())
        )
    entries = proc.stdout.decode("utf-8", "replace").split("\0")
    return {e for e in entries if e}


def is_claim(candidate):
    """Shape test, applied to both carriers: a repo-relative path and not a URL."""
    return "/" in candidate and "://" not in candidate


def extract(line):
    """Return [(candidate, arm)] for one line, in carrier order."""
    out = []
    assertion = ASSERTION_RE.match(line)
    if assertion:
        candidate = assertion.group(2)
        if is_claim(candidate):
            out.append((candidate, "assertion_field"))
        # An assertion field is a whole-line shape, so its own value must not be
        # re-read by the span carrier below and counted a second time.
        return out
    for match in CODE_SPAN_RE.finditer(line):
        candidate = match.group(1).strip()
        if is_claim(candidate):
            out.append((candidate, "code_span"))
    for match in LINK_TARGET_RE.finditer(line):
        candidate = match.group(1).split("#", 1)[0]
        if is_claim(candidate):
            out.append((candidate, "link_target"))
    return out


def resolves(claim_path, tracked):
    """A file claim matches an index entry; a directory claim matches a prefix."""
    claim_path = claim_path.rstrip("/")
    if claim_path not in tracked:
        return any(entry.startswith(claim_path + "/") for entry in tracked)
    return True


def scan_file(root, rel_path, tracked, counters):
    """Walk one surface, extracting claims and checking each against the index."""
    abs_path = os.path.join(root, rel_path)
    try:
        with open(abs_path, "r", encoding="utf-8", errors="replace") as handle:
            lines = handle.read().splitlines()
    except OSError as exc:
        raise RuntimeError("could not read %s: %s" % (rel_path, exc))

    # Advances before any claim is evaluated, so a dead extractor cannot
    # disguise itself by collapsing the population it was supposed to examine.
    counters["surfaces_scanned"] += 1

    findings = []
    for number, line in enumerate(lines, 1):
        for candidate, arm in extract(line):
            counters["claims_examined"] += 1
            if not resolves(candidate, tracked):
                findings.append({
                    "file": rel_path,
                    "line": number,
                    "arm": arm,
                    "claim": candidate,
                    "context": line.strip()[:CONTEXT_LIMIT],
                })
    return findings


def collect(root):
    surfaces = discover(root)
    if not surfaces:
        raise RuntimeError(
            "no attribution surfaces discovered under %s — check --root; this repo "
            "always ships a root NOTICE and LICENSE, so an empty sweep means the "
            "globs stopped matching" % root
        )
    tracked = tracked_paths(root)
    counters = {"surfaces_scanned": 0, "claims_examined": 0}
    findings = []
    for rel_path in surfaces:
        findings.extend(scan_file(root, rel_path, tracked, counters))
    return surfaces, findings, counters


def main(argv):
    parser = argparse.ArgumentParser(description="attribution-path integrity guard")
    parser.add_argument(
        "--root",
        default=None,
        help="tree to scan; discovery and reported paths are relative to it",
    )
    args = parser.parse_args(argv)
    root = os.path.abspath(args.root) if args.root else repo_root_default()

    try:
        surfaces, findings, counters = collect(root)
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
            "surfaces": surfaces,
            "violations": findings,
            "summary": {
                "total": len(findings),
                "by_arm": by_arm,
                "surfaces_affected": len({f["file"] for f in findings}),
                "surfaces_discovered": len(surfaces),
                "surfaces_scanned": counters["surfaces_scanned"],
                "claims_examined": counters["claims_examined"],
            },
        },
        "error": "",
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if findings:
        print("", file=sys.stderr)
        for finding in findings:
            print("FAIL: %s:%d [%s] %s" % (
                finding["file"], finding["line"], finding["arm"], finding["claim"],
            ), file=sys.stderr)
        print("", file=sys.stderr)
        print("Repoint the live attribution surface at the path the asset now "
              "occupies. Never hand-patch a frozen attestation to silence this.",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
