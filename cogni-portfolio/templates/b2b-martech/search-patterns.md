# B2B MarTech Search Patterns

Search queries for discovering MarTech platform capabilities across the 8-dimension taxonomy. Used by the `scan` skill and `portfolio-web-researcher` agent.

## Phase 1: Company Discovery

Search for the target company and its product suite:

```text
WebSearch: "{company name}" "MarTech" OR "marketing technology" OR "marketing platform" OR "advertising technology" products pricing
WebSearch: "{company name}" subsidiaries brands products "platform" OR "suite" OR "cloud"
WebSearch: "{company name}" "acquired" OR "acquisition" products integrations
WebSearch: "{company name}" "developer platform" OR "API" OR "marketplace" OR "exchange"
```

**Extract:**

- Primary product name(s) and web domain(s)
- Product suite / portfolio of distinct MarTech products
- Acquired products now integrated into the platform
- Developer/partner ecosystem sites (developers.{domain}, exchange.{domain})

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

### 1. Customer Data & Identity

```text
# 1.1 Customer Data Platform (CDP)
WebSearch: site:{domain} "CDP" OR "customer data platform" OR "unified profile" OR "data unification"
WebSearch: site:docs.{domain} "customer profile" OR "data ingestion" OR "identity stitching" OR "activation"

# 1.2 Identity Resolution
WebSearch: site:{domain} "identity resolution" OR "identity graph" OR "cross-device" OR "deterministic matching"
WebSearch: site:docs.{domain} "identity" OR "device graph" OR "probabilistic" OR "first-party ID"

# 1.3 Audience Segmentation
WebSearch: site:{domain} "segmentation" OR "audience builder" OR "lookalike" OR "audience activation"
WebSearch: site:docs.{domain} "segments" OR "audience" OR "targeting" OR "cohort"

# 1.4 Data Enrichment
WebSearch: site:{domain} "data enrichment" OR "intent data" OR "firmographic" OR "technographic" OR "third-party data"
WebSearch: site:docs.{domain} "enrichment" OR "data append" OR "behavioral scoring"

# 1.5 Consent & Preference Management
WebSearch: site:{domain} "consent management" OR "preference center" OR "opt-in" OR "opt-out" OR "consent"
WebSearch: site:docs.{domain} "consent" OR "preference" OR "subscription management"

# 1.6 Data Clean Rooms
WebSearch: site:{domain} "clean room" OR "data collaboration" OR "privacy-safe" OR "secure matching"
WebSearch: site:docs.{domain} "clean room" OR "data sharing" OR "aggregate insights"
```

### 2. Campaign & Marketing Automation

```text
# 2.1 Email Marketing
WebSearch: site:{domain} "email marketing" OR "email campaign" OR "email deliverability" OR "transactional email"
WebSearch: site:docs.{domain} "email" OR "SMTP" OR "deliverability" OR "list management"

# 2.2 Marketing Automation
WebSearch: site:{domain} "marketing automation" OR "workflow" OR "trigger" OR "landing page" OR "form builder"
WebSearch: site:docs.{domain} "automation" OR "workflow" OR "dynamic content" OR "campaign builder"

# 2.3 Journey Orchestration
WebSearch: site:{domain} "journey" OR "orchestration" OR "cross-channel" OR "next-best-action" OR "lifecycle"
WebSearch: site:docs.{domain} "journey builder" OR "decisioning" OR "real-time interaction"

# 2.4 A/B Testing & Optimization
WebSearch: site:{domain} "A/B testing" OR "multivariate" OR "optimization" OR "experimentation"
WebSearch: site:docs.{domain} "experiment" OR "variant" OR "statistical significance" OR "feature flag"

# 2.5 Lead Scoring & Nurturing
WebSearch: site:{domain} "lead scoring" OR "lead nurturing" OR "MQL" OR "SQL" OR "lead management"
WebSearch: site:docs.{domain} "scoring model" OR "nurture" OR "lead qualification"

# 2.6 Social Media Management
WebSearch: site:{domain} "social media" OR "social publishing" OR "social listening" OR "social management"
WebSearch: site:docs.{domain} "social" OR "scheduling" OR "community management" OR "influencer"
```

