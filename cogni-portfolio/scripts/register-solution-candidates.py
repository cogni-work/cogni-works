#!/usr/bin/env python3
"""Pre-register a Lean-Canvas Solutions block as solution CANDIDATES.

A Lean Canvas (or any offer document) has a "Solution"/"Solutions" block holding
already-decided offerings. Portfolio ingest historically dropped that content, so
the solutions layer started empty and the `solutions` skill fell back to 1:1
generation from propositions. This script carries those offerings forward as
marked candidates into a register that lives OUTSIDE the solutions/ directory —
so `project-status.sh` (which counts solutions/*.json) never mistakes a candidate
for a finished, sellable solution.

Design (option a — a candidate register): candidates are written to
`<project>/research/solution-candidates.json`, mirroring the existing
`research/scan-solutions-draft.json` seed-file precedent. Each candidate carries a
`status` of "candidate", a deterministic `slug` (idempotency key), and a
`product_ref` resolved against the project's products/ when a match exists.

Contract: stdlib-only, emits a single `{"success", "data", "error"}` JSON object
on stdout. An absent or empty Solutions block is a no-op with exit 0 (no register
mutation). Re-running on the same canvas is idempotent: candidates are UPSERTed by
slug (matching records are updated in place, only genuinely new slugs are
appended), never duplicated.

Usage:
  register-solution-candidates.py --project <project-dir> --canvas <canvas-file>
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone

STATUS_CANDIDATE = "candidate"
REGISTER_RELPATH = os.path.join("research", "solution-candidates.json")
REGISTER_VERSION = 1


def _out(success, data=None, error=None, code=0):
    """Emit the canonical envelope and exit."""
    print(json.dumps({"success": success, "data": data, "error": error}))
    sys.exit(code)


def slugify(text):
    """Deterministic kebab-case slug — the register's idempotency key."""
    s = re.sub(r"[^a-z0-9]+", "-", (text or "").strip().lower())
    return s.strip("-")


def _entry_name(entry):
    """Coerce one Solutions-block entry (str or dict) to a display name."""
    if isinstance(entry, str):
        return entry.strip()
    if isinstance(entry, dict):
        for key in ("name", "title", "text", "label", "value", "solution"):
            v = entry.get(key)
            if isinstance(v, str) and v.strip():
                return v.strip()
    return ""


def _norm_key(k):
    return re.sub(r"[^a-z]", "", (k or "").lower())


def _find_solutions_in_obj(obj):
    """Locate a Solutions block inside a parsed JSON canvas.

    Accepts a value keyed (case-insensitively, ignoring punctuation) as
    `solution` or `solutions` at the top level or nested one level under a
    container such as `sections`, `blocks`, or `canvas`. This mapping is the
    single load-bearing line the AC6 mutation check removes.
    """
    if not isinstance(obj, dict):
        return None
    # >>> AC6-MUTATION-TARGET: Solutions-block mapping (mutation-check.sh excises
    # the lines between these two markers to prove the candidate path has teeth).
    for k, v in obj.items():
        if _norm_key(k) in ("solution", "solutions"):
            return v
    # <<< AC6-MUTATION-TARGET
    for container in ("sections", "blocks", "canvas", "lean_canvas", "leancanvas"):
        inner = obj.get(container)
        if isinstance(inner, dict):
            found = _find_solutions_in_obj(inner)
            if found is not None:
                return found
    return None


def _coerce_entries(block):
    """Turn a Solutions block value into a list of entry names."""
    names = []
    if block is None:
        return names
    if isinstance(block, list):
        for item in block:
            n = _entry_name(item)
            if n:
                names.append(n)
    elif isinstance(block, dict):
        for item in block.values():
            n = _entry_name(item)
            if n:
                names.append(n)
    elif isinstance(block, str):
        for line in re.split(r"[\n;]+", block):
            n = re.sub(r"^[\s\-\*•\d\.\)]+", "", line).strip()
            if n:
                names.append(n)
    return names


def _parse_markdown_solutions(text):
    """Extract Solutions-block entries from a markdown canvas.

    Finds a heading matching Solution/Solutions (numbered prefixes like
    "## 4. Solution" allowed) and collects the following list items until the
    next heading.
    """
    names = []
    heading_re = re.compile(r"^#{1,6}\s*(?:\d+[\.\)]\s*)?solutions?\b", re.IGNORECASE)
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        if heading_re.match(lines[i].strip()):
            i += 1
            while i < len(lines):
                stripped = lines[i].strip()
                if stripped.startswith("#"):
                    break  # next heading ends the block
                if stripped:
                    # Strip a leading bullet / numbered-list marker, keep the text.
                    item = re.sub(r"^[\-\*•]\s+", "", stripped)
                    item = re.sub(r"^\d+[\.\)]\s+", "", item).strip()
                    if item:
                        names.append(item)
                i += 1
            break
        i += 1
    return names


