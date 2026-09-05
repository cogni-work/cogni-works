# Agent tool declarations

Why the `tools:` line of a `cogni-workspace/agents/*.md` file is shaped the way it is. An agent body is
a runtime system prompt, loaded on every dispatch — rationale addressed to a future editor spends
that budget on text the agent cannot act on, so it lives here instead. Cite this file by its
repo-relative path (`cogni-workspace/references/agent-tool-declarations.md`) rather than restating a
rationale inside the agent it explains.

## story-to-infographic

`tools:` mirrors `skills/story-to-infographic/SKILL.md`'s `allowed-tools`. The Skill tool runs that
skill in this agent's own context, so the skill's own tool needs are served by the agent's grant —
which means narrowing `tools:` to `Skill` alone removes capability, not privilege.

An editor who trims the list to what the agent body appears to use directly will break the agent:
the missing tools are exercised by the skill running inside it, not by the body's own prose.

## narrative-adapter

`tools:` covers what `skills/narrative/SKILL.md` needs in its `--format` derivative mode, not what the
agent body writes itself. The body says "DO NOT write files directly" and "your only responsibility is
parameter relay" — both are true of the *body*, and neither licenses trimming the grant: the Skill tool
runs `narrative` in this agent's own context, and that skill's final derivative-mode act is writing the
output file. Dropping `Write` would make every dispatch fail at the write; dropping `Bash` would remove
the skill's own word-count and validation steps.

This was raised as a least-privilege finding on PR #1672 and declined on that basis. The `tools:` line is
byte-identical at base and HEAD, so it is pre-existing rather than introduced — but the reason it should
stay is the one above, not its age.

## narrative-writer

`tools:` is `Read, Write, Glob, Grep, Bash, Skill` — deliberately **without** `AskUserQuestion`, even though
`skills/narrative/SKILL.md`, the skill this agent dispatches through the Skill tool, grants it in its
`allowed-tools`. The omission is not an oversight to be "aligned": this agent is the headless caller, and
it always invokes the skill with `--interactive false`, so the skill never reaches a prompt site (the
Phase 2 arc shortlist, or the Phase 0 materiality gate) while running in this agent's context. A prompt
that did reach a subagent would stall it — there is no user on the other side — which is the defect the
flag was added to close. `cogni-workspace/tests/test-narrative-interactive-flag.sh` case P5 pins the
absence of the grant in the agent body and case P4 pins the flag on the invocation.

An editor who reads the file's own rule ("`tools:` mirrors the skill's `allowed-tools`") and adds the grant
here re-opens the stall while making the agent look more complete. The rule applies to tools the skill
*uses* in this agent's context; a prompt tool the skill is told not to use is not one of them.
