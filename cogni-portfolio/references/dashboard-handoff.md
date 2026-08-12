# End-of-step dashboard handoff

Every skill that writes portfolio entities ends its work step the same way: regenerate the
dashboard, hand the user a link to it, and move on. This file is the only place those steps are
written. Skills cite it; they never restate it.

The reason it is one file: before this existed, the dispatch was copy-pasted into seven skills as
near-identical paragraphs, and they had already drifted. A wording change now lands everywhere at
once.

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
