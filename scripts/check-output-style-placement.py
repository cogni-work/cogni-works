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
      root. This is the arm that catches the original defect.

  (2) FRONTMATTER -- a style `*.md` missing `name:` or `description:`. Both are
      what the picker renders; a style without them is discovered and unusable.
      Parsed from the leading `---` block only, never file-wide: the body of a
      register routinely quotes frontmatter keys when documenting the format,
      and a file-wide scan reads those as satisfying the requirement.

  (3) IN-PLUGIN RESOLUTION -- a `$CLAUDE_PLUGIN_ROOT/<path>` reference inside a
      style whose target does not exist in that style's OWN plugin. The variable
      resolves to the OWNING plugin, so this is the mechanical form of the rule
      that a style cannot be relocated to another plugin without orphaning what
      it points at. Detection requires the token in a CODE SPAN: `$CLAUDE_PLUGIN_ROOT`
      appears in running prose across this repo when the convention itself is
      being discussed, and matching prose would report every such sentence.

WHY NO CROSS-PLUGIN ARM. `$COGNI_WORKSPACE_PLUGIN` is the sanctioned way for a
plugin's REFERENCE to read cogni-workspace's canonical register, and it is
deliberately not checked here: it resolves from generated workspace settings
that do not exist in a repo checkout, so any assertion about its target would
grade the developer's machine rather than the tree. Arm (3) is scoped to
`$CLAUDE_PLUGIN_ROOT` precisely because that one IS resolvable from the tree.

SCOPE IS STYLES, NOT REFERENCES. Arm (3) reads `output-styles/*.md` only. A
`references/*.md` file carries the same variable far more often and is loaded by
a skill rather than by the host, so its resolution is the plugin's own business.
Widening this arm to `references/` was measured and rejected: it reports the
prose-discussion class this guard is built to avoid.

ZERO DISCOVERY IS A FAILURE (exit 2), not a clean zero -- a glob that stops
matching must not read as a green sweep. Hard clean zero otherwise: no baseline,
no allowlist, no skip marker, and no per-plugin exemption.

Stdlib-only. Suite: tests/test_check_output_style_placement.sh
"""

import json
import os
import re
import sys

STYLE_DIR = "output-styles"
# A plugin root is a directory holding a plugin manifest. Deriving it from the
# manifest rather than from a `cogni-*` name prefix keeps the guard correct for
# a plugin that does not carry the prefix.
MANIFEST = os.path.join(".claude-plugin", "plugin.json")

# The token must sit in a backtick code span. Bare prose mentions are the
# false-positive class that would otherwise dominate this arm.
PLUGIN_ROOT_REF = re.compile(r"`\$(?:\{)?CLAUDE_PLUGIN_ROOT(?:\})?/([^`\s]+)`")


def repo_root():
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.dirname(here)


def find_plugin_roots(root):
    out = []
    for name in sorted(os.listdir(root)):
        path = os.path.join(root, name)
        if os.path.isdir(path) and os.path.isfile(os.path.join(path, MANIFEST)):
            out.append(name)
    return out


def frontmatter_keys(text):
    """Keys of the leading --- block. Empty when the file has no frontmatter."""
    if not text.startswith("---"):
        return set()
    lines = text.split("\n")
    keys = set()
    for line in lines[1:]:
        if line.strip() == "---":
            return keys
        m = re.match(r"^([A-Za-z][A-Za-z0-9_-]*):", line)
        if m:
            keys.add(m.group(1))
    return set()  # unterminated block -- treat as no frontmatter


def main():
    root = repo_root()
    findings = []
    plugins = find_plugin_roots(root)
    styles_scanned = 0
    refs_checked = 0

    # Arm 1 -- placement. Walk every plugin for a stray output-styles/ directory.
    style_dirs = []
    for plugin in plugins:
        pdir = os.path.join(root, plugin)
        for dirpath, dirnames, _ in os.walk(pdir):
            if ".git" in dirnames:
                dirnames.remove(".git")
            if os.path.basename(dirpath) != STYLE_DIR:
                continue
            rel = os.path.relpath(dirpath, root)
            style_dirs.append(rel)
            parent = os.path.dirname(rel)
            if parent != plugin:
                findings.append({
                    "arm": "placement",
                    "file": rel,
                    "detail": (
                        "output-styles/ must sit at the plugin root (%s/), not nested "
                        "under %s/ -- Claude Code discovers it only at the root, so a "
                        "nested register never reaches the /config picker"
                        % (plugin, parent)
                    ),
                })

    # Arms 2 and 3 -- per style file.
    for rel_dir in style_dirs:
        plugin = rel_dir.split(os.sep)[0]
        abs_dir = os.path.join(root, rel_dir)
        for fname in sorted(os.listdir(abs_dir)):
            if not fname.endswith(".md"):
                continue
            rel = os.path.join(rel_dir, fname)
            styles_scanned += 1
            with open(os.path.join(abs_dir, fname), encoding="utf-8") as fh:
                text = fh.read()

            keys = frontmatter_keys(text)
            for required in ("name", "description"):
                if required not in keys:
                    findings.append({
                        "arm": "frontmatter",
                        "file": rel,
                        "detail": (
                            "style frontmatter is missing `%s:` -- the /config picker "
                            "renders it, so the style is discovered but unusable"
                            % required
                        ),
                    })

            for m in PLUGIN_ROOT_REF.finditer(text):
                refs_checked += 1
                target = m.group(1).rstrip(".,;:)")
                if not os.path.exists(os.path.join(root, plugin, target)):
                    findings.append({
                        "arm": "resolution",
                        "file": rel,
                        "detail": (
                            "`$CLAUDE_PLUGIN_ROOT/%s` does not resolve inside %s/ -- the "
                            "variable resolves to the OWNING plugin, so this style cannot "
                            "reach that file" % (target, plugin)
                        ),
                    })

    status = 0
    error = ""
    if not plugins or not style_dirs:
        status = 2
        error = (
            "zero discovery: found %d plugin roots and %d output-styles directories. "
            "A sweep that matches nothing is a broken glob, not a clean tree."
            % (len(plugins), len(style_dirs))
        )
    elif findings:
        status = 1

    result = {
        "success": status == 0,
        "data": {
            "findings": findings,
            "summary": {
                "total": len(findings),
                "plugins_discovered": len(plugins),
                "style_dirs_discovered": len(style_dirs),
                "styles_scanned": styles_scanned,
                "plugin_root_refs_checked": refs_checked,
            },
        },
        "error": error,
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if error:
        sys.stderr.write("FAIL: %s\n" % error)
        return 2
    if findings:
        for f in findings:
            sys.stderr.write("FAIL: [%s] %s -- %s\n" % (f["arm"], f["file"], f["detail"]))
        sys.stderr.write(
            "\nMove the register to <plugin>/output-styles/, add the missing frontmatter "
            "key, or repoint the reference at a file inside its own plugin. Do not add a "
            "skip marker -- this guard has none. A style is never copied into a workspace "
            "and never centralized into another plugin: a copied style only appears in the "
            "picker, and a relocated one orphans everything it points at.\n"
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
