#!/usr/bin/env python3
"""check-marketplace-manifest-sync.py — deterministic manifest-mirror guard.

The root `.claude-plugin/marketplace.json` hand-duplicates two fields from each
plugin's own `.claude-plugin/plugin.json`. This guard asserts, for every plugin
the marketplace enumerates:

  1. DESCRIPTION MIRROR — the marketplace entry's `description` is **strictly
     equal** to that plugin's `plugin.json` `description`.
  2. KEYWORDS SUBSET — the marketplace entry's `keywords` are a **subset** of
     that plugin's `plugin.json` `keywords`.

Why the two arms are asymmetric, and why that is measured rather than assumed.
Descriptions are byte-identical across the roster, so equality is the invariant
they already satisfy. Keyword lists are not: three entries deliberately carry a
curated, narrower list than the plugin manifest they mirror. An equality arm on
keywords would therefore land red on three plugins that are behaving correctly,
and the only ways out would be widening those lists (churn nobody asked for) or
an exemption (which defeats the guard). Subset is the invariant that is both
true today and still catches the drift class: a marketplace-only keyword is
always a mistake, because the marketplace copy is a projection of the plugin's
own list, never a superset of it.

Why this exists at all: nothing bound these two fields together, so a skill
retirement that rewrote one copy left the other stale, advertising a capability
the plugin no longer had. That drift survived until a human found it by hand
months later. A mirror assertion is a durable invariant rather than a
banned-string grep for one historical event — the same reasoning
`check-plugin-inventory.py` states for the inventory bijection.

Why a standalone sibling rather than a third arm inside `check-version-bump.py`,
which already opens both manifests in one pass: that script's identity, its
docstring, its remediation table, its `pr`/`post-merge` modes, its merge-base
anchoring and its CI job name are all specific to `version` lines. Folding an
unrelated content-mirror assertion in would mean a job named for the version gate
failing pull requests over description drift. `check-plugin-inventory.py` faced
the same choice for a structurally identical marketplace-anchored invariant and
chose standalone, naming the restatement cost as acceptable. This follows it.

Two scoping decisions are deliberate rather than incidental:

  * The description arm's subject is the **per-plugin entry**, never the
    manifest's top-level `metadata.description`, which describes the marketplace
    itself and mirrors nothing.
  * Only `description` and `keywords` are asserted. `version` is deliberately
    root-authoritative and already owned by `check-version-bump.py`'s mirror
    pass; `source` and `maturity` exist only on the marketplace side; `name`,
    `author` and `license` are outside the drift class this guard closes.

Plugins are enumerated ONLY from `plugins[].source` — never a glob. Stale
`plugin.json` copies live under `.claude/worktrees/**` and inside plugin caches,
and a tree scan would read those and report violations on a clean repo.

Absence is never agreement. A missing or wrongly-typed field on either side is
its own violation rather than two `None` values comparing equal — a silent pass
on exactly the manifest that is broken — and never an unhandled exception.

Zero discovery is a failure, never a clean zero: a run that compared nothing
must not report the tree as consistent.

Hard clean zero — no baseline file, allowlist, skip marker or per-plugin
exemption. A guard with an exemption surface re-opens the drift class it exists
to close.

Usage:
    python3 scripts/check-marketplace-manifest-sync.py [--root DIR]

    --root defaults to the repo containing this script.

stdlib only; runs under any python3. Exit 0 = clean, 1 = violation(s) found,
2 = script error.
"""

import argparse
import json
import os
import sys

MANIFEST = os.path.join(".claude-plugin", "plugin.json")
MARKETPLACE = os.path.join(".claude-plugin", "marketplace.json")


def read_marketplace(root):
    """Return the marketplace plugins[] list. Raises RuntimeError when unusable.

    Deliberately duplicated from its siblings here rather than imported, since no
    guard in this directory imports another. If the manifest's shape ever
    changes, each copy needs the fix.
    """
    path = os.path.join(root, MARKETPLACE)
    if not os.path.isfile(path):
        raise RuntimeError("marketplace manifest not found at {}".format(path))
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
    except ValueError as exc:
        raise RuntimeError("marketplace.json does not parse as JSON: {}".format(exc))
    plugins = data.get("plugins")
    if not isinstance(plugins, list):
        raise RuntimeError("marketplace.json has no plugins[] array")
    return plugins


