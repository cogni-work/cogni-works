# Portfolio Review: T-Systems Cloud Services

## Executive Summary

T-Systems currently operates a single product called "Cloud Services" that bundles 8 features spanning sovereign infrastructure, hyperscaler management, migration services, container platforms, SAP hosting, private cloud, FinOps governance, and hybrid cloud. This is a textbook case of the **accidental bundle** anti-pattern. The product is too broad to pass the "would a customer evaluate and buy this independently?" test — because no customer evaluates all 8 of these capabilities in a single buying decision.

I would split this into 3 products. Here is my strategic assessment.

---

## What I Would Keep

**The feature set itself is strong.** Eight features covering the full cloud lifecycle — from sovereign infrastructure through migration, operations, and cost optimization — is a credible enterprise cloud portfolio. T-Systems has genuine differentiation in sovereign cloud (European data residency, BaFin/KRITIS compliance) and SAP (Platinum Partner, 4,000+ experts). These are not generic capabilities; they are earned positions.

**The taxonomy alignment is solid.** These features map naturally to the b2b-ict taxonomy's Cloud Services dimension. There is no obvious gap in the cloud infrastructure story.

## What I Would Change

I would restructure the single "cloud-services" product into **three distinct products**, each with a clear buyer, buying motion, and revenue model:

### Product 1: Sovereign Cloud Infrastructure

**Features:** sovereign-cloud, private-cloud, hybrid-cloud

**Why this grouping:** These three features share a common buyer (CISO / Head of Infrastructure in regulated industries), a common buying trigger (compliance mandate or data residency requirement), and a common competitive frame (vs. hyperscaler-native sovereignty offerings from AWS/Google/Azure). A customer evaluating sovereign cloud will inevitably ask about private cloud as a fallback and hybrid cloud as the bridge. They belong together.

**Revenue model:** Subscription. These are infrastructure services with recurring revenue — monthly/annual commitments, not project engagements.

**Maturity:** Growth. Sovereign cloud is a hot market in Europe post-Schrems II and with ongoing EU data sovereignty regulation. T-Systems has a first-mover position with Open Sovereign Cloud and the Deutsche Telekom trust brand.

**Positioning:** "European-sovereign cloud infrastructure for regulated enterprises — fully EU-operated, BaFin and KRITIS compliant, with private and hybrid deployment options."

### Product 2: Cloud Transformation Services

**Features:** cloud-migration, managed-hyperscaler, multi-cloud-finops, cloud-native-container

**Why this grouping:** These four features represent the operational lifecycle of cloud adoption: migrate (cloud-migration), operate (managed-hyperscaler), optimize (multi-cloud-finops), and modernize (cloud-native-container). They share a common buyer (VP/Head of Cloud Operations or CTO), a common buying motion (starts with migration, expands into managed services), and a common revenue model (project-based initial engagement expanding into managed services).

**Revenue model:** Hybrid. Migration is project-based (one-time engagement), but managed hyperscaler and FinOps are recurring subscription services. This product naturally blends both — land with a migration project, expand into ongoing managed services.

**Maturity:** Mature. Cloud migration and managed services are established markets. T-Systems competes here on certification depth (AWS/Azure/GCP MSP partnerships) and the CMF methodology.

**Positioning:** "End-to-end cloud transformation — from migration through managed operations and FinOps optimization — delivered by certified hyperscaler partners."

### Product 3: SAP on Cloud

**Features:** sap-on-cloud

**Why a separate product:** SAP is its own buying center. The person evaluating SAP hosting is the SAP Basis lead or the VP of Enterprise Applications — a completely different buyer from the cloud infrastructure buyer. SAP decisions involve SAP-specific criteria (RISE with SAP certification, S/4HANA expertise, SAP user count capacity). Bundling SAP into "cloud services" dilutes this positioning and makes it invisible to the SAP buyer.

**Revenue model:** Hybrid. SAP hosting involves subscription infrastructure plus project-based migration and implementation services.

**Maturity:** Growth. The RISE with SAP wave is driving massive migration activity. T-Systems' Premium Supplier status and 4,000+ SAP experts are a genuine competitive moat.

**Positioning:** "SAP Platinum Partner delivering end-to-end S/4HANA hosting, migration, and operations as a RISE with SAP Premium Supplier."

**Note:** This product currently has only one feature. That is acceptable because SAP on Cloud is a distinct buying decision, and sub-capabilities (hosting, migration, basis operations, performance optimization) can be broken out as separate features later if needed. A single-feature product is better than a mis-scoped multi-feature product.

---

## Customer Journey Analysis

The current single-product structure has no customer journey — it's a flat catalog. The three-product structure creates a natural **land-and-expand** motion:

1. **Entry point — Cloud Transformation Services.** Most enterprise cloud journeys start with a migration need. The customer engages T-Systems for a cloud migration assessment, which leads to a migration project, which naturally expands into managed hyperscaler services and FinOps optimization. This is the highest-volume entry product.

