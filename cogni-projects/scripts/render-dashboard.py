#!/usr/bin/env python3
"""Render a partner-meeting portfolio dashboard from a cogni-projects portfolio.

Reads projects-portfolio.json to confirm the portfolio, then opens and parses
every consultant / project / assignment entity's frontmatter to compute:
  - per-project staffing coverage (open_roles filled vs still open) + a health flag,
  - an aggregate portfolio value summary grouped by strategic_impact (1..5),
  - a simple consultant-utilization aggregate.
Writes a self-contained HTML dashboard to <portfolio-dir>/output/dashboard.html.

Read-only: never writes projects-portfolio.json (register-entity.py is its only
writer) and never appends to .metadata/. Degrades gracefully — a missing or
malformed entity field yields a partial snapshot with a surfaced warning, never
a hard failure, because a partial snapshot is more useful than no snapshot to a
partner reviewing a portfolio that is still being authored.

Stdlib-only (no PyYAML). Reuses validate-entities.py's read_frontmatter and
_entity_files via the shared _projects_lib loader rather than re-implementing a
reader or a directory walk.

Usage:
  python3 render-dashboard.py <portfolio-dir> [--design-variables <path.json>]

Output: a single JSON line following the repo contract
  {"success": bool, "data": {...}, "error": str}
Exit: 0 ok / 2 usage or environment failure.
"""

import argparse
import datetime
import html
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _projects_lib import VALIDATOR_PATH, load_validator  # noqa: E402

# Reusing the validator's parser + entity-file discovery means the dashboard
# reads exactly the shape the validator enforces rather than duplicating (and
# drifting from) those rules. The envelope and exit code stay here: this check
# fires at import time, before argparse, and that timing is part of the contract.
_ve = load_validator()
if _ve is None:
    print(json.dumps({
        "success": False, "data": {},
        "error": "cannot load validator module: %s" % VALIDATOR_PATH,
    }))
    sys.exit(2)


# The built-in palette. The dashboard renders with this whenever no
# --design-variables file is supplied, so the script never depends on
# cogni-workspace:pick-theme; a themed override is a purely optional flag.
DEFAULT_THEME = {
    "theme_name": "cogni-work",
    "bg": "#0f1419",
    "surface": "#1a2028",
    "text": "#e6edf3",
    "muted": "#9aa7b4",
    "accent": "#4f9cf9",
    "ok": "#3fb950",
    "warn": "#d29922",
    "risk": "#f85149",
    "border": "#2d333b",
    "font": "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
}

# The status values that count an assignment as actively covering a role. A
# completed assignment no longer staffs an open role.
ACTIVE_ASSIGNMENT_STATES = ("planned", "active")

# Named so a status *comparison* is distinguishable at a glance from a status
# *label* the renderer prints — "closed" is both, and only the comparison
# depends on _status_text having normalized its input. See _status_text.
PROJECT_STATUS_CLOSED = "closed"
PROJECT_STATUS_ACTIVE = "active"

# Theme values are interpolated into the <style> block rather than into escaped
# text nodes, so a value carrying CSS-structural or markup characters could
# close the stylesheet and inject arbitrary markup into the self-contained HTML.
# Parentheses are denied for a distinct reason: a value like
# `url(https://evil.example/track.png)` is CSS-valid and would interpolate
# verbatim into `background: url(...)`, turning a self-contained partner-meeting
# artifact into one that fetches an external resource (a phone-home beacon) the
# moment it is opened. Rejecting `(` / `)` blocks the url()/@import fetch surface
# alongside the markup-injection one.
# The file is operator-supplied rather than portfolio-derived, so a conservative
# denylist of CSS-structural characters is the proportionate guard: reject and
# fall back rather than attempt to sanitize.
# Single quotes stay legal: a font stack ("'Segoe UI', Roboto") needs them and
# they cannot terminate a <style> block on their own.
_THEME_VALUE_FORBIDDEN = set("<>{}();@\\")
_THEME_VALUE_MAX_LEN = 120


