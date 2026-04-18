# Index

This is the content catalog for **insight-wave**. Every wiki page is listed here with a one-line summary. Claude consults this file before drilling into specific pages.

## Categories

### Ecosystem

- [[ecosystem-overview]] — High-level shape of the 13-plugin monorepo for consulting, sales, and marketing on Claude Code.

### Architecture

- [[arch-design-philosophy]] — The six recurring design principles (data isolation, progressive disclosure, slug-based lookups, brief-based rendering, quality gates, orchestrator pattern).
- [[arch-plugin-anatomy]] — Standard directory structure, manifest, SKILL.md, agent, hook, and naming conventions for any insight-wave plugin.
- [[arch-er-diagram]] — Cross-plugin entity model, four architectural layers, bridge files, frontmatter contracts, and data isolation in practice.

### Cross-cutting concepts

- [[concept-agent-model-strategy]] — Sonnet/opus/haiku per agent role; the cost-per-task rationale.
- [[concept-bridge-files]] — Versioned JSON exports between plugins; the table of all six current bridge files.
- [[concept-brief-based-rendering]] — cogni-visual splits content specification (briefs) from rendering; briefs are reviewable independently.
- [[concept-claim-lifecycle]] — The unverified → verified | deviated → resolved state machine for sourced assertions.
- [[concept-claims-propagation]] — Auto-log claims, verify in cogni-claims, propagate corrections back, cascade staleness downstream.
- [[concept-data-isolation]] — Each plugin owns its data; cross-plugin reads through path refs, bridge files, or frontmatter contracts only.
- [[concept-data-model-patterns]] — Entity slugs, project directory layout, Feature × Market join, IS/DOES/MEANS messaging, source lineage, Obsidian-browsability.
- [[concept-four-layer-architecture]] — Orchestration / Foundation / Data / Output layers and the dependency direction.
- [[concept-mcp-server-map]] — Excalidraw, claude-in-chrome, and pencil MCP servers and which plugins consume them.
- [[concept-multilingual-support]] — 10 markets, character encoding discipline, per-market authority sources, section header mappings.
- [[concept-naming-conventions]] — Tiered skill names, role-based agent names, kebab-case slugs, JSON-output script names.
- [[concept-orchestrator-pattern]] — cogni-consulting tracks engagement state and dispatches; never produces content.
- [[concept-plugin-maturity-model]] — Maturity hard-derived from version (0.0.x Incubating → 2.x.x Established); marketplace.json mirror discipline.
- [[concept-progressive-disclosure]] — Skills and agents load reference material at the step that needs it, not at startup.
- [[concept-quality-gates]] — The three-layer pattern (structural validation, quality assessment, stakeholder review) that gates downstream generation.
- [[concept-readme-convention]] — The 16-section IS/DOES/MEANS plugin README structure; auto-generated vs hand-written sections.
- [[concept-script-output-format]] — Universal `{"success": bool, "data": {...}, "error": "..."}` JSON contract; stdlib only.
- [[concept-slug-based-lookups]] — Kebab-case identifiers across plugins; double-dash for paired entities; UUIDs for nameless entities.
- [[concept-theme-inheritance]] — All visual plugins read theme from cogni-workspace via design-variables CSS pattern.
- [[concept-trends-portfolio-bridge]] — The most complex single integration: three bridge files in two directions between cogni-trends and cogni-portfolio.

### Plugins

- [[plugin-cogni-claims]] — Claim verification and management: submit, verify against cited URLs, detect deviations, resolve.
- [[plugin-cogni-consulting]] — Double Diamond orchestrator (Discover → Define → Develop → Deliver) that dispatches to other plugins at phase boundaries.
- [[plugin-cogni-copywriting]] — Document polishing with messaging frameworks, persona Q&A review, Power Positions sales enhancement.
- [[plugin-cogni-help]] — Central help hub: courses, plugin guides, workflow templates, troubleshooting, cheatsheets, GitHub issue filing.
- [[plugin-cogni-marketing]] — B2B content engine bridging trends (GTM paths) and portfolio (propositions) into channel-ready content across the funnel.
- [[plugin-cogni-narrative]] — Story-arc engine with 10 frameworks (Corporate Visions, JTBD, Strategic Foresight, Trend Panorama and 6 more) and 8 narrative techniques.
- [[plugin-cogni-portfolio]] — IS/DOES/MEANS messaging at Feature × Market with quality gates and 8 industry taxonomies.
- [[plugin-cogni-research]] — Multi-agent research reports with localized search across 18 markets, STORM-inspired editorial workflow, claims verification.
- [[plugin-cogni-sales]] — B2B sales pitches via Corporate Visions Why Change methodology; deal-specific or segment-reusable.
- [[plugin-cogni-trends]] — TIPS strategic trend scouting (Trends, Implications, Possibilities, Solutions) with bilingual web research.
- [[plugin-cogni-visual]] — Brief-driven rendering of slides, infographics, web narratives, storyboards, and enriched HTML reports.
- [[plugin-cogni-website]] — Multi-page customer websites assembled from portfolio, marketing, trend, and research content.
- [[plugin-cogni-wiki]] — Karpathy-style LLM wiki engine; the engine that runs this very wiki.
- [[plugin-cogni-workspace]] — Foundation plugin: shared infra, MCP install, theme management, workspace health, vault integration.

### Workflows

- [[workflow-consulting-engagement]] — Full Double Diamond pipeline orchestrated by cogni-consulting (Discover → Define → Develop → Deliver).
- [[workflow-content-pipeline]] — Marketing content generation through narrative arc shaping, copywriting polish, and visual rendering.
- [[workflow-install-to-infographic]] — First-run workflow: install marketplace, set up workspace, extract theme, render first infographic.
- [[workflow-portfolio-to-pitch]] — Generate deal-specific or segment-reusable Why Change sales pitches from portfolio data.
- [[workflow-portfolio-to-website]] — Assemble multi-page customer website from portfolio model and workspace theme.
- [[workflow-research-to-report]] — Verified, polished research report as themed HTML with claims-verified citations and Chart.js visualizations.
- [[workflow-trends-to-solutions]] — Turn scouted trends into ranked solution blueprints with TIPS network and visual deliverables.
