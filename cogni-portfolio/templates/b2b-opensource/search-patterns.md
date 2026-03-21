# B2B Open-Source Search Patterns

Search queries for discovering COSS (Commercial Open Source) capabilities across the 8-dimension taxonomy. Used by the `scan` skill and `portfolio-web-researcher` agent.

## Phase 1: Company & Project Discovery

Search for the target company, its open-source projects, and commercial offerings:

```text
WebSearch: "{company name}" open source project github repository
WebSearch: "{company name}" "enterprise" OR "commercial" OR "cloud" OR "managed service"
WebSearch: "{company name}" "acquired" OR "acquisition" OR "merged" open source
WebSearch: "{company name}" "CNCF" OR "Apache Foundation" OR "Linux Foundation" OR "open source foundation"
WebSearch: github.com/{company-github-org} repositories stars
```

**Extract:**

- Primary open-source project(s) and GitHub organization
- Commercial product name(s) (often different from OSS project name)
- Foundation affiliations (CNCF, ASF, LF, etc.)
- Acquired open-source projects
- Cloud service domains (cloud.{domain}, {product}.{domain})

## Phase 2: Provider Profile Discovery (Dimension 0)

Include the current year in Financial Scale and Workforce searches.

```text
WebSearch: "{company name}" "revenue" OR "ARR" OR "funding" OR "valuation" {current year}
WebSearch: "{company name}" "employees" OR "team" OR "engineering" {current year}
WebSearch: site:{domain} "headquarters" OR "offices" OR "locations" OR "data centers"
WebSearch: "{company name}" "Gartner" OR "Forrester" OR "DB-Engines" OR "CNCF" ranking {current year}
WebSearch: site:{domain} "SOC 2" OR "ISO 27001" OR "HIPAA" OR "FedRAMP"
WebSearch: site:{domain} "partners" OR "AWS" OR "Azure" OR "GCP" OR "Red Hat"
```

**Map findings to Dimension 0 categories:**

| Category | Search Focus |
|----------|--------------|
| 0.1 Financial Scale | Revenue, ARR, funding rounds, valuation, growth |
| 0.2 Workforce Capacity | Employees, engineering headcount, community team |
| 0.3 Geographic Presence | HQ, offices, data center regions |
| 0.4 Market Position | Analyst ratings, GitHub stars, DB-Engines ranking, adoption metrics |
| 0.5 Certifications & Accreditations | SOC 2, ISO 27001, HIPAA, FedRAMP |
| 0.6 Partnership Ecosystem | Cloud provider partnerships, technology alliances |

## Phase 3: Portfolio Discovery (Dimensions 1-7)

For each category, execute TWO site-scoped searches per domain (THREE when LANGUAGE=de):

1. **Marketing search (EN):** Standard category terms on primary domain
2. **Docs/GitHub search:** Technical details on docs subdomain or GitHub
3. **Marketing search (DE):** German category terms on primary domain (LANGUAGE=de only)

### 1. Open Source Projects

```text
# 1.1 Core OSS Project(s)
WebSearch: site:github.com/{org} stars:>100 language description
WebSearch: site:{domain} "open source" OR "community edition" OR "source code"

# 1.2 Contributor Ecosystem
WebSearch: site:github.com/{org}/{project} contributors insights
WebSearch: "{project name}" contributors committers community metrics

# 1.3 Release Cadence & Governance
WebSearch: site:github.com/{org}/{project} releases tags
WebSearch: "{project name}" "governance" OR "RFC" OR "proposal" OR "steering committee"

# 1.4 Project Maturity
WebSearch: "{project name}" "CNCF graduated" OR "CNCF incubating" OR "Apache top-level" OR "production ready"
WebSearch: "{project name}" "used by" OR "adopters" OR "case study" OR "production deployment"

# 1.5 Community Distributions
WebSearch: "{project name}" "docker" OR "helm chart" OR "apt" OR "yum" OR "brew" OR "snap"
WebSearch: site:{domain} "download" OR "install" OR "getting started" OR "community edition"

# 1.6 Forks & Compatibility
WebSearch: "{project name}" fork OR "compatible" OR "drop-in replacement" OR "wire protocol"
WebSearch: "{project name}" vs OR "alternative to" OR "comparison"

# 1.7 Open Standards & Protocols
WebSearch: "{project name}" "OpenTelemetry" OR "SQL" OR "S3-compatible" OR "Prometheus" OR "OTEL" OR "standard"
WebSearch: site:{domain} "standards" OR "compatibility" OR "protocol" OR "specification"
```

### 2. Enterprise Platform

```text
# 2.1 Enterprise Edition Features
WebSearch: site:{domain} "enterprise" OR "enterprise edition" OR "commercial features" OR "premium"

# 2.2 Security Hardening & FIPS
WebSearch: site:{domain} "FIPS" OR "security hardening" OR "encryption at rest" OR "TLS" OR "CVE"

# 2.3 High Availability & Clustering
WebSearch: site:{domain} "high availability" OR "clustering" OR "replication" OR "failover" OR "disaster recovery"

# 2.4 Multi-Tenancy
WebSearch: site:{domain} "multi-tenant" OR "tenant isolation" OR "namespaces" OR "resource quotas"

# 2.5 Admin & Governance Console
WebSearch: site:{domain} "admin console" OR "management UI" OR "governance" OR "policy" OR "audit"

# 2.6 Enterprise Integrations
WebSearch: site:{domain} "LDAP" OR "Active Directory" OR "SAML" OR "SSO" OR "SCIM" OR "OIDC"

# 2.7 Air-Gapped & Offline Deployment
WebSearch: site:{domain} "air-gapped" OR "offline" OR "disconnected" OR "private registry" OR "on-premises"
```

