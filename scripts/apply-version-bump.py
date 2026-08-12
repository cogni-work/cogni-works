#!/usr/bin/env python3
"""apply-version-bump.py — post-merge patch bump for every plugin a merge touched.

The write half of the version contract whose read half is `check-version-bump.py`.
Feature branches no longer author the `version` line (that single line was the
canonical merge-conflict class — the instant one PR merged, every other open PR's
version line became a textual conflict). This script is the sole actor that
advances a version: `.github/workflows/cogni-version-bump.yml` runs it on every
push to main and it patch-increments each plugin the merge actually touched, once.

insight-wave mirrors every version into the root `.claude-plugin/marketplace.json`
for Claude Desktop's update detection, so a bump is a PAIRED edit — `plugin.json`
and the plugin's `marketplace.json` entry, or neither. A half-applied bump ships an
invisible update, so this script never writes one file without the other.

Safety properties, in the order they matter:

  * ENUMERATION. Plugins come only from `marketplace.json` `plugins[].source`,
    never a glob — stale `plugin.json` copies live under `.claude/worktrees/**`.

  * PATCH-ONLY. Only the last version component is incremented, and only when it
    is a plain non-negative integer. This structurally cannot cross a maturity
    boundary (`0.0.x` stays `0.0.x`); boundary crossings stay human, per CLAUDE.md.

  * SURGICAL EDIT. The version value is replaced by an anchored `re.subn` on the
    file text rather than a `json.dump` round-trip. A round-trip would reformat
    hand-maintained files and — without `ensure_ascii=False` — escape every
    non-ASCII character in 14 descriptions.

  * SCOPED MARKETPLACE EDIT. `marketplace.json` holds all 14 entries in one file,
    so an unscoped regex could rewrite the wrong plugin, or the root
    `metadata.version`. The replacement is confined to the text span between this
    plugin's `"name": "<plugin>"` key and the next entry's `"name": "` key.

  * VERIFY BEFORE WRITE. Nothing is written until the proposed new text is
    re-parsed and structurally compared against the old parse: same keys, same
    entry order, every field of every entry byte-identical except exactly the
    intended `version` values. Any deviation aborts the whole run with exit 2 and
    leaves the tree untouched. This is what makes a mis-scoped regex a loud
    failure rather than a silent 14-entry corruption.

A plugin whose pair is already out of sync, whose version tail is non-numeric, or
whose anchor cannot be located exactly once is SKIPPED with a reason rather than
guessed at — and skipping is total: neither file is written for that plugin.

This script never shells out to git. The caller computes the touched-file set —
the workflow does it in bash, where the push-shape edge cases (zero shas, a
manual range, the fallback chain) are easiest to log — and hands it over as a
plain list. That keeps every branch here exercisable from a fixture.

Usage:
    # normal (workflow) use
    python3 scripts/apply-version-bump.py --changed-file changed-files.txt

    # testing — supply the changed paths directly
    python3 scripts/apply-version-bump.py --changed cogni-help/README.md
    python3 scripts/apply-version-bump.py --changed ... --dry-run

Output: {"success": bool, "data": {"bumped": [...], "skipped": [...]}, "error": ""}
Exit 0 = ran cleanly (including "nothing to bump"), 1 = a touched plugin was
skipped with severity "error" (healthy plugins were still written — the caller
pushes them, then fails), 2 = script or verification error, nothing written.
"""

import argparse
import json
import re
import sys
from pathlib import Path


def fail(msg):
    print(json.dumps({"success": False, "data": None, "error": msg},
                     indent=2, ensure_ascii=False))
    return 2


def patch_increment(version):
    """'1.2.9' -> '1.2.10'. None when the tail is not a plain integer."""
    if not isinstance(version, str):
        return None
    comps = version.split(".")
    if len(comps) < 2 or not comps[-1].isdigit():
        return None
    return ".".join(comps[:-1] + [str(int(comps[-1]) + 1)])


