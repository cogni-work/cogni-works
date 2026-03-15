---
name: research-story
description: |
  Research-to-narrative story pipeline: transforms completed research synthesis into a polished
  executive narrative with story arc structure, copywriting polish, and optional derivatives.
  Chains cogni-research synthesis → citation bridge → cogni-narrative → cogni-copywriting.
  Use when the user says "polish the research", "create story from research", "research story",
  "executive narrative from research", "story arc from research", "narrative from findings",
  "create a compelling narrative", or wants research output that reads like a compelling executive
  brief rather than a raw report. Prerequisite: synthesis must be complete.
---

# Research Story Pipeline

Transform completed research synthesis into a polished executive narrative with story arc structure — all in one command.

## Quick Example

**User**: "Create a story from the research on edge AI in manufacturing quality control"

**Result**: A polished ~1,675-word executive narrative with story arc structure, produced via:
1. Synthesis check → verify `synthesis/research-hub.md` exists and synthesis is complete
2. Citation bridging → per-source files for narrative traceability
3. Story arc transformation → `synthesis/insight-summary.md` (4-element arc, inline citations)
4. Executive polish → arc-aware copywriting with readability scoring
5. Optional derivatives → executive brief, talking points, one-pager

## Prerequisites

- cogni-research synthesis must be complete (`synthesis_complete: true` in sprint-log)
- cogni-narrative plugin installed (story arc transformation)
- cogni-copywriting plugin installed (executive polish)

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `--project-path` | Yes | — | Project directory containing completed synthesis |
| `--arc-id` | No | auto-detect | Story arc override. See arc table below |
| `--language` | No | `en` | Output language: `en` or `de` |
| `--target-length` | No | `1675` | Narrative word count target (800-4,000 range) |
| `--gates` | No | `auto` | Quality gate mode: `auto`, `interactive`, `skip` |
| `--derivatives` | No | `none` | Comma-separated: `executive-brief`, `talking-points`, `one-pager`, `all` |

## Available Story Arcs

| Arc ID | Elements | Best For |
|--------|----------|----------|
| `corporate-visions` | Why Change → Why Now → Why You → Why Pay | B2B positioning, market research, sales |
| `technology-futures` | Emerging → Converging → Possible → Required | Innovation scouting, R&D strategy |
| `competitive-intelligence` | Landscape → Shifts → Positioning → Implications | Competitive analysis, threat assessment |
| `strategic-foresight` | Signals → Scenarios → Strategies → Decisions | Long-range planning, scenario analysis |
| `industry-transformation` | Forces → Friction → Evolution → Leadership | Industry analysis, regulatory impact |
| `trend-panorama` | Forces → Impact → Horizons → Foundations | Trend-scout output, TIPS reports |

## References Index

| Reference | Read When |
|-----------|-----------|
| `references/arc-selection-heuristics.md` | Phase 3 — auto-detecting arc from research content |
| `references/pipeline-config.md` | Phase 1 — default thresholds and gate behavior |

---

## Workflow

```text
Phase 1        Phase 2          Phase 3        Phase 4         Phase 5        Phase 6       Phase 7
Synthesis --> Citation    -->  Arc       -->  Narrative  -->  Quality   -->  Polish   -->  Derivatives
Check         Bridge          Selection      (delegated)     Gate           (delegated)   + Finalize
```

### Phase 1: Check Synthesis

Verify that cogni-research synthesis is complete before proceeding. This skill does NOT run research — it transforms already-completed synthesis output.

**Checks:**
1. Read the project's sprint-log and verify `synthesis_complete: true`
2. Verify `synthesis/research-hub.md` exists and has reasonable content (> 500 words)
3. If synthesis is NOT complete, stop and tell the user: "Synthesis must be complete before running research-story. Run `/synthesis` first."

**Resumability**: If `synthesis/pipeline-state.json` already exists, read it and resume from the first incomplete phase. Present resumption status to user before continuing.

After verification, update `synthesis/pipeline-state.json` with synthesis_check phase completion.

### Phase 2: Citation Bridge

The research hub uses `[Source: Publisher](URL)` inline citations. cogni-narrative expects source files it can reference as `<sup>[N](file.md)</sup>`. This bridge creates per-source files that preserve the full audit trail: narrative citation → source file → original URL → source entity enrichment.

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/bridge-citations.py" \
  --project-path "${PROJECT_PATH}" --json
