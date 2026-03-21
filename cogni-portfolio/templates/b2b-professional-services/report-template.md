# Scan Report Template

Instructions for generating `<company-slug>-portfolio.md` in Phase 6.

## Report Structure

Generate the report dynamically from the taxonomy in the template's `template.md`. Do NOT hardcode empty table sections — iterate over the taxonomy dimensions and categories to produce each section.

```markdown
# <Company Name> Portfolio

> Portfolio scan generated on <YYYY-MM-DD>
> Analyzed domains: domain1.com, insights.domain1.com, careers.domain1.com
```

### Legends (include at top)

**Service Horizons:**

| Horizon | Timeframe | Characteristics |
|---------|-----------|-----------------|
| **Current** | 0-1 years | Generally available, proven engagements, established fee structures |
| **Emerging** | 1-3 years | Pilot programs, limited availability, evolving pricing |
| **Future** | 3+ years | Announced, conceptual, R&D phase, no fixed pricing |

**Discovery Status:**

| Status | Meaning |
|--------|---------|
| **Confirmed** | Firm offers this capability (evidence found) |
| **Not Offered** | No evidence found for this category |
| **Emerging** | Announced or pilot status (not yet broadly offered) |
| **Extended** | Firm-specific variant beyond standard taxonomy |

### Per-Category Section Format

For each category in the taxonomy, generate:

```markdown
### <ID> <Category Name> [Status: <status>]

| Name | Description | Domain | Link | USP | Practice Line | Fee Model | Availability | Partners | Segments | Horizon |
|------|-------------|--------|------|-----|--------------|-----------|--------------|----------|----------|---------|
| <offerings...> |
```

Group categories under their dimension headers (`## 1. Strategy & Transformation`, etc.).

### Empty Categories

When no offerings are found:

```markdown
| *No offerings found* | | | | | | | | | | |
```

Set status to `[Status: Not Offered]`.

### Cross-Cutting Attributes (include at end)

```markdown
## Cross-Cutting Attributes

### Target Segments
Mid-Market, Large Enterprise, Global Multinationals, Government/Public Sector

### Delivery Options
On-site advisory, Remote/hybrid delivery, Offshore delivery centers, Co-delivery with alliances

### Ecosystem Partners
- **Technology Platforms:** SAP, Salesforce, Microsoft, AWS, Azure, GCP
- **Industry Associations:** (firm-specific)
- **Academic Partnerships:** (firm-specific)
```

## Column Reference

| Column | Description |
|--------|-------------|
| **Name** | Service or capability name |
| **Description** | What the service delivers |
| **Domain** | Source domain where discovered |
| **Link** | Direct URL to the service page |
| **USP** | Unique selling proposition / differentiators |
| **Practice Line** | Which practice area or service line owns this |
| **Fee Model** | How the service is priced (project fee, retainer, success fee, time & materials) |
| **Availability** | GA, pilot, announced |
| **Partners** | Key technology or delivery partnerships for this capability |
| **Segments** | Target client segments (mid-market, large enterprise, government) |
| **Horizon** | Current, Emerging, or Future |
