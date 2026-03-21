# Cross-Category Assignment Rules

Some offerings legitimately span multiple taxonomy categories. After aggregating offerings from all domains, analyze each offering for multi-category fit.

## Detection Rules

```text
FOR each offering in all_offerings:

  # Rule 1: Extensibility + Marketplace → dual category
  IF offering.category == "1.4" (Extensibility Framework)
     AND (offering.description CONTAINS "marketplace"
          OR offering.description CONTAINS "app store"
          OR offering.description CONTAINS "third-party")
  THEN also_assign_to("3.2")  # Marketplace & App Store

  # Rule 2: AI/ML + Reporting → dual category
  IF offering.category == "2.4" (AI & ML Capabilities)
     AND (offering.description CONTAINS "analytics"
          OR offering.description CONTAINS "dashboards"
          OR offering.description CONTAINS "insights")
  THEN also_assign_to("2.1")  # Reporting & Dashboards

  # Rule 3: Professional Services + Onboarding → dual category
  IF offering.category == "5.5" (Professional Services)
     AND (offering.description CONTAINS "implementation"
          OR offering.description CONTAINS "onboarding"
          OR offering.description CONTAINS "data migration")
  THEN also_assign_to("5.1")  # Onboarding Services

  # Rule 4: Platform API + Developer Tools → dual category
  IF offering.category == "1.3" (Platform API)
     AND (offering.description CONTAINS "SDK"
          OR offering.description CONTAINS "CLI"
          OR offering.description CONTAINS "developer tools")
  THEN also_assign_to("3.6")  # Developer Tools & SDKs

  # Rule 5: Enterprise Licensing + Usage-Based → dual category
  IF offering.category == "6.3" (Enterprise Licensing)
     AND (offering.description CONTAINS "consumption"
          OR offering.description CONTAINS "usage-based"
          OR offering.description CONTAINS "credits")
  THEN also_assign_to("6.2")  # Usage-Based Pricing

  # Rule 6: Authentication + Compliance → dual category
  IF offering.category == "4.1" (Authentication & SSO)
     AND (offering.description CONTAINS "HIPAA"
          OR offering.description CONTAINS "FedRAMP"
          OR offering.description CONTAINS "compliance")
  THEN also_assign_to("4.4")  # Compliance Certifications
```

## Dual-Category Assignment Patterns

| Pattern | Primary Category | Secondary Category | Trigger |
|---------|-----------------|-------------------|---------|
| Platform extensibility + marketplace | 1.4 | 3.2 | Third-party apps or marketplace mentioned |
| AI features + analytics | 2.4 | 2.1 | Analytics or dashboard context |
| Pro services + implementation | 5.5 | 5.1 | Implementation or migration context |
| API + developer SDK | 1.3 | 3.6 | SDK/CLI/developer tools mentioned |
| Enterprise + consumption pricing | 6.3 | 6.2 | Usage-based or credit pricing hybrid |
| Auth/SSO + regulatory compliance | 4.1 | 4.4 | HIPAA/FedRAMP/compliance context |

When duplicating to a secondary category: copy all fields, update `category`, add `cross_category_source` to track origin.
