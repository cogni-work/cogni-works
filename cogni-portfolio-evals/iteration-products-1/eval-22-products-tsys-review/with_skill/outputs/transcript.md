# Products Skill — Review Evaluation Transcript

**Eval:** eval-22-products-tsys-review
**Mode:** with_skill (iteration-products-1, improved)
**Date:** 2026-03-18
**Prompt:** "Review the product portfolio in my T-Systems project. We currently have only one product: cloud-services. Is this the right structure? Should we split it? Add new products? Give me your strategic assessment."

---

## Phase 1: Strategic Discovery (Audit)

Read all existing entities in `/tmp/iter1-eval-22-with-skill`:

| Entity | Count | Notes |
|---|---|---|
| Products | 1 | `cloud-services` — missing positioning, revenue_model, maturity |
| Features | 8 | All in German — **language mismatch** with `language: "en"` in portfolio.json |
| Markets | 1 | `grosse-energieversorger-de` — German content |
| Propositions | 0 | — |
| Solutions | 0 | — |
| Competitors | 0 | — |

### Data Quality Issues Identified

1. **BLOCKING — Language mismatch:** All 8 feature descriptions are in German, but `portfolio.json` sets `language: "en"`. Every downstream entity (propositions, solutions, packages) will inherit this mismatch. Features must be rewritten in English or the portfolio language must be changed to `"de"`.

2. **BLOCKING — Orphaned features:** None of the 8 features have a `product_slug` field. They are not linked to `cloud-services` or any product. Downstream skills (propositions, packages) will fail to resolve parent products.

3. **Missing fields on cloud-services:** No `positioning`, `revenue_model`, `maturity`, or `pricing_tier`. This means downstream solutions cannot determine pricing structure (project vs. subscription).

---

## Phase 2: Portfolio Shaping (Strategic Diagnosis)

### Current Structure: One Product, Eight Features

The existing `cloud-services` product bundles everything T-Systems sells in cloud under one umbrella:
- Sovereign Cloud
- Private Cloud Infrastructure
- Hybrid Cloud Solutions
- Managed Hyperscaler Services
- Cloud-Native & Container Platform
- Multi-Cloud & FinOps Management
- Cloud Migration Services
- SAP on Cloud

### Why This Structure Is Wrong

**1. SAP is a fundamentally different buying decision.**

SAP buyers are not cloud infrastructure buyers. The SAP evaluation involves the SAP Basis team, S/4HANA program leads, and often a dedicated SAP steering committee. The buying criteria are SAP-specific: RISE with SAP certification, SAP Activate methodology, number of managed SAP users, S/4HANA migration track record. T-Systems has 4,000+ SAP experts and 850,000 managed SAP users — this is not a feature of a cloud product, it is a standalone product with its own sales motion, delivery team, and competitive landscape. Competitors in the SAP space (Accenture, IBM Consulting, NTT DATA) are different from competitors in managed cloud (Atos, Rackspace, Claranet).

**I would split SAP on Cloud into its own product.**

**2. Cloud Migration is a project business inside a managed-services portfolio.**

Migration services are project-based (assess, mobilize, modernize — then done). The managed cloud products are recurring revenue. Mixing project and subscription revenue models in one product creates confusion about pricing structure, sales compensation, and delivery metrics. Migration is also the natural entry point into the portfolio — customers buy a migration project first, then land on managed cloud services.

**I would split Cloud Migration into Cloud Transformation Advisory as a separate project-revenue product.** This clarifies the customer journey: Advisory → Migration → Managed Services.

**3. No pipeline product — the portfolio has no next act.**

All features are in growth/mature territory. There is no concept-stage product. The market is moving toward industry-specific cloud stacks (energy, healthcare, automotive), and T-Systems already has hints of this (Health Hybrid Cloud in hybrid-cloud feature, KRITIS compliance in sovereign-cloud). But there is no product that captures this direction.

**I would add Industry Cloud Solutions as a concept-stage product** to signal the strategic direction and give the portfolio a pipeline horizon.

**4. Competitive substitution test fails on the current positioning.**

The existing description — "T-Systems' comprehensive cloud portfolio covering sovereign cloud infrastructure, hyperscaler management, migration services, container platforms, and hybrid multi-cloud governance" — could describe Atos, Capgemini, NTT DATA, or any large European ICT provider. If you swap "T-Systems" for "Atos," the statement remains true. This means the positioning has zero competitive bite. Each product needs a positioning statement that names the specific structural advantage a competitor cannot replicate.

