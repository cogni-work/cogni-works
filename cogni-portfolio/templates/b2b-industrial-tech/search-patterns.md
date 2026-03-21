# B2B Industrial Technology Search Patterns

Search queries for discovering industrial technology capabilities across the 8-dimension taxonomy. Used by the `scan` skill and `portfolio-web-researcher` agent.

## Phase 1: Company Discovery

Search for the target company and its product suite:

```text
WebSearch: "{company name}" "industrial automation" OR "manufacturing technology" OR "operational technology" products portfolio
WebSearch: "{company name}" subsidiaries brands divisions "automation" OR "digital industries" OR "process"
WebSearch: "{company name}" "acquired" OR "acquisition" products "industrial" OR "automation" OR "IoT"
WebSearch: "{company name}" "developer platform" OR "IoT platform" OR "edge" OR "marketplace"
```

**Extract:**

- Primary product families and web domain(s)
- Business divisions / segments relevant to industrial technology
- Acquired products now integrated into the portfolio
- Developer/partner ecosystem sites (developers.{domain}, marketplace.{domain}, support.{domain})

## Phase 2: Provider Profile Discovery (Dimension 0)

Include the current year in Financial Scale and Workforce searches.

```text
WebSearch: site:{domain} "revenue" OR "order intake" OR "annual report" {current year}
WebSearch: site:{domain} "employees" OR "workforce" OR "R&D" {current year}
WebSearch: site:{domain} "headquarters" OR "offices" OR "plants" OR "service centers"
WebSearch: "{company name}" "Gartner Magic Quadrant" OR "ARC Advisory" OR "Forrester Wave" {current year}
WebSearch: site:{domain} "ISO 9001" OR "ISO 27001" OR "IEC 62443" OR "UL" OR "CE"
WebSearch: site:{domain} "partners" OR "alliances" OR "ecosystem" OR "consortia"
```

**Map findings to Dimension 0 categories:**

| Category | Search Focus |
|----------|--------------|
| 0.1 Financial Scale | Revenue, order intake, segment breakdown, growth rate |
| 0.2 Workforce Capacity | Employee count, R&D spend, engineering headcount, regional distribution |
| 0.3 Geographic Presence | HQ, offices, manufacturing plants, service centers, regional coverage |
| 0.4 Market Position | Analyst ratings, ARC Advisory rankings, market share, reference clients |
| 0.5 Certifications & Accreditations | ISO 9001, ISO 27001, IEC 62443, UL/CE, industry-specific accreditations |
| 0.6 Partnership Ecosystem | SI partners, technology alliances, OEM partnerships, industry consortia |

## Phase 3: Platform Portfolio Discovery (Dimensions 1-7)

For each category, execute TWO site-scoped searches per domain (THREE when LANGUAGE=de):

1. **Marketing search (EN):** Standard category terms on primary domain
2. **Product docs search:** Feature names/synonyms on docs subdomain
3. **Marketing search (DE):** German category terms on primary domain (LANGUAGE=de only)

```text
# Pattern for each category:
Search 1 (Marketing EN): site:{{DOMAIN}} {standard_terms}
Search 2 (Product Docs):  site:docs.{{DOMAIN}} OR site:support.{{DOMAIN}} {feature_synonyms}
Search 3 (Marketing DE):  site:{{DOMAIN}} {german_terms}  # Only when LANGUAGE=de
```

### 1. Automation & Control