def _valid_theme_value(value):
    """Return True when a theme override is safe to interpolate into <style>."""
    return (
        isinstance(value, str)
        and 0 < len(value) <= _THEME_VALUE_MAX_LEN
        and not (_THEME_VALUE_FORBIDDEN & set(value))
    )


def _load_theme(path):
    """Return the theme dict. Falls back to DEFAULT_THEME on any read problem.

    Theming is a nicety, never a hard dependency: a missing or malformed
    --design-variables file must not fail the render, only fall back.
    """
    if not path:
        return dict(DEFAULT_THEME), None
    try:
        with open(path, "r", encoding="utf-8") as f:
            overrides = json.load(f)
    except (OSError, ValueError) as exc:
        return dict(DEFAULT_THEME), "design-variables ignored (%s): %s" % (path, exc)
    theme = dict(DEFAULT_THEME)
    rejected = set()
    if isinstance(overrides, dict):
        # Accept both a flat {key: value} map and a nested {"colors": {...}} one.
        for src in (overrides, overrides.get("colors", {})):
            if isinstance(src, dict):
                for key, value in src.items():
                    if key not in theme:
                        continue
                    if _valid_theme_value(value):
                        theme[key] = value
                    else:
                        rejected.add(key)
    if rejected:
        return theme, "design-variables: ignored unsafe value(s) for %s — using the built-in palette for those keys" % ", ".join(sorted(rejected))
    return theme, None


def _read_entities(portfolio_dir):
    """Parse every entity file into type-keyed lists, collecting warnings.

    Returns (entities, warnings) where entities is
    {"consultant": [...], "project": [...], "assignment": [...]} of frontmatter
    dicts. A file that cannot be read, cannot be decoded, or has no frontmatter
    is recorded as a warning and skipped — the rest of the portfolio still
    renders, because one unreadable record must never cost the partner the whole
    snapshot.
    """
    entities = {"consultant": [], "project": [], "assignment": []}
    warnings = []
    for path in _ve._entity_files(portfolio_dir):
        rel = os.path.relpath(path, portfolio_dir)
        # One unreadable entity file must degrade to a single warning, not abort
        # the whole render.
        fm, exc = _ve.read_frontmatter(path)
        if exc is not None:
            warnings.append("cannot read %s: %s" % (rel, exc))
            continue
        if not fm:
            warnings.append("no frontmatter in %s — skipped" % rel)
            continue
        etype = fm.get("type")
        if etype not in entities:
            warnings.append("unknown entity type %r in %s — skipped" % (etype, rel))
            continue
        fm["_file"] = rel
        entities[etype].append(fm)
    return entities, warnings


def _coerce_impact(value, project_label, warnings):
    """Return strategic_impact as an int 1..5, or None with a warning."""
    if value is None:
        warnings.append("%s has no strategic_impact — omitted from the value summary" % project_label)
        return None
    try:
        impact = int(str(value).strip())
    except (TypeError, ValueError):
        warnings.append("%s has a non-numeric strategic_impact %r — omitted from the value summary" % (project_label, value))
        return None
    if not 1 <= impact <= 5:
        warnings.append("%s strategic_impact %d is outside 1..5 — omitted from the value summary" % (project_label, impact))
        return None
    return impact


def _normalize_open_roles(proj):
    """Return the project's open_roles as a list, or None when undeclared.

    None is the only representation of "fill status unknown", so every way of
    failing to declare roles — key absent, `open_roles:` with no value, an
    explicit null — collapses to the same state. Declaring an empty list stays
    distinct: that is a project asserting it needs nobody, which is a real
    answer rather than a missing one.
    """
    if "open_roles" not in proj:
        return None
    raw = proj["open_roles"]
    if raw is None or (isinstance(raw, str) and not raw.strip()):
        return None
    if not isinstance(raw, list):
        return [raw]
    return raw


