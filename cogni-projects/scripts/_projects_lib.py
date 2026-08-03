#!/usr/bin/env python3
"""
_projects_lib.py — shared primitives for cogni-projects scripts.

Single source of truth for loading `validate-entities.py`. That file carries a
hyphen, so it is not an importable module name and every consumer has to load it
by file location instead.

Never prints and never exits: `load_validator()` returns `None` and the caller
owns the envelope, the exit code, and the timing. That separation is what lets
callers with genuinely different failure contracts share one loader — baking any
one of those policies in here would silently change the others.

stdlib-only. Python 3.8+.
"""

import importlib.util
import os

# Anchored on this file, so it holds however the consumer was invoked.
VALIDATOR_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "validate-entities.py"
)


def load_validator():
    """Load the sibling validate-entities.py by file location.

    Returns the loaded module, or None when the spec cannot be built — the
    caller owns the error envelope, the exit code, and the timing.
    """
    spec = importlib.util.spec_from_file_location("validate_entities", VALIDATOR_PATH)
    if spec is None or spec.loader is None:
        return None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module
