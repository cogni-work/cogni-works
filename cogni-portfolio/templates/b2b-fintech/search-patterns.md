# B2B Fintech Search Patterns

Search queries for discovering fintech platform capabilities across the 8-dimension taxonomy. Used by the `scan` skill and `portfolio-web-researcher` agent.

## Phase 1: Company Discovery

Search for the target company and its product suite:

```text
WebSearch: "{company name}" "fintech" OR "payments" OR "banking platform" OR "financial technology" products pricing
WebSearch: "{company name}" subsidiaries brands products "platform" OR "suite" OR "licenses"
WebSearch: "{company name}" "acquired" OR "acquisition" products integrations
WebSearch: "{company name}" "developer platform" OR "API" OR "marketplace" OR "partner portal"
```

**Extract:**

- Primary product name(s) and web domain(s)
- Product suite / portfolio of distinct fintech products
- Acquired products now integrated into the platform
- Developer/partner ecosystem sites (developers.{domain}, docs.{domain})
- Regulated entity names and license types (EMI, PI, banking license)

## Phase 2: Provider Profile Discovery (Dimension 0)

Include the current year in Financial Scale and Workforce searches.

```text
WebSearch: site:{domain} "revenue" OR "ARR" OR "TPV" OR "total payment volume" {current year}
WebSearch: site:{domain} "employees" OR "team" OR "workforce" {current year}
WebSearch: site:{domain} "headquarters" OR "offices" OR "locations" OR "data centers"
WebSearch: "{company name}" "Gartner Magic Quadrant" OR "Forrester Wave" OR "IDC MarketScape" {current year}
WebSearch: site:{domain} "PCI DSS" OR "SOC 2" OR "ISO 27001" OR "EMI" OR "FCA" OR "MAS" OR "FinCEN"
WebSearch: site:{domain} "partners" OR "Visa" OR "Mastercard" OR "banking partner" OR "ecosystem"
```

**Map findings to Dimension 0 categories:**

| Category | Search Focus |
|----------|--------------|
| 0.1 Financial Scale | ARR, total revenue, TPV, funding rounds, valuation, growth rate |
| 0.2 Workforce Capacity | Employee count, engineering headcount, regional distribution |
| 0.3 Geographic Presence | HQ, offices, data center regions, licensed jurisdictions |
| 0.4 Market Position | Analyst ratings, market share, industry rankings, reference clients |
| 0.5 Certifications & Accreditations | PCI DSS, SOC 2, ISO 27001, PSD2, EMI/PI licenses, regulatory registrations |
| 0.6 Partnership Ecosystem | Card networks, banking partners, SI partnerships, technology alliances |

## Phase 3: Platform Portfolio Discovery (Dimensions 1-7)

For each category, execute TWO site-scoped searches per domain (THREE when LANGUAGE=de):

1. **Marketing search (EN):** Standard category terms on primary domain
2. **Product docs search:** Feature names/synonyms on docs subdomain
3. **Marketing search (DE):** German category terms on primary domain (LANGUAGE=de only)

```text
# Pattern for each category:
Search 1 (Marketing EN): site:{{DOMAIN}} {standard_terms}
Search 2 (Product Docs):  site:docs.{{DOMAIN}} OR site:help.{{DOMAIN}} {feature_synonyms}
Search 3 (Marketing DE):  site:{{DOMAIN}} {german_terms}  # Only when LANGUAGE=de
```

### 1. Payment Services

