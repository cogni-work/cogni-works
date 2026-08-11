"""Per-engagement field extractor for cogni-consult discover-projects.sh.

Loaded by cogni-workspace/scripts/discover-plugin-projects.sh. Must define
``extract(project_dir: str) -> dict`` returning the per-engagement JSON envelope.

cogni-consult's consult-project.json is FLAT (slug/name/language/key_question/
workflow_state/plugin_refs/updated at top level) — unlike a legacy
nested engagement{}/phases{} schema. There are no phases here: the engagement's
shape is its action fields, so the envelope carries the scope state and the
ordered action-field list instead of a phase map.

The envelope also carries ``last_activity``: the newest ``transitions[].timestamp``
in the engagement's ``.metadata/execution-log.json``, falling back to the root
``updated`` (itself already resolved to ``created`` when absent) and then to the
empty string. It is surfaced RAW — a transition-sourced
value keeps its full ISO datetime, an ``updated``-sourced value keeps its bare ISO
date — so intra-day ordering survives in the data and consumers render the date
part themselves. Precomputing it here means a consumer sorts on discovery output
instead of reopening every engagement's log.
"""

import json
import os


def extract(d: str) -> dict:
    project = {"path": d, "slug": os.path.basename(d)}

    pf = os.path.join(d, "consult-project.json")
    if os.path.exists(pf):
        try:
            with open(pf) as f:
                data = json.load(f)
            project["slug"] = data.get("slug", project["slug"])
            project["name"] = data.get("name", "")
            project["language"] = data.get("language", "en")
            project["key_question"] = data.get("key_question", "")
            project["action_fields"] = data.get("action_fields", [])
            project["scope_state"] = (data.get("workflow_state") or {}).get(
                "scope", "pending"
            )
            project["plugin_refs"] = data.get("plugin_refs", {})
            project["updated"] = data.get("updated", data.get("created", ""))
        except Exception:
            pass

    # Own try/except, at function scope: a corrupt log must not strip the fields
    # the block above already resolved, and the key must exist on the path where
    # consult-project.json is absent entirely.
    log = os.path.join(d, ".metadata", "execution-log.json")
    stamps = []
    try:
        with open(log) as f:
            entries = json.load(f).get("transitions", [])
        if isinstance(entries, list):
            stamps = [
                t["timestamp"]
                for t in entries
                if isinstance(t, dict)
                and isinstance(t.get("timestamp"), str)
                and t["timestamp"]
            ]
    except Exception:
        pass
    # max(), not stamps[-1]: the log is append-ordered only by convention, so a
    # hand-edited or merged log can carry its newest entry in any position.
    project["last_activity"] = max(stamps) if stamps else project.get("updated", "")

    return project
