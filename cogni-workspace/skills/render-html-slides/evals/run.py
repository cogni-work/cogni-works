#!/usr/bin/env python3
"""evals/run.py — Regression eval for render-html-slides.

Stdlib-only. Every case runs end-to-end against the real
``generate-html-slides.py`` script; ``main()``'s ``cases`` list is the
authoritative roster. The Theme System v2 cases are:

1. **Tier-0 baseline (regression).** No ``--theme-slug`` flag. Asserts the
   rendered HTML contains the inline ``:root`` token block and does NOT
   contain an ``@import url(...tokens.css)`` line. This is the well-tested
   default code path — it runs on every legacy invocation.

2. **Tier-1 tokens.css import.** ``--theme-slug cogni-work`` against the
   real ``cogni-workspace/themes/cogni-work`` (which declares
   ``tiers.tokens`` and has ``tokens/tokens.css`` on disk). Asserts the
   rendered HTML contains an ``@import url('file://.../cogni-work/tokens/tokens.css')``
   line ahead of the inline ``:root`` block.

3. **Tier-0 theme with --theme-slug (graceful fallback).** ``--theme-slug
   _template`` against the manifestless ``_template`` theme. Asserts the
   rendered HTML behaves exactly like case (1) — the missing manifest is a
   normal control-flow signal that triggers the fallback path. This is
   also the well-tested code path that runs whenever a theme without
   ``tiers.tokens`` is selected (so today, every cogni-work consumer that
   passes ``--theme-slug cogni-work`` falls into case 2; every legacy
   caller falls into case 1; this case 3 is the documented behavior for
   in-between themes that haven't migrated yet).

Exit code 0 on all-pass, 1 on any failure. Prints a JSON results envelope
on stdout for machine consumption.
"""

import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path


HERE = Path(__file__).resolve().parent
SKILL_DIR = HERE.parent
SCRIPT = SKILL_DIR / "scripts" / "generate-html-slides.py"
PLUGIN_ROOT = SKILL_DIR.parent.parent  # cogni-visual/
REPO_ROOT = PLUGIN_ROOT.parent  # insight-wave/
THEMES_DIR = REPO_ROOT / "cogni-workspace" / "themes"


MINIMAL_SLIDE_DATA = {
    "metadata": {
        "title": "Eval Deck",
        "customer": "Test",
        "provider": "Test",
        "generated": "2026-04-25",
    },
    "slides": [
        {
            "number": 1,
            "layout": "title-slide",
            "headline": "Phase 2 Pilot",
            "fields": {"Subtitle": "Theme System v2"},
        },
        {
            "number": 2,
            "layout": "generic",
            "headline": "Tier-1 Tokens",
            "bullets": ["tokens.css imports cleanly", "Inline :root provides fallbacks"],
            "fields": {},
        },
    ],
}


def run_render(theme_slug=None, themes_dir=None, slide_data=None, language=None):
    """Invoke generate-html-slides.py. Returns the rendered HTML body as a
    string and the JSON status the script printed.

    Defaults to ``MINIMAL_SLIDE_DATA``; pass ``slide_data`` to render a
    different deck.
    """
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        slide_data_path = tmp / "slide-data.json"
        output_path = tmp / "out.html"
        payload = MINIMAL_SLIDE_DATA if slide_data is None else slide_data
        slide_data_path.write_text(json.dumps(payload), encoding="utf-8")

        cmd = [
            sys.executable,
            str(SCRIPT),
            "--slide-data", str(slide_data_path),
            "--output", str(output_path),
        ]
        if theme_slug:
            cmd += ["--theme-slug", theme_slug]
        if themes_dir:
            cmd += ["--themes-dir", str(themes_dir)]
        if language:
            cmd += ["--language", language]

        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            return None, {"error": proc.stderr or proc.stdout}
        try:
            status = json.loads(proc.stdout.strip().splitlines()[-1])
        except (json.JSONDecodeError, IndexError):
            status = {"raw": proc.stdout}
        html = output_path.read_text(encoding="utf-8")
        return html, status


def assert_substring(name, html, needle, present=True):
    found = needle in html
    if found != present:
        verb = "missing" if present else "unexpectedly present"
        return False, "{}: {} substring '{}'".format(name, verb, needle[:80])
    return True, None


