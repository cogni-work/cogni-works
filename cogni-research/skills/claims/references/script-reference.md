# Script Reference — Claims

Quick reference for scripts used during claim extraction and verification. All scripts live in `${CLAUDE_PLUGIN_ROOT}/scripts/`.

## partition-entities.sh

Split entity files across parallel agents for balanced workload distribution.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/partition-entities.sh \
  --entity-dir <project>/04-findings/data \
  --pattern "*.md" \
  --partition-index 0 \
  --total-partitions 4 \
  --json
```

**Output:**
```json
{
  "success": true,
  "partition_index": 0,
  "total_partitions": 4,
  "total_entities": 140,
  "partition_size": 35,
  "entities_in_partition": 35,
  "entity_files": ["/path/to/finding-1.md", "..."]
}
```

Exit codes: 0 = success, 1 = validation error, 2 = invalid arguments, 3 = directory not found.

---

## scan-resumption-state.sh

Detect interrupted claims runs and identify pending work.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/scan-resumption-state.sh \
  --phase 7 \
  --project-path <path> \
  --json
```

**Output:**
```json
{
  "success": true,
  "phase": 7,
  "total_findings": 140,
  "completed_findings": 80,
  "pending_finding_ids": ["finding-foo-abc123", "finding-bar-def456"],
  "pending_finding_paths": ["/path/to/finding-foo-abc123.md", "/path/to/finding-bar-def456.md"],
  "recommendation": "RESUME"
}
```

Recommendations: `FULL_RUN` (no prior progress), `RESUME` (partial — use `pending_finding_paths` to filter), `COMPLETE` (all findings processed).

Exit codes: 0 = state determined, 1 = project not found, 2 = invalid arguments.

---

## generate-claims-readme.sh

Generate the claim inventory README in `06-claims/README.md`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-claims-readme.sh \
  --project-path <path> \
  --language <en|de> \
  --json
```

**Output:**
```json
{
  "success": true,
  "data": {
    "readme_path": "06-claims/README.md",
    "readme_created": true
  },
  "stats": {
    "claim_count": 62,
    "avg_confidence": 0.78,
    "high_confidence_count": 28,
    "moderate_confidence_count": 24,
    "low_confidence_count": 10,
    "flagged_count": 3
  }
}
```

Exit codes: 0 = success, 2 = invalid args / missing path, 3 = no claim files found.

---

## check-phase-state.sh

Verify a prior phase completed before claims can proceed. For simple prerequisite checks, reading `discovery_complete` from sprint-log directly is often simpler.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-phase-state.sh \
  --phase <0-4> \
  --project-path <path> \
  --execution-id <id>
```

**Output:**
```json
{
  "completed": true,
  "phase": 3,
  "status": "completed",
  "timestamp": "2026-03-15T10:00:00Z"
}
```

Exit codes: 0 = phase completed, 1 = not completed / state missing, 2 = invalid parameters.

---

## Sprint-log Fields Written by Claims

| Field | Type | Set When |
|-------|------|----------|
| `claims_complete` | boolean | Phase 3 — after finalization |
| `partial_scope` | object | Phase 3 — only for selective execution |
| `updated_at` | ISO 8601 | Phase 3 — current timestamp |

Note: `claim-extractor-stats.json` is written by the claim-extractor agent to `.metadata/`, not to sprint-log.

`partial_scope` structure (selective execution only):
```json
{
  "included_dimensions": [1, 3],
  "excluded_dimensions": [2, 4, 5],
  "reason": "user request"
}
```
