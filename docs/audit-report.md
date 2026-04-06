# Documentation Drift Report
Generated: 2026-04-06
Repo: /Users/stephandehaas/GitHub/dev/insight-wave

## Summary

| Plugin | Components | Architecture | Descriptions | Dependencies | plugin.json | CLAUDE.md | Messaging | docs/ | Commercial | Doc Logic | Known Issues | Overall |
|--------|-----------|--------------|-------------|-------------|-------------|-----------|-----------|-------|------------|-----------|--------------|---------|
| cogni-claims | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK |
| cogni-narrative | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | N/A | OK |
| cogni-copywriting | OK | DRIFT | OK | OK | OK | OK | WEAK | OK | OK | OK | N/A | NEEDS UPDATE |
| cogni-workspace | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK |
| cogni-trends | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | N/A | OK |
| cogni-portfolio | OK | DRIFT | OK | OK | OK | OK | OK | OK | OK | DRIFT | N/A | NEEDS UPDATE |
| cogni-visual | OK | OK | OK | OK | OK | OK | WEAK | OK | OK | OK | OK | NEEDS UPDATE |
| cogni-help | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK |
| cogni-marketing | OK | OK | DRIFT | OK | OK | OK | OK | STALE | OK | OK | N/A | NEEDS UPDATE |
| cogni-research | DRIFT | DRIFT | DRIFT | OK | OK | OK | OK | STALE | OK | OK | N/A | NEEDS UPDATE |
| cogni-sales | OK | OK | DRIFT | OK | OK | OK | OK | STALE | OK | OK | N/A | NEEDS UPDATE |
| cogni-website | OK | OK | OK | OK | OK | OK | WEAK | OK | OK | DRIFT | N/A | NEEDS UPDATE |
| cogni-consulting | DRIFT | DRIFT | DRIFT | OK | OK | OK | WEAK | OK | OK | OK | N/A | NEEDS UPDATE |

**5 OK** · **8 NEEDS UPDATE** · **0 MISSING**

---

## Cross-Cutting Patterns

### 1. Undocumented workspace directories
Three plugins have `*-workspace` directories inside `skills/` not listed in Components or Architecture:
- **cogni-copywriting**: `copywriter-workspace/` (stale `insight-summary.md` artifact at root)
- **cogni-research**: `research-report-workspace/`
- **cogni-consulting**: `consulting-define-workspace/`

These are dev/eval workspace directories (no SKILL.md), not real skills. Architecture trees should annotate them the way cogni-visual annotates `story-to-slides-workspace`.

### 2. "for Claude Cowork" divergence
4 plugins (cogni-marketing, cogni-research, cogni-sales, cogni-consulting) include `[Claude Cowork](https://claude.ai/cowork)` in their README first paragraph, but neither plugin.json nor marketplace.json contains this link. This is a consistent README-vs-manifest divergence.

### 3. Missing CONTRIBUTING.md
4 plugins lack CONTRIBUTING.md: cogni-marketing, cogni-research, cogni-website, cogni-consulting.

### 4. Pipeline registry stale entries
`synthesize` and `portfolio-export` are registered in `pipeline-registry.json` as cogni-portfolio skills but no longer exist on disk — stale registry entries.

### 5. MEANS quantifier weakness
4 plugins have WEAK messaging primarily due to MEANS bullets lacking hard quantifiers:
- **cogni-copywriting**: "one pass" is vague
- **cogni-visual**: no numeric quantifiers despite problem table citing "1-2 days"
- **cogni-website**: no time/count/percentage stats
- **cogni-consulting**: qualitative claims only ("weeks later with full continuity")

---

## cogni-copywriting

### Architecture Tree Drift
- DRIFT: Stale `insight-summary.md` artifact exists at plugin root, not in architecture tree

### Power Messaging
- WEAK: MEANS bullets lack hard quantifiers. "Ship in one pass" and "Preserve story arc structure" are qualitative — need measurable outcomes

---

## cogni-portfolio

### Architecture Tree Drift
- DRIFT: `portfolio-canvas-workspace/` exists on disk but not annotated in architecture tree
- DRIFT: `templates/power-positions.md` is undocumented in architecture tree

### Documentation Logic Drift
- DRIFT: Pipeline registry contains 2 stale entries — `synthesize` and `portfolio-export` no longer exist as skills on disk

---

## cogni-visual

### Power Messaging
- WEAK: Only 3 MEANS bullets, none with hard quantifiers. Problem table cites "1-2 days of formatting work" but MEANS doesn't echo a matching quantified counter-claim

---

## cogni-marketing

### Description Alignment
- DRIFT: README first paragraph includes "for [Claude Cowork]" link absent from plugin.json and marketplace.json

---

## cogni-research

### Component Table Drift
- DRIFT: `research-report-workspace/` exists on disk but not in Components table (dev workspace, not a real skill — should be annotated)

### Architecture Tree Drift
- DRIFT: `research-report-workspace/` absent from architecture tree

### Description Alignment
- DRIFT: README adds "for [Claude Cowork]" prefix not in plugin.json/marketplace.json

---

## cogni-sales

### Description Alignment
- DRIFT: README adds "for [Claude Cowork]" prefix not in plugin.json/marketplace.json

---

## cogni-website

### Power Messaging
- WEAK: MEANS bullets have no numeric quantifiers

### Documentation Logic Drift
- DRIFT: Zero pipeline registry entries for all 5 skills — pipeline suffixes unavailable for "What it does" items

---

## cogni-consulting

### Component Table Drift
- DRIFT: `consulting-define-workspace/` exists on disk but not in Components table

### Architecture Tree Drift
- DRIFT: `consulting-define-workspace/` absent from architecture tree

### Description Alignment
- DRIFT: README lead paragraph diverges from plugin.json/marketplace description

### Power Messaging
- WEAK: MEANS bullets have no numeric quantifiers ("Big-5 complexity", "your consulting judgment")

---

## Recommended Actions

1. **Fix structural drift** — Run `/doc-generate` for cogni-research, cogni-consulting, cogni-portfolio, cogni-copywriting to update Components tables and Architecture trees (annotate workspace dirs)
2. **Align descriptions** — Run `/doc-sync` for cogni-marketing, cogni-research, cogni-sales, cogni-consulting to reconcile README first paragraphs with plugin.json/marketplace.json
3. **Strengthen messaging** — Run `/doc-power` for cogni-copywriting, cogni-visual, cogni-website, cogni-consulting to add hard quantifiers to MEANS bullets
4. **Clean pipeline registry** — Remove stale `synthesize` and `portfolio-export` entries from `pipeline-registry.json`; add cogni-website skills
5. **Refresh stale docs/** — Regenerate plugin guides for cogni-marketing, cogni-research, cogni-sales via `/doc-hub --category=plugin-guide`
