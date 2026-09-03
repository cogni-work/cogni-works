#!/usr/bin/env python3
"""check-output-style-placement.py -- output-style registers live at the plugin root.

WHY THIS EXISTS. A plugin's `output-styles/` directory is auto-discovered by
Claude Code and surfaces in the `/config` picker only when it sits at the PLUGIN
ROOT. A register parked one level deeper -- `assets/output-styles/` was the
observed instance -- is discovered by nothing, and the failure is silent: the
files are present, they parse, they read like configuration, and no guard,
audit or test reports them. The observed workaround was worse than the bug,
because it looked like a fix: an init skill hand-copied the file into every
workspace's `.claude/output-styles/`, which only makes a style APPEAR in the
picker and never activates it. So the copy shipped a file that governed nothing
while reading as though it governed the session. A repo-wide documentation audit
had already seen the nesting and excused it in writing as "not drift".

THREE ARMS, all failing.

  (1) PLACEMENT -- an `output-styles/` directory whose parent is not a plugin
      root. This is the arm that catches the original defect. Discovery walks
      the REPO ROOT, not each plugin in turn: a register re-created one level
      OUT -- at the repo root, or under `docs/` or a top-level `assets/` -- has
      no plugin-root parent at all, and a per-plugin walk cannot see it. That
      is the same silent non-discovery the arm exists to end, so scoping the
      walk to plugin interiors would have shipped the arm already blind to it.

  (2) FRONTMATTER -- a style `*.md` missing `name:` or `description:`, or
      carrying either with an EMPTY value. Both are what the picker renders; a
      style without them is discovered and unusable, and a null value renders a
      blank row, which is the same end state by a quieter route. Parsed from
      the leading `---` block only, never file-wide: the body of a register
      routinely quotes frontmatter keys when documenting the format, and a
      file-wide scan reads those as satisfying the requirement.

      The parser tolerates what a real YAML loader tolerates, because a false
      positive here has no escape -- this guard ships no allowlist and no skip
      marker, so the only exits from one are rewriting a valid file or
      weakening the guard. A leading BOM is stripped before the fence test (a
      Windows editor or a PowerShell redirect adds one, and `utf-8` decoding
      does not remove it), and `name : value` and `"name": value` are accepted
      because pyyaml accepts them.

  (3) IN-PLUGIN RESOLUTION -- a `$CLAUDE_PLUGIN_ROOT/<path>` reference inside a
      style whose target does not exist in that style's OWN plugin. The variable
      resolves to the OWNING plugin, so this is the mechanical form of the rule
      that a style cannot be relocated to another plugin without orphaning what
      it points at. Detection requires the token in a CODE SPAN: `$CLAUDE_PLUGIN_ROOT`
      appears in running prose across this repo when the convention itself is
      being discussed, and matching prose would report every such sentence.

      The span is located FIRST and the token searched inside it, rather than
      matched by one regex anchored on both backticks. The anchored form reads
      as equivalent and is not: it cannot match a span carrying a command word
      or an argument (`bash $CLAUDE_PLUGIN_ROOT/scripts/x.sh --json`), which is
      15% of this repo's `CLAUDE_PLUGIN_ROOT` code spans -- and because a
      skipped span is not counted, the arm reports the same `refs_checked` as
      if the reference were absent. Resolution then rejects a target escaping
      the plugin via `..`, which is the cross-plugin reference this arm names
      as its own subject and which a bare existence test resolves and passes.

WHY NO CROSS-PLUGIN ARM. `$COGNI_WORKSPACE_PLUGIN` is the sanctioned way for a
plugin's REFERENCE to read cogni-workspace's canonical register, and it is
deliberately not checked here: it resolves from generated workspace settings
that do not exist in a repo checkout, so any assertion about its target would
grade the developer's machine rather than the tree. Arm (3) is scoped to
`$CLAUDE_PLUGIN_ROOT` precisely because that one IS resolvable from the tree.

SCOPE IS STYLES, NOT REFERENCES. Arm (3) reads `output-styles/**/*.md` only. A
`references/*.md` file carries the same variable far more often and is loaded by
a skill rather than by the host, so its resolution is the plugin's own business.
Widening this arm to `references/` was measured and rejected: it reports the
prose-discussion class this guard is built to avoid.

DOT-PREFIXED DIRECTORIES ARE PRUNED, on both the plugin-root listing and the
placement walk. Stale manifests live under `.claude/worktrees/**` and in plugin
caches, and a workspace that predates this rule keeps a retired copy at
`.claude/output-styles/` -- which the migration text tells the user to KEEP.
Grading those reports violations a contributor cannot fix in this repo.

ZERO DISCOVERY IS A FAILURE (exit 2), not a clean zero -- a glob that stops
matching must not read as a green sweep. The floor counts SCANNED STYLES, not
just directories: an `output-styles/` left behind holding no register (a
deletion that spared the directory, a rename to `.markdown`) satisfies a
directory-only floor while arms 2 and 3 examine nothing. Hard clean zero
otherwise: no baseline, no allowlist, no skip marker, and no per-plugin
exemption.

Stdlib-only. Suite: tests/test_check_output_style_placement.sh
"""