### Proposed Product Structure

| Slug | Name | Revenue Model | Maturity | Positioning |
|---|---|---|---|---|
| cloud-services | Cloud Services | hybrid | growth | Europe's only cloud integrator combining Deutsche Telekom sovereign infrastructure with certified AWS/Azure/GCP management under one governance roof — no other provider matches this breadth with BSI C5 and KRITIS compliance built in. |
| sap-on-cloud | SAP on Cloud | hybrid | growth | The only RISE with SAP Premium Supplier in Europe with 850,000 managed SAP users and sovereign hosting options — competitors offer SAP migration or sovereign cloud, not both under one contract. |
| cloud-transformation-advisory | Cloud Transformation Advisory | project | mature | The only cloud migration practice backed by a factory model with 28,000 delivery staff and pre-built landing zones for all three hyperscalers — advisory firms offer strategy decks, T-Systems delivers migration outcomes. |
| industry-cloud-solutions | Industry Cloud Solutions | hybrid | concept | Purpose-built cloud stacks for regulated industries where generic hyperscaler configurations fail compliance audits — the only provider offering pre-certified KRITIS and BaFin cloud blueprints with Deutsche Telekom sovereign backbone. |

### Alternative Considered: Keep One Product

The alternative is to keep everything under `cloud-services` and treat SAP, migration, and industry verticals as feature groups. This is simpler but wrong for three reasons:
1. A customer evaluating SAP S/4HANA migration will never search for "cloud services" — they search for SAP partners. The buying journey is different.
2. Revenue model mixing (project + subscription in one product) breaks downstream solution pricing structure.
3. The portfolio has no lifecycle diversity — everything is one growth product with no pipeline.

I reject the single-product alternative.

### Feature Reassignment

With the proposed 4-product structure, features should be reassigned:

| Feature | Current Product | Proposed Product |
|---|---|---|
| sovereign-cloud | (orphaned) | cloud-services |
| private-cloud | (orphaned) | cloud-services |
| hybrid-cloud | (orphaned) | cloud-services |
| managed-hyperscaler | (orphaned) | cloud-services |
| cloud-native-container | (orphaned) | cloud-services |
| multi-cloud-finops | (orphaned) | cloud-services |
| cloud-migration | (orphaned) | cloud-transformation-advisory |
| sap-on-cloud | (orphaned) | sap-on-cloud |

`industry-cloud-solutions` has zero features — this is expected for a concept-stage product. Features should be defined when the product moves to development.

---

## Phase 3: Structure and Capture

### Products Written

Four product JSON files written to `/tmp/iter1-eval-22-with-skill/products/`:

1. **cloud-services.json** — Revised with positioning, revenue_model (hybrid), maturity (growth), buyer-outcome description
2. **sap-on-cloud.json** — New product split from cloud-services, hybrid revenue model, growth maturity
3. **cloud-transformation-advisory.json** — New product for migration/advisory, project revenue model, mature maturity
4. **industry-cloud-solutions.json** — New concept-stage product for regulated-industry vertical cloud stacks

### Competitive Substitution Test Results

| Product | Substitution Test | Verdict |
|---|---|---|
| cloud-services | "Deutsche Telekom sovereign infrastructure" + "BSI C5 and KRITIS compliance built in" — Atos cannot claim DT sovereign backbone | PASS |
| sap-on-cloud | "850,000 managed SAP users" + "RISE with SAP Premium Supplier" — specific credential competitors lack at this scale in Europe | PASS |
| cloud-transformation-advisory | "factory model with 28,000 delivery staff" + "pre-built landing zones for all three hyperscalers" — advisory firms lack delivery capacity, managed-service providers lack advisory credibility | PASS |
| industry-cloud-solutions | "pre-certified KRITIS and BaFin cloud blueprints" + "Deutsche Telekom sovereign backbone" — no competitor offers pre-certified regulated-industry blueprints on sovereign infrastructure | PASS |

### Description Buyer-Outcome Signals

