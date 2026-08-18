# Agent tool declarations

Why the `tools:` line of a `cogni-visual/agents/*.md` file is shaped the way it is. An agent body is
a runtime system prompt, loaded on every dispatch — rationale addressed to a future editor spends
that budget on text the agent cannot act on, so it lives here instead. Cite this file by its
repo-relative path (`cogni-visual/references/agent-tool-declarations.md`) rather than restating a
rationale inside the agent it explains.

## story-to-infographic

`tools:` mirrors `skills/story-to-infographic/SKILL.md`'s `allowed-tools`. The Skill tool runs that
skill in this agent's own context, so the skill's own tool needs are served by the agent's grant —
which means narrowing `tools:` to `Skill` alone removes capability, not privilege.

An editor who trims the list to what the agent body appears to use directly will break the agent:
the missing tools are exercised by the skill running inside it, not by the body's own prose.
