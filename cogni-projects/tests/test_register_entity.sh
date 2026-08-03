#!/usr/bin/env bash
# Test register-entity.py's atomic manifest + execution-log writes.
#
# Covers the atomicity contract (a mid-write failure never truncates a live
# file, and leaves no temp debris), the failure envelope's nothing-written-vs-
# partial distinction, and the happy-path / idempotency guarantees.
#
# stdlib-only (bash + python3, no pytest/pip), matching the house convention.
# The failure is simulated by monkeypatching os.replace to raise OSError —
# never `ulimit -f`, whose SIGXFSZ terminates the process before the handler
# runs and leaves the .tmp debris the contract forbids.
#
# Usage: bash cogni-projects/tests/test_register_entity.sh
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
import shutil
import sys

SCRIPTS_DIR = os.environ["SCRIPTS_DIR"]
WORK = os.environ["WORK"]

# register-entity.py is not an importable module name (hyphen), so load it by
# file location — the same idiom the script itself uses for validate-entities.py.
_spec = importlib.util.spec_from_file_location(
    "register_entity", os.path.join(SCRIPTS_DIR, "register-entity.py")
)
reg = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(reg)

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
    os.makedirs(os.path.join(root, "consultants"))
    os.makedirs(os.path.join(root, ".metadata"))
    manifest = {
        "slug": "test", "name": "Test Portfolio", "language": "en",
        "consultants": [], "projects": [], "assignments": [],
        "workflow_state": {"portfolio": "initialized"},
        "created": "2026-01-01", "updated": "2026-01-01",
    }
    with open(os.path.join(root, "projects-portfolio.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
        f.write("\n")
    return root


def make_consultant(root, slug, name):
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


def make_project(root, slug, name):
    # make_portfolio creates only consultants/ and .metadata/, so the subdir has
    # to be made here — and exist_ok because a portfolio takes several records.
    os.makedirs(os.path.join(root, "projects"), exist_ok=True)
    path = os.path.join(root, "projects", slug + ".md")
    with open(path, "w", encoding="utf-8") as f:
        f.write(
            "---\n"
            "type: project\n"
            "slug: %s\n"
            "name: %s\n"
            "client: Northwind\n"
            "strategic_impact: 4\n"
            "---\n\n# %s\n" % (slug, name, name)
        )
    return path


def make_assignment(root, consultant_ref, project_ref):
    """Write an assignment. Its refs are whatever the caller passes, so a
    dangling one is written without disturbing the records it points at."""
    os.makedirs(os.path.join(root, "assignments"), exist_ok=True)
    slug = "%s--%s" % (consultant_ref, project_ref)
    path = os.path.join(root, "assignments", slug + ".md")
    with open(path, "w", encoding="utf-8") as f:
        f.write(
            "---\n"
            "type: assignment\n"
            "slug: %s\n"
            "consultant: %s\n"
            "project: %s\n"
            "role: Lead Engineer\n"
            "start_date: 2026-02-01\n"
            "end_date: 2026-08-01\n"
            "---\n\n# %s\n" % (slug, consultant_ref, project_ref, slug)
        )
    return path


def register(root, entity_file):
    """Run register-entity.main and return (exit_code, parsed_envelope)."""
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        code = reg.main([root, entity_file])
    return code, json.loads(buf.getvalue().strip().splitlines()[-1])


def tmp_debris(root):
    seen = []
    for d in (root, os.path.join(root, ".metadata")):
        if os.path.isdir(d):
            seen += [f for f in os.listdir(d) if f.endswith(".tmp")]
    return seen


# --- Happy path: a fresh entity registers as "created" -----------------------
root = make_portfolio("happy")
ana = make_consultant(root, "ana-silva", "Ana Silva")
code, env = register(root, ana)
check("happy: success is True", env.get("success") is True, str(env))
check("happy: action is created", env.get("data", {}).get("action") == "created", str(env))
manifest = json.load(open(os.path.join(root, "projects-portfolio.json"), encoding="utf-8"))
check("happy: consultants array length 1", len(manifest["consultants"]) == 1)
check("happy: no tmp debris on success", tmp_debris(root) == [], str(tmp_debris(root)))

# --- Idempotency: re-registering the same slug flips to "updated" ------------
code, env = register(root, ana)
check("idempotency: action flips to updated", env.get("data", {}).get("action") == "updated", str(env))
manifest = json.load(open(os.path.join(root, "projects-portfolio.json"), encoding="utf-8"))
check("idempotency: array still length 1", len(manifest["consultants"]) == 1)

# --- European names round-trip without ASCII escaping ------------------------
bjoern = make_consultant(root, "bjoern-mueller", u"Björn Müller")
code, env = register(root, bjoern)
raw = open(os.path.join(root, "projects-portfolio.json"), encoding="utf-8").read()
check("encoding: umlaut stored literally", u"Björn Müller" in raw, "not found in manifest")
check("encoding: no \\u escapes in manifest", "\\u" not in raw)

# --- Failure path: os.replace raises → nothing written, no corruption --------
root2 = make_portfolio("replace-fail")
carlos = make_consultant(root2, "carlos-diaz", "Carlos Diaz")
before = open(os.path.join(root2, "projects-portfolio.json"), "rb").read()

orig_replace = os.replace


def boom(src, dst):
    raise OSError(27, "File too large")


try:
    os.replace = boom
    code, env = register(root2, carlos)
finally:
    os.replace = orig_replace

check("replace-fail: success is False", env.get("success") is False, str(env))
check(
    "replace-fail: message says nothing written",
    "nothing was written" in env.get("error", ""),
    str(env),
)
after = open(os.path.join(root2, "projects-portfolio.json"), "rb").read()
check("replace-fail: manifest byte-identical", before == after)
check("replace-fail: no tmp debris", tmp_debris(root2) == [], str(tmp_debris(root2)))
# The pre-existing manifest is still parseable — the whole point of the fix.
try:
    json.load(open(os.path.join(root2, "projects-portfolio.json"), encoding="utf-8"))
    parseable = True
except ValueError:
    parseable = False
check("replace-fail: manifest still parses", parseable)

# --- Real OSError from the filesystem: .metadata is a file, not a dir --------
root3 = make_portfolio("notadir")
dana = make_consultant(root3, "dana-koch", "Dana Koch")
shutil.rmtree(os.path.join(root3, ".metadata"))
open(os.path.join(root3, ".metadata"), "w").close()  # now a regular file
before3 = open(os.path.join(root3, "projects-portfolio.json"), "rb").read()
code, env = register(root3, dana)
check("notadir: success is False", env.get("success") is False, str(env))
after3 = open(os.path.join(root3, "projects-portfolio.json"), "rb").read()
check("notadir: manifest intact", before3 == after3)
check("notadir: no tmp debris", tmp_debris(root3) == [], str(tmp_debris(root3)))

# --- File mode is preserved across the atomic swap ---------------------------
# mkstemp always creates at 0600 and os.replace carries that mode onto the
# target, so without an explicit fchmod the manifest and log silently tighten
# from whatever a plain open(path, "w") produced. Compare against a reference
# file written the plain way under the same umask rather than hardcoding 0644,
# so the assertion holds under any umask the runner happens to use.
root4 = make_portfolio("modes")
erik = make_consultant(root4, "erik-sandoval", "Erik Sandoval")
ref_path = os.path.join(root4, ".mode-reference")
open(ref_path, "w").close()
ref_mode = os.stat(ref_path).st_mode & 0o777

code, env = register(root4, erik)
check("modes: register succeeded", env.get("success") is True, str(env))
man_mode = os.stat(os.path.join(root4, "projects-portfolio.json")).st_mode & 0o777
log_mode = os.stat(
    os.path.join(root4, ".metadata", "execution-log.json")
).st_mode & 0o777
check("modes: manifest keeps plain-open mode",
      man_mode == ref_mode, "%o != %o" % (man_mode, ref_mode))
check("modes: execution log keeps plain-open mode",
      log_mode == ref_mode, "%o != %o" % (log_mode, ref_mode))

# An operator-set mode on an existing target must survive a re-register, so the
# upsert path neither widens nor tightens permissions someone chose on purpose.
os.chmod(os.path.join(root4, "projects-portfolio.json"), 0o640)
code, env = register(root4, erik)
check("modes: upsert succeeded", env.get("success") is True, str(env))
man_mode2 = os.stat(os.path.join(root4, "projects-portfolio.json")).st_mode & 0o777
check("modes: upsert preserves the existing mode",
      man_mode2 == 0o640, "%o != 0o640" % man_mode2)

# --- Portfolio ref resolution on the write path ------------------------------
# validate_file is single-file and runs no ref pass, so before the gate an
# assignment naming a misspelled consultant registered clean and then read as an
# unfilled role. Every record below is on disk before the first register call:
# the project case only proves the gate leaves non-assignments alone if a
# dangling assignment is already sitting in the same portfolio.
root5 = make_portfolio("refs")
make_consultant(root5, "ana-silva", "Ana Silva")
proj = make_project(root5, "nordic-erp", "Nordic ERP")
# Misspelled but still kebab-valid: an underscore would fail the composite-slug
# rule and the assertions below would be measuring a shape error, not a ref one.
dangling = make_assignment(root5, "ana-silvaa", "nordic-erp")


def registered_assignments():
    with open(os.path.join(root5, "projects-portfolio.json"), encoding="utf-8") as f:
        return json.load(f)["assignments"]


# A rejected registration must leave both write targets untouched. The parsed
# assignments[] check alone is too weak: it would still pass if the manifest were
# rewritten with equivalent JSON, and it never looks at the execution log at all.
def manifest_bytes():
    with open(os.path.join(root5, "projects-portfolio.json"), "rb") as f:
        return f.read()


def transition_count():
    # No missing-file fallback on purpose: every caller runs after a successful
    # registration, so an absent log is a real regression and should raise here
    # rather than read as a legitimate count of zero.
    path = os.path.join(root5, ".metadata", "execution-log.json")
    with open(path, encoding="utf-8") as f:
        return len(json.load(f).get("transitions", []))


def check_untouched(tag, man_before, trans_before):
    """Assert a rejected registration wrote to neither the manifest nor the log."""
    trans_after = transition_count()
    check("refs: %s leaves the manifest byte-identical" % tag,
          manifest_bytes() == man_before, "manifest changed")
    check("refs: %s leaves execution-log transitions[] unchanged" % tag,
          trans_after == trans_before, "%d != %d" % (trans_after, trans_before))


code, env = register(root5, proj)
check("refs: a project still registers while a dangling assignment exists",
      env.get("success") is True, str(env))

man_before, trans_before = manifest_bytes(), transition_count()
code, env = register(root5, dangling)
errs = env.get("data", {}).get("errors", [])
assigns = registered_assignments()
check("refs: dangling consultant ref fails registration",
      env.get("success") is False and code == 1, "code=%s env=%s" % (code, env))
check("refs: the offending ref comes back in data.errors[]", len(errs) == 1, str(env))
check("refs: the error keeps the standard {entity, file, field, message} shape",
      bool(errs) and set(errs[0]) == {"entity", "file", "field", "message"}
      and errs[0]["entity"] == "assignment" and errs[0]["field"] == "consultant",
      str(errs))
check("refs: nothing was written to the manifest", assigns == [], str(assigns))
check_untouched("a dangling consultant ref", man_before, trans_before)

# The filter compares files, not path strings. Passing the portfolio as
# "<root>/." makes _entity_files emit "<root>/./assignments/..." — a string
# compare matches none of the errors, the gate fails open, the registration
# succeeds, and this goes red.
man_before, trans_before = manifest_bytes(), transition_count()
code, env = register(os.path.join(root5, "."), dangling)
assigns = registered_assignments()
check("refs: still rejected when the portfolio is passed as <root>/.",
      env.get("success") is False and code == 1 and assigns == [],
      "code=%s assignments=%s env=%s" % (code, assigns, env))
check_untouched("a non-canonical portfolio path", man_before, trans_before)

# _ref_errors loops over both ref fields, so the consultant case above exercises
# only half of it. A resolving consultant with a misspelled project covers the
# other half — and again kebab-valid, so this measures a ref error, not a shape one.
dangling_project = make_assignment(root5, "ana-silva", "nordic-erpp")
man_before, trans_before = manifest_bytes(), transition_count()
code, env = register(root5, dangling_project)
errs = env.get("data", {}).get("errors", [])
check("refs: dangling project ref fails registration",
      env.get("success") is False and code == 1, "code=%s env=%s" % (code, env))
check("refs: the dangling project is the single reported error",
      len(errs) == 1 and errs[0]["entity"] == "assignment"
      and errs[0]["field"] == "project", str(errs))
assigns = registered_assignments()
check("refs: nothing was written to the manifest for a dangling project",
      assigns == [], str(assigns))
check_untouched("a dangling project ref", man_before, trans_before)

# The dangling assignments stay on disk, so this also proves the filter reports
# only the entity being registered rather than the whole portfolio's errors.
resolving = make_assignment(root5, "ana-silva", "nordic-erp")
code, env = register(root5, resolving)
check("refs: an assignment whose refs resolve registers unaffected",
      env.get("success") is True
      and env.get("data", {}).get("action") == "created", str(env))
# Length, not just success: a duplicate append would satisfy the check above.
assigns = registered_assignments()
check("refs: the resolving assignment is registered exactly once",
      len(assigns) == 1, str(assigns))

# The ref scan walks the portfolio, so an unreadable subdirectory raises inside
# _entity_files. main() must still answer with the envelope: the __main__
# catch-all only covers CLI callers, and register() here calls main() directly —
# exactly the in-process caller that would otherwise get a traceback.
if os.geteuid() == 0:
    print("SKIP: refs: unreadable subdir (running as root — mode bits do not deny)")
else:
    os.chmod(os.path.join(root5, "consultants"), 0o000)
    try:
        code, env = register(root5, resolving)
        # code 2 (environment failure), never 1 — the entity did not fail
        # validation; the portfolio could not be read.
        check("refs: an unreadable portfolio subdir returns the envelope, not a traceback",
              env.get("success") is False and code == 2, "code=%s env=%s" % (code, env))
        check("refs: the unreadable-subdir error names the ref scan",
              "cannot scan portfolio for refs" in (env.get("error") or ""), str(env))
    except OSError as exc:
        check("refs: an unreadable portfolio subdir returns the envelope, not a traceback",
              False, "main() raised %s: %s" % (type(exc).__name__, exc))
    finally:
        os.chmod(os.path.join(root5, "consultants"), 0o755)

# The scan is not trusted to raise only OSError: read_frontmatter calls
# parse_frontmatter outside its own try, so a parser fault surfaces as
# ValueError. The envelope is the contract for every exception type, not just
# the one that happened to be found first.
_real_ref_errors = reg._ve._ref_errors
try:
    def _boom(_files):
        raise ValueError("simulated parser fault")
    reg._ve._ref_errors = _boom
    code, env = register(root5, resolving)
    check("refs: a non-OSError from the ref scan still returns the envelope",
          env.get("success") is False and code == 2, "code=%s env=%s" % (code, env))
    check("refs: the envelope names the failing exception type",
          "ValueError" in (env.get("error") or ""), str(env))
except Exception as exc:
    check("refs: a non-OSError from the ref scan still returns the envelope",
          False, "main() raised %s: %s" % (type(exc).__name__, exc))
finally:
    reg._ve._ref_errors = _real_ref_errors

print()
if failures:
    print("%d check(s) failed." % failures)
    sys.exit(1)
print("All checks passed.")
PY