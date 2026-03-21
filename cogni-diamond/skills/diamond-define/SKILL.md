---
name: diamond-define
description: |
  Execute the Define phase of a Double Diamond engagement — converge from discovery insights
  to a clear problem statement. Verifies assumptions via cogni-claims and guides the consultant
  through synthesis methods like affinity clustering and HMW framing.
  Use whenever the user mentions "define the problem", "converge", "problem statement",
  "frame the challenge", "assumption check", "how might we", "define phase",
  or wants to synthesize discovery findings into a focused problem — even if they
  don't say "define" explicitly.
---

# Diamond Define — Converge on the Challenge

Synthesize discovery findings into a clear, actionable problem statement. This is the convergence half of Diamond 1 — the goal is to narrow from a broad evidence base to the core challenge worth solving.

## Core Concept

Define is about making choices. Discovery surfaced many themes, tensions, and opportunities. Define forces the consultant and client to decide: "Of everything we learned, what is the one challenge that, if solved, would create the most value?" This requires both analytical rigor (verifying assumptions) and creative synthesis (reframing the problem).

The outputs — a problem statement and HMW questions — become the brief for Diamond 2. Getting the problem framing wrong means solving the wrong problem, no matter how elegant the solution.

## Prerequisites

- Discovery phase should be complete or substantially progressed (the phase-gate-guard hook will warn if not)
- Discovery synthesis (`discover/synthesis.md`) should exist — the starting input for Define

## Workflow

### 1. Load Context

Read diamond-project.json and `discover/synthesis.md`. Review the themes, surprises, and tensions from Discovery.

Update phase state:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" define in-progress
```

### 2. Propose Define Methods

Present the convergence plan:

**Assumption Verification** (plugin-powered):
- Extract key assumptions from the discovery synthesis
- Submit to cogni-claims for verification against cited sources
- Flag unsupported or contradicted assumptions

**Guided Convergence Methods** (interactive):

| Method | Purpose | Reference |
|---|---|---|
| Affinity Clustering | Group discovery themes into clusters | `references/methods/affinity-clustering.md` |
| HMW Synthesis | Reframe clusters as "How Might We" questions | `references/methods/hmw-synthesis.md` |
| Assumption Mapping | Map and prioritize assumptions by risk | `references/methods/assumption-mapping.md` |

Ask: "I recommend starting with assumption verification, then affinity clustering, then HMW synthesis. Want to adjust the approach?"

### 3. Assumption Verification

Extract 10-20 key assumptions from the discovery synthesis. These are factual claims that underpin the emerging problem framing.

Present them to the consultant:

> **Assumptions extracted from Discovery:**
> 1. "Mid-market cloud spend in DACH will grow 18% YoY through 2028" — from desk research
> 2. "No incumbent offers unified monitoring across hybrid environments" — from competitive analysis
> 3. ...
>
> Any to add, remove, or reframe?

After confirmation, dispatch to cogni-claims:
- Submit assumptions as claims with source references from discovery
- Run `claims:verify` to check against cited sources
- Present results: verified, deviated, source unavailable

Save verified/deviated results to `define/assumptions.json`.

Key decision point: deviated assumptions may require revisiting the discovery synthesis. Ask the consultant how to handle each deviation — correct, investigate further, or accept the risk.

### 4. Affinity Clustering (Guided)

Read `$CLAUDE_PLUGIN_ROOT/references/methods/affinity-clustering.md` and guide the consultant:

1. List all discovery themes (from synthesis.md) as individual items
2. Propose initial groupings based on thematic similarity
3. Ask the consultant to review, merge, split, or relabel clusters
4. Name each cluster with a descriptive label
5. Rank clusters by relevance to the engagement vision

Output: 3-7 named theme clusters, ordered by priority.

### 5. HMW Synthesis (Guided)

Read `$CLAUDE_PLUGIN_ROOT/references/methods/hmw-synthesis.md` and guide the consultant:

1. For each top-priority cluster, draft 2-3 "How Might We" questions
2. Present HMW questions for refinement — too broad is useless, too narrow is premature
3. Converge on 3-5 HMW questions that frame the problem space for Diamond 2

Save to `define/hmw-questions.md`.

### 6. Problem Statement

Synthesize the verified assumptions, clusters, and HMW questions into a problem statement:

**Structure**:
- **Context**: What is the situation? (from Discovery)
- **Tension**: What is the core conflict or gap?
- **Question**: What needs to be resolved? (from HMW)
- **Constraints**: What boundaries apply? (from engagement vision)

Draft the problem statement and present for consultant review. Iterate until confirmed.

Save to `define/problem-statement.md`.

### 7. Log and Transition

Update method log and decision log with key choices made during Define.

Present the Define summary:

> **Define phase complete.**
> - Assumptions: N verified, N deviated, N unresolved
> - Theme clusters: [list top 3]
> - HMW questions: [list top 3]
> - Problem statement: [one-sentence version]
>
> Ready to move to Diamond 2? The Develop phase will generate solution options for these HMW questions.

Mark Define complete:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" define complete
```

## Important Notes

- Define is the most collaborative phase — expect heavy back-and-forth with the consultant
- Never auto-generate the problem statement without consultant input
- Deviated assumptions are valuable signals, not failures — they refine understanding
- Record key decisions in the decision log (why one framing was chosen over another)
- If discovery was thin in some areas, note this as a known limitation rather than blocking progress
