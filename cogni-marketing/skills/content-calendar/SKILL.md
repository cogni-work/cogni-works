---
name: content-calendar
description: "Generate and manage an editorial content calendar with publication dates, channel assignments, and cadence tracking. Use this skill when the user asks to 'create a content calendar', 'editorial calendar', 'publication schedule', 'when to publish', 'content cadence', 'plan publications', 'schedule content', or wants to organize content pieces into a time-based publishing plan — even if they don't say 'calendar' explicitly."
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Content Calendar

## Purpose

Generate a structured editorial calendar from the content strategy and campaigns. The calendar is the operational plan — it turns the strategic content matrix into dated, assigned, trackable publication slots.

## Prerequisites

- Marketing project with content strategy defined
- Recommended: at least one campaign built

## Output Formats

The calendar is maintained in two synchronized formats:
1. **`calendar/content-calendar.yaml`** — Machine-readable source of truth
2. **`calendar/content-calendar.md`** — Human-readable rendered view
3. **CSV export** (on request) — For import into HubSpot, Notion, Asana, etc.

## Workflow

### Step 1: Load Content Inventory

1. Read `content-strategy.json` — all planned content across markets and GTM paths
2. Read `campaigns/*.json` — touchpoint timelines with day offsets
3. Scan `content/` — identify what's generated (draft) vs. still planned
4. Read `marketing-project.json` — cadence defaults

### Step 2: Build Calendar

For each content piece, assign:
- **Publication date**: Based on campaign timeline or cadence defaults
- **Channel**: From content format → channel mapping
- **Status**: planned → drafted → reviewed → scheduled → published
- **Owner**: Marketing (default) or Sales (for enablement content)
- **Dependencies**: e.g., "LinkedIn promo post depends on blog being published"

Apply cadence rules from `marketing-project.json`:
- linkedin-post: 3x/week → Mon, Wed, Fri
- blog: 2x/month → 1st and 3rd Tuesday
- email-nurture: triggered by download (not scheduled)
- webinar: 1x/quarter → align with campaign timing

### Step 3: Write Calendar Files

**YAML source** (`content-calendar.yaml`):
```yaml
calendar:
  start_date: "2026-04-01"
  end_date: "2026-06-30"
  entries:
    - date: "2026-04-01"
      day: "Mon"
      market: "mid-market-saas-dach"
      gtm_path: "ai-predictive-maintenance"
      type: "demand-generation"
      format: "linkedin-post"
      title: "Trend hook: AI predictive maintenance"
      file: "content/demand-generation/mid-market--ai-pred--linkedin-post-01.md"
      channel: "linkedin"
      status: "drafted"
      campaign: "ai-pred-q2"
      owner: "marketing"
      notes: ""
```

**Markdown view** (`content-calendar.md`):
```markdown
# Content Calendar — Q2 2026

## April 2026

| Date | Day | Market | Type | Format | Title | Channel | Status |
|------|-----|--------|------|--------|-------|---------|--------|
| Apr 1 | Mon | DACH mid-market | DG | LinkedIn post | Trend hook: AI pred. | LinkedIn | ✅ draft |
| Apr 3 | Wed | DACH mid-market | TL | Blog | AI-Driven Predictive... | Website | ✅ draft |
| Apr 4 | Thu | DACH mid-market | DG | LinkedIn post | Blog promo | LinkedIn | ⬜ planned |
...
```

**CSV export** (on request via `/content-calendar --export csv`):
```csv
date,market,type,format,title,channel,status,campaign,owner,file
2026-04-01,mid-market-saas-dach,demand-generation,linkedin-post,"Trend hook",linkedin,drafted,ai-pred-q2,marketing,content/demand-generation/...
```

### Step 4: Gap & Conflict Detection

After building, check for:
- **Overload days**: More than 2 publications on the same day → spread out
- **Channel fatigue**: Same channel more than daily → reduce
- **Content gaps**: Weeks with no activity for a market → fill with evergreen
- **Missing dependencies**: Promo post scheduled before anchor content → reorder
- **Status gaps**: Campaign starts next week but content still "planned" → flag as urgent

### Step 5: Display & Confirm

Present calendar summary:
```
Content Calendar: Q2 2026 (13 weeks)
  Total entries: 42
  By status: 12 drafted, 30 planned
  By channel: LinkedIn 20, Blog 8, Email 8, Webinar 2, Other 4
  Markets: 2 active

Urgent (next 2 weeks):
  ⚠️ Apr 1: LinkedIn post — drafted, ready to schedule
  ⚠️ Apr 3: Blog — drafted, needs review
  🔴 Apr 4: LinkedIn promo — NOT YET GENERATED

Adjust dates? Add/remove entries? Or save as-is?
```

## Calendar Management

The calendar can be updated incrementally:
- `/content-calendar --add` — Add new entries
- `/content-calendar --update {date} --status published` — Mark as published
- `/content-calendar --reschedule {date} --to {new_date}` — Move an entry
- `/content-calendar --export csv` — Export for tool import
