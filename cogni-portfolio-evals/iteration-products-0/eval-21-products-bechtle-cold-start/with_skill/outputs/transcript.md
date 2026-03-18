# Product Portfolio Consulting Transcript — Bechtle AG (Cold Start)

## Phase 1: Strategic Discovery

**Portfolio state**: Empty — zero products, zero features. Complete cold start.

**Company context from portfolio.json**:
- Bechtle AG, 15,000 employees, ICT Services industry
- Domain: bechtle.com, Country: DE
- Taxonomy: b2b-ict
- Language: English

**User input**: Bechtle is Germany's largest IT reseller and system integrator. They sell hardware, software licensing, managed services, and IT consulting.

**Discovery findings**:
- Four distinct revenue streams with fundamentally different business economics
- Resale business (hardware, software) operates on volume and margin
- Services business (managed services, consulting) operates on people and recurring contracts
- No existing product definitions to inherit or migrate

## Phase 2: Portfolio Shaping — Strategic Recommendation

### Anti-Patterns Identified

1. **Services vs. resell tension**: Hardware/software resale scales with volume and logistics efficiency. Consulting scales with headcount. Managed services scales with automation and customer base. Treating these as one business obscures portfolio economics and confuses go-to-market messaging.

2. **Missing entry-point clarity**: A mid-market customer buying a laptop fleet enters through procurement. An enterprise CIO evaluating cloud migration enters through consulting. These are different buyer journeys that need different product entry points.

3. **No pipeline product**: All four revenue streams are established and mature/growth. The question Bechtle should be asking: what's the next act? Likely candidates include security-as-a-service, AI/digital workplace, or sustainability/green IT — but these would emerge as features or sub-products, not as standalone products today.

### Recommended Product Structure

I proposed **4 products** organized by how customers buy and how Bechtle delivers:

| # | Product | Revenue Model | Maturity | Rationale |
|---|---------|---------------|----------|-----------|
| 1 | IT Supply & Lifecycle | hybrid | mature | Core resale business + lifecycle services. Hybrid because it combines transactional hardware sales with recurring lifecycle/leasing contracts. Mature — this is Bechtle's heritage business. |
| 2 | Software & Cloud Licensing | hybrid | growth | License procurement + cloud subscription brokerage. Hybrid because it mixes one-time license sales with ongoing cloud spend optimization advisory. Growth — cloud migration is driving expansion. |
| 3 | Managed Services | subscription | growth | Recurring IT operations under SLAs. Pure subscription model. Growth — this is Bechtle's margin expansion play as they shift from resale to recurring revenue. |
| 4 | IT Consulting | project | growth | Project-based advisory and implementation. Classic project revenue model. Growth — digital transformation demand continues to expand the addressable market. |

### Strategic Commentary

**What I would keep**: The 4-product structure maps cleanly to how Bechtle actually delivers and how customers actually buy. Each product passes the "would a customer evaluate this independently?" test. A customer buying laptops is not the same buyer as one commissioning a cloud migration strategy.

**What I would watch**: The boundary between IT Consulting and Managed Services needs discipline. Consulting engagements often lead to managed services contracts (design then operate). This is a strength — it creates a natural land-and-expand motion — but only if the handoff is intentional, not accidental.

**Customer journey**: The typical Bechtle journey is: (1) Enter through IT Supply (hardware procurement — low risk, transactional), (2) Expand to Software & Cloud Licensing (license optimization creates advisory relationship), (3) Deepen with IT Consulting (strategic projects build trust), (4) Lock in with Managed Services (recurring operations create stickiness). This land-and-expand path is Bechtle's core commercial engine.

**Competitive angle**: Competitors like Computacenter, Cancom, and SHI sell similar portfolios. Bechtle's structural advantage is scale in Germany (70+ locations) and the ability to bundle all four products. The portfolio structure should enable bundled deals without forcing them — each product must stand alone but play well together.

**Biggest risk**: The resale business (IT Supply + Software Licensing) is under secular pressure from direct-to-customer cloud models. If Bechtle doesn't aggressively grow Managed Services and Consulting as a percentage of revenue, they risk becoming a low-margin logistics company. The product portfolio structure supports this transition, but the strategy must follow.

**Recommended next steps**:
1. Define features for Managed Services first — this is the growth engine and where differentiation matters most
2. Define features for IT Consulting second — this is the value-creation engine
3. IT Supply and Software Licensing features can follow — they're mature and well-understood

## Phase 3: Structure and Capture

Four product JSON files created in `/tmp/eval-21-with-skill/products/`:
- `it-supply-lifecycle.json`
- `software-cloud-licensing.json`
- `managed-services.json`
- `it-consulting.json`

### Portfolio Review Table

| Slug | Name | Revenue Model | Maturity | Positioning |
|------|------|---------------|----------|-------------|
| it-supply-lifecycle | IT Supply & Lifecycle | hybrid | mature | Germany's largest IT procurement partner with nationwide logistics, configuration centers, and lifecycle services |
| software-cloud-licensing | Software & Cloud Licensing | hybrid | growth | Vendor-neutral licensing advisory that optimizes spend across on-premise and cloud |
| managed-services | Managed Services | subscription | growth | Enterprise-grade managed IT operations with German data sovereignty and predictable monthly costs |
| it-consulting | IT Consulting | project | growth | Hands-on IT consulting that bridges strategy and execution |

## Phase 4: Sync portfolio.json

Ran `sync-portfolio.sh` — portfolio.json updated with all 4 product slugs in `company.products` and `updated` timestamp set to `2026-03-18`.

## Phase 5: Validation

- **Features per product**: All 4 products have 0 features (expected — cold start)
- **Orphaned features**: None (no features exist)
- **Overlap detection**: No near-identical product descriptions — each product addresses a distinct delivery model
- **Coverage gaps**: All products need features defined as next step
- **Cross-reference**: No downstream entities (propositions, solutions, competitors) exist yet — all depend on features being defined first
