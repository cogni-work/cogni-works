# Script Reference — Synthesis

Quick reference for scripts used during synthesis.

## check-phase-state.sh

Verify a prior phase completed before synthesis can proceed.

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
  "phase": 4,
  "status": "completed",
  "timestamp": "2026-03-15T10:00:00Z",
  "state_file": "<project>/.metadata/state/execution-<id>.json"
}
```

Exit codes: 0 = phase completed, 1 = not completed / state missing, 2 = invalid parameters.

---

## generate-sources-readme.sh

Generate the source inventory README in `05-sources/README.md`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-sources-readme.sh \
  --project-path <path> \
  --language <en|de> \
  --json
```

**Output:**
```json
{
  "success": true,
  "data": {
    "readme_path": "05-sources/README.md",
    "readme_created": true
  },
  "stats": {
    "source_count": 45,
    "domain_count": 28,
    "finding_refs_total": 140
  }
}
```

Exit codes: 0 = success, 2 = invalid args / missing path, 3 = no source files found.

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

## save-phase-state.sh

Persist phase completion state for resumption.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/save-phase-state.sh \
  --phase <0-4> \
  --project-path <path> \
  --execution-id <id> \
  --status <completed|failed>
```

**Output:**
```json
{
  "success": true,
  "phase": 4,
  "status": "completed",
  "execution_id": "synth-2026-03-15",
  "state_file": "<project>/.metadata/state/execution-synth-2026-03-15.json",
  "timestamp": "2026-03-15T10:00:00Z"
}
```

Exit codes: 0 = state saved, 1 = save failed, 2 = invalid parameters.

---

## Sprint-log Fields Written by Synthesis

| Field | Type | Set When |
|-------|------|----------|
| `arc_id` | string | Phase 1 — after user confirms arc selection |
| `completed_dimensions` | string[] | Phase 2 — after each dimension completes |
| `synthesis_complete` | boolean | Phase 4 — after finalization |
| `dimension_count` | integer | Phase 4 — total dimensions synthesized |
| `partial_scope` | object | Phase 4 — only for selective execution |
| `updated_at` | ISO 8601 | Phase 4 — current timestamp |

`partial_scope` structure (selective execution only):
```json
{
  "included_dimensions": [1, 3],
  "excluded_dimensions": [2, 4, 5],
  "reason": "user request"
}
```