```text
# 1.1 PLC/DCS Systems
WebSearch: site:{domain} "PLC" OR "DCS" OR "programmable logic controller" OR "distributed control system" OR "PAC"
WebSearch: site:docs.{domain} OR site:support.{domain} "controller" OR "programming environment" OR "TIA Portal" OR "Studio 5000"

# 1.2 SCADA/HMI
WebSearch: site:{domain} "SCADA" OR "HMI" OR "supervisory control" OR "human-machine interface" OR "operator panel"
WebSearch: site:docs.{domain} "visualization" OR "alarm management" OR "process graphics" OR "operator display"

# 1.3 Motion Control & Robotics
WebSearch: site:{domain} "servo drive" OR "VFD" OR "variable frequency" OR "CNC" OR "robot" OR "cobot" OR "motion control"
WebSearch: site:docs.{domain} "motion planning" OR "servo" OR "frequency converter" OR "robotics"

# 1.4 Instrumentation & Sensors
WebSearch: site:{domain} "transmitter" OR "analyzer" OR "sensor" OR "instrumentation" OR "flow meter" OR "pressure"
WebSearch: site:docs.{domain} "process instrument" OR "level" OR "temperature" OR "smart sensor"

# 1.5 Industrial Networking
WebSearch: site:{domain} "PROFINET" OR "EtherNet/IP" OR "EtherCAT" OR "industrial Ethernet" OR "fieldbus" OR "industrial switch"
WebSearch: site:docs.{domain} "industrial network" OR "network infrastructure" OR "PROFIBUS" OR "IO-Link"

# 1.6 Edge Computing (OT)
WebSearch: site:{domain} "edge computing" OR "industrial edge" OR "edge device" OR "edge runtime" OR "OT edge"
WebSearch: site:docs.{domain} "edge app" OR "edge management" OR "edge analytics" OR "data brokering"

# 1.7 Safety Systems
WebSearch: site:{domain} "safety PLC" OR "safety relay" OR "SIL" OR "safety controller" OR "emergency shutdown" OR "machine safety"
WebSearch: site:docs.{domain} "safety I/O" OR "safety integrated" OR "functional safety" OR "safe motion"
```

### 2. Manufacturing Execution

```text
# 2.1 MES/MOM Platforms
WebSearch: site:{domain} "MES" OR "MOM" OR "manufacturing execution" OR "manufacturing operations management"
WebSearch: site:docs.{domain} "production order" OR "shop floor" OR "work-in-progress" OR "OEE"

# 2.2 Quality Management
WebSearch: site:{domain} "quality management" OR "SPC" OR "statistical process control" OR "defect tracking" OR "CAPA"
WebSearch: site:docs.{domain} "inline inspection" OR "quality analytics" OR "quality assurance"

# 2.3 Production Scheduling
WebSearch: site:{domain} "production scheduling" OR "advanced planning" OR "APS" OR "finite capacity" OR "sequencing"
WebSearch: site:docs.{domain} "scheduling" OR "capacity planning" OR "demand planning"

# 2.4 Track & Trace
WebSearch: site:{domain} "track and trace" OR "serialization" OR "genealogy" OR "traceability" OR "material tracking"
WebSearch: site:docs.{domain} "product history" OR "batch traceability" OR "compliance reporting"

# 2.5 Recipe/Batch Management
WebSearch: site:{domain} "batch management" OR "recipe management" OR "ISA-88" OR "batch control"
WebSearch: site:docs.{domain} "batch execution" OR "recipe" OR "process parameter"

# 2.6 Warehouse Execution
WebSearch: site:{domain} "warehouse execution" OR "material flow" OR "intralogistics" OR "AGV" OR "AMR"
WebSearch: site:docs.{domain} "warehouse management" OR "material handling" OR "logistics automation"
```

### 3. Digital Twin & Simulation

