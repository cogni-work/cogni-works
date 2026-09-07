# `patch-desktop-config.py` result envelope

The output contract of the config writer. This file is the single home of the shape;
`install-mcp/SKILL.md` and `manage-workspace/SKILL.md` step 5 (Init and Update) both point
here rather than restating it.

## The shape depends on the target

A **single-target** run (`--target cli` or `--target desktop`) reports a flat `data.action`
and `data.config_path`.

A **`--target both`** run reports neither at the top level — it returns `data.targets[]`,
one `{target, action, config_path, actions}` object per config. Branch on the target before
reading the envelope, or a `both` run parses as though nothing happened.

## Per-server detail lives in `actions[]`

In both shapes the per-server detail is `actions[]`. Every entry carries `server` and
`action` (`added`, `updated` or `skipped`). An `added` or `updated` entry also carries
`config_key`; only a `skipped` entry carries `reason` — so do not expect `reason` on every
entry.

The **target-level** `action` is `patched`, `noop` (nothing needed) or `dry_run`. Build
per-server summary rows from `actions[]`, never from the target-level verb: doing otherwise
collapses every server into one row and makes a `noop` read as a failure.

Take each row's action verbatim from this envelope.

## Two shapes that yield no rows at all

Neither of these returns a usable `actions[]`, and both are ordinary outcomes rather than
crashes. Render no rows rather than inventing them:

- **A `--target both` run stops at the first target it cannot write** (desktop is attempted
  first) and exits non-zero with `data.target` naming it — the other target is left
  unwritten. Do not read that as a completed run: re-invoke with `--target <the other one>`
  so the healthy config is still written, and report the failed target separately.
- **A backup that cannot be created** (permissions) exits with **no JSON envelope at all**.
  Surface the raw error rather than waiting for a payload that never comes, and re-invoke
  per-target as above.

## Backups

A timestamped backup is created before an **existing** config is modified. A first-ever
write has nothing to back up and reports `backup: null` — omit the `Backup:` row in that
case rather than rendering `Backup: None`.
