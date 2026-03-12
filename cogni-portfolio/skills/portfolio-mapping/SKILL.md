---
name: portfolio-mapping
description: |
  Analyze what IT services a company offers via web research. Use when user asks to map, analyze, or research a company's ICT/IT service portfolio, product offerings, or solution catalog. Triggers on requests like "what does [company] sell", "map [company] portfolio", "[company] service offerings", "competitor analysis of [company]", or "vendor assessment". Discovers subsidiaries/brands, searches their domains via parallel agents, and outputs structured portfolio across 8 dimensions (0-7): Provider Profile Metrics, Connectivity, Security, Digital Workplace, Cloud, Managed Infrastructure, Application, Consulting. Captures 57 categories with full entity schema (Name, Description, USP, Provider Unit, Pricing, Delivery, Partners, Verticals, Horizon) and Discovery Status. Requires an existing cogni-portfolio project (run setup first).
---

# Portfolio Mapping

Map a target company's ICT service portfolio to the B2B ICT Portfolio taxonomy (8 dimensions, 57 categories).

**Prerequisite:** A cogni-portfolio project must exist for this company. If `cogni-portfolio/{slug}/portfolio.json` does not exist, instruct the user to run `cogni-portfolio:setup` first.

**Note (zsh compatibility):** Do NOT combine variable assignment with `$()` command substitution and pipes in a single command. Use separate Bash tool calls.

## Workflow

### Phase 0: Prerequisite Check

1. Identify the target company from the user's request (or ask via AskUserQuestion)
2. Derive `COMPANY_SLUG` (kebab-case):
   ```bash
   echo "Company Name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//'
   ```
3. Locate the existing portfolio project:
   ```bash
   # Find the project directory
   find . -path "*/cogni-portfolio/*/portfolio.json" -type f 2>/dev/null
   ```
4. Read `portfolio.json` and extract `slug`, `company.name`
5. Set environment variables:

| Variable | Source | Example |
|----------|--------|---------|
| COMPANY_NAME | `portfolio.json` → `company.name` | `Deutsche Telekom` |
| COMPANY_SLUG | `portfolio.json` → `slug` | `deutsche-telekom` |
| PROJECT_PATH | Directory containing `portfolio.json` | `/path/to/cogni-portfolio/deutsche-telekom` |
| OUTPUT_FILE | `{PROJECT_PATH}/research/{COMPANY_SLUG}-portfolio.md` | |

6. Create research directories lazily:
   ```bash
   mkdir -p "${PROJECT_PATH}/research/.logs"
   mkdir -p "${PROJECT_PATH}/research/.metadata"
   ```

**If no portfolio project exists:** Stop and tell the user: "No portfolio project found for {company}. Run `cogni-portfolio:setup` first to create the project structure."

---

### Phase 1: Company Discovery

Search for the target company and its affiliated entities:

```text
WebSearch: "{company name}" subsidiaries affiliates brands "ICT services" OR "IT services" OR "digital services"
WebSearch: "{company name}" group companies divisions business units
WebSearch: "{company name}" consulting advisory strategy "IT consulting"
WebSearch: "{company name}" "managed services" OR "onsite services" OR "field services" OR "IT outsourcing" subsidiary
```

**Extract:**

- Parent company name and primary web domain
- Subsidiary/affiliate companies with their web domains
- Business units that offer B2B ICT services
- **Consulting/advisory subsidiaries** (often have IT Strategy, Architecture services)
- **On-site/field services subsidiaries** (often have IT Support, IT Outsourcing services)
- **Industry-vertical subsidiaries** (e.g., healthcare IT, automotive IT)

#### Delivery Unit Classification Rules

**INCLUDE as delivery unit if ANY of these criteria are met:**

| Criterion | Examples | Why Include |
|-----------|----------|-------------|
| Provides B2B ICT/IT services | T-Systems, Infosys, Accenture Technology | Core portfolio scope |
| Consulting/advisory subsidiary | Detecon, Capgemini Invent, McKinsey Digital | Dimension 7 (IT Strategy, Architecture) |
| On-site/field services subsidiary | T-Systems Onsite, DXC Workplace Services | Dimension 3.5 (IT Support), 5.5 (IT Outsourcing) |
| Industry-vertical subsidiary | Telekom Healthcare, Siemens Healthineers Digital | Vertical-specific ICT offerings |
| Regional delivery entity | T-Systems Hungary, Infosys BPM Europe | May have specialized regional offerings |
| Digital/technology brand | Telekom MMS, Publicis Sapient | Dimension 6 (Application Services) |
| Managed services provider | T-Systems MMS, Kyndryl | Dimension 5 (Infrastructure Services) |

