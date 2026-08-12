#!/usr/bin/env python3
"""check-plugin-inventory.py — deterministic plugin-inventory guard.

Asserts a **bijection** between the plugins the marketplace enumerates and the
plugin directories that actually exist at the repo root:

  1. every `plugins[].source` in `.claude-plugin/marketplace.json` resolves to a
     directory containing `.claude-plugin/plugin.json`;
  2. every top-level directory containing `.claude-plugin/plugin.json` appears
     in `plugins[]`.

Direction 1 restates what `check-version-bump.py` already enforces, so this
guard reads standalone. Direction 2 is the gap this guard exists to close:
`check-version-bump.py` enumerates plugins **only** from the marketplace and
deliberately never globs the tree, so a plugin directory with **no** marketplace
entry is invisible to every other guard in the repo. That is precisely the
residue a half-finished plugin removal leaves behind — the directory survives, no
manifest names it, and nothing anywhere raises.

Enumeration is a single **non-recursive** scan of the repo root, and dot-prefixed
entries are skipped. Both properties are load-bearing: stale plugin manifests
live under `.claude/worktrees/**` and inside plugin caches, and a recursive glob
would report them as unlisted plugins on a perfectly clean tree. This mirrors the
reasoning in `run-plugin-tests.py`'s discovery docstring and the explicit
no-globbing note in `check-version-bump.py`.

Why a bijection rather than a banned-string grep: a one-off "never mention
<retired-plugin>" guard encodes a single historical event, needs a
hand-maintained list of retired names, and says nothing about the next plugin
removed. The bijection is a durable invariant — it catches this failure class and
every future carve-out, in both directions, without being told any names.

stdlib only; runs under any python3. Exit 0 = clean, 1 = violations,
2 = script error.
"""

import argparse
import json
import os
import sys

MANIFEST = os.path.join(".claude-plugin", "plugin.json")
MARKETPLACE = os.path.join(".claude-plugin", "marketplace.json")


def read_marketplace(root):
    """Return plugins[] from the repo marketplace manifest."""
    path = os.path.join(root, MARKETPLACE)
    if not os.path.isfile(path):
        raise RuntimeError("marketplace manifest not found: {}".format(MARKETPLACE))
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
    except ValueError as exc:
        raise RuntimeError("marketplace manifest is not valid JSON: {}".format(exc))
    plugins = data.get("plugins")
    if not isinstance(plugins, list):
        raise RuntimeError("marketplace manifest has no plugins[] array")
    return plugins


def discover_plugin_dirs(root):
    """Top-level directories holding a plugin manifest.

    Non-recursive by design, and dot-prefixed entries are skipped, so stale
    manifests under `.claude/worktrees/**` or a plugin cache never register.
    """
    found = []
    for name in sorted(os.listdir(root)):
        if name.startswith("."):
            continue
        if os.path.isfile(os.path.join(root, name, MANIFEST)):
            found.append(name)
    return found


def source_to_dirname(source):
    """Normalise a plugins[].source value to a top-level directory name.

    Returns None when the source is not a plain relative path into this repo
    (an absolute path or a remote reference), which the bijection cannot judge.
    """
    if not isinstance(source, str) or not source:
        return None
    cleaned = source.strip()
    if cleaned.startswith("./"):
        cleaned = cleaned[2:]
    cleaned = cleaned.rstrip("/")
    if not cleaned or cleaned.startswith("/") or ":" in cleaned or ".." in cleaned:
        return None
    return cleaned


def collect(root):
    """Return the violation list for the inventory bijection."""
    plugins = read_marketplace(root)
    dirs_on_disk = discover_plugin_dirs(root)
    violations = []
    enumerated = set()

    for entry in plugins:
        name = entry.get("name") if isinstance(entry, dict) else None
        source = entry.get("source") if isinstance(entry, dict) else None
        dirname = source_to_dirname(source)
        if dirname is None:
            violations.append({
                "code": "source-unresolvable",
                "plugin": name,
                "source": source,
                "detail": "plugins[].source is not a relative path into this repo",
            })
            continue
        enumerated.add(dirname)
        if not os.path.isfile(os.path.join(root, dirname, MANIFEST)):
            violations.append({
                "code": "source-missing",
                "plugin": name,
                "source": source,
                "detail": "marketplace enumerates a plugin whose directory has no "
                          "{}".format(MANIFEST),
            })

    for dirname in dirs_on_disk:
        if dirname not in enumerated:
            violations.append({
                "code": "plugin-unlisted",
                "plugin": dirname,
                "source": "./{}".format(dirname),
                "detail": "plugin directory exists but no plugins[] entry names it",
            })

    return violations, plugins, dirs_on_disk


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", help="repo root to check (default: this script's parent)")
    args = ap.parse_args(argv)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    root = os.path.abspath(args.root) if args.root else os.path.dirname(script_dir)

    try:
        violations, plugins, dirs_on_disk = collect(root)
    except (RuntimeError, OSError) as exc:
        print(json.dumps({"success": False, "data": {}, "error": str(exc)}))
        return 2

    by_code = {}
    for v in violations:
        by_code[v["code"]] = by_code.get(v["code"], 0) + 1

    result = {
        "success": not violations,
        "data": {
            "marketplace_plugins": len(plugins),
            "plugin_directories": len(dirs_on_disk),
            "violations": violations,
            "summary": {"total": len(violations), "by_code": by_code},
        },
        "error": "",
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if violations:
        print("\nFAIL: {} plugin-inventory violation(s):".format(len(violations)),
              file=sys.stderr)
        for v in violations:
            print("  [{}] {}  ({})".format(v["code"], v["plugin"], v["detail"]),
                  file=sys.stderr)
        print("\nFix: for `source-missing`, the marketplace entry outlived its "
              "directory — remove the entry in the same PR that deleted the "
              "directory. For `plugin-unlisted`, a plugin directory has no "
              "marketplace entry — either add the entry or, if the plugin was "
              "removed, delete the leftover directory. The two halves of a "
              "plugin removal must land together, or one guard or the other "
              "trips.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