def extract_solutions(canvas_path):
    """Read a canvas file and return its Solutions-block entry names.

    Returns [] for a missing file, an absent block, or an empty block — the
    caller treats all three as the same no-op.
    """
    if not canvas_path or not os.path.isfile(canvas_path):
        return []
    with open(canvas_path, "r", encoding="utf-8") as fh:
        raw = fh.read()
    if canvas_path.lower().endswith(".json"):
        try:
            obj = json.loads(raw)
        except (ValueError, json.JSONDecodeError):
            return []
        return _coerce_entries(_find_solutions_in_obj(obj))
    # Markdown / plain text canvas.
    return _parse_markdown_solutions(raw)


def load_products(project_dir):
    """Map product slug/name -> product slug, for candidate resolution."""
    products = {}
    pdir = os.path.join(project_dir, "products")
    if not os.path.isdir(pdir):
        return products
    for fn in sorted(os.listdir(pdir)):
        if not fn.endswith(".json"):
            continue
        try:
            with open(os.path.join(pdir, fn), "r", encoding="utf-8") as fh:
                p = json.load(fh)
        except (ValueError, OSError):
            continue
        slug = p.get("slug") or os.path.splitext(fn)[0]
        products[slug] = {"slug": slug, "name": (p.get("name") or "").strip()}
    return products


def resolve_product(entry_name, entry_slug, products):
    """Best-effort resolve a candidate to an existing product slug, else None."""
    if entry_slug in products:
        return entry_slug
    el = entry_name.lower()
    for slug, p in products.items():
        name = p["name"].lower()
        if name and (name in el or el in name):
            return slug
        if slug and slug in entry_slug:
            return slug
    return None


def load_register(path):
    if not os.path.isfile(path):
        return {"version": REGISTER_VERSION, "candidates": []}
    try:
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)
        if isinstance(data, dict) and isinstance(data.get("candidates"), list):
            data.setdefault("version", REGISTER_VERSION)
            return data
    except (ValueError, OSError):
        pass
    return {"version": REGISTER_VERSION, "candidates": []}


def main():
    ap = argparse.ArgumentParser(description="Register Lean-Canvas Solutions-block entries as solution candidates.")
    ap.add_argument("--project", required=True, help="Portfolio project directory (holds portfolio.json, research/, products/).")
    ap.add_argument("--canvas", required=True, help="Path to the canvas / offer document (markdown or JSON).")
    ap.add_argument("--status", default=STATUS_CANDIDATE, choices=["candidate", "draft"], help="Candidate status marker.")
    args = ap.parse_args()

    project_dir = args.project
    if not os.path.isdir(project_dir):
        _out(False, error="Project directory not found: %s" % project_dir, code=2)

    names = extract_solutions(args.canvas)
    register_path = os.path.join(project_dir, REGISTER_RELPATH)

    # No-op: absent/empty Solutions block. Never create or mutate the register.
    if not names:
        _out(True, data={
            "registered": 0,
            "new": 0,
            "updated": 0,
            "register_path": register_path,
            "candidates": [],
            "noop": True,
        }, code=0)

    products = load_products(project_dir)
    register = load_register(register_path)
    by_slug = {c.get("slug"): c for c in register["candidates"] if isinstance(c, dict) and c.get("slug")}

    source = os.path.basename(args.canvas)
    now = datetime.now(timezone.utc).isoformat()
    new_count = 0
    updated_count = 0
    touched = []

    seen = set()
    for name in names:
        slug = slugify(name)
        if not slug or slug in seen:
            continue  # de-dupe within a single canvas by slug
        seen.add(slug)
        product_ref = resolve_product(name, slug, products)
        if slug in by_slug:
            rec = by_slug[slug]
            rec["name"] = name
            rec["status"] = args.status
            rec["product_ref"] = product_ref
            rec["source"] = source
            rec.setdefault("created", now)  # preserve original creation time
            updated_count += 1
        else:
            rec = {
                "slug": slug,
                "name": name,
                "status": args.status,
                "product_ref": product_ref,
                "source": source,
                "created": now,
            }
            register["candidates"].append(rec)
            by_slug[slug] = rec
            new_count += 1
        touched.append(slug)

    os.makedirs(os.path.dirname(register_path), exist_ok=True)
    with open(register_path, "w", encoding="utf-8") as fh:
        json.dump(register, fh, ensure_ascii=False, indent=2)
        fh.write("\n")

    _out(True, data={
        "registered": len(touched),
        "new": new_count,
        "updated": updated_count,
        "register_path": register_path,
        "candidates": touched,
        "noop": False,
    }, code=0)


if __name__ == "__main__":
    main()
