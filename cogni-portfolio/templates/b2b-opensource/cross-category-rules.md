# Cross-Category Assignment Rules

Some offerings legitimately span multiple taxonomy categories. After aggregating offerings from all domains, analyze each offering for multi-category fit.

## Detection Rules

```text
FOR each offering in all_offerings:

  # Rule 1: Managed cloud + Marketplace → dual category
  IF offering.category == "3.1" (Fully Managed Cloud)
     AND (offering.description CONTAINS "marketplace"
          OR offering.description CONTAINS "AWS Marketplace"
          OR offering.description CONTAINS "Azure Marketplace")
  THEN also_assign_to("3.5")  # Marketplace Listings

  # Rule 2: Enterprise features + Security hardening → dual category
  IF offering.category == "2.1" (Enterprise Edition Features)
     AND (offering.description CONTAINS "security"
          OR offering.description CONTAINS "FIPS"
          OR offering.description CONTAINS "encryption"
          OR offering.description CONTAINS "hardening")
  THEN also_assign_to("2.2")  # Security Hardening & FIPS

  # Rule 3: License model + Cloud moat pattern → flag for review
  IF offering.category == "7.1" (License Model)
     AND (offering.description CONTAINS "source-available"
          OR offering.description CONTAINS "BSL"
          OR offering.description CONTAINS "SSPL")
     AND company_has_managed_cloud == true
  THEN flag_for_review("open-core-cloud-moat")
  # This is the pattern where licensing restricts competing managed services

  # Rule 4: Certification program + Training → dual category
  IF offering.category == "4.5" (Certification Program)
     AND (offering.description CONTAINS "training"
          OR offering.description CONTAINS "workshop"
          OR offering.description CONTAINS "instructor-led")
  THEN also_assign_to("6.4")  # Training & Enablement

  # Rule 5: Community distributions + Edge deployment → dual category
  IF offering.category == "1.5" (Community Distributions)
     AND (offering.description CONTAINS "edge"
          OR offering.description CONTAINS "IoT"
          OR offering.description CONTAINS "ARM"
          OR offering.description CONTAINS "lightweight")
  THEN also_assign_to("3.6")  # Edge Deployment

  # Rule 6: Enterprise integrations + Admin console → dual category
  IF offering.category == "2.6" (Enterprise Integrations)
     AND (offering.description CONTAINS "admin"
          OR offering.description CONTAINS "management console"
          OR offering.description CONTAINS "governance")
  THEN also_assign_to("2.5")  # Admin & Governance Console

  # Rule 7: Self-hosted + Managed operations → dual category
  IF offering.category == "3.3" (Self-Hosted with Vendor Support)
     AND (offering.description CONTAINS "managed"
          OR offering.description CONTAINS "monitoring"
          OR offering.description CONTAINS "24/7")
  THEN also_assign_to("6.5")  # Managed Operations
```

## Dual-Category Assignment Patterns

| Pattern | Primary Category | Secondary Category | Trigger |
|---------|-----------------|-------------------|---------|
| Managed cloud on marketplace | 3.1 | 3.5 | AWS/Azure/GCP marketplace billing |
| Enterprise features + security | 2.1 | 2.2 | FIPS/encryption/hardening context |
| Source-available + managed cloud | 7.1 | flag | BSL/SSPL + cloud offering = "cloud moat" pattern |
| Certification + training | 4.5 | 6.4 | Instructor-led or workshop context |
| Community distro + edge | 1.5 | 3.6 | Lightweight/IoT/ARM context |
| Enterprise integrations + admin | 2.6 | 2.5 | Admin console or governance context |
| Self-hosted + managed ops | 3.3 | 6.5 | 24/7 monitoring or managed services context |

When duplicating to a secondary category: copy all fields, update `category`, add `cross_category_source` to track origin.

## COSS-Specific: The "Open Core + Cloud Moat" Pattern

Many COSS companies use restrictive licenses (SSPL, BSL) to prevent cloud providers from offering competing managed services while offering their own managed cloud. When detected:

1. Capture in category 7.1 (License Model) with the specific license and rationale
2. Cross-reference with category 3.1 (Fully Managed Cloud) to show the commercial strategy
3. Flag in propositions as a competitive differentiation angle — the IS (open-source project) is freely available, but the DOES (managed cloud without license risk) is the commercial moat
