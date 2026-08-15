# Known Issues

Maintained list of diagnosed problems and their fixes. Add new entries as patterns emerge.

---

## Leftover course-progress file

**Symptom**: `.claude/cogni-teacher.local.md` or `.claude/cogni-help.local.md` is present
but nothing reads it.

**Cause**: Both files held progress for the interactive course system, which has been
retired. No surviving skill reads them.

**Fix**: Delete them. There is nothing to migrate to.
```bash
rm -f .claude/cogni-teacher.local.md .claude/cogni-help.local.md
```

---

## Stale project file after cogni-diamond rename

**Symptom**: Consulting engagement data not found when resuming a project.

**Cause**: Project file still named `diamond-project.json` after the plugin was renamed
to cogni-consulting.

**Fix**: Rename the file:
```bash
mv diamond-project.json consulting-project.json
```

**Note**: cogni-consulting has been removed — replaced by cogni-consult (its source
remains in git history). This note only applies to legacy Double Diamond engagement
data. All new consulting engagements use cogni-consult
(`consult-project.json`).

---

## GitHub not logged in

**Symptom**: The cogni-issues skill fails with an authentication or login error.

**Cause**: GitHub CLI is not authenticated for the current user.

**Fix**: Run `gh auth status`. If authentication is missing, run `gh auth login`,
choose **GitHub.com** and **HTTPS**, and complete the browser or token flow. Then
retry the cogni-issues operation.

---

## Missing COGNI_WORKSPACE_ROOT

**Symptom**: Plugin skills can't find shared resources (themes, env vars).

**Cause**: Workspace not initialized, or `.workspace-env.sh` not sourced by session hook.

**Fix**: Run `/manage-workspace` to set up or update the workspace, or `/workspace-status` to
diagnose what's missing.

---

## PPTX generation fails with "pptxgenjs not found"

**Symptom**: `/render-slides` fails.

**Cause**: PptxGenJS not installed globally.

**Fix**:
```bash
npm install -g pptxgenjs
```
