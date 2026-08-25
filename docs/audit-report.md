# Documentation Drift Report

Generated: 2026-08-25
Repo: /Users/stephandehaas/GitHub/dev/insight-wave

Output of a full `/doc-audit all` run against the current **8-plugin** ecosystem, replacing the prior 2026-06-14 snapshot. That snapshot described a 13-plugin roster and predated the absorption of cogni-claims, cogni-narrative, cogni-copywriting and cogni-visual into cogni-workspace, the absorption of cogni-research and cogni-wiki into cogni-knowledge, and the retirement of cogni-help and cogni-consulting. The roster is read from `.claude-plugin/marketplace.json` `plugins[]`, which is its single source of truth.

This run uses the 18-check schema (the prior snapshot predates Check 18, Narrative Conformance). Verified false positives are corrected and recorded under "Audit notes".

**Reading convention.** This report is a snapshot dated above. Where a plugin name appears below that is absent from `plugins[].name` — `cogni-visual`, `cogni-wiki`, `cogni-research`, `cogni-consulting`, `cogni-claims`, `cogni-narrative`, `cogni-copywriting`, `cogni-help` — it is naming a **stale reference held by the file under discussion as of this date**, or recording lineage. It is never an assertion that the plugin is live. Check 17 exists precisely to enumerate those references, so it cannot do its job without naming them.

## Repository-Level

