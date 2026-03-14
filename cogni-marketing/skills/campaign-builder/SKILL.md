---
name: campaign-builder
description: "Build multi-channel marketing campaigns that orchestrate content across touchpoints with day-based timelines. Use this skill when the user asks to 'build a campaign', 'create a campaign', 'launch campaign', 'multi-channel campaign', 'campaign plan', 'orchestrate content', 'campaign timeline', 'touch sequence', or wants to bundle content pieces into a coordinated marketing initiative — even if they don't say 'campaign' explicitly."
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent
---

# Campaign Builder

## Purpose

Orchestrate existing and new content pieces into a coordinated multi-channel campaign with day-based timing, touch sequences, and clear objectives. One campaign = one market × one GTM path. Cross-path campaigns are built by combining multiple campaign objects.

## Prerequisites

- Marketing project with content strategy defined
- Recommended: some content already generated (the campaign assembles + fills gaps)

## Input Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| market | Yes | Market slug |
| gtm_path | Yes | GTM path theme ID |
| campaign_name | No | Campaign name (kebab-case). If omitted, derive from theme |
| duration_weeks | No | Campaign duration (default: 8 weeks) |

## Workflow

### Step 1: Load Existing Content

1. Read `content-strategy.json` for this market × GTM path
2. Scan `content/` directories for existing pieces matching this cell
3. Identify gaps — what's planned but not yet generated

Present inventory:
```
Campaign: {gtm_path} in {market}
Existing content:
  ✅ thought-leadership/blog (1050w, draft)
  ✅ demand-generation/linkedin-post-01 (280w, draft)
  ✅ demand-generation/linkedin-post-02 (250w, draft)
  ❌ lead-generation/whitepaper — NOT YET GENERATED
  ❌ lead-generation/landing-page — NOT YET GENERATED
  ❌ sales-enablement/battle-card — NOT YET GENERATED

Would you like me to generate the missing pieces first, or build the campaign with what we have?
```

### Step 2: Campaign Architecture

Define campaign structure:

1. **Objective**: What this campaign aims to achieve
   - Awareness-focused: reach, impressions, engagement rate
   - Lead-focused: MQLs, whitepaper downloads, webinar registrations
   - Pipeline-focused: demos booked, proposals sent
   Recommend based on funnel focus from content strategy.

2. **Audience**: Primary persona from portfolio customer profiles

3. **Phases** (map to funnel):
   - **Phase 1 — Attract** (weeks 1-2): Thought leadership + social. Build awareness.
   - **Phase 2 — Engage** (weeks 3-5): Deep content + email. Drive consideration.
   - **Phase 3 — Convert** (weeks 6-8): Gated assets + sales follow-up. Capture leads.

### Step 3: Touch Sequence

Build a day-by-day timeline:

```
Week 1:
  Day 1 (Mon): LinkedIn post #1 — Trend hook [demand-gen]
  Day 3 (Wed): Blog published — Full thought leadership piece [thought-leadership]
  Day 4 (Thu): LinkedIn post #2 — Promote blog with key insight [demand-gen]
  Day 5 (Fri): Email to existing list — "New insight on {theme}" [demand-gen]

Week 2:
  Day 8 (Mon): LinkedIn carousel — 5 key stats from the trend [demand-gen]
  Day 10 (Wed): SEO article published — Supporting keyword content [demand-gen]
  Day 12 (Fri): LinkedIn post #3 — Ask audience a question [demand-gen]

Week 3:
  Day 15 (Mon): Whitepaper published + landing page live [lead-gen]
  Day 15 (Mon): LinkedIn post #4 — Announce whitepaper [demand-gen → lead-gen]
  Day 16 (Tue): Email to list — Whitepaper promotion [lead-gen]
  Day 18 (Thu): Email nurture #1 fires for downloaders [lead-gen]

Week 4-5:
  Day 22: Email nurture #2 [lead-gen]
  Day 25: Webinar invite email [lead-gen]
  Day 29: Email nurture #3 [lead-gen]
  Day 32: Webinar event [lead-gen]
  Day 33: Post-webinar follow-up + recording [lead-gen]

Week 6-8:
  Day 36: Email nurture #4 — Soft offer [lead-gen → sales-enablement]
  Day 40: Sales team receives battle cards + one-pagers [sales-enablement]
  Day 42: Email nurture #5 — Direct offer [sales-enablement]
  Day 50: Campaign review + retargeting [wrap-up]
```

For each touchpoint, specify:
- **Content piece**: Link to existing file or mark as "TO GENERATE"
- **Channel**: Where it publishes
- **Owner**: Marketing (automated) or Sales (manual)
- **Metric**: What to measure (impressions, clicks, downloads, replies)

### Step 4: Channel Adaptation

For content pieces that need channel variants, delegate to **channel-adapter** agent:
- Blog → LinkedIn promotion post (extract key insight, write hook)
- Whitepaper → Email announcement (extract 3 key takeaways, add CTA)
- Webinar → LinkedIn event post + email invite

### Step 5: Write Campaign File

Write to `campaigns/{market}--{gtm-path}--{campaign-name}.json`:
```json
{
  "campaign_name": "ai-predictive-maintenance-q2",
  "market": "mid-market-saas-dach",
  "gtm_path": "ai-predictive-maintenance",
  "objective": "Generate 50 MQLs from whitepaper downloads",
  "duration_weeks": 8,
  "start_date": null,
  "audience": { "persona": "CTO mid-market SaaS", "estimated_reach": 5000 },
  "phases": [ ... ],
  "touchpoints": [
    {
      "day": 1,
      "channel": "linkedin",
      "content_type": "demand-generation",
      "format": "linkedin-post",
      "content_file": "content/demand-generation/mid-market--ai-pred--linkedin-post-01.md",
      "owner": "marketing",
      "metric": "impressions, engagement_rate",
      "status": "ready"
    },
    ...
  ],
  "content_gaps": [
    { "type": "lead-generation", "format": "whitepaper", "needed_by_day": 15 }
  ]
}
```

### Step 6: Summary & Next Steps

```
Campaign built: {campaign_name}
  Market: {market}
  GTM path: {gtm_path}
  Duration: {weeks} weeks, {touchpoint_count} touchpoints
  Content ready: {ready_count}/{total_count}
  Gaps to fill: {gap_count} pieces

Next steps:
  1. Generate missing content: {list of /skill commands to run}
  2. Set start_date when ready to launch
  3. Add to calendar: /content-calendar
  4. Review on dashboard: /marketing-dashboard
```

## Campaign Patterns

### Quick Launch (2-week sprint)
- 1 blog + 3 LinkedIn posts + 1 email blast
- Good for: testing a GTM path, event-driven content

### Standard Nurture (8 weeks)
- Full funnel: thought leadership → demand gen → lead gen → sales enablement
- Good for: sustained pipeline building

### Event-Driven (4 weeks around an event)
- Pre-event: 2 weeks of awareness + registration
- Event: webinar/conference
- Post-event: 2 weeks of follow-up + conversion
- Good for: webinar launches, conference presence
