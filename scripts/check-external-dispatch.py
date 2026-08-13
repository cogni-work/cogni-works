#!/usr/bin/env python3
"""check-external-dispatch.py — deterministic external-dispatch guard.

Asserts that **no live-dispatch surface** dispatches a retired engine anywhere in
the repo. This is the machine proof behind the archival decision: once a plugin is
archived (source kept, not installable) or absorbed into another, a live caller
dispatching it would break at runtime. The guard makes that absence objective and
regression-proof.

The retired set is **data, not source** — it lives in `scripts/retired-plugins.json`
(override with `--registry`), so retiring another plugin is a one-line edit to that
file rather than a regex edit here:

    {"retired_prefixes": ["cogni-wiki", "cogni-research"]}

Entries are BARE prefixes with no trailing colon and no surrounding whitespace — this
script appends the colon that makes the token dispatch-shaped, and rejects both a
colon-bearing entry (`cogni-wiki::`) and a padded one (`re.escape("  cogni-wiki  ")`)
rather than compiling a pattern that would silently match nothing.

The registry is **mandatory config, not an optional ratchet**: absent, unreadable,
malformed, wrongly-typed or empty all exit 2. A guard that quietly loaded nothing and
reported a clean zero would be worse than no guard, because CI would stay green while
the invariant went unprotected.

Two scoping choices, stated because the sibling guard next door made the opposite one:

  - **Enumerated, not derived.** `check-plugin-inventory.py` deliberately avoids a
    hand-maintained list of retired names, preferring a bijection that works without
    being told any. That is the right shape *there*, where the live set is the datum.
    Here the live set is not enough: `\bcogni-[a-z0-9-]+:` minus the installed plugins
    would also flag every prose mention of a plugin that simply is not installed in
    the reader's workspace, so the guard would fire on trees it should not. The cost
    of enumerating is a registry that can go **stale** — a plugin retired without an
    entry here is silently unguarded — and nothing detects that today. The retiring
    change is expected to add its own entry; that expectation is the control.
  - **Plugin-granular.** An entry is a whole plugin prefix, and this script appends
    the colon. A retired *skill* on a live plugin (`cogni-x:some-skill`) therefore
    cannot be expressed, and the loader rejects the colon-bearing entry a maintainer
    would reach for rather than silently compiling `cogni-x::`, which would match
    nothing. Widening to full dispatch tokens is a ~10-line change to `load_registry`
    (validate the shape instead of manufacturing it) if that case ever arrives.

Scope — the surfaces a running session actually dispatches FROM:

  - */skills/*/SKILL.md   (skill bodies + their YAML description)
  - */agents/*.md         (agent prompts)
  - */commands/*.md       (slash-command definitions)
  - */hooks/**            (lifecycle hooks: *.sh / *.py / *.json)

Excluded, by design (NOT live-dispatch surfaces):

  - cogni-knowledge/                its delegation-contract / references
                                    legitimately NAME the retired plugins as
                                    history, and it carries the vendored wiki
                                    engine under scripts/vendor/cogni-wiki/; it
                                    dispatches neither retired plugin (FMO
                                    vendored the engine), and the runtime-path
                                    guard for that lives in its own
                                    test_skill_contracts.
                                    (The cogni-research/ and cogni-wiki/ source
                                    trees were removed from the repo entirely
                                    once archived, so they need no exclude.)
  - */wiki/ , top-level wiki/       generated page dumps (a wiki mirror may
                                    quote a retired dispatch as page content)
  - docs/                           the doc mirror (prose, not a dispatch)

`references/` directories are out of scope on purpose: a reference doc is
loaded on demand as documentation, not the surface a session dispatches from, so
a lineage mention there ("modeled on the cogni-research verify-report skill") is
not a caller.

Unlike the breadcrumb guard, this guard targets a HARD clean-zero — there is no
legitimate live dispatch of a registered retired prefix, so the ratchet/baseline
model is the wrong tool. The single escape hatch is a per-line marker for a genuine
NON-dispatch prose mention that must keep the literal token (rare); state the
rationale on the same line:

    ... see cogni-research:verify-report for the lineage  # external-dispatch-guard:allow

The fix when the guard trips is to REMOVE the dispatch (cut the caller over to
the vendored cogni-knowledge surface) or, for a true prose mention, reword it
semantically to drop the `plugin:skill` token (drop the colon) — exactly the
discipline the Maintainer-breadcrumb guard uses.

stdlib only; runs under any python3. Exit 0 = clean (zero dispatches),
1 = dispatch(es) found, 2 = script error.
"""