**EXCLUDE only if ALL conditions are true:**

- Entity is purely consumer/retail focused (e.g., Telekom shops)
- Entity has no B2B service portfolio
- Entity provides no IT/digital services to enterprises

**Principle: When in doubt, INCLUDE.** Phase 3 research will naturally return no offerings if the entity isn't relevant.

#### Phase 1 Output Schema

Store discovered entities in structured format for downstream phases:

```json
{
  "company_name": "{company}",
  "parent_domain": "{domain}",
  "subsidiaries": [
    {
      "name": "{entity}",
      "domain": "{domain}",
      "type": "ict_delivery|consulting|field_services|industry_vertical|regional|digital",
      "docs_subdomains": [],
      "search_priority": "high"
    }
  ]
}
```

**CRITICAL:** NEVER deprioritize consulting subsidiaries. They often have IT Strategy (7.1), Architecture, and Advisory services that would otherwise be missed.

---

### Phase 1.5: User Confirmation & Validation

**MANDATORY:** Before proceeding to Phase 2, validate and present discovered delivery units.

#### Pre-checks (automated, before showing user)

Run these 3 checks silently and fix issues before presenting:

1. **Subsidiary count match:** Domain list count >= entities discovered in Phase 1. If missing, search for their domains.
2. **Domain completeness:** Each entity has a resolvable domain. Probe for missing ones.
3. **Docs subdomain probe:** For each primary domain, check for `docs.*`, `help.*` subdomains.

#### Present Discovery Summary

Use `AskUserQuestion` to present the validated entities:

```markdown
## Discovered Delivery Units for {COMPANY_NAME}

| # | Entity | Domain | Type | Include? |
|---|--------|--------|------|----------|
| 1 | {entity} | {domain} | {type} | Y |
| ... | ... | ... | ... | ... |

**Missing any subsidiaries?** Common entity types to check:
- Consulting/advisory subsidiaries
- On-site/field services
- Industry-specific brands (healthcare, automotive, etc.)
- Regional delivery units
```

**If user selects "Add more entities":**
1. Ask for entity names or domains
2. Search for each to discover domain
3. Re-present updated list
4. Repeat until confirmed (max 3 iterations)

**If user selects "Confirmed - proceed":** Lock the delivery unit list and proceed to Phase 2.

---

### Phase 2: Provider Profile Discovery (Dimension 0)

Search for provider business metrics within discovered domains.

**Important:** Include the current year in Financial Scale and Workforce Capacity searches.

```text
WebSearch: site:{domain} "annual revenue" OR "turnover" OR "financial results" {current year}
WebSearch: site:{domain} "employees" OR "workforce" OR "team size" {current year}
WebSearch: site:{domain} "headquarters" OR "locations" OR "offices" OR "data centers"
WebSearch: site:{domain} "market share" OR "ranking" OR "analyst" OR "Gartner" OR "Forrester"
WebSearch: site:{domain} "ISO" OR "certifications" OR "accreditations" OR "compliance"
WebSearch: site:{domain} "partner" OR "AWS" OR "Azure" OR "GCP" OR "SAP" OR "Microsoft"
```

**Map findings to Dimension 0 categories:**

| Category | Search Focus |
|----------|--------------|
| 0.1 Financial Scale | Revenue, turnover, market cap, growth trends |
| 0.2 Workforce Capacity | Employee count, IT specialists, regional distribution |
| 0.3 Geographic Presence | HQ, delivery centers, service countries, data centers |
| 0.4 Market Position | Rankings, analyst ratings, reference clients |
| 0.5 Certifications & Accreditations | ISO certs, industry accreditations, compliance |
| 0.6 Partnership Ecosystem | Hyperscaler tiers, strategic alliances |

### Phase 3: Portfolio Discovery (Dimensions 1-7)

Use the `portfolio-web-researcher` agent for parallel, domain-scoped web research. Each agent searches one domain across all 51 service categories (Dimensions 1-7).

#### Step 3.1: Prepare Domain List

Extract discovered domains from Phase 1 into a list:

