#!/usr/bin/env python3
"""
bridge-citations.py
Version: 1.0.0
Purpose: Bridge citation formats between cogni-research synthesis and cogni-narrative.
Category: core

Usage:
    bridge-citations.py --project-path <path> [--json]

Reads synthesis/research-hub.md and extracts all [Source: Publisher](URL) citations.
Creates synthesis/narrative-input/ with:
  - report-for-narrative.md — research hub body with [source-NN-slug.md] markers
  - sources/source-NN-publisher-slug.md — per-source files with YAML frontmatter

Additionally cross-references each extracted URL against 05-sources/data/*.md entity
files to enrich per-source files with reliability_score, apa_citation, and
publisher_type from existing source entities.

cogni-narrative then cites these source files as <sup>[N](source-NN-slug.md)</sup>,
preserving the full audit trail back to original URLs.

Output:
    {"success": true, "data": {"sources_extracted": N, "unique_publishers": N, ...}}
"""

import argparse
import glob
import json
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


def slugify(text: str) -> str:
    """Convert publisher name to a filesystem-safe slug."""
    slug = text.lower().strip()
    slug = re.sub(r'[^a-z0-9]+', '-', slug)
    slug = slug.strip('-')
    return slug[:60] if slug else 'unknown'


def parse_yaml_frontmatter(text: str) -> Dict[str, str]:
    """Extract YAML frontmatter fields from a markdown file as a flat dict.

    Handles simple key: value pairs (no nested YAML). Strips quotes from values.
    """
    frontmatter = {}
    match = re.match(r'^---\s*\n(.*?)\n---', text, re.DOTALL)
    if not match:
        return frontmatter

    for line in match.group(1).splitlines():
        line = line.strip()
        if ':' in line and not line.startswith('#'):
            key, _, value = line.partition(':')
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key and value:
                frontmatter[key] = value

    return frontmatter


def build_source_entity_lookup(project_path: Path) -> Dict[str, Dict[str, str]]:
    """Build a URL → {reliability_score, apa_citation, publisher_type} lookup dict.

    Reads all 05-sources/data/*.md entity files and extracts source_url plus
    enrichment fields from their YAML frontmatter.
    """
    lookup: Dict[str, Dict[str, str]] = {}
    sources_dir = project_path / "05-sources" / "data"

    if not sources_dir.is_dir():
        return lookup

    for md_path in sorted(sources_dir.glob("*.md")):
        try:
            text = md_path.read_text(encoding='utf-8')
        except (OSError, UnicodeDecodeError):
            continue

        fm = parse_yaml_frontmatter(text)
        source_url = fm.get('source_url', '')
        if not source_url:
            continue

        enrichment: Dict[str, str] = {}
        if 'reliability_score' in fm:
            enrichment['reliability_score'] = fm['reliability_score']
        if 'apa_citation' in fm:
            enrichment['apa_citation'] = fm['apa_citation']
        if 'publisher_type' in fm:
            enrichment['publisher_type'] = fm['publisher_type']

        if enrichment:
            lookup[source_url] = enrichment

    return lookup


def extract_citations(report_text: str) -> List[Dict[str, str]]:
    """Extract all [Source: Publisher](URL) citations from report text.

    Returns deduplicated list of {publisher, url} dicts in order of first appearance.
    """
    pattern = r'\[Source:\s*([^\]]+)\]\(([^)]+)\)'
    seen_urls: set = set()
    citations: List[Dict[str, str]] = []

    for match in re.finditer(pattern, report_text):
        publisher = match.group(1).strip()
        url = match.group(2).strip()

        if url not in seen_urls:
            seen_urls.add(url)
            citations.append({
                'publisher': publisher,
                'url': url,
            })

    return citations


def create_source_file(index: int, publisher: str, url: str,
                       enrichment: Optional[Dict[str, str]] = None) -> Tuple[str, str]:
    """Create a source reference file content and filename.

    If enrichment data is available from 05-sources/data/ entities, includes
    reliability_score, apa_citation, and publisher_type in frontmatter.

    Returns (filename, content).
    """
    slug = slugify(publisher)
    filename = f"source-{index:02d}-{slug}.md"

    # Build frontmatter lines
    fm_lines = [
        "---",
        f"source_index: {index}",
        f'publisher: "{publisher}"',
        f'url: "{url}"',
    ]

    if enrichment:
        if 'reliability_score' in enrichment:
            fm_lines.append(f"reliability_score: {enrichment['reliability_score']}")
        if 'publisher_type' in enrichment:
            fm_lines.append(f'publisher_type: "{enrichment["publisher_type"]}"')
        if 'apa_citation' in enrichment:
            fm_lines.append(f'apa_citation: "{enrichment["apa_citation"]}"')

    fm_lines.append("---")

    # Build body
    body_lines = [
        "",
        f"# Source {index}: {publisher}",
        "",
        f"URL: {url}",
    ]

    if enrichment:
        if 'reliability_score' in enrichment:
            body_lines.append(f"Reliability Score: {enrichment['reliability_score']}")
        if 'publisher_type' in enrichment:
            body_lines.append(f"Publisher Type: {enrichment['publisher_type']}")
        if 'apa_citation' in enrichment:
            body_lines.append(f"APA Citation: {enrichment['apa_citation']}")

    body_lines.append("")

    content = "\n".join(fm_lines) + "\n".join(body_lines)
    return filename, content


