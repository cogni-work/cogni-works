# Report Structure Reference

## Three Report Templates

### Basic Report (DOK-1/2, 3000-5000 words)

Concise overview suitable for quick briefings and initial assessments.

```
1. Executive Summary (200-300 words)
   - Key findings across all dimensions
   - Top 3-5 takeaways

2. Introduction (200-300 words)
   - Research question
   - Scope and methodology
   - Dimension overview

3. Findings by Dimension (400-600 words each)
   Section per dimension:
   - Key findings (evidence-based, cited)
   - Supporting data points
   - Notable gaps or limitations

4. Cross-Cutting Themes (300-500 words)
   - Patterns observed across dimensions
   - Convergent findings
   - Contradictions or tensions

5. Conclusion (200-300 words)
   - Answer to the research question
   - Confidence assessment
   - Suggested next steps

6. References
   - Numbered list, sorted by first citation
   - Publisher, URL, reliability score
```

### Detailed Report (DOK-3, 5000-10000 words)

Comprehensive analysis suitable for strategic decision-making.

```
1. Executive Summary (300-500 words)

2. Introduction (400-600 words)
   - Context and motivation
   - Research question (refined)
   - Scope, boundaries, limitations
   - Methodology overview

3. Findings by Dimension (600-1000 words each)
   Section per dimension:
   - Dimension overview
   - Sub-sections per finding cluster
   - Evidence synthesis with inline citations
   - Claim confidence indicators
   - Dimension-level implications

4. Cross-Cutting Analysis (500-800 words)
   - Cross-dimensional patterns
   - Source convergence/divergence
   - Evidence strength mapping
   - Key uncertainties

5. Conclusion and Recommendations (400-600 words)
   - Synthesis of findings
   - Confidence-weighted recommendations
   - Areas requiring further research

6. Appendix: Claim Verification Summary
   - High-confidence claims (≥0.75)
   - Flagged claims requiring attention
   - Verification coverage statistics

7. References
```

### Deep Report (DOK-4, 8000-15000 words)

Exhaustive analysis suitable for academic publication or comprehensive strategy documents.

```
Same structure as Detailed, with:
- Deeper sub-section nesting within each dimension
- Per-dimension structure: Overview → Detailed Findings → Evidence Assessment → Implications
- Extended cross-cutting analysis with claim confidence mapping
- Methodology appendix with search strategy details
- Full claim verification appendix
```

## Section-to-Dimension Mapping

Report sections map 1:1 to research dimensions from `01-research-dimensions/data/`:
- Section heading = dimension `title` from frontmatter
- Section content = findings filtered by `question_ref` → dimension membership
- Section order = dimension `dimension_number` from frontmatter (ascending)

## Citation Format

Inline: `[Source: Publisher Name](URL)`
- Every statistic, data point, quote, or named finding gets its own citation
- Aim: 2-3 citations per paragraph with data
- When multiple sources support same point, cite all

References section:
```
[1] Publisher Name. "Article Title". URL. Reliability: 0.85
[2] Publisher Name. URL. Reliability: 0.72
```

## Claim Confidence Indicators

When referencing claims from 06-claims/data/:
- High confidence (≥0.75): State directly
- Medium confidence (0.50-0.74): "Evidence suggests...", "Research indicates..."
- Low confidence (<0.50): "Limited evidence points to...", "Preliminary findings suggest..."
- Flagged claims: Note explicitly with reason
