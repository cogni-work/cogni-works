---
name: review-brief
description: Review a visual brief from stakeholder perspectives (design, audience, usability)
argument-hint: "brief_path=/path/to/brief.md"
allowed-tools:
  - Skill
  - Read
  - Glob
  - AskUserQuestion
  - Agent
---

# Review Brief

Review a visual brief from three stakeholder perspectives adapted to the brief type, then
optionally apply improvements based on the verdict.

## Usage

```
/review-brief brief_path=/path/to/presentation-brief.md
/review-brief brief_path=/path/to/big-picture-brief.md auto_improve=true
/review-brief brief_path=/path/to/web-brief.md audience_context="CTO of mid-market energy utility"
/review-brief
```

When no `brief_path` is given, the skill searches for `*-brief.md` files nearby.

## What This Does

Invokes the `review-brief` skill which:
1. Discovers and parses the brief (auto-detects brief type)
2. Launches the `brief-review-assessor` agent with type-adapted perspectives
3. Presents a formatted verdict with prioritized improvements
4. Optionally applies improvements and re-assesses (max 2 rounds)
5. Writes a `.review.json` alongside the brief

## Perspectives by Brief Type

| Brief Type | Perspective A | Perspective B | Perspective C |
|-----------|--------------|--------------|--------------|
| Slides | Communication Designer | Target Audience | Presenter |
| Big Picture | Visual Storyteller | Target Audience | Workshop Facilitator |
| Web | UX Designer | Target Audience | Content Strategist |
| Storyboard | Print Designer | Target Audience | Exhibition Presenter |
| Big Block | Solution Architect | Investment Decision Maker | Sales Engineer |

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `brief_path` | auto-discovered | Path to the brief file |
| `auto_improve` | `false` | Apply improvements automatically |
| `audience_context` | none | Audience description for targeted evaluation |
| `source_narrative` | auto-discovered | Path to the source narrative |

## Action

Invoke the `review-brief` skill with the provided parameters.