```text
# 1.1 Card Processing
WebSearch: site:{domain} "card processing" OR "card acquiring" OR "card issuing" OR "tokenization" OR "3DS"
WebSearch: site:docs.{domain} "card payments" OR "PCI vault" OR "BIN" OR "authorization" OR "capture"

# 1.2 Digital Wallets
WebSearch: site:{domain} "Apple Pay" OR "Google Pay" OR "digital wallet" OR "PayPal" OR "wallet"
WebSearch: site:docs.{domain} "wallet integration" OR "mobile wallet" OR "NFC" OR "QR code payments"

# 1.3 Cross-Border Payments
WebSearch: site:{domain} "cross-border" OR "international payments" OR "multi-currency" OR "FX" OR "foreign exchange"
WebSearch: site:docs.{domain} "currency conversion" OR "SWIFT" OR "SEPA" OR "correspondent banking" OR "local rails"

# 1.4 Real-Time Payments
WebSearch: site:{domain} "real-time payments" OR "instant payments" OR "Faster Payments" OR "SEPA Instant" OR "FedNow"
WebSearch: site:docs.{domain} "instant transfer" OR "real-time" OR "UPI" OR "request to pay" OR "immediate settlement"

# 1.5 Merchant Acquiring
WebSearch: site:{domain} "merchant" OR "acquiring" OR "payment gateway" OR "POS" OR "PayFac" OR "payment facilitator"
WebSearch: site:docs.{domain} "merchant onboarding" OR "checkout" OR "terminal" OR "in-store payments"

# 1.6 Payment Orchestration
WebSearch: site:{domain} "orchestration" OR "smart routing" OR "failover" OR "multi-PSP" OR "payment optimization"
WebSearch: site:docs.{domain} "routing rules" OR "retry logic" OR "network tokenization" OR "cascading"

# 1.7 Billing & Invoicing
WebSearch: site:{domain} "billing" OR "invoicing" OR "subscription" OR "recurring" OR "dunning"
WebSearch: site:docs.{domain} "subscription management" OR "recurring billing" OR "revenue recovery" OR "proration"
```

### 2. Banking & Lending Platform

```text
# 2.1 Core Banking Platform
WebSearch: site:{domain} "core banking" OR "banking platform" OR "ledger" OR "transaction processing"
WebSearch: site:docs.{domain} "account ledger" OR "general ledger" OR "multi-currency accounts" OR "interest calculation"

# 2.2 Lending Origination
WebSearch: site:{domain} "lending" OR "loan origination" OR "credit" OR "loan management"
WebSearch: site:docs.{domain} "loan application" OR "credit decisioning" OR "disbursement" OR "underwriting"

# 2.3 Deposit Management
WebSearch: site:{domain} "deposits" OR "savings" OR "term deposit" OR "interest rate"
WebSearch: site:docs.{domain} "deposit products" OR "savings accounts" OR "sweep accounts" OR "interest management"

# 2.4 Account Management
WebSearch: site:{domain} "account opening" OR "onboarding" OR "account management" OR "KYB"
WebSearch: site:docs.{domain} "customer onboarding" OR "account lifecycle" OR "multi-entity" OR "beneficiary management"

# 2.5 Open Banking & API
WebSearch: site:{domain} "open banking" OR "PSD2" OR "account aggregation" OR "open finance"
WebSearch: site:docs.{domain} "AISP" OR "PISP" OR "consent management" OR "TPP" OR "account information"

# 2.6 Banking-as-a-Service
WebSearch: site:{domain} "banking-as-a-service" OR "BaaS" OR "embedded banking" OR "white-label banking"
WebSearch: site:docs.{domain} "sponsor bank" OR "ledger-as-a-service" OR "embedded accounts" OR "banking API"
```

### 3. Risk & Compliance

