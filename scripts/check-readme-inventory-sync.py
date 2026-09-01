#!/usr/bin/env python3
"""check-readme-inventory-sync.py — deterministic root-README inventory guard.

Binds every per-plugin **count claim** the repo-root `README.md` makes to a count
computed from the filesystem at run time:

  1. the prose claim in each plugin's paragraph — `... N skills and M agents.`;
  2. that plugin's row in the "Plugins at a glance" table — its Skills and
     Agents cells;
  3. the roll-up sentence under the same table — `**N skills, M agents** across
     the K active plugins.`
  4. the three **bare plugin-count** claims — the lede sentence before the first
     H2, the section intro under "## What the plugins do", and the
     marketplace-manifest comment inside the fenced tree diagram — each bound to
     the size of the live plugin universe.
  5. the two **directory-count** claims inside that same fenced tree diagram —
     the per-plugin guide count and the cross-plugin workflow count — each bound
     to the live `*.md` population of the directory its own line names.

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
No expected count — skills, agents, plugins, guides or workflows — appears
anywhere in this file.

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

**The fence decision is deliberate, not incidental.** Claim 4's three sites do
not share a region, so each one states whether a fenced code block is in or out
rather than leaving it to whichever lines a scan happens to reach. The tree
claim is read **only** inside a fenced block; the lede and intro claims **only**
outside one. Neither half is decorative: without the in-fence rule the tree
claim is unreachable, since its region is a code block under a heading this
guard anchors nothing else on; without the out-of-fence rule an example README
pasted into a fenced block inside the prose section contributes a second match
and the intro site degrades to `plugin-count-ambiguous` instead of a claim.

**The noun discriminates, not the digit.** That same fenced tree carries three
parenthesised counts — plugins, guides and workflows — and two of them can hold
the same digit at once. A `(N <word>)` shape would bind whichever came first and
would redden a plugin-count gate on a workflow-count edit, so each pattern is
anchored on its own literal noun. Every one of the three is now a claim in its
own right rather than a bystander: claim 4 binds `plugins` to the plugin
universe, claim 5 binds `guides` and `workflows` to their own directories. The
rule that keeps them apart is unchanged and is now three-way load-bearing — a
future line added inside that fence with a coincidental digit is excluded by
construction rather than by luck.

**Claim 5 compares against its own directory, not the plugin universe.** The
guides count and the plugin count coincide whenever every plugin has a guide, so
grading a guides claim against `len(counts)` would pass on that coincidence and
misattribute on the day it breaks — a finding naming the wrong subject is worse
than none, because it sends the reader at the wrong edit. Each claim-5 site
therefore carries its own backing directory in its spec row and is compared
against a live listing of it. When that directory is absent the site reports
`dir-basis-missing` rather than a mismatch against a live count of zero: an
absent basis un-binds the claim, and reporting "the directory holds 0" would let
a `(0 guides)` claim pass green against a directory that does not exist.

**Claim 4 compares against the same universe claim 3 does.** Both read
`len(counts)` — the plugins the manifest lists *and* whose `source` normalises
to a directory this guard can count — never `len(plugins)`. The two can diverge
the day a manifest entry carries an unusable `source`, and two arms asserting
over one quantity from two different bases would contradict each other on
exactly that day, for a reason no reader of either message could see.

**Absence is a violation, per site.** Each of claim 4's three sites reports its
own `plugin-count-missing` when its claim cannot be found, and each of claim 5's
two sites its own `dir-count-missing`, so renaming the prose around a claim fails
loudly instead of silently discovering nothing. The
`no-claims-discovered` floor below deliberately keeps its original subject — the
per-plugin and roll-up claims — because a per-site missing violation is already
strictly louder than the floor, and folding these sites into it would stop a
README carrying no claim at all from reporting the floor it exists to report.

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

# The bare plugin-count claims (claim 4). Read as running prose, so the count
# may be separated from the noun by one qualifier word — "8 Apache-2.0 plugins"
# reads the same claim as "8 plugins".
#
# The negative lookbehind is load-bearing rather than defensive: a version-like
# qualifier ends in a digit, so without it "Apache-2.0 plugins" offers its own
# trailing "0" as a count and a claim whose number was *deleted* reads as a
# claim of zero — a mismatch against a live universe instead of the missing
# claim it actually is. Anchoring the digit to a non-word, non-dot, non-hyphen
# boundary refuses that reading whatever the scan order.
BARE_PLUGIN_COUNT_RE = re.compile(
    r"(?<![\w.-])(\d+)\s+(?:[A-Za-z][A-Za-z0-9.+-]*\s+)?plugins\b"
)

# The tree-diagram claim is a parenthesised count in a directory comment. The
# noun is inside the pattern on purpose — see "The noun discriminates" above.
TREE_PLUGIN_COUNT_RE = re.compile(r"\((\d+)\s+plugins\)")

# The two directory-count claims share that shape and that reasoning; each names
# its own noun for the same reason the plugin pattern names its own. Plural-only
# is deliberate: a singular claim reports `dir-count-missing`, which is loud,
# rather than being matched and bound to a count it does not state.
TREE_GUIDES_COUNT_RE = re.compile(r"\((\d+)\s+guides\)")
TREE_WORKFLOWS_COUNT_RE = re.compile(r"\((\d+)\s+workflows\)")

FENCE_RE = re.compile(r"^\s*```")

# Each site declares its region kind, its pattern and its fence polarity in one
# row, and the roster the comparison loop walks is derived from the same rows.
# Stating the roster twice is what would let a fourth site be collected and
# reported while never being compared against anything — a claim that looks
# bound and asserts nothing, which is the failure class this whole guard exists
# to remove.
PLUGIN_COUNT_SPEC = (
    ("lede", "before-first-h2", BARE_PLUGIN_COUNT_RE, False),
    ("intro", "prose-section", BARE_PLUGIN_COUNT_RE, False),
    ("tree", "whole-file", TREE_PLUGIN_COUNT_RE, True),
)

PLUGIN_COUNT_SITES = tuple(spec[0] for spec in PLUGIN_COUNT_SPEC)

# Claim 5's rows carry one field the bare arm's do not — the repo-relative
# directory the site's claim is bound to. Both the roster the comparison loop
# walks and the basis it compares against are derived from these same rows, for
# the reason stated above: a roster stated twice is what lets a site be collected
# and reported while asserting nothing.
DIR_COUNT_SPEC = (
    ("tree-guides", "whole-file", TREE_GUIDES_COUNT_RE, True,
     os.path.join("docs", "plugin-guide")),
    ("tree-workflows", "whole-file", TREE_WORKFLOWS_COUNT_RE, True,
     os.path.join("docs", "workflows")),
)

# No `_SITES` twin of PLUGIN_COUNT_SITES here on purpose: the comparison loop
# below iterates these rows directly, so it needs the basis alongside the site
# and a derived roster would be a second copy rather than the single source the
# comment above requires. A positional `spec[4]` lookup would also rebind
# silently to the wrong column the day a field is inserted mid-row.


def read_marketplace(root):
    """Return plugins[] from the repo marketplace manifest.

    Deliberately duplicated in every guard here that reads the manifest, since
    no guard in this directory imports another. If the manifest's shape ever
    changes, each copy needs the fix. Deliberately not counted: a stated number
    of copies goes stale the next time a guard is added, which is the drift this
    file exists to catch elsewhere.
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
    return (start, next_h2(lines, start))


