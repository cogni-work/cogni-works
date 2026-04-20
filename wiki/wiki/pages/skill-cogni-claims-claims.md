---
id: skill-cogni-claims-claims
title: "cogni-claims:claims (skill)"
type: entity
tags: [cogni-claims, claims, verification, skill, orchestrator, cobrowse, webfetch]
created: 2026-04-17
updated: 2026-04-20
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-claims/skills/claims/SKILL.md
status: stable
related: [plugin-cogni-claims, skill-cogni-claims-claim-entity, agent-cogni-claims-claim-verifier, agent-cogni-claims-source-inspector, concept-claim-lifecycle, concept-claims-propagation]
---

> The claim-verification orchestrator inside [[plugin-cogni-claims]]. Six modes (submit, verify, dashboard, inspect, resolve, cobrowse) drive the full lifecycle defined by [[skill-cogni-claims-claim-entity]], with WebFetch for automated verification and claude-in-chrome for interactive recovery.

`claims` is the user-facing skill for the plugin — triggered by `/claims` and by any phrasing that implies fact-checking, citation review, or source verification. It accepts claims from other plugins or the user, dispatches verifier agents, renders the status dashboard, launches source inspection, walks the user through resolution, and recovers unreachable sources via user-assisted browsing.

## Key takeaways

- **Six modes, one skill.** `submit` (register new claims), `verify` (fetch sources and compare), `dashboard` (status overview grouped by state), `inspect` (drill into one claim's evidence), `resolve` (user decides how to handle a deviation), `cobrowse` (interactive recovery for unreachable sources). Intent-to-mode mapping is in the skill body — "check my claims" → verify, "what's the status" → dashboard.
- **Parallelized verification by source URL.** Claims citing the same URL are grouped; one [[agent-cogni-claims-claim-verifier]] agent per unique URL, all launched in parallel. This is the main performance lever.
- **WebFetch only for automated verification.** No browser fallback in the verifier path — if WebFetch fails (403, timeout, paywall, anti-bot), the claim goes to `source_unavailable`. The browser fallback is a separate, explicit mode (cobrowse), not a silent retry.
- **Cobrowse mode recovers human-gated sources.** The user dismisses cookie banners, logs in, scrolls to load dynamic content while Claude reads and verifies via [claude-in-chrome](https://github.com/anthropics/claude-in-chrome). Records `fetch_method: "cobrowse_interactive"` to distinguish from automated fetches.
- **Inspect launches source-inspector automatically.** When the user wants to see evidence in context, [[agent-cogni-claims-source-inspector]] opens the source in the browser, locates the passage, and returns text + surrounding context + screenshot. Don't make the user request it — just do it.
- **5-dimension comparison.** Verifier agents and cobrowse inline verification both apply: accuracy (words/numbers match), inference (conclusions supported), completeness (context preserved), currency (data still current), agreement (source supports/contradicts/silent).
- **Conservative detection is the default posture.** False positives erode trust; when the comparison is ambiguous, not flagging is the safer choice. Explanations always hedge ("the source appears to say...") — see [[skill-cogni-claims-claim-entity]] for why.

## What this skill does NOT do

- **Generate claims** — that's the submitting plugin's job ([[plugin-cogni-research]] `verify-report`, [[plugin-cogni-portfolio]] `portfolio-verify`, [[plugin-cogni-trends]] `trend-report`, [[plugin-cogni-consulting]] `consulting-deliver`).
- **Make editorial decisions** — the user always has final say on resolutions.
- **Present findings as verdicts** — every finding is an assessment for the user to review.

## Verify-mode pipeline

1. Select claims (specific `--id` or all `unverified`).
2. Group by `source_url` — each URL fetched exactly once.
3. Pre-flight check for claude-in-chrome availability (affects inspect/cobrowse, not verify itself).
4. Dispatch [[agent-cogni-claims-claim-verifier]] agents in parallel — one per unique URL.
5. Collect results — update `claims.json`: `verified` | `deviated` | `source_unavailable`.
6. Summarize counts; if `source_unavailable` claims exist, suggest `/claims cobrowse`; if `deviated` with severity ≥ medium, proactively offer source inspection.

## Cobrowse-mode pipeline

1. Pre-requisite: claude-in-chrome must be available (no fallback).
2. Filter to `source_unavailable` claims; group by URL.
3. Session overview to the user — what's recoverable, what the user's role is.
4. Per-URL loop: open new tab, navigate, classify page state (content visible, login, cookie barrier, 404, empty), wait for user "ready", extract content, verify inline (same 5-dimension comparison), present per-URL results, save to `claims.json` with `fetch_method: "cobrowse_interactive"`.
5. Session summary — recovered / still unavailable / skipped.

## Cross-plugin integration

| Plugin | Integration point |
|--------|-------------------|
| [[plugin-cogni-research]] | `verify-report` calls this skill in submit mode with extracted claims |
| [[plugin-cogni-portfolio]] | `portfolio-verify` submits web-sourced entity claims; reads `entity_ref` back to propagate corrections |
| [[plugin-cogni-trends]] | `trend-report` submits all sourced assertions post-generation |
| [[plugin-cogni-consulting]] | `consulting-deliver` runs final verification pass before producing deliverables |

Claims propagation — how corrections flow back to the originating entity files — is covered in [[concept-claims-propagation]].

## Guiding principles

These principles reflect the fundamental nature of LLM-based verification, not style preferences:

- **Conservative detection** — false positives damage trust more than false negatives.
- **Evidence-first** — every finding ships with the `source_excerpt` so the user can judge it in seconds.
- **Honest about uncertainty** — "appears to diverge" not "is wrong" — the system makes probabilistic assessments.
- **User authority** — auto-resolving would be presumptuous and risky.
- **No silent failures** — `source_unavailable` is surfaced, never collapsed into `verified`.

## Reference files

- `references/verification-protocol.md` — quality principles, re-verification rules, epistemic-humility rationale
- `references/dashboard-format.md` — complete dashboard layout spec (section ordering, truncation, sorting)
- `scripts/claims-store.sh` — workspace init, ID generation, URL hashing, claim counting

## Sources

- [SKILL.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/cogni-claims/skills/claims/SKILL.md)
