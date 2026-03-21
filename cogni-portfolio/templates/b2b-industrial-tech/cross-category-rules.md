# Cross-Category Assignment Rules

Some offerings legitimately span multiple taxonomy categories. After aggregating offerings from all domains, analyze each offering for multi-category fit.

## Detection Rules

```text
FOR each offering in all_offerings:

  # Rule 1: OT Edge + IoT Platform → dual category
  IF offering.category == "1.6" (Edge Computing (OT))
     AND (offering.description CONTAINS "IoT platform"
          OR offering.description CONTAINS "cloud connectivity"
          OR offering.description CONTAINS "device management")
  THEN also_assign_to("4.1")  # IoT Platform

  # Rule 2: Product Digital Twin + Simulation → dual category
  IF offering.category == "3.1" (Product Digital Twin)
     AND (offering.description CONTAINS "simulation"
          OR offering.description CONTAINS "physics-based"
          OR offering.description CONTAINS "FEA"
          OR offering.description CONTAINS "CFD")
  THEN also_assign_to("3.4")  # Simulation & Modeling

  # Rule 3: Predictive Analytics + Maintenance → dual category
  IF offering.category == "4.3" (Predictive Analytics)
     AND (offering.description CONTAINS "maintenance"
          OR offering.description CONTAINS "failure prediction"
          OR offering.description CONTAINS "remaining useful life")
  THEN also_assign_to("6.2")  # Predictive/Preventive Maintenance

  # Rule 4: Safety Systems + IEC 62443 Compliance → dual category
  IF offering.category == "1.7" (Safety Systems)
     AND (offering.description CONTAINS "IEC 62443"
          OR offering.description CONTAINS "cybersecurity"
          OR offering.description CONTAINS "security level"
          OR offering.description CONTAINS "secure by design")
  THEN also_assign_to("5.5")  # IEC 62443 Compliance

  # Rule 5: Energy Management + Emissions Monitoring → dual category
  IF offering.category == "4.5" (Energy Management)
     AND (offering.description CONTAINS "emissions"
          OR offering.description CONTAINS "carbon"
          OR offering.description CONTAINS "sustainability"
          OR offering.description CONTAINS "ESG")
  THEN also_assign_to("4.6")  # Emissions Monitoring

  # Rule 6: Condition Monitoring + Remote Monitoring → dual category
  IF offering.category == "4.4" (Condition Monitoring)
     AND (offering.description CONTAINS "remote"
          OR offering.description CONTAINS "fleet monitoring"
          OR offering.description CONTAINS "teleservice")
  THEN also_assign_to("6.5")  # Remote Monitoring & Diagnostics

  # Rule 7: MES/MOM + Quality Management → dual category
  IF offering.category == "2.1" (MES/MOM Platforms)
     AND (offering.description CONTAINS "quality"
          OR offering.description CONTAINS "SPC"
          OR offering.description CONTAINS "defect tracking")
  THEN also_assign_to("2.2")  # Quality Management

  # Rule 8: IoT Platform + Industrial Data Management → dual category
  IF offering.category == "4.1" (IoT Platform)
     AND (offering.description CONTAINS "historian"
          OR offering.description CONTAINS "time series"
          OR offering.description CONTAINS "data lake"
          OR offering.description CONTAINS "unified namespace")
  THEN also_assign_to("4.2")  # Industrial Data Management
```

## Dual-Category Assignment Patterns

| Pattern | Primary Category | Secondary Category | Trigger |
|---------|-----------------|-------------------|---------|
| OT edge + IoT platform | 1.6 | 4.1 | Cloud connectivity or device management mentioned |
| Product twin + simulation | 3.1 | 3.4 | Physics-based simulation or FEA/CFD context |
| Predictive analytics + maintenance | 4.3 | 6.2 | Maintenance or failure prediction context |
| Safety systems + IEC 62443 | 1.7 | 5.5 | Cybersecurity or security level context |
| Energy management + emissions | 4.5 | 4.6 | Emissions, carbon, or ESG context |
| Condition monitoring + remote monitoring | 4.4 | 6.5 | Remote or fleet monitoring context |
| MES/MOM + quality | 2.1 | 2.2 | Quality or SPC context |
| IoT platform + data management | 4.1 | 4.2 | Historian, time series, or data lake context |

When duplicating to a secondary category: copy all fields, update `category`, add `cross_category_source` to track origin.