def next_h2(lines, start):
    """Index of the first H2 at or after `start`, else len(lines).

    Both boundary rules in this file resolve through here: where an anchored
    section ends, and where the lede region — which has no heading of its own —
    stops. Falling off to len(lines) means an unterminated section runs to the
    end of the file, which is what the text does too.
    """
    for i in range(start, len(lines)):
        if HEADING_RE.match(lines[i]):
            return i
    return len(lines)


def fence_flags(lines):
    """Return a per-line list of bools: True when the line is inside a fence.

    The delimiter lines themselves are outside. An unterminated fence leaves
    every line after it flagged inside, which is the honest reading — the
    remaining text really is inside an open code block.
    """
    flags = []
    inside = False
    for line in lines:
        if FENCE_RE.match(line):
            flags.append(False)
            inside = not inside
        else:
            flags.append(inside)
    return flags


def count_region(kind, lines, prose_bounds):
    """Resolve a site's region kind to the line indices it covers.

    Each kind is a boundary rule, not a hand-shaped scope: `before-first-h2`
    stops where the first heading starts, `prose-section` is the anchored
    section's own body, and `whole-file` is every line (the fence polarity is
    what narrows it). An absent anchoring section yields an empty region, so the
    site reports as missing through the ordinary path rather than needing a
    branch of its own — the `section-missing` for that heading is already
    emitted once by the caller, and a second one would double-report it.

    The lede region degrades honestly rather than gracefully: demote every H2 in
    the file and it widens to the whole README, which then carries several bare
    counts and the site reports `plugin-count-ambiguous`. That is a loud
    failure, not a discovered claim — the point is that no shape of this region
    is silently empty.
    """
    if kind == "before-first-h2":
        return range(0, next_h2(lines, 0))
    if kind == "prose-section":
        return range(*prose_bounds) if prose_bounds is not None else range(0)
    return range(0, len(lines))


