# Course 9: B2B Marketing Content

**Duration**: 45 minutes | **Modules**: 5 | **Prerequisites**: Courses 4-5 (TIPS) + Course 6 (Portfolio)
**Plugin**: cogni-marketing (v0.1.1, 11 skills, 3 agents)
**Audience**: Consultants and marketers creating B2B content pipelines

---

## Module 1: Marketing Setup & Content Strategy

### Theory (3 min)

**cogni-marketing** is a B2B content engine that bridges two upstream plugins:
cogni-trends strategic themes (your GTM paths) and cogni-portfolio propositions
(your solutions) into channel-ready content across the full marketing funnel.

**GTM Path concept**: A GTM path takes a strategic theme from the TIPS value
model and maps it to a specific market with a funnel focus. Think of it as the
strategic lane your content will travel:

| GTM Path Component | Source | Example |
|--------------------|--------|---------|
| Strategic theme | TIPS value model | "AI-driven supply chain" |
| Target market | Portfolio / market selection | Manufacturing mid-market |
| Funnel focus | Marketing strategy | awareness, consideration, decision, or full-funnel |

**Brand voice configuration**: cogni-marketing provides industry-based defaults
for tone and style, with modifiers per content type. A thought-leadership blog
sounds different from a LinkedIn post, even when covering the same theme.

**`/marketing-setup` skill**: Initializes your marketing project:
1. Project creation and naming
2. Market selection (from your portfolio work)
3. GTM path mapping (theme + market + funnel focus)
4. Brand voice configuration

**The 3D Content Matrix**: The strategic planning layer that organizes your
entire content effort across three dimensions:

```
Market  x  GTM Path  x  Content Type
```

This matrix reveals gaps, priorities, and coverage at a glance.

**`/content-strategy` skill**: Builds your content plan using four narrative
angle layers drawn from TIPS:

| Layer | TIPS Origin | Narrative Role |
|-------|-------------|----------------|
| T — Trend hook | Trend data | Grabs attention with market momentum |
| I — Implication tension | Impact analysis | Creates urgency through consequences |
| P — Possibility promise | Opportunity mapping | Opens the door to a better future |
| S — Solution proof | Solution validation | Delivers credible evidence of results |

The strategy skill recommends formats, sets priority sequencing, and maps
content across **16 content formats** spanning **5 funnel stages**.

### Demo

Walk through marketing setup and strategy:
1. Run `/marketing-setup` — configure brand voice for your industry
2. Select a market from your portfolio
3. Map a GTM path: pick a TIPS theme, assign the market, choose funnel focus
4. Run `/content-strategy` — show the 3D matrix being built
5. Review narrative angles: how T/I/P/S layers shape each content piece
6. Show format recommendations and priority sequencing

### Exercise

Ask the user to:
1. Pick a market from their portfolio work (Course 6)
2. Define a GTM path: which TIPS theme drives it? What funnel focus?
3. Sketch a simple content strategy: 3 content pieces across awareness, consideration, and decision
4. For each piece, identify which narrative layer (T/I/P/S) leads the message

### Quiz

1. **Multiple choice**: What is a GTM path in cogni-marketing?
   - a) A file path to your marketing assets
   - b) A strategic theme mapped to a market with a funnel focus
   - c) A technical API route for content delivery
   - d) A competitor analysis framework
   **Answer**: b

2. **Multiple choice**: What are the three dimensions of the 3D Content Matrix?
   - a) Audience, channel, budget
   - b) Market, GTM path, content type
   - c) Theme, format, schedule
   - d) Brand, tone, length
   **Answer**: b

### Recap

- cogni-marketing bridges TIPS themes and portfolio propositions into content
- GTM paths combine a strategic theme, target market, and funnel focus
- The 3D Content Matrix (market x GTM path x content type) drives planning
- T/I/P/S narrative layers give every content piece a strategic angle
- 16 content formats across 5 funnel stages

---

## Module 2: Awareness & Engagement Content

### Theory (3 min)

**Funnel stage: Awareness** — the goal is educating the market and establishing
thought leadership. You are not selling yet; you are earning attention.

**`/thought-leadership` skill** — 5 formats:

| Format | Length | Best For |
|--------|--------|----------|
| Blog post | 800-1200 words | SEO, website traffic |
| LinkedIn article | 600-800 words | Professional network reach |
| Keynote abstract | 150-200 words | Speaking engagements |
| Podcast outline | 400-500 words | Audio content planning |
| Op-ed | 600-800 words | Industry publication placement |

