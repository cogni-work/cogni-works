---
name: review-brief
description: >
  Review a visual brief from three stakeholder perspectives — design quality, audience
  experience, and usability. Supports all cogni-visual brief types: presentation-brief,
  web-brief, storyboard-brief, and infographic-brief. Returns a structured
  verdict (accept/revise/reject) with prioritized improvements. Use this skill whenever
  the user mentions "review brief", "check brief quality", "assess brief", "brief review",
  "review my presentation brief", "is this brief ready",
  "stakeholder review", "review from audience perspective", "review from design perspective",
  or wants quality assurance on a visual brief before rendering. Also trigger when the user
  asks to review an existing brief after manual edits, or wants to evaluate whether a brief
  is ready for the PPTX, Excalidraw, or Pencil rendering pipeline.
allowed-tools: Read, Glob, AskUserQuestion, Agent
version: 1.0.0
---

# Review Brief Skill

## Purpose

Evaluate a visual brief from three stakeholder perspectives adapted to the brief type, then
optionally apply improvements based on the review verdict. This skill wraps the
`brief-review-assessor` agent with discovery, presentation, and optional revision capabilities.

Visual briefs are the decision point between narrative content and visual rendering — every
headline, layout choice, section sequence, and CTA in the brief directly shapes the final
deliverable. Reviewing at the brief stage is efficient because changes are cheap (edit text)
vs. post-rendering (re-render entire scene).

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `brief_path` | auto-discovered | Path to the brief file. When omitted, searches nearby for `*-brief.md` files. |
| `source_narrative` | auto-discovered | Path to the source narrative (for completeness checks). Optional. |
| `brief_type` | auto-detected | One of: `slides`, `web`, `storyboard`, `infographic`. Auto-detected from brief frontmatter `type:` field or filename pattern. |
| `auto_improve` | `false` | When true, apply CRITICAL and HIGH improvements automatically (max 2 rounds). |
| `audience_context` | none | Optional audience description (industry, role, language) for more targeted evaluation. |

## Workflow

### Step 0: Discover Brief

If `brief_path` is not provided:
1. Search for `*-brief.md` files in the current directory and `cogni-visual/` subdirectory
2. If multiple briefs found, present them via AskUserQuestion and let the user choose
3. If one brief found, confirm it with the user

### Step 1: Parse Brief & Detect Type

Read the brief file. Extract:
- YAML frontmatter (type, version, arc_type, arc_id, theme, language, title)
- Brief body content

Detect `brief_type` from:
1. Explicit parameter (if provided)
2. Frontmatter `type:` field
3. Filename pattern: `presentation-brief.md` → slides, `web-brief.md` → web, `storyboard-brief.md` → storyboard, `infographic-brief.md` → infographic

### Step 2: Discover Source Narrative

If `source_narrative` is not provided, look for it:
1. Check brief frontmatter for `source_path` or `narrative_path`
2. Search sibling directories for narrative files (files with `arc_id` in frontmatter)
3. If not found, proceed without it (skip completeness checks, note the gap)

### Step 3: Launch Review

Launch the `brief-review-assessor` agent with:
- `brief_path`: the brief file
- `brief_type`: detected type
- `source_narrative`: if found
- `audience_context`: if provided
- `round`: 1

### Step 4: Present Results

Parse the assessor's JSON response and present a formatted summary:

```
## Brief Review: {title}

**Verdict: {ACCEPT|REVISE|REJECT}** (Score: {overall_score}/100, Round {round})

### Perspective Scores
| Perspective | Score | Status |
|-------------|-------|--------|
| {name} | {score} | {pass|warn|fail} |
| {name} | {score} | {pass|warn|fail} |
| {name} | {score} | {pass|warn|fail} |

### Improvements Needed
**CRITICAL:**
- {description} (flagged by: {stakeholders})

**HIGH:**
- {description} (flagged by: {stakeholders})

**OPTIONAL:**
- {description} (flagged by: {stakeholders})

### Revision Guidance
{synthesis.revision_guidance}
```

Write the full JSON verdict to `{brief_name}.review.json` alongside the brief file.

### Step 5: Handle Verdict

**On accept:** Report success. The brief is ready for rendering.

**On revise (auto_improve=true):**
1. Apply CRITICAL improvements first, then HIGH improvements
2. For each improvement, edit the brief content surgically — change the specific section,
   headline, layout type, or CTA referenced in the recommendation
3. Re-validate structural integrity (check YAML frontmatter is valid, section counts are
   consistent, no broken references)
4. Re-launch the assessor (round 2)
5. If round 2 accepts or scores 70+ with no CRITICAL issues: write the improved brief
6. If round 2 still has issues: present remaining issues to user, write brief with
   `.review.json` noting unresolved items

**On revise (auto_improve=false):**
Report the findings and let the user decide. Offer:
- "Would you like me to apply the improvements automatically?"
- "Would you like to edit the brief manually and re-run the review?"

**On reject:**
Surface to user via AskUserQuestion. Rejection means fundamental issues that need human
judgment — the skill should not auto-fix rejections.

### Step 6: Write Review Artifact

Write the review verdict JSON to `{brief_stem}.review.json` in the same directory as the brief.

If improvements were applied, also note:
```json
{
  "improvements_applied": 3,
  "improvements_skipped": 1,
  "rounds_completed": 2,
  "final_verdict": "accept",
  "final_score": 87
}
```

## Integration with Story-to-X Skills

This skill can be invoked standalone, but the story-to-X skills also integrate the
brief-review-assessor agent directly into their workflow (between validation and write steps).
When invoked from a story-to-X skill, the review is gated by the `stakeholder_review`
parameter and follows the same assess → improve → re-assess loop.

The standalone skill exists for:
- Reviewing briefs after manual edits
- Reviewing briefs produced in earlier sessions
- Reviewing briefs from other sources
- Running a second review after rendering feedback suggests brief-level issues
