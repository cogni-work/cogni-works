# Sub-Question Generation Reference

## Context-Aware Decomposition

Before generating sub-questions, Phase 0.5 performs preliminary web searches on the topic. Use these search results to ground your decomposition in reality — if preliminary results show the topic is dominated by a regulatory debate, ensure one sub-question targets that angle rather than generic templates.

## Decomposition Strategy

Good sub-questions are:
- **Orthogonal**: Each covers a distinct aspect (no overlap)
- **Searchable**: Can be answered via web search (not too abstract)
- **Specific**: Narrow enough for focused research
- **Collectively exhaustive**: Together they cover the full topic
- **Grounded**: Informed by preliminary search results — don't target angles with no available content

## Templates by Topic Type

### Technology Topics
1. What is [X] and how does it work? (fundamentals)
2. What is the current state of [X] development? (status quo)
3. Who are the key players/organizations in [X]? (landscape)
4. What are the main challenges/limitations of [X]? (obstacles)
5. What are the practical applications/implications of [X]? (impact)

### Business/Industry Topics
1. What is the market size and growth trajectory of [X]? (market)
2. Who are the major competitors in [X]? (landscape)
3. What are the key trends driving [X]? (trends)
4. What are the regulatory considerations for [X]? (compliance)
5. What are the strategic implications for businesses? (strategy)

### Scientific/Research Topics
1. What is the current scientific understanding of [X]? (state of knowledge)
2. What are the recent breakthrough findings in [X]? (discoveries)
3. What methodologies are used to study [X]? (methods)
4. What are the open questions and debates in [X]? (gaps)
5. What are the practical implications of [X] research? (applications)

## Search Guidance Generation

For each sub-question, generate `search_guidance` that helps the section-researcher:
- Suggest specific search terms and operators
- Identify authoritative source types (academic, government, industry)
- Note any region-specific considerations
- Flag potential misinformation risks

**Recency hints**: When the topic involves rapidly evolving fields or annual publications (DORA, Gartner, industry surveys), include a note in `search_guidance` to search for the latest edition by year. This prevents researchers from citing outdated editions when newer ones exist.

Example:
```
query: "What are the leading post-quantum cryptographic algorithms?"
search_guidance: "Focus on NIST PQC standardization. Key terms: CRYSTALS-Kyber, CRYSTALS-Dilithium, SPHINCS+, lattice-based. Authoritative sources: NIST, IETF, academic papers. Avoid vendor marketing."
```

Example with recency hint:
```
query: "What do current DevOps metrics reveal about AI adoption impact?"
search_guidance: "Search for the latest DORA report by year (e.g., 'DORA 2025', 'DORA 2026'). Also check State of DevOps, Accelerate metrics. Prefer the most recent annual edition over older ones."
```
