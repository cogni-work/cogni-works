# Cross-Category Assignment Rules

Some offerings legitimately span multiple taxonomy categories. After aggregating offerings from all domains, analyze each offering for multi-category fit.

## Detection Rules

```text
FOR each offering in all_offerings:

  # Rule 1: Organizational Transformation + Digital Strategy → dual category
  IF offering.category == "1.4" (Organizational Transformation)
     AND (offering.description CONTAINS "digital"
          OR offering.description CONTAINS "technology-enabled"
          OR offering.description CONTAINS "digital transformation")
  THEN also_assign_to("3.1")  # Digital Strategy

  # Rule 2: Data & AI Advisory + Regulatory → dual category
  IF offering.category == "3.3" (Data & AI Advisory)
     AND (offering.description CONTAINS "regulatory"
          OR offering.description CONTAINS "compliance"
          OR offering.description CONTAINS "data privacy"
          OR offering.description CONTAINS "GDPR")
  THEN also_assign_to("5.1")  # Regulatory Advisory

  # Rule 3: Leadership Development + Change Management → dual category
  IF offering.category == "6.3" (Leadership Development)
     AND (offering.description CONTAINS "change"
          OR offering.description CONTAINS "transformation leadership"
          OR offering.description CONTAINS "change readiness")
  THEN also_assign_to("6.1")  # Change Management

  # Rule 4: M&A Advisory + Financial Audit Support → dual category
  IF offering.category == "1.3" (M&A Advisory)
     AND (offering.description CONTAINS "financial due diligence"
          OR offering.description CONTAINS "audit"
          OR offering.description CONTAINS "accounting"
          OR offering.description CONTAINS "financial statements")
  THEN also_assign_to("5.3")  # Financial Audit Support

  # Rule 5: ESG & Sustainability Strategy + Regulatory Advisory → dual category
  IF offering.category == "1.6" (ESG & Sustainability Strategy)
     AND (offering.description CONTAINS "regulation"
          OR offering.description CONTAINS "CSRD"
          OR offering.description CONTAINS "taxonomy regulation"
          OR offering.description CONTAINS "disclosure")
  THEN also_assign_to("5.1")  # Regulatory Advisory

  # Rule 6: HR Transformation + Change Management → dual category
  IF offering.category == "6.4" (HR Transformation)
     AND (offering.description CONTAINS "change management"
          OR offering.description CONTAINS "adoption"
          OR offering.description CONTAINS "stakeholder engagement")
  THEN also_assign_to("6.1")  # Change Management
```

## Dual-Category Assignment Patterns

| Pattern | Primary Category | Secondary Category | Trigger |
|---------|-----------------|-------------------|---------|
| Org transformation + digital strategy | 1.4 | 3.1 | Digital or technology-enabled transformation mentioned |
| Data & AI advisory + regulatory | 3.3 | 5.1 | Data privacy, GDPR, or compliance context |
| Leadership + change management | 6.3 | 6.1 | Change readiness or transformation leadership mentioned |
| M&A advisory + financial audit | 1.3 | 5.3 | Financial due diligence or audit context |
| ESG strategy + regulatory advisory | 1.6 | 5.1 | CSRD, disclosure, or regulatory compliance context |
| HR transformation + change management | 6.4 | 6.1 | Change management or adoption context |

When duplicating to a secondary category: copy all fields, update `category`, add `cross_category_source` to track origin.