```text
# 3.1 KYC/AML
WebSearch: site:{domain} "KYC" OR "AML" OR "identity verification" OR "know your customer" OR "anti-money laundering"
WebSearch: site:docs.{domain} "document verification" OR "PEP screening" OR "beneficial ownership" OR "ongoing monitoring"

# 3.2 Fraud Detection
WebSearch: site:{domain} "fraud" OR "fraud detection" OR "fraud prevention" OR "chargeback"
WebSearch: site:docs.{domain} "fraud scoring" OR "behavioral analytics" OR "device fingerprinting" OR "risk rules"

# 3.3 Credit Scoring
WebSearch: site:{domain} "credit scoring" OR "credit risk" OR "risk assessment" OR "affordability"
WebSearch: site:docs.{domain} "credit bureau" OR "alternative data" OR "risk model" OR "credit decisioning"

# 3.4 Regulatory Reporting
WebSearch: site:{domain} "regulatory reporting" OR "compliance reporting" OR "SAR" OR "STR"
WebSearch: site:docs.{domain} "COREP" OR "FINREP" OR "MiFID" OR "EMIR" OR "automated filing"

# 3.5 Transaction Monitoring
WebSearch: site:{domain} "transaction monitoring" OR "AML monitoring" OR "suspicious activity"
WebSearch: site:docs.{domain} "rule engine" OR "alert management" OR "case management" OR "screening"

# 3.6 Sanctions Screening
WebSearch: site:{domain} "sanctions" OR "sanctions screening" OR "embargo" OR "watchlist"
WebSearch: site:docs.{domain} "sanctions list" OR "OFAC" OR "EU sanctions" OR "adverse media" OR "real-time screening"
```

### 4. Capital Markets & Trading

```text
# 4.1 Trading Platforms
WebSearch: site:{domain} "trading platform" OR "execution" OR "multi-asset" OR "equities" OR "FX trading"
WebSearch: site:docs.{domain} "trading" OR "DMA" OR "execution management" OR "OTC" OR "exchange connectivity"

# 4.2 Order Management
WebSearch: site:{domain} "order management" OR "OMS" OR "order routing" OR "FIX"
WebSearch: site:docs.{domain} "order lifecycle" OR "smart order routing" OR "FIX protocol" OR "execution report"

# 4.3 Market Data
WebSearch: site:{domain} "market data" OR "real-time data" OR "pricing" OR "reference data"
WebSearch: site:docs.{domain} "market feed" OR "historical data" OR "index calculation" OR "pricing engine"

# 4.4 Portfolio Management
WebSearch: site:{domain} "portfolio management" OR "wealth management" OR "rebalancing" OR "model portfolio"
WebSearch: site:docs.{domain} "portfolio construction" OR "performance attribution" OR "risk analytics" OR "asset allocation"

# 4.5 Clearing & Settlement
WebSearch: site:{domain} "clearing" OR "settlement" OR "post-trade" OR "reconciliation"
WebSearch: site:docs.{domain} "CCP" OR "settlement workflow" OR "corporate actions" OR "netting"

# 4.6 Algorithmic Trading
WebSearch: site:{domain} "algorithmic trading" OR "algo" OR "quantitative" OR "systematic trading"
WebSearch: site:docs.{domain} "backtesting" OR "execution algorithm" OR "latency" OR "VWAP" OR "TWAP"
```

### 5. Insurance Technology

```text
# 5.1 Policy Administration
WebSearch: site:{domain} "policy administration" OR "policy management" OR "insurance platform"
WebSearch: site:docs.{domain} "policy lifecycle" OR "endorsement" OR "renewal" OR "product configuration"

# 5.2 Claims Management
WebSearch: site:{domain} "claims" OR "claims management" OR "FNOL" OR "claims processing"
WebSearch: site:docs.{domain} "claims workflow" OR "adjudication" OR "subrogation" OR "claims automation"

# 5.3 Underwriting Automation
WebSearch: site:{domain} "underwriting" OR "risk assessment" OR "automated underwriting"
WebSearch: site:docs.{domain} "underwriting rules" OR "pricing model" OR "quote engine" OR "risk selection"

# 5.4 Distribution Platforms
WebSearch: site:{domain} "insurance distribution" OR "broker portal" OR "agent" OR "comparison"
WebSearch: site:docs.{domain} "embedded insurance" OR "insurance API" OR "digital distribution" OR "aggregator"

# 5.5 Actuarial Analytics
WebSearch: site:{domain} "actuarial" OR "loss reserving" OR "capital modeling" OR "IFRS 17"
WebSearch: site:docs.{domain} "actuarial model" OR "pricing analytics" OR "experience analysis" OR "Solvency II"
```