```

This creates `synthesis/narrative-input/` containing:
- `report-for-narrative.md` — research hub with `[source-NN-slug.md]` markers
- `sources/source-01-publisher-slug.md` — per-source files with publisher name, URL, and enriched metadata (reliability score, APA citation, publisher type) from `05-sources/data/` entity cross-reference

Verify: JSON output shows `sources_extracted > 0`. If zero sources, proceed with a warning — the narrative will have fewer citations but can still produce a useful output.

### Phase 3: Arc Selection

The story arc shapes the entire narrative structure. The wrong arc buries the insights that matter most for the audience.

**Read**: `references/arc-selection-heuristics.md`

**Selection priority:**
1. If `--arc-id` provided, use it directly
2. Auto-detect from research hub content using keyword density against arc signal sets (see heuristics reference)
3. Fallback: `corporate-visions`

**Gate behavior:**
- `--gates=interactive`: Present detected arc with rationale and alternatives via AskUserQuestion. Accept user confirmation or override.
- `--gates=auto`: Use detected arc without confirmation.
- `--gates=skip`: Use detected arc without confirmation.

Store: `arc_id`, `arc_display_name`, `detection_reason` in `synthesis/pipeline-state.json`.

### Phase 4: Narrative Transformation

Delegate to cogni-narrative's narrative skill. This transforms the bridged research content into a 4-element story arc narrative with proportional word allocation and inline citations.

```
Invoke cogni-narrative:narrative with:
  --source-path synthesis/narrative-input/
  --arc-id <selected-arc>
  --language <language>
  --output-path synthesis/insight-summary.md
  --research-question "<original topic>"
  --target-length <target-length>
```

If delegating via agent, use `cogni-narrative:narrative-writer`:
```
Agent(cogni-narrative:narrative-writer,
  --source-path synthesis/narrative-input/
  --arc-id <selected-arc>
  --language <language>
  --output-path synthesis/insight-summary.md
  --research-question "<topic>"
  --target-length <target-length>)
```

Verify output:
- `synthesis/insight-summary.md` exists
- Frontmatter contains `arc_id` (this is the integration contract with cogni-copywriting)
- Word count within expected range (target +/-15%)
- Citation count >= 15
- Exactly 4 `##` headers matching arc element names

### Phase 5: Narrative Quality Gate

Delegate to cogni-narrative's review skill to produce a structured scorecard (0-100 score, A-F grade).

```
Invoke cogni-narrative:narrative-review with:
  --source-path synthesis/insight-summary.md
```

**Gate behavior by mode:**

| Mode | Behavior |
|------|----------|
| `auto` | Run review. Score >= 70 (C+): proceed. Score < 70: re-invoke narrative once with adjusted parameters, then re-review. If still < 70: proceed with quality warning. |
| `interactive` | Present scorecard to user. Ask whether to proceed, re-generate, or change arc. |
| `skip` | Skip review entirely. |

### Phase 6: Executive Polish

Delegate to cogni-copywriting's copywriter skill. The `arc_id` field in `insight-summary.md`'s YAML frontmatter automatically activates arc-aware preservation mode — no special configuration needed.

```
Invoke cogni-copywriting:copywriter with:
  file_path=synthesis/insight-summary.md
  scope=full
  impact_level=high
```

Arc-aware mode applies per-element polishing techniques:
- Why Change / Landscape / Forces → PSB + Ratio framing
- Why Now / Shifts / Friction → Forcing Functions + Before/after contrast
- Why You / Positioning / Evolution → IS-DOES-MEANS + You-Phrasing
- Why Pay / Implications / Leadership → Compound Impact calculation

The copywriter preserves: arc structure (4 `##` headers), citation format and count, word count targets, and frontmatter metadata.

**Optional multi-persona review** (when `--gates != skip`):

After polishing, invoke the copy-reader for stakeholder perspective validation:
```
Invoke cogni-copywriting:copy-reader with:
  FILE_PATH=synthesis/insight-summary.md
  PERSONAS=executive,technical,marketing
  AUTO_IMPROVE=true
```

This runs 3 parallel persona agents, synthesizes cross-persona feedback, and applies one auto-improvement loop for CRITICAL/HIGH priority issues.

### Phase 7: Derivatives + Finalization

**Derivatives** (when `--derivatives` is not `none`):

