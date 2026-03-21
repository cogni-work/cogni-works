# Cross-Category Assignment Rules

Some offerings legitimately span multiple taxonomy categories. After aggregating offerings from all domains, analyze each offering for multi-category fit.

## Detection Rules

```text
FOR each offering in all_offerings:

  # Rule 1: Remote Patient Monitoring + EHR Integration → dual category
  IF offering.category == "2.3" (Remote Patient Monitoring)
     AND (offering.description CONTAINS "EHR"
          OR offering.description CONTAINS "EMR"
          OR offering.description CONTAINS "clinical documentation"
          OR offering.description CONTAINS "chart integration")
  THEN also_assign_to("1.1")  # EHR/EMR

  # Rule 2: AI/Clinical Analytics + Radiology/PACS → dual category
  IF offering.category == "3.5" (AI & Clinical Analytics)
     AND (offering.description CONTAINS "radiology"
          OR offering.description CONTAINS "imaging"
          OR offering.description CONTAINS "PACS"
          OR offering.description CONTAINS "DICOM")
  THEN also_assign_to("1.5")  # Radiology/PACS/Imaging IT

  # Rule 3: Medical Device Connectivity + Remote Monitoring → dual category
  IF offering.category == "6.4" (Medical Device Connectivity)
     AND (offering.description CONTAINS "remote monitoring"
          OR offering.description CONTAINS "RPM"
          OR offering.description CONTAINS "patient monitoring"
          OR offering.description CONTAINS "vital signs")
  THEN also_assign_to("2.3")  # Remote Patient Monitoring

  # Rule 4: Clinical Quality Reporting + Population Health → dual category
  IF offering.category == "5.2" (Clinical Quality Reporting)
     AND (offering.description CONTAINS "population health"
          OR offering.description CONTAINS "risk stratification"
          OR offering.description CONTAINS "care gaps"
          OR offering.description CONTAINS "cohort")
  THEN also_assign_to("3.4")  # Population Health Analytics

  # Rule 5: FHIR/HL7 + HIE → dual category
  IF offering.category == "3.2" (FHIR/HL7 Integration)
     AND (offering.description CONTAINS "health information exchange"
          OR offering.description CONTAINS "HIE"
          OR offering.description CONTAINS "cross-organization"
          OR offering.description CONTAINS "data sharing network")
  THEN also_assign_to("3.1")  # Health Information Exchange (HIE)

  # Rule 6: EHR Implementation + Clinical Transformation → dual category
  IF offering.category == "7.2" (EHR Implementation Services)
     AND (offering.description CONTAINS "workflow redesign"
          OR offering.description CONTAINS "clinical transformation"
          OR offering.description CONTAINS "care model"
          OR offering.description CONTAINS "optimization")
  THEN also_assign_to("7.1")  # Clinical Transformation Consulting
```

## Dual-Category Assignment Patterns

| Pattern | Primary Category | Secondary Category | Trigger |
|---------|-----------------|-------------------|---------|
| Remote monitoring + EHR integration | 2.3 | 1.1 | EHR/EMR or chart integration mentioned |
| AI analytics + radiology/imaging | 3.5 | 1.5 | Radiology, imaging, or PACS context |
| Device connectivity + remote monitoring | 6.4 | 2.3 | RPM or patient monitoring context |
| Quality reporting + population health | 5.2 | 3.4 | Population health or care gaps context |
| FHIR/HL7 + health information exchange | 3.2 | 3.1 | HIE or cross-organization data sharing context |
| EHR implementation + clinical transformation | 7.2 | 7.1 | Workflow redesign or care model optimization context |

When duplicating to a secondary category: copy all fields, update `category`, add `cross_category_source` to track origin.
