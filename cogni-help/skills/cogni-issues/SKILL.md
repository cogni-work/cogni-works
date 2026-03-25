---
name: cogni-issues
version: 0.2.0
description: |
  File and track GitHub issues (bugs, feature requests, change requests, questions) against
  insight-wave ecosystem plugins using browser automation (claude-in-chrome). Guides users
  through a short consultation to capture the right details, resolves the target plugin's
  repository automatically, drafts issues from templates, creates them via cobrowsing on
  github.com, and tracks them locally.
  Use this skill whenever the user wants to report a bug, request a feature, file a change
  request, ask a question about a plugin, list filed issues, or check issue status.
  Also trigger when the user says things like "this plugin is broken", "I found a problem
  with {plugin}", "can we get X added to {plugin}", "{plugin} doesn't work", "open an issue",
  "something is wrong with {plugin}", "das Plugin funktioniert nicht", "Fehler in {plugin}",
  "set up GitHub issues", "configure issue filing", "ich kann kein Issue erstellen",
  or any complaint/suggestion about a specific plugin — even if they don't use the word "issue".
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Cogni Issues

Manage the lifecycle of GitHub issues for insight-wave ecosystem plugins: consult with the
user to understand the problem clearly, resolve which repository the plugin belongs to,
draft issues from templates, create them via browser cobrowsing on github.com, and track
them locally.

All GitHub operations use **browser automation via claude-in-chrome** — navigating to
github.com, reading pages, and filling forms directly. This works in any environment
with a browser, including Cowork. No MCP connector setup, Personal Access Tokens, or
`gh` CLI needed — the user just needs to be logged into GitHub in their browser.

**Important:** Do NOT use `gh` CLI commands — all GitHub operations go through
browser automation. The `gh` CLI is not required and should not be invoked.

## Language

Read the workspace language from `.workspace-config.json` in the workspace root
(`language` field — `"en"` or `"de"`) as the default interaction language. If the
user's message is in a different language, prefer the user's language (message
detection overrides the workspace setting — someone writing in German wants a
German response even if the workspace is set to English).

If `.workspace-config.json` is missing, fall back to detecting the user's language
from their message. If still unclear, default to English.

Conduct the entire interaction in the chosen language — consultation questions,
acknowledgments, draft body, and confirmation prompts.

Exceptions where English stays:
- **Title prefixes**: `[Bug]`, `[Feature]`, `[Change]`, `[Question]` — conventions for
  GitHub label automation and cross-team readability.
- **Technical terms**: plugin names, CLI commands, error messages, stack traces.

## Environment

The skill scripts live at `${CLAUDE_PLUGIN_ROOT}/skills/cogni-issues/scripts/`.
`CLAUDE_PLUGIN_ROOT` points to the cogni-help plugin directory. If you can't
find the scripts, tell the user — don't guess paths.

## Browser Tools for GitHub

All GitHub operations use claude-in-chrome browser automation tools:

| Operation | Tools | URL Pattern |
|-----------|-------|-------------|
| Create issue | `navigate`, `form_input`, `computer` | `github.com/{owner}/{repo}/issues/new` |
| List issues | `navigate`, `get_page_text` | `github.com/{owner}/{repo}/issues` |
| Search issues | `navigate`, `get_page_text` | `github.com/{owner}/{repo}/issues?q={keywords}` |
| Get issue | `navigate`, `get_page_text` | `github.com/{owner}/{repo}/issues/{number}` |

Before using any claude-in-chrome tool, load it via `ToolSearch` first
(e.g., `select:mcp__claude-in-chrome__navigate`).

## Modes

| Mode | Triggers | Action |
|------|----------|--------|
| **setup** | Browser not available or user not logged into GitHub, "set up issues", "ich kann kein Issue erstellen" | Guide user to log into GitHub in browser |
| **create** | reporting bugs, requesting features, filing change requests, asking plugin questions | Consult, resolve, draft, confirm, create, log |
| **list** | "my issues", "show issues", "what have I filed" | Read local state, display grouped by plugin |
| **status** | "check issue #N", "any updates on my issue" | Fetch from GitHub via browser, update local record |
| **browse** | "open issue", "show in browser" | Navigate to the GitHub issue in the browser |