```text
DOMAINS = [
  {"domain": "{domain}", "provider_unit": "{entity}"},
  ...
]
```

#### Step 3.2: Invoke portfolio-web-researcher Agents (Parallel)

**CRITICAL:** Invoke ALL domain agents in a SINGLE message to enable parallel execution.

For each domain, invoke the `portfolio-web-researcher` agent:

```text
Task(
  subagent_type="cogni-portfolio:portfolio-web-researcher",
  description="Portfolio research for {provider_unit}",
  prompt="Execute domain-scoped portfolio research.

PROJECT_PATH={PROJECT_PATH}
COMPANY_NAME={COMPANY_NAME}
DOMAIN={domain}
PROVIDER_UNIT={provider_unit}

Execute all 51 searches across Dimensions 1-7 and return compact JSON. NO PROSE."
)
```

**Invoke all domains in a single message for parallel execution.**

#### Step 3.3: Parse Agent Responses

Each agent returns compact JSON (~200 chars):

```json
{"ok":true,"d":"{domain}","u":"{unit}","s":{"ex":51,"ok":48},"o":{"tot":56,"cur":45,"emg":8,"fut":3},"log":"research/.logs/portfolio-web-research-{domain-slug}.json"}
```

#### Step 3.4: Load Full Results from Log Files

Read detailed offerings from each agent's log file:

```text
${PROJECT_PATH}/research/.logs/portfolio-web-research-{domain-slug}.json
```

#### Step 3.5: Handle Failures

If an agent returns `{"ok":false,...}`, retry that domain individually.

### Phase 4: Offering Aggregation

Aggregate offerings from all agent log files.

#### Step 4.0: Validation Gate

**Before aggregating**, verify all expected log files exist:

```bash
# Check each domain's log file exists
for domain_slug in {list}; do
  test -f "${PROJECT_PATH}/research/.logs/portfolio-web-research-${domain_slug}.json" && echo "OK: ${domain_slug}" || echo "MISSING: ${domain_slug}"
done
```

**If any are missing:** Report which domains failed, offer to retry those specific domains before proceeding. Do not aggregate partial results without user confirmation.

#### Step 4.1: Load All Log Files

For each domain, read the log file and extract offerings.

#### Step 4.2: Merge Offerings by Category

Combine offerings from all domains, grouped by category ID (1.1, 1.2, ... 7.5).

#### Step 4.3: Entity Schema Reference

Each offering contains the **full entity schema** (11 fields):

| Field | Description | Example Values |
|-------|-------------|----------------|
| Name | Service/product name as marketed | "Managed SD-WAN Pro" |
| Description | 1-2 sentence summary | "End-to-end SD-WAN with 24/7 NOC support" |
| Domain | Source domain where offering was found | "t-systems.com" |
| Link | Direct URL to source page | `[Link](https://t-systems.com/sd-wan)` |
| USP | Unique selling proposition / differentiators | "Only provider with native 5G failover" |
| Provider Unit | Business unit offering this service | "T-Systems", "MMS" |
| Pricing Model | How the service is priced | subscription, usage-based, project-based |
| Delivery Model | Where service is delivered from | Onshore, nearshore, offshore, hybrid |
| Technology Partners | Key partnerships and certifications | "AWS Advanced Partner", "Microsoft Gold" |
| Industry Verticals | Target industries | Healthcare, Automotive, Public Sector |
| Service Horizon | Market maturity classification | Current, Emerging, Future |

**Service Horizons:**

| Horizon | Timeframe | Characteristics |
|---------|-----------|-----------------|
| Current | 0-1 years | Generally available, proven deployments |
| Emerging | 1-3 years | Pilot/beta, limited availability |
| Future | 3+ years | Announced, conceptual, R&D phase |

### Phase 4.5: Cross-Category Entity Resolution

After aggregating offerings from all domains, analyze each offering for multi-category fit. Some offerings legitimately span multiple taxonomy categories.

#### Detection Rules

