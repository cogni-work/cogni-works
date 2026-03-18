# T-Systems Product Portfolio Review — Strategic Assessment

## Current State

The portfolio contains a single product, **Cloud Services**, with 8 features spanning very different capabilities:

| Feature | Domain |
|---------|--------|
| sovereign-cloud | Data sovereignty / compliance |
| private-cloud | On-prem / dedicated infrastructure |
| managed-hyperscaler | AWS/Azure/GCP operations |
| hybrid-cloud | Cross-cloud orchestration |
| multi-cloud-finops | Governance and cost management |
| cloud-migration | Migration programs |
| cloud-native-container | Kubernetes / modernization |
| sap-on-cloud | SAP-specific hosting and migration |

All feature descriptions are in German, while the portfolio language is set to "en".

## Problem with Single-Product Structure

A single "Cloud Services" product is too broad for meaningful portfolio management:

1. **Different buyer personas** — A CISO buying sovereign cloud has different concerns than a CTO buying migration services or an SAP basis team evaluating S/4HANA hosting.
2. **Different sales motions** — Sovereign cloud sells on compliance and trust; managed multi-cloud sells on operational efficiency; cloud transformation sells on modernization ROI.
3. **Different competitive landscapes** — Sovereign cloud competes with OVHcloud and Ionos; managed cloud competes with Rackspace and Accenture; SAP competes with other SAP partners.
4. **No portfolio-level insight** — With everything in one bucket, you cannot track which product lines are growing, which need investment, or where to place strategic bets.

## Recommended Structure: 4 Products

### 1. Sovereign Cloud
**Features:** sovereign-cloud, private-cloud

Rationale: Sovereign cloud and private cloud share the same value proposition — European data residency and regulatory compliance. Buyers in regulated industries (finance, healthcare, public sector) evaluate these together. This is T-Systems' strongest differentiator versus hyperscaler-only competitors.

### 2. Managed Multi-Cloud
**Features:** managed-hyperscaler, hybrid-cloud, multi-cloud-finops

Rationale: These three features form a coherent operations story — manage hyperscaler environments, connect them via hybrid cloud, and govern cost and compliance across all of them. The buyer is typically a cloud platform team or CTO looking for a single MSP partner.

### 3. Cloud Transformation
**Features:** cloud-migration, cloud-native-container

Rationale: Migration and cloud-native enablement are sequential stages of the same customer journey (move workloads, then modernize them). These are project-based engagements with a clear start and end, unlike the ongoing managed services above.

### 4. SAP on Cloud
**Features:** sap-on-cloud

Rationale: SAP is a distinct market with its own ecosystem (RISE with SAP, SAP Activate), its own buyer (SAP basis / SAP CoE), and its own competitive set (other SAP Platinum Partners). Keeping it as a standalone product ensures it gets dedicated positioning and does not get lost inside a generic cloud umbrella.

## Feature-to-Product Mapping

| Feature | Old Product | New Product |
|---------|------------|-------------|
| sovereign-cloud | cloud-services | sovereign-cloud |
| private-cloud | cloud-services | sovereign-cloud |
| managed-hyperscaler | cloud-services | managed-multi-cloud |
| hybrid-cloud | cloud-services | managed-multi-cloud |
| multi-cloud-finops | cloud-services | managed-multi-cloud |
| cloud-migration | cloud-services | cloud-transformation |
| cloud-native-container | cloud-services | cloud-transformation |
| sap-on-cloud | cloud-services | sap-on-cloud |

All 8 features are accounted for. No features are dropped or duplicated.

## Additional Observations

- **Language mismatch**: The portfolio is set to `"language": "en"` but all feature descriptions are in German. These should be aligned.
- **portfolio.json not linked**: The `products` and `features` arrays in portfolio.json are empty. After restructuring, these should reference the new product slugs.
- **Markets directory is empty**: No market definitions exist yet. With a 4-product structure, market segmentation becomes more actionable (e.g., sovereign cloud targets public sector and finance; SAP on Cloud targets manufacturing and utilities).

## Files Created

- `sovereign-cloud.json` — Sovereign Cloud product (2 features)
- `managed-multi-cloud.json` — Managed Multi-Cloud product (3 features)
- `cloud-transformation.json` — Cloud Transformation product (2 features)
- `sap-on-cloud.json` — SAP on Cloud product (1 feature)