def _project_health(filled, open_roles, status):
    """Map (roles filled, declared open_roles, project status) to (label, severity).

    open_roles is None when the project never declared any. Rendering that with
    the same green as a fully staffed project would show an unstaffed project as
    healthy on a partner's decision surface, so it gets its own warn state.
    """
    if status == PROJECT_STATUS_CLOSED:
        return ("closed", "muted")
    if open_roles is None:
        return ("staffing unknown", "warn")
    total = len(open_roles)
    if total == 0:
        return ("no open roles", "ok")
    if filled >= total:
        return ("fully staffed", "ok")
    if filled == 0 and status == PROJECT_STATUS_ACTIVE:
        return ("unstaffed", "risk")
    return ("%d/%d roles open" % (total - filled, total), "warn")


def _is_closed(status):
    """Whether a project status means the work is over — delivered or lost.

    Takes a status _status_text has already normalized — this compares, it does
    not fold. Passing a raw frontmatter value here reads a mixed-case `Closed`
    as still live.
    """
    return status == PROJECT_STATUS_CLOSED


def _text_field(raw, field, label, warnings):
    """Read a parsed entity field as text, warning when it was not text already.

    The frontmatter parser this script borrows from validate-entities.py coerces
    any all-digit scalar to an int before the schema enum is ever checked — and
    the renderer never runs that validator. So a hand-edited `status: 2026` or
    `role: 2` arrives here as an int. Comparing or calling a str method on it
    raises inside _compute, which no local handler catches: the module-level
    catch-all then discards every warning collected so far and fails the whole
    render. That inverts this script's contract, where one bad record costs a
    warning and nothing else.

    `role` fails harder than `status`, because _compute sorts the covered-role
    set and Python refuses to order a str against an int — one numeric role
    beside any text role was enough.

    Both sides of a comparison must come through here, not just the side that
    raised. `open_roles` entries are coerced by the same parser, so normalizing
    only the assignment role would trade the crash for something quieter and
    worse: a numeric role that matches its numeric open_roles entry today would
    stop matching, silently reporting a filled role as open.

    The guard keys on `raw is not None`, deliberately not on truthiness — a
    falsy `status: 0` or `role: 0` would otherwise normalize away with no
    warning at all.

    Normalizing every text field once, where the entities are parsed, would
    close this class rather than its instances, and retire this helper with it.
    That is tracked as its own change: it decides the string-typed field set for
    every entity type, and staffing-score.py reads the same parser, where a
    numeric role label scores every consultant at zero fit instead of raising.
    """
    if raw is None:
        return ""
    if not isinstance(raw, str):
        warnings.append(
            "%s has a non-string %s %r — coerced to text; fix the record" % (label, field, raw)
        )
    return str(raw).strip()


def _status_text(raw, label, warnings):
    """Read an entity's `status` as normalized text. See _text_field for the why.

    The single place a status is folded to lower case, so the health flag, the
    missing-open_roles gate, _is_closed, the assignment-state check and the
    rendered row all read one string. Folding at each site instead would satisfy
    the same tests while rebuilding the drift this exists to remove. Only
    `status` is folded — role labels and open_roles entries are free text
    matched by exact equality, so case-folding them would change what counts as
    a filled role.

    A status that had to be normalized is reported, like every other
    schema-deviating record here: the schema admits only the lowercase value, so
    `Closed` is a record to fix, not a spelling to accept quietly.

    The isinstance guard keeps one defect to one warning. _text_field returns
    str(raw).strip() for a non-string and has already warned about it, and a
    list-valued `status: [Closed]` arrives as "['Closed']" — whose folded form
    differs, so ungated it would report the same record twice.
    """
    text = _text_field(raw, "status", label, warnings)
    normalized = text.lower()
    if isinstance(raw, str) and normalized != text:
        warnings.append(
            "%s has a non-lowercase status %r — normalized to %r; fix the record"
            % (label, text, normalized)
        )
    return normalized


