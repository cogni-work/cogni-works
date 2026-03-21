---
name: Desk Research Framing
phase: discover
type: divergent
inputs: [engagement-vision, scope]
outputs: [research-topic, research-config]
duration_estimate: "10-15 min with consultant"
requires_plugins: [cogni-gpt-researcher]
---

# Desk Research Framing

Translate the engagement vision into a well-scoped research topic for cogni-gpt-researcher.

## When to Use

- Every engagement that needs evidence beyond what the client already has
- Critical for: strategic-options, business-case, market-entry, digital-transformation

## Guided Prompt Sequence

### Step 1: Topic Derivation
From the engagement vision, derive a research topic:
- **strategic-options**: "[Industry] strategic landscape and growth vectors in [scope]"
- **business-case**: "[Product/initiative] market opportunity and competitive dynamics"
- **gtm-roadmap**: "[Market] buyer landscape, channels, and competitive positioning"
- **cost-optimization**: "[Domain] operational benchmarks and efficiency best practices"
- **digital-transformation**: "[Industry] digital maturity, technology trends, and transformation case studies"
- **innovation-portfolio**: "[Industry] emerging technologies and innovation investment patterns"
- **market-entry**: "[Market/geography] entry barriers, regulatory landscape, and competitive dynamics"

Present the derived topic and ask the consultant to refine.

### Step 2: Research Configuration
Recommend settings for cogni-gpt-researcher:
- **Report type**: `detailed` (default), `deep` for digital-transformation/innovation
- **Market**: Match engagement scope (dach, de, us, uk, fr, global)
- **Tone**: `analytical` for business engagements
- **Source mode**: `web` (default), `hybrid` if client has internal documents

### Step 3: Dispatch
Invoke cogni-gpt-researcher:research-report with the configured topic and settings.

## Output
The research report and its sources become inputs for the Define phase.
