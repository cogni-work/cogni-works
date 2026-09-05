# Narrative Validation

The single home of every universal gate a generated narrative must clear. SKILL.md Phase 5 runs this file; an arc contract's `## Validation` section adds only what is specific to that arc and never restates a gate written here. If a rule about a finished narrative is not in this file or in the selected arc's `## Validation`, it is not a gate.

Two kinds of check live here. The **deterministic gates** are mechanical and are run first by `scripts/validate-narrative.py`, which reads the narrative and the arc contract and reports each gate as pass or fail in JSON. The **judged gates** need a reader and are checked by the writer against the draft after the script is green. Fix in priority order — a structural failure makes every later gate meaningless — and re-run the full set after every fix, because a fix can break a gate that passed.

## Deterministic gates (run `validate-narrative.py` first)

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/narrative/scripts/validate-narrative.py" \
  --narrative "${OUTPUT_PATH}" \
  --contract "${CLAUDE_PLUGIN_ROOT}/skills/narrative/references/story-arc/${ARC_ID}/arc-definition.md" --json
```

**Structural (check first):**

- S1 — exactly four `##` headers in the body below the frontmatter. No fifth section, no extra `##` anywhere.
- S2 — each header is byte-equal to the selected arc's `## Headings` cell for the output language, in arc order. Never a paraphrase, never a re-cased or re-punctuated variant.

If S1 or S2 fails, rewrite against the arc's `## Composition` rather than renaming sections: content drafted for the wrong structure reads wrong even under the right headers.

**Content:**

- C1 — total body word count within `[target × 0.85, target × 1.15]`, where `target` is `--target-length` (default 1675).
- C2 — each element's word count within `[proportion × total_lower, proportion × total_upper]`, proportions taken from the arc's `## Composition`.
- C3 — frontmatter carries every required field: `title`, `subtitle`, `arc_id`, `arc_display_name`, `target_length`, `word_count`, `language`, `date_created`, `source_file_count`; `arc_id` equals the contract's.

**Evidence:**

- E1 — at least 15 inline citations, and no more than 25 at the default length, in the form `Claim text<sup>[N](source-file.md)</sup>`. The floor is the same at every length; longer narratives may exceed 25.
- E2 — citation numbers run sequentially from 1 in order of first appearance; a reused source reuses its number.

**Language (when `language: de`):**

- L1 — proper Unicode umlauts and ß throughout body text and headings. Zero ASCII fallbacks (`ae`, `oe`, `ue`, `ss` standing in for ä, ö, ü, ß). Common failures to scan for: "fuer", "ueber", "Aenderung", "groesste", "Fuehrung". File names, slugs and YAML keys stay ASCII.

**Executive TL;DR (for every contract without a Hook segment — all migrated arcs):**

- T1 — the prose between the subtitle and the first `##` is 2-4 sentences and 60-100 words. The band is absolute: it does not scale with `--target-length`, because a summary a reader skims does not get longer when the report does.
- T2 — every `[N]` marker in the TL;DR also appears below the first `##`, with the same source and the same number.

## Executive TL;DR contract

The narrative opens with an answer, not a tension. Between the `*{Subtitle}*` line and the first `##` sits the Executive TL;DR — prose with no heading of its own, so the four-header contract renderers parse is unchanged. Its contract lives here and in SKILL.md Output only; an arc contract states in one line what its TL;DR should emphasize and never restates these rules.

**Shape:** 2-4 sentences, 60-100 words, independent of `--target-length`.

**Answer-first sequence:** the conclusion the reader most needs → the strongest reason for it (the most consequential evidence, shift or mechanism) → the decision implication (what to decide, prioritize or do) → optionally a qualification or urgency, only when uncertainty, timing or the cost of inaction changes the decision.

**Rules:**

- It synthesizes all four elements; it never forces one sentence per element and never previews them in order.
- It introduces no fact, number or recommendation absent from the body.
- Every material number it carries reuses the body's citation — same source, same `[N]`.
- It reads as complete if the reader stops there.
- It is written last, from the finished elements (SKILL.md Pass 2).

**Rejected and rewritten when it:** reads as a teaser with no decision implication; summarizes only the first section; mechanically summarizes all four topics one after another; introduces evidence the body lacks; restates the title; or grows its own heading.

## Judged gates (the writer checks these after the script is green)

**Content:**

- J1 — the title is arc-specific and could not head a different narrative. "Insight Summary" and any generic label fail.
- J2 — the Executive TL;DR follows the answer-first sequence, emphasizes what the arc's `## Composition` TL;DR line says, and none of the rejection modes above applies.
- J3 — the arc's own `## Validation` assertions hold, and the techniques the arc names for each element are visibly applied.
- J4 — transitions between elements follow the arc's transition patterns and read as consequences, not topic labels.

**Execution Fit** (against the Phase 0 brief in `execution-brief.md`, which resolves each field down the same ladder — explicit instruction → project metadata → conversation context → source cues → default):

- F1 — the narrative is recognizably written for the target audience.
- F2 — terminology and explanation depth match the inferred knowledge level.
- F3 — the Executive TL;DR, the emphasis across elements, the implications and the close serve the decision purpose.
- F4 — perspective and pronouns are consistent with the stated voice throughout.
- F5 — geographic emphasis matches the scope: evidence from the named markets leads.
- F6 — where the brief asked for evidence and interpretation to be kept apart, the separation is visible in the prose.
- The brief never infers sensitive personal attributes about the audience; a narrative that reads as if it had fails F1.

**Evidence:**

- J5 — every quantitative claim carries a citation. An uncited number reads as invented.
- J6 — every citation points at a loaded source file; nothing is fabricated, nothing cites a file that was not read. The synthesis document is never cited where a more specific underlying source was supplied.
- J7 — the same source is one citation identity: repeated URLs or duplicate bibliographic entries never become two numbers.

## Citation strategy

Cite only the input source files; fabricated references undermine credibility entirely. Format: `Claim text<sup>[N](source-file.md)</sup>`. Numbering starts at 1 and is sequential by first appearance. Density is highest where the argument leans on numbers — forcing functions, cost calculations, market data — and lowest where it leans on positioning. Every element carries at least one citation.

## Gates this file deliberately does not carry

Two gate families from an earlier workflow layer were dropped rather than moved: an entity-wikilink count and a set of presentation gates tied to a `stats_*` frontmatter block with an inline HTML stats grid. Both bound the narrative to a retired numbered research-project layout that no live producer emits. A narrative is markdown with YAML frontmatter and four sections; anything a renderer needs beyond that is the renderer's job.