### 6. Data & Intelligence

```text
# 6.1 Financial Analytics
WebSearch: site:{domain} "analytics" OR "financial analytics" OR "transaction analytics" OR "revenue analytics"
WebSearch: site:docs.{domain} "cohort analysis" OR "performance dashboard" OR "financial reporting"

# 6.2 Embedded Finance APIs
WebSearch: site:{domain} "embedded finance" OR "financial API" OR "banking API" OR "payments API"
WebSearch: site:docs.{domain} "embedded" OR "plug-and-play" OR "financial services API" OR "platform integration"

# 6.3 AI/ML for Financial Services
WebSearch: site:{domain} "AI" OR "machine learning" OR "artificial intelligence" OR "robo-advisory"
WebSearch: site:docs.{domain} "ML model" OR "predictive" OR "NLP" OR "document intelligence" OR "conversational"

# 6.4 Data Aggregation
WebSearch: site:{domain} "data aggregation" OR "account aggregation" OR "open banking data" OR "financial data"
WebSearch: site:docs.{domain} "data enrichment" OR "categorization" OR "data normalization" OR "transaction enrichment"

# 6.5 Reporting & Dashboards
WebSearch: site:{domain} "reporting" OR "dashboards" OR "business intelligence" OR "operational reporting"
WebSearch: site:docs.{domain} "management reporting" OR "regulatory dashboard" OR "self-service BI" OR "custom reports"

# 6.6 Customer Insights
WebSearch: site:{domain} "customer insights" OR "segmentation" OR "behavioral analytics" OR "lifetime value"
WebSearch: site:docs.{domain} "churn prediction" OR "customer analytics" OR "CLV" OR "personalization"
```

### 7. Advisory & Implementation

```text
# 7.1 Regulatory Consulting
WebSearch: site:{domain} "regulatory consulting" OR "licensing" OR "compliance advisory" OR "regulatory"
WebSearch: site:docs.{domain} "compliance program" OR "regulatory change" OR "audit preparation" OR "licensing advisory"

# 7.2 Technology Implementation
WebSearch: site:{domain} "implementation" OR "integration services" OR "migration" OR "go-live"
WebSearch: site:docs.{domain} "implementation guide" OR "data migration" OR "configuration" OR "onboarding"

# 7.3 Digital Transformation
WebSearch: site:{domain} "digital transformation" OR "modernization" OR "cloud migration" OR "legacy"
WebSearch: site:docs.{domain} "core modernization" OR "digital strategy" OR "operating model" OR "cloud-native"

# 7.4 Program Management
WebSearch: site:{domain} "program management" OR "PMO" OR "delivery" OR "vendor management"
WebSearch: site:docs.{domain} "project delivery" OR "agile transformation" OR "multi-workstream"

# 7.5 Managed Operations
WebSearch: site:{domain} "managed services" OR "outsourcing" OR "BPO" OR "managed operations"
WebSearch: site:docs.{domain} "managed compliance" OR "payment operations" OR "NOC" OR "SOC services"

# 7.6 Training & Certification
WebSearch: site:{domain} "training" OR "certification" OR "academy" OR "learning"
WebSearch: site:docs.{domain} "certification program" OR "developer academy" OR "partner enablement" OR "regulatory training"
```

## Phase 4: Competitor & Analyst Discovery

```text
WebSearch: "{company name}" vs OR versus OR alternative OR competitor "payments" OR "banking" OR "fintech"
WebSearch: "{company name}" "Gartner" OR "Forrester" OR "IDC" review {current year}
WebSearch: "{company name}" case study OR customer story OR testimonial "bank" OR "payment" OR "insurance"
```