def replace_version(text, old, new, start=0, end=None):
    """Anchored single replacement of a `"version": "<old>"` value within a span.
    Returns the new text, or None when the anchor is not found exactly once.

    The replacement is a CALLABLE, never a replacement string. `new` is digits and
    dots today, but a replacement string re-interprets backslashes and `\\g<N>`,
    and that class of bug has no business living next to a 14-entry manifest.
    """
    end = len(text) if end is None else end
    span = text[start:end]
    pattern = r'("version"\s*:\s*")' + re.escape(old) + r'(")'
    if len(re.findall(pattern, span)) != 1:
        return None
    new_span, n = re.subn(pattern, lambda m: m.group(1) + new + m.group(2),
                          span, count=1)
    if n != 1:
        return None
    return text[:start] + new_span + text[end:]


def entry_span(text, plugin):
    """Text span of one plugins[] entry: from its `"name": "<plugin>"` key up to
    the next entry's `"name": "` key. Keeps the edit away from sibling entries and
    from the root `metadata.version`, which precedes plugins[]."""
    needle = '"name": "{}"'.format(plugin)
    start = text.find(needle)
    if start == -1 or text.find(needle, start + 1) != -1:
        return None  # absent, or ambiguous
    nxt = text.find('"name": "', start + len(needle))
    return start, (nxt if nxt != -1 else len(text))


def verify_plugin_json(old_text, new_text, new_version):
    old, new = json.loads(old_text), json.loads(new_text)
    if new.get("version") != new_version:
        return "version did not land as {}".format(new_version)
    if {k: v for k, v in old.items() if k != "version"} != \
       {k: v for k, v in new.items() if k != "version"}:
        return "a field other than `version` changed"
    return None


def verify_marketplace(old_text, new_text, expected):
    """expected: {plugin_name: new_version}. Everything else must be identical."""
    old, new = json.loads(old_text), json.loads(new_text)
    if set(old) != set(new):
        return "top-level keys changed"
    for key in old:
        if key != "plugins" and old[key] != new[key]:
            return "root key `{}` changed".format(key)
    o_plugins, n_plugins = old.get("plugins") or [], new.get("plugins") or []
    if len(o_plugins) != len(n_plugins):
        return "plugin count changed"
    for o, n in zip(o_plugins, n_plugins):
        name = o.get("name")
        if n.get("name") != name:
            return "entry order changed at `{}`".format(name)
        want = expected.get(name, o.get("version"))
        if n.get("version") != want:
            return "entry `{}` version is {}, expected {}".format(
                name, n.get("version"), want)
        if {k: v for k, v in o.items() if k != "version"} != \
           {k: v for k, v in n.items() if k != "version"}:
            return "entry `{}` changed a field other than `version`".format(name)
    return None


