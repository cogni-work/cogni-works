#!/usr/bin/env python3
"""Derive the text-to-narrative skill's vendored asset set from the narrative skill's tree.

The text-to-narrative skill carries its own copy of every asset the narrative skill
reads at run time — the arc registry, the fifteen arc contracts, the techniques
overview, the language files, the execution brief, the validation rules and the two
scripts — because the narrative skill is slated for retirement and the successor has
to stand alone. The copy is FLAT: the narrative skill nests its contracts two levels
under `references/`, and a verbatim copy of that tree would add one `reference-depth`
finding per directory to the shrink-only skill-spec baseline. Flattening is the
restructure the baseline's own comment names as the way out, so the vendored tree
takes it on the way in.

Flattening changes file names, and the files link to each other by relative path, so
a byte-for-byte copy is not possible. This script is the single statement of every
delta between origin and copy: the file mapping, the relative-path rewrites, and the
handful of prose edits (the registry's directory-structure section, the validation
file's derivative sentence). Nothing else may differ.

Two modes over one derivation:

  --write   derive every vendored file from its origin and write it into the target
            skill (the one-time vendoring, re-runnable);
  default   derive every vendored file and COMPARE it with what the target skill
            holds — the identity check the test suite runs, so the two copies cannot
            drift apart while both skills exist. A vendored file that differs from
            its derivation, a missing vendored file, and an origin arc directory
            with no vendored twin are each a finding.

Envelope: {"success": bool, "data": {...}, "error": str|null}. Exit 0 when every
derived file matches (or was written), 1 on any mismatch, 2 when an input cannot be
read or an expected prose anchor is absent from the origin — an anchor that vanished
upstream means the derivation is stale, and that must surface as an error rather than
as a silently unedited copy.

Stdlib only.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys

ARC_DEFINITION = "arc-definition.md"

# Relative-path rewrites, applied in order to every vendored markdown file.
PATH_RULES = [
    (
        "${CLAUDE_PLUGIN_ROOT}/skills/narrative/references/story-arc/${ARC_ID}/arc-definition.md",
        "${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/references/arc-${ARC_ID}.md",
    ),
    ("${CLAUDE_PLUGIN_ROOT}/skills/narrative/scripts/", "${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/scripts/"),
    ("../../narrative-techniques/techniques-overview.md", "techniques-overview.md"),
    ("../narrative-techniques/techniques-overview.md", "techniques-overview.md"),
    ("../../validation.md", "validation.md"),
    ("../validation.md", "validation.md"),
    ("../arc-registry.md", "arc-registry.md"),
    ("story-arc/{arc-id}/arc-definition.md", "arc-{arc-id}.md"),
    ("{arc-id}/arc-definition.md", "arc-{arc-id}.md"),
    ("language/shared.md", "language-shared.md"),
    ("`shared.md`", "`language-shared.md`"),
    ("`en.md`", "`language-en.md`"),
    ("`de.md`", "`language-de.md`"),
]

# `../corporate-visions/arc-definition.md` and `corporate-visions/arc-definition.md`
ARC_LINK_RE = re.compile(r"(?<![\w/])(?:\.\./)?([a-z][a-z0-9-]*)/arc-definition\.md")

# Prose edits keyed by vendored file name: (exact origin text, replacement). An absent
# anchor is an error (exit 2), never a silent skip.
PROSE_RULES = {
    "arc-registry.md": [
        (
            "The selection contract for the `narrative` skill:",
            "The selection contract for the `text-to-narrative` skill:",
        ),
        (
            "Each arc is one contract file:\n"
            "\n"
            "```\n"
            "story-arc/{arc-id}/\n"
            "└── arc-definition.md          # v2 contract: Intent, Selection, Headings, Composition, Elements, Validation, See Also\n"
            "```\n",
            "Each arc is one contract file, flat beside this registry:\n"
            "\n"
            "```\n"
            "references/\n"
            "├── arc-registry.md            # this file\n"
            "└── arc-{arc-id}.md            # v2 contract: Intent, Selection, Headings, Composition, Elements, Validation, See Also\n"
            "```\n",
        ),
        (
            "`cogni-workspace/tests/test-arc-contract-shape.sh` enforces the shape for every arc directory it finds; "
            "its `UNMIGRATED` ratchet is empty and can only stay so — an arc directory carrying anything other than a "
            "`contract: 2` file turns the suite red.",
            "The tree is flat on purpose: a directory nested under `references/` is a skill-spec finding, and the "
            "narrative skill's nested tree is what this copy flattened. While the narrative skill still exists, "
            "`cogni-workspace/scripts/flatten-narrative-assets.py` derives every file here from its origin and "
            "`cogni-workspace/tests/test-text-to-narrative-brief.sh` fails when a vendored file drifts from that derivation.",
        ),
        (
            "2. Create `arc-{arc-id}.md` on the v2 contract shape — copy a migrated contract such as "
            "`arc-corporate-visions.md` and replace every section.",
            "2. Create `arc-{arc-id}.md` on the v2 contract shape — copy a contract such as "
            "`arc-corporate-visions.md` and replace every section. While the narrative skill exists, add the arc "
            "there first and re-run `cogni-workspace/scripts/flatten-narrative-assets.py --write`; the vendored copy is derived, never hand-edited.",
        ),
        (
            "6. Update the arc list in `SKILL.md`'s frontmatter description and every prose surface that states an arc count.\n"
            "7. Run `bash cogni-workspace/tests/test-arc-contract-shape.sh` and `bash cogni-workspace/tests/test-arc-taxonomy-sync.sh` "
            "— both enumerate the arc directories at run time, so the new arc is checked with no test edit.",
            "6. Update the arc list in `SKILL.md`'s frontmatter description, its Bundled arcs table and every prose surface that states an arc count.\n"
            "7. Run `bash cogni-workspace/tests/test-text-to-narrative-brief.sh` — its identity and path cases enumerate the "
            "arc files at run time, so the new arc is checked with no test edit.",
        ),
    ],
    "validation.md": [
        (
            "Derivatives: the executive brief keeps the block and renumbers surviving entries from 1; "
            "talking points and the one-pager omit it (`derivative-formats.md`).",
            "The design brief carries the block verbatim (`design-brief-template.md`); this skill produces no other derivative.",
        ),
    ],
}


class DeriveError(Exception):
    pass


def read(path: str) -> str:
    try:
        with open(path, encoding="utf-8") as fh:
            return fh.read()
    except OSError as exc:
        raise DeriveError(f"cannot read {path}: {exc.strerror}") from exc


def rewrite_paths(text: str) -> str:
    for old, new in PATH_RULES:
        text = text.replace(old, new)
    return ARC_LINK_RE.sub(lambda m: f"arc-{m.group(1)}.md", text)


def apply_prose(name: str, text: str) -> str:
    for old, new in PROSE_RULES.get(name, []):
        if old not in text:
            raise DeriveError(f"prose anchor missing in origin of {name}: {old[:60]!r}")
        text = text.replace(old, new, 1)
    return text


def mapping(source: str) -> list[tuple[str, str]]:
    """(origin path, vendored path relative to the target skill), origin tree order."""
    refs = os.path.join(source, "references")
    story_arc = os.path.join(refs, "story-arc")
    if not os.path.isdir(story_arc):
        raise DeriveError(f"no story-arc directory under {refs}")
    pairs: list[tuple[str, str]] = []
    for entry in sorted(os.listdir(story_arc)):
        contract = os.path.join(story_arc, entry, ARC_DEFINITION)
        if os.path.isfile(contract):
            pairs.append((contract, os.path.join("references", f"arc-{entry}.md")))
    if not pairs:
        raise DeriveError(f"no arc contracts found under {story_arc}")
    pairs += [
        (os.path.join(story_arc, "arc-registry.md"), os.path.join("references", "arc-registry.md")),
        (os.path.join(refs, "narrative-techniques", "techniques-overview.md"), os.path.join("references", "techniques-overview.md")),
        (os.path.join(refs, "language", "shared.md"), os.path.join("references", "language-shared.md")),
        (os.path.join(refs, "language", "en.md"), os.path.join("references", "language-en.md")),
        (os.path.join(refs, "language", "de.md"), os.path.join("references", "language-de.md")),
        (os.path.join(refs, "execution-brief.md"), os.path.join("references", "execution-brief.md")),
        (os.path.join(refs, "validation.md"), os.path.join("references", "validation.md")),
        (os.path.join(source, "scripts", "bridge-citations.py"), os.path.join("scripts", "bridge-citations.py")),
        (os.path.join(source, "scripts", "validate-narrative.py"), os.path.join("scripts", "validate-narrative.py")),
    ]
    return pairs


def derive(origin: str, vendored_rel: str) -> str:
    text = read(origin)
    if not vendored_rel.endswith(".md"):
        return text
    name = os.path.basename(vendored_rel)
    # The registry's step 2 is path-rewritten first, so its prose anchor is written in
    # the rewritten form.
    return apply_prose(name, rewrite_paths(text))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--source", required=True, help="the narrative skill directory")
    ap.add_argument("--target", required=True, help="the text-to-narrative skill directory")
    ap.add_argument("--write", action="store_true", help="write the derived files into --target")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    def emit(success: bool, data: dict, error: str | None, code: int) -> int:
        if args.json:
            print(json.dumps({"success": success, "data": data, "error": error}, indent=2, ensure_ascii=False))
        else:
            for line in data.get("findings", []):
                print(line)
            print(f"{'ok' if success else 'FAIL'}: {data.get('matched', 0)} matched, {len(data.get('findings', []))} findings"
                  + (f" — {error}" if error else ""))
        return code

    try:
        pairs = mapping(args.source)
        findings: list[str] = []
        matched = 0
        written = 0
        for origin, rel in pairs:
            expected = derive(origin, rel)
            dest = os.path.join(args.target, rel)
            if args.write:
                os.makedirs(os.path.dirname(dest), exist_ok=True)
                with open(dest, "w", encoding="utf-8") as fh:
                    fh.write(expected)
                written += 1
                continue
            if not os.path.isfile(dest):
                findings.append(f"missing: {rel}")
                continue
            if read(dest) != expected:
                findings.append(f"drift: {rel} differs from its derivation")
                continue
            matched += 1
        # Every vendored arc file must have an origin — a stray copy is drift too.
        vendored_arcs = {
            f for f in os.listdir(os.path.join(args.target, "references"))
            if f.startswith("arc-") and f != "arc-registry.md" and f.endswith(".md")
        } if os.path.isdir(os.path.join(args.target, "references")) else set()
        expected_arcs = {os.path.basename(rel) for _, rel in pairs if os.path.basename(rel).startswith("arc-") and rel != os.path.join("references", "arc-registry.md")}
        for stray in sorted(vendored_arcs - expected_arcs):
            findings.append(f"stray: references/{stray} has no origin arc")
    except DeriveError as exc:
        return emit(False, {"findings": [], "matched": 0}, str(exc), 2)

    data = {"files": len(pairs), "matched": matched, "written": written, "findings": findings}
    if args.write:
        return emit(True, data, None, 0)
    return emit(not findings, data, None if not findings else "vendored copy drifts from its derivation", 1 if findings else 0)


if __name__ == "__main__":
    sys.exit(main())
