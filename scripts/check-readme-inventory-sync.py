#!/usr/bin/env python3
"""check-readme-inventory-sync.py — deterministic root-README inventory guard.

Binds every per-plugin **count claim** the repo-root `README.md` makes to a count
computed from the filesystem at run time:

  1. the prose claim in each plugin's paragraph — `... N skills and M agents.`;
  2. that plugin's row in the "Plugins at a glance" table — its Skills and
     Agents cells;
  3. the roll-up sentence under the same table — `**N skills, M agents** across
     the K active plugins.`

The motivating defect: a plugin's skill was retired and the root README's count
claim was not swept with it, in three linked places at once, with nothing in CI
reporting it. The plugin's own README was corrected; the root's duplicate of the
same number was not, because nothing bound it. Every future retirement would
re-drift it the same silent way.

Why a structural binding rather than a banned-string grep: a "never say 25"
grep encodes one historical retirement, needs a hand-maintained list of stale
values, and says nothing about the next skill added or removed. Binding the
claim to a live directory count is a durable invariant — it catches this failure
class and every future one, in both directions, without being told any numbers.
No expected count appears anywhere in this file.

**Subject is the root README alone.** Per-plugin `*/README.md` files are never
opened. They carry their own counts, owned by their own plugin; asserting over
both from here would put two guards on one claim and none on the other.

**Claims are read only inside their anchoring H2 section**, never file-wide.
That is load-bearing rather than tidy: the README carries a second pipe table
elsewhere whose cells are prose and whose rows link plugins. It does not parse as
a claim today only because its first cell happens to be unlinked — a one-line
formatting edit away from making a file-wide scan report violations on a change
that has nothing to do with counts. Scoping to the section removes that class
structurally instead of depending on current content. A renamed or deleted
anchor heading is a `section-missing` violation, so the scoping fails loudly
rather than silently discovering nothing.

**Rows are keyed by the plugin name extracted from each row's link text, never
by position**, and the Skills/Agents cells are located from the table's own
header row for the same reason. The table's row order and the marketplace
manifest's `plugins[]` order genuinely differ, so positional row keying would
mis-attribute today; the column set is not stable either, so a fixed cell offset
would read the wrong column the day one moves.

**This README is a generated artifact, which is what makes the anchors above
sound and is also this guard's one external dependency.** It is reassembled
section-by-section by a documentation generator that lives in another
repository, so the two H2 headings are that generator's own canonical section
names — the most stable strings in the file, since renaming one means editing a
template elsewhere. The same coupling cuts the other way: the generator's
authoring guidance tells writers to use skill/agent counts sparingly and prefer
outcome language, so a regeneration that follows it and drops a plugin's count
sentence lands here as `prose-claim-missing`. That is the guard working — the
claim is gone, not merely wrong — but the fix is to teach the generator to emit
counts derived from the same directories this guard reads, not to loosen the
guard. It already computes them and does not emit them.

stdlib only; runs under any python3. Exit 0 = clean, 1 = violations,
2 = script error.
"""

import argparse
import glob
import json
import os
import re
import sys

README_REL = "README.md"
MARKETPLACE = os.path.join(".claude-plugin", "marketplace.json")

PROSE_SECTION = "## What the plugins do"
TABLE_SECTION = "## Plugins at a glance"

# Anchored on the whole sentence-final phrase, so a mid-sentence mention such as
# "21 skills handle the full positioning lifecycle" is not a claim. Both nouns
# are optionally singular: one plugin ships exactly one skill today, and a
# one-agent plugin would read "and 1 agent." tomorrow.
PROSE_RE = re.compile(r"(\d+)\s+skills?\s+and\s+(\d+)\s+agents?\.")

# A claim line opens with the plugin's own markdown link, whose text is the
# marketplace plugin name.
PROSE_OWNER_RE = re.compile(r"^\[(?P<name>[A-Za-z0-9._-]+)\]\(")
TABLE_OWNER_RE = re.compile(r"^\|\s*\[(?P<name>[A-Za-z0-9._-]+)\]\([^)]*\)\s*\|")

# The header row names the columns, so the Skills and Agents cells are resolved
# from it rather than pinned to fixed offsets. The table's own column set is not
# stable — the generator that reassembles this README carries a different one —
# so a fixed index would silently read the wrong cell the day a column moves.
TABLE_SKILLS_HEADER = "Skills"
TABLE_AGENTS_HEADER = "Agents"

ROLLUP_RE = re.compile(
    r"\*\*(\d+)\s+skills,\s+(\d+)\s+agents\*\*"
    r"(?:\s+across the (\d+) active plugins)?"
)

HEADING_RE = re.compile(r"^## ")


def read_marketplace(root):
    """Return plugins[] from the repo marketplace manifest.

    The same reader `check-plugin-inventory.py` carries; the two are deliberate
    copies, since no guard in this directory imports another. If the manifest's
    shape ever changes, both need the fix.
    """
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


