---
id: concept-multilingual-support
title: Multilingual European support (10 markets, encoding discipline)
type: concept
tags: [multilingual, languages, markets, dach, european-support, authority-sources]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md
status: stable
---

insight-wave is built for European multilingual operation, not English-only with translations bolted on. The output language is configurable per project (`output_language` in project config) and 10 markets are supported.

## Supported markets

`dach`, `de`, `fr`, `it`, `pl`, `nl`, `es`, `us`, `uk`, `eu` (composite). Each project picks one.

## Character encoding discipline

Proper character encoding per language is non-negotiable — never ASCII substitutes:

- **DE**: ä/ö/ü/ß
- **FR**: é/è/ê/ç
- **IT**: à/è/é/ì/ò/ù
- **PL**: ą/ć/ę/ł/ń/ó/ś/ź/ż
- **ES**: á/é/í/ó/ú/ñ

This matters because downstream rendering (cogni-visual, cogni-website, document export) and comparisons (cogni-claims source matching) all depend on the correct characters being present in the entity files.

## Per-market authority sources

Authority sources are curated per market in two files:
- `cogni-research/references/market-sources.json`
- `cogni-trends/references/region-authority-sources.json`

Default authority sources by market:
- **DACH**: fraunhofer.de, bitkom.org, vdma.org, destatis.de, handelsblatt.com
- **FR**: inria.fr, cnes.fr, arcep.fr, insee.fr, lesechos.fr
- **IT**: cnr.it, asi.it, agcom.it, istat.it, ilsole24ore.com
- **PL**: pan.pl, polsa.gov.pl, uke.gov.pl, stat.gov.pl, rp.pl
- **NL**: tno.nl, spaceoffice.nl, acm.nl, cbs.nl, fd.nl
- **ES**: csic.es, inta.es, cnmc.es, ine.es, expansion.com

Research and trend agents prefer these sources when scouting; quality assessors weight them higher in stakeholder review.

## Section header mappings

Per-language section header mappings live in `references/section-headers-de.md` (and equivalents) inside each plugin that produces structured output. Used by report generators to localize standard section names like "Executive Summary", "Findings", "Recommendations".

## Plugins most affected

- cogni-research, cogni-trends — language-aware web research and authority weighting
- cogni-narrative, cogni-copywriting, cogni-marketing — language-aware writing tone
- cogni-visual, cogni-website — language-aware text rendering and section headers

**Source**: [insight-wave/CLAUDE.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md)
