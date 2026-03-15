---
name: export-report
description: |
  Export research as a structured analytical report — traditional format with sections per dimension,
  inline citations, and references. Alternative to synthesis (narrative) for users who want a report,
  not a story. Prerequisite: claims stage must be complete.
  Trigger when user says "export report", "structured report", "analytical report",
  "traditional report", "write report without narrative", "research report",
  "compile report", "generate report from findings", or wants a formal document
  without story arc transformation.
---

# Export Report

Produce a structured analytical research report directly from the entity chain — no narrative arc, no cogni-narrative delegation. This gives users a traditional report format: executive summary, dimension-based sections, cross-cutting analysis, and a full reference list with source reliability scores.

## Quick Example

**Input:** Completed research project with 5 dimensions, 140 findings, 45 sources, 85 claims

**Output:** `output/research-report.md` — 6000-word detailed report with sections per dimension, 40+ inline citations, claim confidence indicators, and numbered reference list.

## Prerequisites

1. **Verify project exists**: Confirm project directory and `.metadata/sprint-log.json` are present.
2. **Check claims completed**: Read sprint-log and confirm `claims_complete: true`. If false, tell user to run `claims` first.
3. **Verify entity data**: At least 1 dimension in `01-research-dimensions/data/`, at least 1 finding in `04-findings/data/`, at least 1 source in `05-sources/data/`.

## Workflow

### Phase 1: Report Generation

1. **Determine report type** from DOK level in sprint-log:
   - DOK-1 or DOK-2 → basic (3000-5000 words)
   - DOK-3 → detailed (5000-10000 words)
   - DOK-4 → deep (8000-15000 words)
   - User can override by specifying "basic", "detailed", or "deep" explicitly.

2. **Read project language** from sprint-log (`project_language`, default "en").

3. **Invoke report-writer agent** via Agent tool:
   ```
   Agent: report-writer
   Args: --project-path <path> --report-type <type> --language <code>
   ```

4. **Verify output**: Check that `output/research-report.md` exists and meets word count minimum for the report type.

5. **Report to user**:
   ```
   **Report Generated**
   - Type: <basic|detailed|deep>
   - Words: <N>
   - Sections: <N> (one per dimension + intro/conclusion)
   - Sources cited: <N>
   - Claims referenced: <N>
   - Output: output/research-report.md
   ```

## Error Recovery

| Scenario | What to Do |
|----------|------------|
| claims_complete not true | Tell user to run claims skill first |
| No findings in 04-findings/ | Tell user to run findings-sources first |
| Report below word minimum | Re-invoke report-writer with explicit instruction to expand |
| report-writer returns ok: false | Check error message, report to user |

## Completion

Export-report is complete when:
- `output/research-report.md` exists with content meeting word count minimum
- Report contains inline citations referencing actual sources

This skill is an alternative to synthesis. Users choose: `synthesis` for narrative storytelling via cogni-narrative, `export-report` for traditional analytical reports.
