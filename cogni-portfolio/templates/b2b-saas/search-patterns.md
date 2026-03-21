# B2B SaaS Search Patterns

Search queries for discovering SaaS platform capabilities across the 8-dimension taxonomy. Used by the `scan` skill and `portfolio-web-researcher` agent.

## Phase 1: Company Discovery

Search for the target company and its product suite:

```text
WebSearch: "{company name}" "SaaS" OR "cloud platform" OR "enterprise software" products pricing
WebSearch: "{company name}" subsidiaries brands products "platform" OR "suite"
WebSearch: "{company name}" "acquired" OR "acquisition" products integrations
WebSearch: "{company name}" "developer platform" OR "API" OR "marketplace" OR "app store"
```

**Extract:**

- Primary product name(s) and web domain(s)
- Product suite / portfolio of distinct SaaS products
- Acquired products now integrated into the platform
- Developer/partner ecosystem sites (developers.{domain}, marketplace.{domain})

## Phase 2: Provider Profile Discovery (Dimension 0)

Include the current year in Financial Scale and Workforce searches.

```text
WebSearch: site:{domain} "ARR" OR "annual recurring revenue" OR "revenue" {current year}
WebSearch: site:{domain} "employees" OR "team" OR "workforce" {current year}
WebSearch: site:{domain} "headquarters" OR "offices" OR "locations" OR "data centers"
WebSearch: "{company name}" "Gartner Magic Quadrant" OR "Forrester Wave" OR "G2" {current year}
WebSearch: site:{domain} "SOC 2" OR "ISO 27001" OR "HIPAA" OR "FedRAMP" OR "GDPR"
WebSearch: site:{domain} "partners" OR "alliances" OR "integrations" OR "ecosystem"
```

**Map findings to Dimension 0 categories:**

| Category | Search Focus |
|----------|--------------|
| 0.1 Financial Scale | ARR, total revenue, funding rounds, valuation, growth rate |
| 0.2 Workforce Capacity | Employee count, engineering headcount, regional distribution |
| 0.3 Geographic Presence | HQ, offices, data center regions, service countries |
| 0.4 Market Position | Analyst ratings, G2/Capterra reviews, market share, reference clients |
| 0.5 Certifications & Accreditations | SOC 2, ISO 27001, HIPAA, FedRAMP, GDPR certifications |
| 0.6 Partnership Ecosystem | SI partners, technology alliances, channel programs |

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

### 1. Core Platform

```text
# 1.1 Product Editions
WebSearch: site:{domain} "pricing" OR "plans" OR "editions" OR "tiers" "starter" OR "professional" OR "enterprise"
WebSearch: site:docs.{domain} "plan comparison" OR "feature comparison" OR "edition differences"

# 1.2 Multi-Tenancy & Architecture
WebSearch: site:{domain} "architecture" OR "multi-tenant" OR "scalability" OR "infrastructure"
WebSearch: site:docs.{domain} "tenant isolation" OR "data separation" OR "dedicated instance"

# 1.3 Platform API
WebSearch: site:{domain} "API" OR "REST" OR "GraphQL" OR "developer portal"
WebSearch: site:docs.{domain} OR site:developers.{domain} "API reference" OR "rate limits" OR "authentication"

# 1.4 Extensibility Framework
WebSearch: site:{domain} "customization" OR "extensibility" OR "workflows" OR "automation"
WebSearch: site:docs.{domain} "custom objects" OR "scripting" OR "formula fields" OR "custom components"

# 1.5 Mobile Platform
WebSearch: site:{domain} "mobile app" OR "mobile SDK" OR "iOS" OR "Android"
WebSearch: site:docs.{domain} "mobile" OR "responsive" OR "native app"

# 1.6 Offline Capabilities
WebSearch: site:{domain} "offline" OR "offline access" OR "sync"
WebSearch: site:docs.{domain} "offline mode" OR "data sync" OR "conflict resolution"

# 1.7 White-Label & OEM
WebSearch: site:{domain} "white label" OR "OEM" OR "embedded" OR "reseller" OR "partner platform"
WebSearch: site:docs.{domain} "branding" OR "custom domain" OR "embedded SDK"
```

### 2. Data & Analytics

```text
# 2.1 Reporting & Dashboards
WebSearch: site:{domain} "reporting" OR "dashboards" OR "analytics" OR "reports"

# 2.2 Embedded Analytics
WebSearch: site:{domain} "embedded analytics" OR "data visualization" OR "drill-down"

# 2.3 Data Warehouse & Lake
WebSearch: site:{domain} "data warehouse" OR "data lake" OR "historical data" OR "data retention"

# 2.4 AI & ML Capabilities
WebSearch: site:{domain} "AI" OR "machine learning" OR "predictive" OR "generative AI" OR "copilot"

# 2.5 Data Import & Export
WebSearch: site:{domain} "import" OR "export" OR "data migration" OR "CSV" OR "bulk"

# 2.6 Real-Time Processing
WebSearch: site:{domain} "real-time" OR "streaming" OR "live data" OR "webhooks" OR "CDC"
```

