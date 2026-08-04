# Interaction language vs. deliverable language

cogni-consult separates two independent language axes. Conflating them forces a
single choice where two are needed — e.g. an engagement whose deliverables are
deliberately English while the consultant and user converse in German.

## The two axes

| Axis | What it controls | Where it lives |
|------|------------------|----------------|
| **deliverable language** | The language of generated artifacts — knowledge-base output, dashboard document language, written deliverables. | The `language` field in `consult-project.json` (ISO 639-1, default `en`). Persisted; set at setup; seeds `--output-language` for the knowledge base. |
| **interaction language** | The language of the user-facing conversation — questions, acknowledgments, status messages, recommendations. | Runtime-derived, **never persisted**. Resolved fresh each session (see below). |

The `language` field is the deliverable axis **only**. Never read it to decide
which language to *converse* in.

## Resolving the interaction language

Resolve it the same way `cogni-help:cogni-issues` does, in this order:

1. **Workspace default** — the `language` key in `.claude/settings.local.json`
   (a natural-language name, e.g. `"english"` or `"german"`) is the workspace
   default. It is authoritative because Claude Code turns it into a `# Language`
   system-prompt section, so it governs the session whether or not any skill
   reads it. Fall back to the `language` field in `.workspace-config.json`
   (ISO 639-1, e.g. `"en"` / `"de"`) for workspaces created before the key
   existed. Do **not** read the workspace `CLAUDE.md` — it is the user's file
   and states nothing about language.
2. **Message-detection override** — if the user's message is written in a
   different language, prefer the user's language. Someone writing in German
   wants a German reply even when the workspace is set to English.
3. **Fallback** — if neither source is present and the message language is
   unclear, default to English.

Conduct the entire conversation in the resolved interaction language. Technical
terms, slugs, skill names, CLI commands, and file names are identifiers: once one
is surfaced at all, it keeps the exact form the system writes it in — never
translated, never re-cased, never Title-Cased. `scope_state` stays `scope_state`;
rendering it as `Scope` is the defect this rule forbids.

That governs *how* an identifier is spelled, not *whether* it belongs on the
surface at all. The whether question is owned by
`references/user-facing-output.md`, where the default answer is **no**.

## Subagents do not inherit it

The `# Language` section reaches the main loop only. A subagent's system prompt
is its own body plus a short notes block and the environment info — no settings
language, no `CLAUDE.md`. Any dispatched agent that produces user-facing prose
must therefore be told the language explicitly: cogni-consult's `SubagentStart`
hook supplies the workspace default to every `consult-*` agent, and a dispatch
that resolved rung 2 passes `interaction_language` in its inputs, which wins
over the hook's default.

## Why they are separate

A consultant can legitimately produce English deliverables for a client while
working through them with a German-speaking stakeholder. One axis cannot express
that. Keeping the deliverable language in `consult-project.json` and deriving the
interaction language at runtime lets each follow its own source of truth.

## What this file does not own

This file owns the language axis and nothing else. A surface can be governed by
the resolved interaction language and still take its copy rules from elsewhere —
notably the `description` of a Bash tool call, which is written in the resolved
language per this file, but whose own copy constraints are owned by section (f)
of `references/user-facing-output.md`. Deliberately not restated here: a fourth
copy of the specifics is the drift this split exists to prevent. Look for a copy
rule there, not here.

The same split governs identifiers: this file says how one is spelled once it
appears, and `references/user-facing-output.md` says whether it may appear.
