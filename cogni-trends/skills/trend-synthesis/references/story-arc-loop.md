# Story-Arc Review Loop

A closed review loop that scores the assembled `tips-trend-report.md` against
the `cogni-narrative` story-arc quality gates and dispatches targeted
revisions until the report passes — or until the iteration cap is hit and the
gap is logged transparently.

This is the storytelling counterpart to `verify-trend-report` (which checks
factual claims): it answers "does the report *tell a story*?", not "is the
evidence sound?".

## Why

The canonical TIPS skeleton produces a structurally correct report — 4 H2
dimensions, N H3 theme-cases, a Capability Imperative closer. Structural
correctness does not guarantee that the prose lands as a CxO narrative. The
review loop closes that gap by treating `cogni-narrative:narrative-reviewer`
as an external storytelling expert: it reads the assembled report, scores it
against arc gates, and returns the top three improvements. Phase 2.8 maps
those improvements to the artefacts that produced them and re-dispatches only
the affected writer/composer agents — cheap, targeted retries.

## When the loop runs

- Default: enabled on every `/trend-synthesis` run after Phase 2.7.
- Skip: set `tips-project.json.skip_story_arc_review = true`, OR pass
  `--no-story-review` on the skill invocation. Skipping is recorded in
  finalization metadata as `story_arc_final_status: "skipped"`.

## Configuration

| Field | Default | Source |
|-------|---------|--------|
| `STORY_ARC_ID` | `smarter-service` | `tips-project.json.story_arc_id`, else default |
| `PASS_THRESHOLD` | `75` | constant — matches narrative-review B-grade boundary |
| `MAX_ATTEMPTS` | `3` | 1 review + up to 2 revision passes |
| `LANGUAGE` | inherited | manifest language (`de` / `en`) |

`PASS_THRESHOLD = 75` is deliberately set at the B/C-grade boundary in the
narrative-review rubric. Reports above 75 read as publication-ready or
near-ready; below 75, structural or evidence gaps tend to surface that no
amount of polish downstream will hide.

## Loop

```text
attempt = 1
best_scorecard = null

while attempt <= MAX_ATTEMPTS:
    invoke cogni-narrative:narrative-reviewer agent with:
        source_path = "{PROJECT_PATH}/tips-trend-report.md"
        arc_id      = STORY_ARC_ID
        language    = LANGUAGE

    persist returned JSON to .logs/story-arc-scorecard-iter-{attempt}.json
    persist {source-dir}/narrative-review.md (written by the skill) to
        .logs/story-arc-scorecard-iter-{attempt}.md

    if scorecard.success
       and scorecard.overall_score >= PASS_THRESHOLD
       and no gate in scorecard.gates is "fail":
        best_scorecard = scorecard
        break

    if best_scorecard == null or scorecard.overall_score > best_scorecard.overall_score:
        best_scorecard = scorecard

    if attempt == MAX_ATTEMPTS:
        WARN — see "Cap behaviour" below
        break

    # Targeted revision
    route(scorecard.top_improvements) → set of (artefact, agent) to redispatch
    re-dispatch only those agents
    re-run Step 2.6 (assemble) — rewrites tips-trend-report.md in place
    attempt += 1

copy best_scorecard's iteration file to .logs/story-arc-final-scorecard.md
```

## Routing top_improvements → artefact

The `narrative-reviewer` returns up to 3 improvement strings. Map them by
keyword to the artefact whose composer/writer must be re-dispatched. When a
single improvement matches multiple artefacts, redispatch all of them in one
parallel turn.

