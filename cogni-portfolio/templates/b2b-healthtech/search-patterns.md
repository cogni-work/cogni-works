# B2B HealthTech Search Patterns

Search queries for discovering health IT platform capabilities across the 8-dimension taxonomy. Used by the `scan` skill and `portfolio-web-researcher` agent.

## Phase 1: Company Discovery

Search for the target company and its product suite:

```text
WebSearch: "{company name}" "health IT" OR "healthcare technology" OR "digital health" OR "clinical platform" products pricing
WebSearch: "{company name}" subsidiaries brands products "EHR" OR "clinical" OR "health data"
WebSearch: "{company name}" "acquired" OR "acquisition" products integrations "healthcare"
WebSearch: "{company name}" "developer platform" OR "FHIR" OR "API" OR "app gallery" OR "marketplace"
```

**Extract:**

- Primary product name(s) and web domain(s)
- Product suite / portfolio of distinct health IT products
- Acquired products now integrated into the platform
- Developer/partner ecosystem sites (developers.{domain}, open.{domain}, fhir.{domain})

## Phase 2: Provider Profile Discovery (Dimension 0)

Include the current year in Financial Scale and Workforce searches.

```text
WebSearch: site:{domain} "ARR" OR "annual recurring revenue" OR "revenue" {current year}
WebSearch: site:{domain} "employees" OR "team" OR "workforce" {current year}
WebSearch: site:{domain} "headquarters" OR "offices" OR "locations" OR "data centers"
WebSearch: "{company name}" "Gartner Magic Quadrant" OR "KLAS" OR "Forrester Wave" OR "Best in KLAS" {current year}
WebSearch: site:{domain} "HITRUST" OR "SOC 2" OR "ISO 27001" OR "HIPAA" OR "ONC" OR "certified"
WebSearch: site:{domain} "partners" OR "alliances" OR "health system" OR "ecosystem"
```

**Map findings to Dimension 0 categories:**

| Category | Search Focus |
|----------|--------------|
| 0.1 Financial Scale | ARR, total revenue, funding rounds, valuation, growth rate |
| 0.2 Workforce Capacity | Employee count, engineering headcount, regional distribution |
| 0.3 Geographic Presence | HQ, offices, data center regions, service countries |
| 0.4 Market Position | Analyst ratings, KLAS reviews, Gartner MQ, market share, reference clients |
| 0.5 Certifications & Accreditations | HITRUST, SOC 2, ISO 27001, ONC Health IT, HIPAA |
| 0.6 Partnership Ecosystem | Health system alliances, SI partners, technology alliances, channel programs |

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

### 1. Clinical Systems

```text
# 1.1 EHR/EMR
WebSearch: site:{domain} "EHR" OR "EMR" OR "electronic health record" OR "clinical documentation"
WebSearch: site:docs.{domain} "chart" OR "patient record" OR "clinical workflow" OR "documentation"

# 1.2 Clinical Decision Support
WebSearch: site:{domain} "clinical decision support" OR "CDS" OR "alerts" OR "order sets" OR "evidence-based"
WebSearch: site:docs.{domain} "clinical rules" OR "best practice alerts" OR "diagnostic support"

# 1.3 CPOE & Medication Management
WebSearch: site:{domain} "CPOE" OR "e-prescribing" OR "medication management" OR "pharmacy"
WebSearch: site:docs.{domain} "order entry" OR "medication reconciliation" OR "drug interaction"

# 1.4 Laboratory Information Systems
WebSearch: site:{domain} "laboratory" OR "LIS" OR "lab information" OR "specimen tracking"
WebSearch: site:docs.{domain} "lab orders" OR "results reporting" OR "pathology"

# 1.5 Radiology/PACS/Imaging IT
WebSearch: site:{domain} "radiology" OR "PACS" OR "imaging" OR "RIS" OR "DICOM"
WebSearch: site:docs.{domain} "image archive" OR "diagnostic imaging" OR "radiology workflow"

# 1.6 Perioperative/Surgical Systems
WebSearch: site:{domain} "perioperative" OR "surgical" OR "operating room" OR "anesthesia"
WebSearch: site:docs.{domain} "OR scheduling" OR "surgical documentation" OR "instrument tracking"
```

### 2. Patient Engagement

```text
# 2.1 Patient Portal
WebSearch: site:{domain} "patient portal" OR "MyChart" OR "patient access" OR "health records online"

# 2.2 Telehealth & Virtual Care
WebSearch: site:{domain} "telehealth" OR "virtual care" OR "video visit" OR "telemedicine"

# 2.3 Remote Patient Monitoring
WebSearch: site:{domain} "remote monitoring" OR "RPM" OR "connected devices" OR "wearables"

# 2.4 Patient Scheduling & Access
WebSearch: site:{domain} "scheduling" OR "appointment" OR "online booking" OR "patient access"

# 2.5 Patient Communication
WebSearch: site:{domain} "patient communication" OR "reminders" OR "messaging" OR "outreach"

# 2.6 Consumer Health Apps
WebSearch: site:{domain} "mobile app" OR "consumer health" OR "wellness" OR "patient app"
```

