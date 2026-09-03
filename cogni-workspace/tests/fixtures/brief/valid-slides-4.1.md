---
type: presentation-brief
version: "4.1"
theme: fixture-theme
customer: "Fixture GmbH"
provider: "Test AG"
language: de
arc_type: problem-solution
governing_thought: "Die Zustandsüberwachung muss messbar größer werden."
confidence_score: 0.9
slides: 3
climax: 2
design:
  register: sachlich
  dark_slides: [1, 3]
  speaker_notes: ausführlich
key_figures:
  - "3 Standorte im Pilotbetrieb"
  - "12 Wochen bis zum Rollout"
transformation_notes: |
  Diese Datei ist eine Testvorlage.
  Sie deckt Konstrukte ab, die EXAMPLE_BRIEF.md nicht enthält.
---

## Slide 1: Der Pilotbetrieb ist abgeschlossen

```yaml
Layout: title-slide
Slide-Kind: content
intent:
  role: hook
  emphasis: none
visual:
  kind: none
Title: Zustandsüberwachung im Pilotbetrieb
Subtitle: Ergebnisse aus drei Standorten
Metadata: Fixture GmbH | Test AG | Februar 2026
```

## Slide 2: Vier Rollen entscheiden über den Rollout

```yaml
Layout: four-quadrants
Slide-Kind: internal-prep
intent:
  role: context
  emphasis: medium
visual:
  kind: grid
Slide-Title: Das Buying Center
Q1:
  Label: Economic Buyer
  Sublabel: CFO Infrastruktur
  Bullets:
    - "Führen mit: Kapitalbindung"
    - "Vermeiden: Technikdetails"
Q2:
  Label: Technical Buyer
  Sublabel: Leiter Instandhaltung
  Bullets:
    - "Führen mit: Ausfallzeiten"
    - "Vermeiden: Vertragsdetails"
Q3:
  Label: User Buyer
  Sublabel: Schichtleitung
  Bullets:
    - "Führen mit: Arbeitsalltag"
    - "Vermeiden: Kennzahlen"
Q4:
  Label: Coach
  Sublabel: Projektleitung
  Bullets:
    - "Führen mit: Zeitplan"
    - "Vermeiden: Grundsatzfragen"
Bottom-Banner:
  Text: INTERN — NICHT PRÄSENTIEREN
Speaker-Notes: |
  Diese Folie bleibt intern.

  Der Absatz oben ist durch eine Leerzeile getrennt.
    Diese Zeile ist tiefer eingerückt und muss so bleiben.
  Quelle mit Fussnote <sup>[1](https://example.invalid/eins)</sup> im Fliesstext.
  Das Muster <sup>[N]</sup> ist nur eine Beschreibung und keine Fussnote.
```

## Slide 3: Der Rollout läuft in drei Schritten

```yaml
Layout: timeline-steps
Slide-Kind: content
intent:
  role: resolution
  emphasis: high
visual:
  kind: diagram
Slide-Title: Rollout-Fahrplan
Step-2:
  Title: Ausweitung
  Detail: Zwölf weitere Standorte
Step-10:
  Title: Abschluss
  Detail: "Rollout abgeschlossen"
Step-1:
  Title: Pilot
  Detail: Drei Standorte
Diagram: |
  graph LR
    A[Pilot] --> B[Ausweitung]
    B --> C[Abschluss]
Bottom-Banner:
  Text: Rollout in drei Schritten
```

## Generation Metadata

```yaml
slides_total: 3
content_slides: 2
prep_slides: 1
avg_confidence: 0.9
validation:
  schema: pass
  messages: pass
  copy: pass
  logic: pass
  integrity: pass
```

## Notes

| Feld | Zweck |
|---|---|
| Step-N | prüft die numerische Sortierung |
| Q1-Q4 | prüft die Alias-Normalisierung |

Dieser Abschnitt ist bewusst nicht eingefasst und gehört keinem Parser.
