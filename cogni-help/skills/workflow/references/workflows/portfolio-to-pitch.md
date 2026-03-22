# Workflow: Portfolio to Pitch

**Pipeline**: cogni-portfolio → cogni-narrative → cogni-sales → cogni-visual
**Duration**: 2-4 hours for a complete pitch deck
**Use case**: Sales creating a customer-specific pitch presentation

```mermaid
graph LR
    A[cogni-portfolio] -->|propositions| B[cogni-narrative]
    B -->|story arc| C[cogni-sales]
    C -->|pitch content| D[cogni-visual]
    D -->|deck.pptx| E[Deliverable]
```

## Step 1: Portfolio Data (cogni-portfolio)

**Command**: `/portfolio-export` (if already set up) or `/portfolio-setup` → `/portfolio-draft`

**Input**: Your product/service catalog and target market
**Output**: Propositions with IS/DOES/MEANS, competitor analysis, market sizing

**Tips**:
- If you already have portfolio data, skip to Step 2
- Focus on the propositions relevant to this specific customer or segment
- Competitor analysis strengthens the "why us" part of the pitch

## Step 2: Narrative Arc (cogni-narrative)

**Command**: `/narrate`

**Input**: Portfolio propositions and customer context
**Output**: A narrative shaped by a story arc (typically SCQA or Why Change)

**Tips**:
- For sales pitches, SCQA (Situation-Complication-Question-Answer) works well
- The Corporate Visions "Why Change" arc is built into cogni-sales directly —
  you can skip this step if using that methodology
- For complex enterprise deals, the narrative step adds strategic depth

## Step 3: Sales Pitch (cogni-sales)

**Command**: `/pitch-setup` → `/pitch-draft`

**Input**: Narrative + portfolio data + customer specifics
**Output**: Structured pitch content using Why Change methodology

**Tips**:
- Named-customer pitches are deal-specific — include customer research
- Segment pitches are reusable across similar customers
- Optionally enrich with TIPS trends for "why now" urgency
- The pitch content includes unconsidered needs, business case, and proposal

## Step 4: Visual Delivery (cogni-visual)

**Command**: `/render-slides`

**Input**: The pitch content from Step 3
**Output**: A PPTX presentation deck

**Tips**:
- Sales decks need strong visual flow — review and adjust after generation
- For customer meetings, fewer slides with more impact beats comprehensive decks
- Consider also generating a leave-behind document (web narrative format)

## Common Pitfalls

- **Generic propositions**: Customer-specific pitches need customer-specific value
  statements. Don't just reuse segment-level DOES/MEANS.
- **Missing "why change"**: The Why Change methodology needs a compelling
  unconsidered need — without it, the pitch is just a feature list.
- **Too many slides**: Executive pitches should be 10-15 slides max. Edit down.
