#!/usr/bin/env python3
"""Deterministic Phase 5 gates for a generated narrative.

Reads a narrative markdown file and the v2 arc contract it claims, and reports
every mechanical gate from references/validation.md as pass/fail. The judged
gates (title specificity, technique application, transition quality) need a
reader and are not here.

Gates:
  S1  exactly four `##` headers in the body
  S2  headers byte-equal to the contract's `## Headings` cells for the language
  C1  body word count within [target*0.85, target*1.15]
  C2  each segment within [proportion*lower, proportion*upper]
  C3  required frontmatter fields present; arc_id matches the contract
  E1  citation markers >= 15 (<= 25 at the default length); a reused source
      reuses its number, so markers are counted, not distinct numbers
  E2  citation numbers sequential from 1 by first appearance
  E3  one number per source file and one file per number (dedup by identity)
  L1  (de only) no ASCII umlaut fallbacks in body text
  T1  (contracts without a Hook segment) opening TL;DR is 2-4 sentences and
      60-100 words
  T2  every citation number in the TL;DR also appears below the first `##`
  X1  when a `**Sources**` block is present: every body citation number has
      exactly one entry and every entry is cited at least once

Usage:
  validate-narrative.py --narrative FILE --contract ARC_DEFINITION.md
                        [--language en|de] [--target-length N] [--json]

Exit 0 when every gate passes, 1 when any gate fails, 2 on a usage or read
error. Output is the repo's script envelope:
  {"success": bool, "data": {...}, "error": str|null}

Stdlib only.
"""

import argparse
import json
import re
import sys

REQUIRED_FRONTMATTER = (
    "title", "subtitle", "arc_id", "arc_display_name", "target_length",
    "word_count", "language", "date_created", "source_file_count",
)
CITATION_RE = re.compile(r"<sup>\[(\d+)\]\(([^)]+)\)</sup>")
SOURCES_ENTRY_RE = re.compile(r"^\s*(?:-\s*)?\[(\d+)\]\s")
DE_ASCII_FALLBACKS = (
    "fuer", "ueber", "aenderung", "groesste", "fuehrung", "loesung", "moeglich",
    "koennen", "muessen", "waehrend", "zurueck", "naechste", "verstaerkt",
)
DEFAULT_TARGET = 1675
CITATION_FLOOR = 15
CITATION_CEILING_AT_DEFAULT = 25
TLDR_WORDS = (60, 100)
TLDR_SENTENCES = (2, 4)


def envelope(success, data=None, error=None):
    return {"success": success, "data": data if data is not None else {}, "error": error}