def source_to_dirname(source):
    """Normalise a plugins[].source value to a top-level directory name.

    Returns None when the source is not a plain relative path into this repo
    (an absolute path or a remote reference), which this guard cannot resolve.
    Matches the normalisation its siblings here apply, and is duplicated for the
    same reason `read_marketplace` above is.
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


def read_plugin_manifest(root, dirname):
    """Return the parsed plugin.json for one plugin directory, or None."""
    path = os.path.join(root, dirname, MANIFEST)
    if not os.path.isfile(path):
        return None
    try:
        with open(path, encoding="utf-8") as fh:
            loaded = json.load(fh)
    except ValueError:
        return None
    if not isinstance(loaded, dict):
        return None
    return loaded


def absent_sides(entry_value, plugin_value, wanted):
    """Return the sides whose value is missing or of the wrong type."""
    sides = []
    if not isinstance(entry_value, wanted):
        sides.append("marketplace.json")
    if not isinstance(plugin_value, wanted):
        sides.append("plugin.json")
    return sides


def collect(root):
    """Return (violations, data) for the marketplace/plugin.json field mirror."""
    plugins = read_marketplace(root)
    violations = []
    enumerated = 0
    descriptions_compared = 0
    keyword_sets_compared = 0

    for entry in plugins:
        if not isinstance(entry, dict):
            violations.append({
                "code": "source-unresolvable",
                "plugin": None,
                "detail": "plugins[] carries an element that is not an object",
            })
            continue

        enumerated += 1
        source = entry.get("source")
        name = entry.get("name") or (source if isinstance(source, str) else None)
        dirname = source_to_dirname(source)

        if dirname is None:
            violations.append({
                "code": "source-unresolvable",
                "plugin": name,
                "detail": "source {!r} is not a plain relative path into this "
                          "repo, so its plugin.json cannot be located".format(source),
            })
            continue

        plugin = read_plugin_manifest(root, dirname)
        if plugin is None:
            violations.append({
                "code": "manifest-unreadable",
                "plugin": name,
                "detail": "{}/{} is missing or does not parse as a JSON "
                          "object".format(dirname, MANIFEST),
            })
            continue

        entry_desc = entry.get("description")
        plugin_desc = plugin.get("description")
        missing = absent_sides(entry_desc, plugin_desc, str)
        if missing:
            violations.append({
                "code": "description-absent",
                "plugin": name,
                "detail": "description is missing or not a string on: "
                          "{}".format(", ".join(missing)),
            })
        else:
            descriptions_compared += 1
            if entry_desc != plugin_desc:
                violations.append({
                    "code": "description-desync",
                    "plugin": name,
                    "detail": "the marketplace entry description differs from "
                              "{}/{}; the two are mirrored copies and must be "
                              "byte-identical".format(dirname, MANIFEST),
                })

        entry_kw = entry.get("keywords")
        plugin_kw = plugin.get("keywords")
        missing_kw = absent_sides(entry_kw, plugin_kw, list)
        if missing_kw:
            violations.append({
                "code": "keywords-absent",
                "plugin": name,
                "detail": "keywords is missing or not a list on: "
                          "{}".format(", ".join(missing_kw)),
            })
        else:
            keyword_sets_compared += 1
            extras = sorted(set(entry_kw) - set(plugin_kw))
            if extras:
                violations.append({
                    "code": "keywords-not-subset",
                    "plugin": name,
                    "detail": "marketplace-only keyword(s) {}; the marketplace "
                              "list is a projection of the plugin's own list, so "
                              "it may be narrower but never wider".format(
                                  ", ".join(repr(k) for k in extras)),
                })

    # Zero discovery is a failure, never a clean zero: a guard that compared
    # nothing must not report the two manifests as reconciled.
    if not enumerated or not (descriptions_compared or keyword_sets_compared):
        violations.append({
            "code": "nothing-compared",
            "plugin": None,
            "detail": "the guard enumerated {} plugin(s) and performed {} "
                      "description and {} keyword comparison(s); it examined "
                      "nothing".format(enumerated, descriptions_compared,
                                       keyword_sets_compared),
        })

    data = {
        "plugins_enumerated": enumerated,
        "descriptions_compared": descriptions_compared,
        "keyword_sets_compared": keyword_sets_compared,
        "violations": violations,
    }
    return violations, data


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", help="repo root to check (default: this script's parent)")
    args = ap.parse_args(argv)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    root = os.path.abspath(args.root) if args.root else os.path.dirname(script_dir)

    try:
        violations, data = collect(root)
    except (RuntimeError, OSError) as exc:
        print(json.dumps({"success": False, "data": {}, "error": str(exc)}))
        return 2

    by_code = {}
    for v in violations:
        by_code[v["code"]] = by_code.get(v["code"], 0) + 1
    data["summary"] = {"total": len(violations), "by_code": by_code}

    result = {"success": not violations, "data": data, "error": ""}
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if violations:
        print("\nFAIL: {} marketplace manifest-sync violation(s):".format(len(violations)),
              file=sys.stderr)
        for v in violations:
            subject = v["plugin"] or "-"
            print("  [{}] {}  ({})".format(v["code"], subject, v["detail"]),
                  file=sys.stderr)
        print("\nFix: the root marketplace entry mirrors two fields from the "
              "plugin's own manifest, and nothing keeps them together except this "
              "guard. For a `description-desync` finding, edit whichever copy is "
              "stale so the two read byte-for-byte alike — usually the marketplace "
              "copy, since the plugin's own manifest is where a capability change "
              "lands first; never truncate the plugin manifest to match a shorter "
              "root blurb, which trades the drift for a false claim. For a "
              "`keywords-not-subset` finding, either drop the marketplace-only "
              "keyword or add it to the plugin manifest: the marketplace list may "
              "be a curated narrower projection, but it may never name a keyword "
              "the plugin itself does not. A `description-absent` or "
              "`keywords-absent` finding means one side omits the field entirely "
              "or carries the wrong type — restore it rather than deleting its "
              "twin, because two missing values would otherwise agree. "
              "`source-unresolvable` and `manifest-unreadable` mean the entry "
              "could not be joined to a plugin at all, which is a manifest bug "
              "rather than a mirror bug. `nothing-compared` means the guard "
              "examined nothing: plugins[] is empty or every entry failed to "
              "resolve, so a clean exit would have been vacuous.",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