def case_1_tier0_baseline():
    html, status = run_render(theme_slug=None)
    if html is None:
        return False, "case 1: render failed: {}".format(status.get("error"))
    checks = [
        assert_substring("case 1", html, "@import url('file://", present=False),
        assert_substring("case 1", html, "tokens.css", present=False),
        assert_substring("case 1", html, ":root", present=True),
        assert_substring("case 1", html, "--primary:", present=True),
    ]
    failures = [msg for ok, msg in checks if not ok]
    if status.get("tokens_css_imported") is True:
        failures.append("case 1: status reported tokens_css_imported=true on legacy invocation")
    if status.get("theme_slug_resolution") is not None:
        failures.append("case 1: theme_slug_resolution={} (expected None with no --theme-slug)".format(status.get("theme_slug_resolution")))
    return len(failures) == 0, failures


def case_2_tier1_cogni_work():
    cogni_work = THEMES_DIR / "cogni-work"
    if not (cogni_work / "manifest.json").is_file() or not (cogni_work / "tokens" / "tokens.css").is_file():
        return False, ["case 2: cogni-work tier-1 layout missing on disk — phase-1 deps not merged?"]
    html, status = run_render(theme_slug="cogni-work", themes_dir=THEMES_DIR)
    if html is None:
        return False, ["case 2: render failed: {}".format(status.get("error"))]
    expected_import = "@import url('file://{}/cogni-work/tokens/tokens.css'".format(THEMES_DIR.resolve())
    checks = [
        assert_substring("case 2", html, expected_import, present=True),
        assert_substring("case 2", html, ":root", present=True),
    ]
    failures = [msg for ok, msg in checks if not ok]
    if status.get("tokens_css_imported") is not True:
        failures.append("case 2: status reported tokens_css_imported={} (expected true)".format(status.get("tokens_css_imported")))
    if status.get("theme_slug_resolution") != "imported":
        failures.append("case 2: theme_slug_resolution={} (expected 'imported')".format(status.get("theme_slug_resolution")))
    return len(failures) == 0, failures


def case_3_tier0_theme_with_slug():
    template = THEMES_DIR / "_template"
    if not template.is_dir():
        return False, ["case 3: _template theme missing on disk"]
    if (template / "manifest.json").is_file():
        return False, ["case 3: _template unexpectedly has a manifest.json — graceful-fallback case is invalid"]
    html, status = run_render(theme_slug="_template", themes_dir=THEMES_DIR)
    if html is None:
        return False, ["case 3: render failed: {}".format(status.get("error"))]
    checks = [
        assert_substring("case 3", html, "@import url('file://", present=False),
        assert_substring("case 3", html, ":root", present=True),
    ]
    failures = [msg for ok, msg in checks if not ok]
    if status.get("tokens_css_imported") is True:
        failures.append("case 3: status reported tokens_css_imported=true (expected false — fallback path)")
    if status.get("theme_slug_resolution") != "manifest_missing":
        failures.append("case 3: theme_slug_resolution={} (expected 'manifest_missing')".format(status.get("theme_slug_resolution")))
    return len(failures) == 0, failures


def case_4_themes_dir_unresolved():
    """The actual #241 footgun: --theme-slug set but the themes dir can't be
    resolved (here forced via a bogus --themes-dir, which resolve_themes_dir
    rejects → None). Asserts the fallback is taken AND the diagnostic names
    it: theme_slug_resolution is the bare code "themes_dir_unresolved" and the
    companion detail field carries the human hint."""
    html, status = run_render(theme_slug="cogni-work", themes_dir="/nonexistent/bogus-themes-dir")
    if html is None:
        return False, ["case 4: render failed: {}".format(status.get("error"))]
    checks = [
        assert_substring("case 4", html, "@import url('file://", present=False),
        assert_substring("case 4", html, ":root", present=True),
    ]
    failures = [msg for ok, msg in checks if not ok]
    if status.get("tokens_css_imported") is True:
        failures.append("case 4: status reported tokens_css_imported=true (expected false — workspace unresolved)")
    if status.get("theme_slug_resolution") != "themes_dir_unresolved":
        failures.append("case 4: theme_slug_resolution={} (expected bare code 'themes_dir_unresolved')".format(status.get("theme_slug_resolution")))
    if not (status.get("theme_slug_resolution_detail") or ""):
        failures.append("case 4: theme_slug_resolution_detail missing (expected the workspace hint)")
    return len(failures) == 0, failures


PARSER = PLUGIN_ROOT / "scripts" / "parse-brief.py"
EXAMPLE_BRIEF = PLUGIN_ROOT / "libraries" / "EXAMPLE_BRIEF.md"