**Evidence requirement**: Every thought-leadership piece draws on 3-5 TIPS
claims as evidence. This grounds your content in real trend data rather than
opinion.

**Funnel stage: Engagement** — the goal is driving traffic and interaction.
Content here is shorter, sharper, and designed for social and search channels.

**`/demand-gen` skill** — 5 formats:

| Format | Length | Best For |
|--------|--------|----------|
| LinkedIn post | 200-300 words | Social engagement |
| SEO article | 1000-1500 words | Organic search traffic |
| Carousel | 8 slides x 30 words | Visual storytelling |
| Video script | 90 seconds | Video marketing |
| Infographic spec | Layout + data | Visual data sharing |

**Implication tension** from TIPS acts as the emotional driver in engagement
content — it is the "so what?" that stops the scroll.

**Parallel batch generation**: The content-writer agents run concurrently,
generating multiple pieces simultaneously across formats and themes.

### Demo

Walk through awareness and engagement content:
1. Pick a TIPS theme from your GTM path
2. Generate a thought-leadership blog post using `/thought-leadership`
3. Show how TIPS claims appear as evidence throughout the piece
4. Generate a LinkedIn post for the same theme using `/demand-gen`
5. Compare the two outputs: format difference, tone difference, same core message
6. Point out the implication tension driving the LinkedIn post

### Exercise

Ask the user to:
1. Choose a format from thought leadership: blog, LinkedIn article, or op-ed
2. Generate one piece for their GTM path from Module 1
3. Review: Are the TIPS claims visible as evidence? Does the narrative angle work?
4. Note which T/I/P/S layer leads the piece

### Quiz

1. **Multiple choice**: What is the primary goal of awareness-stage content?
   - a) Closing deals
   - b) Educating the market and establishing thought leadership
   - c) Generating qualified leads
   - d) Enabling the sales team
   **Answer**: b

2. **Multiple choice**: What does "implication tension" mean in the TIPS context?
   - a) Internal team disagreements about strategy
   - b) The urgency created by consequences of not acting on a trend
   - c) Technical limitations of current systems
   - d) Budget constraints for marketing campaigns
   **Answer**: b

### Recap

- Awareness content educates; engagement content drives interaction
- Thought leadership: 5 formats grounded in 3-5 TIPS claims each
- Demand gen: 5 shorter formats optimized for social and search channels
- Implication tension is the emotional driver that creates urgency
- Parallel generation produces multiple pieces concurrently

---

## Module 3: Conversion & Sales Content

### Theory (3 min)

**Funnel stage: Consideration** — the goal is generating leads with gated,
high-value content that earns contact information in exchange for insight.

**`/lead-gen` skill** — 5 formats:

| Format | Length | Best For |
|--------|--------|----------|
| Whitepaper | 2500-4000 words | Deep-dive thought leadership |
| Landing page | 300-400 words | Conversion-focused web page |
| Email nurture sequence | 3-5 emails x 150-250 words | Drip campaigns |
| Webinar outline | 600-800 words | Live event planning |
| Gated checklist | 500-700 words | Quick-win downloadable |

**Persona-specific value calculation**: Lead-gen content adapts its messaging
for three buyer personas — economic buyer (ROI focus), technical evaluator
(feasibility focus), and end user (usability focus).

**Funnel stage: Decision** — the goal is enabling the sales team with content
that helps close deals.

**`/sales-enablement` skill** — 5 formats:

| Format | Length | Best For |
|--------|--------|----------|
| Battle card | 400-500 words per competitor | Competitive positioning |
| One-pager | 500-600 words | Quick solution overview |
| Demo script | 500-600 words | Product demonstration |
| Objection handler | 300-400 words | Overcoming buyer resistance |
| Proposal section | 400-600 words | Formal bid content |

Sales enablement draws from **cogni-portfolio** competitor data and
propositions, ensuring your content reflects actual positioning.

**`/abm` skill** — account-based marketing for named accounts:
- Account plans tailored to specific companies
- Personalized email sequences for key stakeholders
- Executive briefings with company-specific context
- Custom landing pages for target accounts
- Includes web research on the target company and stakeholder mapping

### Demo

Walk through conversion and sales content:
1. Generate a one-pager using `/sales-enablement`
2. Show how portfolio propositions flow into the content
3. Point out persona-specific messaging
4. Generate an ABM executive briefing for a named account using `/abm`
5. Show the stakeholder map and company-specific research
6. Compare: segment-level content vs. account-specific content

