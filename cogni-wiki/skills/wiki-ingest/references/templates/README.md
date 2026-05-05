# Body Templates

Each `.md` file in this directory is a body scaffold for one `type` of page. `wiki-ingest` Step 4 picks the matching template (by `--type`, or by inferring the type from source content) and uses it to generate the page body. The LLM still writes the content; the template fixes the heading shape and the prompted-fields list so downstream queries can rely on uniform structure.

A scaffold is **structure, not content**. It does not pre-fill claims, takeaways, or examples — those must trace back to the source per the "never summarise from memory" rule (`SKILL.md` Failure modes).

## Available templates

| File | Maps to `type` | When to use |
|---|---|---|
| `default.md` | `summary`, `concept`, `entity` | Generic source ingest. The current freeform shape, made explicit. |
| `interview.md` | `interview` | Customer/expert/user interview transcripts. |
| `customer-call.md` | `interview` (variant) | Sales / customer-success / discovery calls. Same `type` as interview, different scaffold and required links. |
| `meeting.md` | `meeting` | Internal or external meeting notes. |
| `decision.md` | `decision` | ADR-style records: context, options, decision, consequences. |
| `retro.md` | `learning` (variant) | Retrospectives: what worked, what didn't, actions. Filed as `type: learning` so it surfaces in lessons-learned queries. |
| `learning.md` | `learning` | Generalised takeaway drawn from one or more sources. |

`customer-call.md` and `retro.md` are scaffold variants, not new types — to keep the `type` enum in `page-frontmatter.md` small. Distinguish them with a tag (`customer-call`, `retro`) so `wiki-query` can still slice by use case.

## Per-template required wikilinks

Each scaffold documents a "Required `[[wikilinks]]`" block at its top. These are the links the body MUST contain for the page to be considered well-formed for that type. They become per-type lint rules once the forward→reverse link contract (issue #210) lands. Until then, treat them as authoring guidance — `wiki-ingest` should surface a warning when a required link is missing.

## Selection rules (Step 4)

1. **Explicit `--type T` was passed.** Use the template that maps to `T`. If the user wants a variant scaffold (e.g. `--type interview` for a customer call), pass `--tags customer-call` so the page is recognisable downstream and pick `customer-call.md`.
2. **No `--type` was passed.** Infer from source heuristics — see `wiki-ingest/SKILL.md` Step 4 for the matrix. Fall back to `default.md` when no signal dominates.
3. **Re-ingest mode.** Preserve the existing page's `type` from frontmatter and pick the matching template; do not switch templates silently.

## Authoring conventions

- Use `{{placeholder}}` syntax for fields the LLM must fill in.
- Use `_(prompt to author)_` lines to explain what content belongs in a section without demanding a specific phrasing.
- Required `[[wikilinks]]` are listed at the top; suggested ones are noted inline.
- Scaffolds keep to the standard ingest body shape: one-sentence summary → key takeaways → details → sources. The type-specific structure lives **inside** the Details section.
