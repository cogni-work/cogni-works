---
name: marketing-resume
description: "Resume a cogni-marketing project session by showing current status, content gaps, campaign progress, and recommended next actions. Use this skill when the user asks to 'resume marketing', 'continue marketing', 'marketing status', 'where was I with marketing', 'what's next for marketing', 'pick up marketing', or wants to re-enter a marketing project from a previous session — even if they don't say 'resume' explicitly."
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Marketing Resume

## Purpose

Re-enter an existing marketing project, display comprehensive status, and recommend the highest-priority next action. Designed for multi-session workflows where the user returns after days or weeks.

## Workflow

### Step 1: Discover Projects

Glob for `**/marketing-project.json` in the working directory. If multiple found, present list and ask user to select. If one found, load automatically.

### Step 2: Status Assessment

Read all project files and compute:

1. **Project health**:
   - Sources connected: ✅/❌ for portfolio and TIPS
   - Markets configured: count
   - GTM paths mapped: count
   - Brand configured: ✅/❌

2. **Content strategy status**:
   - Strategy defined: ✅/❌
   - Total planned pieces: count
   - Generated pieces: count (by scanning content/ directories)
   - Coverage percentage: overall and per market

3. **Campaign status**:
   - Active campaigns: count
   - Campaign phase: attract/engage/convert
   - Content gaps blocking campaigns: list

4. **Calendar status**:
   - Calendar exists: ✅/❌
   - Upcoming deadlines: next 7 days
   - Overdue items: any with past dates still in "planned" status

### Step 3: Present Dashboard Summary

```
cogni-marketing: {project_name}
  Brand: {brand_name} | Language: {language}
  Portfolio: {portfolio_path} | TIPS: {tips_path}

Markets & Coverage:
  mid-market-saas-dach:     ████████░░ 78% (14/18 pieces)
  enterprise-mfg-dach:      ████░░░░░░ 40% (6/15 pieces)

Campaigns:
  ai-pred-q2:               Phase 2/3 (Engage) — 8 touchpoints done, 4 remaining
  cloud-native-awareness:   Phase 1/3 (Attract) — just started

Content by Type:
  Thought Leadership:  5/6  ████████░░
  Demand Generation:   8/12 ██████░░░░
  Lead Generation:     3/8  ████░░░░░░
  Sales Enablement:    2/5  ███░░░░░░░
  ABM:                 2/2  ██████████

Calendar:
  ⚠️ 2 items overdue (linkedin-post Apr 10, email-nurture Apr 12)
  📅 Next: blog publication Apr 15
```

### Step 4: Recommend Next Action

Based on priority logic:
1. **Overdue content** → Highest priority. "Generate the overdue LinkedIn post for campaign X."
2. **Campaign blockers** → Content gaps blocking the next campaign phase. "Generate whitepaper to unblock Phase 2 of ai-pred-q2."
3. **Lowest coverage market** → "Enterprise-mfg-dach is at 40% — start with thought leadership blog."
4. **Funnel gaps** → "You have 8 awareness pieces but only 2 decision pieces — generate battle cards."
5. **New content from strategy** → Next item in priority sequence from content-strategy.

Present as:
```
Recommended next action:
  /lead-gen --market mid-market-saas-dach --gtm-path ai-predictive-maintenance --format whitepaper
  Reason: Campaign ai-pred-q2 enters Phase 2 (Engage) next week and needs the whitepaper as the gated asset.

Other options:
  - /demand-gen --market enterprise-mfg-dach (boost lowest-coverage market)
  - /content-calendar --update (mark overdue items)
  - /marketing-dashboard (refresh visual overview)
```

### Step 5: Source Freshness Check

Check if upstream data has changed since last session:
- Portfolio: compare `portfolio.json` updated timestamp vs. `marketing-project.json` updated
- TIPS: compare `tips-value-model.json` updated timestamp

If upstream changed:
```
⚠️ Portfolio updated since last session (new propositions added).
   Consider re-running /content-strategy to incorporate new messaging.

⚠️ TIPS value model updated (re-anchored solutions).
   New GTM path opportunities may be available.
```
