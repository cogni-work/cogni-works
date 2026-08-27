#!/usr/bin/env python3
"""check-contrast.py — WCAG 2.1 contrast ratios for a theme palette.

Stdlib-only. Reads a flat ``{"role": "#rrggbb"}`` JSON map and reports the
contrast ratio of every foreground/background pair, each with its AA verdict.
The map is deliberately palette-shape-agnostic: a tier-0 theme keeps its
colours only as ``theme.md`` prose and a tiered theme keeps them in
``tokens/colors.json``, so the caller resolves whichever source exists and
hands this script the same flat map either way.

A ratio is a formula, not a judgement. Everything downstream of the arithmetic
-- the below-AA flag and the replacement-hex suggestion -- is computed here and
reported as data, so a caller never has to derive a figure of its own.

Thresholds are WCAG 2.1 AA: 4.5:1 for normal text, 3:1 for large text and UI
components. Both comparisons are inclusive and run against the unrounded
ratio; rounding is applied to the reported figure only.

A below-AA pair is a finding, not an error -- ``success`` stays true. False is
reserved for operational failure: an unreadable file, malformed JSON, or a
pair naming a role the palette does not define.

Nothing the palette supplies is dropped quietly. ``data.unparsed`` holds the
roles present but not spelled ``#rrggbb``; ``data.unclassified`` holds the
roles that parse fine but fall outside the vocabulary above, so they form no
default pair. Both are reported on every run. A caller that reads only
``data.evaluated`` would otherwise be told a partial audit was a clean one --
the exact false-confidence shape this script exists to remove.

Every pair also carries ``fg_luminance`` and ``bg_luminance``, the WCAG
relative luminances the ratio is computed from. They are reported as evidence,
never as a filter: this script pairs every foreground role with every surface
role, and only the theme itself knows which of those pairings it intends. No
pair is suppressed on the script's own guess about intent.

Usage:
    python3 check-contrast.py <palette.json>
    python3 check-contrast.py <palette.json> --pair text:background
    python3 check-contrast.py <palette.json> --large-pair accent:background
"""

import argparse
import colorsys
import json
import re
import sys
from pathlib import Path


AA_NORMAL = 4.5
AA_LARGE = 3.0

HEX_RE = re.compile(r"^#?([0-9A-Fa-f]{6})$")

# Role families used to derive the default pair set. The vocabulary tracks the
# role names this repo's themes actually carry -- ``themes/_template/theme.md``
# and every ``design-variables`` artifact spell the status colour ``danger``,
# never ``error``. A role the palette defines and this vocabulary does not
# classify is still reported, under ``data.unclassified``, so a mis-keyed or
# custom role can never leave the audit quietly partial.
#
# One role per line in LARGE_UI_ROLES: the mutation harness anchors on a
# single-line literal, and a tuple wrapped mid-role is not anchorable.
NORMAL_TEXT_ROLES = (
    "text",
    "text-light",
    "text-muted",
    "textmuted",
    "muted",
    "foreground",
    "fg",
)
LARGE_UI_ROLES = (
    "primary",
    "secondary",
    "accent",
    "accent-dark",
    "accent-muted",
    "border",
    "link",
    "success",
    "warning",
    "danger",
    "info",
)
SURFACE_ROLES = (
    "background",
    "bg",
    "surface",
    "surface-2",
    "surface-dark",
    "canvas",
    "card",
)

CLASSIFIED_ROLES = frozenset(NORMAL_TEXT_ROLES + LARGE_UI_ROLES + SURFACE_ROLES)


# ---------------------------------------------------------------------------
# Output envelope
# ---------------------------------------------------------------------------


def emit(success: bool, data=None, error: str = "") -> int:
    print(json.dumps({"success": success, "data": data or {}, "error": error}))
    return 0 if success else 1


# ---------------------------------------------------------------------------
# WCAG 2.1 arithmetic
# ---------------------------------------------------------------------------