```text
FOR each offering in all_offerings:

  # Rule 1: Cloud infrastructure + Application services → dual category
  IF offering.category == "6.3" (Enterprise Platform Services)
     AND (offering.description CONTAINS "cloud infrastructure"
          OR offering.delivery_model == "cloud"
          OR offering.name CONTAINS "RISE with SAP")
  THEN also_assign_to("4.8")  # Enterprise Platforms on Cloud

  # Rule 2: Sovereign cloud + Data protection → dual category
  IF offering.category == "4.7" (Sovereign Cloud)
     AND offering.description CONTAINS "privacy" OR "data protection" OR "GDPR"
  THEN also_assign_to("2.10")  # Data Protection & Privacy

  # Rule 3: Managed security + IT outsourcing → dual category
  IF offering.category == "2.1" (SOC/SIEM)
     AND offering.description CONTAINS "outsourcing" OR "operations"
  THEN also_assign_to("5.5")  # IT Outsourcing

  # Rule 4: Cloud-native + DevOps → dual category
  IF offering.category == "4.6" (Cloud-Native Platform)
     AND offering.description CONTAINS "CI/CD" OR "DevOps" OR "GitOps"
  THEN also_assign_to("6.7")  # DevOps & Platform Engineering

  # Rule 5: Hyperscaler partnership → consider 4.1
  IF offering.partners CONTAINS "AWS" OR "Azure" OR "GCP"
     AND offering.category NOT IN ["4.1", "4.2"]
  THEN consider_for("4.1")  # Flag for review
```

#### Dual-Category Assignment Patterns

| Pattern | Primary Category | Secondary Category | Trigger |
|---------|-----------------|-------------------|---------|
| RISE with SAP | 6.3 | 4.8 | Name contains "RISE with SAP" or "SAP RISE" |
| SAP on Cloud | 4.8 | 6.3 | SAP + cloud infrastructure mentioned |
| Sovereign Cloud | 4.7 | 2.10 | Data sovereignty + privacy/protection |
| Managed SOC + ITO | 2.1 | 5.5 | SOC/SIEM + IT operations outsourcing |
| Cloud-Native + DevOps | 4.6 | 6.7 | Kubernetes + CI/CD/DevOps |

When duplicating to a secondary category: copy all 11 fields, update `category`, add `cross_category_source` to track origin.

---

### Phase 5: Discovery Status Assignment

For each of the 57 taxonomy categories, assign a **Discovery Status**:

| Status | Meaning | Action |
|--------|---------|--------|
| Confirmed | Provider offers this service (evidence found) | Populate entity table |
| Not Offered | No evidence found for this category | Mark as "No offerings found" |
| Emerging | Announced or pilot status (not yet GA) | Note in Horizon column |
| Extended | Provider-specific variant beyond standard taxonomy | Capture separately |

**Note:** Extended discoveries should not exceed ~10-15 additional entities beyond the 57 standard categories.

### Phase 6: Output Generation

Create the portfolio file at `${PROJECT_PATH}/research/${COMPANY_SLUG}-portfolio.md`.

Use the template from [references/portfolio-template.md](references/portfolio-template.md) for the complete output structure. Include:

- Header with generation date and analyzed domains
- Service Horizons and Discovery Status legends
- All 8 dimensions (0-7), 57 categories
- Full entity tables with 11 columns
- Cross-Cutting Attributes section

See [references/b2b-ict-taxonomy.md](references/b2b-ict-taxonomy.md) for category definitions.

#### Null-Safe Field Access

When processing offerings from log files, use null-safe access for optional fields (`partners`, `verticals`, `usp`, `pricing_model`, `delivery_model`):

```python
# CORRECT: Use 'or' to handle both missing AND null values
partners = (offer.get('partners') or '').replace('|', '\\|')[:60]
```

```bash
# Use // to provide default for null values
jq -r '.partners // ""'
```

#### Update Project Metadata

Write portfolio metadata to `research/.metadata/portfolio-mapping-output.json`:

```json
{
  "version": "1.0.0",
  "company_name": "{COMPANY_NAME}",
  "company_slug": "{COMPANY_SLUG}",
  "created": "{ISO_TIMESTAMP}",
  "skill": "cogni-portfolio:portfolio-mapping",
  "output_file": "research/{COMPANY_SLUG}-portfolio.md",
  "domains_analyzed": ["domain1.com", "domain2.com"],
  "dimensions_covered": 8,
  "categories_total": 57,
  "status_summary": {
    "confirmed": 0,
    "not_offered": 0,
    "emerging": 0,
    "extended": 0
  }
}
```

---

### Phase 7: Portfolio Data Model Integration (Optional)

After generating the portfolio markdown, offer to map discovered offerings to the cogni-portfolio data model. This bridges the research output into actionable portfolio entities.