def _open_role_demand(projects):
    """Sum unfilled roles across the projects that still represent live demand.

    A closed project is delivered or lost, so its declared roles are not work
    anyone will staff — staffing-score.py drops the same set before scoring, and
    the data model says as much. Counting them here made the headline number
    disagree with the shortlist a partner acts on.

    Only `closed` is excluded, never an `active` allowlist: `prospective` is a
    valid status, and filtering to active alone would silently drop pipeline
    demand — the same divergence in the other direction.
    """
    return sum(
        p["roles_total"] - p["roles_filled"]
        for p in projects
        if not _is_closed(p["status"])
    )


def _compute(entities, warnings):
    """Derive per-project staffing + the portfolio value/utilization aggregates.

    Fill status is derived, not stored: for a project's open_roles list, a role
    is "filled" when some planned/active assignment for that project carries a
    matching role label. Role labels are free strings, so a label an assignment
    names that no open_roles entry matches is surfaced as a warning rather than
    silently changing the counts — a visible mismatch is safer than a confident
    wrong number.
    """
    assignments = entities["assignment"]
    projects_out = []
    value_by_impact = {i: 0 for i in range(1, 6)}

    for proj in sorted(entities["project"], key=lambda p: str(p.get("name") or p.get("slug") or "")):
        slug = proj.get("slug")
        label = "project %s" % (proj.get("name") or slug or "(unnamed)")
        # An undeclared open_roles is not an empty one — see _normalize_open_roles.
        declared_roles = _normalize_open_roles(proj)
        # Coerced so both sides of the covered/open_roles comparison are text.
        # Length is preserved, so roles_total and _project_health still see the
        # declared count.
        open_roles = [_text_field(r, "open_roles entry", label, warnings) for r in (declared_roles or [])]
        status = _status_text(proj.get("status"), label, warnings)
        if declared_roles is None and status != PROJECT_STATUS_CLOSED:
            warnings.append("%s has no open_roles — staffing status unknown" % label)

        covered = set()
        for a in assignments:
            # Filter first — an assignment belonging to another project must not
            # have its status read here, or it would warn once per project.
            if a.get("project") != slug:
                continue
            a_label = "assignment %s" % (a.get("_file") or a.get("slug") or "(unknown)")
            # Normalized too, deliberately: exempting assignment status would
            # rebuild the split one call site over.
            if _status_text(a.get("status"), a_label, warnings) in ACTIVE_ASSIGNMENT_STATES:
                role = _text_field(a.get("role"), "role", a_label, warnings)
                if role:
                    covered.add(role)
        # An assignment role that matches no listed open role may be a label
        # mismatch (erp-lead vs "ERP Lead") — flag it, don't hard-fail.
        for role in sorted(covered):
            if open_roles and role not in open_roles:
                warnings.append(
                    "%s: assignment role %r matches no open_roles label — possible label mismatch" % (label, role)
                )
        filled = [r for r in open_roles if r in covered]
        health_label, health_sev = _project_health(len(filled), declared_roles, status)

        impact = _coerce_impact(proj.get("strategic_impact"), label, warnings)
        if impact is not None:
            value_by_impact[impact] += 1

        projects_out.append({
            "name": proj.get("name") or slug or "(unnamed)",
            "client": proj.get("client") or "",
            "status": status or "unknown",
            "impact": impact,
            "roles_total": len(open_roles),
            "roles_filled": len(filled),
            "open_roles": [r for r in open_roles if r not in covered],
            "health_label": health_label,
            "health_sev": health_sev,
        })

    # Orphan assignments: an assignment whose `project` names no project in the
    # portfolio — a typo, or a project file since deleted. It matches no slug on
    # any iteration of the loop above, so without this it is skipped silently by
    # every one of them and reduces role coverage with nothing said.
    #
    # One pass over `assignments`, deliberately OUTSIDE that loop: nested inside
    # it this would warn once per project per orphan, because an orphan is
    # precisely the assignment every project fails to match. One warning per
    # assignment, not one per project iteration.
    #
    # Status is never read here. A `completed` assignment naming a project that
    # does not exist is still a broken reference, so the check must not narrow
    # to ACTIVE_ASSIGNMENT_STATES the way the coverage filter above does.
    known_slugs = set()
    for p in entities["project"]:
        raw_slug = p.get("slug")
        # Dropped on `is None` or empty, deliberately not on truthiness — same
        # reasoning as _text_field's guard, so a real falsy slug stays a known
        # project. Without the drop, a project whose slug is absent would adopt
        # every assignment whose `project` is absent, masking two bad records.
        if raw_slug is None or raw_slug == "":
            continue
        try:
            known_slugs.add(raw_slug)
        except TypeError:
            # An unhashable slug can never be matched by an assignment anyway,
            # and raising here would cost the entire render — see below.
            continue
    for a in assignments:
        proj_ref = a.get("project")
        try:
            known = proj_ref in known_slugs
        except TypeError:
            # A list- or dict-valued `project:` is unhashable, so `in` raises
            # before it can miss. Nothing unhashable is ever a valid slug, so
            # read it as unresolved: letting it propagate would reach the
            # module-level catch-all, which discards every warning collected so
            # far and fails the whole render over one hand-edited record.
            known = False
        if known:
            continue
        # Both sides stay raw, never routed through _text_field. The borrowed
        # parser coerces an all-digit scalar to int for `slug` and `project`
        # alike, and the coverage filter above compares raw to raw — coercing
        # only this side would turn `2026` into "2026", miss its own int slug,
        # and report a legitimately matched assignment as an orphan.
        #
        # validate-entities.py reports the same dangling ref, but resolves it
        # through str() and fails hard. That divergence is deliberate: the
        # renderer never runs the validator, and matching its coercion here
        # would break the raw-to-raw symmetry the filter above depends on.
        a_label = "assignment %s" % (a.get("_file") or a.get("slug") or "(unknown)")
        warnings.append(
            "%s names no known project %r — fix the assignment's project ref "
            "or add the project" % (a_label, proj_ref)
        )

    # Utilization: a simple average of consultant allocation_pct, plus a count of
    # consultants at or above 100%. Consultants with no allocation_pct are
    # excluded from the average rather than counted as zero, so a thinly authored
    # portfolio is not made to look under-allocated. Richer heuristics are out of
    # scope.
    allocations = []
    for c in entities["consultant"]:
        raw = c.get("allocation_pct")
        if raw is None:
            continue
        try:
            allocations.append(int(str(raw).strip()))
        except (TypeError, ValueError):
            warnings.append("consultant %s has a non-numeric allocation_pct %r — omitted from utilization" % (c.get("slug") or "(unknown)", raw))
    util = {
        "consultants": len(entities["consultant"]),
        "with_allocation": len(allocations),
        "avg_allocation": round(sum(allocations) / len(allocations)) if allocations else None,
        "fully_allocated": sum(1 for a in allocations if a >= 100),
    }

    return projects_out, value_by_impact, util


