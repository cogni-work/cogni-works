# Course 8: Research Reports

**Duration**: 45 minutes | **Modules**: 5 | **Prerequisites**: Course 3
**Plugin**: cogni-gpt-researcher (v0.5.1, 4 skills, 8 agents)
**Audience**: Consultants generating research-backed reports and intelligence

---

## Module 1: Research Fundamentals & Setup

### Theory (3 min)

**cogni-gpt-researcher** is a STORM-inspired multi-agent editorial workflow
that turns a research question into a fully sourced, reviewed report. Instead
of a single prompt, it orchestrates specialized agents across distinct phases
— each handling decomposition, research, writing, or review.

**Five report types**:

| Type | Length | Sub-questions / Sections | Best For |
|------|--------|--------------------------|----------|
| Basic | 3-5K words | 5 sub-questions | Quick insight on a focused topic |
| Detailed | 5-10K words | 5-10 sections | Client deliverables and briefings |
| Deep | 8-15K words | Recursive tree exploration | Strategic intelligence and due diligence |
| Outline | 1-2K words | Framework only | Planning before committing to a full report |
| Resource | 1.5-3K words | Bibliography | Source collection and literature review |

**Three source modes**:
- **Web** (default) — searches the open internet for current information
- **Local** — analyzes user-provided documents (PDF, MD, TXT, CSV, JSON)
- **Hybrid** — combines web search with local document analysis

**Configuration menu**:
- **Depth**: basic, detailed, deep, outline, resource
- **Tone**: 13 options (objective, analytical, critical, persuasive, formal, informal, enthusiastic, cautionary, comparative, speculative, investigative, advisory, balanced)
- **Citation format**: APA, MLA, Chicago, Harvard, IEEE, Wikilink
- **Language**: EN (default), DE (DACH-specific sources)

Before any research begins, the plugin asks you to select a project storage
location and initializes a structured directory for all outputs.

### Demo

Walk through starting a basic research report:
1. Invoke the research-report skill with a sample topic
2. Show the configuration menu — explain each option
3. Select depth (basic), tone (analytical), and citation format (APA)
4. Choose a project storage location
5. Show the initialized project directory structure

### Exercise

Ask the user to:
1. Think of a topic they've recently needed to research for a client
2. Decide which report type fits: basic, detailed, or deep?
3. Configure the report: pick a tone, citation format, and source mode
4. No actual run needed — just walk through the setup decisions

### Quiz

1. **Multiple choice**: A client asks for a 10-page market analysis with full citations. Which report type fits best?
   - a) Basic — quick insight is enough
   - b) Detailed — right length for a client deliverable
   - c) Outline — just the framework
   - d) Resource — bibliography only
   **Answer**: b

2. **Hands-on**: You need to research a topic using both public sources and internal company documents. Which source mode would you use, and why?

### Recap

- cogni-gpt-researcher orchestrates 8 agents across a multi-phase pipeline
- 5 report types: basic, detailed, deep, outline, resource
- 3 source modes: web, local, hybrid
- Configure tone, citation format, and language before starting
- Project directory is initialized with a dedicated storage location

---

## Module 2: Sub-Questions & Parallel Research

### Theory (3 min)

The research pipeline begins by breaking your topic into independent
sub-questions, then dispatches parallel agents to investigate each one.

**Phase 0.5 — Preliminary web search**:
Before generating sub-questions, the system runs a quick web search to ground
the decomposition in what is actually available online. This prevents
sub-questions about topics with no accessible sources.

**Phase 1 — Orthogonal sub-question decomposition**:
- "Orthogonal" means each sub-question is independent — no overlap, no
  redundancy
- Together, the sub-questions collectively cover the full scope of the topic
- The system also selects an auto-generated researcher role (agent persona
  matched to the topic domain, e.g., "market analyst" or "policy researcher")

**Phase 2 — Parallel section-researcher agents**:
- 4-5 researcher agents run concurrently per batch
- Each agent executes 5-7 web searches for its sub-question
- **Local-researcher agents** handle document analysis when source mode is
  local or hybrid (PDF, MD, TXT, CSV, JSON)
- **Deep-researcher agents** perform recursive tree exploration for deep
  reports (depth-2: 3-5 branches, each with 2-3 sub-branches)

