#!/usr/bin/env python3
"""
batch_builder.py — enumerate candidate sources and emit a valid wiki-ingest
batch-mode payload on stdout.

The wiki-ingest batch-mode reference doc already describes the schema
`{"sources": [{"source": "...", "title": "...", "type": "...", "tags": [...]}]}`
and the fail-fast validator in Step 0 of the skill. What did not exist before
this script: any way to *produce* that payload without the user (or
Claude-on-behalf-of-the-user) hand-typing it. For the Phase 2 pilot rebuild
(~164 skill+agent pages across a sibling monorepo), hand-typing does not
scale; the skill was effectively half-shipped.

This script is the missing half. It only enumerates — it never writes to the
wiki. That preserves the "review before ingest" discipline: a user can pipe
this to a file, eyeball it, and then pass the file to `wiki-ingest
--batch-file`, or use the skill's `--discover` flag to glue the two calls
together.

Discovery modes (exactly one required):

    --glob PATTERN      Walk the filesystem starting at --root (default: the
                        wiki root, i.e. the parent of .cogni-wiki/) and emit
                        each matching file as a sources[] entry. Supports
                        recursive glob via ** and the standard fnmatch
                        metacharacters. Patterns are resolved relative to
                        --root; absolute patterns are honoured as-is.

    --orphans           Files under <wiki-root>/raw/ that are not referenced
                        by any page's `sources:` frontmatter entry. Mirrors
                        the orphan_raw_count logic in wiki_status.sh but
                        returns the filenames themselves.

    --stubs             Pages under <wiki-root>/wiki/pages/ whose frontmatter
                        has `status: draft`. With --older-than-days N, restrict
                        to drafts whose `updated:` date is more than N days
                        old. Stubs re-enter the wiki via the mode: re-ingest
                        branch of Step 1, which is the intended refresh path.

Filters (compose freely with any discovery mode):

    --exclude-ingested  Drop any source whose derived slug already exists as
                        <wiki-root>/wiki/pages/{slug}.md. Key dedupe for the
                        "ingest everything not yet in the wiki" use case —
                        safe to rerun after partial progress.

    --type TYPE         Apply as the per-entry `type` default (one of:
                        concept, entity, summary, decision, learning, note).
    --tags a,b,c        Apply as the per-entry `tags` default.
    --title-template T  Python-style format string for the per-entry title,
                        derived from the discovered path. Placeholders:
                            {stem}      filename without extension
                            {parent}    immediate parent directory name
                            {parent2}   two directories up
                            {parent3}   three directories up
                            {parts[-N]} any negative index into Path.parts
                        Example: for paths like
                        `../cogni-claims/skills/claim-entity/SKILL.md` in a
                        wiki whose existing slug convention is
                        `skill-cogni-claims-claim-entity`, pass
                        `--title-template 'skill-{parent3}-{parent}'`.
                        When --title-template is set, the derived title is
                        also used by --exclude-ingested for slug comparison.
    --limit N           Cap the emitted sources[] at N entries.

Output contract:

    {
      "success": true,
      "data": {
        "mode": "glob" | "orphans" | "stubs",
        "count": <int>,
        "skipped_existing": <int>,
        "sources": [ { "source": "...", ... }, ... ]
      },
      "error": ""
    }

    On failure: {"success": false, "data": {}, "error": "..."} with exit 1.

Slug derivation matches the skill's rule: lowercase the filename (or the
last URL segment), strip the extension, replace any run of non-[a-z0-9]
characters with a hyphen, trim leading/trailing hyphens. This has to stay in
sync with the SKILL.md Step 1 rule or --exclude-ingested will miss dedupes.

stdlib-only. Python 3.8+.
"""

from __future__ import annotations

import argparse
import datetime as dt
import fnmatch
import json
import os
import re
import sys
from pathlib import Path
from typing import Iterable


VALID_TYPES = {"concept", "entity", "summary", "decision", "learning", "note"}
FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
SLUG_CLEAN_RE = re.compile(r"[^a-z0-9]+")