def collect_plugin_counts(lines, prose_bounds, violations):
    """Bare plugin-count claims (claim 4), keyed by site.

    Returns `(claims, unusable)` — the sites whose claim resolved, and the sites
    that carried more than one candidate. Two numbers in one region cannot both
    be the claim, so an ambiguous site yields no claim and a
    `plugin-count-ambiguous` violation instead of binding whichever the scan
    reached first. It is reported separately from a missing site because the two
    call for opposite fixes: one region has too many candidates, the other none.
    """
    claims = {}
    unusable = set()
    fenced = fence_flags(lines)

    for site, kind, pattern, want_fenced in PLUGIN_COUNT_SPEC:
        found = []
        for idx in count_region(kind, lines, prose_bounds):
            if fenced[idx] != want_fenced:
                continue
            match = pattern.search(lines[idx])
            if match:
                found.append((int(match.group(1)), idx + 1))
        if not found:
            continue
        if len(found) > 1:
            unusable.add(site)
            violations.append({
                "code": "plugin-count-ambiguous",
                "plugin": None,
                "site": site,
                "line": found[0][1],
                "detail": "the {} region carries {} plugin-count phrases; cannot "
                          "tell which is the claim".format(site, len(found)),
            })
            continue
        claims[site] = {"count": found[0][0], "line": found[0][1]}
    return claims, unusable


def live_dir_count(absdir):
    """Live `*.md` population of one documented directory.

    The basis for a claim-5 site. It reads a directory listing rather than a
    manifest because the claim names a directory: binding it to anything else
    would assert over a quantity its own line does not state. It takes the
    resolved directory rather than `(root, reldir)` so its caller, which must
    already test that path for existence, joins it once.
    """
    return len(glob.glob(os.path.join(absdir, "*.md")))


