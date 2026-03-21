# Scan Report Template

Instructions for generating `<company-slug>-portfolio.md` in Phase 6.

## Report Structure

Generate the report dynamically from the taxonomy in the template's `template.md`. Do NOT hardcode empty table sections — iterate over the taxonomy dimensions and categories to produce each section.

```markdown
# <Company Name> Portfolio

> Portfolio scan generated on <YYYY-MM-DD>
> Analyzed domains: domain1.com, docs.domain1.com, support.domain1.com
```

### Legends (include at top)

**Service Horizons:**

| Horizon | Timeframe | Characteristics |
|---------|-----------|-----------------|
| **Current** | 0-1 years | Generally available, proven deployments, established pricing |
| **Emerging** | 1-3 years | Beta/early access, limited availability, evolving pricing |
| **Future** | 3+ years | Announced, conceptual, R&D phase, no fixed pricing |

**Discovery Status:**

| Status | Meaning |
|--------|---------|
| **Confirmed** | Provider offers this capability (evidence found) |
| **Not Offered** | No evidence found for this category |
| **Emerging** | Announced or beta status (not yet GA) |
| **Extended** | Provider-specific variant beyond standard taxonomy |

### Per-Category Section Format

For each category in the taxonomy, generate:

```markdown
### <ID> <Category Name> [Status: <status>]

| Name | Description | Domain | Link | USP | Product Line | Pricing Model | Availability | Partners | Segments | Horizon |
|------|-------------|--------|------|-----|-------------|---------------|--------------|----------|----------|---------|
| <offerings...> |
```

Group categories under their dimension headers (`## 1. Automation & Control`, etc.).

### Empty Categories

When no offerings are found:

```markdown
| *No offerings found* | | | | | | | | | | |
```

Set status to `[Status: Not Offered]`.

### Cross-Cutting Attributes (include at end)

```markdown
## Cross-Cutting Attributes

### Target Segments
Discrete Manufacturing, Process Industries, Hybrid Manufacturing, Utilities, Oil & Gas, Mining

### Deployment Options
On-premises, Edge, Private Cloud, Hybrid Cloud, SaaS (cloud-native)

### Industrial Protocols
- **Fieldbus/Ethernet:** OPC UA, PROFINET, EtherNet/IP, EtherCAT, Modbus, PROFIBUS
- **IoT/Messaging:** MQTT, AMQP, HTTP/REST
- **Instrumentation:** HART, Foundation Fieldbus, IO-Link
```

## Column Reference

| Column | Description |
|--------|-------------|
| **Name** | Capability, product, or feature name |
| **Description** | What the capability does |
| **Domain** | Source domain where discovered |
| **Link** | Direct URL to the capability page |
| **USP** | Unique selling proposition / differentiators |
| **Product Line** | Which product family or division owns this |
| **Pricing Model** | How the capability is priced (product, license, subscription, service contract) |
| **Availability** | GA, beta, early access, announced |
| **Partners** | Key technology partnerships for this capability |
| **Segments** | Target industry segments (discrete, process, hybrid, utilities) |
| **Horizon** | Current, Emerging, or Future |