**Phase 2.5 — Source curation** (detailed and deep reports only):
- Automatically ranks all discovered sources into three tiers:
  primary (highest authority), secondary (supporting evidence),
  and supporting (background context)
- Removes low-quality or redundant sources before writing begins

### Demo

Walk through how sub-questions are generated:
1. Show a sample topic and the preliminary web search results
2. Display the generated sub-questions — point out their independence
3. Show the auto-selected researcher role
4. Explain how parallel agents run concurrently (4-5 at a time)
5. Show source quality scoring and tier assignment

### Exercise

Ask the user to:
1. Take the topic from Module 1's exercise
2. Write 5 orthogonal sub-questions for that topic
3. Self-check: Are the sub-questions truly independent? Does any pair overlap?
4. Do the 5 questions collectively cover the full topic? What might be missing?

### Quiz

1. **Multiple choice**: What does "orthogonal" mean in the context of sub-question decomposition?
   - a) Questions that build on each other sequentially
   - b) Questions that are independent and collectively cover the topic without overlap
   - c) Questions sorted by difficulty
   - d) Questions that all explore the same angle from different perspectives
   **Answer**: b

2. **Multiple choice**: What does source curation do in Phase 2.5?
   - a) Deletes all sources to save space
   - b) Ranks sources into primary, secondary, and supporting tiers
   - c) Translates sources into the target language
   - d) Sends sources to the user for manual review
   **Answer**: b

### Recap

- Phase 0.5 grounds sub-questions in available online information
- Phase 1 decomposes the topic into orthogonal, non-overlapping sub-questions
- Phase 2 dispatches parallel researcher agents (4-5 per batch, 5-7 searches each)
- Deep reports use recursive tree exploration (depth-2 branching)
- Phase 2.5 curates sources into quality tiers for detailed and deep reports

---

## Module 3: Writing, Review & Finalization

### Theory (3 min)

Once research is complete, the pipeline aggregates findings and hands them
to specialized writing and review agents.

**Phase 3 — Context aggregation**:
- Merges all researcher outputs into a single context
- Deduplicates overlapping findings across agents
- Enforces a 25,000-word context limit to keep the writer focused

**Phase 4 — Writer agent**:
- Produces the full report draft using the configured tone and citation format
- 13 tones available: objective, analytical, critical, persuasive, formal,
  informal, enthusiastic, cautionary, comparative, speculative, investigative,
  advisory, balanced
- Citations are formatted inline according to your chosen standard

**Phase 4.5 — Optional image generation**:
- Excalidraw diagrams and illustrations can be generated to accompany the report
- Activated via configuration toggle

**Phase 5 — Structural review**:
Five review dimensions scored by the review agent:

| Dimension | What It Evaluates |
|-----------|-------------------|
| Completeness | Are all sub-questions adequately addressed? |
| Coherence | Does the report flow logically between sections? |
| Source diversity | Are claims backed by multiple independent sources? |
| Depth | Is the analysis sufficiently detailed for the report type? |
| Clarity | Is the writing accessible to the target audience? |

- Accept threshold: **0.82** (weighted average across all dimensions)
- If below threshold: the writer receives specific feedback and revises
- Maximum **1 revision iteration** to keep costs predictable

**Phase 6 — Finalization**:
- Accepted draft is saved to `output/report.md`
- Cost accumulation is logged
- Summary of the report is displayed

### Demo

Walk through how raw research becomes a polished report:
1. Show the aggregated context from researcher agents
2. Demonstrate writer configuration (tone, citation format)
3. Show a sample draft and its review scores across 5 dimensions
4. Walk through a revision cycle: feedback given, writer revises
5. Show the finalized report in the output directory

### Exercise

Ask the user to:
1. Read the sample report excerpt below (or use one from a previous exercise)
2. Score it on each of the 5 review dimensions (1-10 scale)
3. Which dimension would they score lowest? Why?
4. Write one sentence of feedback the review agent might give

### Quiz

1. **Multiple choice**: Which of the following is NOT one of the 5 structural review dimensions?
   - a) Completeness
   - b) Source diversity
   - c) Word count
   - d) Clarity
   **Answer**: c

