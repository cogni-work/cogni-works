#!/usr/bin/env python3
"""generate-tokens-css.py — Regenerate tokens.css from canonical tokens/*.json files.

Stdlib-only. Each canonical tokens/<stem>.json file contributes a block of CSS
custom properties prefixed with the file stem. Output is deterministic: the
canonical file order below, alphabetical key order within each block. The
function is importable as ``generate(tokens_dir) -> str`` (used by
validate-theme-manifest.py for parity checking) and runnable as a CLI for the
authoring lifecycle (#128).

Token JSON files are flat ``{key: value}`` maps where value is a primitive
(string, integer, or float). Nested values are skipped silently in v1.0; the
manage-themes authoring flow will reject them upstream.

Usage:
    python3 generate-tokens-css.py --tokens-dir <dir>            # print to stdout
    python3 generate-tokens-css.py --tokens-dir <dir> --write    # write tokens.css
"""

import argparse
import json
import sys
from pathlib import Path


CANONICAL_FILES = ("colors", "typography", "spacing", "radii", "shadows", "motion")


def _emit_block(stem: str, data: dict) -> list:
    """Return CSS lines for one tokens/<stem>.json block.

    Token keys are normalised by replacing underscores with hyphens *before*
    being composed into the CSS variable name. This avoids a double-dash
    artefact (``--colors--focus``) when a JSON key starts with an underscore.
    """
    lines = ["  /* {} */".format(stem)]
    for key in sorted(data.keys()):
        value = data[key]
        if not isinstance(value, (str, int, float)) or isinstance(value, bool):
            continue
        normalised_key = key.replace("_", "-").lstrip("-")
        var_name = "--{}-{}".format(stem, normalised_key)
        lines.append("  {}: {};".format(var_name, value))
    return lines


def generate(tokens_dir) -> str:
    """Read tokens/<canonical>.json files and return a canonical CSS string.

    Empty / missing files are skipped; the generator never fails on a partial
    tokens directory. A directory with no canonical files yields an empty
    ``:root {}`` block.
    """
    tokens_dir = Path(tokens_dir)
    if not tokens_dir.is_dir():
        raise FileNotFoundError("tokens directory not found: {}".format(tokens_dir))

    body: list = []
    for stem in CANONICAL_FILES:
        f = tokens_dir / (stem + ".json")
        if not f.exists():
            continue
        with f.open("r", encoding="utf-8") as h:
            data = json.load(h)
        if not isinstance(data, dict):
            continue
        body.extend(_emit_block(stem, data))

    header = "/* Generated from tokens/*.json by generate-tokens-css.py — do not edit by hand. */\n"
    if body:
        return header + ":root {\n" + "\n".join(body) + "\n}\n"
    return header + ":root {\n}\n"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Regenerate tokens.css from canonical tokens/*.json files."
    )
    parser.add_argument(
        "--tokens-dir",
        required=True,
        help="Path to the tokens/ directory inside a theme.",
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="Write the regenerated CSS to <tokens-dir>/tokens.css. "
        "Without this flag the generator prints to stdout.",
    )
    args = parser.parse_args()

    try:
        css = generate(args.tokens_dir)
    except (FileNotFoundError, json.JSONDecodeError, OSError) as e:
        print(json.dumps({"success": False, "data": {}, "error": str(e)}))
        return 1

    if args.write:
        out = Path(args.tokens_dir) / "tokens.css"
        try:
            out.write_text(css, encoding="utf-8")
        except OSError as e:
            print(json.dumps({"success": False, "data": {}, "error": str(e)}))
            return 1
        print(
            json.dumps(
                {
                    "success": True,
                    "data": {"path": str(out), "bytes": len(css)},
                    "error": "",
                }
            )
        )
    else:
        sys.stdout.write(css)

    return 0


if __name__ == "__main__":
    sys.exit(main())