def _esc(value):
    return html.escape(str(value), quote=True)


def _render_html(portfolio, projects, value_by_impact, util, warnings, theme):
    t = theme
    generated = datetime.date.today().isoformat()
    sev_color = {"ok": t["ok"], "warn": t["warn"], "risk": t["risk"], "muted": t["muted"]}

    rows = []
    for p in projects:
        impact = "—" if p["impact"] is None else ("★" * p["impact"])
        coverage = "%d/%d" % (p["roles_filled"], p["roles_total"]) if p["roles_total"] else "—"
        open_roles = ", ".join(_esc(r) for r in p["open_roles"]) if p["open_roles"] else "—"
        rows.append(
            "<tr>"
            "<td><strong>%s</strong><div class='sub'>%s</div></td>"
            "<td>%s</td>"
            "<td>%s</td>"
            "<td>%s</td>"
            "<td>%s</td>"
            "<td><span class='flag' style='color:%s'>%s</span></td>"
            "</tr>" % (
                _esc(p["name"]), _esc(p["client"]),
                _esc(p["status"]), impact, coverage, open_roles,
                sev_color.get(p["health_sev"], t["text"]), _esc(p["health_label"]),
            )
        )

    value_rows = []
    for impact in range(5, 0, -1):
        count = value_by_impact.get(impact, 0)
        bar = "█" * count
        value_rows.append(
            "<tr><td>%s</td><td>%d</td><td class='bar'>%s</td></tr>"
            % ("★" * impact, count, bar)
        )

    warn_block = ""
    if warnings:
        items = "".join("<li>%s</li>" % _esc(w) for w in warnings)
        warn_block = (
            "<section class='card warnings'><h2>Warnings — partial snapshot "
            "(%d)</h2><ul>%s</ul></section>" % (len(warnings), items)
        )

    avg = "—" if util["avg_allocation"] is None else "%d%%" % util["avg_allocation"]
    total_open = _open_role_demand(projects)

    return """<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Portfolio dashboard — {name}</title>
<style>
  :root {{ color-scheme: dark; }}
  * {{ box-sizing: border-box; }}
  body {{ margin: 0; background: {bg}; color: {text}; font-family: {font}; line-height: 1.5; }}
  .wrap {{ max-width: 1040px; margin: 0 auto; padding: 32px 20px 64px; }}
  header h1 {{ margin: 0 0 4px; font-size: 1.6rem; }}
  header .meta {{ color: {muted}; font-size: 0.9rem; }}
  .tiles {{ display: flex; flex-wrap: wrap; gap: 14px; margin: 22px 0; }}
  .tile {{ flex: 1 1 150px; background: {surface}; border: 1px solid {border};
           border-radius: 10px; padding: 16px; }}
  .tile .n {{ font-size: 1.8rem; font-weight: 700; }}
  .tile .l {{ color: {muted}; font-size: 0.82rem; text-transform: uppercase; letter-spacing: 0.04em; }}
  .card {{ background: {surface}; border: 1px solid {border}; border-radius: 10px;
           padding: 18px 20px; margin: 18px 0; overflow-x: auto; }}
  .card h2 {{ margin: 0 0 12px; font-size: 1.05rem; }}
  table {{ width: 100%; border-collapse: collapse; font-size: 0.92rem; }}
  th, td {{ text-align: left; padding: 9px 10px; border-bottom: 1px solid {border}; vertical-align: top; }}
  th {{ color: {muted}; font-weight: 600; font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.03em; }}
  td .sub {{ color: {muted}; font-size: 0.8rem; }}
  .flag {{ font-weight: 600; }}
  .bar {{ color: {accent}; letter-spacing: 1px; }}
  .warnings {{ border-color: {warn}; }}
  .warnings h2 {{ color: {warn}; }}
  .warnings li {{ color: {muted}; font-size: 0.88rem; }}
  footer {{ color: {muted}; font-size: 0.8rem; margin-top: 26px; }}
</style></head>
<body><div class="wrap">
<header>
  <h1>{name}</h1>
  <div class="meta">Partner-meeting portfolio dashboard · generated {generated}</div>
</header>
<div class="tiles">
  <div class="tile"><div class="n">{n_projects}</div><div class="l">Projects</div></div>
  <div class="tile"><div class="n">{n_consultants}</div><div class="l">Consultants</div></div>
  <div class="tile"><div class="n">{open_roles}</div><div class="l">Open roles</div></div>
  <div class="tile"><div class="n">{avg}</div><div class="l">Avg allocation</div></div>
</div>
<section class="card">
  <h2>Projects — staffing &amp; health</h2>
  <table>
    <thead><tr><th>Project</th><th>Status</th><th>Impact</th><th>Roles filled</th><th>Still open</th><th>Health</th></tr></thead>
    <tbody>{rows}</tbody>
  </table>
</section>
<section class="card">
  <h2>Portfolio value — projects by strategic impact</h2>
  <table>
    <thead><tr><th>Impact</th><th>Projects</th><th></th></tr></thead>
    <tbody>{value_rows}</tbody>
  </table>
</section>
{warn_block}
<footer>cogni-projects · read-only render · {generated}</footer>
</div></body></html>
""".format(
        name=_esc(portfolio.get("name") or portfolio.get("slug") or "Portfolio"),
        generated=generated,
        bg=t["bg"], surface=t["surface"], text=t["text"],
        muted=t["muted"], accent=t["accent"], border=t["border"],
        ok=t["ok"], warn=t["warn"], risk=t["risk"], font=t["font"],
        n_projects=len(projects),
        n_consultants=util["consultants"],
        open_roles=total_open,
        avg=avg,
        rows="".join(rows) or "<tr><td colspan='6'>No projects yet.</td></tr>",
        value_rows="".join(value_rows),
        warn_block=warn_block,
    )


