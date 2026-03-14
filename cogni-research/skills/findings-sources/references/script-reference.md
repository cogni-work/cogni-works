# Script Reference — findings-sources

Quick reference for scripts used during findings and source extraction. All scripts live in `${CLAUDE_PLUGIN_ROOT}/scripts/`.

## discover-questions-by-dimension.sh

Groups refined questions by dimension and creates execution batches for parallel processing.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/discover-questions-by-dimension.sh \
  --project-path /path/to/project --json
```

**Output JSON (key fields):**
```json
{
  "success": true,
  "data": {
    "total_dimensions": 5,
    "total_questions": 28,
    "dimensions": {
      "dimension-entity-id": {
        "dimension_number": 1,
        "title": "AI/ML Techniques & Maturity",
        "question_count": 6,
        "questions": ["/path/to/question-file.md"]
      }
    },
    "execution_batches": [
      {
        "batch_number": 1,
        "batch_name": "Dimension A + Dimension B",
        "question_count": 18,
        "question_paths": ["/path/to/q1.md"]
      }
    ],
    "batching": {
      "strategy": "question-count-based",
      "target_min": 15,
      "target_max": 20,
      "total_batches": 2
    }
  }
}
```

The batching strategy groups dimensions together until 15-20 questions per execution batch. This balances parallelism (too few = underutilization) against context load (too many = agent contention).

## scan-resumption-state.sh (phase 3)

Checks which questions already have findings from a previous interrupted run.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/scan-resumption-state.sh \
  --phase 3 --project-path /path/to/project --json
```

**Output JSON:**
```json
{
  "success": true,
  "phase": 3,
  "total_questions": 28,
  "completed_questions": 12,
  "pending_questions": ["question-foo-abc123"],
  "recommendation": "RESUME"
}
```

Recommendations: `FULL_RUN` (no prior progress), `RESUME` (partial — skip completed questions), `COMPLETE` (all questions have findings).

## Prerequisite Check

The simplest way to verify planning is complete: read `.metadata/sprint-log.json` and check `planning_complete: true`. The `check-phase-state.sh` script is available but requires a numeric phase and execution ID, which makes it less practical for a simple prerequisite check.

## generate-sources-readme.sh

Creates a provenance chain README with source statistics and entity index.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-sources-readme.sh \
  --project-path /path/to/project --language en --json
```

Exit codes: 0 = success, 2 = invalid args, 3 = no sources found.

## Sprint-log Fields

Located at `.metadata/sprint-log.json` in the project directory.

| Field | Type | Set By |
|-------|------|--------|
| `discovery_complete` | boolean | Phase 2 completion (source extraction done) |
| `phase_findings_coverage` | object | Phase 1 reconciliation — see schema below |
| `partial_scope` | object or null | Selective execution — records included/excluded dimensions and reason |
| `updated_at` | ISO 8601 | Each phase update |

**`phase_findings_coverage` schema:**
```json
{
  "total_questions": 28,
  "questions_with_findings": 26,
  "questions_without_findings": 2,
  "coverage_rate": 0.93,
  "gaps": ["question-entity-id-1", "question-entity-id-2"]
}
```

`discovery_complete: true` is the signal that the `claims` skill can begin.
