# Content Format Specifications

## Format Defaults by Content Type

### Thought Leadership

| Format | Words | Evidence | Funnel Stage | Channels |
|--------|-------|----------|-------------|----------|
| blog | 800-1200 | yes (TIPS claims) | awareness | website |
| linkedin-article | 600-800 | yes | awareness | LinkedIn |
| keynote-abstract | 150-200 | no | awareness | events |
| podcast-outline | 400-500 | no | awareness | podcast platforms |
| op-ed | 600-800 | yes | awareness | industry publications |

### Demand Generation

| Format | Words | Evidence | Funnel Stage | Channels |
|--------|-------|----------|-------------|----------|
| seo-article | 1000-1500 | yes | awareness/consideration | website |
| linkedin-post | 200-300 | no | awareness | LinkedIn |
| carousel | 8 slides × 30w | no | awareness | LinkedIn, Instagram |
| video-script | 90s / 225w | no | awareness | YouTube, LinkedIn |
| infographic-spec | 300-400 (brief) | yes | awareness | social, website |

### Lead Generation

| Format | Words | Evidence | Funnel Stage | Channels |
|--------|-------|----------|-------------|----------|
| whitepaper | 2500-4000 | yes | consideration | gated download |
| landing-page | 300-400 | no | consideration | website |
| email-nurture | 150-250 per email | no | consideration | email |
| webinar-outline | 600-800 | yes | consideration | webinar platform |
| gated-checklist | 500-700 | no | consideration | gated download |

### Sales Enablement

| Format | Words | Evidence | Funnel Stage | Channels |
|--------|-------|----------|-------------|----------|
| battle-card | 400-500 | yes | decision | internal |
| one-pager | 500-600 | yes | decision | sales handout |
| demo-script | 500-600 | no | decision | internal |
| objection-handler | 300-400 | yes | decision | internal |
| proposal-section | 400-600 | yes | decision | proposal doc |

### ABM (Account-Based Marketing)

| Format | Words | Evidence | Funnel Stage | Channels |
|--------|-------|----------|-------------|----------|
| account-plan | 800-1000 | yes | full-funnel | internal |
| personalized-email | 150-250 | no | awareness/consideration | email |
| executive-briefing | 400-500 | yes | consideration/decision | meeting prep |
| custom-landing-page | 300-400 | no | consideration | website |

## Tone Modifiers

Base brand voice applies to all content. Modifiers adjust per format:

| Format Category | Modifier | Effect |
|----------------|----------|--------|
| whitepaper, blog, one-pager | +formal, +detailed | Longer sentences, data-heavy, passive voice OK |
| linkedin-post, carousel | +conversational, +punchy | Short sentences, hooks, questions, emoji OK |
| email-nurture, personalized-email | +personal, +direct | First person, "you" addressing, clear CTA |
| battle-card, objection-handler | +competitive, +factual | Comparison tables, data points, no hedging |
| keynote-abstract, podcast-outline | +inspirational, +narrative | Story arcs, rhetorical questions, forward-looking |
| demo-script | +instructional, +clear | Step-by-step, simple language, user benefit per step |

## Evidence Integration Rules

When `evidence: true`:
- Embed TIPS claims inline as `[claim_id](source_url)` markers
- Use portfolio proposition evidence (case studies, metrics)
- Prefer quantitative over qualitative ("47% reduction" > "significant reduction")
- Cap at 3-5 evidence points per piece (avoid academic density)
- Mark unverified claims with `[unverified]` suffix

When `evidence: false`:
- Use insights without specific citations
- OK to reference trends qualitatively ("industry leaders are shifting to...")
- Focus on narrative flow over proof density

## Language-Specific Guidelines

### German (DE)
- Follow Wolf Schneider principles: short sentences, active voice, concrete nouns
- Preserve Umlauts (ä, ö, ü, ß) — never convert to ASCII
- Use Sie-form for formal content, Du-form only if brand config specifies
- B2B default: Sie-form
- Technical terms: use German term with English in parentheses on first mention, then German only

### English (EN)
- AP style for articles, Chicago for whitepapers
- Active voice, concrete language
- Avoid jargon unless audience-appropriate
- Use Oxford comma