import argparse
import json
import os
import re
import subprocess
import sys

# git ls-files pathspec globs for the live-dispatch surfaces.
DEFAULT_GLOBS = [
    "*/skills/*/SKILL.md",
    "*/agents/*.md",
    "*/commands/*.md",
    "*/hooks/*",
    "*/hooks/*/*",
]

# Path-prefix excludes (own trees + the history-bearing FMO plugin).
EXCLUDE_PREFIXES = ("cogni-knowledge/",)

# Path-segment excludes (generated wiki mirrors + the doc mirror). A surface
# under any of these is content, not a caller.
EXCLUDE_SEGMENTS = ("/wiki/", "/docs/")
EXCLUDE_TOPLEVEL = ("wiki/", "docs/")

# Default registry location, resolved next to THIS script (never under --root, so
# scanning a foreign tree still reads our own retired set). Override: --registry.
REGISTRY_BASENAME = "retired-plugins.json"

# Per-line escape hatch for a genuine non-dispatch prose mention.
ALLOW_MARKER = "external-dispatch-guard:allow"


def load_registry(path):
    """Return the list of bare retired prefixes from the registry at `path`.

    Every degenerate input raises RuntimeError, which main() renders as the exit-2
    envelope — there is deliberately no empty-list fallback and no hardcoded default
    set (see the module docstring for why).
    """
    if not os.path.exists(path):
        raise RuntimeError("retired-plugin registry not found: {}".format(path))
    try:
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, ValueError) as exc:
        raise RuntimeError("bad retired-plugin registry {}: {}".format(path, exc))

    prefixes = data.get("retired_prefixes") if isinstance(data, dict) else None

    # Mutation-recipe invariant: keep the next line exactly as written, on ONE
    # physical line, and do not repeat its text anywhere else in this file — the
    # recorded recipe rewrites the FIRST match only (perl -0pi, no /g), so a second
    # occurrence would mutate the wrong site and report the guard as decorative.
    if not isinstance(prefixes, list) or not prefixes:
        raise RuntimeError(
            "retired-plugin registry {} must carry a non-empty "
            "'retired_prefixes' list".format(path))

    for entry in prefixes:
        if not isinstance(entry, str) or not entry.strip():
            raise RuntimeError(
                "retired-plugin registry {}: every prefix must be a non-empty "
                "string, got {!r}".format(path, entry))
        if entry != entry.strip():
            raise RuntimeError(
                "retired-plugin registry {}: prefix {!r} must not carry surrounding "
                "whitespace — re.escape would compile it into a pattern that never "
                "matches".format(path, entry))
        if ":" in entry:
            raise RuntimeError(
                "retired-plugin registry {}: prefix {!r} must not carry a colon — "
                "this guard appends it".format(path, entry))
    return prefixes


def compile_dispatch_re(prefixes):
    r"""Compile `\b(?:prefix|…):` — the `plugin:` half of a dispatch reference.

    The trailing colon is MANDATORY, so a bare "cogni-research" is a plain noun and
    is NOT matched, and a hit's `match` is the full "cogni-research:".
    """
    return re.compile(
        r"\b(?:" + "|".join(re.escape(p) for p in prefixes) + r"):")