### 3. Cloud & Managed Services

```text
# 3.1 Fully Managed Cloud
WebSearch: site:{domain} "cloud" OR "managed" OR "fully managed" OR "DBaaS" OR "PaaS" OR "as-a-service"

# 3.2 Serverless Offering
WebSearch: site:{domain} "serverless" OR "pay-per-query" OR "consumption" OR "auto-scaling"

# 3.3 Self-Hosted with Vendor Support
WebSearch: site:{domain} "self-hosted" OR "self-managed" OR "bring your own cloud" OR "BYOC"

# 3.4 Hybrid Cloud Deployment
WebSearch: site:{domain} "hybrid" OR "control plane" OR "data plane" OR "private link"

# 3.5 Marketplace Listings
WebSearch: site:aws.amazon.com/marketplace "{company name}" OR "{product name}"
WebSearch: site:azuremarketplace.microsoft.com "{company name}" OR "{product name}"
WebSearch: site:console.cloud.google.com/marketplace "{company name}" OR "{product name}"

# 3.6 Edge Deployment
WebSearch: site:{domain} "edge" OR "IoT" OR "lightweight" OR "embedded" OR "ARM"
```

### 4. Developer Ecosystem

```text
# 4.1 Documentation & Tutorials
WebSearch: site:docs.{domain} OR site:{domain}/docs "getting started" OR "quickstart" OR "tutorial"

# 4.2 SDKs & Client Libraries
WebSearch: site:{domain} OR site:github.com/{org} "SDK" OR "client library" OR "driver" "python" OR "java" OR "go"

# 4.3 Plugin & Extension Marketplace
WebSearch: site:{domain} "plugins" OR "extensions" OR "modules" OR "marketplace" OR "registry"

# 4.4 Developer Advocacy & Community
WebSearch: site:{domain} "community" OR "meetup" OR "conference" OR "slack" OR "discord" OR "forum"

# 4.5 Certification Program
WebSearch: site:{domain} "certification" OR "certified" OR "exam" OR "learning path" OR "academy"

# 4.6 Partner ISV Ecosystem
WebSearch: site:{domain} "partner" OR "ISV" OR "technology partner" OR "integration partner"
```

### 5. Support & Subscriptions

```text
# 5.1 Support Tiers
WebSearch: site:{domain} "support" OR "support plans" OR "community support" OR "premium support"

# 5.2 SLA Guarantees
WebSearch: site:{domain} "SLA" OR "uptime" OR "response time" OR "service level"

# 5.3 Incident Response
WebSearch: site:{domain} "security" OR "CVE" OR "incident" OR "vulnerability" OR "advisory"

# 5.4 Long-Term Support (LTS)
WebSearch: site:{domain} "LTS" OR "long-term support" OR "end of life" OR "EOL" OR "lifecycle"

# 5.5 Consulting Credits
WebSearch: site:{domain} "consulting" OR "advisory hours" OR "expert sessions" OR "architecture review"

# 5.6 Technical Account Management
WebSearch: site:{domain} "TAM" OR "technical account" OR "dedicated engineer" OR "named support"
```

### 6. Professional Services

```text
# 6.1 Implementation & Migration
WebSearch: site:{domain} "implementation" OR "migration" OR "deployment" OR "upgrade services"

# 6.2 Architecture Review
WebSearch: site:{domain} "architecture review" OR "design review" OR "capacity planning"

# 6.3 Performance Tuning
WebSearch: site:{domain} "performance" OR "optimization" OR "tuning" OR "benchmarking"

# 6.4 Training & Enablement
WebSearch: site:{domain} "training" OR "workshop" OR "bootcamp" OR "instructor-led"

# 6.5 Managed Operations
WebSearch: site:{domain} "managed operations" OR "managed service" OR "24/7" OR "monitoring"

# 6.6 Custom Development
WebSearch: site:{domain} "custom development" OR "custom feature" OR "bespoke" OR "integration development"
```

### 7. Licensing & Monetization

```text
# 7.1 License Model
WebSearch: site:{domain} "license" OR "Apache" OR "GPL" OR "SSPL" OR "BSL" OR "AGPL" OR "dual license"
WebSearch: site:github.com/{org}/{project} LICENSE

# 7.2 Usage Metering & Enforcement
WebSearch: site:{domain} "pricing" OR "per node" OR "per vCPU" OR "per GB" OR "metering"

# 7.3 Community Edition Scope
WebSearch: site:{domain} "community" OR "free" OR "open source" OR "comparison" "enterprise"

# 7.4 Commercial License Terms
WebSearch: site:{domain} "enterprise license" OR "subscription agreement" OR "terms"

# 7.5 Audit & Compliance Tools
WebSearch: site:{domain} "license compliance" OR "audit" OR "usage reporting"

# 7.6 OEM & Embedded Licensing
WebSearch: site:{domain} "OEM" OR "embedded" OR "redistribution" OR "ISV" OR "bundling"
```

## Phase 4: Competitor & Ecosystem Discovery

```text
WebSearch: "{project name}" vs OR versus OR alternative OR competitor
WebSearch: "{project name}" "DB-Engines" OR "CNCF landscape" OR "Thoughtworks Radar" {current year}
WebSearch: "{company name}" case study OR customer story OR "production deployment"
```