| Check | Verdict | Detail |
|-------|---------|--------|
| Root README & ecosystem (Check 12) | OK | "Plugins at a glance" table 8/8 matches `marketplace.json`; all plugin links resolve; `assets/architecture.{svg,excalidraw}` both present; Security & compliance and MCP servers subsections present; no commercial keywords outside the designated zones |
| Deploy Data Freshness (Signal 10d) | DRIFT | `deploy-data.json` researched 2026-04-16 — **131 days**, past the 90-day threshold. Companion `deploy-guide.md` present. Run `/doc-deploy refresh` |
| Known Issues Registry (Check 11) | OK | `known-issues.json` (2 issues) + `known-issues.md` companion present; `docs/known-issues.md` consuming-repo mirror present |
| Removed/Archived Plugin Refs (Check 17) | DRIFT | 125 raw findings across 26 files (excluding this report's own enumeration); **14 actionable** after allowlist review (see the dated section below). The remainder are lineage prose or helper false positives |
| docs/ canonical set (Check 8, repo-level) | OK | All 7 canonical files present; 8/8 plugin guides; 7 workflow guides, **0 orphaned**; no render-vs-source lag; 1 forwarder stub with 0 stale inbound links |

## Summary (Per-Plugin)

| Plugin | Components | Architecture | Descriptions | Dependencies | plugin.json | CLAUDE.md | Messaging | docs/ | Commercial | Doc Logic | Deploy | Known Issues | Maturity | Readiness | Markets | Entry Point | Narrative | Overall |
|--------|-----------|--------------|-------------|-------------|-------------|-----------|-----------|-------|------------|-----------|--------|--------------|----------|-----------|---------|-------------|-----------|---------|
| cogni-knowledge | OK | OK | OK | OK | OK | OK | OK | OK | OK | DRIFT | DRIFT | OK | OK | OK | OK | OK | OK | NEEDS UPDATE |
| cogni-consult | OK | OK | OK | DRIFT | OK | OK | OK | OK | OK | DRIFT | DRIFT | OK | OK | OK | OK | OK | DRIFT | NEEDS UPDATE |
| cogni-workspace | OK | OK | DRIFT | OK | DRIFT | OK | OK | OK | OK | DRIFT | DRIFT | OK | OK | OK | OK | n/a | DRIFT | NEEDS UPDATE |
| cogni-trends | OK | OK | OK | DRIFT | OK | OK | OK | OK | OK | DRIFT | DRIFT | OK | OK | OK | OK | OK | OK | NEEDS UPDATE |
| cogni-portfolio | OK | OK | OK | DRIFT | OK | OK | OK | OK | OK | OK | DRIFT | OK | OK | OK | OK | OK | OK | NEEDS UPDATE |
| cogni-marketing | OK | OK | OK | DRIFT | OK | OK | OK | OK | OK | OK | DRIFT | OK | OK | OK | OK | OK | OK | NEEDS UPDATE |
| cogni-sales | OK | DRIFT | OK | DRIFT | OK | OK | OK | OK | OK | DRIFT | DRIFT | OK | OK | OK | OK | n/a | OK | NEEDS UPDATE |
| cogni-website | OK | DRIFT | OK | OK | OK | OK | OK | OK | OK | DRIFT | DRIFT | OK | OK | OK | OK | OK | OK | NEEDS UPDATE |

**Overall: NEEDS UPDATE** — 0 of 8 plugins have component-table drift, all 8 carry strong messaging, and every plugin guide now covers its plugin's full skill set; but 5 plugins have a stale Dependencies table naming an absorbed plugin, 6 lack artifact trails in "What it does", 2 carry a wrong version annotation, and the repository-level deploy data has aged past its threshold. `n/a` in Entry Point means the plugin ships no `*-resume` skill, which is a silent skip, not a finding.

## cogni-knowledge

### Documentation Logic Drift
- DRIFT (Signal 10a): 21 skills are registered in `pipeline-registry.json`, but **0 of the 15** `## What it does` items carry a ` → ` artifact trail. Readers cannot see which artifact each phase emits or which skill consumes it next — the plugin's whole value is a seven-phase pipeline, so the missing trail is most costly here. Remediation: `/doc-generate cogni-knowledge --section=what-it-does`.

### Deployment Data Freshness
- DRIFT (Signal 10d, repo-level): see the Repository-Level table.

### Everything else
- Components, Architecture, Descriptions, Dependencies, plugin.json, CLAUDE.md, Messaging, docs/, Commercial, Known Issues, Maturity, Readiness, Markets, Entry Point, Narrative: OK. The `cogni-wiki` mention in `## Dependencies` is a correct **negative** statement ("not an external dependency: the wiki engine is vendored under `scripts/vendor/cogni-wiki/`") and is not drift — see Audit notes.

## cogni-consult

### Dependency Table Drift
- DRIFT: the `## Dependencies` table row `cogni-visual / document-skills` names **cogni-visual**, which is absent from `plugins[]` — its skills were absorbed into cogni-workspace. Retarget the row to `cogni-workspace / document-skills`.

### Documentation Logic Drift
- DRIFT (Signal 10a): 9 registered skills; **7 of 8** `## What it does` items lack a ` → ` artifact trail.

### Narrative Conformance
- DRIFT: `## What it means for you` is **158 words** against a 60–120 band (±15%).
- DRIFT: `## How it works` is **370 words** against a 150–300 band (±15%).
- No scaffold-label leakage; all required hand-written sections present. Remediation: `/doc-power cogni-consult`.

## cogni-workspace

### Description Alignment
- DRIFT: `plugin.json` `description` (784 chars) names capabilities the `marketplace.json` copy (605 chars) omits — "story-arc narrative composition with quality scoring and derivative formats, and executive copywriting with seven messaging frameworks, arc-aware polish and EN/DE-pivot translation". The marketplace copy predates the narrative/copywriting absorption. Remediation: `/doc-sync cogni-workspace`.

### plugin.json
- DRIFT: the plugin ships **26 agents** but `keywords[]` contains no `agent` term (current keywords: workspace, themes, orchestrator, insight-wave, obsidian, vault, terminal, mcp, hooks, wiki, ask, claim-verification, fact-checking, source-validation, cross-plugin-contract).

### docs/ Staleness
- OK: `docs/plugin-guide/cogni-workspace.md` covers **26 of 26** skills. The four that were absent when this run started — `cogni-issues`, `render-html-slides`, `review-brief`, `workspace-dashboard` — were added in the same change that produced this report.

### Documentation Logic Drift
- DRIFT (Signal 10a): 26 registered skills; **11 of 13** `## What it does` items lack a ` → ` artifact trail.

### Narrative Conformance
- DRIFT: title paragraph is **42 words** against a 15–25 band (±15%).
- DRIFT: `## What it is` is **95 words** against a 40–80 band (±15%).
- DRIFT: `## What it means for you` is **140 words** against a 60–120 band (±15%).
- No scaffold-label leakage. Remediation: `/doc-power cogni-workspace`.

### Entry Point
- n/a — `scan.resume_skill` is null (no `skills/*-resume/` directory). Silent skip.

## cogni-trends

### Dependency Table Drift
- DRIFT: the `## Dependencies` table lists **cogni-visual** ("Themed HTML report via enrich-report; Big Block diagrams from value-modeler solution networks"), which is off-roster — `enrich-report` is now a cogni-workspace skill, and the row duplicates what the adjacent cogni-workspace row already covers.
- DRIFT: undocumented dependency — `skills/value-modeler/references/workflow-phases/phase-2-solutions.md` invokes `cogni-knowledge:knowledge-ingest-source`, but no `cogni-knowledge` row exists in the table.

### Documentation Logic Drift
- DRIFT (Signal 10a): **1 of 7** `## What it does` items lacks a ` → ` artifact trail (item 7, "Catalog curated solutions…"). The strongest artifact-trail coverage in the ecosystem; one item short of clean.

## cogni-portfolio

### Dependency Table Drift
- DRIFT: the `## Dependencies` table lists **cogni-visual** ("Pitch output consumable by story-to-slides, story-to-web, and story-to-storyboard"). Those three skills now live in cogni-workspace; retarget the row.

### Everything else
- Components, Architecture, Descriptions, plugin.json, CLAUDE.md, Messaging, docs/, Commercial, Doc Logic, Known Issues, Maturity, Readiness, Markets, Entry Point, Narrative: OK. Artifact-trail coverage is **14 of 14** — the reference implementation for Signal 10a.

## cogni-marketing

### Dependency Table Drift
- DRIFT: the `## Dependencies` table lists **cogni-visual** ("Slide decks and visual assets from content briefs") but has **no cogni-workspace row**, while `skills/abm/SKILL.md:124` and `skills/thought-leadership/SKILL.md:142,145` invoke `/cogni-workspace:story-to-slides` and `cogni-workspace:copywriter` directly. The stale row stands in for the live dependency it should have become.

### Everything else
- All other checks OK. Artifact-trail coverage is 6 of 6.

## cogni-sales

### Architecture Tree Drift
- DRIFT: the tree annotates `.claude-plugin/  Plugin manifest (v0.4.3)` but `plugin.json` is at **0.4.7**.

### Dependency Table Drift
- DRIFT: the `## Dependencies` table lists **cogni-visual** ("PPTX generation from sales presentation"). PPTX generation is now reached through cogni-workspace (`agents/pptx.md`, `skills/render-html-slides`). The same stale claim is mirrored in `cogni-sales/CLAUDE.md:86`.

### Documentation Logic Drift
- DRIFT (Signal 10a): **6 of 7** `## What it does` items lack a ` → ` artifact trail.

### Entry Point
- n/a — `scan.resume_skill` is null. Silent skip.

## cogni-website

### Architecture Tree Drift
- DRIFT: the tree annotates `.claude-plugin/  Plugin manifest (v0.0.6)` but `plugin.json` is at **0.0.15**.

### docs/ Staleness
- OK: `docs/plugin-guide/cogni-website.md` covers **6 of 6** skills. `website-legal` was absent when this run started — below Check 8's 2+ DRIFT threshold, but a violation of doc-hub's skill-coverage rule ("every skill in the JSON `skills` array must appear in the guide") — and was added in the same change that produced this report.

### Documentation Logic Drift
- DRIFT (Signal 10a): 6 registered skills; **0 of 9** `## What it does` items carry a ` → ` artifact trail.

## Check 17 — Removed/Archived Plugin References (as of 2026-08-25)

Each entry below reports a **stale reference held by the named file**. Naming a retired plugin here is a description of that file's current text, not a claim that the plugin is live.

**Actionable — the reference asserts a live dependency, dispatch target or component:**

| File:line | Names | What it wrongly asserts |
|---|---|---|
| `docs/ecosystem-overview.md:140,323,325,327` | cogni-visual | Named in three workflow-table pipelines (Portfolio to Pitch, Trends to Solutions, Content Pipeline) and one hand-off line, as though the deck/visual stage still runs there |
| `cogni-consult/README.md:236` | cogni-visual | `## Dependencies` row — deliverable export |
| `cogni-sales/README.md:159`, `cogni-sales/CLAUDE.md:86` | cogni-visual | `## Dependencies` row — PPTX generation |
| `cogni-marketing/README.md:190` | cogni-visual | `## Dependencies` row — slide decks and visual assets |
| `cogni-portfolio/README.md:220`, `cogni-portfolio/CLAUDE.md:195` | cogni-visual | `## Dependencies` row — pitch output consumed by `story-to-*` |
| `cogni-trends/README.md:255` | cogni-visual | `## Dependencies` row — themed HTML report and Big Block diagrams |
| `cogni-workspace/CLAUDE.md:162,166,174` | cogni-visual | Adoption notes describing test fixtures and guards carried across the absorption; borderline lineage, but phrased in a way that reads as a live sibling tree |

Each names **cogni-visual**, whose skills were absorbed into cogni-workspace. All lie outside this report's own change scope — the `docs/plugin-guide/` and `docs/audit-report.md` surfaces — and are listed here so the next pass can retarget them. See "Recommended fix order" items 2 and 7.

**Resolved in the change that produced this report:** the equivalent live claims in `docs/plugin-guide/cogni-knowledge.md` (a table row claiming `knowledge-setup` dispatches `cogni-wiki:wiki-setup`, contradicted by `knowledge-setup/SKILL.md:11,127`, plus cogni-research described as an available sibling plugin), `cogni-sales.md`, `cogni-trends.md`, `cogni-marketing.md`, `cogni-consult.md`, `cogni-workspace.md` and `cogni-portfolio.md`. Those guides now hold retired-plugin names only as lineage, as vendored-path literals, or in negative statements ("no longer dispatches …").

**Not actionable — legitimate lineage prose** (past-tense retirement, successor, or absorption records): `docs/contributing/cogni-consult-evaluation.md` (11), `docs/contributing/plugin-absorption-slicing.md` (8), `docs/architecture/loop-health-map.md` (7), `docs/plugin-guide/cogni-workspace.md` "Absorbed from the retired …" prose (6), `docs/plugin-guide/cogni-consult.md:13,148`, `docs/workflows/consulting-engagement.md:7`, `cogni-knowledge/CLAUDE.md` (28, describing the vendored engine and archived chain), `cogni-knowledge/README.md:225`, and 8 of the 11 in `cogni-workspace/CLAUDE.md` (the other 3 are listed as actionable above).

**Frozen by policy — do not reconcile:** `docs/relicensing/vendored-license-audit.md` (10). Root `CLAUDE.md` designates this a frozen attestation recording the repository as of its stated audit date; its findings are history by design.

## Audit notes

Verified false positives, corrected in the verdicts above:

- **Architecture tree directory scan — not drift.** A naive scan reported `skills/`, `agents/`, `scripts/`, `references/` and others "missing from the tree" on every plugin. All are present; the scan failed on the box-drawing prefix (`├── `). Separately, `cogni-workspace`'s `output-styles/` and `cogni-website`'s `scripts/` / `references/` are nested (`assets/output-styles/`, `skills/*/references/`), not top-level. Only the two version annotations are real Architecture drift.
- **Components table — not drift.** Rows for `claims-store.sh`, `on-session-start.sh`, `on-session-start-language.sh` and `portability-utils.sh` in `cogni-workspace` resolve to real files in nested locations (`skills/claims/scripts/`, `hooks/`, `bash/`). Command rows written with a leading `/` in `cogni-marketing` and `cogni-sales`, and the `ensure-excalidraw-canvas` hook row in `cogni-portfolio`, all resolve on disk.
- **cogni-knowledge Dependencies — not drift.** `## Dependencies` names `cogni-wiki` only to state it is *not* an external dependency. Check 4 counts this as satisfied.
- **Undocumented-dependency grep — mostly prose.** Matches for `cogni-portfolio` / `cogni-trends` in cogni-knowledge, `cogni-consult` / `cogni-marketing` / `cogni-sales` in cogni-workspace, and `cogni-marketing` in cogni-sales all resolve to prose, CHANGELOG, eval-fixture or reference-material mentions rather than invocations. Only the two real invocations (cogni-trends → cogni-knowledge, cogni-marketing → cogni-workspace) are reported.
- **Check 9 commercial tone — not a violation.** The word "pricing" in `cogni-portfolio`'s `## Why this exists` problem table describes the *customer's* scattered artifacts ("Propositions, competitive intel, and pricing live in disconnected spreadsheets"), not a commercial offer for the plugin.
- **Check 17 token class — helper false positives.** `cogni-x` (generic placeholder for any ecosystem plugin), `cogni-work` / `cogni-works` (the brand and the bundled theme name), `cogni-example` (a JSON sample value), `cogni-plugin` (a naming-convention phrase), and `cogni-issues` (a cogni-workspace **skill**, not a plugin) are not removed plugins. `cogni-docs` and `cogni-service` are live plugins that ship from `cogni-work/managed-service` and are correctly named as external.
- **Signal 10a mapping caveat.** Several plugins register more skills than they have `## What it does` items, so the registered-skill → numbered-item mapping is many-to-one and not mechanically decidable. The reported figure is the measured artifact-trail coverage of the items themselves, which is the verifiable part of the signal.
- **Maturity — cogni-knowledge callout correctly absent.** At `1.0.97` it derives to Released, which is exempt from a maturity callout by design; `marketplace.json` agrees.

## Recommended fix order

1. **Refresh deployment data:** `/doc-deploy refresh` — clears the repo-level Signal 10d finding that currently marks every plugin row.
2. **Retarget stale dependency rows:** edit the `## Dependencies` tables in cogni-consult, cogni-trends, cogni-portfolio, cogni-marketing and cogni-sales (plus `cogni-sales/CLAUDE.md`, `cogni-portfolio/CLAUDE.md`) — `cogni-visual` → `cogni-workspace`; add the missing `cogni-workspace` row to cogni-marketing and the missing `cogni-knowledge` row to cogni-trends. Content correction, no `/doc-generate` pass.
3. **Fix version annotations:** `/doc-generate cogni-sales --section=architecture` and `/doc-generate cogni-website --section=architecture`.
4. **Align the workspace description:** `/doc-sync cogni-workspace`, and add an `agents` keyword to its `plugin.json`.
5. **Restore artifact trails:** `/doc-generate {plugin} --section=what-it-does` for cogni-knowledge, cogni-website, cogni-sales, cogni-workspace, cogni-consult and cogni-trends — highest value on cogni-knowledge and cogni-website, which have none.
6. **Bring narrative sections into band:** `/doc-power cogni-workspace` and `/doc-power cogni-consult`.
7. **Retarget the ecosystem-overview pipelines:** `docs/ecosystem-overview.md:140,323,325,327` still route three workflows through cogni-visual.
