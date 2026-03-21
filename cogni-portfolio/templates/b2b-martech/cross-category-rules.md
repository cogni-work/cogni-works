# Cross-Category Assignment Rules

Some offerings legitimately span multiple taxonomy categories. After aggregating offerings from all domains, analyze each offering for multi-category fit.

## Detection Rules

```text
FOR each offering in all_offerings:

  # Rule 1: CDP + Programmatic Advertising Activation
  IF offering.category == "1.1" (Customer Data Platform)
     AND (offering.description CONTAINS "programmatic"
          OR offering.description CONTAINS "DSP"
          OR offering.description CONTAINS "advertising activation"
          OR offering.description CONTAINS "ad targeting")
  THEN also_assign_to("4.1")  # Programmatic Advertising (DSP/SSP)

  # Rule 2: Commerce Experience + Personalization
  IF offering.category == "3.4" (Commerce Experience)
     AND (offering.description CONTAINS "personalization"
          OR offering.description CONTAINS "recommendation"
          OR offering.description CONTAINS "personalized"
          OR offering.description CONTAINS "dynamic content")
  THEN also_assign_to("3.3")  # Personalization Engine

  # Rule 3: AI/ML for Marketing + CMS Generative Content
  IF offering.category == "5.3" (AI/ML for Marketing)
     AND (offering.description CONTAINS "content generation"
          OR offering.description CONTAINS "generative content"
          OR offering.description CONTAINS "AI authoring"
          OR offering.description CONTAINS "content creation")
  THEN also_assign_to("3.1")  # Content Management System (CMS)

  # Rule 4: Consent Management + Data Privacy
  IF offering.category == "6.1" (Cookie/Consent Management)
     AND (offering.description CONTAINS "GDPR"
          OR offering.description CONTAINS "CCPA"
          OR offering.description CONTAINS "data subject"
          OR offering.description CONTAINS "privacy regulation")
  THEN also_assign_to("6.2")  # Data Privacy (GDPR/CCPA)

  # Rule 5: Journey Orchestration + Customer Journey Analytics
  IF offering.category == "2.3" (Journey Orchestration)
     AND (offering.description CONTAINS "analytics"
          OR offering.description CONTAINS "path analysis"
          OR offering.description CONTAINS "journey insights"
          OR offering.description CONTAINS "journey reporting")
  THEN also_assign_to("5.2")  # Customer Journey Analytics

  # Rule 6: Identity Resolution + Data Clean Rooms
  IF offering.category == "1.2" (Identity Resolution)
     AND (offering.description CONTAINS "clean room"
          OR offering.description CONTAINS "data collaboration"
          OR offering.description CONTAINS "privacy-safe matching")
  THEN also_assign_to("1.6")  # Data Clean Rooms

  # Rule 7: Marketing Automation + Lead Scoring
  IF offering.category == "2.2" (Marketing Automation)
     AND (offering.description CONTAINS "lead scoring"
          OR offering.description CONTAINS "lead qualification"
          OR offering.description CONTAINS "MQL"
          OR offering.description CONTAINS "nurture")
  THEN also_assign_to("2.5")  # Lead Scoring & Nurturing

  # Rule 8: Attribution + Marketing Analytics
  IF offering.category == "4.5" (Attribution & Measurement)
     AND (offering.description CONTAINS "dashboard"
          OR offering.description CONTAINS "campaign performance"
          OR offering.description CONTAINS "channel analytics")
  THEN also_assign_to("5.1")  # Marketing Analytics
```

## Dual-Category Assignment Patterns

| Pattern | Primary Category | Secondary Category | Trigger |
|---------|-----------------|-------------------|---------|
| CDP + programmatic activation | 1.1 | 4.1 | Advertising activation or DSP mentioned |
| Commerce + personalization | 3.4 | 3.3 | Personalization or recommendations in commerce context |
| AI/ML + generative content | 5.3 | 3.1 | Content generation or AI authoring mentioned |
| Consent + data privacy | 6.1 | 6.2 | GDPR/CCPA regulatory context |
| Journey orchestration + journey analytics | 2.3 | 5.2 | Analytics or reporting in journey context |
| Identity resolution + clean rooms | 1.2 | 1.6 | Clean room or privacy-safe matching mentioned |
| Marketing automation + lead scoring | 2.2 | 2.5 | Lead scoring or nurture in automation context |
| Attribution + marketing analytics | 4.5 | 5.1 | Dashboard or campaign performance context |

When duplicating to a secondary category: copy all fields, update `category`, add `cross_category_source` to track origin.
