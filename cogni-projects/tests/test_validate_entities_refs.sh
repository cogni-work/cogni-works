#!/usr/bin/env bash
# Test validate-entities.py's assignment referential-integrity pass.
#
# Covers the invocation-shape gate that pass hangs on: a portfolio directory
# resolves each assignment's consultant / project against the records collected
# from that same directory, while a single file argument — which carries no
# portfolio-wide collection — keeps its shape-only behaviour. The single-file
# case is the regression guard for projects-entities Step 4 and for
# register-entity.py, which both hand the validator one file at a time.
#
# stdlib-only (bash + python3, no pytest/pip), matching the house convention.
# The script is exercised through main() rather than a subprocess so a failing
# assertion reports the parsed envelope, not a shell exit code.
#
# Usage: bash cogni-projects/tests/test_validate_entities_refs.sh
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
# file location — the same idiom the script itself uses across the plugin.
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


def write(path, frontmatter):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    lines = ["---"]
    for key, value in frontmatter.items():
        lines.append("%s: %s" % (key, value))
    lines.extend(["---", "", "Notes.", ""])
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


PROJECT = "apollo-migration"


def make_portfolio(name, consultant_ref):
    """Seed a portfolio whose assignment points at the given consultant slug."""
    root = os.path.join(WORK, name)
    os.makedirs(root, exist_ok=True)
    with open(os.path.join(root, "projects-portfolio.json"), "w",
              encoding="utf-8") as f:
        json.dump({"slug": name}, f)
    write(os.path.join(root, "consultants", "ada-lovelace.md"), {
        "type": "consultant", "slug": "ada-lovelace", "name": "Ada Lovelace",
        "seniority": "senior", "skills": "[python, analysis]",
    })
    write(os.path.join(root, "projects", "%s.md" % PROJECT), {
        "type": "project", "slug": PROJECT, "name": "Apollo Migration",
        "client": "Apollo GmbH", "strategic_impact": "4",
    })
    assignment = os.path.join(root, "assignments",
                              "%s--%s.md" % (consultant_ref, PROJECT))
    write(assignment, {
        "type": "assignment", "slug": "%s--%s" % (consultant_ref, PROJECT),
        "consultant": consultant_ref, "project": PROJECT,
        "role": "Tech Lead", "start_date": "2026-01-05",
        "end_date": "2026-06-30",
    })
    return root, assignment


def run(*paths):
    """Invoke main() on paths, returning (exit_code, parsed envelope)."""
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        code = ve.main(list(paths))
    return code, json.loads(buf.getvalue())


def ref_errors(envelope):
    return [e for e in envelope["data"]["errors"]
            if e["field"] in ("consultant", "project")]


# --- 1. Directory invocation: every ref resolves -------------------------
root, _ = make_portfolio("clean", "ada-lovelace")
code, env = run(root)
check("clean portfolio validates", env["success"] is True and code == 0,
      json.dumps(env["data"]["errors"]))

# --- 2. Directory invocation: dangling consultant ref --------------------
root, assignment = make_portfolio("dangling", "grace-hopper")
code, env = run(root)
errs = ref_errors(env)
check("dangling consultant fails the run",
      env["success"] is False and code == 1, json.dumps(env))
check("exactly one ref error", len(errs) == 1, json.dumps(errs))
if errs:
    e = errs[0]
    check("ref error carries the standard four keys",
          set(e) == {"entity", "file", "field", "message"}, json.dumps(e))
    check("ref error names the assignment and the offending field",
          e["entity"] == "assignment" and e["field"] == "consultant"
          and e["file"] == assignment, json.dumps(e))
    check("ref error message names the unresolved value",
          "grace-hopper" in e["message"], e["message"])

# --- 3. Single-file invocation on the SAME dangling assignment -----------
# The guard for projects-entities Step 4 and register-entity.py: with no
# portfolio-wide collection there is nothing to resolve against, so the file
# must still validate clean.
code, env = run(assignment)
check("single-file invocation runs no ref check",
      env["success"] is True and code == 0, json.dumps(env["data"]["errors"]))

# --- 4. Refs never resolve across two portfolios in one invocation -------
a_root, _ = make_portfolio("portfolio-a", "grace-hopper")
b_root, _ = make_portfolio("portfolio-b", "ada-lovelace")
write(os.path.join(b_root, "consultants", "grace-hopper.md"), {
    "type": "consultant", "slug": "grace-hopper", "name": "Grace Hopper",
    "seniority": "principal", "skills": "[compilers]",
})
_, env = run(a_root, b_root)
check("a ref existing only in the sibling portfolio still dangles",
      len(ref_errors(env)) == 1, json.dumps(ref_errors(env)))

# --- 5. A shape-invalid entity does not cascade dangling-ref errors ------
root, _ = make_portfolio("shape-broken", "ada-lovelace")
write(os.path.join(root, "consultants", "ada-lovelace.md"), {
    "type": "consultant", "slug": "Ada_Lovelace", "name": "Ada Lovelace",
    "seniority": "senior", "skills": "[python]",
})
_, env = run(root)
check("shape-invalid consultant slug is reported once, not as a dangling ref",
      ref_errors(env) == [], json.dumps(ref_errors(env)))
check("the shape error itself is still reported",
      any(e["field"] == "slug" for e in env["data"]["errors"]),
      json.dumps(env["data"]["errors"]))

# --- 5b. A VALID slug is not also resolvable by its filename -------------
# The stem is admitted only to stop a broken record from cascading. Every
# consumer matches on the slug, so a ref naming the file of a well-formed
# record must still dangle rather than pass and later read as zero coverage.
root, _ = make_portfolio("stem-not-alias", "a-lovelace")
_, env = run(root)
check("a ref naming the filename of a valid-slug record still dangles",
      len(ref_errors(env)) == 1, json.dumps(ref_errors(env)))

# --- 6. A missing ref is a required-key error, not a duplicate ------------
root, _ = make_portfolio("missing-ref", "ada-lovelace")
write(os.path.join(root, "assignments", "ada-lovelace--%s.md" % PROJECT), {
    "type": "assignment", "slug": "ada-lovelace--%s" % PROJECT,
    "project": PROJECT, "role": "Tech Lead",
    "start_date": "2026-01-05", "end_date": "2026-06-30",
})
_, env = run(root)
consultant_errs = [e for e in env["data"]["errors"] if e["field"] == "consultant"]
check("an absent consultant ref is reported exactly once",
      len(consultant_errs) == 1, json.dumps(consultant_errs))

print()
if failures:
    print("%d assertion(s) failed" % failures)
    sys.exit(1)
print("all assertions passed")
PY
