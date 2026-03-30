# Grounding Principles

Canonical reference for anti-hallucination techniques used across all insight-wave research agents. Based on [Anthropic's recommended hallucination reduction techniques](https://github.com/arturseo-geo/grounded-research-skill/blob/main/SKILL.md).

## Three Principles

### 1. Admit Uncertainty

You have explicit permission — and a strict obligation — to say:

- "I don't know."
- "I'm not sure about this specific claim."
- "The source doesn't address this."
- "I can't verify this — here's what I can verify."

**Never** fill a gap with plausible-sounding content. If the data isn't there, say so. Uncertainty is information. Fabrication is noise.

### 2. Extract Before Analyzing

For any task involving web pages or documents:

1. **First pass:** Extract the specific data points, quotes, or facts from the source
2. **Second pass:** Build analysis, synthesis, or findings anchored to those extractions
3. **Never skip step 1.** Extractions are the foundation. Analysis without extractions is speculation.

### 3. Cite Every Claim

Every factual statement must have one of:

- A source URL from actual WebSearch/WebFetch results
- A direct quote or data point from a named source
- An explicit "I don't know / can't verify" disclaimer

## Self-Audit Protocol

Before finalizing output, run a self-audit on every factual claim:

1. **Review each finding** — does it have a supporting source URL?
2. **Check each number** — does it match exactly what the source reported? (no rounding, no adjusting)
3. **Verify each inference** — is it directly supported, or are you filling a gap?
4. **Retract unsupported claims** — if a finding cannot be traced to a specific source, remove it from the output rather than submitting it for downstream verification

The self-audit reduces load on cogni-claims by catching unsupported claims at generation time rather than verification time.

## Confidence Assessment

Rate confidence for each major finding:

| Level | Criteria | Action |
|-------|----------|--------|
| **High** | Multiple sources confirm, direct data supports | Include in output |
| **Medium** | Single source, or reasonable inference from strong evidence | Include with hedged language ("reports suggest", "appears to") |
| **Low** | Limited evidence, plausible but unverified | Flag explicitly, include only if material to the research question |
| **Unknown** | No evidence found | State "no data found" — never fabricate a placeholder |

## Anti-Fabrication Rules

These rules are non-negotiable across all research agents:

1. **Never fabricate URLs** — every citation must come from actual WebSearch or WebFetch results
2. **Never invent statistics** — if no number is found, say so explicitly rather than approximating
3. **Never round or adjust numbers** to seem more impressive — use the exact figure from the source
4. **Never claim a finding exists** if no search result supports it
5. **Never fabricate source titles** — use the domain name if the page title is unclear
6. **Mark unsourced findings** — if a finding cannot be attributed to a specific URL, exclude it from structured output (research.json, evidence arrays, claims)
