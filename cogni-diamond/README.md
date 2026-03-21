# cogni-diamond

**Double Diamond Consulting Orchestrator for Claude Cowork**

cogni-diamond guides collaborative consulting engagements through the Double Diamond framework — diverge to explore, converge to decide, twice — driving structured progress from a shared vision toward actionable, multi-format deliverables. It orchestrates existing cogni-work plugins as phase-appropriate tools rather than reinventing capabilities.

## How It Works

Every engagement starts with **Vision Framing**: define the desired outcome class (e.g., strategic options for market expansion, an investment business case, a go-to-market roadmap). cogni-diamond then proposes phase-appropriate methods — including calls to existing cogni-work plugins — and steers the process through all four phases toward that outcome.

### Diamond 1 — Problem Space

| Phase | Purpose | Methods & Plugin Integration |
|---|---|---|
| **Discover** | Diverge to build a rich understanding of the problem landscape | **cogni-gpt-researcher** for structured desk research · **cogni-tips** for trend scouting across ACT/PLAN/OBSERVE horizons · **cogni-portfolio** for competitive baseline · Stakeholder mapping · Customer journey analysis · Data audit |
| **Define** | Converge on the core challenge to solve | **cogni-claims** to verify assumptions from Discovery · Affinity clustering · HMW synthesis · Problem statement framing · Assumption mapping |

### Diamond 2 — Solution Space

| Phase | Purpose | Methods & Plugin Integration |
|---|---|---|
| **Develop** | Diverge to generate and explore solution options | **cogni-tips** value-modeler to translate trends into options · **cogni-portfolio** for proposition modeling via IS/DOES/MEANS · Scenario planning · Option synthesis |
| **Deliver** | Converge on validated, actionable outcomes | **cogni-claims** for final claim verification · **cogni-portfolio** for positioning validation · Opportunity scoring · Business case canvas · Roadmap construction |

## Vision Classes

| Class | Outcome | Typical Duration |
|---|---|---|
| `strategic-options` | Ranked strategic alternatives with evaluation criteria | 4-8 weeks |
| `business-case` | Investment justification with financials and risk analysis | 3-6 weeks |
| `gtm-roadmap` | Go-to-market plan with channels, segments, and timeline | 4-6 weeks |
| `cost-optimization` | Prioritized cost reduction opportunities | 3-5 weeks |
| `digital-transformation` | Current-to-target state mapping with transition roadmap | 6-12 weeks |
| `innovation-portfolio` | Prioritized innovation investment bets across horizons | 4-8 weeks |
| `market-entry` | Market feasibility assessment and entry strategy | 4-8 weeks |

## Skills

| Skill | Purpose |
|---|---|
| `diamond-setup` | Vision framing and engagement initialization |
| `diamond-discover` | D1 diverge: research, trends, competitive baseline |
| `diamond-define` | D1 converge: assumption verification, problem statement |
| `diamond-develop` | D2 diverge: option generation, proposition modeling |
| `diamond-deliver` | D2 converge: verification, business case, roadmap |
| `diamond-resume` | Multi-session re-entry and status dashboard |
| `diamond-export` | Final deliverable package generation |

## Plugin Orchestration

cogni-diamond acts as the **process orchestrator** — it dispatches to existing plugins at the right moment:

| Plugin | Role | When Invoked |
|---|---|---|
| **cogni-gpt-researcher** | Deep desk research | Discover |
| **cogni-tips** | Trend scouting and value modeling | Discover + Develop |
| **cogni-portfolio** | Competitive analysis and proposition modeling | Discover + Develop + Deliver |
| **cogni-claims** | Claim verification and quality gates | Define + Deliver |
| **cogni-visual** | Visual deliverables (slides, diagrams) | Export |
| **document-skills** | Formatted outputs (PPTX, DOCX, XLSX) | Export |

## Getting Started

```
diamond-setup
```

Or describe what you need: "I need to evaluate strategic options for expanding our cloud portfolio in the DACH market."

---

*Part of the [cogni-work](https://github.com/cogni-work) plugin ecosystem for Claude Cowork.*
