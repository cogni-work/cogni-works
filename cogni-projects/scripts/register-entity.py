#!/usr/bin/env python3
"""Register a cogni-projects entity file into its portfolio manifest.

Upserts the entity's summary ref into the matching projects-portfolio.json array
(keyed on `slug`), bumps the manifest `updated` date, and appends a transition to
.metadata/execution-log.json.

Idempotent: re-registering the same slug replaces the existing ref in place
rather than appending a second one, and reports action "updated" instead of
"created". This is what makes a re-run of the authoring skill safe.

Not transactional: the execution log and the manifest are two writes, log first.
An interrupted run is repaired by re-running — the upsert is what makes that safe.

Each individual write IS atomic: the payload is dumped to a temp file in the
target's own directory and swapped in with os.replace, so a reader sees either
the old file or the complete new one, never a truncation. Both temps are staged
before either replace, which puts the disk-full-prone step (the dump) while both
live files are untouched. That yields two distinct failure envelopes: "nothing
written" — the common case, both files byte-identical — and "log updated but
manifest not", reachable only if os.replace itself fails between the two swaps.
The mode a plain open(path, "w") would have produced is preserved across the
swap, since mkstemp would otherwise force every target to 0600.

Validates before registering, via validate-entities.py, so the manifest cannot
take an entity the validator rejects even when this script is invoked directly.
An assignment's consultant / project refs are additionally resolved against the
whole portfolio directory — the pass the validator runs only for a directory
argument, never for the single file this script hands it — so a dangling ref is
refused here rather than surfacing later as a role that silently reads unfilled.
Each unresolved ref is reported in data.errors[].

Stdlib-only (no PyYAML).

Usage:
  python3 register-entity.py <portfolio-dir> <entity-file>

Output: a single JSON line following the repo contract
  {"success": bool, "data": {...}, "error": str}
Exit: 0 ok / 1 the entity failed validation / 2 usage or environment failure.
"""

import datetime
import importlib.util
import json
import os
import sys
import tempfile

# validate-entities.py is not an importable module name (hyphens), so load it by
# file location rather than duplicating its rules here — this script must gate on
# exactly the schema the validator enforces.
_v_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "validate-entities.py")
_spec = importlib.util.spec_from_file_location("validate_entities", _v_path)
if _spec is None or _spec.loader is None:
    print(json.dumps({
        "success": False, "data": {},
        "error": "cannot load validator module: %s" % _v_path,
    }))
    sys.exit(2)
_ve = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_ve)

# The summary-ref fields each type carries into the manifest (see
# references/data-model.md "Manifest registration"). These are an editorial
# subset of the validator's `required` list — the ref is a pointer, not a copy —
# so they are named here rather than derived. The array each type registers into
# is the validator's own subdir name, so it is read from SCHEMA, not restated.
REF_FIELDS = {
    "consultant": ["slug", "name"],
    "project": ["slug", "name"],
    "assignment": ["slug", "consultant", "project"],
}


def _fail(message, code=2, data=None):
    print(json.dumps(
        {"success": False, "data": data or {}, "error": message},
        ensure_ascii=False,
    ))
    return code


def _same_file(a, b):
    """True when `a` and `b` name the same file on disk.

    Never a string compare: the ref errors carry the path _entity_files built
    from the caller's raw portfolio-dir argument, while the entity file is an
    independent raw argument, so the two spellings of one file routinely differ
    (relative vs absolute, a trailing "/.", a symlinked portfolio root).

    samefile rather than the realpath equality used for the portfolio-escape
    check below, because realpath does not case-fold: on a case-insensitive
    filesystem a case-variant path to the same file compares unequal, which
    would drop the registered entity's own ref error and let the gate fail
    OPEN — registering exactly the dangling assignment it exists to refuse.
    Comparing (st_dev, st_ino) is also correct through a hard link.

    Both paths exist whenever this is called, so the OSError branch is only a
    concurrent-unlink race; falling back keeps the helper raise-free for the
    imported-main callers the __main__ catch-all does not cover.
    """
    try:
        return os.path.samefile(a, b)
    except OSError:
        return os.path.realpath(a) == os.path.realpath(b)


def _intended_mode(path):
    """Return the mode a plain open(path, "w") would leave on `path`.

    An existing target keeps its own mode, so a re-register never widens or
    tightens permissions an operator set deliberately. A new target gets
    0o666 masked by the process umask — exactly what open(path, "w") does.
    Reading the umask requires setting it, so restore it immediately; this
    script is single-threaded, so the window is not observable.
    """
    try:
        return os.stat(path).st_mode & 0o777
    except OSError:
        cur = os.umask(0)
        os.umask(cur)
        return 0o666 & ~cur


