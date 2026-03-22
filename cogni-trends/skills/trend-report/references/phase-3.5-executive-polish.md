# Phase 3.5: Executive Polish via cogni-copywriting

Polish the assembled trend report for executive readability. Runs after claim verification so citations and claim references remain stable during extraction and verification. The copywriter preserves all inline citations, German characters, and protected content (diagram placeholders, figure references, kanban tables).

---

## Step 3.5.1: Check Availability

If `cogni-copywriting` plugin is not installed, display a warning and skip to Phase 4 — do not halt.

## Step 3.5.2: Invoke Copywriter

```yaml
Skill:
  skill: "cogni-copywriting:copywriter"
  args: "FILE_PATH={PROJECT_PATH}/tips-trend-report.md SCOPE=tone STAKEHOLDERS=executive REVIEW_MODE=automated"
```

**Parameter choices:**
- `SCOPE=tone` — the report structure is already defined by the theme assembly (Phase 2). Only polish prose clarity, paragraph flow, bold anchoring, and sentence rhythm. Do not restructure sections or reorder themes.
- `STAKEHOLDERS=executive` — the primary audience is CxO-level decision makers.
- `REVIEW_MODE=automated` — lightweight review pass without interactive feedback.

## Step 3.5.3: Validate Output

After the copywriter returns:

| Check | Condition | On Failure |
|-------|-----------|------------|
| Citation count | polished >= original | REVERT: restore from `.tips-trend-report.md` backup |
| Frontmatter intact | YAML frontmatter unchanged | REVERT |
| Theme structure | Same H2/H3 heading count and text | REVERT |
| Claims registry | Claims table rows unchanged | REVERT |

If any check fails, revert to the backup the copywriter created (`.tips-trend-report.md` in the same directory) and log the failure reason. Partial polish failure does not block Phase 4.

## Step 3.5.4: Update Metadata

If polish succeeded, note it for the finalization summary:

```json
{ "copywriter_applied": true, "copywriter_scope": "tone" }
```
