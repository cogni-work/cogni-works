#!/usr/bin/env python3
"""Retirement-ledger gate — a skill retirement must account for its trigger phrases.

WHAT THIS ASSERTS. When a branch deletes a `cogni-workspace/skills/<name>/SKILL.md`,
every trigger phrase that file advertised **at the merge base** must still be
accounted for at HEAD, in one of exactly two ways: a surviving live skill yields
the same phrase (it was re-claimed, so nothing was lost), or
`cogni-workspace/references/retired-trigger-phrases.tsv` carries a row for it with
a non-empty `reason` (the retirement was recorded). A phrase in neither is a
violation.

WHY THIS IS A SEPARATE GUARD AND NOT ANOTHER ARM OF C10. Case C10 in
`cogni-workspace/tests/test-skill-trigger-phrases.sh` cross-checks the ledger
against the live tree in both directions: `comm -23` finds a phrase recorded
`claimed` that no live skill yields (an orphan), and `comm -12` finds a phrase
recorded `retired` that a live skill does yield (a stale record). Both directions
operate over sets that a silently-dropped phrase is absent from. Delete a skill
and write no row, and the phrase is neither claimed nor retired nor live — it
leaves both sides of the comparison at once, the two sides still agree, and C10
stays green on a claim surface that just shrank. C10 is tree-only by design (its
suite takes no git ref), so the omission is not detectable there at all: seeing it
requires the base side. That is this guard's whole subject.

MERGE BASE, NEVER THE BASE-REF TIP. The deleted-file set and the base-side blob
are both resolved fork-point relative — `git diff <base>...HEAD` and
`git show $(git merge-base <base> HEAD):<path>`. Anchoring on the base-ref tip
would false-flag a branch forked before `main` advanced: `main`'s own later
deletions would read as this branch's. Since `main` here advances on every merge,
that would misfire on most real PRs. This is the same anchoring decision, for the
same reason, as `scripts/check-version-bump.py`.

THE LEDGER IS READ FROM THE HEAD SIDE. Deliberately, and it is load-bearing: the
row that satisfies this guard is the one the author adds **on the branch**. Read
the ledger from the base side and that row is invisible, so the documented remedy
would never satisfy the check — the guard would be unfixable rather than merely
wrong. The live-skill set is read from HEAD for the same reason: a re-claim lands
on the branch too.

SCOPED TO DELETIONS. A phrase can also leave the surface when a *surviving*
skill's `description:` is edited to drop it. That is the same omission class but a
different diff shape — it needs a per-skill base-vs-head phrase-set diff over
modified files rather than this deletion scan — so it is tracked separately rather
than widened into here.

DEGRADATION IS DELIBERATE. An unresolvable base ref (shallow clone, offline
runner, unfetched remote) yields `status: "degraded"` and exit 0. A guard that
hard-failed when it cannot see the baseline would block every PR on a constrained
runner. The cost of that choice is that a dropped `fetch-depth: 0` turns this
guard into a vacuous pass, which is why its CI job re-grades the SAME invocation's
JSON and fails the build when the status is `degraded`.

REJECTED ALTERNATIVE — a checked-in baseline snapshot of the phrase set, compared
against the current tree. It needs no git history, but it reintroduces exactly the
stale-record class the ledger already carries: the snapshot becomes a second thing
to keep in step, and a retirement that forgets the ledger would equally forget the
snapshot.

EXTRACTOR PARITY. The phrase extraction below reproduces `emit_phrases` in
`cogni-workspace/tests/test-skill-trigger-phrases.sh` exactly — same frontmatter
match, same column-0 description terminator, same YAML scalar unwrap performed
BEFORE quote-hunting, same double-quoted-spans-only rule, same
`" ".join(phrase.split()).lower()` key. No shared extractor exists to import, so
this is a second implementation, and a loose one would produce false greens in
precisely the direction this guard exists to close. Case C11 in that suite pins the
two together by diffing this script's `--emit-phrases` output against
`emit_phrases` over the real tree.

UNPARSEABLE IS NOT EMPTY. `phrases_from_skill_text` returns the `UNPARSEABLE`
sentinel for its keys when it could not parse the file at all — no frontmatter
block, or a block with no `description:` key — and a list, possibly empty, only
when it parsed. Collapsing the two is the invisibility class this guard exists
to close: an empty answer from a failed parse is indistinguishable from a
genuine empty, and every caller reading it as "nothing to check" goes green on
the failure. Each call site states its own decision inline; this paragraph
deliberately does not enumerate them, so it cannot drift out of step with one.
The sentinel is a truthy object rather than `None` on purpose — see its
definition.

Usage: check-retirement-ledger.py [--root PATH] [--base-ref REF]
       check-retirement-ledger.py --emit-phrases SKILLS_DIR

  RETIREMENT_LEDGER_BASE_REF  overrides --base-ref (default: origin/main).

Envelope on stdout, human summary on stderr.
Exit 0 clean or degraded, 1 violations, 2 script error.

Stdlib only; runs under any python3.
"""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

