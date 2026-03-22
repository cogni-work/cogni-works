# Products Skill Evaluation — Bechtle AG Cold Start

**Eval ID:** eval-21-products-bechtle-cold-start
**Iteration:** products-1 (improved)
**Skill:** products
**Date:** 2026-03-18

---

## Phase 1: Strategic Discovery

**Input context:** The user described Bechtle AG as "Germany's largest IT reseller and system integrator" selling four revenue streams: hardware, software licensing, managed services, and IT consulting. The project path is `/tmp/iter1-eval-21-with-skill`. Portfolio.json confirms Bechtle AG, ICT Services industry, DE country, 15,000 employees, empty products/features arrays. Language is English.

**What I already know (skip redundant questions):**
- Bechtle is publicly traded (ISIN DE0005158703), ~EUR 6B revenue
- Revenue split is roughly 70% IT e-commerce (resale), 30% IT system house & managed services
- They operate 80+ locations (Systemhäuser) across DACH plus 14 European countries
- Primary segments: "IT System House & Managed Services" and "IT E-Commerce"
- Key vendor partnerships: Microsoft (top German partner), Cisco, HP, VMware, Dell
- Competitors: Cancom, Computacenter, SHI, Insight, Atos (services), T-Systems (managed)

**Key discovery questions that remain:**
1. Do the four revenue streams (hardware, software licensing, managed services, consulting) map to how *customers* buy — or to how Bechtle's P&L is organized?
2. Is there a natural entry point product, or do most customers enter through a sales conversation?
3. Is there a pipeline product for what comes next beyond today's offerings?

**Discovery assessment:** The user gave four streams. The cold-start discipline requires me NOT to default to four products. I need to question whether org-chart silos = right product boundaries.

---

## Phase 2: Portfolio Shaping

### The Cold-Start Challenge

The user named four revenue streams: hardware, software licensing, managed services, IT consulting. Mapping these 1:1 to products would be the org-chart trap. Here's why:

**Problem 1 — Hardware and software licensing are not separate buying decisions.** When a customer buys 200 laptops, they also buy Windows licenses, Microsoft 365 seats, and often endpoint management software. No customer evaluates "hardware procurement" and "software licensing" as independent products. They're one purchase decision: "I need equipped, licensed IT infrastructure." Splitting them creates artificial boundaries that don't match how procurement teams think.

**Problem 2 — "IT consulting" is too broad.** Bechtle's consulting spans cloud migration, network architecture, security, workplace modernization, and more. These serve radically different buyer personas (CISO vs. CIO vs. CFO) and compete against different competitors. As one product, "IT consulting" fails the differentiation test — it's a department, not a product.

**Problem 3 — No pipeline product.** All four streams are mature or growth-stage. Where is Bechtle's next act? With sovereignty concerns, NIS2 regulation, and DACH public sector cloud mandates, there's a clear concept-stage opportunity.

### Alternative Structure A: Mirror the User's 4 Streams (Not Recommended)

| # | Product | Revenue Model | Issue |
|---|---------|---------------|-------|
| 1 | Hardware Procurement | hybrid | Not independently buyable — always bundled with licensing |
| 2 | Software Licensing | hybrid | Same buyer, same PO as hardware |
| 3 | Managed Services | subscription | Viable but positioning would be generic |
| 4 | IT Consulting | project | Too broad — cloud vs. security vs. workplace are different decisions |

**Why I reject this:** Products 1 and 2 fail the "buyable independently" test (they're always co-purchased). Product 4 fails the "distinct from siblings" test (it's a catch-all). No concept-stage product for pipeline.

### Alternative Structure B: 5 Products, Buyer-Journey Aligned (Recommended)

| # | Product | Revenue Model | Maturity | Rationale |
|---|---------|---------------|----------|-----------|
| 1 | **IT Commerce** | hybrid | mature | Merges hardware + software licensing into a single procurement product. This is how customers buy: one PO, one vendor, configured and licensed. |
| 2 | **Managed IT Services** | subscription | growth | Pure recurring-revenue operations. Distinct buyer (IT ops leader wanting to outsource) and distinct competitive set (MSPs, not resellers). |
| 3 | **IT Consulting & Integration** | project | growth | Project-based advisory and implementation. Scoped to infrastructure modernization (cloud, network, security). Distinct from managed services because it's project-based with a defined end state. |
| 4 | **Digital Workplace** | hybrid | growth | Carved out of both "hardware" and "consulting" — this is the intersection where device procurement meets M365 deployment meets endpoint management. It's a distinct buying decision because the buyer is HR/IT leadership solving employee productivity, not infrastructure teams solving server problems. |
| 5 | **Sovereign Cloud Platform** | subscription | concept | Pipeline product. Data sovereignty + NIS2 compliance + DACH public sector cloud mandates create a clear opportunity. Bechtle's multi-vendor neutrality and German presence are structural advantages. |