def collect_dir_counts(lines, prose_bounds, violations):
    """Directory-count claims (claim 5), keyed by site.

    The claim-4 collector's twin. The finding half genuinely is the same
    algorithm, so a shared collector parameterised by spec and code prefix is a
    live alternative; it is not taken here because the two arms' spec rows carry
    different arities and each arm's ambiguity message names its own claim
    vocabulary, and collapsing them would trade both for one fewer copy. The
    ambiguity RULE is what must not drift between them: a site with two
    candidates yields no claim in either arm, and a change to one is a change
    owed to the other. Returns `(claims, unusable)` on the same contract — two
    numbers in one region cannot both be the claim, so an ambiguous site yields
    no claim and a `dir-count-ambiguous` violation instead of binding whichever
    the scan reached first.
    """
    claims = {}
    unusable = set()
    fenced = fence_flags(lines)

    for site, kind, pattern, want_fenced, _reldir in DIR_COUNT_SPEC:
        found = []
        for idx in count_region(kind, lines, prose_bounds):
            if fenced[idx] != want_fenced:
                continue
            match = pattern.search(lines[idx])
            if match:
                found.append((int(match.group(1)), idx + 1))
        if not found:
            continue
        if len(found) > 1:
            unusable.add(site)
            violations.append({
                "code": "dir-count-ambiguous",
                "plugin": None,
                "site": site,
                "line": found[0][1],
                "detail": "the {} region carries {} matching count phrases; cannot "
                          "tell which is the claim".format(site, len(found)),
            })
            continue
        claims[site] = {"count": found[0][0], "line": found[0][1]}
    return claims, unusable


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

    plugin_counts, unusable_sites = collect_plugin_counts(
        lines, prose_bounds, violations)
    for site in PLUGIN_COUNT_SITES:
        claim = plugin_counts.get(site)
        if claim is None:
            if site in unusable_sites:
                # Already reported as ambiguous. Adding "missing" on top would
                # send the reader at the opposite fix — restore a claim that is
                # in fact there twice.
                continue
            violations.append({
                "code": "plugin-count-missing",
                "plugin": None,
                "site": site,
                "line": None,
                "detail": "no plugin-count claim found at the {} site".format(site),
            })
            continue
        if claim["count"] != len(counts):
            violations.append({
                "code": "plugin-count-mismatch",
                "plugin": None,
                "site": site,
                "line": claim["line"],
                "detail": "{} claims {} plugins but the marketplace universe holds "
                          "{}".format(site, claim["count"], len(counts)),
            })

    dir_counts, unusable_dirs = collect_dir_counts(
        lines, prose_bounds, violations)
    live_dir_counts = {}
    for site, _kind, _pattern, _want_fenced, reldir in DIR_COUNT_SPEC:
        claim = dir_counts.get(site)
        if claim is None:
            if site in unusable_dirs:
                # Suppressed for the same reason the bare arm suppresses its
                # own: "missing" on top of "ambiguous" sends the reader at the
                # opposite fix — restore a claim that is in fact there twice.
                continue
            violations.append({
                "code": "dir-count-missing",
                "plugin": None,
                "site": site,
                "line": None,
                "detail": "no directory-count claim found at the {} site".format(site),
            })
            continue
        absdir = os.path.join(root, reldir)
        if not os.path.isdir(absdir):
            # The basis, not the claim, is what is gone. Falling through to the
            # comparison would grade the claim against a live count of zero,
            # which passes a `(0 ...)` claim against a directory that does not
            # exist and misreports every other claim as a drift.
            violations.append({
                "code": "dir-basis-missing",
                "plugin": None,
                "site": site,
                "line": claim["line"],
                "detail": "the {} claim is bound to {}, which does not exist; the "
                          "claim asserts nothing until it does".format(site, reldir),
            })
            continue
        live_dir = live_dir_count(absdir)
        live_dir_counts[site] = live_dir
        if claim["count"] != live_dir:
            violations.append({
                "code": "dir-count-mismatch",
                "plugin": None,
                "site": site,
                "line": claim["line"],
                "detail": "{} claims {} but {} holds {}".format(
                    site, claim["count"], reldir, live_dir),
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
        "plugin_count_claims": plugin_counts,
        "dir_count_claims": dir_counts,
        "live_counts": counts,
        "live_dir_counts": live_dir_counts,
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
            # A plugin-count violation names no plugin; its subject is the site.
            subject = v["plugin"] or v.get("site") or "-"
            print("  [{}] {}  ({})".format(v["code"], subject, v["detail"]),
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
              "markdown link. A `plugin-count-mismatch`, `plugin-count-missing` or "
              "`plugin-count-ambiguous` finding is the separate bare-plugin-count "
              "binding: its subject is the claim site (`lede`, `intro` or `tree`) "
              "rather than a plugin, so the finding already names which of the three "
              "drifted — a plugin added or removed must sweep all three alongside the "
              "roll-up, and a `missing` finding means that site's prose was renamed "
              "rather than its number changed. A `dir-count-mismatch`, "
              "`dir-count-missing`, `dir-count-ambiguous` or `dir-basis-missing` "
              "finding is the directory-count binding over the other two counts in "
              "that same fenced tree: its subject is the claim site (`tree-guides` "
              "or `tree-workflows`) and its basis is a listing of the `docs/` "
              "directory that site's own line names, never the plugin universe. "
              "`dir-count-missing` means the claim line was renamed or removed; "
              "`dir-basis-missing` means the backing directory itself is gone, so "
              "the claim is un-bound rather than merely wrong.",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
