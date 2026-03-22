# Phase 3: Claim Verification

Optional phase — asks the user whether to verify extracted claims via `cogni-claims:claim-work`.

---

## Step 3.1: Ask User

```yaml
AskUserQuestion:
  question: "{total_claims} quantitative claims were extracted. Verify them now?"
  header: "Verify"
  options:
    - label: "Verify now (Recommended)"
      description: "Run automated claim verification against source URLs"
    - label: "Skip verification"
      description: "Save claims file for later verification"
```

## Step 3.2: Run Verification (if chosen)

```yaml
Skill:
  skill: "cogni-claims:claim-work"
  args: "--file-path {PROJECT_PATH}/tips-trend-report.md --claims-file {PROJECT_PATH}/tips-trend-report-claims.json --verdict-mode --language {LANGUAGE}"
```

If `cogni-claims` is not installed, display a warning and skip — do not halt.

## Step 3.3: Process Results

Parse the QualityGateResult, display PASS/REVIEW/FAIL summary, write verification metadata to `.metadata/trend-report-verification.json`:

```json
{
  "verified_at": "ISO-8601",
  "verdict": "PASS|REVIEW|FAIL",
  "total_claims": N,
  "verified": N,
  "passed": N,
  "failed": N,
  "review": N
}
```

If FAIL: present failed claims as information only — do not auto-correct the report.