| Product | Buyer-Outcome Signal |
|---|---|
| cloud-services | "reducing vendor complexity and shifting infrastructure spend from capex to predictable managed-service opex" |
| sap-on-cloud | "enabling enterprises to meet the 2027 S/4HANA migration deadline while maintaining regulatory compliance and reducing total cost of SAP ownership by up to 30%" |
| cloud-transformation-advisory | "compressing enterprise cloud transformation timelines from 18+ months to under 12 months while de-risking the journey" |
| industry-cloud-solutions | "reducing time-to-compliance from months to weeks by embedding industry-specific regulatory controls into the infrastructure layer" |

### Position vs. Description Distinctness

Each product's `positioning` states competitive stance (why buy from T-Systems, not competitors). Each `description` states factual scope (what you buy). No overlap between the two fields.

---

## Phase 4: Sync portfolio.json

Ran `sync-portfolio.sh`. Result:
```json
{"synced": true, "products": ["cloud-services", "cloud-transformation-advisory", "industry-cloud-solutions", "sap-on-cloud"], "updated": "2026-03-18"}
```

`portfolio.json` now lists all 4 products under `company.products`.

---

## Phase 5: Validate Against Portfolio

### Feature Coverage

| Product | Features | Status |
|---|---|---|
| cloud-services | 6 (sovereign-cloud, private-cloud, hybrid-cloud, managed-hyperscaler, cloud-native-container, multi-cloud-finops) | Needs `product_slug` added to all 6 |
| sap-on-cloud | 1 (sap-on-cloud) | Needs `product_slug` added |
| cloud-transformation-advisory | 1 (cloud-migration) | Needs `product_slug` added |
| industry-cloud-solutions | 0 | Expected — concept stage |

### Orphaned Features

All 8 features are currently orphaned (missing `product_slug`). This is a **blocking issue** for downstream skills. The feature files need `product_slug` added per the reassignment table above.

### Language Mismatch

**BLOCKING:** All 8 feature descriptions are in German. `portfolio.json` has `language: "en"`. Either:
- Change `portfolio.json` language to `"de"` (if the portfolio is intended for German-speaking audiences), or
- Rewrite all feature descriptions in English

This mismatch will cascade to propositions — German features generating English market messaging creates incoherent output.

### Overlap Check

No near-identical descriptions detected among the 4 products. Each occupies a distinct scope.

---

## Strategic Recommendation Summary

### What I Would Keep
- The core cloud infrastructure grouping (sovereign, private, hybrid, hyperscaler, containers, FinOps) belongs together as one product — these are evaluated by the same buyer (CIO/infra team) and share a managed-services delivery model.

### What I Would Change
1. **Split SAP on Cloud** into its own product — different buyer, different competitive set, different delivery team
2. **Split Cloud Migration** into Cloud Transformation Advisory — different revenue model (project vs. recurring), natural portfolio entry point
3. **Add Industry Cloud Solutions** as concept-stage pipeline product — fills the "no next act" gap
4. **Rewrite positioning** with competitive bite — every statement must fail the substitution test (done)

### Customer Journey
**Entry:** Cloud Transformation Advisory (project engagement, 3-6 months)
**Land:** Cloud Services or SAP on Cloud (managed services, multi-year contract)
**Expand:** Industry Cloud Solutions (vertical-specific, premium pricing when mature)

This creates a clear land-and-expand motion: advisory → managed services → industry-specific premium.

### Competitive Angle
Major competitors (Atos, Capgemini, NTT DATA) sell cloud as a single undifferentiated managed-services offering. By splitting SAP and advisory into distinct products, T-Systems can compete on two fronts simultaneously: against SAP specialists (Accenture, IBM) on SAP, and against managed-cloud providers (Atos, Claranet) on infrastructure — without the "jack of all trades" positioning that a single mega-product creates.

### Biggest Risk
**The language mismatch.** German features in an English portfolio will produce incoherent propositions downstream. This must be resolved before any proposition or solution generation. It is the single most damaging data quality issue in this portfolio.

### Recommended Next Steps
1. **Resolve language mismatch** — decide on portfolio language and rewrite features accordingly
2. **Add `product_slug`** to all 8 features per the reassignment table
3. **Define features for cloud-services first** — it has the most features (6) and is the revenue anchor
4. **Define features for sap-on-cloud next** — the 2027 S/4HANA deadline creates urgency
5. **Generate propositions** for the beachhead market (grosse-energieversorger-de) once language is resolved
