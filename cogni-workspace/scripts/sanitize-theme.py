#!/usr/bin/env python3
"""Shared theme-value guard for cogni dashboard/report renderers.

Operator-supplied ``--design-variables`` values are interpolated into a
generated ``<style>`` block. A value carrying CSS-structural or markup
characters — e.g. ``"background": "#000000</style><script>alert(1)</script>"`` —
could break out of the stylesheet in the self-contained HTML output, while
entity-derived values are HTML-escaped. This helper lets every renderer reject
such a value and fall back to its built-in palette for that key, so the guard
lives in one place instead of being copy-pasted per renderer.

Two consumption surfaces:

  * **In-plugin import** (the fast path used by renderers): load this file by
    path and call :func:`is_safe_value` / :func:`sanitize_values`. Renderers in
    *other* plugins cannot rely on a normal ``import`` (separate plugin cache
    dirs), so the natural consumers are cogni-workspace's own renderers; the
    cross-plugin sharing mechanism is a separate, deferred decision.
  * **CLI report**: ``python3 sanitize-theme.py <design-variables.json>`` prints
    a ``{"success","data","error"}`` envelope naming which keys would be
    rejected — the stdlib-only, dependency-free contract every cogni script
    follows.

Profiles
--------
``strict`` (the default)
    Denylist ``<>{}();@\\``, max length 120. Rejects stylesheet/markup breakout
    **and** the ``url()`` / ``@import`` external-fetch surface (a self-contained
    artifact that phones home on open). Correct for ``colors`` / ``status`` /
    border tokens, which never legitimately need those characters.

``font-aware``
    Denylist ``<>{};@\\`` (``strict``'s set minus the two paren characters), max
    length 300. For the values ``strict`` cannot express: font stacks, shadows,
    ``radius``, and ``google_fonts_import``. Permits ``rgba(...)`` / ``url(...)``
    by allowing parens, and — through a *second, anchored acceptance path* — one
    ``@import url(<https-url>);`` statement or one bare ``https://…`` URL. That
    shape gate is the only way ``@`` and ``;`` can appear, which is what keeps
    the relaxation from turning every declaration slot into an injection point:
    a bare ``;`` would let ``red; background-image: url(https://evil/beacon.png)``
    ride along inside ``:root``, and an ungated ``@`` would let the
    top-level ``google_fonts_import`` slot carry any number of at-rules.

    Rejected under ``font-aware``: ``</style>`` / ``<script>`` and any markup
    breakout, rule-block injection (``{``/``}``), ``;`` declaration injection,
    ``data:`` / ``http:`` / protocol-relative schemes, chained imports
    (``@import a;@import b;``), media-qualified imports
    (``@import url(...) screen;``), and anything with trailing content.

    **Accepted residual, by policy:** a well-formed *https* ``@import`` from an
    arbitrary host passes — there is deliberately no host allowlist, so
    self-hosted, Bunny, and Adobe font hosts keep working. External imports are
    kept rather than inlined; narrowing that is a maintainer policy decision,
    not a property of this guard.

Single quotes stay legal under both profiles: a font stack
(``'Segoe UI', Roboto``) needs them and they cannot terminate a ``<style>``
block on their own.
"""

import json
import re
import sys

# One ``@import url(<https-url>);`` statement, or one bare ``https://…`` URL —
# the two shapes renderers actually accept (``cogni-visual/enrich-report``
# normalizes the latter into the former).
#
# Anchored ``^…\Z`` with **no trailing ``\s*``**. Both details are load-bearing:
# ``$`` alone matches *before* a trailing newline, and a trailing ``\s*``
# re-admits that newline even under ``\Z``. With the anchor tight, a shape-gated
# value carrying anything after the statement — ``@import url('https://h/x.css');
# body{color:red}``, a second chained ``@import``, or bare trailing whitespace —
# fails closed onto the built-in default rather than being normalized away.
#
# This gate is consulted **only when the denylist path already failed**, i.e. for
# values carrying ``@`` or ``;``. A value with none of the forbidden characters
# is accepted without ever being shape-checked — deliberately, since it provably
# cannot break out, and demanding this shape of every value would reject the
# ``rgba(...)`` shadows and font stacks the profile exists to allow.
#
# ``_URL`` is named once because both alternatives must stay identical: excluding
# whitespace, quotes, parens, angle brackets, braces and backslash is what makes
# a shape-accepted value provably free of every breakout character. It still
# allows ``@`` and ``;`` *inside* the URL — the shipped default needs both for
# ``wght@400;500``.
_URL = r"https://[^\s'\"()<>{}\\]+"
_FONT_IMPORT_RE = re.compile(
    r"^(?:@import\s+url\(\s*(['\"]?)" + _URL + r"\1\s*\)\s*;?|" + _URL + r")\Z"
)

# profile name -> (forbidden character set, max length, optional shape regex).
# The regex is the profile's *second* acceptance path; carrying it in the record
# keeps this table the complete statement of policy, so a future profile is a new
# row rather than a new branch inside is_safe_value.
_PROFILES = {
    "strict": (set("<>{}();@\\"), 120, None),
    "font-aware": (set("<>{};@\\"), 300, _FONT_IMPORT_RE),
}
DEFAULT_PROFILE = "strict"
FONT_AWARE_PROFILE = "font-aware"

# Which profile each design-variables section is vetted under, and whether it is
# a ``{key: value}`` map or a single string value. This is a fact about the
# shared design-variables schema rather than about any one renderer — every
# consumer reads the same section names in the same shapes — so it lives here
# instead of being restated per renderer. Consume it via :func:`sanitize_section`.
SECTION_PROFILES = {
    "colors": ("dict", DEFAULT_PROFILE),
    "status": ("dict", DEFAULT_PROFILE),
    "fonts": ("dict", FONT_AWARE_PROFILE),
    "shadows": ("dict", FONT_AWARE_PROFILE),
    "google_fonts_import": ("scalar", FONT_AWARE_PROFILE),
    "radius": ("scalar", FONT_AWARE_PROFILE),
}


