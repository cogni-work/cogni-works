# Review-Revision Criteria

## When to Trigger Revision

After claim extraction (Phase 1) and optional source verification (Phase 2), evaluate claim confidence distribution:

| Metric | Threshold | Action |
|--------|-----------|--------|
| Claims with final_confidence < 0.60 | > 20% of total | Trigger revision loop |
| Claims with final_confidence < 0.60 | ≤ 20% of total | Skip revision, proceed to finalization |

## Revision Loop Mechanics

1. Identify all claims with `final_confidence < 0.60` (or `confidence_score < 0.60` if source verification was skipped)
2. Invoke claim-revisor agent with weak claim paths
3. claim-revisor creates new finding entities with corroborating evidence
4. Re-run source-creator to process new sources
5. Re-run claim-extractor ONLY on the new revision-generated findings (filter by `revision_source: true`)
6. Merge new claims into the claim set
7. Re-evaluate: if still >20% below threshold, run iteration 2
8. After iteration 2 (or if threshold met), proceed to finalization

## Iteration Limits

| Setting | Value | Rationale |
|---------|-------|-----------|
| Max iterations | 2 | Diminishing returns after 2 rounds; cost control |
| Cap enforcement | `review-loop-guard.sh` hook | Reads `.metadata/revision-log.json`, blocks if iteration > 2 |

## Claim-Level Review Dimensions

When evaluating individual weak claims for revision priority:

| Dimension | Weight | Description |
|-----------|--------|-------------|
| Evidence strength | 0.30 | How well-supported by source content |
| Source diversity | 0.20 | Number of independent sources |
| Claim specificity | 0.20 | Precision of the assertion (specific > vague) |
| Cross-validation | 0.15 | Agreement across multiple findings |
| Temporal relevance | 0.15 | Recency of supporting evidence |

## Oscillation Detection

Prevents infinite revision loops where claim-revisor "fixes" a claim that the next round flags again.

**Rules:**
1. Track revised claims in `.metadata/revision-log.json`: `{claim_id: {iterations_revised: [1], status: "revised"|"accepted_with_warning"}}`
2. If a claim appears in `revision-log.json` from iteration N-1 AND is still below threshold in iteration N: accept with warning, do not search again
3. Maximum 1 revision attempt per claim per iteration
4. Log oscillation events for debugging

## Revision Log Schema

`.metadata/revision-log.json`:
```json
{
  "revision_iterations": [
    {
      "iteration": 1,
      "timestamp": "ISO 8601",
      "weak_claims_count": 15,
      "revised_count": 12,
      "accepted_with_warning": 3,
      "new_findings_created": 18,
      "claim_ids_revised": ["claim-xxx", "claim-yyy"]
    }
  ],
  "total_iterations": 1,
  "max_iterations": 2
}
```