def fail(msg: str) -> None:
    print(json.dumps({"success": False, "data": {}, "error": msg}))
    sys.exit(1)


def ok(data: dict) -> None:
    print(json.dumps({"success": True, "data": data, "error": ""}))
    sys.exit(0)


def derive_slug(source: str) -> str:
    """Mirror the skill's slug derivation rule.

    The orchestrator in SKILL.md uses the title if given, else the filename
    or URL tail. This script does not know about per-entry titles (they are
    opt-in downstream), so the discovery-time slug is always filename-based.
    That is the right default for --exclude-ingested: if the user later
    overrides the title in the batch file, the dedupe may miss — but the
    re-ingest branch of Step 1 catches it safely.
    """
    tail = source.rstrip("/").split("/")[-1]
    base = tail.rsplit(".", 1)[0] if "." in tail else tail
    slug = SLUG_CLEAN_RE.sub("-", base.lower()).strip("-")
    return slug


def parse_frontmatter(text: str) -> dict:
    """Same shape as lint_wiki.py's parser — keep them structurally aligned."""
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}
    out: dict = {}
    current_key = None
    for line in m.group(1).splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.startswith("  - ") and current_key:
            out.setdefault(current_key, []).append(line[4:].strip())
            continue
        if ":" in line:
            k, _, v = line.partition(":")
            k = k.strip()
            v = v.strip()
            current_key = k
            if v.startswith("[") and v.endswith("]"):
                inside = v[1:-1].strip()
                if not inside:
                    out[k] = []
                else:
                    out[k] = [x.strip() for x in inside.split(",") if x.strip()]
            elif v:
                out[k] = v
            else:
                out[k] = []
    return out


def parse_date(s: str):
    try:
        return dt.datetime.strptime(s.strip(), "%Y-%m-%d").date()
    except (ValueError, AttributeError):
        return None


def find_wiki_root(start: Path) -> Path:
    """Walk up looking for .cogni-wiki/config.json."""
    current = start.resolve()
    while True:
        if (current / ".cogni-wiki" / "config.json").is_file():
            return current
        if current.parent == current:
            fail(f"not inside a cogni-wiki (no .cogni-wiki/config.json at or above {start})")
        current = current.parent


def existing_slugs(wiki_root: Path) -> set:
    pages = wiki_root / "wiki" / "pages"
    if not pages.is_dir():
        return set()
    return {
        p.stem for p in pages.iterdir()
        if p.is_file() and p.suffix == ".md" and not p.name.startswith("lint-")
    }


def discover_glob(pattern: str, root: Path) -> list:
    """Resolve a glob pattern against root. Supports ** recursion via pathlib."""
    if os.path.isabs(pattern):
        base = Path(pattern).anchor
        rel = pattern[len(base):]
        results = list(Path(base).glob(rel))
    else:
        results = list(root.glob(pattern))
    # Stable ordering so reruns produce identical output.
    return sorted(str(p) for p in results if p.is_file())


def discover_orphans(wiki_root: Path) -> list:
    """Files under raw/ that no page cites in its sources: frontmatter."""
    raw_dir = wiki_root / "raw"
    if not raw_dir.is_dir():
        return []
    pages_dir = wiki_root / "wiki" / "pages"
    cited: set = set()
    if pages_dir.is_dir():
        for page in pages_dir.iterdir():
            if not (page.is_file() and page.suffix == ".md"):
                continue
            try:
                text = page.read_text(encoding="utf-8")
            except OSError:
                continue
            fm = parse_frontmatter(text)
            sources = fm.get("sources", [])
            if isinstance(sources, list):
                for s in sources:
                    if not isinstance(s, str):
                        continue
                    # Paths in sources are typically ../raw/foo.pdf — we only
                    # care about the filename tail for orphan detection.
                    cited.add(s.rstrip("/").split("/")[-1])
    orphans = []
    for item in sorted(raw_dir.iterdir()):
        if not item.is_file():
            continue
        if item.name.startswith("."):
            continue
        if item.name not in cited:
            orphans.append(str(item))
    return orphans