### Exercise

Ask the user to:
1. Choose one: generate a one-pager or a battle card using `/sales-enablement`
2. Review: Does the content draw on their portfolio data effectively?
3. Check: Is the competitive positioning accurate and specific?
4. Identify one improvement to make the content more compelling

### Quiz

1. **Multiple choice**: What is the primary difference between lead-gen and sales-enablement content?
   - a) Lead-gen is longer
   - b) Lead-gen earns contact information; sales-enablement helps close deals
   - c) Sales-enablement is only for digital channels
   - d) Lead-gen targets individual accounts
   **Answer**: b

2. **Multiple choice**: When should you use ABM instead of segment-level marketing?
   - a) When targeting broad market segments
   - b) When you have named accounts with specific stakeholders to reach
   - c) When your budget is limited
   - d) When creating thought-leadership content
   **Answer**: b

### Recap

- Consideration content generates leads through gated high-value assets
- Decision content enables sales teams to close deals
- Persona-specific messaging adapts to economic, technical, and end-user buyers
- Sales enablement draws directly from portfolio propositions and competitor data
- ABM creates account-specific content with company research and stakeholder maps

---

## Module 4: Campaign Orchestration

### Theory (3 min)

**`/campaign` skill**: Orchestrates individual content pieces into coordinated
multi-channel campaigns with three phases:

| Phase | Timing | Goal | Content Focus |
|-------|--------|------|---------------|
| Attract | Weeks 1-2 | Build awareness | Thought leadership, social posts |
| Engage | Weeks 3-5 | Drive interaction | SEO articles, carousels, webinars |
| Convert | Weeks 6-8 | Generate leads | Whitepapers, landing pages, email nurture |

**Touch sequences with dependencies**: Content pieces connect in logical order.
A LinkedIn post drives traffic to a blog, the blog links to a whitepaper, and
the whitepaper triggers an email nurture sequence. The campaign builder maps
these dependencies explicitly.

**Gap detection**: When you build a campaign, the skill identifies missing
content pieces — a conversion phase without a landing page, an engage phase
without social content — so nothing falls through the cracks.

**`/content-calendar` skill**: Editorial scheduling that turns your campaign
plan into a publication timeline:
- Publication dates and channel assignments
- Cadence tracking across all active campaigns
- Output formats: YAML source + Markdown view + CSV export

**Smart alerts** flag potential issues:
- Overload days (too much content scheduled at once)
- Channel fatigue (same channel used too frequently)
- Content gaps (periods with no publications)
- Missing dependencies (content published before its prerequisite)

**Bilingual support**: Full DE/EN capability with language-specific brand voice
and terminology, so campaigns can run in parallel across markets.

### Demo

Walk through campaign orchestration:
1. Run `/campaign` — build a 3-phase campaign for a single GTM path
2. Show the timeline: Attract (weeks 1-2) to Engage (weeks 3-5) to Convert (weeks 6-8)
3. Show touch sequences and content dependencies
4. Trigger gap detection — what content is missing?
5. Run `/content-calendar` — show the editorial schedule
6. Walk through smart alerts: overload days, channel fatigue

### Exercise

Ask the user to:
1. Plan a 4-week campaign for their market from Module 1
2. Pick 4-6 content pieces from what they have generated in Modules 2-3
3. Sequence them into Attract, Engage, and Convert phases
4. Identify any gaps: Is there a phase without enough content?

### Quiz

1. **Multiple choice**: What are the three phases of a cogni-marketing campaign?
   - a) Plan, Execute, Measure
   - b) Attract, Engage, Convert
   - c) Research, Write, Publish
   - d) Awareness, Interest, Decision
   **Answer**: b

2. **Multiple choice**: What do content calendar smart alerts detect?
   - a) Spelling errors in content
   - b) Overload days, channel fatigue, content gaps, and missing dependencies
   - c) Competitor marketing activity
   - d) Social media follower counts
   **Answer**: b

### Recap

- Campaigns orchestrate content into Attract, Engage, and Convert phases
- Touch sequences map content dependencies in logical order
- Gap detection ensures no phase is missing critical content
- Content calendar provides publication dates, channel assignments, and alerts
- Bilingual DE/EN support runs parallel campaigns across markets

---

## Module 5: Dashboard, Pipeline & Resume

### Theory (3 min)

**`/marketing-dashboard` skill**: Generates an interactive HTML dashboard with
five views:

| View | Visualization | Shows |
|------|---------------|-------|
| Coverage heatmap | Market x GTM path grid | Content counts per cell — where are the gaps? |
| Funnel distribution | Stacked bar chart | Awareness/consideration/decision split per market |
| Channel mix | Donut chart | Content distribution across channels |
| Production tracker | Status table | Content pieces with draft/review/published status |
| Campaign timeline | Gantt view | Campaign phases and milestones over time |

**`/marketing-resume` skill**: Session resumption that picks up where you left
off. When you return to a marketing project, it detects:
- Overdue items past their publication date
- Campaign blockers (missing dependencies holding up the next phase)
- Lowest-coverage markets (where to focus next)
- Funnel gaps (stages with thin content)

**The full content pipeline** connects five courses:

```
TIPS (Courses 4-5)  →  Portfolio (Course 6)  →  Marketing (this course)
                                                      ↓
                                              Sales (Course 10)
                                                      ↓
                                              Visual (Course 7)
```

TIPS provides themes and evidence. Portfolio provides propositions and
competitive positioning. Marketing transforms both into channel-ready content.
Sales takes it further into deal-specific pitches. Visual turns it all into
presentations and deliverables.

**Cross-plugin integration**:
- **cogni-copywriting** — Polish and refine marketing content
- **cogni-narrative** — Transform content using story arc structures
- **cogni-claims** — Verify evidence and citations in content

### Demo

Walk through the dashboard and resume flow:
1. Open the marketing dashboard — show all five views
2. Read the coverage heatmap: which markets have strong coverage? Where are gaps?
3. Check funnel distribution: is any stage underweight?
4. Show the campaign timeline: are milestones on track?
5. Run `/marketing-resume` — show what it recommends as next actions
6. Discuss: how does the dashboard guide your weekly marketing decisions?

### Exercise

Ask the user to:
1. Map the full content pipeline for one market
2. Start from a TIPS theme (Courses 4-5)
3. Connect it to a portfolio proposition (Course 6)
4. Identify 3 marketing content pieces that bridge the two
5. Sketch a campaign plan that sequences those pieces
6. Describe how the dashboard would track progress

### Quiz

1. **Hands-on**: Describe your ideal marketing content pipeline for your
   organization. What themes drive it? What content formats matter most?
   How would you phase a campaign?

2. **Multiple choice**: What does a coverage heatmap show?
   - a) Website traffic by region
   - b) Content counts per market and GTM path combination
   - c) Email open rates across campaigns
   - d) Social media engagement by platform
   **Answer**: b

### Recap

- The marketing dashboard provides five views: heatmap, funnel, channel, tracker, timeline
- Resume skill detects overdue items, blockers, gaps, and lowest-coverage markets
- The full pipeline flows from TIPS through portfolio, marketing, sales, to visual
- Cross-plugin integration with copywriting, narrative, and claims adds polish and rigor
- The dashboard turns marketing from reactive to strategic

---

## Course Completion

You have completed Course 9: B2B Marketing Content.

**What you learned**:
- Setting up a marketing project with GTM paths and the 3D Content Matrix
- Building content strategy with T/I/P/S narrative angles
- Generating awareness content (thought leadership, demand gen)
- Creating conversion content (lead gen, sales enablement, ABM)
- Orchestrating campaigns with phased touch sequences
- Scheduling with content calendars and smart alerts
- Tracking coverage and progress with the marketing dashboard

**Your marketing toolkit**:

| Skill | Purpose |
|-------|---------|
| `/marketing-setup` | Project initialization and GTM path mapping |
| `/content-strategy` | 3D matrix planning and narrative angles |
| `/thought-leadership` | Awareness content (5 formats) |
| `/demand-gen` | Engagement content (5 formats) |
| `/lead-gen` | Consideration content (5 formats) |
| `/sales-enablement` | Decision content (5 formats) |
| `/abm` | Account-based marketing for named accounts |
| `/campaign` | Multi-phase campaign orchestration |
| `/content-calendar` | Editorial scheduling and alerts |
| `/marketing-dashboard` | Interactive coverage and progress tracking |
| `/marketing-resume` | Session resumption and next-action detection |

**The bridge**: TIPS themes power your narrative angles. Portfolio propositions
power your sales content. Marketing bridges research to revenue.

**Something unclear or broken?** Tell Claude what happened — cogni-issues will help you file it.

**Next**: Course 10 (Sales) takes the pipeline further into deal-specific
pitches for named customers.