**Ask the user:** "Would you like to map the discovered offerings to your portfolio data model? This creates feature and product entities you can use with propositions, solutions, and packages."

If the user declines, skip this phase.

#### Step 7.1: Map Offerings to Features

For each confirmed offering, propose a feature entity:

| Offering Field | Feature Field | Mapping Rule |
|---|---|---|
| Name | `name` | Use as-is |
| Name (kebab-case) | `slug` | Derive from name |
| Description | `description` | Use as-is |
| Category ID | `taxonomy_mapping.category_id` | Direct map |
| Category Name | `taxonomy_mapping.category_name` | From taxonomy |
| Dimension | `taxonomy_mapping.dimension` | From category ID (first digit) |
| Dimension Name | `taxonomy_mapping.dimension_name` | From taxonomy |
| Horizon | `taxonomy_mapping.horizon` | Current→`current`, Emerging→`emerging`, Future→`future` |
| Horizon | `readiness` | Current→`ga`, Emerging→`beta`, Future→`planned` |

#### Step 7.2: Map Dimensions to Products

If no products exist in the portfolio yet, suggest creating one product per dimension that has confirmed offerings:

| Dimension | Proposed Product | Condition |
|---|---|---|
| 1. Connectivity | `connectivity-services` | Has ≥1 confirmed offering |
| 2. Security | `security-services` | Has ≥1 confirmed offering |
| 3. Digital Workplace | `workplace-services` | Has ≥1 confirmed offering |
| 4. Cloud | `cloud-services` | Has ≥1 confirmed offering |
| 5. Infrastructure | `infrastructure-services` | Has ≥1 confirmed offering |
| 6. Application | `application-services` | Has ≥1 confirmed offering |
| 7. Consulting | `consulting-services` | Has ≥1 confirmed offering |

If products already exist, ask the user to assign each feature to an existing product.

#### Step 7.3: Present Mapping for Confirmation

Present proposed entities in a table for user review (same pattern as the `ingest` skill):

```markdown
## Proposed Feature Entities

| # | Slug | Name | Product | Readiness | Taxonomy | Action |
|---|------|------|---------|-----------|----------|--------|
| 1 | managed-sd-wan | Managed SD-WAN Pro | connectivity-services | ga | 1.1 WAN Services | Create |
| 2 | sase-gateway | SASE Gateway | connectivity-services | ga | 1.2 SASE | Create |
| ... | ... | ... | ... | ... | ... | ... |
```

Allow the user to:
- **Approve all** — create all proposed entities
- **Select individually** — approve, edit, or skip each
- **Edit before creating** — modify fields before writing

#### Step 7.4: Write Entities and Sync

For each confirmed entity:
1. Write product JSON to `products/{slug}.json` (if new products created)
2. Write feature JSON to `features/{slug}.json`
3. Set `created` to today's date
4. Include `"source_file": "research/{COMPANY_SLUG}-portfolio.md"` for traceability

After writing, sync the portfolio:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/sync-portfolio.sh "${PROJECT_PATH}"
```

#### Step 7.5: Set Taxonomy in portfolio.json

If not already set, update `portfolio.json` to include the taxonomy reference:

```json
{
  "taxonomy": {
    "type": "b2b-ict-portfolio",
    "version": "3.7",
    "dimensions": 8,
    "categories": 57,
    "source": "cogni-portfolio/skills/portfolio-mapping/references/b2b-ict-taxonomy.md"
  }
}
```

---

## Quality Requirements

- **Domain restriction:** Only search within discovered company domains
- **Evidence-based:** Every offering must link to a source page (Domain + Link columns REQUIRED)
- **Complete coverage:** Include all 8 dimensions (0-7) and 57 categories
- **Full entity schema:** Capture all 11 fields per offering where available
- **Discovery Status:** Mark each category with Confirmed/Not Offered/Emerging/Extended
- **Service Horizons:** Classify each offering as Current/Emerging/Future
- **Mark gaps:** Use "No offerings found" for empty categories with [Status: Not Offered]

## Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| COMPANY_NAME | Target company name | `Deutsche Telekom` |
| COMPANY_SLUG | From portfolio.json slug | `deutsche-telekom` |
| PROJECT_PATH | Path to portfolio project dir | `/path/to/cogni-portfolio/deutsche-telekom` |
| OUTPUT_FILE | Path to portfolio markdown | `${PROJECT_PATH}/research/${COMPANY_SLUG}-portfolio.md` |