def want_in_section(failures, label, html, number, needle, present=True, why=""):
    """Assert a substring is (or is not) inside one slide's section."""
    section = _slide_section(html, number)
    if (needle in section) != present:
        failures.append("{}: slide {}: {} {!r}{}".format(
            label, number,
            "missing" if present else "unexpectedly present",
            needle,
            " ({})".format(why) if why else ""))


def _slide_section(html, number):
    """The markup of one ``<section class="slide" data-slide="N">`` block."""
    marker = 'data-slide="{}"'.format(number)
    start = html.find(marker)
    if start == -1:
        return ""
    end = html.find("</section>", start)
    return html[start:end if end != -1 else len(html)]


def case_5_example_brief_end_to_end():
    """Render the real producer fixture through the real parser.

    Asserts by shape, so a producer/renderer field mismatch fails loudly here
    instead of rendering blank cards the way it does today.
    """
    failures = []
    if not PARSER.exists() or not EXAMPLE_BRIEF.exists():
        return False, ["case 5: missing parser or fixture ({} / {})".format(PARSER, EXAMPLE_BRIEF)]

    def emit(mode):
        proc = subprocess.run(
            [sys.executable, str(PARSER), "--brief", str(EXAMPLE_BRIEF), "--emit", mode],
            capture_output=True, text=True,
        )
        try:
            return json.loads(proc.stdout)
        except json.JSONDecodeError:
            return {"success": False, "error": proc.stderr or proc.stdout}

    sd_env = emit("slide-data")
    md_env = emit("metadata")
    if not sd_env.get("success"):
        return False, ["case 5: --emit slide-data failed: {}".format(sd_env.get("error"))]
    if not md_env.get("success"):
        return False, ["case 5: --emit metadata failed: {}".format(md_env.get("error"))]

    slides = sd_env["data"]["slides"]

    # Slide count must equal the fixture's own heading count — derived, never hardcoded.
    brief_text = EXAMPLE_BRIEF.read_text(encoding="utf-8")
    heading_count = len(re.findall(r"^## Slide", brief_text, re.MULTILINE))
    if len(slides) != heading_count:
        failures.append("case 5: parsed {} slides, brief has {} '## Slide' headings".format(
            len(slides), heading_count))

    # Assemble metadata exactly as SKILL.md Phase 1 states.
    fm = md_env["data"].get("frontmatter", {}) or {}
    first = slides[0]["fields"] if slides else {}
    slide_data = {
        "metadata": {
            "title": first.get("Title") or (slides[0].get("headline") if slides else ""),
            "subtitle": first.get("Subtitle", ""),
            "customer": fm.get("customer", ""),
            "provider": fm.get("provider", ""),
            "generated": fm.get("generated", ""),
        },
        "slides": slides,
    }
    html, status = run_render(slide_data=slide_data, language=fm.get("language") or "de")
    if html is None:
        return False, ["case 5: render failed: {}".format(status.get("error"))]
    if status.get("status") != "ok":
        failures.append("case 5: renderer status={} (expected ok)".format(status.get("status")))

    # The Buying Center slide: four quadrant cards, each carrying a real label.
    buying = next((s for s in slides if "Quadrant-1" in s.get("fields", {})
                   or "Q1" in s.get("fields", {})), None)
    if buying is None:
        failures.append("case 5: no quadrant slide found in the parsed fixture")
    else:
        section = _slide_section(html, buying.get("number"))
        if section.count('class="quad-card"') != 4:
            failures.append("case 5: buying-center slide rendered {} quad-card(s), expected 4".format(
                section.count('class="quad-card"')))
        if section.count('class="quad-label"') != 4:
            failures.append("case 5: buying-center slide rendered {} non-empty quad-label(s), expected 4".format(
                section.count('class="quad-label"')))

    # The closing slide's Subtitle must reach the page.
    closing = next((s for s in slides if s.get("layout") == "closing-slide"), None)
    if closing is None:
        failures.append("case 5: no closing-slide found in the parsed fixture")
    else:
        subtitle = closing["fields"].get("Subtitle", "")
        # Pinned: without this the check below no-ops the moment the producer
        # stops emitting Subtitle at all, which is the regression it guards.
        if not subtitle:
            failures.append("case 5: closing slide carries no Subtitle — the fixture must parse one")
        elif subtitle not in html:
            failures.append("case 5: closing subtitle {!r} absent from the render".format(subtitle))

    # One source footer per Source-carrying slide, each an actual link.
    with_source = [s for s in slides if s.get("source") or s.get("fields", {}).get("Source")]
    # Pinned: a bare count comparison comes out 0 == 0 and passes when the
    # producer emits no Source at all, so require the fixture to carry some.
    if len(with_source) < 2:
        failures.append("case 5: {} Source-carrying slide(s) parsed, expected at least 2".format(
            len(with_source)))
    if html.count('class="source-footer') != len(with_source):
        failures.append("case 5: {} source footer(s) for {} Source-carrying slide(s)".format(
            html.count('class="source-footer'), len(with_source)))
    for s in with_source:
        section = _slide_section(html, s.get("number"))
        if "source-footer" in section and "<a href" not in section:
            failures.append("case 5: slide {} source footer has no anchor (escaped instead of linked)".format(
                s.get("number")))

    # Badges come from each box's Label even though the deck is German.
    idm = next((s for s in slides if s.get("layout") == "is-does-means"), None)
    if idm is not None:
        section = _slide_section(html, idm.get("number"))
        for box in ("IS-Box", "DOES-Box", "MEANS-Box"):
            label = (idm["fields"].get(box) or {}).get("Label")
            if label:
                want_in_section(
                    failures, "case 5", html, idm.get("number"),
                    '<span class="idm-badge">{}</span>'.format(label),
                    why="{} badge is not the authored Label".format(box))

    # Falsifier for the guarded slide_kind routing: a slide declaring
    # Slide-Kind: references with no References payload must KEEP its own
    # layout. Without this an unconditional override would still pass above.
    for s in slides:
        f = s.get("fields", {})
        kind = s.get("slide_kind") or f.get("Slide-Kind")
        if kind == "references" and not (f.get("References") or f.get("Citations")):
            section = _slide_section(html, s.get("number"))
            if 'data-layout="{}"'.format(s.get("layout")) not in section:
                failures.append(
                    "case 5: slide {} was rerouted to the references renderer despite carrying "
                    "no References/Citations payload".format(s.get("number")))
            for col in ("Left-Column", "Right-Column"):
                for bullet in (f.get(col) or {}).get("Bullets", []):
                    if bullet.split(" ")[0] not in section:
                        failures.append(
                            "case 5: slide {} lost {} content on routing".format(s.get("number"), col))

    return len(failures) == 0, failures


