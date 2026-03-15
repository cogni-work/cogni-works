# Deep Research Tree

Reference for the adaptive deep research tree algorithm used by `findings-creator`. This describes how a single refined question is recursively explored through branching sub-aspects with decreasing breadth.

---

## Tree Structure

```
Refined Question (root)
├── Sub-Aspect A (breadth=3)
│   ├── Query A1 → learnings → follow-up FA1
│   ├── Query A2 → learnings → follow-up FA2
│   └── Query A3 → learnings
│       ├── Follow-up FA1 (breadth=2)
│       │   ├── Query FA1a → learnings → follow-up FFA1
│       │   └── Query FA1b → learnings
│       │       └── Follow-up FFA1 (breadth=2, depth=3 MAX)
│       │           ├── Query FFA1a → learnings
│       │           └── Query FFA1b → learnings
│       └── Follow-up FA2 (breadth=2)
│           ├── Query FA2a → learnings
│           └── Query FA2b → learnings
├── Sub-Aspect B (breadth=3)
│   ├── Query B1 → learnings → follow-up FB1
│   ├── Query B2 → learnings
│   └── Query B3 → learnings
│       └── Follow-up FB1 (breadth=2)
│           ├── Query FB1a → learnings
│           └── Query FB1b → learnings
└── Sub-Aspect C (breadth=2)
    ├── Query C1 → learnings
    └── Query C2 → learnings → follow-up FC1
        └── Follow-up FC1 (breadth=2)
            ├── Query FC1a → learnings
            └── Query FC1b → learnings
```

## Branching Rules

| Level | Breadth | Description |
|-------|---------|-------------|
| Root decomposition | 2-3 sub-aspects | Initial decomposition of the refined question |
| Sub-aspect queries | 2-3 queries each | 4-9 total queries at level 1 |
| Follow-up (depth 2) | `max(2, breadth // 2)` | Reduced breadth per follow-up |
| Follow-up (depth 3) | `max(2, breadth // 2)` | Further reduced, minimum 2 |

**Maximum depth**: 3 levels (root + 2 recursions). Configurable via `DEPTH` parameter, default 2.

**Breadth reduction formula**: `max(2, current_breadth // 2)` — halve the breadth at each depth level, but never go below 2 queries.

## Stopping Criteria

The recursive exploration stops when ANY of these conditions is met:

1. **Depth exhausted**: `remaining_depth` reaches 0
2. **Duplicate learnings**: Follow-up questions would repeat what is already in `all_learnings`
3. **Diminishing returns**: New search results add no substantial new information
4. **Context limit**: Total context approaching 25,000 words — trim older/lower-confidence findings first
5. **No follow-ups**: The learning extraction phase produces no meaningful follow-up questions

## Search Budget

Worst-case search counts by depth setting:

| Depth | Sub-Aspects | Level 1 Queries | Level 2 Queries | Level 3 Queries | Max Total |
|-------|-------------|-----------------|-----------------|-----------------|-----------|
| 1     | 3           | 9               | 0               | 0               | 9         |
| 2     | 3           | 9               | ~12             | 0               | ~21       |
| 3     | 3           | 9               | ~12             | ~8              | ~29       |

In practice, stopping criteria reduce actual query counts significantly below these maximums.

## Batching Strategy

The findings-sources skill dispatches 4-5 `findings-creator` agents concurrently (one per question). Each agent handles its own internal recursion. This provides parallelism across questions while keeping per-question recursion sequential for context preservation.

```
Batch 1 (parallel):
  findings-creator → question-1 (internal tree)
  findings-creator → question-2 (internal tree)
  findings-creator → question-3 (internal tree)
  findings-creator → question-4 (internal tree)

Batch 2 (parallel):
  findings-creator → question-5 (internal tree)
  findings-creator → question-6 (internal tree)
  ...
```

## Entity Output

Each `findings-creator` agent produces:

- **Finding entities** in `04-findings/data/` — one per sub-aspect (not per learning). Created via `create-entity.sh --entity-type 04-findings`.
- Findings include `deep_research: true` and `depth_reached: N` in frontmatter.
- Source entities are NOT created by this agent — `source-creator` handles deduplication and enrichment in Phase 2 of findings-sources.

### Finding Entity Structure

Each finding entity contains hierarchically structured content:
- Top-level sub-aspect summary
- Key learnings from initial search pass
- Follow-up learnings from deeper recursion (indented/nested)
- Source URLs for every cited fact

## Integration with Pipeline

Deep findings are standard finding entities that flow through claims and synthesis like any other finding. The `deep_research: true` and `depth_reached` fields are metadata for traceability — they do not change how downstream skills process the findings. Claims skill extracts claims from deep findings using the same logic as regular findings. Synthesis skill incorporates deep findings alongside regular findings without special handling.

## Agent Selection

The `deep_exploration` flag in `.metadata/sprint-log.json` controls which agent is dispatched:

| Flag | Agent | Set By |
|------|-------|--------|
| `deep_exploration: true` | `findings-creator` | research-plan (auto for DOK-4) |
| `deep_exploration: false` | `findings-creator` | research-plan (default for DOK 1-3) |
| User override | Whichever requested | Explicit user instruction |

See [research-type-routing.md](research-type-routing.md) for the full routing table.