| Cue in `top_improvements[i]` | Re-dispatch target | Agent |
|------------------------------|--------------------|-------|
| "Why Now", "opener", "executive summary", "lead", "open ", "hook" | `report-header.md` | exec-summary writer (Step 2.3, inline orchestrator) |
| "{dimension name}" present + "narrative", "voice", "flow", "transition", "primer" | `macro-section-{dimension}.md` | `cogni-trends:trend-report-composer` |
| "theme", "case", "Stake", "Move", "Cost-of-Inaction", investment-theme name | `theme-case-{theme_id}.md` for the named theme(s) | `cogni-trends:trend-report-investment-theme-writer` |
| "Capability Imperative", "synthesis", "closer", "ending" | `report-synthesis.md` | synthesis writer (Step 2.5, inline orchestrator) |
| "citation", "evidence", "claim", "uncited" | the macro-section whose dimension is named, OR the theme-case for the named theme | composer / theme writer accordingly |
| "structure", "ordering", "header" without further cue | re-run Step 2.6 only (assembly) — usually a concatenation glitch |
| Anything else | log as `unrouted_improvement` in the scorecard log; do NOT redispatch on that line alone |

After redispatch, run Step 2.6 (assembly) again. The claims registry from
Step 2.4 and the merged claims JSON from Step 2.7 are NOT regenerated —
they remain valid because revisions only touch prose, never claim IDs or
their bindings.

## Cap behaviour

When `attempt == MAX_ATTEMPTS` and the threshold still hasn't been crossed:

- WARN with this exact line (using the localized `STORY_ARC_CAP_WARNING` label
  from `i18n/labels-{en,de}.md`):

  ```
  Story-arc loop hit the iteration cap. Best score: {best_scorecard.overall_score}/100 ({best_scorecard.grade}).
  See .logs/story-arc-final-scorecard.md for the top improvements that did not converge.
  Proceeding with finalization — verify-trend-report still recommended.
  ```

- Set `story_arc_final_status: "warn-cap-hit"` in metadata.
- Do NOT halt. The report is still produced; the user owns the decision to
  ship as-is or hand-edit before publishing.

## Finalization metadata

Phase 3.1 mirrors the loop result into `trend-scout-output.json`:

```json
{
  "story_arc_score": 82,
  "story_arc_grade": "B",
  "story_arc_iterations": 1,
  "story_arc_final_status": "pass",
  "story_arc_id": "smarter-service",
  "story_arc_unrouted_improvements": []
}
```

`story_arc_final_status` values:

| Value | Meaning |
|-------|---------|
| `pass` | Threshold met, no gate marked `fail`. |
| `warn-cap-hit` | Cap reached without crossing threshold; best-attempt scorecard persisted. |
| `skipped` | User opted out via flag or project config. |
| `error` | Reviewer agent returned `success: false`; loop aborted, no metric reliable. |

## Logged artefacts

Inside `{PROJECT_PATH}/.logs/`:

- `story-arc-scorecard-iter-{N}.md` — markdown scorecard per attempt
- `story-arc-scorecard-iter-{N}.json` — JSON summary per attempt
- `story-arc-final-scorecard.md` — copy of the best/passing iteration's MD
- `story-arc-revisions.log` — one line per revision dispatch:
  `iter={N} target=macro-section-digitales-fundament reason="evidence: uncited claim p3"`

## Error handling

| Scenario | Action |
|----------|--------|
| `cogni-narrative:narrative-reviewer` agent unavailable | WARN once, set `story_arc_final_status: "skipped"`, continue |
| Reviewer returns `success: false` | persist error, set status `error`, continue (do not block report) |
| Routing matches 0 artefacts for all 3 improvements | log `unrouted_improvement` lines; if iteration would be a no-op, break early and surface the scorecard as `warn-cap-hit` rather than burning attempts |
| Revision dispatch fails (composer/theme writer returns `ok: false`) | retry once per the Phase 2 rules, then surface as `warn-cap-hit` with the last good scorecard |
| `STORY_ARC_ID` not found in `cogni-narrative` arc registry | the reviewer skill itself flags it; we record `story_arc_final_status: "error"` and continue |

## Why a 3-attempt cap

Three attempts is the smallest budget that lets the loop demonstrate it can
actually *improve* the report (you need at least one revision pass after the
initial review to prove convergence) while staying cheap on tokens. Past
three, observed gains plateau because the same gate findings tend to recur —
that's a signal the underlying inputs (enriched-trends, value-model) are
weak, not that more rewriting will help.