def case_6_field_aliases_direct():
    """Prove the renderer-side aliases on slide-data the parser never touched.

    This case exists because ``parse-brief.py`` normalizes ``Q{n}`` to
    ``Quadrant-{n}`` upstream, so an end-to-end assertion renders four
    populated cards with or without the renderer change — a vacuous green.
    Building the slide-data here is what lets these assertions actually fail.
    """
    slide_data = {
        "metadata": {"title": "Alias Deck", "customer": "C", "provider": "P", "generated": "2026-01-01"},
        "slides": [
            {"number": 1, "layout": "four-quadrants", "headline": "Q alias",
             "fields": {"Q{}".format(i): {"Label": "QL{}".format(i), "Bullets": ["qb{}".format(i)]}
                        for i in range(1, 5)}},
            {"number": 2, "layout": "four-quadrants", "headline": "canonical wins",
             "fields": {"Quadrant-1": {"Label": "CANON", "Bullets": ["x"]},
                        "Q1": {"Label": "ALIAS", "Bullets": ["y"]}}},
            {"number": 3, "layout": "closing-slide", "headline": "closing new",
             "fields": {"Title": "NEWHEAD", "Subtitle": "NEWSUB", "Metadata": "NEWMETA"}},
            {"number": 4, "layout": "closing-slide", "headline": "closing old wins",
             "fields": {"Headline": "OLDHEAD", "Title": "NEWHEAD2",
                        "Key-Takeaway": "OLDTAKE", "Subtitle": "NEWSUB2",
                        "CTA": "OLDCTA", "Metadata": "NEWMETA2"}},
            {"number": 5, "layout": "three-options", "headline": "options new",
             "fields": {"Option-1": {"Name": "OPTNAME", "Price": "OPTPRICE",
                                     "Badge": "BADGETEXT", "Features": ["feat-a"]},
                        "Option-2": {"Name": "PLAIN", "Price": "P2", "Features": ["feat-b"]}}},
            {"number": 6, "layout": "timeline-steps", "headline": "steps new",
             "fields": {"Step-1": {"Number": "01", "Label": "STEPLABEL",
                                   "Description": "STEPDESC", "Duration": "STEPDUR"}}},
            {"number": 7, "layout": "is-does-means", "headline": "idm label",
             "fields": {"IS-Box": {"Label": "CUSTOMIS", "Text": "t1"},
                        "DOES-Box": {"Label": "CUSTOMDOES", "Text": "t2"},
                        "MEANS-Box": {"Label": "CUSTOMMEANS", "Text": "t3"}}},
            {"number": 8, "layout": "two-columns-equal", "headline": "refs with payload",
             "slide_kind": "references",
             "fields": {"Slide-Kind": "references",
                        "References": ["REFONE", "REFTWO"]}},
            {"number": 9, "layout": "two-columns-equal", "headline": "refs without payload",
             "slide_kind": "references",
             "fields": {"Slide-Kind": "references",
                        "Left-Column": {"Headline": "LCOL", "Bullets": ["LEFTBULLET"]},
                        "Right-Column": {"Headline": "RCOL", "Bullets": ["RIGHTBULLET"]}}},
            {"number": 10, "layout": "two-columns-equal", "headline": "LONGHEADLINE",
             "fields": {"Slide-Title": "SHORTTITLE",
                        "Left-Column": {"Headline": "L", "Bullets": ["b"]},
                        "Right-Column": {"Headline": "R", "Bullets": ["c"]}}},
            {"number": 11, "layout": "unknown-layout-kind", "headline": "generic",
             "fields": {"intent": "INTENTVAL", "visual": "VISUALVAL", "cta": "CTAVAL",
                        "Slide-Kind": "KINDVAL", "Source": "SOURCEVAL",
                        "Slide-Title": "TITLEVAL", "Real": "REALVAL"}},
            {"number": 12, "layout": "two-columns-equal", "headline": "source link",
             "fields": {"Source": "[SRCTEXT](https://example.invalid/doc)",
                        "Left-Column": {"Headline": "L", "Bullets": ["b"]},
                        "Right-Column": {"Headline": "R", "Bullets": ["c"]}}},
            # Slide 6 covers only the Step-N map shape; the Steps[] list form is
            # the other live shape and was untested.
            {"number": 13, "layout": "timeline-steps", "headline": "steps list form",
             "fields": {"Steps": [{"Title": "LISTSTEPA", "Detail": "LISTDETA",
                                   "Bullets": ["listbullet-a"]},
                                  {"Title": "LISTSTEPB", "Detail": "LISTDETB"}]}},
            # Slide 6 uses Label; Title is the older name that must win over it.
            {"number": 14, "layout": "timeline-steps", "headline": "steps old name wins",
             "fields": {"Step-1": {"Number": "02", "Title": "OLDSTEPTITLE",
                                   "Label": "NEWSTEPLABEL", "Detail": "OLDSTEPDETAIL",
                                   "Duration": "NEWSTEPDUR"}}},
            # Slide 7 tests only the Label-wins direction of the badge contract.
            # With no Label anywhere, --language de must supply the defaults.
            {"number": 15, "layout": "is-does-means", "headline": "idm no label",
             "fields": {"IS-Box": {"Text": "nolabel-is"},
                        "DOES-Box": {"Text": "nolabel-does"},
                        "MEANS-Box": {"Text": "nolabel-means"}}},
        ],
    }
    # German, so a badge falling back to --language would read IST/MACHT/BEDEUTET.
    html, status = run_render(slide_data=slide_data, language="de")
    if html is None:
        return False, ["case 6: render failed: {}".format(status.get("error"))]

    failures = []

    def want(number, needle, present=True, why=""):
        want_in_section(failures, "case 6", html, number, needle, present, why)

    # Q1..Q4 accepted — the assertion the end-to-end case cannot make.
    s1 = _slide_section(html, 1)
    if s1.count('class="quad-card"') != 4:
        failures.append("case 6: literal Q1..Q4 rendered {} quad-card(s), expected 4".format(
            s1.count('class="quad-card"')))
    for i in range(1, 5):
        want(1, "QL{}".format(i), why="Q{} alias not read".format(i))

    # Canonical Quadrant-N keeps precedence over the Q-alias.
    want(2, "CANON")
    want(2, "ALIAS", present=False, why="alias must not override the canonical name")

    # Closing slide reaches the producer's Subtitle/Metadata...
    want(3, "NEWSUB")
    want(3, "NEWMETA")
    # ...while the old names still win when both are present.
    want(4, "OLDTAKE")
    want(4, "NEWSUB2", present=False, why="old name must keep precedence")
    want(4, "OLDCTA")
    want(4, "NEWMETA2", present=False, why="old name must keep precedence")

    # Three options: producer names, and a non-empty Badge means recommended.
    want(5, "OPTNAME")
    want(5, "OPTPRICE")
    want(5, "feat-a")
    want(5, "BADGETEXT")
    if _slide_section(html, 5).count("option-recommended") != 1:
        failures.append("case 6: expected exactly one option-recommended card on slide 5")

    # Every Step-N sub-field reaches the output.
    for needle in ("01", "STEPLABEL", "STEPDESC", "STEPDUR"):
        want(6, needle)

    # The Steps[] list form is the other live shape and must render the same slots.
    for needle in ("LISTSTEPA", "LISTDETA", "listbullet-a", "LISTSTEPB", "LISTDETB"):
        want(13, needle)
    # Within a Step-N map the older Title/Detail win over Label/Duration.
    want(14, "OLDSTEPTITLE")
    want(14, "NEWSTEPLABEL", present=False, why="Title must keep precedence over Label")
    want(14, "OLDSTEPDETAIL")
    want(14, "NEWSTEPDUR", present=False, why="Detail must keep precedence over Duration")

    # The authored badge beats the --language default.
    for needle in ("CUSTOMIS", "CUSTOMDOES", "CUSTOMMEANS"):
        want(7, needle)
    want(7, "IST", present=False, why="--language fallback must not override an authored Label")
    # ...and the untested direction: with no Label at all, --language de supplies them.
    for needle in ("IST", "MACHT", "BEDEUTET"):
        want(15, needle, why="Label-less box must fall back to the --language default badge")

    # slide_kind routing: WITH a payload it routes...
    want(8, "references-list")
    want(8, "REFONE")
    # ...and WITHOUT one it must not, or the column content is destroyed.
    want(9, "LEFTBULLET", why="content dropped by an unguarded slide_kind reroute")
    want(9, "RIGHTBULLET", why="content dropped by an unguarded slide_kind reroute")
    want(9, "references-list", present=False, why="rerouted with no References payload")

    # Slide-Title overrides the long assertion headline.
    want(10, "SHORTTITLE")
    want(10, "LONGHEADLINE", present=False, why="Slide-Title must win over the H2 headline")

    # Non-content keys are suppressed by the generic fallback renderer. The
    # test is the labelled-paragraph form that renderer emits — not the bare
    # value, because two of the six legitimately reach the page by another
    # route: Slide-Title becomes the H2, and Source becomes the footer.
    for key in ("intent", "visual", "cta", "Slide-Kind", "Source", "Slide-Title"):
        want(11, "<strong>{}:</strong>".format(key), present=False,
             why="non-content key leaked into the generic slide body")
    for needle in ("INTENTVAL", "VISUALVAL", "CTAVAL", "KINDVAL"):
        want(11, needle, present=False, why="non-content value leaked into the slide body")
    want(11, "<strong>Real:</strong>", why="a genuine content field must still render")
    want(11, "REALVAL", why="a genuine content field must still render")
    # The two that do have another home land there, and only there.
    want(11, "SHORTTITLE", present=False)
    want(11, "TITLEVAL", why="Slide-Title supplies the H2")
    want(11, "SOURCEVAL", why="Source supplies the footer")

    # A Source renders as a real link, not escaped markdown.
    want(12, '<a href="https://example.invalid/doc"')
    want(12, "[SRCTEXT]", present=False, why="markdown link was escaped instead of converted")

    return len(failures) == 0, failures


def main():
    cases = [
        ("tier-0 baseline (regression)", case_1_tier0_baseline),
        ("tier-1 cogni-work tokens.css", case_2_tier1_cogni_work),
        ("tier-0 _template with --theme-slug (graceful fallback)", case_3_tier0_theme_with_slug),
        ("themes_dir_unresolved diagnostic (#241 footgun)", case_4_themes_dir_unresolved),
        ("EXAMPLE_BRIEF end-to-end through parse-brief.py", case_5_example_brief_end_to_end),
        ("renderer field aliases on direct slide-data", case_6_field_aliases_direct),
    ]
    results = []
    failed = 0
    for name, fn in cases:
        ok, detail = fn()
        results.append({
            "name": name,
            "passed": ok,
            "details": detail if not ok else None,
        })
        if not ok:
            failed += 1

    envelope = {
        "passed": failed == 0,
        "total": len(cases),
        "failed": failed,
        "results": results,
    }
    print(json.dumps(envelope, indent=2))
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
