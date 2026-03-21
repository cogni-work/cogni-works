# Cross-Category Assignment Rules

Some offerings legitimately span multiple taxonomy categories. After aggregating offerings from all domains, analyze each offering for multi-category fit.

## Detection Rules

```text
FOR each offering in all_offerings:

  # Rule 1: Payment Orchestration + Cross-Border → dual category
  IF offering.category == "1.6" (Payment Orchestration)
     AND (offering.description CONTAINS "cross-border"
          OR offering.description CONTAINS "multi-currency"
          OR offering.description CONTAINS "international")
  THEN also_assign_to("1.3")  # Cross-Border Payments

  # Rule 2: Open Banking + Payments PSD2 → dual category
  IF offering.category == "2.5" (Open Banking & API)
     AND (offering.description CONTAINS "payment initiation"
          OR offering.description CONTAINS "PSD2 payments"
          OR offering.description CONTAINS "PISP")
  THEN also_assign_to("1.1")  # Card Processing

  # Rule 3: KYC/AML + Account Onboarding → dual category
  IF offering.category == "3.1" (KYC/AML)
     AND (offering.description CONTAINS "onboarding"
          OR offering.description CONTAINS "account opening"
          OR offering.description CONTAINS "customer verification")
  THEN also_assign_to("2.4")  # Account Management

  # Rule 4: AI/ML + Fraud Detection → dual category
  IF offering.category == "6.3" (AI/ML for Financial Services)
     AND (offering.description CONTAINS "fraud"
          OR offering.description CONTAINS "anomaly detection"
          OR offering.description CONTAINS "suspicious")
  THEN also_assign_to("3.2")  # Fraud Detection

  # Rule 5: Core Banking + BaaS → dual category
  IF offering.category == "2.1" (Core Banking Platform)
     AND (offering.description CONTAINS "as-a-service"
          OR offering.description CONTAINS "embedded"
          OR offering.description CONTAINS "white-label"
          OR offering.description CONTAINS "BaaS")
  THEN also_assign_to("2.6")  # Banking-as-a-Service

  # Rule 6: Embedded Finance APIs + Payment Services → dual category
  IF offering.category == "6.2" (Embedded Finance APIs)
     AND (offering.description CONTAINS "payment"
          OR offering.description CONTAINS "checkout"
          OR offering.description CONTAINS "pay-in"
          OR offering.description CONTAINS "pay-out")
  THEN also_assign_to("1.5")  # Merchant Acquiring

  # Rule 7: Transaction Monitoring + Sanctions Screening → dual category
  IF offering.category == "3.5" (Transaction Monitoring)
     AND (offering.description CONTAINS "sanctions"
          OR offering.description CONTAINS "watchlist"
          OR offering.description CONTAINS "OFAC")
  THEN also_assign_to("3.6")  # Sanctions Screening

  # Rule 8: Portfolio Management + Actuarial Analytics → dual category
  IF offering.category == "4.4" (Portfolio Management)
     AND (offering.description CONTAINS "insurance"
          OR offering.description CONTAINS "actuarial"
          OR offering.description CONTAINS "asset-liability")
  THEN also_assign_to("5.5")  # Actuarial Analytics

  # Rule 9: Regulatory Consulting + Regulatory Reporting → dual category
  IF offering.category == "7.1" (Regulatory Consulting)
     AND (offering.description CONTAINS "reporting"
          OR offering.description CONTAINS "filing"
          OR offering.description CONTAINS "returns")
  THEN also_assign_to("3.4")  # Regulatory Reporting

  # Rule 10: Technology Implementation + Digital Transformation → dual category
  IF offering.category == "7.2" (Technology Implementation)
     AND (offering.description CONTAINS "modernization"
          OR offering.description CONTAINS "cloud migration"
          OR offering.description CONTAINS "legacy replacement")
  THEN also_assign_to("7.3")  # Digital Transformation
```

## Dual-Category Assignment Patterns

| Pattern | Primary Category | Secondary Category | Trigger |
|---------|-----------------|-------------------|---------|
| Payment orchestration + cross-border | 1.6 | 1.3 | Multi-currency or international context |
| Open banking + payment initiation | 2.5 | 1.1 | PSD2 payment initiation or PISP |
| KYC/AML + account onboarding | 3.1 | 2.4 | Customer onboarding or account opening |
| AI/ML + fraud detection | 6.3 | 3.2 | Fraud or anomaly detection context |
| Core banking + BaaS | 2.1 | 2.6 | As-a-service or embedded context |
| Embedded finance + payments | 6.2 | 1.5 | Payment or checkout context |
| Transaction monitoring + sanctions | 3.5 | 3.6 | Sanctions or watchlist screening |
| Portfolio mgmt + actuarial | 4.4 | 5.5 | Insurance or asset-liability context |
| Regulatory consulting + reporting | 7.1 | 3.4 | Regulatory filing or returns |
| Implementation + transformation | 7.2 | 7.3 | Modernization or legacy replacement |

When duplicating to a secondary category: copy all fields, update `category`, add `cross_category_source` to track origin.
