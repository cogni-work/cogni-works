# B2B Professional Services Search Patterns

Search queries for discovering professional services firm capabilities across the 8-dimension taxonomy. Used by the `scan` skill and `portfolio-web-researcher` agent.

## Phase 1: Firm Discovery

Search for the target firm and its service portfolio:

```text
WebSearch: "{company name}" "consulting" OR "advisory" OR "professional services" services practices
WebSearch: "{company name}" subsidiaries brands practices "consulting" OR "advisory"
WebSearch: "{company name}" "acquired" OR "acquisition" OR "merged" practices capabilities
WebSearch: "{company name}" "industry practices" OR "service lines" OR "capabilities" OR "what we do"
```

**Extract:**

- Primary firm name(s) and web domain(s)
- Service lines / practice areas
- Acquired firms now integrated into the practice
- Regional or specialty sub-brands (e.g., Monitor Deloitte, Arcadis Gen)

## Phase 2: Provider Profile Discovery (Dimension 0)

Include the current year in Financial Scale and Workforce searches.

```text
WebSearch: site:{domain} "revenue" OR "annual revenue" OR "turnover" {current year}
WebSearch: site:{domain} "employees" OR "consultants" OR "partners" OR "workforce" {current year}
WebSearch: site:{domain} "headquarters" OR "offices" OR "locations" OR "global presence"
WebSearch: "{company name}" "ALM Vanguard" OR "Forrester" OR "Source Global" OR "Vault" {current year}
WebSearch: site:{domain} "ISO" OR "certifications" OR "accreditations" OR "memberships"
WebSearch: site:{domain} "alliances" OR "partnerships" OR "ecosystem" OR "joint ventures"
```

**Map findings to Dimension 0 categories:**

| Category | Search Focus |
|----------|--------------|
| 0.1 Financial Scale | Revenue, revenue growth, ownership structure, PE backing, profit margins |
| 0.2 Workforce Capacity | Employee count, partner/principal headcount, consultant count, regional distribution |
| 0.3 Geographic Presence | HQ, offices, global delivery centers, service countries |
| 0.4 Market Position | Analyst ratings, industry rankings, Vault rankings, reference clients |
| 0.5 Certifications & Accreditations | ISO certifications, professional body memberships, industry accreditations |
| 0.6 Partnership Ecosystem | Technology alliances, academic partnerships, co-delivery arrangements |

## Phase 3: Service Portfolio Discovery (Dimensions 1-7)

For each category, execute TWO site-scoped searches per domain (THREE when LANGUAGE=de):

1. **Marketing search (EN):** Standard category terms on primary domain
2. **Thought leadership search:** Service names/synonyms on insights or publications pages
3. **Marketing search (DE):** German category terms on primary domain (LANGUAGE=de only)

```text
# Pattern for each category:
Search 1 (Marketing EN): site:{{DOMAIN}} {standard_terms}
Search 2 (Thought Leadership): site:{{DOMAIN}}/insights OR site:{{DOMAIN}}/publications {service_synonyms}
Search 3 (Marketing DE): site:{{DOMAIN}} {german_terms}  # Only when LANGUAGE=de
```

### 1. Strategy & Transformation

```text
# 1.1 Corporate Strategy
WebSearch: site:{domain} "corporate strategy" OR "growth strategy" OR "market entry" OR "competitive positioning"
WebSearch: site:{domain} "strategy consulting" OR "strategic advisory" OR "scenario planning" OR "portfolio strategy"

# 1.2 Operating Model Design
WebSearch: site:{domain} "operating model" OR "organizational design" OR "shared services" OR "target operating model"
WebSearch: site:{domain} "TOM" OR "process architecture" OR "operating model transformation"

# 1.3 M&A Advisory
WebSearch: site:{domain} "M&A" OR "mergers and acquisitions" OR "due diligence" OR "post-merger integration"
WebSearch: site:{domain} "carve-out" OR "divestiture" OR "synergy" OR "deal advisory"

# 1.4 Organizational Transformation
WebSearch: site:{domain} "transformation" OR "business transformation" OR "turnaround" OR "restructuring"
WebSearch: site:{domain} "transformation program" OR "business model redesign" OR "large-scale change"

# 1.5 Innovation & Growth Strategy
WebSearch: site:{domain} "innovation" OR "venture building" OR "digital business model" OR "growth accelerator"
WebSearch: site:{domain} "R&D strategy" OR "innovation lab" OR "new ventures" OR "disruptive"

# 1.6 ESG & Sustainability Strategy
WebSearch: site:{domain} "ESG" OR "sustainability" OR "net zero" OR "climate" OR "social impact"
WebSearch: site:{domain} "sustainability strategy" OR "ESG reporting" OR "decarbonization" OR "CSRD"
```

### 2. Operations & Performance

```text
# 2.1 Supply Chain Optimization
WebSearch: site:{domain} "supply chain" OR "logistics" OR "demand planning" OR "supplier management"

# 2.2 Process Excellence
WebSearch: site:{domain} "process excellence" OR "lean" OR "six sigma" OR "business process" OR "continuous improvement"

# 2.3 Procurement Advisory
WebSearch: site:{domain} "procurement" OR "strategic sourcing" OR "category management" OR "spend analysis"

# 2.4 Cost Transformation
WebSearch: site:{domain} "cost transformation" OR "cost reduction" OR "zero-based" OR "margin improvement"

# 2.5 Operational Risk Management
WebSearch: site:{domain} "operational risk" OR "business continuity" OR "crisis management" OR "resilience"
```