Default to **list** when intent is unclear.

## Prerequisites

Before any GitHub operation, verify browser access and login:

1. Use `ToolSearch` to look for `mcp__claude-in-chrome__tabs_context_mcp`
2. If the tool is not found, tell the user: "This skill requires the claude-in-chrome
   browser extension. Please ensure it is installed and active."
3. Call `tabs_context_mcp` to verify the browser is connected
4. Navigate to `https://github.com` and check login with `javascript_tool`:
   ```javascript
   document.querySelector('meta[name="user-login"]')?.content || 'not-logged-in'
   ```
5. If the result is `'not-logged-in'`, switch to **setup mode**
6. If the result returns a username, the user is logged in — proceed

## Setup mode

Browser-based setup is straightforward — the user just needs to be logged into
GitHub in Chrome.

### 1. Check browser availability

Use `ToolSearch` with query `mcp__claude-in-chrome__tabs_context_mcp`. If the tool
is found, the browser extension is active. If not, inform the user that browser
automation is required and they need to ensure claude-in-chrome is installed.

### 2. Check GitHub login

Navigate to `https://github.com` and run:

```javascript
document.querySelector('meta[name="user-login"]')?.content || 'not-logged-in'
```

If the result returns a username, the user is already logged in — tell them they're
all set and offer to file an issue.

### 3. If not logged in

Navigate to `https://github.com/login` and guide the user to sign in.

**English:**

> I need you to be logged into GitHub in the browser. I've opened the GitHub login
> page — please sign in with your GitHub account, then tell me when you're ready.

**German:**

> Ich brauche dich bei GitHub im Browser angemeldet. Ich habe die GitHub-Anmeldeseite
> geoeffnet — bitte melde dich mit deinem GitHub-Konto an und sag mir Bescheid,
> wenn du fertig bist.

### 4. After the user confirms

Re-check the login with the `javascript_tool` meta tag check. If the user is now
logged in, confirm success. If still not logged in, suggest:
- Clear the browser cache and try again
- Check if a corporate SSO or 2FA prompt needs to be completed first
- Try signing in manually in a new Chrome tab

### 5. Setup complete

If the user came here because they were trying to file an issue, continue with
the **create** flow.

## Workspace init

Run once before any operation (idempotent):

```bash
bash "${SKILL_DIR}/scripts/issue-store.sh" init "${working_dir}"
```

`working_dir` defaults to the current working directory. State lives in `{working_dir}/cogni-issues/`.

## Create mode

### 1. Check readiness and resolve the plugin

First, verify browser access and GitHub login (see Prerequisites). If not ready,
enter **setup mode** and return here once the user is logged in.

If the user hasn't named a specific plugin, ask which plugin this is about. Then resolve it:

```bash
bash "${SKILL_DIR}/scripts/resolve-plugin.sh" "<plugin_name>"
```

Handle: `"ambiguous": true` -> present matches and ask; `"error"` -> list available plugins
and ask; success -> extract `owner_repo`, `version`, `marketplace`.

### 2. Check for duplicates

Before investing in consultation and drafting, search for existing issues via the browser:

1. Navigate to `https://github.com/{owner}/{repo}/issues?q=is%3Aopen+{url_encoded_keywords}`
   using 2-3 keywords from the user's complaint
2. Use `get_page_text` to read the search results page
3. Look for issue titles and links in the page text

If you find a likely match, show it to the user and ask: "This looks similar — is it
the same problem, or something different?" If it's the same, link them to the existing
issue instead of creating a duplicate.

If `get_page_text` returns too much noise, use `javascript_tool` to extract structured data:

```javascript
[...document.querySelectorAll('[data-hovercard-type="issue"]')].slice(0, 10).map(a => ({
  title: a.textContent.trim(),
  url: a.href
}))
```

### 3. Determine the issue type

Infer the type from context (match intent across languages, not specific keywords):