def discover_files(root):
    """Tracked live-dispatch surfaces, relative to root, via git ls-files."""
    try:
        out = subprocess.check_output(
            ["git", "-C", root, "ls-files", "-z"] + DEFAULT_GLOBS,
            stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, OSError) as exc:
        raise RuntimeError("git ls-files failed: {}".format(exc))
    files = []
    for rel in out.decode("utf-8").split("\x00"):
        if not rel:
            continue
        if rel.startswith(EXCLUDE_PREFIXES):
            continue
        if rel.startswith(EXCLUDE_TOPLEVEL):
            continue
        if any(seg in ("/" + rel) for seg in EXCLUDE_SEGMENTS):
            continue
        files.append(rel)
    return files


def scan_file(abs_path, rel_path, dispatch_re):
    """Yield violation dicts for one file."""
    try:
        with open(abs_path, "r", encoding="utf-8") as fh:
            lines = fh.readlines()
    except (OSError, UnicodeDecodeError) as exc:
        raise RuntimeError("cannot read {}: {}".format(rel_path, exc))
    for lineno, raw in enumerate(lines, start=1):
        line = raw.rstrip("\n")
        if ALLOW_MARKER in line:
            continue
        for m in dispatch_re.finditer(line):
            yield {
                "file": rel_path,
                "line": lineno,
                "match": m.group(0),
                "context": line.strip()[:140],
            }


def collect(root, explicit_files, dispatch_re):
    occ = []
    if explicit_files:
        pairs = []
        for f in explicit_files:
            abs_path = f if os.path.isabs(f) else os.path.join(root, f)
            rel = os.path.relpath(abs_path, root)
            if rel == os.pardir or rel.startswith(os.pardir + os.sep):
                raise RuntimeError(
                    "file {!r} is outside --root {!r}".format(f, root))
            pairs.append((abs_path, rel))
    else:
        pairs = [(os.path.join(root, rel), rel) for rel in discover_files(root)]
    for abs_path, rel in pairs:
        occ.extend(scan_file(abs_path, rel, dispatch_re))
    return occ


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("files", nargs="*",
                    help="explicit files to scan (default: git ls-files globs)")
    ap.add_argument("--root", default=None,
                    help="repo root for discovery + relative paths "
                         "(default: parent of scripts/)")
    ap.add_argument("--registry", default=None,
                    help="retired-prefix registry JSON (default: {} next to this "
                         "script). REPLACES the default file — it is not merged "
                         "with it.".format(REGISTRY_BASENAME))
    args = ap.parse_args(argv)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    root = os.path.abspath(args.root) if args.root else os.path.dirname(script_dir)
    # Anchored on the script, never on --root: scanning a foreign tree must still
    # read OUR retired set, not whatever that tree happens to ship.
    registry_path = args.registry or os.path.join(script_dir, REGISTRY_BASENAME)

    try:
        retired = load_registry(registry_path)
        violations = collect(root, args.files, compile_dispatch_re(retired))
    except RuntimeError as exc:
        print(json.dumps({"success": False, "data": {}, "error": str(exc)}))
        return 2

    by_plugin = {}
    for o in violations:
        plugin = o["file"].split("/", 1)[0]
        by_plugin[plugin] = by_plugin.get(plugin, 0) + 1

    result = {
        "success": not violations,
        "data": {
            "violations": violations,
            "summary": {
                "total": len(violations),
                "by_plugin": by_plugin,
                "files_affected": len(sorted({o["file"] for o in violations})),
            },
        },
        "error": "",
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if violations:
        print("\nFAIL: {} live {} dispatch(es) found "
              "in live-dispatch surfaces:".format(
                  len(violations), "/".join(p + ":" for p in retired)),
              file=sys.stderr)
        for o in violations:
            print("  {}:{}: {}  ->  {}".format(
                o["file"], o["line"], o["match"], o["context"]), file=sys.stderr)
        print("\nFix: cut the caller over to the vendored cogni-knowledge "
              "surface, OR — for a genuine non-dispatch prose mention — reword "
              "it to drop the `plugin:skill` token (drop the colon), or mark the "
              "line with `# external-dispatch-guard:allow` and a rationale.",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