### 3. Content & Experience

```text
# 3.1 Content Management System (CMS)
WebSearch: site:{domain} "CMS" OR "content management" OR "headless CMS" OR "page builder" OR "web content"
WebSearch: site:docs.{domain} "content authoring" OR "templates" OR "multi-site" OR "content workflow"

# 3.2 Digital Asset Management (DAM)
WebSearch: site:{domain} "DAM" OR "digital asset management" OR "asset management" OR "media library"
WebSearch: site:docs.{domain} "assets" OR "metadata" OR "rights management" OR "asset transformation"

# 3.3 Personalization Engine
WebSearch: site:{domain} "personalization" OR "recommendations" OR "contextual targeting" OR "experience optimization"
WebSearch: site:docs.{domain} "personalize" OR "recommendation" OR "targeting rules" OR "experience"

# 3.4 Commerce Experience
WebSearch: site:{domain} "commerce" OR "storefront" OR "product catalog" OR "checkout" OR "B2B commerce"
WebSearch: site:docs.{domain} "commerce" OR "catalog" OR "shopping" OR "checkout" OR "cart"

# 3.5 Search & Discovery
WebSearch: site:{domain} "search" OR "site search" OR "product discovery" OR "faceted" OR "relevance"
WebSearch: site:docs.{domain} "search" OR "discovery" OR "merchandising" OR "autocomplete"

# 3.6 Localization
WebSearch: site:{domain} "localization" OR "translation" OR "multi-language" OR "locale" OR "internationalization"
WebSearch: site:docs.{domain} "localization" OR "translation" OR "locale" OR "i18n"
```

### 4. Advertising & Media

```text
# 4.1 Programmatic Advertising (DSP/SSP)
WebSearch: site:{domain} "programmatic" OR "DSP" OR "SSP" OR "real-time bidding" OR "RTB" OR "connected TV"
WebSearch: site:docs.{domain} "programmatic" OR "bid" OR "impression" OR "inventory" OR "deal ID"

# 4.2 Search Advertising
WebSearch: site:{domain} "search ads" OR "paid search" OR "SEM" OR "Google Ads" OR "keyword bidding"
WebSearch: site:docs.{domain} "search campaign" OR "keyword" OR "shopping ads" OR "bid strategy"

# 4.3 Social Advertising
WebSearch: site:{domain} "social ads" OR "paid social" OR "Facebook ads" OR "Instagram ads" OR "TikTok ads"
WebSearch: site:docs.{domain} "social campaign" OR "social targeting" OR "creative optimization"

# 4.4 Retail Media
WebSearch: site:{domain} "retail media" OR "sponsored products" OR "shopper marketing" OR "retail advertising"
WebSearch: site:docs.{domain} "retail media" OR "sponsored" OR "on-site ads" OR "off-site ads"

# 4.5 Attribution & Measurement
WebSearch: site:{domain} "attribution" OR "measurement" OR "media mix" OR "incrementality" OR "multi-touch"
WebSearch: site:docs.{domain} "attribution" OR "conversion" OR "lift" OR "ROI" OR "ROAS"

# 4.6 Media Planning & Buying
WebSearch: site:{domain} "media planning" OR "media buying" OR "insertion order" OR "budget allocation"
WebSearch: site:docs.{domain} "media plan" OR "campaign plan" OR "inventory forecast" OR "IO"
```

### 5. Analytics & Intelligence