def _fail(message, code=2):
    print(json.dumps({"success": False, "data": {}, "error": message}, ensure_ascii=False))
    return code


def main(argv):
    ap = argparse.ArgumentParser(
        description="Render a cogni-projects partner-meeting portfolio dashboard.",
    )
    ap.add_argument("portfolio_dir")
    ap.add_argument("--design-variables", dest="design_variables", default=None)
    # argparse raises SystemExit on a usage error, and SystemExit is a
    # BaseException — the top-level `except Exception` would not catch it, so a
    # caller parsing stdout would get nothing at all. Convert it to the envelope
    # every path in this repo is contracted to print.
    try:
        args = ap.parse_args(argv)
    except SystemExit as exc:
        # --help exits 0 having already printed help; that is a success path and
        # must not be dressed up as a failure envelope.
        if exc.code == 0:
            return 0
        # Derived from the parser rather than restated, so adding an argument
        # cannot leave this message describing an older signature.
        return _fail(ap.format_usage().strip())

    portfolio_dir = os.path.abspath(args.portfolio_dir)
    if not os.path.isdir(portfolio_dir):
        return _fail("portfolio directory not found: %s" % portfolio_dir)

    manifest_path = os.path.join(portfolio_dir, "projects-portfolio.json")
    if not os.path.isfile(manifest_path):
        return _fail(
            "portfolio manifest not found: %s (run /cogni-projects:projects-setup first)"
            % manifest_path
        )

    warnings = []
    try:
        with open(manifest_path, "r", encoding="utf-8") as f:
            portfolio = json.load(f)
    except (OSError, ValueError) as exc:
        return _fail("cannot read portfolio manifest: %s" % exc)

    theme, theme_warning = _load_theme(args.design_variables)
    if theme_warning:
        warnings.append(theme_warning)

    entities, read_warnings = _read_entities(portfolio_dir)
    warnings.extend(read_warnings)
    projects, value_by_impact, util = _compute(entities, warnings)

    out_dir = os.path.join(portfolio_dir, "output")
    try:
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, "dashboard.html")
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(_render_html(portfolio, projects, value_by_impact, util, warnings, theme))
    except OSError as exc:
        return _fail("cannot write dashboard: %s" % exc)

    print(json.dumps({
        "success": True,
        "data": {
            "path": out_path,
            "portfolio": portfolio.get("slug") or "",
            "projects": len(projects),
            "consultants": util["consultants"],
            "avg_allocation": util["avg_allocation"],
            "fully_allocated": util["fully_allocated"],
            "open_roles": _open_role_demand(projects),
            "projects_detail": projects,
            "value_by_impact": value_by_impact,
            "warnings": warnings,
            "partial": bool(warnings),
        },
        "error": "",
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    # Same envelope contract as the sibling scripts: a hand-edited manifest or
    # entity of the wrong shape must report as a readable failure, never a
    # traceback that breaks the {success,data,error} contract mid-render.
    try:
        _code = main(sys.argv[1:])
    except Exception as _exc:  # noqa: BLE001 — deliberate catch-all
        _code = _fail("unexpected failure: %s: %s" % (type(_exc).__name__, _exc))
    sys.exit(_code)