def is_safe_value(value, profile=DEFAULT_PROFILE):
    """Return True when ``value`` is safe to interpolate into a ``<style>`` block.

    A value passes on either of two paths, and the profile's length bound
    applies to both. The **denylist path** (the only one ``strict`` has) accepts
    a non-empty string carrying none of the profile's forbidden characters. The
    **shape path** accepts a value matching the profile's own regex, when it
    declares one — see the module docstring for why that escape hatch is narrow
    rather than a wider denylist.

    Non-strings (numbers, dicts, None) are unsafe on both paths — theme values
    reach the stylesheet as raw text, so only vetted strings may pass. An
    unknown profile name falls back to ``strict``, i.e. fails closed onto the
    tightest policy.
    """
    name = profile if profile in _PROFILES else DEFAULT_PROFILE
    forbidden, max_len, shape = _PROFILES[name]
    if not isinstance(value, str) or not (0 < len(value) <= max_len):
        return False
    if not (forbidden & set(value)):
        return True
    return shape is not None and bool(shape.match(value))


def sanitize_values(values, defaults, profile=DEFAULT_PROFILE):
    """Filter a ``{key: value}`` override map against a fallback map.

    Returns ``(clean, rejected)`` where ``clean`` carries the safe overrides
    merged onto ``defaults`` (a rejected or absent key keeps the ``defaults``
    value), and ``rejected`` is the sorted list of keys whose override was
    dropped. ``defaults`` is the source of truth for the key set — an override
    key absent from ``defaults`` is ignored, never introduced.
    """
    clean = dict(defaults)
    rejected = []
    if isinstance(values, dict):
        for key in defaults:
            if key not in values:
                continue
            if is_safe_value(values[key], profile):
                clean[key] = values[key]
            else:
                rejected.append(key)
    return clean, sorted(rejected)


def sanitize_section(section, value, defaults, profile=None):
    """Vet one design-variables section under the profile its consumers apply.

    The single entry point a renderer should use: it resolves the section's
    shape and profile from :data:`SECTION_PROFILES`, so no caller has to restate
    which sections are dict-shaped or which profile each one takes. Returns
    ``(clean, rejected)`` — ``clean`` being the vetted value (or ``defaults``
    when the override is rejected) and ``rejected`` a list of dropped keys, or
    ``[section]`` for a rejected scalar.

    An absent or empty scalar is **not** an override — an empty
    ``google_fonts_import`` legitimately means "no import" — so it yields
    ``defaults`` with nothing rejected rather than being reported as unsafe.

    ``profile`` overrides the section's default profile; leave it ``None`` to
    apply the policy the renderers actually use.
    """
    shape, section_profile = SECTION_PROFILES[section]
    applied = profile or section_profile
    if shape == "dict":
        return sanitize_values(value, defaults, applied)
    if value in (None, ""):
        return defaults, []
    if is_safe_value(value, applied):
        return value, []
    return defaults, [section]


def _cli(argv):
    """Report which design-variable override values a file would lose.

    Walks every section in :data:`SECTION_PROFILES`, vetting each under the
    profile that section's renderer applies. An explicit ``--profile=`` forces
    one profile across all sections instead — useful for asking "what would
    `strict` reject here?" of a file the renderer treats more leniently.
    """
    args = [a for a in argv if not a.startswith("--")]
    forced_profile = None
    for a in argv:
        if a.startswith("--profile="):
            forced_profile = a.split("=", 1)[1]
    if not args:
        return {"success": False, "data": None,
                "error": "usage: sanitize-theme.py <design-variables.json> "
                         "[--profile=strict|font-aware]"}
    if forced_profile is not None and forced_profile not in _PROFILES:
        return {"success": False, "data": None,
                "error": "unknown profile %r (available: %s)"
                         % (forced_profile, ", ".join(sorted(_PROFILES)))}
    try:
        with open(args[0], "r", encoding="utf-8") as f:
            overrides = json.load(f)
    except (OSError, ValueError) as exc:
        return {"success": False, "data": None, "error": "cannot read %s: %s" % (args[0], exc)}
    if not isinstance(overrides, dict):
        return {"success": False, "data": None, "error": "design-variables must be a JSON object"}

    rejected = {}
    section_profiles = {}
    checked = 0
    for section, (shape, section_profile) in SECTION_PROFILES.items():
        section_profiles[section] = forced_profile or section_profile
        src = overrides.get(section)
        # Report against the file's own keys, so `defaults` is `src` itself —
        # the same walk `sanitize_section` gives a renderer, minus the fallback
        # values a report has no use for.
        if shape == "dict" and isinstance(src, dict):
            checked += len(src)
        elif shape == "scalar" and src not in (None, ""):
            checked += 1
        else:
            continue
        _, bad = sanitize_section(section, src, src, forced_profile)
        if bad:
            rejected[section] = bad
    return {"success": True,
            # ``profile`` is what was *forced*; null means each section was
            # vetted under its own default, which ``section_profiles`` spells out.
            "data": {"profile": forced_profile,
                     "section_profiles": section_profiles,
                     "checked": checked,
                     "rejected": rejected},
            "error": None}


if __name__ == "__main__":
    result = _cli(sys.argv[1:])
    print(json.dumps(result))
    # Envelope is always printed; a usage/read error also exits non-zero so a
    # shell caller can branch on `$?`, matching the cogni script convention.
    sys.exit(0 if result["success"] else 2)
