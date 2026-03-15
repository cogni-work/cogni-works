# Deep Research Tree Reference

## Adaptive Tree Exploration

Deep mode builds a research tree that expands dynamically based on what each branch discovers. Unlike basic/detailed modes where sub-questions are fully planned upfront, deep research starts with a top-level decomposition and then lets each branch grow organically through learning extraction and follow-up questions.

This mirrors GPT-Researcher's recursive deep research algorithm: each research pass produces learnings and follow-up questions, and those follow-ups drive the next level of exploration with decreasing breadth.

## Initial Decomposition

The skill orchestrator creates the top-level branches (3-5 sub-questions). Each branch becomes a deep-researcher agent assignment:

```
User Topic
├── Branch 1: [aspect A]  → deep-researcher agent 1
├── Branch 2: [aspect B]  → deep-researcher agent 2
├── Branch 3: [aspect C]  → deep-researcher agent 3
└── Branch 4: [aspect D]  → deep-researcher agent 4
```

## Within-Branch Recursion

Each deep-researcher agent internally performs adaptive exploration:

```
Branch 1: [aspect A]
├── Sub-aspect A.1 (initial decomposition)
│   ├── Search pass → learnings + follow-up questions
│   ├── Follow-up 1 (depth 2, reduced breadth)
│   │   └── Search pass → deeper learnings
│   └── Follow-up 2 (depth 2, reduced breadth)
│       └── Search pass → deeper learnings
├── Sub-aspect A.2
│   ├── Search pass → learnings + follow-up questions
│   └── Follow-up 1 (depth 2)
│       └── Search pass → deeper learnings
└── Sub-aspect A.3
    └── Search pass → learnings (no follow-up needed)
```

**Key behavior**: The tree shape is NOT predetermined. Follow-up branches appear only when the initial search reveals knowledge gaps, contradictions, or under-explored angles.

## Branching Rules

- **Top level (orchestrator)**: 3-5 branches (major aspects of the topic)
- **Within each branch (deep-researcher)**:
  - Initial: 2-3 sub-aspects, 2-3 queries each
  - Follow-up: `max(2, current_breadth // 2)` queries per follow-up question
  - 1-2 follow-up questions per sub-aspect (only if warranted)
  - Max depth: 3 levels of recursion within a branch
- **Total leaf research**: 8-15 search passes typical, max ~25

## Stopping Criteria

Recursion stops when any of these conditions is met:
- `remaining_depth` reaches 0
- Follow-up questions would duplicate existing learnings
- Search results return no new information (diminishing returns)
- Context word count approaches 25,000 words

## Entity Tracking

Each branch is a sub-question entity with `tree_path`:
- Branch 1: `tree_path: "1"`
- Sub-aspects and follow-ups within a branch are tracked internally by the deep-researcher agent
- The agent produces a single comprehensive context entity per branch, with findings structured hierarchically

## Batching Strategy

With 3-5 top-level branches and max 4-5 concurrent agents:

```
Batch 1: branches 1, 2, 3, 4  (4 agents)
Batch 2: branch 5             (1 agent, if needed)
```

Wait for each batch to complete before starting the next. Deep-researchers use sonnet (not haiku) because they perform internal reasoning loops.

## Context Tree to Flat Report

After all deep-researchers complete:
1. Run `merge-context.py` to aggregate all contexts (enforces 25K word limit)
2. The writer agent uses `tree_path` ordering to structure the report hierarchically
3. Branch-level sections become report headings
4. Within-branch hierarchical findings become section content with depth-appropriate detail

## When to Use Deep Mode

- Topic has multiple interconnected domains
- User requests "exhaustive", "deep dive", or "recursive" research
- Topic would benefit from exploring sub-topics that aren't obvious upfront
- Questions where initial search results reveal contradictions that need resolution
- Expected report length: 8000-15000 words