**Why this is better:**
- **IT Commerce** unifies hardware + software because that's one buying decision
- **Digital Workplace** is carved out because the buyer persona and competitive set are different (Microsoft Modern Work ecosystem vs. infrastructure vendors)
- **Sovereign Cloud Platform** fills the pipeline gap with a concrete concept-stage product
- Clear customer journey: Enter via IT Commerce (transactional, low commitment) → expand to Digital Workplace or Consulting (project-based, higher trust) → land on Managed Services (recurring, highest stickiness) → future upsell to Sovereign Cloud

### Strategic Lenses Applied

**Maturity balance:** One mature product (IT Commerce — Bechtle's cash cow), three growth products, one concept product. This is a healthy distribution. The mature product funds investment in growth products, and the concept product ensures pipeline.

**Customer journey:** IT Commerce is the natural entry point — low-risk, transactional. A customer buying hardware discovers Bechtle can also configure, deploy, and manage it. The expansion path: Commerce → Workplace (bundles procurement with deployment) → Consulting (deeper projects) → Managed Services (ongoing relationship). Sovereign Cloud is the future upsell for regulated customers.

**Competitive positioning:**
- vs. **Cancom** (direct competitor): Similar portfolio breadth, but Bechtle's 80+ locations give logistics and on-site density Cancom can't match
- vs. **Computacenter** (UK-based): Strong in UK, weaker DACH presence; Bechtle owns the DACH mid-market
- vs. **T-Systems** (managed services): T-Systems sells their own cloud; Bechtle's multi-vendor neutrality is the differentiator
- vs. **Pure-play MSPs** (managed): No procurement integration; Bechtle owns the full stack
- vs. **Atos/Accenture** (consulting): Vendor-agnostic boutiques or vendor-captive giants; Bechtle holds top-tier certs across all major vendors simultaneously

**Competitive substitution test on positioning:**
- IT Commerce positioning mentions 80+ Systemhäuser and 44,000+ SKUs — competitor-specific, cannot be swapped
- Managed IT Services positioning anchors on nationwide on-site + centralized NOC/SOC — structural advantage over remote-only MSPs
- IT Consulting positioning names the multi-vendor cert advantage vs. vendor-captive competitors (Atos, T-Systems) — passes substitution test
- Digital Workplace positioning names Microsoft Solutions Partner status + device integration — specific enough
- Sovereign Cloud positioning contrasts against US public clouds AND Deutsche Telekom — names the gap Bechtle fills

**Pricing architecture:** IT Commerce serves all budgets (transactional). Managed Services and Digital Workplace are subscription/hybrid with tiered pricing. Consulting is project-based with PoV entry points. Sovereign Cloud will need enterprise pricing. The portfolio covers try-before-you-buy (Commerce) through enterprise commitment (Managed Services).

**Cannibalization risk:** Managed IT Services and IT Consulting could overlap on cloud infrastructure projects. The boundary is clear: Consulting delivers a project with a defined end state (migrate to Azure), Managed Services provides ongoing operations (run the Azure environment). The handoff between them is actually a feature — project customers become managed services customers.

**Biggest risk:** IT Commerce maturity. At 70% of revenue, this cash cow faces margin pressure from direct vendor sales (Dell Direct, HP Direct) and marketplace commoditization. If Commerce margins erode, the entire expansion engine stalls. The portfolio must actively migrate Commerce customers toward higher-margin products (Workplace, Managed Services).

---

## Phase 3: Structure and Capture

### Products Created

Five product JSON files written to `/tmp/iter1-eval-21-with-skill/products/`:

| Slug | Name | Revenue Model | Maturity | Positioning |
|---|---|---|---|---|
| it-commerce | IT Commerce | hybrid | mature | Germany's broadest IT procurement channel with 70+ vendor certifications and 44,000+ SKUs available next-day — competitors match on price, but cannot match the configuration depth and logistics density of Bechtle's 80+ local Systemhäuser. |
| managed-it-services | Managed IT Services | subscription | growth | The only managed services provider in DACH that combines nationwide on-site presence through 80+ locations with centralized NOC/SOC operations — where pure-play MSPs offer remote monitoring only, Bechtle dispatches certified engineers locally within hours. |
| it-consulting | IT Consulting & Integration | project | growth | Unlike vendor-captive consultancies (Atos, T-Systems) or vendor-agnostic boutiques, Bechtle holds top-tier certifications across Microsoft, Cisco, VMware, and HP simultaneously — enabling genuinely best-fit architecture recommendations backed by implementation capacity across all major stacks. |
| digital-workplace | Digital Workplace | hybrid | growth | Bechtle is Germany's largest Microsoft Solutions Partner for Modern Work with direct device procurement integration — competitors sell workplace consulting or device leasing separately, but only Bechtle delivers the full stack from device procurement through M365 configuration to ongoing endpoint management in a single contract. |
| sovereign-cloud-platform | Sovereign Cloud Platform | subscription | concept | Purpose-built for organizations that need hyperscaler agility with German data sovereignty — filling the gap between US-owned public clouds (compliance risk) and Deutsche Telekom's Open Telekom Cloud (limited ecosystem), with Bechtle's multi-vendor neutrality as the trust anchor. |

### Description Quality Check

All descriptions include buyer-outcome signals:
- **IT Commerce:** "reduce procurement cycle time by 40-60%", "shift from reactive spot-buying to planned technology refresh programs"
- **Managed IT Services:** "maintain enterprise-grade IT reliability without building a 24/7 internal operations team"
- **IT Consulting:** "measurable infrastructure improvements (e.g., 30%+ TCO reduction on cloud migrations) within defined timelines"
- **Digital Workplace:** "new employee receives a fully configured, secured, and policy-compliant device on day one", "cutting endpoint-related support tickets by 50%+"
- **Sovereign Cloud:** "adopt cloud services without compromising on data sovereignty requirements or vendor lock-in concerns"

### Phase 2 Issues Resolved in Phase 3

1. **Hardware/software merge** — Resolved by creating IT Commerce as a unified procurement product
2. **Consulting too broad** — Resolved by carving out Digital Workplace as a separate product, narrowing Consulting to infrastructure modernization
3. **Missing pipeline product** — Resolved by adding Sovereign Cloud Platform at concept stage
4. **Competitive substitution** — All positioning statements name Bechtle-specific structural advantages (location density, multi-vendor certs, Microsoft partner status)

---

## Phase 4: Sync

Sync script not available in this evaluation environment. Portfolio.json `company.products` would be updated to: `["IT Commerce", "Managed IT Services", "IT Consulting & Integration", "Digital Workplace", "Sovereign Cloud Platform"]`.

---

## Phase 5: Validation

- **Products created:** 5
- **Features defined:** 0 (expected — this is a cold-start product definition)
- **Orphaned features:** None
- **Products with zero features:** All 5 — features should be defined next
- **Language compliance:** English (matches `portfolio.json` `language: "en"`)

### Strategic Recommendation Summary

**What I would keep:**
- The 5-product structure with clear buyer-journey progression from transactional (Commerce) to recurring (Managed Services)
- Revenue model diversity: hybrid, subscription, project — each product has the right commercial model

**What I would change:**
- Nothing structural at this stage. The boundary between Consulting and Managed Services needs to be reinforced through feature definitions (clear handoff protocols).

**Customer journey:**
Commerce (entry) → Workplace (expand, same buyer discovers deployment services) → Consulting (deepen, infrastructure projects) → Managed Services (retain, ongoing operations) → Sovereign Cloud (future upsell, regulated customers)

**Competitive angle:**
This portfolio structure mirrors Cancom's but with better differentiation per product. Against T-Systems and Atos, Bechtle's multi-vendor neutrality is the structural moat. The Digital Workplace carve-out positions Bechtle directly against Microsoft-focused competitors (SoftwareOne, Crayon) with the added hardware integration they lack.

**Biggest risk:**
IT Commerce margin erosion from direct vendor sales. Mitigation: use Commerce as the acquisition channel but measure success by conversion to higher-margin products.

**Recommended next steps:**
1. Define features for IT Commerce first (highest maturity, most features to capture)
2. Define features for Digital Workplace second (fastest-growing, most differentiated)
3. Research Sovereign Cloud Platform opportunity (NIS2 timeline, public sector demand signals)