```text
# 3.1 Product Digital Twin
WebSearch: site:{domain} "product digital twin" OR "3D model" OR "CAD" OR "CAE" OR "product lifecycle"
WebSearch: site:docs.{domain} "product twin" OR "design simulation" OR "design-to-manufacturing"

# 3.2 Process Digital Twin
WebSearch: site:{domain} "process digital twin" OR "production line simulation" OR "throughput optimization"
WebSearch: site:docs.{domain} "process twin" OR "line modeling" OR "bottleneck analysis"

# 3.3 Asset Digital Twin
WebSearch: site:{domain} "asset digital twin" OR "equipment twin" OR "performance baseline"
WebSearch: site:docs.{domain} "asset twin" OR "behavior model" OR "what-if analysis"

# 3.4 Simulation & Modeling
WebSearch: site:{domain} "simulation" OR "discrete event simulation" OR "physics-based" OR "multi-domain" OR "digital thread"
WebSearch: site:docs.{domain} "simulation modeling" OR "Tecnomatix" OR "SIMIT" OR "Simcenter"

# 3.5 Virtual Commissioning
WebSearch: site:{domain} "virtual commissioning" OR "hardware-in-the-loop" OR "HIL" OR "PLC simulation"
WebSearch: site:docs.{domain} "virtual commissioning" OR "control logic validation" OR "emulation"

# 3.6 AR/VR for Operations
WebSearch: site:{domain} "augmented reality" OR "AR" OR "VR" OR "mixed reality" OR "remote expert" OR "3D work instructions"
WebSearch: site:docs.{domain} "AR maintenance" OR "VR training" OR "remote assistance"
```

### 4. Industrial IoT & Data

```text
# 4.1 IoT Platform
WebSearch: site:{domain} "IoT platform" OR "Industrial IoT" OR "IIoT" OR "OPC UA" OR "MQTT" OR "device management"
WebSearch: site:docs.{domain} "IoT" OR "device connectivity" OR "protocol translation" OR "MindSphere" OR "FactoryTalk"

# 4.2 Industrial Data Management
WebSearch: site:{domain} "historian" OR "time series" OR "data lake" OR "unified namespace" OR "data contextualization"
WebSearch: site:docs.{domain} "data management" OR "industrial data" OR "data model" OR "asset framework"

# 4.3 Predictive Analytics
WebSearch: site:{domain} "predictive analytics" OR "machine learning" OR "anomaly detection" OR "AI" OR "process optimization"
WebSearch: site:docs.{domain} "predictive" OR "ML model" OR "yield optimization" OR "artificial intelligence"

# 4.4 Condition Monitoring
WebSearch: site:{domain} "condition monitoring" OR "vibration analysis" OR "thermal monitoring" OR "equipment health"
WebSearch: site:docs.{domain} "condition" OR "degradation" OR "health score" OR "bearing monitoring"

# 4.5 Energy Management
WebSearch: site:{domain} "energy management" OR "energy monitoring" OR "power quality" OR "demand response" OR "energy optimization"
WebSearch: site:docs.{domain} "energy" OR "power monitoring" OR "energy cost" OR "load management"

# 4.6 Emissions Monitoring
WebSearch: site:{domain} "emissions monitoring" OR "carbon footprint" OR "greenhouse gas" OR "sustainability dashboard" OR "ESG"
WebSearch: site:docs.{domain} "emissions" OR "carbon tracking" OR "environmental compliance" OR "GHG reporting"
```

### 5. OT Cybersecurity

```text
# 5.1 OT Network Security
WebSearch: site:{domain} "OT security" OR "industrial firewall" OR "network segmentation" OR "OT network" OR "deep packet inspection"
WebSearch: site:docs.{domain} "OT firewall" OR "industrial DMZ" OR "network security" OR "IDMZ"

# 5.2 Asset Discovery & Visibility
WebSearch: site:{domain} "asset discovery" OR "OT asset inventory" OR "passive scanning" OR "asset visibility"
WebSearch: site:docs.{domain} "asset inventory" OR "network scanning" OR "communication mapping"

# 5.3 OT SOC
WebSearch: site:{domain} "OT SOC" OR "security operations" OR "threat detection" OR "ICS" OR "incident response"
WebSearch: site:docs.{domain} "OT SIEM" OR "threat monitoring" OR "security analytics" OR "ICS detection"

# 5.4 ICS Vulnerability Management
WebSearch: site:{domain} "vulnerability management" OR "patch management" OR "OT patching" OR "ICS vulnerability"
WebSearch: site:docs.{domain} "vulnerability" OR "risk scoring" OR "compensating controls" OR "CVE"

# 5.5 IEC 62443 Compliance
WebSearch: site:{domain} "IEC 62443" OR "ISA 62443" OR "security level" OR "zone conduit"
WebSearch: site:docs.{domain} "62443" OR "security lifecycle" OR "compliance assessment" OR "IACS security"

# 5.6 Secure Remote Access
WebSearch: site:{domain} "secure remote access" OR "remote OT" OR "privileged access" OR "jump server"
WebSearch: site:docs.{domain} "remote access" OR "session recording" OR "MFA OT" OR "teleservice"
```

