# End-of-step dashboard handoff

A work step that ends here ends the same way: regenerate the dashboard, hand the user a link to
it, and move on. This file is the only place those steps are written. Skills cite it; they never
restate it. Which paths end here is a rule, stated below — not every write qualifies.

The reason it is one file: before this existed, the dispatch was copy-pasted into seven skills as
near-identical paragraphs, and they had already drifted. A wording change now lands everywhere at
once.

## Which paths end here

A path ends at the handoff when it is a **generation run**: a multi-step workflow that produces or
regenerates a body of entity content and then finishes the user's work step. It usually dispatches
an agent to do that work. The table below carries the shapes that qualify.

A path does **not** end here when it is a **management operation**: applying a change the user
already named to one entity in front of them, or only reading. The plugin already uses this split
elsewhere — `portfolio-taxonomy` calls its two mode families *creation modes* and *management
modes*, and this is the same line drawn through every skill.

Grade a path with one question: **when it finishes, is there a body of newly written entity content
the user has not yet seen rendered?** If yes, it ends here.

| Path shape | Ends here |
|---|---|
| A skill's main phase workflow | yes |
| Create or generate a set — batch generation, co-development | yes |
| Import, scan, ingest, or promote candidates | yes |
| Regenerate or research-and-rewrite existing entities — repricing, a deep dive | yes |
| A branch that skips forward past the steps leading here, or exits early | yes |
| Edit or delete one named entity | no |
| List, view, or a read-only review pass | no |

The fourth row is why "only paths that create new entities end here" is the wrong rule: repricing a
solution and deep-diving a proposition both rewrite entities that already exist, and both end here.
The sixth and seventh rows are why "every path that writes entity data ends here" is also wrong:
editing and deleting write, across six skills, and correctly do not. Both simpler rules have been
proposed and both are contradicted by the code; neither should be re-proposed.

Excluding management operations is deliberate. An edit is a step inside a session, not the end of
one — the user is already looking at the entity they just changed, the next generation run hands
them a fresh dashboard anyway, and a link after every field edit is noise that trains them to
ignore the link that matters.

**Known coverage gaps.** Some paths qualify under this rule and do not yet carry a pointer:
`features` Bulk Import, Promote Shadow Candidates and Feature Review; `products` Portfolio Review;
and `propositions` Quick Fix, whose sibling Deep Dive already has one. These are tracked coverage
work, not counter-examples to the rule — grade a new path against the rule, not against them. The
test suite's per-skill pointer counts are floors rather than a census, so closing a gap does not
break the guard.

## Dispatch the refresher

Delegate to the `dashboard-refresher` agent with two values:

- `project_dir` — absolute path to the portfolio project directory
- `plugin_root: $CLAUDE_PLUGIN_ROOT`

Do not pass `open_browser`. Omitting it selects the agent's non-opening default, which is what
makes this step safe to run at the end of every work step rather than only when asked.

## Print the link

On a successful result the agent returns a JSON payload carrying a `url` field alongside `path` and
`theme_source`. Print exactly one line containing that returned `url`.

Cite the `url` the agent returned. Never rebuild the `file://` path by hand — the agent owns where
the dashboard lands, and a hand-built path silently rots when that changes.

## When it fails

A non-ok result carries `"status": "error"`. Print one quiet line saying the dashboard could not be
refreshed, and continue the step.

No stack trace, no retry loop, no blocking. The handoff is a courtesy at the end of work the user
already completed; failing to render it must never cost them that work.

## What this is not

Never open a browser from this step.

The mid-flow review offers scattered through the entity skills are a different, deliberate path: at
those checkpoints the user explicitly asked for a window, so those call sites pass the opt-in flag
and open one. This handoff neither replaces nor suppresses them. It is terminal and unconditional —
it runs at the end of the work step whether or not the user asked, and it hands back a link rather
than a window nobody requested.