### 3. Health Data & Interoperability

```text
# 3.1 Health Information Exchange (HIE)
WebSearch: site:{domain} "health information exchange" OR "HIE" OR "data sharing" OR "care network"

# 3.2 FHIR/HL7 Integration
WebSearch: site:{domain} "FHIR" OR "HL7" OR "interoperability" OR "C-CDA" OR "SMART on FHIR"

# 3.3 Clinical Data Warehouse
WebSearch: site:{domain} "data warehouse" OR "clinical data" OR "data repository" OR "analytics platform"

# 3.4 Population Health Analytics
WebSearch: site:{domain} "population health" OR "risk stratification" OR "care gaps" OR "cohort"

# 3.5 AI & Clinical Analytics
WebSearch: site:{domain} "AI" OR "machine learning" OR "clinical analytics" OR "predictive" OR "NLP" OR "ambient"

# 3.6 Master Patient Index
WebSearch: site:{domain} "patient matching" OR "MPI" OR "master patient index" OR "identity resolution"
```

### 4. Revenue Cycle & Operations

```text
# 4.1 Revenue Cycle Management
WebSearch: site:{domain} "revenue cycle" OR "RCM" OR "billing" OR "charge capture" OR "denial management"

# 4.2 Claims Processing
WebSearch: site:{domain} "claims" OR "adjudication" OR "ERA" OR "payer" OR "clearinghouse"

# 4.3 Coding & Documentation
WebSearch: site:{domain} "coding" OR "CDI" OR "computer-assisted coding" OR "HCC" OR "ICD-10"

# 4.4 Supply Chain Management
WebSearch: site:{domain} "supply chain" OR "inventory" OR "procurement" OR "implant tracking"

# 4.5 Workforce Management
WebSearch: site:{domain} "workforce" OR "scheduling" OR "staffing" OR "credential" OR "labor"
```

### 5. Regulatory & Compliance

```text
# 5.1 HIPAA Compliance Tools
WebSearch: site:{domain} "HIPAA" OR "privacy" OR "breach detection" OR "consent management" OR "access audit"

# 5.2 Clinical Quality Reporting
WebSearch: site:{domain} "quality reporting" OR "MIPS" OR "eCQM" OR "quality measures" OR "CMS"

# 5.3 MDR/FDA Compliance
WebSearch: site:{domain} "FDA" OR "MDR" OR "510(k)" OR "UDI" OR "medical device regulation"

# 5.4 Clinical Trial Management
WebSearch: site:{domain} "clinical trial" OR "CTMS" OR "study management" OR "patient recruitment"

# 5.5 Pharmacovigilance
WebSearch: site:{domain} "pharmacovigilance" OR "adverse event" OR "drug safety" OR "MedWatch"
```

### 6. Life Sciences Platform

```text
# 6.1 Drug Discovery Platforms
WebSearch: site:{domain} "drug discovery" OR "compound screening" OR "target identification" OR "molecular"

# 6.2 Real-World Evidence
WebSearch: site:{domain} "real-world evidence" OR "RWE" OR "observational" OR "outcomes research"

# 6.3 Genomics & Precision Medicine
WebSearch: site:{domain} "genomics" OR "precision medicine" OR "pharmacogenomics" OR "genetic"

# 6.4 Medical Device Connectivity
WebSearch: site:{domain} "device connectivity" OR "IoMT" OR "medical device integration" OR "biomedical"

# 6.5 Clinical Research Informatics
WebSearch: site:{domain} "research informatics" OR "biobank" OR "translational research" OR "research data"
```

### 7. Advisory & Implementation

```text
# 7.1 Clinical Transformation Consulting
WebSearch: site:{domain} "clinical transformation" OR "workflow redesign" OR "digital health strategy" OR "consulting"

# 7.2 EHR Implementation Services
WebSearch: site:{domain} "EHR implementation" OR "go-live" OR "system selection" OR "optimization"

# 7.3 Interoperability Consulting
WebSearch: site:{domain} "interoperability consulting" OR "integration services" OR "HIE strategy"

# 7.4 Training & Adoption
WebSearch: site:{domain} "training" OR "adoption" OR "e-learning" OR "super-user" OR "competency"

# 7.5 Managed Health IT Operations
WebSearch: site:{domain} "managed services" OR "application management" OR "hosting" OR "help desk"

# 7.6 Cybersecurity for Healthcare
WebSearch: site:{domain} "cybersecurity" OR "threat detection" OR "vulnerability" OR "security operations"

# 7.7 Change Management
WebSearch: site:{domain} "change management" OR "organizational readiness" OR "stakeholder engagement"
```

## Phase 4: Competitor & Analyst Discovery

```text
WebSearch: "{company name}" vs OR versus OR alternative OR competitor "health IT" OR "EHR"
WebSearch: "{company name}" "Gartner" OR "KLAS" OR "Forrester" OR "IDC" review {current year}
WebSearch: "{company name}" case study OR customer story OR testimonial "hospital" OR "health system"
```