### 3. Integration & Ecosystem

```text
# 3.1 Native Integrations
WebSearch: site:{domain} "integrations" OR "connectors" OR "Salesforce" OR "SAP" OR "Slack"

# 3.2 Marketplace & App Store
WebSearch: site:{domain} OR site:marketplace.{domain} "marketplace" OR "app store" OR "extensions"

# 3.3 API Management
WebSearch: site:{domain} "API management" OR "API gateway" OR "rate limiting" OR "OAuth"

# 3.4 iPaaS Connectors
WebSearch: site:{domain} "Zapier" OR "Workato" OR "MuleSoft" OR "Tray.io" OR "Make"

# 3.5 Webhook & Event Framework
WebSearch: site:docs.{domain} "webhooks" OR "events" OR "pub/sub" OR "triggers"

# 3.6 Developer Tools & SDKs
WebSearch: site:{domain} OR site:developers.{domain} "SDK" OR "CLI" OR "sandbox" OR "developer tools"
```

### 4. Security & Compliance

```text
# 4.1 Authentication & SSO
WebSearch: site:{domain} "SSO" OR "SAML" OR "OIDC" OR "MFA" OR "SCIM"

# 4.2 Role-Based Access Control
WebSearch: site:{domain} "RBAC" OR "roles" OR "permissions" OR "access control"

# 4.3 Data Encryption
WebSearch: site:{domain} "encryption" OR "BYOK" OR "key management" OR "TLS"

# 4.4 Compliance Certifications
WebSearch: site:{domain} "compliance" OR "SOC 2" OR "ISO 27001" OR "HIPAA" OR "FedRAMP" OR "trust center"

# 4.5 Audit Logging
WebSearch: site:{domain} "audit log" OR "activity log" OR "change tracking"

# 4.6 Data Residency & Sovereignty
WebSearch: site:{domain} "data residency" OR "data sovereignty" OR "EU hosting" OR "region selection"
```

### 5. Customer Success & Support

```text
# 5.1 Onboarding Services
WebSearch: site:{domain} "onboarding" OR "implementation" OR "getting started" OR "setup"

# 5.2 Training & Certification
WebSearch: site:{domain} "training" OR "certification" OR "academy" OR "learning"

# 5.3 Technical Support Tiers
WebSearch: site:{domain} "support" OR "support plans" OR "SLA" OR "24/7"

# 5.4 Customer Success Management
WebSearch: site:{domain} "customer success" OR "CSM" OR "account management"

# 5.5 Professional Services
WebSearch: site:{domain} "professional services" OR "consulting" OR "solution architecture"

# 5.6 Community & Knowledge Base
WebSearch: site:{domain} OR site:community.{domain} "community" OR "forum" OR "knowledge base" OR "user group"
```

### 6. Pricing & Packaging

```text
# 6.1 Subscription Tiers
WebSearch: site:{domain} "pricing" OR "plans" OR "per user" OR "per seat" OR "monthly" OR "annual"

# 6.2 Usage-Based Pricing
WebSearch: site:{domain} "usage-based" OR "consumption" OR "pay-as-you-go" OR "metered"

# 6.3 Enterprise Licensing
WebSearch: site:{domain} "enterprise" OR "custom pricing" OR "volume discount" OR "contact sales"

# 6.4 Add-On Modules
WebSearch: site:{domain} "add-on" OR "premium" OR "advanced" OR "optional module"

# 6.5 Free Tier & Freemium
WebSearch: site:{domain} "free" OR "free plan" OR "trial" OR "developer edition" OR "sandbox"

# 6.6 Partner & Reseller Pricing
WebSearch: site:{domain} "partner program" OR "reseller" OR "channel" OR "referral" OR "MSP"
```

### 7. Industry Solutions

```text
# 7.1 Healthcare & Life Sciences
WebSearch: site:{domain} "healthcare" OR "HIPAA" OR "clinical" OR "life sciences" OR "pharma"

# 7.2 Financial Services
WebSearch: site:{domain} "financial services" OR "banking" OR "insurance" OR "fintech"

# 7.3 Retail & Commerce
WebSearch: site:{domain} "retail" OR "e-commerce" OR "commerce" OR "POS" OR "inventory"

# 7.4 Manufacturing & Industrial
WebSearch: site:{domain} "manufacturing" OR "supply chain" OR "industrial" OR "IoT"
```

## Phase 4: Competitor & Analyst Discovery

```text
WebSearch: "{company name}" vs OR versus OR alternative OR competitor
WebSearch: "{company name}" "Gartner" OR "Forrester" OR "IDC" review {current year}
WebSearch: "{company name}" case study OR customer story OR testimonial
```
