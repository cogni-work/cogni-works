#!/usr/bin/env bash
# Test validate-entities.py's referential-integrity check for assignment refs.
#
# Covers the portfolio-directory ref check (a dangling consultant / project ref
# is an error in the {entity, file, field, message} shape), the single-file
# exemption (a single-file run stays shape-only and never ref-checks), the
# clean-portfolio path (resolvable refs report success), and the no-double-
# report guarantee (an assignment that already fails shape validation is
# excluded from the ref check rather than flagged twice).
#
# stdlib-only (bash + python3, no pytest/pip), matching the house convention.
#
# Usage: bash cogni-projects/tests/test_validate_entities.sh
# Exits non-zero on any assertion failure.

set -u

SCRIPTS_DIR="$(cd "$(dirname "$0")/../scripts" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

SCRIPTS_DIR="$SCRIPTS_DIR" WORK="$WORK" python3 - <<'PY'
import contextlib
import importlib.util
import io
import json
import os
import sys

SCRIPTS_DIR = os.environ["SCRIPTS_DIR"]
WORK = os.environ["WORK"]

# validate-entities.py is not an importable module name (hyphen), so load it by
# file location — the same idiom the script itself documents.
_spec = importlib.util.spec_from_file_location(
    "validate_entities", os.path.join(SCRIPTS_DIR, "validate-entities.py")
)
ve = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ve)

failures = 0


def check(tag, cond, detail=""):
    global failures
    if cond:
        print("PASS: " + tag)
    else:
        failures += 1
        print("FAIL: " + tag + (" — " + detail if detail else ""))


def make_portfolio(name):
    root = os.path.join(WORK, name)
    for subdir in ("consultants", "projects", "assignments"):
        os.makedirs(os.path.join(root, subdir))
    return root


def write_consultant(root, slug, name="A Consultant"):
    path = os.path.join(root, "consultants", slug + ".md")
    with open(path, "w", encoding="utf-8") as f:
        f.write(
            "---\n"
            "type: consultant\n"
            "slug: %s\n"
            "name: %s\n"
            "seniority: senior\n"
            "skills: [cloud, data]\n"
            "---\n\n# %s\n" % (slug, name, name)
        )
    return path


def write_project(root, slug, name="A Project"):
    path = os.path.join(root, "projects", slug + ".md")
    with open(path, "w", encoding="utf-8") as f:
        f.write(
            "---\n"
            "type: project\n"
            "slug: %s\n"
            "name: %s\n"
            "client: Acme\n"
            "strategic_impact: 3\n"
            "---\n\n# %s\n" % (slug, name, name)
        )
    return path


def write_assignment(root, consultant, project, role="Architect", omit=None):
    """Write an assignment file. `omit` drops a required field to force a
    shape error (used to test the no-double-report exclusion)."""
    slug = "%s--%s" % (consultant, project)
    fields = [
        ("type", "assignment"),
        ("slug", slug),
        ("consultant", consultant),
        ("project", project),
        ("role", role),
        ("start_date", "2026-01-01"),
        ("end_date", "2026-06-01"),
    ]
    path = os.path.join(root, "assignments", slug + ".md")
    with open(path, "w", encoding="utf-8") as f:
        f.write("---\n")
        for key, value in fields:
            if key == omit:
                continue
            f.write("%s: %s\n" % (key, value))
        f.write("---\n\n# %s\n" % slug)
    return path


def run(*paths):
    """Run ve.main(paths) and return the parsed envelope."""
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        ve.main(list(paths))
    return json.loads(buf.getvalue().strip().splitlines()[-1])


def ref_errors(env, field):
    return [
        e for e in env.get("data", {}).get("errors", [])
        if e.get("field") == field and "does not resolve" in e.get("message", "")
    ]


# --- (a) Directory run flags a dangling consultant AND project ref -----------
root = make_portfolio("dangling")
write_consultant(root, "ana-silva")
write_project(root, "apollo")
write_assignment(root, "ghost", "apollo")          # dangling consultant
write_assignment(root, "ana-silva", "phantom")     # dangling project
resolvable = write_assignment(root, "ana-silva", "apollo")  # both resolve

env = run(root)
check("dangling: success is False", env.get("success") is False, str(env))
c_errs = ref_errors(env, "consultant")
p_errs = ref_errors(env, "project")
check("dangling: consultant ref flagged", len(c_errs) == 1, str(c_errs))
check("dangling: consultant message names the bad slug",
      c_errs and "ghost" in c_errs[0]["message"], str(c_errs))
check("dangling: consultant error entity is assignment",
      c_errs and c_errs[0].get("entity") == "assignment", str(c_errs))
check("dangling: project ref flagged", len(p_errs) == 1, str(p_errs))
check("dangling: project message names the bad slug",
      p_errs and "phantom" in p_errs[0]["message"], str(p_errs))
# The fully-resolvable assignment produces no ref error of its own.
resolvable_errs = [
    e for e in env["data"]["errors"] if e.get("file") == resolvable
]
check("dangling: resolvable assignment has no error",
      resolvable_errs == [], str(resolvable_errs))

# --- (b) Directory run with all refs resolvable reports success --------------
clean = make_portfolio("clean")
write_consultant(clean, "bea-costa")
write_project(clean, "borealis")
write_assignment(clean, "bea-costa", "borealis")
env = run(clean)
check("clean: success is True", env.get("success") is True, str(env))
check("clean: no errors at all", env["data"]["errors"] == [], str(env["data"]["errors"]))

# --- (c) Single-file run stays shape-only: no ref check ----------------------
# The same dangling assignment, validated as a single file, must NOT ref-check
# (no portfolio-wide slug set is available) and is otherwise shape-valid.
single = make_portfolio("single")
write_consultant(single, "cid-vega")
write_project(single, "cosmos")
lone = write_assignment(single, "ghost", "cosmos")  # dangling consultant
env = run(lone)
check("single-file: success is True (no ref check)", env.get("success") is True, str(env))
check("single-file: no consultant ref error", ref_errors(env, "consultant") == [], str(env))

# --- (d) A shape-broken assignment is excluded from the ref check ------------
# An assignment missing `role` (shape error) that ALSO has a dangling consultant
# must be reported once (the missing field), never double-flagged with a ref
# error — its frontmatter is unreliable, so it is excluded from the ref pass.
mixed = make_portfolio("mixed")
write_consultant(mixed, "dana-koch")
write_project(mixed, "draco")
broken = write_assignment(mixed, "ghost", "draco", omit="role")
env = run(mixed)
check("mixed: success is False", env.get("success") is False, str(env))
role_errs = [
    e for e in env["data"]["errors"]
    if e.get("file") == broken and e.get("field") == "role"
]
check("mixed: missing-role shape error reported", len(role_errs) == 1, str(role_errs))
broken_ref_errs = [
    e for e in env["data"]["errors"]
    if e.get("file") == broken and "does not resolve" in e.get("message", "")
]
check("mixed: shape-broken assignment not double-flagged as dangling",
      broken_ref_errs == [], str(broken_ref_errs))

print()
if failures:
    print("%d check(s) failed." % failures)
    sys.exit(1)
print("All checks passed.")
PY