2. **Multiple choice**: What happens when the review score falls below 0.82?
   - a) The report is discarded and research starts over
   - b) The writer receives feedback and revises (max 1 iteration)
   - c) The user must manually rewrite the report
   - d) Additional researcher agents are dispatched
   **Answer**: b

### Recap

- Phase 3 aggregates and deduplicates research (25,000-word limit)
- Phase 4 writes the report with configurable tone and citation format
- Phase 5 reviews on 5 dimensions with a 0.82 accept threshold
- Maximum 1 revision iteration keeps costs predictable
- Phase 6 finalizes the accepted draft to output/report.md

---

## Module 4: Claims Verification

### Theory (3 min)

A research report is only as trustworthy as its citations. cogni-gpt-researcher
includes a dedicated verification skill that checks whether the report's claims
are actually supported by its sources.

**Two-skill architecture**:
- **research-report** — runs the full research pipeline (Phases 0.5-6)
- **verify-report** — runs in a fresh context window to verify claims

Why separate? The writer agent has seen all sources and may develop
"attention bias" — assuming claims are supported because the source was in
context. A fresh context window forces genuine re-verification.

**Two verification modes**:
- **Mode A**: Verify a cogni-gpt-researcher project (auto-detects draft + sources)
- **Mode B**: Verify a standalone markdown file (any .md report)

**Claim extraction**:
- Extracts 10-30 verifiable claims from the report
- Claims are prioritized by type:

| Priority | Claim Type | Example |
|----------|------------|---------|
| 1 | Statistical | "Market grew 23% year-over-year" |
| 2 | Attribution | "According to Gartner, cloud spending..." |
| 3 | Causal | "Remote work led to a 40% increase in..." |
| 4 | Definitional | "Zero trust architecture is defined as..." |

**Claims submission**: Each extracted claim is verified against its cited
source URLs using cogni-claims (Course 3).

**Five deviation types**:

| Deviation | Meaning |
|-----------|---------|
| Misquotation | Source says something different than what's cited |
| Unsupported conclusion | Claim goes beyond what the source actually states |
| Selective omission | Report omits context that changes the source's meaning |
| Data staleness | Source data is outdated relative to the claim |
| Source contradiction | Two cited sources directly contradict each other |

**Interactive review**: For each flagged claim, you choose:
proceed, fix, drop, accept, or inspect the source directly.

**Revision loop**: Up to 3 iterations. The claims verification rate feeds
back into the review scoring from Phase 5.

### Demo

Walk through verifying claims from a sample report:
1. Run verify-report on a completed research project
2. Show extracted claims and their types
3. Walk through a flagged claim — show the deviation type
4. Demonstrate each deviation type with a concrete example
5. Show the interactive review: choose fix for one, accept for another

### Exercise

Ask the user to:
1. Open `_teacher-exercises/research-notes.md` (or a report from a previous exercise)
2. Identify 3 claims that could be verified
3. For each claim: What type is it (statistical, attribution, causal, definitional)?
4. What deviation type would you watch for in each?

### Quiz

1. **Multiple choice**: What is "selective omission"?
   - a) A source that no longer exists online
   - b) The report omits context that changes the source's meaning
   - c) A citation formatted incorrectly
   - d) A claim with no source attached
   **Answer**: b

2. **Multiple choice**: Why does verify-report use a separate context window from research-report?
   - a) To save memory
   - b) To avoid attention bias from the writing phase
   - c) Because the tools are incompatible
   - d) To run faster
   **Answer**: b

### Recap

- Verification runs in a fresh context window to avoid attention bias
- Two modes: verify a project (auto-detect) or a standalone markdown file
- 10-30 claims extracted and prioritized: statistical > attribution > causal > definitional
- 5 deviation types: misquotation, unsupported conclusion, selective omission, data staleness, source contradiction
- Interactive review lets you proceed, fix, drop, accept, or inspect each claim

---

## Module 5: Export, Resumability & Advanced Features

### Theory (3 min)

Once your report is written and verified, the export skill transforms it into
client-ready formats. The plugin also supports resumability and cost tracking
to handle long-running research gracefully.

**Export formats**:

| Format | Method | Best For |
|--------|--------|----------|
| Markdown | Copy | Internal sharing, version control |
| HTML | Self-contained with ToC + clickable sources | Digital delivery, email |
| PDF | via document-skills or weasyprint | Formal deliverables, print |
| DOCX | via document-skills or pandoc | Client editing, collaboration |

**Theme branding**: `design-variables.json` controls colors, fonts, and link
styling across all export formats. Consistent branding without manual formatting.

**Hyperlink preservation**: Source links remain clickable across all formats —
HTML, PDF, and DOCX all preserve hyperlinks to original sources.

**Resumability**:
- `execution-log.json` tracks which phase each agent has completed
- If a run is interrupted (network issue, timeout, cost pause), resuming
  picks up from the first incomplete phase — no work is lost
- Especially valuable for deep reports that may run for several minutes

**Language support**:
- EN (default) — standard web sources
- DE — activates DACH-specific authority sources and bilingual search queries

**Cost tracking**:
- Per-agent cost estimates are accumulated in `execution-log.json`
- Review the cost breakdown after each run to understand spending patterns

**Advanced options**:
- Sub-question count override (increase or decrease from defaults)
- Domain filtering (restrict searches to specific domains)
- Pre-specified source URLs (ensure certain sources are included)
- Image generation toggle (Excalidraw diagrams in the report)

### Demo

Walk through exporting a report:
1. Export a completed report to HTML format
2. Show the self-contained HTML: table of contents, clickable source links
3. Show theme application via design-variables.json
4. Open `execution-log.json` and walk through the cost breakdown
5. Show how resuming an interrupted run skips completed phases

### Exercise

Ask the user to:
1. Map their current research workflow to the cogni-gpt-researcher pipeline
2. Identify: Where do they spend the most time today? (source finding? writing? formatting?)
3. Which phases of the pipeline would save them the most effort?
4. Which export format would they use for their most common deliverable?

### Quiz

1. **Hands-on**: Describe your ideal report configuration for your next client research deliverable. Include: report type, tone, citation format, source mode, and export format.

2. **Multiple choice**: What happens if a research run is interrupted midway?
   - a) All progress is lost and you must start over
   - b) The execution log tracks completed phases; resuming continues from where it stopped
   - c) A partial report is saved but cannot be completed
   - d) The system automatically retries from the beginning
   **Answer**: b

### Recap

- Export to Markdown, HTML, PDF, or DOCX with preserved hyperlinks
- Theme branding via design-variables.json for consistent styling
- Resumability via execution-log.json — interrupted runs continue, not restart
- Cost tracking shows per-agent spending
- Advanced options: sub-question count, domain filtering, pre-specified sources

---

## Course Completion

You now have a complete understanding of the cogni-gpt-researcher pipeline —
from configuring a research question to delivering a verified, branded report.

**The full research pipeline**:
```
Configure → Decompose → Research → Aggregate → Write → Review → Verify → Export
```

Each phase is handled by specialized agents, and you control the key decisions:
topic framing, report depth, tone, and which claims to accept or revise.

**Connections to other courses**:
- **Claims verification** (Course 3) — cogni-claims powers the verify-report
  skill for citation checking
- **Narrative polish** (Course 3) — cogni-copywriting and cogni-narrative can
  further refine your report before delivery
- **Visual export** (Course 7) — cogni-visual can transform report content
  into presentations, journey maps, or web narratives

**Your updated cogni-works toolkit** (10 plugins):
1. **Claude Cowork** — Your agentic AI platform
2. **cogni-workspace** — Shared project foundation
3. **cogni-obsidian** — Knowledge management dashboard
4. **cogni-copywriting** — Document polishing and stakeholder review
5. **cogni-narrative** — Executive narrative transformation
6. **cogni-claims** — Citation verification
7. **cogni-tips** — Strategic trend research pipeline
8. **cogni-portfolio** — Product and service messaging
9. **cogni-visual** — Presentations and visual deliverables
10. **cogni-gpt-researcher** — Research reports and intelligence

**The consulting workflow**:
```
Workspace Setup → Research → Analyze → Write → Verify → Polish → Present
```

Every step has a cogni-works plugin. Your expertise drives the strategy;
the tools execute the heavy lifting.