def read(path):
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def split_frontmatter(text):
    """Return (frontmatter dict, body). Frontmatter is the leading --- block."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}, text
    fm = {}
    for idx in range(1, len(lines)):
        if lines[idx].strip() == "---":
            return fm, "\n".join(lines[idx + 1:])
        if ":" in lines[idx]:
            key, _, value = lines[idx].partition(":")
            fm[key.strip()] = value.strip().strip('"').strip("'")
    return fm, text


def strip_fences(body):
    """Drop fenced code blocks so a quoted `##` inside one is not a header."""
    out, fenced = [], False
    for line in body.splitlines():
        if line.strip().startswith("```"):
            fenced = not fenced
            continue
        if not fenced:
            out.append(line)
    return "\n".join(out)


def word_count(text):
    text = CITATION_RE.sub("", text)
    return len(re.findall(r"\S+", text))


def parse_table(lines):
    """Parse a pipe table into a list of row dicts keyed by header cell."""
    rows, header = [], None
    for line in lines:
        s = line.strip()
        if not s.startswith("|"):
            if header is not None:
                break
            continue
        cells = [c.strip() for c in s.strip("|").split("|")]
        if header is None:
            header = cells
            continue
        if all(set(c) <= set("-:") for c in cells if c):
            continue
        rows.append(dict(zip(header, cells)))
    return header or [], rows


def contract_sections(text):
    fm, body = split_frontmatter(text)
    sections, current, buf = {}, None, []
    for line in body.splitlines():
        if line.startswith("## "):
            if current is not None:
                sections[current] = buf
            current, buf = line[3:].strip(), []
        elif current is not None:
            buf.append(line)
    if current is not None:
        sections[current] = buf
    return fm, sections


def contract_headings(sections, language):
    header, rows = parse_table(sections.get("Headings", []))
    col = None
    for cell in header:
        if cell.strip().lower() == language.lower():
            col = cell
            break
    if col is None:
        return None
    return [r[col] for r in rows if r.get(col)]


def contract_composition(sections):
    _, rows = parse_table(sections.get("Composition", []))
    out = []
    for r in rows:
        name = r.get("Segment") or r.get("Element")
        prop = r.get("Proportion", "")
        m = re.search(r"(\d+(?:\.\d+)?)", prop)
        if name and m:
            out.append((name, float(m.group(1)) / 100.0))
    return out


def split_body(body):
    """Return (preamble, [(header, text), ...], trailer_after_sources)."""
    lines = body.splitlines()
    h2_idx = [i for i, l in enumerate(lines) if l.startswith("## ")]
    preamble = "\n".join(lines[: h2_idx[0]]) if h2_idx else body
    elements = []
    for n, i in enumerate(h2_idx):
        end = h2_idx[n + 1] if n + 1 < len(h2_idx) else len(lines)
        elements.append((lines[i][3:].strip(), "\n".join(lines[i + 1:end])))
    return preamble, elements


def strip_title_block(preamble):
    """Remove the H1 title, the italic subtitle line and horizontal rules."""
    kept = []
    for line in preamble.splitlines():
        s = line.strip()
        if s.startswith("# ") or s == "---" or (s.startswith("*") and s.endswith("*") and s.count("*") == 2):
            continue
        kept.append(line)
    return "\n".join(kept).strip()


def extract_sources(text):
    """Split a `**Sources**` block off the end of an element body."""
    m = re.search(r"^\*\*Sources\*\*\s*$", text, flags=re.M)
    if not m:
        return text, None
    return text[: m.start()], text[m.end():]


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--narrative", required=True)
    ap.add_argument("--contract", required=True)
    ap.add_argument("--language")
    ap.add_argument("--target-length", type=int)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args(argv)

    try:
        narrative = read(args.narrative)
        contract = read(args.contract)
    except OSError as exc:
        print(json.dumps(envelope(False, error=str(exc))))
        return 2

    fm, raw_body = split_frontmatter(narrative)
    body = strip_fences(raw_body)
    cfm, sections = contract_sections(contract)
    language = (args.language or fm.get("language") or "en").lower()
    try:
        target = int(args.target_length or fm.get("target_length") or DEFAULT_TARGET)
    except ValueError:
        target = DEFAULT_TARGET
    lower, upper = target * 0.85, target * 1.15

    gates = []

    def gate(gid, ok, detail):
        gates.append({"id": gid, "status": "pass" if ok else "fail", "detail": detail})

    preamble, elements = split_body(body)
    if elements:
        last_header, last_text = elements[-1]
        last_text, sources_block = extract_sources(last_text)
        elements[-1] = (last_header, last_text)
    else:
        sources_block = None
    opening = strip_title_block(preamble)

    # S1
    gate("S1", len(elements) == 4, "%d `##` headers (want 4)" % len(elements))

    # S2
    expected = contract_headings(sections, language)
    if expected is None:
        gate("S2", False, "contract has no `%s` column in ## Headings" % language)
    else:
        actual = [h for h, _ in elements]
        gate("S2", actual == expected, "headers %s expected %s" % (actual, expected))

    # C2 / C1 need the composition
    composition = contract_composition(sections)
    has_hook = any(name.lower() == "hook" for name, _ in composition)
    element_words = [word_count(t) for _, t in elements]
    opening_words = word_count(opening)
    band_total = sum(element_words) + (opening_words if has_hook else 0)
    gate("C1", lower <= band_total <= upper,
         "body %d words, band [%d, %d] for target %d" % (band_total, lower, upper, target))

    seg_words = ([opening_words] if has_hook else []) + element_words
    seg_names = [n for n, _ in composition]
    c2_ok, c2_detail = True, []
    if len(composition) != len(seg_words):
        c2_ok = False
        c2_detail.append("composition has %d segments, narrative has %d" % (len(composition), len(seg_words)))
    else:
        for (name, prop), words in zip(composition, seg_words):
            lo, hi = prop * lower, prop * upper
            ok = lo <= words <= hi
            c2_ok = c2_ok and ok
            c2_detail.append("%s=%d[%d-%d]%s" % (name, words, lo, hi, "" if ok else "!"))
    gate("C2", c2_ok, "; ".join(c2_detail))

    # C3
    missing = [k for k in REQUIRED_FRONTMATTER if not fm.get(k)]
    arc_ok = fm.get("arc_id") == cfm.get("arc_id")
    gate("C3", not missing and arc_ok,
         "missing %s; arc_id %s vs contract %s" % (missing, fm.get("arc_id"), cfm.get("arc_id")))

    # E1 / E2 over the elements (the band), citations in the opening count too
    body_for_cites = "\n".join(t for _, t in elements)
    cites = CITATION_RE.findall(opening + "\n" + body_for_cites)
    numbers = [int(n) for n, _ in cites]
    distinct = []
    for n in numbers:
        if n not in distinct:
            distinct.append(n)
    marker_count = len(numbers)
    ceiling_ok = True if target != DEFAULT_TARGET else marker_count <= CITATION_CEILING_AT_DEFAULT
    gate("E1", marker_count >= CITATION_FLOOR and ceiling_ok,
         "%d citation markers over %d source(s) (floor %d)" % (marker_count, len(distinct), CITATION_FLOOR))
    gate("E2", distinct == list(range(1, len(distinct) + 1)),
         "first-appearance order %s" % distinct[:30])
    num_to_files, file_to_nums = {}, {}
    for n, f in cites:
        num_to_files.setdefault(int(n), set()).add(f)
        file_to_nums.setdefault(f, set()).add(int(n))
    multi_file = sorted(n for n, fs in num_to_files.items() if len(fs) > 1)
    multi_num = sorted(f for f, ns in file_to_nums.items() if len(ns) > 1)
    gate("E3", not multi_file and not multi_num,
         "numbers pointing at several files %s; files carrying several numbers %s" % (multi_file, multi_num))

    # L1
    if language == "de":
        text_lower = re.sub(r"`[^`]*`", "", body_for_cites + "\n" + opening).lower()
        hits = sorted({w for w in DE_ASCII_FALLBACKS if re.search(r"\b%s" % w, text_lower)})
        gate("L1", not hits, "ASCII fallbacks found: %s" % hits)

    # T1 / T2 — only for contracts without a Hook segment (the TL;DR contract)
    if not has_hook:
        sentences = [s for s in re.split(r"(?<=[.!?])\s+", opening.strip()) if s.strip()]
        t1_ok = TLDR_WORDS[0] <= opening_words <= TLDR_WORDS[1] and TLDR_SENTENCES[0] <= len(sentences) <= TLDR_SENTENCES[1]
        gate("T1", t1_ok, "TL;DR %d words, %d sentences (want %d-%d words, %d-%d sentences)"
             % (opening_words, len(sentences), TLDR_WORDS[0], TLDR_WORDS[1], TLDR_SENTENCES[0], TLDR_SENTENCES[1]))
        tldr_nums = {int(n) for n, _ in CITATION_RE.findall(opening)}
        body_nums = {int(n) for n, _ in CITATION_RE.findall(body_for_cites)}
        gate("T2", tldr_nums <= body_nums, "TL;DR citations %s not in body: %s" % (sorted(tldr_nums), sorted(tldr_nums - body_nums)))

    # X1 — Sources block completeness when present
    if sources_block is not None:
        entries = [int(m.group(1)) for m in (SOURCES_ENTRY_RE.match(l) for l in sources_block.splitlines()) if m]
        dup = sorted({n for n in entries if entries.count(n) > 1})
        cited = set(distinct)
        uncited = sorted(set(entries) - cited)
        dangling = sorted(cited - set(entries))
        gate("X1", not dup and not uncited and not dangling,
             "duplicates %s; uncited entries %s; cited without entry %s" % (dup, uncited, dangling))

    failed = [g["id"] for g in gates if g["status"] == "fail"]
    data = {
        "gates": gates,
        "word_count": band_total,
        "citation_count": marker_count,
        "source_count": len(distinct),
        "language": language,
        "target_length": target,
        "sources_block": sources_block is not None,
    }
    result = envelope(not failed, data, None if not failed else "gates failed: %s" % ", ".join(failed))
    if args.json:
        print(json.dumps(result, ensure_ascii=False))
    else:
        for g in gates:
            print("%s %s — %s" % ("ok" if g["status"] == "pass" else "FAIL", g["id"], g["detail"]))
        print("RESULT: %s" % ("all gates passed" if not failed else "failed " + ", ".join(failed)))
    return 0 if not failed else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