import argparse
import json
import os
import re
import sys

STYLE_DIR = "output-styles"
# A plugin root is a directory holding a plugin manifest. Deriving it from the
# manifest rather than from a `cogni-*` name prefix keeps the guard correct for
# a plugin that does not carry the prefix.
MANIFEST = os.path.join(".claude-plugin", "plugin.json")

# Code spans first, then the token inside one. Two expressions rather than one
# anchored regex: see arm (3) in the module docstring.
CODE_SPAN = re.compile(r"`([^`\n]+)`")
PLUGIN_ROOT_TOKEN = re.compile(r"\$(?:\{CLAUDE_PLUGIN_ROOT\}|CLAUDE_PLUGIN_ROOT)/(\S+)")

# `name : value` and `"name": value` both parse under pyyaml, so both are read
# here. A value that is present but blank is captured as blank, not dropped.
FM_KEY = re.compile(r"""^["']?([A-Za-z][A-Za-z0-9_-]*)["']?[ \t]*:[ \t]*(.*)$""")


def repo_root_default():
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.dirname(here)


def walk_pruned(top):
    """os.walk with dot-prefixed directories pruned and symlink cycles broken.

    followlinks is on because Claude Code resolves a symlinked `output-styles/`
    and discovers what is behind it; a guard that declines to follow grades a
    different tree than the host reads.
    """
    seen = set()
    for dirpath, dirnames, filenames in os.walk(top, followlinks=True):
        real = os.path.realpath(dirpath)
        if real in seen:
            dirnames[:] = []
            continue
        seen.add(real)
        dirnames[:] = sorted(d for d in dirnames if not d.startswith("."))
        yield dirpath, dirnames, filenames


def find_plugin_roots(root):
    """Top-level directories holding a plugin manifest.

    Non-recursive, and dot-prefixed entries are skipped, so stale manifests
    under `.claude/worktrees/**` or a plugin cache never register. Kept in step
    with `discover_plugin_dirs` in check-plugin-inventory.py, which is the same
    listing under a different name.
    """
    out = []
    for name in sorted(os.listdir(root)):
        if name.startswith("."):
            continue
        path = os.path.join(root, name)
        if os.path.isdir(path) and os.path.isfile(os.path.join(path, MANIFEST)):
            out.append(name)
    return out


def frontmatter_pairs(text):
    """(key, value) pairs of the leading --- block. Empty when there is none."""
    text = text.lstrip("﻿")
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return {}
    pairs = {}
    for line in lines[1:]:
        if line.strip() == "---":
            return pairs
        m = FM_KEY.match(line)
        if m:
            pairs.setdefault(m.group(1), m.group(2).strip())
    return {}  # unterminated block -- treat as no frontmatter


def owning_plugin(rel, plugins):
    head = rel.split(os.sep)[0]
    return head if head in plugins else ""