def bridge_report(report_text: str, citations: List[Dict[str, str]],
                  source_filenames: Dict[str, str]) -> str:
    """Replace [Source: Publisher](URL) citations with [source-NN-slug.md] markers.

    The markers serve as breadcrumbs for cogni-narrative's citation system.
    """
    def replace_citation(match):
        url = match.group(2).strip()
        if url in source_filenames:
            return f"[{source_filenames[url]}]"
        return match.group(0)  # Keep original if not found

    pattern = r'\[Source:\s*([^\]]+)\]\(([^)]+)\)'
    return re.sub(pattern, replace_citation, report_text)


def main() -> None:
    parser = argparse.ArgumentParser(description="Bridge citations for narrative pipeline")
    parser.add_argument("--project-path", required=True, help="Project directory")
    parser.add_argument("--json", action="store_true", help="JSON output")
    args = parser.parse_args()

    project_path = Path(args.project_path)
    report_path = project_path / "synthesis" / "research-hub.md"

    if not report_path.is_file():
        msg = f"Research hub not found: {report_path}"
        if args.json:
            print(json.dumps({"success": False, "error": msg}), file=sys.stderr)
        else:
            print(f"ERROR: {msg}", file=sys.stderr)
        sys.exit(1)

    report_text = report_path.read_text(encoding='utf-8')

    # Build source entity lookup for enrichment
    source_entity_lookup = build_source_entity_lookup(project_path)

    # Extract unique citations
    citations = extract_citations(report_text)

    if not citations:
        msg = "No [Source: Publisher](URL) citations found in research hub"
        if args.json:
            print(json.dumps({
                "success": True,
                "data": {
                    "sources_extracted": 0,
                    "unique_publishers": 0,
                    "narrative_input_dir": str(project_path / "synthesis" / "narrative-input"),
                    "source_files": [],
                    "sources_enriched": 0,
                    "warning": "No citations found — narrative will have limited source references"
                }
            }))
        else:
            print(f"WARNING: {msg}")
        # Still create the directory with just the report copy
        output_dir = project_path / "synthesis" / "narrative-input"
        output_dir.mkdir(parents=True, exist_ok=True)
        (output_dir / "report-for-narrative.md").write_text(report_text, encoding='utf-8')
        return

    # Create output directory structure
    output_dir = project_path / "synthesis" / "narrative-input"
    sources_dir = output_dir / "sources"
    sources_dir.mkdir(parents=True, exist_ok=True)

    # Create per-source files and build URL-to-filename map
    source_filenames: Dict[str, str] = {}  # url -> filename
    source_files_created: List[str] = []
    publishers_seen: set = set()
    sources_enriched = 0

    for i, cit in enumerate(citations, start=1):
        # Look up enrichment data from 05-sources/data/ entities
        enrichment = source_entity_lookup.get(cit['url'])
        if enrichment:
            sources_enriched += 1

        filename, content = create_source_file(i, cit['publisher'], cit['url'], enrichment)
        (sources_dir / filename).write_text(content, encoding='utf-8')
        source_filenames[cit['url']] = filename
        source_files_created.append(filename)
        publishers_seen.add(cit['publisher'])

    # Create bridged report with source-file markers
    bridged_report = bridge_report(report_text, citations, source_filenames)
    (output_dir / "report-for-narrative.md").write_text(bridged_report, encoding='utf-8')

    # Output result
    result = {
        "success": True,
        "data": {
            "sources_extracted": len(citations),
            "unique_publishers": len(publishers_seen),
            "narrative_input_dir": str(output_dir),
            "source_files": source_files_created,
            "sources_enriched": sources_enriched,
        }
    }

    if args.json:
        print(json.dumps(result))
    else:
        print(f"Bridged {len(citations)} citations from {len(publishers_seen)} publishers")
        print(f"Enriched {sources_enriched} sources with entity metadata")
        print(f"Created {len(source_files_created)} source files in {sources_dir}")
        print(f"Bridged report: {output_dir / 'report-for-narrative.md'}")


if __name__ == "__main__":
    main()
