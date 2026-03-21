---
name: diamond-resume
description: |
  Resume, continue, or check status of a Double Diamond consulting engagement.
  Use whenever the user mentions "continue engagement", "resume diamond",
  "pick up where I left off", "diamond status", "what's next", "show progress",
  "where was I", "how far along", "engagement status", or opens a session that
  involves an existing cogni-diamond project — even if they don't say "resume" explicitly.
---

# Diamond Resume

Session entry point for returning to engagement work. This skill orients the consultant by showing where they left off and what to do next — the dashboard view that keeps multi-session engagements on track.

## Core Concept

Diamond engagements span multiple sessions and phases. Without a clear re-entry point, consultants lose context between sessions and waste time reconstructing what happened. This skill bridges that gap: it reads the engagement state, surfaces progress at a glance, and recommends the most valuable next step. The goal is to get the consultant back into productive flow within seconds.

## Workflow

### 1. Find Diamond Engagements

Scan the workspace for diamond engagements:

```bash
find . -maxdepth 3 -name "diamond-project.json" -path "*/cogni-diamond/*"
```

Each match represents an engagement (extract the slug from the directory name). If no engagements are found, say so and suggest the `diamond-setup` skill.

### 2. Select Engagement

- One engagement found — use it automatically.
- Multiple engagements — present them with client name and vision class, ask which one to continue.

### 3. Run Engagement Status

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/engagement-status.sh "<project-dir>"
```

The script returns JSON with engagement details, phase state, plugin status, methods used, decisions, and recommended next actions.

### 4. Present Status Dashboard

Show a concise, scannable dashboard. Lead with the engagement name and client, then the phase progress:

**Acme Cloud Portfolio Expansion** (acme-cloud-expansion)
Client: Acme Cloud Services | Vision: strategic-options | Language: en

| Phase | Status | Files | Plugin Projects |
|-------|--------|-------|-----------------|
| Discover | complete | 12 | research: acme-landscape, tips: b2b-ict/acme, portfolio: acme-cloud |
| Define | in-progress | 3 | claims: verified 8/12 assumptions |
| Develop | pending | 0 | — |
| Deliver | pending | 0 | — |

After the table:

- **Current phase** — translate the phase and status into plain language
- **Methods used** — list methods applied so far from the method log
- **Key decisions** — surface recent decisions from the decision log
- **Plugin projects** — for each non-null plugin_ref, check if the project exists and show brief status
- **Gaps** — note incomplete prerequisites for the next phase

Keep the tone warm and oriented toward action — this is a welcome-back moment, not a status report. The consultant should feel oriented, not overwhelmed.

### 5. Recommend Next Action

Present the recommended next action from the status output:

> **Recommended next step**: Continue the Define phase — 4 assumptions still unverified. Run `diamond-define` to complete assumption verification and synthesize the problem statement.

Offer to proceed with the recommendation immediately.

If all phases are complete, congratulate the consultant and suggest `diamond-export` for the final deliverable package.

## Phase Reference

| Phase | State | What It Means |
|-------|-------|---------------|
| Discover | pending | No research started — begin with diamond-discover |
| Discover | in-progress | Research underway but not yet synthesized |
| Discover | complete | Problem landscape mapped, ready for convergence |
| Define | pending | Ready to converge on the core challenge |
| Define | in-progress | Verifying assumptions, synthesizing problem |
| Define | complete | Problem statement framed, HMW questions ready |
| Develop | pending | Ready to generate solution options |
| Develop | in-progress | Options being explored and modeled |
| Develop | complete | Solution options evaluated, ready for convergence |
| Deliver | pending | Ready to validate and package outcomes |
| Deliver | in-progress | Verification and business case in progress |
| Deliver | complete | All phases done — run diamond-export |

## Multi-Session Design

Diamond engagements naturally span multiple sessions. Each phase involves significant work — desk research, trend analysis, stakeholder synthesis, option modeling — that benefits from focused sessions. This skill is the recommended re-entry point after breaks.

When presenting the status summary, acknowledge what the consultant accomplished in previous sessions if timestamps suggest recent productive work. This continuity helps consultants feel their work persists across sessions.

## Language

- **Communication Language**: Read `diamond-project.json` for the `language` field. If present, communicate in that language (status messages, instructions, recommendations). Technical terms, skill names, and CLI commands remain in English.