DEFAULT_BASE_REF = "origin/main"
SKILLS_REL = "cogni-workspace/skills"
LEDGER_REL = "cogni-workspace/references/retired-trigger-phrases.tsv"
METRIC_VERSION = "1"

# Only a one-level `<skills>/<name>/SKILL.md` is a skill, matching the extractor's
# own non-recursive listdir. A deeper path is not a skill and must not be demanded.
SKILL_PATH_RE = re.compile(r"^" + re.escape(SKILLS_REL) + r"/[^/]+/SKILL\.md$")


# Returned in place of a key list when a SKILL.md could not be parsed at all.
# Deliberately TRUTHY, unlike `None`: the one silent way back into the class this
# guard closes is a new consumer writing `if keys:` before iterating. Against a
# falsy sentinel that reads as "nothing to check" and skips; against this one it
# falls through to iteration and raises TypeError at once.
UNPARSEABLE = object()


def git(repo_root, *args):
    """Run a git command in repo_root. Returns (exit_code, stdout, stderr)."""
    proc = subprocess.run(
        ("git",) + args, cwd=str(repo_root),
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    return proc.returncode, proc.stdout, proc.stderr


def phrases_from_skill_text(text, fallback_name):
    """Phrases + skill name from one SKILL.md's text.

    Returns `(keys, name)`. `keys` is a list when the file parsed — possibly
    the empty list, meaning it parsed and advertised no quoted phrase — and the
    `UNPARSEABLE` sentinel when it could not be parsed at all: no frontmatter
    block, or a block carrying no `description:` key. Callers must distinguish
    the two; see UNPARSEABLE IS NOT EMPTY in the module docstring.

    Byte-for-byte the normal form of `emit_phrases`. Every step here is load
    bearing; see EXTRACTOR PARITY in the module docstring.
    """
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return UNPARSEABLE, fallback_name
    fm = m.group(1)
    nm = re.search(r"^name:[ \t]*(\S+)", fm, re.M)
    name = nm.group(1) if nm else fallback_name
    # description: through the next TOP-LEVEL key (column 0), or end of block.
    dm = re.search(r"^description:.*?(?=^[A-Za-z_][A-Za-z0-9_-]*:|\Z)", fm, re.M | re.S)
    if not dm:
        return UNPARSEABLE, name
    body = re.sub(r"^description:[ \t]*", "", dm.group(0), count=1)
    # Unwrap the YAML scalar BEFORE hunting for quoted phrases: on a
    # double-quoted scalar the outer quotes are syntax, not a trigger phrase.
    stripped = body.strip()
    if stripped[:1] in (">", "|"):
        stripped = stripped.split("\n", 1)[1] if "\n" in stripped else ""
    elif stripped[:1] == "\"" and stripped[-1:] == "\"":
        stripped = stripped[1:-1].replace("\\\"", "\"")
    elif stripped[:1] == chr(39) and stripped[-1:] == chr(39):
        stripped = stripped[1:-1].replace(chr(39) * 2, chr(39))
    keys, seen = [], set()
    for phrase in re.findall(r"\"([^\"]+)\"", stripped):
        key = " ".join(phrase.split()).lower()
        if not key or key in seen:
            continue
        seen.add(key)
        keys.append(key)
    return keys, name


def iter_skills(skills_dir):
    """Yield `(keys, name)` per live `<skills_dir>/<entry>/SKILL.md`, in name order.

    ONE traversal, shared by both callers on purpose. `emit_phrases` is the copy
    case C11 pins against the suite's own extractor; `live_phrase_keys` builds
    the accounting set the whole comparison rests on. Were those separate walks,
    C11 would grade only the first, and a later change to "what counts as a live
    skill" could land in the pinned copy alone — the unpinned one would then
    under-collect live phrases, the guard would demand rows for phrases a
    surviving skill still claims, and C11 would stay green throughout. Routing
    both through here makes the pin cover the live side transitively.

    Raises OSError if `skills_dir` is not listable; callers decide what that means.
    """
    for entry in sorted(os.listdir(skills_dir)):
        path = os.path.join(skills_dir, entry, "SKILL.md")
        if not os.path.isfile(path):
            continue
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        yield phrases_from_skill_text(text, entry)


def emit_phrases(skills_dir):
    """Parity mode. Prints `<key>\\t<name>`; exit 3 unlistable dir, 4 no SKILL.md."""
    try:
        found_any = False
        for keys, name in iter_skills(skills_dir):
            found_any = True
            if keys is UNPARSEABLE:
                # The suite copy counts the file as found and then `continue`s
                # past an unparseable one. Mirror that exactly: parity mode's
                # whole job is to be byte-identical to it.
                continue
            for key in keys:
                print("%s\t%s" % (key, name))
    except OSError:
        return 3
    return 0 if found_any else 4


def live_phrase_keys(skills_dir):
    """Every phrase key a live skill yields at HEAD.

    An unparseable live skill contributes nothing. That is the safe direction:
    this set is what EXCUSES a retired phrase, so omitting a file can only make
    the guard demand more, never less.
    """
    try:
        return {key for keys, _name in iter_skills(skills_dir)
                if keys is not UNPARSEABLE for key in keys}
    except OSError:
        return set()


def ledger_phrase_keys(ledger_path):
    """Keys the HEAD-side ledger accounts for.

    A row accounts for its phrase only when it is well formed AND carries a
    non-empty reason — the documented remedy is recording the retirement WITH a
    justification, so an empty-reason row must not discharge the obligation.
    Row hygiene beyond that (owner attribution, key normalization) stays C10's.
    """
    keys = set()
    with open(ledger_path, encoding="utf-8") as fh:
        for line in fh:
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            fields = line.rstrip("\n").split("\t")
            if len(fields) != 4:
                continue
            key, status, _owner, reason = fields
            if status not in ("claimed", "retired") or not reason.strip():
                continue
            if key:
                keys.add(key)
    return keys


def render(data, error=None):
    """Emit the envelope. `clean` and `count` are DERIVED here, never stored.

    They are pure functions of `violations`, and the sibling guard
    (`scripts/check-version-bump.py`) derives them at render time for the same
    reason: hand-maintaining them at each exit is three sites that must agree,
    and the one that disagrees reports a count its own violation list refutes.
    """
    if data is not None:
        violations = data.get("violations") or []
        data["count"] = len(violations)
        data["clean"] = not violations
    print(json.dumps({"success": error is None, "data": data, "error": error}))


def main():
    parser = argparse.ArgumentParser(add_help=True)
    parser.add_argument("--root", default=None,
                        help="repository root (default: this script's repo)")
    parser.add_argument("--base-ref", default=None,
                        help="base ref to anchor on (default: origin/main)")
    parser.add_argument("--emit-phrases", default=None, metavar="SKILLS_DIR",
                        help="parity mode: print <key>TAB<name> and exit")
    args = parser.parse_args()

    # Parity mode short-circuits BEFORE any git call, on purpose. C11 invokes it
    # from a suite that runs in the deliberately shallow plugin-test-suites job,
    # where no base ref and no merge base resolve; a git call ordered ahead of
    # this dispatch would redden that job.
    if args.emit_phrases is not None:
        return emit_phrases(args.emit_phrases)

    repo_root = Path(args.root).resolve() if args.root \
        else Path(__file__).resolve().parent.parent
    base_ref = (args.base_ref or os.environ.get("RETIREMENT_LEDGER_BASE_REF")
                or DEFAULT_BASE_REF)

    data = {
        "status": "ok", "violations": [],
        "base_ref": base_ref, "merge_base": None, "deleted_skills": [],
        "metric_version": METRIC_VERSION,
    }

    def degrade(reason):
        data["status"] = "degraded"
        data["degraded_reason"] = reason
        render(data)
        sys.stderr.write("retirement-ledger gate DEGRADED: %s\n" % reason)
        return 0

    rc, _, _ = git(repo_root, "rev-parse", "--verify", "--quiet",
                   "{}^{{commit}}".format(base_ref))
    if rc != 0:
        return degrade("base ref '{}' not available (offline, shallow clone, "
                       "or unfetched)".format(base_ref))

    rc, mb_out, _ = git(repo_root, "merge-base", base_ref, "HEAD")
    if rc != 0 or not mb_out.strip():
        return degrade("no merge base between '{}' and HEAD".format(base_ref))
    merge_base = mb_out.strip()
    data["merge_base"] = merge_base

    # Deletions, fork-point relative. `--diff-filter=D` must stay one unsplit
    # token in this argument list — it is what scopes the guard to retirements.
    rc, diff_out, diff_err = git(repo_root, "diff", "--name-only",
                                 "--diff-filter=D",
                                 "{}...HEAD".format(base_ref))
    if rc != 0:
        render(data, "could not diff against '{}': {}".format(
            base_ref, (diff_err or "").strip()[:200]))
        return 2

    deleted = [p for p in diff_out.splitlines() if SKILL_PATH_RE.match(p)]
    if not deleted:
        render(data)
        sys.stderr.write("retirement-ledger gate: no skill deletion in this "
                         "branch; nothing to account for.\n")
        return 0

    ledger_path = repo_root / LEDGER_REL
    if not ledger_path.is_file():
        # Same element shape as the main path below — one key, one schema.
        # `phrases` is null rather than 0: with no ledger there is nothing to
        # compare against, so the count was never computed, which is a
        # different fact from "this skill advertised none".
        data["deleted_skills"] = [{"path": p, "skill": p.split("/")[-2],
                                   "phrases": None} for p in deleted]
        data["violations"] = [{"check": "ledger-missing", "path": LEDGER_REL,
                               "detail": "branch deletes a skill but the "
                                         "retirement ledger is missing or "
                                         "unreadable at HEAD"}]
        render(data)
        sys.stderr.write("FIX_HINTS: restore %s and record the retired "
                         "phrases in it.\n" % LEDGER_REL)
        return 1

    accounted = live_phrase_keys(str(repo_root / SKILLS_REL)) \
        | ledger_phrase_keys(str(ledger_path))

    violations = []
    for path in deleted:
        rc, blob, blob_err = git(repo_root, "show",
                                 "{}:{}".format(merge_base, path))
        if rc != 0:
            # Never a silent skip: a blob we cannot read is a phrase set we
            # cannot check, which is the invisibility class this guard closes.
            render(data, "could not read '{}' at the merge base: {}".format(
                path, (blob_err or "").strip()[:200]))
            return 2
        keys, name = phrases_from_skill_text(blob, path.split("/")[-2])
        # `phrases` is null when the blob did not parse, for the same reason the
        # ledger-missing arm uses null: never computed is a different fact from
        # "this skill advertised none".
        data["deleted_skills"].append(
            {"path": path, "skill": name,
             "phrases": None if keys is UNPARSEABLE else len(keys)})
        if keys is UNPARSEABLE:
            # A blob we could not PARSE is a phrase set we cannot check, exactly
            # like a blob we could not READ a few lines above.
            violations.append({"check": "base-blob-unparseable",
                               "skill": name, "path": path, "phrase": None,
                               "detail": "no parseable frontmatter description "
                                         "block at the merge base, so the "
                                         "trigger phrases it advertised are "
                                         "unknowable"})
            continue
        for key in keys:
            if key not in accounted:
                violations.append({"check": "retirement-row-missing",
                                   "skill": name, "path": path, "phrase": key,
                                   "detail": "trigger phrase \"%s\" is claimed "
                                             "by no surviving skill and carried "
                                             "by no ledger row" % key})

    data["violations"] = violations
    render(data)

    if violations:
        # Every violation carries `detail`, so this pass never branches on which
        # keys a given check happens to have. Only the remedies differ, below.
        checks = {v["check"] for v in violations}
        sys.stderr.write(
            "retirement-ledger gate: %d violation(s) from %d deleted "
            "skill(s).\n" % (len(violations), len(deleted)))
        for v in violations:
            sys.stderr.write("  %s: %s\n" % (v["skill"], v["detail"]))
        if "retirement-row-missing" in checks:
            sys.stderr.write(
                "FIX_HINTS: for each unaccounted phrase above, either re-claim "
                "it in a surviving skill's frontmatter description, or add a "
                "row to %s as\n"
                "  <phrase_key>\\tretired\\t-\\t<non-empty reason>\n"
                "The key is the extractor's normal form: trimmed, internal "
                "whitespace collapsed to single spaces, lowercased.\n"
                % LEDGER_REL)
        if "base-blob-unparseable" in checks:
            # No remedy can edit the merge-base blob, so do not prescribe one.
            # Either the deletion is abandoned, or a human vouches for the set.
            sys.stderr.write(
                "FIX_HINTS: the merge-base content of the file(s) above is "
                "fixed and cannot be re-parsed by any commit on this branch, "
                "so the phrase set they advertised is unknowable rather than "
                "merely unrecorded. Either restore the file at HEAD (which "
                "abandons the retirement), or establish the retired phrases by "
                "hand — read the blob with `git show <merge-base>:<path>` — and "
                "record each one in %s with a non-empty reason.\n" % LEDGER_REL)
        return 1

    sys.stderr.write("retirement-ledger gate: %d deleted skill(s), every "
                     "trigger phrase accounted for.\n" % len(deleted))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # noqa: BLE001 - envelope every failure
        render(None, "unhandled error: %s" % exc)
        sys.exit(2)
