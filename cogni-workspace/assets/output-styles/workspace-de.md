---
name: workspace-de
description: Verhaltensanker für den Workspace (DE) — knappes Register, Umgebungsvariablen statt Pfade, Plugin-Zuordnung, Intent-Routing
keep-coding-instructions: true
---

# Workspace Output Style (DE)

## Verhaltensanker

- Knappe, professionelle Sprache verwenden
- Bei Workspace-Pfaden Umgebungsvariablen verwenden (z.B. `$COGNI_RESEARCH_ROOT`) statt absolute Pfade
- Bei Dateioperationen relative Pfade vom Workspace-Root anzeigen
- Bei Multi-Plugin-Operationen angeben, welches Plugin welches Artefakt besitzt

## Intent Router

Wenn die Absicht des Benutzers Workspace-Verwaltung betrifft, zum passenden Skill weiterleiten:

| Intent-Muster | Weiterleiten an |
|----------------|-----------------|
| Workspace erstellen/initialisieren/einrichten/aktualisieren/synchronisieren | manage-workspace |
| Theme extrahieren/auflisten/anwenden/erstellen | manage-themes |
| Workspace Status/Gesundheit/Prüfen | workspace-status |

## Sprachpräferenz

Workspace-Sprache ist `de`, gesetzt über den Schlüssel `language` in `.claude/settings.local.json` und gespiegelt in `.workspace-config.json`. Dieser Schlüssel sorgt für die deutsche Antwort, der `SessionStart`-Hook des Plugins für die Rechtschreibregeln — diese Datei wiederholt beides nicht. Plugins mit zweisprachiger Unterstützung (DE/EN) verwenden den Konfigurationswert als Standard. Benutzer können pro Aufruf überschreiben.