def parse_hex(value):
    """Return (r, g, b) floats in 0..1, or None when value is not a hex colour."""
    if not isinstance(value, str):
        return None
    match = HEX_RE.match(value.strip())
    if not match:
        return None
    digits = match.group(1)
    return tuple(int(digits[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def relative_luminance(rgb):
    """WCAG 2.1 relative luminance from linearised sRGB channels."""
    linear = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast_ratio(fg_rgb, bg_rgb):
    """WCAG 2.1 contrast ratio between two colours, unrounded."""
    fg_luminance = relative_luminance(fg_rgb)
    bg_luminance = relative_luminance(bg_rgb)
    lighter = max(fg_luminance, bg_luminance)
    darker = min(fg_luminance, bg_luminance)
    return (lighter + 0.05) / (darker + 0.05)


def to_hex(rgb):
    return "#" + "".join("{:02X}".format(max(0, min(255, round(c * 255)))) for c in rgb)


def suggest_hex(fg_rgb, bg_rgb, threshold):
    """Walk the foreground's lightness at constant hue until it clears threshold.

    Returns a hex string this module has itself re-verified against threshold,
    or None when neither direction reaches it.
    """
    hue, lightness, saturation = colorsys.rgb_to_hls(*fg_rgb)
    for direction in (-1, 1):
        step = 0.01
        candidate_lightness = lightness
        while 0.0 <= candidate_lightness <= 1.0:
            candidate_lightness += direction * step
            if not 0.0 <= candidate_lightness <= 1.0:
                break
            candidate = colorsys.hls_to_rgb(hue, candidate_lightness, saturation)
            if contrast_ratio(candidate, bg_rgb) >= threshold:
                snapped = parse_hex(to_hex(candidate))
                if snapped and contrast_ratio(snapped, bg_rgb) >= threshold:
                    return to_hex(candidate)
    return None


# ---------------------------------------------------------------------------
# Pair evaluation
# ---------------------------------------------------------------------------


def evaluate_pair(fg_role, bg_role, fg_value, bg_value, threshold):
    fg_rgb = parse_hex(fg_value)
    bg_rgb = parse_hex(bg_value)
    ratio = contrast_ratio(fg_rgb, bg_rgb)
    entry = {
        "foreground": fg_role,
        "background": bg_role,
        "fg_hex": fg_value,
        "bg_hex": bg_value,
        "fg_luminance": round(relative_luminance(fg_rgb), 4),
        "bg_luminance": round(relative_luminance(bg_rgb), 4),
        "ratio": round(ratio, 4),
        "threshold": threshold,
        "passes": ratio >= threshold,
        "passes_aa_normal": ratio >= AA_NORMAL,
        "passes_aa_large": ratio >= AA_LARGE,
    }
    if not entry["passes"]:
        entry["suggested_hex"] = suggest_hex(fg_rgb, bg_rgb, threshold)
    return entry


def default_pairs(usable):
    pairs = []
    surfaces = [r for r in SURFACE_ROLES if r in usable]
    for surface in surfaces:
        for role in NORMAL_TEXT_ROLES:
            if role in usable:
                pairs.append((role, surface, AA_NORMAL))
        for role in LARGE_UI_ROLES:
            if role in usable:
                pairs.append((role, surface, AA_LARGE))
    return pairs


def split_pair(raw, flag):
    parts = raw.split(":")
    if len(parts) != 2 or not parts[0] or not parts[1]:
        raise ValueError("{} expects FOREGROUND:BACKGROUND, got {!r}".format(flag, raw))
    return parts[0], parts[1]


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(
        description="WCAG 2.1 contrast ratios for a flat {role: '#rrggbb'} palette."
    )
    parser.add_argument("palette", help="path to a flat JSON map of role -> hex colour")
    parser.add_argument("--pair", action="append", default=[], metavar="FG:BG",
                        help="evaluate this role pair at the 4.5:1 normal-text threshold")
    parser.add_argument("--large-pair", action="append", default=[], metavar="FG:BG",
                        help="evaluate this role pair at the 3:1 large-text/UI threshold")
    args = parser.parse_args()

    path = Path(args.palette)
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return emit(False, None, "palette not found: {}".format(path))
    except (OSError, UnicodeDecodeError) as exc:
        return emit(False, None, "palette unreadable: {}".format(exc))
    except json.JSONDecodeError as exc:
        return emit(False, None, "palette is not valid JSON: {}".format(exc))

    if not isinstance(raw, dict):
        return emit(False, None, "palette must be a JSON object of role -> hex colour")

    usable = {}
    unparsed = {}
    for role, value in raw.items():
        key = str(role).strip().lower()
        if parse_hex(value) is None:
            unparsed[key] = value
        else:
            usable[key] = value.strip() if isinstance(value, str) else value

    requested = []
    try:
        for raw_pair in args.pair:
            fg, bg = split_pair(raw_pair, "--pair")
            requested.append((fg.lower(), bg.lower(), AA_NORMAL))
        for raw_pair in args.large_pair:
            fg, bg = split_pair(raw_pair, "--large-pair")
            requested.append((fg.lower(), bg.lower(), AA_LARGE))
    except ValueError as exc:
        return emit(False, None, str(exc))

    for fg, bg, _ in requested:
        for role in (fg, bg):
            if role not in usable:
                reason = ("is present but carries no usable hex value"
                          if role in unparsed else "is not in the palette")
                return emit(False, None,
                            "requested role {!r} {}".format(role, reason))

    pairs_to_run = requested or default_pairs(usable)

    pairs = [evaluate_pair(fg, bg, usable[fg], usable[bg], threshold)
             for fg, bg, threshold in pairs_to_run]
    failures = ["{} on {}".format(p["foreground"], p["background"])
                for p in pairs if not p["passes"]]

    data = {
        "palette": str(path),
        "roles": sorted(usable),
        "unparsed": unparsed,
        "unclassified": sorted(set(usable) - CLASSIFIED_ROLES),
        "pairs": pairs,
        "evaluated": len(pairs),
        "failures": failures,
        "thresholds": {"aa_normal": AA_NORMAL, "aa_large": AA_LARGE},
    }
    return emit(True, data, "")


if __name__ == "__main__":
    sys.exit(main())