### 6. Lifecycle & Service

```text
# 6.1 Asset Lifecycle Management
WebSearch: site:{domain} "asset lifecycle" OR "installed base" OR "obsolescence" OR "modernization" OR "lifecycle management"
WebSearch: site:docs.{domain} "asset registry" OR "lifecycle costing" OR "obsolescence management"

# 6.2 Predictive/Preventive Maintenance
WebSearch: site:{domain} "predictive maintenance" OR "preventive maintenance" OR "condition-based maintenance" OR "CBM"
WebSearch: site:docs.{domain} "maintenance scheduling" OR "failure prediction" OR "MTBF" OR "MTTR"

# 6.3 Field Service Management
WebSearch: site:{domain} "field service" OR "technician dispatch" OR "work order" OR "service management"
WebSearch: site:docs.{domain} "field service" OR "mobile service" OR "service SLA" OR "dispatch"

# 6.4 Spare Parts Management
WebSearch: site:{domain} "spare parts" OR "parts management" OR "parts catalog" OR "inventory optimization"
WebSearch: site:docs.{domain} "spare parts" OR "parts logistics" OR "3D printing spares" OR "parts sourcing"

# 6.5 Remote Monitoring & Diagnostics
WebSearch: site:{domain} "remote monitoring" OR "remote diagnostics" OR "teleservice" OR "fleet monitoring"
WebSearch: site:docs.{domain} "remote access" OR "diagnostic dashboard" OR "alarm management" OR "equipment monitoring"
```

### 7. Engineering & Advisory

```text
# 7.1 Plant Engineering & Design
WebSearch: site:{domain} "plant engineering" OR "process engineering" OR "electrical design" OR "P&ID" OR "engineering platform"
WebSearch: site:docs.{domain} "plant design" OR "COMOS" OR "engineering tool" OR "electrical engineering"

# 7.2 Digital Transformation Consulting
WebSearch: site:{domain} "digital transformation" OR "Industry 4.0" OR "maturity assessment" OR "consulting" OR "advisory"
WebSearch: site:docs.{domain} "transformation roadmap" OR "business case" OR "change management"

# 7.3 OT System Integration
WebSearch: site:{domain} "system integration" OR "control system integration" OR "MES implementation" OR "brownfield" OR "migration"
WebSearch: site:docs.{domain} "system integrator" OR "SCADA deployment" OR "modernization" OR "retrofit"

# 7.4 Training & Certification
WebSearch: site:{domain} "training" OR "certification" OR "academy" OR "learning" OR "operator training"
WebSearch: site:docs.{domain} "training program" OR "certification path" OR "simulation training" OR "competency"

# 7.5 Managed OT Operations
WebSearch: site:{domain} "managed operations" OR "remote operations center" OR "OT-as-a-Service" OR "outsourced operations"
WebSearch: site:docs.{domain} "managed services" OR "performance contract" OR "operations center"

# 7.6 Sustainability & Decarbonization Advisory
WebSearch: site:{domain} "sustainability" OR "decarbonization" OR "net zero" OR "energy transition" OR "ESG" OR "circular economy"
WebSearch: site:docs.{domain} "carbon neutral" OR "sustainability consulting" OR "ESG reporting" OR "green manufacturing"
```

## Phase 4: Competitor & Analyst Discovery

```text
WebSearch: "{company name}" vs OR versus OR alternative OR competitor "industrial automation"
WebSearch: "{company name}" "Gartner" OR "ARC Advisory" OR "Forrester" OR "IDC" review {current year}
WebSearch: "{company name}" case study OR customer story OR reference "manufacturing" OR "industrial"
```
