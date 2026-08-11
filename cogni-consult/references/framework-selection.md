# Framework Selection

How `consult-action-fields` chooses each deliverable's `chosen_framework` when it
plans a field's deliverable set in step 4. This document is authoritative for the
top-5 shortlist, the consulting-partner recommendation and consultant
confirmation, the `combo:<slugA>+<slugB>` storage form, the `framework-selection`
decision-log entry, and the write-once idempotency guard. Deciding *when* to plan
a field's deliverable set, and the manifest entry the choice is written into,
stay in the skill body.

**Select the structuring framework for each deliverable.** Before writing each
entry, choose its `chosen_framework` — the shape the deliverable's argument will
take. Read `$CLAUDE_PLUGIN_ROOT/references/frameworks-registry.md` (once per
session — it covers every deliverable), then for each deliverable being planned:

1. **Shortlist the top-5.** For each deliverable being planned, rank the
   applicable frameworks and take the five strongest — this top-5 is per
   deliverable, not the `1-3 deliverables` count from the start of this step.
   Rank by combining the registry's deliverable-type and field-type
   **affinity** columns with your own judgment of the field's `framing` and the
   engagement's key question (from `scope/` / `consult-project.json`).
2. **Present each candidate** with its one-line structure signature from the
   registry's `Structure signature` column, so the consultant sees what each
   shape commits the deliverable to.
3. **Recommend in the consulting-partner's voice.** Act as the
   `consulting-partner` persona
   (`$CLAUDE_PLUGIN_ROOT/references/personas/consulting-partner.json`) — the
   advisor who knows which frameworks fit which problem shape — and recommend one
   framework, or a combination of two, **with an explicit rationale** tying the
   choice to the field's so-what. A combination is stored as
   `combo:<slugA>+<slugB>`.
4. **Confirm with the consultant** before storing — the recommendation is a
   starting point, not a constraint; the consultant may pick any registry slug,
   or name a new structure (give it a clear kebab-case slug like any other).
5. **Store the choice.** Set `chosen_framework` on the deliverable's `field.json`
   entry to the chosen registry slug, the `combo:<slugA>+<slugB>` string, or
   `null` if the consultant defers, and append a `framework-selection` entry to
   the engagement's `.metadata/decision-log.json` `decisions[]` array (the same
   array that already holds gap-check entries), discriminated by
   `"kind": "framework-selection"`:

```json
{
  "id": "<next decision id>",
  "kind": "framework-selection",
  "action_field": "<field-slug>",
  "deliverable": "<deliverable-slug>",
  "candidates_presented": ["pyramid-principle", "scqa", "..."],
  "chosen": "pyramid-principle",
  "is_combination": false,
  "rationale": "<why this framework fits the field's so-what>",
  "timestamp": "<ISO timestamp>"
}
```

`candidates_presented[]` is the top-5 slugs you shortlisted, `chosen` mirrors the
value written to `chosen_framework`, and `is_combination` is `true` only when
`chosen` is a `combo:` string.

**Idempotency — never silently overwrite a chosen framework.** `chosen_framework`
is written once at creation and read-only thereafter. On a re-run over a
deliverable whose entry already carries a non-null `chosen_framework`, surface the
existing choice and require explicit reconfirmation from the consultant before
changing it — never overwrite it silently, and append no new decision-log entry
unless the consultant explicitly chooses to change it. When the consultant does
change it, append a fresh `framework-selection` entry (the decision-log is
append-only) so both the prior choice and the change stay on the trail.