def discover_stubs(wiki_root: Path, older_than_days: int | None) -> list:
    """Pages with status: draft (optionally filtered by age)."""
    pages_dir = wiki_root / "wiki" / "pages"
    if not pages_dir.is_dir():
        return []
    today = dt.date.today()
    stubs = []
    for page in sorted(pages_dir.iterdir()):
        if not (page.is_file() and page.suffix == ".md"):
            continue
        if page.name.startswith("lint-"):
            continue
        try:
            text = page.read_text(encoding="utf-8")
        except OSError:
            continue
        fm = parse_frontmatter(text)
        status = fm.get("status", "")
        if not (isinstance(status, str) and status.strip().lower() == "draft"):
            continue
        if older_than_days is not None:
            updated = parse_date(fm.get("updated", "") if isinstance(fm.get("updated"), str) else "")
            if updated is None:
                # No valid updated date — treat as eligible (conservative:
                # a stale draft without a date is exactly what needs rebuild).
                pass
            else:
                age = (today - updated).days
                if age <= older_than_days:
                    continue
        # For stubs, the source pointer is the page itself — re-ingest
        # reads the page's cited source and re-synthesises. But the batch
        # entry still needs a `source:` field. Use the first entry in the
        # page's sources: frontmatter as the ingest input; if none, point
        # at the page path itself as a fallback.
        sources = fm.get("sources", [])
        first_source = None
        if isinstance(sources, list) and sources:
            if isinstance(sources[0], str):
                first_source = sources[0]
        stubs.append({"page": str(page), "source": first_source or str(page), "slug": page.stem})
    return stubs


def render_title(template: str, path_obj: Path) -> str:
    parts = path_obj.parts
    fmt_vars = {
        "stem": path_obj.stem,
        "parent": path_obj.parent.name if len(parts) >= 2 else "",
        "parent2": path_obj.parent.parent.name if len(parts) >= 3 else "",
        "parent3": path_obj.parent.parent.parent.name if len(parts) >= 4 else "",
        "parts": list(parts),
    }
    try:
        return template.format(**fmt_vars)
    except (KeyError, IndexError) as e:
        fail(f"--title-template placeholder error for {path_obj}: {e}")
        return ""  # unreachable, fail() exits


def build_entries_from_paths(
    paths: list,
    default_type: str | None,
    default_tags: list | None,
    title_template: str | None,
    wiki_root: Path,
) -> list:
    entries = []
    for p in paths:
        # Emit paths relative to the wiki root when the file lives under it,
        # otherwise leave absolute — batch-mode.md §"Input schema" treats
        # `source` as a path relative to the wiki root or a URL, and relative
        # paths walking outside the wiki root (e.g., ../cogni-*/skills/...) are
        # explicitly the monorepo discovery case we want to support.
        path_obj = Path(p)
        try:
            rel = path_obj.resolve().relative_to(wiki_root.resolve())
            source = str(rel)
        except ValueError:
            # Outside the wiki root — emit as a relative path from wiki_root
            # so batch-mode's "relative to wiki root" rule still applies.
            try:
                rel = os.path.relpath(path_obj.resolve(), wiki_root.resolve())
                source = rel
            except ValueError:
                source = str(path_obj)
        entry: dict = {"source": source}
        if title_template:
            entry["title"] = render_title(title_template, path_obj)
        if default_type:
            entry["type"] = default_type
        if default_tags:
            entry["tags"] = list(default_tags)
        entries.append(entry)
    return entries