For each requested format, delegate to cogni-narrative's adapt skill (these are independent and can run in parallel):

```
Invoke cogni-narrative:narrative-adapt with:
  --source-path synthesis/insight-summary.md
  --format <executive-brief|talking-points|one-pager>
```

| Format | Output | Length |
|--------|--------|--------|
| `executive-brief` | `synthesis/executive-brief.md` | 300-500 words |
| `talking-points` | `synthesis/talking-points.md` | Bullet format |
| `one-pager` | `synthesis/one-pager.md` | 400-600 words |

**Finalization:**

1. Write `synthesis/pipeline-summary.json`:
   ```json
   {
     "topic": "...",
     "pipeline_phases": {
       "synthesis_check": {"research_hub_words": N, "sources_count": N, "claims_count": N},
       "narrative": {"arc_id": "...", "word_count": N, "citation_count": N, "review_score": N},
       "polish": {"readability_score": N, "active_voice_pct": N},
       "derivatives": ["executive-brief", "talking-points"]
     },
     "deliverables": {
       "research_hub": "synthesis/research-hub.md",
       "executive_narrative": "synthesis/insight-summary.md",
       "executive_brief": "synthesis/executive-brief.md",
       "talking_points": "synthesis/talking-points.md",
       "one_pager": "synthesis/one-pager.md"
     }
   }
   ```

2. Present summary to user:
   ```
   Research Story: "{topic}"

   Synthesis: {word_count} words, {sources} sources, {claims} claims verified
   Narrative: {arc_display_name} arc, {narrative_words} words, score {review_score}/100
   Polish:    Readability {flesch_score}, Active voice {active_pct}%

   Deliverables:
     Research hub:        synthesis/research-hub.md
     Executive narrative: synthesis/insight-summary.md
     [Executive brief:    synthesis/executive-brief.md]
     [Talking points:     synthesis/talking-points.md]
     [One-pager:          synthesis/one-pager.md]
   ```

---

## Resumability

Track phase state in `synthesis/pipeline-state.json`:

```json
{
  "topic": "...",
  "language": "en",
  "arc_id": "corporate-visions",
  "created_at": "2026-03-15T10:00:00Z",
  "phases": {
    "synthesis_check":  {"status": "complete"},
    "citation_bridge":  {"status": "complete", "completed_at": "..."},
    "arc_selection":    {"status": "complete", "arc_id": "corporate-visions"},
    "narrative":        {"status": "pending"},
    "narrative_review": {"status": "pending"},
    "copywriter":       {"status": "pending"},
    "derivatives":      {"status": "pending"}
  }
}
```

On skill invocation: if `synthesis/pipeline-state.json` exists, read it and resume from the first incomplete phase. Present resumption status to user before continuing.

---

## Error Recovery

| Phase | Failure | Recovery |
|-------|---------|----------|
| 1 (synthesis check) | Synthesis not complete | Stop pipeline; instruct user to run `/synthesis` first |
| 1 (synthesis check) | research-hub.md missing | Stop pipeline; instruct user to run `/synthesis` first |
| 2 (bridge) | No citations found | Warn user; proceed with raw research hub as narrative input |
| 2 (bridge) | Script error | Re-run; if persistent, copy research-hub.md directly to narrative-input/ |
| 3 (arc selection) | Unknown topic domain | Fall back to `corporate-visions` |
| 4 (narrative) | Skill returns `success: false` | Re-invoke once with `corporate-visions` as fallback arc |
| 5 (review) | Score < 50 (F grade) | Re-generate with different arc; if still < 50, proceed with warning |
| 6 (copywriter) | Arc validation fails | Copywriter's built-in fallback handles partial polish; proceed |
| 7 (derivatives) | One format fails | Generate remaining formats; report failure for the failed one |

---

## Bilingual Support

The `--language` parameter flows through the entire pipeline:

| Phase | Language Effect |
|-------|----------------|
| Synthesis Check | Language-agnostic (reads existing synthesis) |
| Citation Bridge | Language-agnostic (works on any text); enriches with source entity metadata |
| Arc Selection | German signal keywords checked when `--language de` |
| Narrative | German arc element headers, body text in German |
| Polish | Wolf Schneider style rules, Amstad readability formula (target 30-50) |
| Derivatives | Inherit language from narrative frontmatter |