def main(argv):
    if len(argv) != 2:
        return _fail("usage: register-entity.py <portfolio-dir> <entity-file>")

    portfolio_dir, entity_file = argv

    manifest_path = os.path.join(portfolio_dir, "projects-portfolio.json")
    if not os.path.isfile(manifest_path):
        return _fail(
            "portfolio manifest not found: %s (run /cogni-projects:projects-setup first)"
            % manifest_path
        )
    if not os.path.isfile(entity_file):
        return _fail("entity file not found: %s" % entity_file)

    # Gate on the validator rather than re-checking its rules by hand: a weaker
    # local copy would drift, and silently registering an entity the validator
    # rejects is the exact failure registration is supposed to prevent.
    errors, _warnings = _ve.validate_file(entity_file)
    if errors:
        return _fail(
            "entity failed validation (%d error(s)) — run validate-entities.py "
            "on it and fix each error before registering" % len(errors),
            code=1,
        )

    # Route through the shared reader, not a local open(): it guards
    # UnicodeDecodeError too, so a latin-1 record reports "cannot read entity
    # file" rather than the __main__ catch-all's generic message — and the
    # validate_file gate above rejecting it first stops being load-bearing.
    fm, exc = _ve.read_frontmatter(entity_file)
    if exc is not None:
        return _fail("cannot read entity file: %s" % exc)

    # `type` is required for every type and the validator errors when it
    # disagrees with the containing subdirectory, so a validated entity always
    # carries the authoritative type here.
    entity_type = fm.get("type")
    if entity_type not in REF_FIELDS:
        return _fail(
            "unknown entity type %r (expected one of %s)"
            % (entity_type, ", ".join(sorted(REF_FIELDS))),
            code=1,
        )

    # Resolve this assignment's refs against the portfolio. validate_file is
    # single-file by design and so runs no ref pass; without this, an assignment
    # naming a misspelled consultant passes the gate above, lands in the
    # manifest, and then reads as an unfilled role with no error anywhere.
    #
    # The batch must be the whole portfolio, never [entity_file]: the known-slug
    # sets are built from the consultant and project records in the batch, so a
    # single-file expansion resolves nothing and every ref would dangle. That is
    # also why this is scoped to assignments — they are the only type carrying
    # refs, and the walk is O(portfolio), so running it for a consultant or a
    # project would read every record to build a result that cannot be non-empty.
    #
    # Placed after the type is known but before the portfolio-escape check below,
    # which is harmless: an entity outside the portfolio never appears in the
    # walk, so the filter is empty and that check still raises its own error.
    # Neither helper is trusted to be raise-free, matching validate-entities.py's
    # own main(), which wraps this identical call because the envelope is the
    # contract. _entity_files' os.listdir walk is unguarded, so an unreadable
    # subdirectory raises OSError; and read_frontmatter calls parse_frontmatter
    # outside its try, so a parser fault (int() on an over-long digit scalar)
    # surfaces as ValueError. The __main__ catch-all below would convert either
    # to an envelope for CLI callers, but not for the in-process callers (the
    # test harness among them) that call main() directly — hence the guard here.
    if entity_type == "assignment":
        try:
            ref_errors = [
                e for e in _ve._ref_errors(_ve._entity_files(portfolio_dir))
                if _same_file(e["file"], entity_file)
            ]
        except Exception as exc:  # noqa: BLE001 — the envelope is the contract
            # Default code 2 (environment failure), never code 1 — the entity
            # did not fail validation; the portfolio could not be read.
            return _fail("cannot scan portfolio for refs: %s: %s"
                         % (type(exc).__name__, exc))
        if ref_errors:
            return _fail(
                "entity failed ref validation (%d error(s)) — a consultant or "
                "project ref does not resolve within this portfolio; fix each "
                "data.errors[] entry before registering" % len(ref_errors),
                code=1,
                data={"errors": ref_errors},
            )

    array_name = _ve.SCHEMA[entity_type]["subdir"]
    slug = str(fm["slug"])
    ref = {key: str(fm[key]) for key in REF_FIELDS[entity_type]}
    # The ref points at the entity file relative to the portfolio root, so the
    # dashboard and staffing skills can resolve it without knowing the cwd.
    # realpath, not abspath: abspath leaves symlinks unresolved, so an entity
    # reached through a symlinked directory would clear the check below while
    # still resolving outside the root.
    rel = os.path.relpath(os.path.realpath(entity_file), os.path.realpath(portfolio_dir))
    # Refuse an entity that lives outside the target portfolio. Validation cannot
    # catch this — a foreign entity file is itself perfectly valid — but the ref
    # would escape the root, and consumers resolve `file` relative to it, so one
    # portfolio would silently read another's records.
    if rel == os.pardir or rel.startswith(os.pardir + os.sep):
        return _fail(
            "entity file %s is not inside portfolio %s — an entity is registered "
            "only into the portfolio that holds it" % (entity_file, portfolio_dir)
        )
    ref["file"] = rel

    try:
        with open(manifest_path, "r", encoding="utf-8") as f:
            manifest = json.load(f)
    except (OSError, ValueError) as exc:
        return _fail("cannot read portfolio manifest: %s" % exc)

    array = manifest.setdefault(array_name, [])
    if not isinstance(array, list):
        return _fail("manifest %r is not a list" % array_name)

    # Upsert keyed on slug — the idempotency contract.
    index = next(
        (i for i, e in enumerate(array) if isinstance(e, dict) and e.get("slug") == slug),
        None,
    )
    if index is None:
        array.append(ref)
        action = "created"
    else:
        array[index] = ref
        action = "updated"

    today = datetime.date.today().isoformat()
    manifest["updated"] = today

    log_path = os.path.join(portfolio_dir, ".metadata", "execution-log.json")
    log = {"transitions": []}
    if os.path.isfile(log_path):
        try:
            with open(log_path, "r", encoding="utf-8") as f:
                log = json.load(f)
        except (OSError, ValueError) as exc:
            return _fail("cannot read execution log: %s" % exc)
    log.setdefault("transitions", []).append({
        "slug": slug,
        "entity_type": entity_type,
        "action": action,
        "file": ref["file"],
        "at": today,
    })

    # Write both files atomically: json.dump each to a temp file in its own
    # directory, then os.replace it over the target. A bare open(path, "w")
    # truncates in place before json.dump streams the new bytes, so a mid-write
    # failure (a full disk) leaves a half-written, unparseable file with no way
    # back — and the manifest is the portfolio's root index every consumer
    # reads. os.replace is an atomic rename on the same filesystem: either the
    # old file or the complete new file is present, never a truncation.
    #
    # Both temp files are dumped BEFORE either os.replace, so the disk-full-prone
    # step (the dump) happens while the live files are still untouched — the
    # common failure leaves both byte-identical and reports "nothing written".
    # Only the far rarer failure of os.replace itself (after both temps are on
    # disk) can leave a partial write, which the envelope names distinctly.
    # ensure_ascii=False matches portfolio-init.sh's writer: these portfolios
    # carry European names, and the repo convention forbids ASCII escapes. Log
    # first preserves the documented write order.
    #
    # The fchmod is load-bearing, not cosmetic: tempfile.mkstemp always creates
    # at 0600 regardless of umask, and os.replace carries that mode onto the
    # target. Without it these files silently tighten from the 0644 a plain
    # open(path, "w") produced before this writer existed. Applying the mode to
    # the temp fd rather than after the swap means the file is never visible at
    # 0600, not even briefly.
    targets = ((log_path, log), (manifest_path, manifest))
    tmp_paths = []
    replaced = 0
    try:
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        for path, data in targets:
            mode = _intended_mode(path)
            fd, tmp = tempfile.mkstemp(
                prefix="." + os.path.basename(path) + ".",
                suffix=".tmp",
                dir=os.path.dirname(path) or ".",
            )
            tmp_paths.append(tmp)
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
                f.write("\n")
                os.fchmod(f.fileno(), mode)
        for tmp, (path, _data) in zip(tmp_paths, targets):
            os.replace(tmp, path)
            replaced += 1
    except OSError as exc:
        # os.replace removes its source on success, so only temps that were
        # written but not yet swapped in remain — unlink them so no debris is
        # left on either the failure or the success path.
        for tmp in tmp_paths:
            if os.path.exists(tmp):
                try:
                    os.unlink(tmp)
                except OSError:
                    pass
        if replaced == 0:
            return _fail(
                "cannot write portfolio state: %s "
                "(nothing was written; existing files are intact)" % exc
            )
        return _fail(
            "portfolio state partially written: %s "
            "(the execution log was updated but the manifest was not — "
            "re-run to reconcile)" % exc
        )

    print(json.dumps({
        "success": True,
        "data": {
            "slug": slug,
            "entity_type": entity_type,
            "action": action,
            "array": array_name,
            "file": ref["file"],
            "updated": today,
        },
        "error": "",
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    # Same envelope contract as validate-entities.py: this script also writes,
    # so a hand-edited manifest of the wrong shape must report as a failure the
    # caller can read rather than a traceback mid-write.
    try:
        _code = main(sys.argv[1:])
    except Exception as _exc:  # noqa: BLE001 — deliberate catch-all
        _code = _fail("unexpected failure: %s: %s" % (type(_exc).__name__, _exc))
    sys.exit(_code)
