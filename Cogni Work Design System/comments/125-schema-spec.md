# Schema Resolutions for #125

Posting the schema-affecting resolutions from epic #132 here as actionable specs so the implementer doesn't need to back-reference the epic body.

## Locked decisions for v1.0 schema

### From Q1 — Token format

- **JSON is canonical.** Tokens live in `tokens/colors.json`, `typography.json`, `spacing.json`, `radii.json`, `shadows.json`, `motion.json`.
- **CSS is generated.** `tokens/tokens.css` is built from JSON via a Python script in `cogni-workspace/scripts/`.
- **Validator must check parity.** If `tokens.css` exists in a theme directory, validate it matches the regenerated output from JSON. Mismatch is a hard failure.

### From Q2 — Component versioning

- **`live` field is reserved.** Schema MUST reject any manifest that includes `"live": true` or `"live_within_session": true` at the root or inside `components` declarations. Reservation only — semantics defer to Phase 3.
- **No live-resolution code path in v1.0** — but #125 only needs to enforce the schema reservation; runtime behavior is #129's concern.

### From Q3 — Component format

- **HTML is canonical.** Component primitives are `.html` files. Schema validates each `.html` file under `components/<namespace>/` is well-formed HTML5.
- **JSX is permitted.** `.jsx` files alongside `.html` are valid; not required. Schema does not enforce JSX/HTML pairing.
- **No other extensions accepted in v1.0.** Reject `.tsx`, `.vue`, `.svelte`, etc. — opens the door for Phase 3 if demand emerges.

### From Q5 — No copy/voice tier

- **No `copy` tier in v1.0 manifest.** Voice rules stay in `theme.md` (Phase 1).
- Document `copy` as "reserved for Phase 3" in the schema notes section. Schema MUST reject any manifest that declares a `copy` tier in v1.0.

## Manifest schema starting point

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Cogni Workspace Theme Manifest v1.0",
  "type": "object",
  "required": ["schema_version", "name", "slug"],
  "additionalProperties": false,
  "properties": {
    "schema_version": {
      "type": "string",
      "const": "1.0"
    },
    "name": {
      "type": "string",
      "minLength": 1
    },
    "slug": {
      "type": "string",
      "pattern": "^[a-z0-9][a-z0-9-]*$"
    },
    "tiers": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "tokens": {
          "type": "string",
          "description": "Path to tokens directory (typically 'tokens/')"
        },
        "assets": {
          "type": "string"
        },
        "components": {
          "type": "object",
          "patternProperties": {
            "^[a-z][a-z0-9-]*$": {
              "type": "string",
              "description": "Path to namespace directory under components/"
            }
          },
          "additionalProperties": false
        },
        "templates": {
          "type": "object",
          "patternProperties": {
            "^[a-z][a-z0-9-]*$": {
              "type": "string"
            }
          },
          "additionalProperties": false
        }
      }
    },
    "showcase": {
      "type": "string"
    },
    "voice_ref": {
      "type": "string",
      "description": "Pointer into theme.md (e.g. '#voice--copy-guidelines') for skills consuming voice content"
    }
  },
  "not": {
    "anyOf": [
      { "required": ["live"] },
      { "required": ["live_within_session"] },
      { "required": ["copy"] }
    ]
  }
}
```

### Reserved-field enforcement (recursive)

JSON Schema does not natively express "reject this key anywhere in the document." The validator script must perform a recursive scan post-schema-validation that fails on any occurrence of `live`, `live_within_session`, or `copy` as a key — at any nesting depth, in any object or array of objects within `manifest.json`.

Pseudocode for the validator:
```python
RESERVED_KEYS = {"live", "live_within_session", "copy"}

def check_reserved_keys(node, path=""):
    if isinstance(node, dict):
        for key, value in node.items():
            if key in RESERVED_KEYS:
                raise ValidationError(
                    f"Reserved key '{key}' at {path}/{key} — "
                    f"forbidden in schema v1.0; reserved for Phase 3."
                )
            check_reserved_keys(value, f"{path}/{key}")
    elif isinstance(node, list):
        for i, item in enumerate(node):
            check_reserved_keys(item, f"{path}[{i}]")
```

This catches the slip-past case where `{"tiers": {"components": {"web": {"live": true}}}}` would pass the root-level `not` check.

This is a starting point; expect the implementer to refine pattern constraints, add path-existence validation, and write fixtures.

## Validator script — proposed deliverables for #125

1. `cogni-workspace/scripts/validate-theme.py` — validates a theme directory against the schema.
   - Loads `manifest.json` (or skips with success if absent — tier-0 themes are valid).
   - Validates against schema above.
   - Verifies declared paths exist and contain expected content (HTML files in components, JSON files in tokens, etc.).
   - If `tokens.css` is present, regenerates from JSON and compares — fails on drift.
2. `cogni-workspace/scripts/build-tokens-css.py` — regenerates `tokens.css` from JSON sources.
3. CI hook (in `.github/workflows/` or equivalent) — runs validator on every theme in `cogni-workspace/themes/` per PR.
4. Schema file at `cogni-workspace/schemas/theme-manifest-v1.json`.

## Test fixtures

- **Valid tier-0 theme** (no manifest) — must pass validation as a no-op.
- **Valid full-tier theme** (`cogni-work` after #127 migration) — must validate cleanly across all tiers.
- **Invalid: manifest with `live: true`** — must be rejected.
- **Invalid: manifest with `copy` tier** — must be rejected.
- **Invalid: tokens JSON / CSS drift** — must be rejected.
- **Invalid: declared `components/web/` path doesn't exist** — must be rejected.

## Out of scope for #125

- Live-resolution semantics (Phase 3, see Q2)
- `copy/` tier semantics (Phase 3, see Q5)
- Component versioning beyond schema reservation (#129's concern at runtime)
- Migration of `deutsche-telekom`/`telekom-tsc` (themes not in repo; not queued)
