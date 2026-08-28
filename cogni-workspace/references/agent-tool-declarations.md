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