def main(argv):
    parser = argparse.ArgumentParser(
        description="Patch-bump the version of every plugin a merge touched, in "
                    "both plugin.json and marketplace.json.")
    parser.add_argument("--root", default=None,
                        help="Repo root (default: the repo containing this script).")
    parser.add_argument("--changed-file", default=None,
                        help="File of newline-separated repo-relative paths the "
                             "merge touched; '-' reads stdin.")
    parser.add_argument("--changed", nargs="*", default=None,
                        help="Changed paths, supplied directly (testing).")
    parser.add_argument("--dry-run", action="store_true",
                        help="Compute and verify, but write nothing.")
    args = parser.parse_args(argv)

    repo_root = Path(args.root).resolve() if args.root \
        else Path(__file__).resolve().parent.parent

    market_path = repo_root / ".claude-plugin" / "marketplace.json"
    if not market_path.is_file():
        return fail("marketplace manifest not found at {}".format(market_path))
    try:
        market_text = market_path.read_text(encoding="utf-8")
        manifest = json.loads(market_text)
    except (json.JSONDecodeError, OSError) as exc:
        return fail("marketplace.json does not parse as JSON: {}".format(exc))

    if args.changed is not None:
        changed = [c.strip() for c in args.changed if c.strip()]
    elif args.changed_file:
        try:
            blob = sys.stdin.read() if args.changed_file == "-" \
                else Path(args.changed_file).read_text(encoding="utf-8")
        except OSError as exc:
            return fail("cannot read changed-file list: {}".format(exc))
        changed = [line.strip() for line in blob.splitlines() if line.strip()]
    else:
        return fail("one of --changed-file or --changed is required")

    bumped, skipped = [], []
    market_new_text = market_text
    expected = {}
    pending_plugin_writes = []  # (path, new_text)

    for entry in manifest.get("plugins") or []:
        source = (entry.get("source") or "").lstrip("./")
        if not source:
            continue
        name = entry.get("name") or source

        if not any(p == source or p.startswith("{}/".format(source))
                   for p in changed):
            continue

        rel_manifest = "{}/.claude-plugin/plugin.json".format(source)
        plugin_path = repo_root / rel_manifest

        def skip(reason, severity="warning"):
            skipped.append({"plugin": name, "severity": severity, "reason": reason})

        if not plugin_path.is_file():
            skip("plugin.json not found at {}".format(rel_manifest))
            continue
        try:
            plugin_text = plugin_path.read_text(encoding="utf-8")
            old_version = json.loads(plugin_text).get("version")
        except (json.JSONDecodeError, OSError) as exc:
            skip("plugin.json does not parse: {}".format(exc))
            continue

        # Mirror precondition. Which of the two is authoritative is not this
        # script's call to make, so bump neither and surface it for a human.
        if old_version != entry.get("version"):
            skip("mirror drift: plugin.json says {} but marketplace.json says {} "
                 "— reconcile by hand, then re-run; the version cannot advance "
                 "until they agree".format(old_version, entry.get("version")),
                 severity="error")
            continue

        new_version = patch_increment(old_version)
        if new_version is None:
            skip("unexpected version shape '{}'".format(old_version))
            continue

        plugin_new_text = replace_version(plugin_text, old_version, new_version)
        if plugin_new_text is None:
            skip("could not locate exactly one version value in {}".format(
                rel_manifest), severity="error")
            continue
        problem = verify_plugin_json(plugin_text, plugin_new_text, new_version)
        if problem:
            return fail("{}: verification failed — {}".format(rel_manifest, problem))

        # Re-derived from the WORKING text on every iteration, not computed once
        # up front: a `...9 -> ...10` bump grows the file by a byte and shifts
        # every later span, so a cached span would misplace the next plugin's
        # edit in a multi-plugin merge.
        span = entry_span(market_new_text, name)
        if span is None:
            skip("could not locate a unique marketplace.json entry for {}".format(name),
                 severity="error")
            continue
        candidate = replace_version(market_new_text, old_version, new_version,
                                    span[0], span[1])
        if candidate is None:
            skip("could not locate exactly one version value in the "
                 "marketplace.json entry for {}".format(name), severity="error")
            continue

        market_new_text = candidate
        expected[name] = new_version
        pending_plugin_writes.append((plugin_path, plugin_new_text))
        bumped.append({"plugin": name, "source": source,
                       "old": old_version, "new": new_version})

    if bumped:
        # One structural check over the accumulated marketplace edits. Runs before
        # anything is written, so a mis-scoped replacement aborts with a clean tree.
        problem = verify_marketplace(market_text, market_new_text, expected)
        if problem:
            return fail("marketplace.json verification failed — {}".format(problem))

        if not args.dry_run:
            for path, text in pending_plugin_writes:
                path.write_text(text, encoding="utf-8")
            market_path.write_text(market_new_text, encoding="utf-8")

    paths = [b["source"] + "/.claude-plugin/plugin.json" for b in bumped]
    if bumped:
        paths.append(".claude-plugin/marketplace.json")

    # A hard skip means a touched plugin's version silently stops advancing —
    # that must be loud. The healthy plugins in the same merge were still
    # written, so the caller pushes them and fails the run afterwards rather than
    # stalling every other plugin behind one drifted manifest.
    hard = [s for s in skipped if s["severity"] == "error"]

    print(json.dumps({
        "success": not hard,
        "data": {
            "bumped": bumped,
            "skipped": skipped,
            "paths_to_stage": paths,
            "dry_run": bool(args.dry_run),
        },
        "error": "",
    }, indent=2, ensure_ascii=False))

    for s in skipped:
        print("{}: version-bump skipped {}: {}".format(
            s["severity"].upper(), s["plugin"], s["reason"]), file=sys.stderr)
    for b in bumped:
        print("bumped {} {} -> {}".format(b["plugin"], b["old"], b["new"]),
              file=sys.stderr)
    return 1 if hard else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
