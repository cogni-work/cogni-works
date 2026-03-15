# Prior Art & Architectural Inspiration

cogni-research is an independent implementation built on Claude Code plugin primitives. The following projects influenced its multi-agent research architecture:

## GPT-Researcher

- **Author:** Assaf Elovic / Tavily
- **License:** Apache-2.0
- **Repository:** https://github.com/assafelovic/gpt-researcher

**Influences adopted:**
- Parallel multi-agent web research (one researcher per sub-question)
- Adaptive recursive tree exploration for deep research (within-branch recursion at decreasing breadth)
- Iterative review cycles with quality gates

**Key divergences:**
- Replaces human-in-the-loop LangGraph review with automated three-layer claim assurance (evidence confidence + claim quality + source verification)
- Single-agent internal recursion (findings-creator-deep) instead of exponential sub-agent spawning — fixed cost per branch vs O(breadth^depth)
- Entity-driven Obsidian-browsable workspace instead of artifact pipeline
- Native bilingual DACH support (EN + DE queries, German source authority scoring)

## STORM

- **Author:** Stanford OVAL (Open Virtual Assistant Lab)
- **Paper:** arXiv:2402.14207
- **License:** MIT

**Influences adopted:**
- Editorial workflow pattern: research → write → review → revise
- Multi-perspective synthesis (dimension-based decomposition mirrors STORM's perspective-driven article generation)

**Key divergences:**
- MECE dimensional decomposition with PICOT-structured questions instead of Wikipedia-style perspective gathering
- Three-layer claim assurance replaces STORM's grounding approach
- Separation of research pipeline (cogni-research) from narrative synthesis (cogni-narrative)