### 3. Technology & Digital Advisory

```text
# 3.1 Digital Strategy
WebSearch: site:{domain} "digital strategy" OR "digital transformation" OR "digital maturity" OR "customer experience"

# 3.2 Technology Selection & Architecture
WebSearch: site:{domain} "technology advisory" OR "ERP selection" OR "enterprise architecture" OR "IT strategy"

# 3.3 Data & AI Advisory
WebSearch: site:{domain} "data strategy" OR "AI advisory" OR "analytics" OR "data governance" OR "machine learning"

# 3.4 Cybersecurity Advisory
WebSearch: site:{domain} "cybersecurity" OR "cyber risk" OR "information security" OR "CISO advisory"

# 3.5 Cloud Strategy
WebSearch: site:{domain} "cloud strategy" OR "cloud migration" OR "multi-cloud" OR "infrastructure modernization"
```

### 4. Industry Practices

```text
# 4.1 Financial Services
WebSearch: site:{domain} "financial services" OR "banking" OR "insurance" OR "capital markets" OR "wealth management"

# 4.2 Healthcare & Life Sciences
WebSearch: site:{domain} "healthcare" OR "life sciences" OR "pharma" OR "hospitals" OR "medtech"

# 4.3 Energy & Resources
WebSearch: site:{domain} "energy" OR "oil and gas" OR "mining" OR "utilities" OR "energy transition"

# 4.4 Public Sector
WebSearch: site:{domain} "public sector" OR "government" OR "defense" OR "infrastructure" OR "education"

# 4.5 Manufacturing & Industrial
WebSearch: site:{domain} "manufacturing" OR "industrial" OR "automotive" OR "aerospace" OR "Industry 4.0"

# 4.6 TMT (Technology/Media/Telecom)
WebSearch: site:{domain} "technology" OR "media" OR "telecom" OR "telecommunications" OR "semiconductor"
```

### 5. Risk, Compliance & Assurance

```text
# 5.1 Regulatory Advisory
WebSearch: site:{domain} "regulatory" OR "compliance" OR "regulation" OR "licensing" OR "policy"

# 5.2 Internal Audit
WebSearch: site:{domain} "internal audit" OR "audit co-sourcing" OR "controls testing" OR "audit transformation"

# 5.3 Financial Audit Support
WebSearch: site:{domain} "financial audit" OR "audit support" OR "IFRS" OR "GAAP" OR "accounting advisory"

# 5.4 Forensic & Investigation
WebSearch: site:{domain} "forensic" OR "investigation" OR "fraud" OR "anti-bribery" OR "dispute advisory"

# 5.5 Enterprise Risk Management
WebSearch: site:{domain} "enterprise risk" OR "ERM" OR "risk management" OR "risk appetite" OR "risk framework"

# 5.6 Third-Party Risk
WebSearch: site:{domain} "third-party risk" OR "vendor due diligence" OR "supply chain compliance" OR "sanctions"
```

### 6. People & Change

```text
# 6.1 Change Management
WebSearch: site:{domain} "change management" OR "stakeholder engagement" OR "change readiness" OR "adoption"

# 6.2 Talent & Workforce Advisory
WebSearch: site:{domain} "talent" OR "workforce" OR "workforce planning" OR "skills" OR "future of work"

# 6.3 Leadership Development
WebSearch: site:{domain} "leadership" OR "executive coaching" OR "succession planning" OR "board effectiveness"

# 6.4 HR Transformation
WebSearch: site:{domain} "HR transformation" OR "HR operating model" OR "employee experience" OR "HR technology"

# 6.5 Culture & Engagement
WebSearch: site:{domain} "culture" OR "engagement" OR "diversity" OR "inclusion" OR "values"
```

### 7. Engagement Models

```text
# 7.1 Retainer/Advisory
WebSearch: site:{domain} "retainer" OR "advisory" OR "fractional" OR "ongoing advisory" OR "standing advisory"

# 7.2 Project-Based Delivery
WebSearch: site:{domain} "project-based" OR "fixed scope" OR "statement of work" OR "milestone"

# 7.3 Managed Services
WebSearch: site:{domain} "managed services" OR "outsourcing" OR "run-the-business" OR "BPO"

# 7.4 Secondment/Staff Augmentation
WebSearch: site:{domain} "secondment" OR "staff augmentation" OR "interim management" OR "embedded consultant"

# 7.5 Outcome-Based Engagements
WebSearch: site:{domain} "outcome-based" OR "success fee" OR "gain sharing" OR "risk reward" OR "performance fee"
```

## Phase 4: Competitor & Analyst Discovery

```text
WebSearch: "{company name}" vs OR versus OR alternative OR competitor consulting
WebSearch: "{company name}" "ALM Vanguard" OR "Forrester" OR "Source Global" OR "Kennedy" review {current year}
WebSearch: "{company name}" case study OR client story OR testimonial OR engagement
```