```text
# 5.1 Marketing Analytics
WebSearch: site:{domain} "marketing analytics" OR "campaign analytics" OR "channel analytics" OR "performance dashboard"
WebSearch: site:docs.{domain} "analytics" OR "metrics" OR "KPI" OR "conversion tracking"

# 5.2 Customer Journey Analytics
WebSearch: site:{domain} "journey analytics" OR "path analysis" OR "customer journey" OR "touchpoint"
WebSearch: site:docs.{domain} "journey" OR "funnel" OR "drop-off" OR "cohort analysis"

# 5.3 AI/ML for Marketing
WebSearch: site:{domain} "AI" OR "machine learning" OR "generative AI" OR "predictive" OR "copilot" OR "GenAI"
WebSearch: site:docs.{domain} "AI" OR "model" OR "recommendation" OR "optimization" OR "generative"

# 5.4 Predictive Modeling
WebSearch: site:{domain} "predictive" OR "forecasting" OR "propensity" OR "CLV" OR "lifetime value"
WebSearch: site:docs.{domain} "prediction" OR "forecast" OR "scoring" OR "model"

# 5.5 Reporting & Dashboards
WebSearch: site:{domain} "reporting" OR "dashboards" OR "insights" OR "executive dashboard"
WebSearch: site:docs.{domain} "report" OR "dashboard" OR "export" OR "scheduled report"
```

### 6. Privacy & Compliance

```text
# 6.1 Cookie/Consent Management
WebSearch: site:{domain} "cookie" OR "consent banner" OR "TCF" OR "GPP" OR "tag management"
WebSearch: site:docs.{domain} "consent" OR "cookie" OR "tag gating" OR "scanner"

# 6.2 Data Privacy (GDPR/CCPA)
WebSearch: site:{domain} "GDPR" OR "CCPA" OR "privacy" OR "data subject" OR "right to deletion"
WebSearch: site:docs.{domain} "DSAR" OR "privacy" OR "data processing" OR "cross-border"

# 6.3 Brand Safety & Ad Verification
WebSearch: site:{domain} "brand safety" OR "ad verification" OR "viewability" OR "ad fraud" OR "IAS" OR "DoubleVerify"
WebSearch: site:docs.{domain} "brand safety" OR "verification" OR "viewability" OR "fraud detection"

# 6.4 Data Governance
WebSearch: site:{domain} "data governance" OR "data lineage" OR "data classification" OR "data quality"
WebSearch: site:docs.{domain} "governance" OR "lineage" OR "retention" OR "access control"

# 6.5 Identity Deprecation Solutions
WebSearch: site:{domain} "cookieless" OR "privacy sandbox" OR "contextual targeting" OR "universal ID" OR "first-party"
WebSearch: site:docs.{domain} "cookieless" OR "Topics API" OR "FLEDGE" OR "contextual" OR "UID2"
```

### 7. Services & Enablement

```text
# 7.1 Implementation Services
WebSearch: site:{domain} "implementation" OR "onboarding" OR "professional services" OR "go-live"
WebSearch: site:docs.{domain} "getting started" OR "setup" OR "migration" OR "configuration"

# 7.2 Strategic Consulting
WebSearch: site:{domain} "consulting" OR "strategy" OR "advisory" OR "maturity assessment"
WebSearch: site:docs.{domain} "roadmap" OR "best practices" OR "transformation"

# 7.3 Creative Services
WebSearch: site:{domain} "creative services" OR "content production" OR "design services" OR "campaign creative"
WebSearch: site:docs.{domain} "templates" OR "creative" OR "brand assets"

# 7.4 Training & Certification
WebSearch: site:{domain} "training" OR "certification" OR "academy" OR "learning" OR "university"
WebSearch: site:docs.{domain} "course" OR "certification" OR "learning path"

# 7.5 Managed Campaign Services
WebSearch: site:{domain} "managed services" OR "campaign management" OR "outsourced" OR "dedicated team"
WebSearch: site:docs.{domain} "managed" OR "full-service" OR "campaign operations"
```

## Phase 4: Competitor & Analyst Discovery

```text
WebSearch: "{company name}" vs OR versus OR alternative OR competitor "marketing technology" OR "martech"
WebSearch: "{company name}" "Gartner" OR "Forrester" OR "IDC" review {current year}
WebSearch: "{company name}" case study OR customer story OR testimonial
```