| Type | Signals |
|------|---------|
| `bug` | something is broken, errors, crashes, doesn't work, fails, wrong output |
| `feature` | add something new, would be nice, request, support for |
| `change-request` | change existing behavior, modify, adjust, different behavior wanted |
| `question` | how to, why does, confused, wondering |

If genuinely ambiguous, ask. Otherwise trust your judgment.

**When the complaint involves config changes or unexpected output**, do a quick sanity
check before classifying: scan the plugin's data model or config schema to verify the
user's premise. For example, if a user says "I updated the logo in the config but it
still shows the old one," check whether the config actually has a logo field. The user's
mental model of how the plugin works may not match reality — what looks like a bug might
be a feature gap, a wrong-config-file situation, or a misunderstanding of which component
owns that functionality. A 30-second `Grep` or `Read` of the relevant schema can save
everyone from filing a misleading issue.

### 4. Consult the user

Help the user articulate what they need. Many users know something is wrong but haven't
organized their thoughts. Your job is to be a helpful interviewer, not a form.

**First, mine the conversation for existing evidence.** Check recent tool outputs for
error messages, stack traces, or failed commands. Look at what the user was working on —
the conversation often contains the exact workflow that triggered the problem. If you see
a traceback from earlier, use it — don't ask "did you see an error?"

**If you did a premise check (above) and found a mismatch**, incorporate that finding
into your consultation. Instead of generic "what happened?" questions, tell the user
what you found and ask targeted questions to resolve the gap — e.g., "I checked the
portfolio config schema and it doesn't have a logo field. Where exactly are you seeing
the logo, and which file did you edit?"

**Then ask only what's missing** — 2-3 questions max, batched in one turn:

- **Bug:** What were you doing? What happened? Reproducible or one-off?
- **Feature:** What problem does this solve? How should it work? Current workaround?
- **Change request:** What does it do now vs what should it do? Why doesn't current behavior work?
- **Question:** What are you trying to accomplish? What have you tried?

**Skip consultation entirely** if the user (or conversation context) already provides
enough detail. Acknowledge it: "You've given me a clear picture — let me draft this up."

### 5. Draft the issue

Read the template from `references/issue-templates.md` for the determined type.

Fill in from conversation + resolver output. Omit sections you can't fill meaningfully —
shorter with real content beats complete with placeholders.

**Auto-detect environment:**

```bash
uname -s && uname -r && node -v 2>/dev/null
```

**Write in the user's language** (except title prefixes and technical terms).

**Transform vague input into precise descriptions.** This is the core value you add:

| User says | You write |
|-----------|-----------|
| "it doesn't work" | "The skill exits with a non-zero status code without producing output when invoked with default arguments" |
| "it's slow" | "Rendering takes 45+ seconds for a 3-station brief, compared to ~15s previously — a 3x regression" |
| "the output looks wrong" | "Generated propositions show placeholder text ('Lorem ipsum') instead of configured descriptions" |
| "es funktioniert nicht mehr" | "Das Skill bricht beim Aufruf mit einem TypeError ab und erzeugt keine Ausgabe" |

The pattern: replace subjective impressions with observable facts, measurable quantities,
or specific error details.

**Add a root cause hypothesis when you can.** If the error or context suggests a likely
cause, include it in "Additional context" — e.g., "The TypeError on `narrative_arc`
suggests a property was renamed or removed in the latest update, possibly a breaking
change in the data model." This helps maintainers triage faster. Only do this when the
evidence supports it — don't speculate wildly.

### 6. Confirm with the user

Show the complete draft (title + body) and ask for approval in the user's language.
Never create without explicit confirmation. If the user wants changes, apply them and
show the updated draft.

### 7. Create on GitHub via browser

Navigate to `https://github.com/{owner}/{repo}/issues/new` and fill the form:

1. Use `get_page_text` to verify the "New Issue" form has loaded
2. Use `form_input` to fill the **title** field
3. Use `form_input` to fill the **body** textarea (paste the full drafted body)
4. **Labels** (optional): Use `computer` to click the "Labels" gear icon in the sidebar,
   then `form_input` to type the label name in the filter, then `computer` to click the
   matching label. Label mapping is in `references/issue-templates.md`. If the label
   doesn't appear or the interaction fails, skip it — the issue can be created without labels.
5. Use `computer` to click the **"Submit new issue"** button
6. After submission, the browser redirects to the new issue page. Read the page URL
   to extract `github_number` (the number in `/issues/{number}`) and `github_url`

**If form interaction fails:** Use `javascript_tool` as a fallback to fill and submit:

```javascript
document.querySelector('#issue_title').value = '<title>';
document.querySelector('#issue_body').value = '<body>';
document.querySelector('button[type="submit"][data-disable-with]').click();
```

If creation fails entirely, show the error and suggest next steps — don't retry blindly.

### 8. Log locally

```bash
ID_JSON=$(bash "${SKILL_DIR}/scripts/issue-store.sh" gen-id)
```

Then pipe the issue record as JSON via stdin:

```bash
echo '<json_record>' | bash "${SKILL_DIR}/scripts/issue-store.sh" add "${working_dir}"
```

The record includes: `id`, `plugin`, `marketplace`, `repository`, `github_number`,
`github_url`, `type`, `title`, `status` ("open"), `created_at`, `updated_at`.

Parse `github_number` and `github_url` from the browser redirect URL after submission.

### 9. Confirm

Return the GitHub issue URL and local issue ID.

## List mode

```bash
bash "${SKILL_DIR}/scripts/issue-store.sh" read "${working_dir}"
```

Display issues grouped by plugin: title, type badge, GitHub number + URL, status, date.
If empty, suggest the create flow.

## Status mode

1. Look up the issue in local state to get `owner`, `repo`, and `github_number`
2. Navigate to `https://github.com/{owner}/{repo}/issues/{github_number}` in the browser
3. Use `get_page_text` to read the issue page — extract state (open/closed), labels,
   latest comments, and last update timestamp
4. Update local record via `update-status`
5. Show: state, latest comments summary, labels, last update

If the page text is too noisy, use `javascript_tool` to extract structured data:

```javascript
({
  state: document.querySelector('.State')?.textContent?.trim(),
  title: document.querySelector('.js-issue-title')?.textContent?.trim(),
  labels: [...document.querySelectorAll('.IssueLabel')].map(l => l.textContent.trim()),
  comments: document.querySelectorAll('.timeline-comment').length
})
```

## Browse mode

Navigate to the GitHub issue URL in the browser using `navigate`. The URL follows
the pattern: `https://github.com/<owner>/<repo>/issues/<number>`

If browser tools are unavailable, provide the URL as text instead.

## Edge cases

- **2FA / SSO prompts**: If navigating to github.com triggers additional authentication,
  the page will not contain normal GitHub content. Detect this and tell the user:
  "GitHub is asking for additional authentication. Please complete it in the browser,
  then tell me when you're ready."
- **Private repos**: Browser access inherits the user's session permissions, so private
  repos work as long as the user has access — no extra token scopes needed.
- **GitHub HTML changes**: If expected form fields or selectors stop working, use
  `read_page` to inspect the current page structure and adapt. The `javascript_tool`
  fallback is more resilient to selector changes.
- **Rate limiting**: If GitHub returns a rate-limit page, inform the user to wait a few
  minutes before retrying.

## Scripts

- **`scripts/setup-gh.sh`** — Platform info script. Returns JSON with OS detection. The primary readiness check is done via browser tools (ToolSearch + login check).
- **`scripts/resolve-plugin.sh`** — Resolves a plugin name to its GitHub repo by scanning marketplace.json files. All insight-wave plugins resolve to the monorepo `cogni-work/insight-wave`.
- **`scripts/issue-store.sh`** — Local JSON state management (init, gen-id, add, read, update-status). The `add` command reads JSON from stdin for safety.

## References

- **`references/issue-templates.md`** — Templates for the four issue types with auto-fill placeholders and label mapping