def build_entries_from_stubs(
    stubs: list,
    default_type: str | None,
    default_tags: list | None,
    wiki_root: Path,
) -> list:
    entries = []
    for stub in stubs:
        source = stub["source"]
        # Stub sources: if the frontmatter pointed at "../raw/foo.pdf" we keep
        # it as-is (that is already a wiki-root-relative path). If we fell
        # back to the page path itself, normalise the same way as above.
        if not (source.startswith("http://") or source.startswith("https://") or source.startswith("../") or source.startswith("./")):
            # Looks like an absolute path — make it wiki-root-relative.
            try:
                rel = os.path.relpath(Path(source).resolve(), wiki_root.resolve())
                source = rel
            except ValueError:
                pass
        entry: dict = {"source": source, "title": stub["slug"].replace("-", " ").title()}
        if default_type:
            entry["type"] = default_type
        if default_tags:
            entry["tags"] = list(default_tags)
        entries.append(entry)
    return entries


def apply_exclude_ingested(entries: list, wiki_root: Path) -> tuple:
    slugs = existing_slugs(wiki_root)
    kept = []
    skipped = 0
    for entry in entries:
        slug = derive_slug(entry.get("title") or entry["source"])
        if slug in slugs:
            skipped += 1
            continue
        kept.append(entry)
    return kept, skipped


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Enumerate wiki-ingest batch candidates and emit the sources[] payload on stdout.",
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--glob", help="Filesystem glob pattern (resolved against --root).")
    mode.add_argument("--orphans", action="store_true", help="Files in raw/ not yet in any page's sources: frontmatter.")
    mode.add_argument("--stubs", action="store_true", help="Pages with status: draft.")

    parser.add_argument("--root", help="Walk base for --glob (default: wiki root).")
    parser.add_argument("--wiki-root", help="Override auto-detected wiki root.")
    parser.add_argument("--older-than-days", type=int, default=None, help="For --stubs: filter to drafts older than N days.")
    parser.add_argument("--exclude-ingested", action="store_true", help="Drop sources whose derived slug already has a page.")
    parser.add_argument("--type", dest="default_type", choices=sorted(VALID_TYPES), help="Default per-entry type.")
    parser.add_argument("--tags", help="Default per-entry tags (comma-separated).")
    parser.add_argument("--title-template", dest="title_template", help="Python format-string for per-entry titles. Placeholders: {stem}, {parent}, {parent2}, {parent3}, {parts[-N]}.")
    parser.add_argument("--limit", type=int, default=None, help="Cap sources[] at N entries after filtering.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    if args.wiki_root:
        wiki_root = Path(args.wiki_root).resolve()
        if not (wiki_root / ".cogni-wiki" / "config.json").is_file():
            fail(f"not a cogni-wiki: {wiki_root}/.cogni-wiki/config.json not found")
    else:
        wiki_root = find_wiki_root(Path.cwd())

    default_tags = None
    if args.tags:
        default_tags = [t.strip() for t in args.tags.split(",") if t.strip()]

    if args.glob:
        root = Path(args.root).resolve() if args.root else wiki_root
        if not root.is_dir():
            fail(f"--root is not a directory: {root}")
        paths = discover_glob(args.glob, root)
        entries = build_entries_from_paths(paths, args.default_type, default_tags, args.title_template, wiki_root)
        mode_name = "glob"
    elif args.orphans:
        if args.older_than_days is not None:
            fail("--older-than-days applies only to --stubs")
        paths = discover_orphans(wiki_root)
        entries = build_entries_from_paths(paths, args.default_type, default_tags, args.title_template, wiki_root)
        mode_name = "orphans"
    elif args.stubs:
        stubs = discover_stubs(wiki_root, args.older_than_days)
        entries = build_entries_from_stubs(stubs, args.default_type, default_tags, wiki_root)
        mode_name = "stubs"
    else:  # argparse enforces required mutex group, but keep the guard explicit
        fail("no discovery mode selected")
        return

    skipped_existing = 0
    if args.exclude_ingested:
        entries, skipped_existing = apply_exclude_ingested(entries, wiki_root)

    if args.limit is not None and args.limit >= 0:
        entries = entries[: args.limit]

    ok({
        "mode": mode_name,
        "count": len(entries),
        "skipped_existing": skipped_existing,
        "sources": entries,
    })


if __name__ == "__main__":
    main()