def source_to_dirname(source):
    """Normalise a plugins[].source value to a top-level directory name.

    Returns None for anything that is not a plain relative path into this repo,
    matching the normalisation `check-plugin-inventory.py` applies.
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


def live_counts(root, plugins):
    """Map plugin name -> {'skills': n, 'agents': n}, counted from disk.

    A plugin with no `skills/` or no `agents/` directory counts 0 there. That is
    a legitimate shape, not an error: the claim it is compared against is still
    a number, and a future plugin shipping only skills must not break CI.
    """
    counts = {}
    for entry in plugins:
        if not isinstance(entry, dict):
            continue
        name = entry.get("name")
        dirname = source_to_dirname(entry.get("source"))
        if not name or dirname is None:
            continue
        counts[name] = {
            "skills": len(glob.glob(os.path.join(root, dirname, "skills", "*", "SKILL.md"))),
            "agents": len(glob.glob(os.path.join(root, dirname, "agents", "*.md"))),
        }
    return counts


def section_bounds(lines, heading):
    """Return (start, end) 0-based line indices for an H2 section's body.

    `start` is the line after the heading; `end` is the index of the next H2 (or
    len(lines)). Returns None when the heading is absent.
    """
    start = None
    for i, line in enumerate(lines):
        if line.rstrip() == heading:
            start = i + 1
            break
    if start is None:
        return None
    for j in range(start, len(lines)):
        if HEADING_RE.match(lines[j]):
            return (start, j)
    return (start, len(lines))


def collect_prose(lines, bounds, known, violations):
    """Per-plugin prose claims inside the prose section."""
    claims = {}
    if bounds is None:
        return claims
    for idx in range(*bounds):
        line = lines[idx]
        owner = PROSE_OWNER_RE.match(line)
        if not owner:
            continue
        name = owner.group("name")
        found = PROSE_RE.findall(line)
        if not found:
            continue
        if name not in known:
            violations.append({
                "code": "claim-unknown-plugin",
                "plugin": name,
                "line": idx + 1,
                "detail": "prose claim names a plugin the marketplace does not list",
            })
            continue
        if len(found) > 1:
            violations.append({
                "code": "prose-claim-ambiguous",
                "plugin": name,
                "line": idx + 1,
                "detail": "line carries {} count phrases; cannot tell which is the "
                          "claim".format(len(found)),
            })
            continue
        claims[name] = {"skills": int(found[0][0]), "agents": int(found[0][1]),
                        "line": idx + 1}
    return claims


def table_columns(lines, bounds):
    """Resolve (skills_index, agents_index) from the glance table's header row.

    Returns None when no header row inside the section names both columns. The
    indices are into `line.split("|")` on the raw line, so they line up with the
    data rows without re-deriving an offset.
    """
    if bounds is None:
        return None
    for idx in range(*bounds):
        line = lines[idx]
        if not line.lstrip().startswith("|"):
            continue
        cells = [c.strip() for c in line.rstrip("\n").split("|")]
        if TABLE_SKILLS_HEADER in cells and TABLE_AGENTS_HEADER in cells:
            return (cells.index(TABLE_SKILLS_HEADER), cells.index(TABLE_AGENTS_HEADER))
    return None


def collect_table(lines, bounds, known, violations, columns):
    """Per-plugin table claims inside the glance-table section."""
    claims = {}
    if bounds is None:
        return claims
    if columns is None:
        violations.append({
            "code": "table-header-unrecognized",
            "plugin": None,
            "line": None,
            "detail": "no header row inside {!r} names both a {!r} and an {!r} column; "
                      "the count cells cannot be located".format(
                          TABLE_SECTION, TABLE_SKILLS_HEADER, TABLE_AGENTS_HEADER),
        })
        return claims
    skills_col, agents_col = columns
    for idx in range(*bounds):
        line = lines[idx]
        owner = TABLE_OWNER_RE.match(line)
        if not owner:
            continue
        name = owner.group("name")
        # Split the RAW line so the indices resolved from the header row apply
        # unchanged: split("|")[0] and [-1] are the empty strings either side of
        # the leading and trailing pipe, and the header was split the same way.
        if name not in known:
            violations.append({
                "code": "claim-unknown-plugin",
                "plugin": name,
                "line": idx + 1,
                "detail": "table row names a plugin the marketplace does not list",
            })
            continue
        parts = line.rstrip("\n").split("|")
        if len(parts) <= max(skills_col, agents_col):
            violations.append({
                "code": "table-cell-unparsable",
                "plugin": name,
                "line": idx + 1,
                "detail": "row has {} pipe-delimited fields; the header places the "
                          "count columns at {} and {}".format(
                              len(parts), skills_col, agents_col),
            })
            continue
        try:
            skills = int(parts[skills_col].strip())
            agents = int(parts[agents_col].strip())
        except ValueError:
            violations.append({
                "code": "table-cell-unparsable",
                "plugin": name,
                "line": idx + 1,
                "detail": "cells under {!r} / {!r} are not integers: {!r} / {!r}".format(
                    TABLE_SKILLS_HEADER, TABLE_AGENTS_HEADER,
                    parts[skills_col].strip(), parts[agents_col].strip()),
            })
            continue
        claims[name] = {"skills": skills, "agents": agents, "line": idx + 1}
    return claims


def collect(root):
    """Return (violations, data) for the root-README inventory binding."""
    readme = os.path.join(root, README_REL)
    if not os.path.isfile(readme):
        raise RuntimeError("root README not found: {}".format(README_REL))
    try:
        with open(readme, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
    except OSError as exc:
        raise RuntimeError("root README is unreadable: {}".format(exc))

    plugins = read_marketplace(root)
    counts = live_counts(root, plugins)
    known = set(counts)
    violations = []

    prose_bounds = section_bounds(lines, PROSE_SECTION)
    table_bounds = section_bounds(lines, TABLE_SECTION)
    for heading, bounds in ((PROSE_SECTION, prose_bounds), (TABLE_SECTION, table_bounds)):
        if bounds is None:
            violations.append({
                "code": "section-missing",
                "plugin": None,
                "line": None,
                "detail": "anchoring heading {!r} is absent; claims under it cannot be "
                          "discovered".format(heading),
            })

    prose = collect_prose(lines, prose_bounds, known, violations)
    table = collect_table(lines, table_bounds, known, violations,
                          table_columns(lines, table_bounds))

    for name in sorted(known):
        live = counts[name]
        for kind, claims in (("prose", prose), ("table", table)):
            claim = claims.get(name)
            if claim is None:
                violations.append({
                    "code": "{}-claim-missing".format(kind),
                    "plugin": name,
                    "line": None,
                    "detail": "no {} count claim found for this plugin".format(kind),
                })
                continue
            for field in ("skills", "agents"):
                if claim[field] != live[field]:
                    violations.append({
                        "code": "{}-count-mismatch".format(kind),
                        "plugin": name,
                        "line": claim["line"],
                        "detail": "{} claims {} {} but the directory holds {}".format(
                            kind, claim[field], field, live[field]),
                    })

    rollup_present = False
    if table_bounds is not None:
        for idx in range(*table_bounds):
            match = ROLLUP_RE.search(lines[idx])
            if not match:
                continue
            rollup_present = True
            live_skills = sum(c["skills"] for c in counts.values())
            live_agents = sum(c["agents"] for c in counts.values())
            for claimed, live_total, field in (
                (int(match.group(1)), live_skills, "skills"),
                (int(match.group(2)), live_agents, "agents"),
            ):
                if claimed != live_total:
                    violations.append({
                        "code": "rollup-count-mismatch",
                        "plugin": None,
                        "line": idx + 1,
                        "detail": "roll-up claims {} {} but the directories hold "
                                  "{}".format(claimed, field, live_total),
                    })
            if match.group(3) is not None and int(match.group(3)) != len(counts):
                violations.append({
                    "code": "rollup-plugin-count-mismatch",
                    "plugin": None,
                    "line": idx + 1,
                    "detail": "roll-up claims {} active plugins but the marketplace "
                              "lists {}".format(match.group(3), len(counts)),
                })
            break
        else:
            violations.append({
                "code": "rollup-missing",
                "plugin": None,
                "line": None,
                "detail": "no roll-up total found under {!r}".format(TABLE_SECTION),
            })

    # Zero discovery is a failure, never a clean zero: a guard that found nothing
    # to check must not report the tree as consistent.
    if not prose and not table and not rollup_present:
        violations.append({
            "code": "no-claims-discovered",
            "plugin": None,
            "line": None,
            "detail": "no prose claim, table claim or roll-up was discovered in the "
                      "root README; the guard examined nothing",
        })

    data = {
        "files_scanned": [README_REL],
        "plugins_enumerated": len(counts),
        "prose_claims": len(prose),
        "table_claims": len(table),
        "rollup_present": rollup_present,
        "live_counts": counts,
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
        print("\nFAIL: {} root-README inventory violation(s):".format(len(violations)),
              file=sys.stderr)
        for v in violations:
            print("  [{}] {}  ({})".format(v["code"], v["plugin"] or "-", v["detail"]),
                  file=sys.stderr)
        print("\nFix: every count the root README states is derived from a directory, "
              "not maintained by hand. A skill or agent added or retired must update "
              "the plugin's prose claim, its row in the glance table, and the roll-up "
              "total in the same PR — all three carry the same number, so fixing one "
              "leaves the file contradicting itself. For a `section-missing` or "
              "`no-claims-discovered` finding the claims did not move, the headings "
              "did: restore the anchoring heading or teach this guard the new one. "
              "For `prose-claim-missing` the claim sentence itself is gone or "
              "rephrased — it is matched sentence-finally as `N skills and M agents.`, "
              "singular forms included, on a line opening with that plugin's own "
              "markdown link.",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