2. **Expansion — Sovereign Cloud Infrastructure.** Once the customer is running workloads with T-Systems, the conversation about data sovereignty naturally arises — especially in regulated industries (financial services, healthcare, public sector). "You're already running on our managed hyperscaler; let us move your sensitive workloads to sovereign infrastructure." This is the upsell path with the highest margin.

3. **Parallel track — SAP on Cloud.** SAP engagements often run on a separate timeline from general cloud transformation. A customer may engage on SAP first (driven by an S/4HANA mandate) and later expand into broader cloud services, or vice versa. The key is that SAP has its own entry point and its own expansion path (hosting leads to migration leads to managed operations).

**What's missing:** There is no self-serve or low-commitment entry point. Every engagement requires a sales conversation and a substantial commitment. For T-Systems' enterprise market this may be acceptable, but consider whether a FinOps assessment or cloud readiness assessment could serve as a low-friction "proof of value" entry that feeds the pipeline.

---

## Competitive Angle

T-Systems' portfolio structure should be compared to how competitors organize their offerings:

- **Hyperscalers (AWS, Azure, GCP)** sell platform capabilities, not managed services. T-Systems' value is the management layer on top — and the sovereign layer that hyperscalers cannot credibly offer in Europe.

- **Managed service providers (Rackspace, Claranet, NTT)** typically split along the same lines I'm proposing: infrastructure services, transformation/migration services, and application-specific hosting (SAP, Oracle). This is an established pattern that enterprise buyers understand.

- **European sovereignty players (OVHcloud, IONOS, Stackit)** compete primarily on the sovereign infrastructure story. T-Systems' advantage is that sovereignty is one product in a broader portfolio — the customer can get sovereign infrastructure AND managed hyperscaler AND SAP hosting from the same provider. The competitors force the customer to stitch together multiple vendors.

The three-product structure positions T-Systems as the only provider that spans all three buying decisions. That's a genuine competitive advantage — but only if the portfolio structure makes it visible. A single "cloud services" product hides this breadth behind a generic label.

---

## Biggest Risk

**The biggest structural risk is that the current monolithic product makes T-Systems invisible in segment-specific evaluations.** When a CISO is evaluating sovereign cloud options, T-Systems shows up as a "cloud services" company — indistinguishable from any other MSP. When an SAP Basis lead is evaluating RISE with SAP partners, T-Systems' 4,000 SAP experts are buried inside a generic cloud portfolio.

Enterprise buyers don't evaluate "cloud services" — they evaluate specific solutions to specific problems. A sovereign cloud buyer, a migration buyer, and an SAP buyer are three different people with three different budgets, three different timelines, and three different evaluation criteria. The portfolio structure must reflect this reality or T-Systems will consistently lose to specialists who show up with a focused offering.

If this structural issue is not addressed, every downstream entity — propositions, competitive analyses, solutions, packages — will inherit the confusion. Features will generate propositions that try to be everything to everyone, competitive analyses will compare T-Systems to the wrong competitors, and solutions will be priced as generic cloud services when they should be priced as specialized capabilities.

---

## Recommended Next Steps

1. **Approve the three-product structure** (or push back — the conversation is the value). The proposed products are saved alongside this memo.

2. **Assign features to products.** Every feature needs a `product_slug` field. Currently none of the 8 features have one. This is the most urgent data quality issue.

3. **Standardize feature language.** The portfolio language is set to English, but all features are written in German. Either change the portfolio language to `"de"` (which seems appropriate for a German enterprise ICT provider) or rewrite the feature descriptions in English for consistency.

4. **Add product metadata.** The current cloud-services product has no `positioning`, `revenue_model`, `maturity`, or `pricing_tier`. The proposed products include these fields.

5. **Define features for Cloud Transformation Services first.** This product has the most features (4) and the clearest land-and-expand journey. It's the best candidate for building out propositions and solutions next.

6. **Consider splitting SAP on Cloud into sub-features.** The single `sap-on-cloud` feature covers hosting, migration, and operations. These could be three separate features to enable more targeted propositions per market segment.

---

## Proposed Portfolio Structure

| Slug | Name | Revenue Model | Maturity | Features | Positioning |
|---|---|---|---|---|---|
| sovereign-cloud-infrastructure | Sovereign Cloud Infrastructure | subscription | growth | 3 (sovereign-cloud, private-cloud, hybrid-cloud) | European-sovereign cloud infrastructure for regulated enterprises |
| cloud-transformation-services | Cloud Transformation Services | hybrid | mature | 4 (cloud-migration, managed-hyperscaler, multi-cloud-finops, cloud-native-container) | End-to-end cloud transformation from migration through managed operations |
| sap-on-cloud | SAP on Cloud | hybrid | growth | 1 (sap-on-cloud) | SAP Platinum Partner for S/4HANA hosting, migration, and operations |
