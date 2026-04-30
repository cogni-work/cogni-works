# JSON Quote Discipline (canonical)

This is the canonical prompt snippet for any cogni-trends agent that emits structured
JSON containing multilingual prose. Every agent that writes a `.logs/*.json` file or
returns a JSON response from a `Write`-shaped payload MUST inline this block verbatim
into its constraints / output-discipline section, and add the keep-in-sync marker
above it:

```html
<!-- keep in sync with references/json-quote-discipline.md -->
```

Originally introduced for `trend-generator` to fix issue #169
(German typographic opener `„` paired with ASCII closer `"` terminating the JSON
string early). Re-scoped after the same defect class re-appeared in
`trend-report-writer` as issue #182. The text below is the agent-facing copy — paste
verbatim into the agent prompt; do not paraphrase.

---

## JSON String Safety (STRICT)

This applies to every JSON string value you emit in any `.logs/*.json` file or
JSON response. The downstream parsers (`jq`, `python3 -c "json.loads(...)"`,
`prepare-phase3-data.sh`, `validate-enriched-trends.sh`) interpret ASCII U+0022 (`"`)
as the JSON string delimiter. A single stray ASCII `"` inside a prose value
terminates the string early and corrupts the entire file.

- **Quote pairing in prose:** When you need typographic quotes inside a JSON string in DE
  mode, pair them correctly. The German opening quote U+201E (`„`, low-9 quotation mark)
  MUST be closed with U+201D (`"`, right double quotation mark). Never close it with ASCII
  U+0022 (`"`). The same discipline applies to FR/IT/ES (guillemets `« »` U+00AB/U+00BB)
  and any future locale: typography pairs with typography, never with ASCII.
- **ASCII `"` is reserved:** Inside a JSON string value, the bare ASCII double-quote U+0022
  is reserved for the JSON delimiter itself. If ASCII `"` must appear in prose (e.g.
  quoting an English term inside a DE sentence), escape it as `\"`. Better: use the
  locale-appropriate typographic pair instead.
- **Self-check before Write:** Construct the payload as a Python dict and
  serialize with `json.dumps(payload, ensure_ascii=False, indent=2)` rather than
  hand-assembling JSON with string concatenation. `json.dumps` will refuse to produce
  invalid output, so a stray ASCII `"` inside a prose value is impossible by
  construction. If you must template JSON manually, validate the result with
  `json.loads(rendered)` before calling `Write` — and on failure, repair the offending
  ASCII closer (`"`) with U+201D (`"`) for that span and re-validate. This is a hard
  gate, not advisory: one mismatched pair blocks the next phase for the whole project.

This is the same constraint that applies to FR (guillemets `«…»`), IT (typographic
double quotes), and ES (typographic double quotes or `«…»`). Keep prose typography
consistent within each locale; reserve ASCII `"` for the JSON envelope only.

---

## Defense-in-depth

Two scripts implement an idempotent parse-then-repair safety net for the same defect
class, both using the regex `„([^"\\]*)"` → `„\1"`:

- `cogni-trends/skills/trend-scout/scripts/prepare-phase3-data.sh`
  — guards `.logs/trend-generator-candidates.json` (Phase 2 → Phase 3 boundary).
- `cogni-trends/skills/trend-report/scripts/validate-enriched-trends.sh`
  — guards `.logs/enriched-trends-{dimension}.json` (Phase 1 → Phase 2 boundary).

Both run `json.loads` first; only if parsing fails do they attempt the regex
repair, and they only persist the repaired file if it produces valid JSON.
This makes them safe to run on already-valid input (no-op) and prevents a regex
that doesn't actually fix the file from overwriting the original.

## Agents bound to this rule

The following agents must inline the canonical block above:

- `agents/trend-generator.md` — writes `.logs/trend-generator-candidates.json`
- `agents/trend-report-writer.md` — writes `.logs/enriched-trends-{dimension}.json`,
  `.logs/claims-{dimension}.json`, `.logs/section-{dimension}.md`
- `agents/trend-deep-researcher.md` — writes `.logs/deep-research-{trend-slug}.json`
- `agents/trend-report-composer.md` — returns compact JSON response
- `agents/trend-report-investment-theme-writer.md` — returns compact JSON response

When adding a new JSON-emitting trends agent, copy the block above verbatim and
append the agent path to this list.