def collect(root):
    findings = []
    plugins = find_plugin_roots(root)
    styles_scanned = 0
    refs_checked = 0

    # Arm 1 -- placement. Walk the whole repo: a stray register outside every
    # plugin is exactly the case a per-plugin walk cannot reach.
    style_dirs = []
    for dirpath, _dirnames, _filenames in walk_pruned(root):
        if os.path.basename(dirpath) != STYLE_DIR:
            continue
        rel = os.path.relpath(dirpath, root)
        style_dirs.append(rel)
        parent = os.path.dirname(rel)
        if parent in plugins:
            continue
        where = "%s/" % parent if parent else "the repository root"
        findings.append({
            "arm": "placement",
            "file": rel,
            "detail": (
                "output-styles/ must sit at the plugin root, not under %s -- Claude "
                "Code discovers it only at the root of a directory holding a plugin "
                "manifest, so this register never reaches the /config picker" % where
            ),
        })

    # Arms 2 and 3 -- per style file, recursively: a register one level deeper
    # inside a compliant directory is skipped by arm 1 (its basename is not
    # `output-styles`) and would otherwise be graded by no arm at all.
    for rel_dir in sorted(style_dirs):
        plugin = owning_plugin(rel_dir, plugins)
        for dirpath, _dirnames, filenames in walk_pruned(os.path.join(root, rel_dir)):
            for fname in sorted(filenames):
                if not fname.lower().endswith(".md"):
                    continue
                abs_path = os.path.join(dirpath, fname)
                rel = os.path.relpath(abs_path, root)
                styles_scanned += 1
                try:
                    with open(abs_path, encoding="utf-8", errors="replace") as fh:
                        text = fh.read()
                except OSError as exc:
                    findings.append({
                        "arm": "frontmatter",
                        "file": rel,
                        "detail": "style file could not be read: %s" % exc,
                    })
                    continue

                pairs = frontmatter_pairs(text)
                for required in ("name", "description"):
                    if required not in pairs:
                        findings.append({
                            "arm": "frontmatter",
                            "file": rel,
                            "detail": (
                                "style frontmatter is missing `%s:` -- the /config "
                                "picker renders it, so the style is discovered but "
                                "unusable" % required
                            ),
                        })
                    elif not pairs[required]:
                        findings.append({
                            "arm": "frontmatter",
                            "file": rel,
                            "detail": (
                                "style frontmatter has `%s:` with an empty value -- "
                                "the /config picker renders a blank row, which is as "
                                "unusable as the missing key" % required
                            ),
                        })

                if not plugin:
                    continue  # arm 1 already reported it; there is no plugin to resolve against
                pdir = os.path.join(root, plugin)
                for span in CODE_SPAN.finditer(text):
                    for m in PLUGIN_ROOT_TOKEN.finditer(span.group(1)):
                        refs_checked += 1
                        target = m.group(1)
                        candidate = os.path.realpath(os.path.join(pdir, target))
                        inside = candidate == os.path.realpath(pdir) or candidate.startswith(
                            os.path.realpath(pdir) + os.sep
                        )
                        if not inside:
                            findings.append({
                                "arm": "resolution",
                                "file": rel,
                                "detail": (
                                    "`$CLAUDE_PLUGIN_ROOT/%s` escapes %s/ -- the variable "
                                    "resolves to the OWNING plugin, so a `..` reference "
                                    "points outside the only tree this style can reach"
                                    % (target, plugin)
                                ),
                            })
                        elif not os.path.exists(candidate):
                            findings.append({
                                "arm": "resolution",
                                "file": rel,
                                "detail": (
                                    "`$CLAUDE_PLUGIN_ROOT/%s` does not resolve inside %s/ "
                                    "-- the variable resolves to the OWNING plugin, so "
                                    "this style cannot reach that file" % (target, plugin)
                                ),
                            })

    summary = {
        "total": len(findings),
        "plugins_discovered": len(plugins),
        "style_dirs_discovered": len(style_dirs),
        "styles_scanned": styles_scanned,
        "plugin_root_refs_checked": refs_checked,
    }
    if not plugins or not style_dirs or not styles_scanned:
        raise RuntimeError(
            "zero discovery: found %d plugin roots, %d output-styles directories and "
            "%d style files. A sweep that matches nothing is a broken glob, not a "
            "clean tree." % (len(plugins), len(style_dirs), styles_scanned)
        )
    return findings, summary


def main(argv=None):
    ap = argparse.ArgumentParser(description="output-style registers live at the plugin root")
    ap.add_argument("--root", help="repo root to check (default: this script's parent)")
    args = ap.parse_args(argv)
    root = os.path.abspath(args.root) if args.root else repo_root_default()

    try:
        findings, summary = collect(root)
    except (RuntimeError, OSError) as exc:
        print(json.dumps({"success": False, "data": {}, "error": str(exc)}, indent=2))
        sys.stderr.write("FAIL: %s\n" % exc)
        return 2

    status = 1 if findings else 0
    print(json.dumps({
        "success": status == 0,
        "data": {"findings": findings, "summary": summary},
        "error": "",
    }, indent=2, ensure_ascii=False))

    if findings:
        for f in findings:
            sys.stderr.write("FAIL: [%s] %s -- %s\n" % (f["arm"], f["file"], f["detail"]))
        sys.stderr.write(
            "\nMove the register to <plugin>/output-styles/, fill in the missing "
            "frontmatter key, or repoint the reference at a file inside its own plugin. "
            "Do not add a skip marker -- this guard has none. A style is never copied "
            "into a workspace and never centralized into another plugin: a copied style "
            "only appears in the picker, and a relocated one orphans everything it "
            "points at.\n"
        )
    return status


if __name__ == "__main__":
    sys.exit(main())
