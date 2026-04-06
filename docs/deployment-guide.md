# Deployment Guide

Enterprise deployment reference for Claude Code and Claude Cowork — security configuration, GDPR compliance, network setup, and operations.

> **Data last researched:** 2026-04-04 | **Sources:** 38 unique URLs
>
> If this guide is more than 90 days old, consider running `/doc-deploy` in the cogni-docs plugin to refresh the underlying data before relying on specific configuration values.

For the canonical plugin and workspace setup, see [Getting Started](getting-started.md). This guide covers the infrastructure and compliance layer that sits underneath.

---

## Two Deployment Paths

| Path | Who it's for | Key differences |
|------|-------------|-----------------|
| **Claude Cowork** | Business users, analysts, project managers | Desktop app, visual interface, local file access, no CLI |
| **Claude Code** | Developers, power users, CI/CD pipelines | CLI + IDE extensions, sandboxed execution, full audit logging |

**Compliance note:** Cowork sessions are stored locally on each user's machine and do **not** appear in Enterprise audit logs or the Compliance API. If your organization requires compliance logging for all AI tool usage, use Claude Code for regulated workloads.

---

## Claude Cowork Deployment

### Installation

Claude Desktop (which hosts Cowork) is available for macOS 11+ and Windows 10+. Cowork is a research preview available on Pro, Max, Team, and Enterprise paid plans. Linux is not supported.

1. Download from claude.ai/download
2. Install and launch
3. Sign in with your organizational account
4. Select the **Cowork** tab in the mode selector

Your computer must remain awake with Claude Desktop open during tasks. An active internet connection is required throughout.

### Workspace Policies

Enterprise admins enable or disable Cowork organization-wide via **Organization settings > Capabilities**. During the research preview, Cowork is ON by default.

- No per-user or per-role controls during research preview (all-or-nothing)
- Selective enablement requires contacting Anthropic Sales
- Network egress permissions are respected; web search can be disabled separately
- Self-serve seat management and spend caps available (Enterprise)
- Custom data retention controls available (minimum 30 days, Enterprise)

### Plugins and Integrations

Claude Desktop uses **Desktop Extensions** (`.mcpb` files) — bundled packages with an MCP server and all dependencies. A built-in Node.js runtime means no separate installation.

- Install via **Settings > Extensions > Browse extensions**, or drag-and-drop a `.mcpb` file
- Enterprise controls: pre-install approved plugins via Group Policy (Windows) or MDM (macOS), block publishers, disable public directory, host a private directory
- Sensitive settings (API keys, tokens) encrypted via OS keychain

---

## Claude Code Deployment

### Installation Methods

| Method | Command | Auto-Updates |
|--------|---------|:------------:|
| **Native (recommended)** | `curl -fsSL https://claude.ai/install.sh \| bash` | Yes |
| **Native (Windows PS)** | `irm https://claude.ai/install.ps1 \| iex` | Yes |
| Homebrew | `brew install --cask claude-code` | No |
| WinGet | `winget install Anthropic.ClaudeCode` | No |

Requires macOS 13.0+, Windows 10 1809+, or Ubuntu 20.04+, 4 GB+ RAM, and a paid plan. Post-install: `claude --version` to verify, `claude doctor` to check configuration.

The npm method (`npm install -g @anthropic-ai/claude-code`) is **deprecated** — migrate to the native installer.

### Enterprise Configuration

Claude Code uses a layered settings system. **Managed settings** (highest priority) are deployed by IT via MDM, Group Policy, or filesystem and cannot be overridden by users.

**Settings precedence** (highest to lowest): Managed > CLI args > Local > Project > User

**Managed settings locations:**
- macOS: `/Library/Application Support/ClaudeCode/` or MDM preference domain `com.anthropic.claudecode`
- Linux/WSL: `/etc/claude-code/`
- Windows: `C:\Program Files\ClaudeCode\` or Registry `HKLM\SOFTWARE\Policies\ClaudeCode`

**Key enterprise controls:**
- `forceLoginMethod`: restrict to `claudeai` or `console`
- `forceLoginOrgUUID`: restrict to specific organization
- `availableModels`: restrict model selection
- `allowedMcpServers` / `deniedMcpServers`: control MCP server access
- `allowManagedHooksOnly`, `allowManagedMcpServersOnly`: lock down user overrides
- `apiKeyHelper`: script for custom auth integration (rotating credentials)

Binary integrity is verified via SHA256 checksums + GPG signatures (v2.1.89+). macOS binaries are Apple-notarized.

### Team Configuration

Teams share configuration via a committed `.claude/` directory:

- **`.claude/settings.json`**: shared permission rules, hooks, tool configs (committed)
- **`CLAUDE.md`**: project conventions (committed, advisory ~80% adherence)
- **`.claude/settings.local.json`**: personal overrides (auto-gitignored)
- Hooks are **deterministic (100% adherence)** vs. CLAUDE.md which is advisory
- Server-managed settings via Claude.ai admin console for Team/Enterprise

### IDE Integration

| IDE | Installation | Key features |
|-----|-------------|-------------|
| VS Code (1.98.0+) | Extensions marketplace | Inline diff review, @-mention files, parallel conversations, Plan mode |
| JetBrains | JetBrains Marketplace | CLI in IDE terminal, native diff viewer |
| Cursor | Extensions marketplace | Similar to VS Code integration |

### CI/CD Integration

Claude Code supports CI/CD through **hooks** (24 lifecycle events) and headless CLI execution.

**Hook types:** `command` (shell), `http` (webhook), `prompt` (single-turn LLM), `agent` (multi-turn subagent)

**Key patterns:**
- **PreToolUse** hooks fire before permission checks — can block even in `bypassPermissions` mode
- **PostToolUse** hooks for auto-formatting, logging, quality checks
- **Stop** hooks for completion verification
- Permission modes for CI/CD: `default`, `acceptEdits`, `plan`, `auto`, `bypassPermissions`

### Security and Sandboxing

Claude Code uses OS-level sandboxing for filesystem and network isolation:

- **Filesystem**: macOS Seatbelt, Linux bubblewrap — write restricted to working directory
- **Network**: domain-based proxy filtering
- **Command blocklist**: `curl`, `wget` blocked by default
- Sandbox reduces permission prompts by 84%
- Prompt injection protections: context-aware analysis, input sanitization, isolated web fetch context
- **Fail-closed**: unmatched commands default to manual approval

---

## Security Configuration

### API Key Management

API keys are created through the Claude Console (not via API). Admin API keys (`sk-ant-admin...`) require the admin role and are separate from standard keys.

- Keys are scoped to Organizations, not individual users — they persist when users are removed
- Admin API supports listing, filtering by status/workspace, and deactivation
- Organization roles: `user`, `claude_code_user`, `developer` (manage API keys), `billing`, `admin`
- Rotate keys regularly (Anthropic recommendation)

### Network Requirements

**Required endpoints to allowlist:**

| Endpoint | Purpose |
|----------|---------|
| `api.anthropic.com` | Claude API |
| `claude.ai` | Authentication (claude.ai accounts) |
| `platform.claude.com` | Authentication (Console accounts) |
| `storage.googleapis.com` | Binary downloads and auto-updater |
| `downloads.claude.ai` | Install scripts, plugins |

**Optional endpoints (disable with env vars):**

| Endpoint | Purpose | Disable with |
|----------|---------|-------------|
| `statsig.anthropic.com` | Telemetry | `DISABLE_TELEMETRY=1` |
| `sentry.io` | Error reporting | `DISABLE_ERROR_REPORTING=1` |

**Proxy support:** `HTTPS_PROXY` / `HTTP_PROXY` / `NO_PROXY` environment variables. Basic auth supported. SOCKS, NTLM, and Kerberos are **not** supported — use an LLM Gateway. Custom CA certificates: `NODE_EXTRA_CA_CERTS=/path/to/ca-cert.pem`.

**Alternative providers:** AWS Bedrock, Google Vertex AI, and Microsoft Foundry are supported as API providers.

### Authentication and SSO

Enterprise plan includes SSO with domain capture and SCIM provisioning. Each parent organization links to one Identity Provider.

- SSO enforcement option to prevent non-SSO access
- SCIM provisioning (Enterprise and Console)
- Just-in-Time provisioning (Team and Enterprise)
- Group mappings for role-based organization assignment

### Audit Logging

| Channel | What it captures | Plan |
|---------|-----------------|------|
| Enterprise audit logs | claude.ai and Claude Code activity | Enterprise |
| Compliance API | Programmatic access (NDA required) | Enterprise |
| OpenTelemetry | Metrics, events, traces | All Claude Code |
| Usage/Cost API | Token and cost tracking | All API |

**OpenTelemetry metrics:** `session.count`, `lines_of_code.count`, `cost.usage`, `token.usage`. Exporters: OTLP, Prometheus, console. Prompt content is NOT logged by default (enable with `OTEL_LOG_USER_PROMPTS=1`).

**Critical:** Cowork sessions are NOT captured in audit logs or the Compliance API.

### Data Handling

Commercial data (Team, Enterprise, API) is **never** used for model training unless the customer opts into the Development Partner Program.

| Data Type | Retention |
|-----------|-----------|
| Standard API inputs/outputs | Deleted within 30 days |
| Zero Data Retention (ZDR) | No storage after response |
| Enterprise UI (custom) | Minimum 30 days, configurable |
| Safety classifier results | Retained even under ZDR |
| Policy violation flags | Up to 2 years |

ZDR is available per-organization via Anthropic sales. It does **not** apply to: Console/Workbench, consumer products, Batch API, Files API, Code Execution, MCP Connector.

Telemetry opt-out: `DISABLE_TELEMETRY=1`, `DISABLE_ERROR_REPORTING=1`, or `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`.

---

## GDPR Compliance

> **Does your Claude deployment process personal data?** If prompts or responses contain employee data, customer PII, or other personal data, GDPR applies. If Claude is used only for tasks without personal data (e.g., code generation, internal documentation), skip to [Operations](#operations-and-monitoring).

### Data Residency

The direct Anthropic API offers `global` and `us` inference geographies — there is **no dedicated EU inference option yet**. For guaranteed EU data residency, use AWS Bedrock or Google Vertex AI with EU regional endpoints.

**AWS Bedrock EU regions** (use `eu.` prefix inference profiles):

| Region | Location | Key models |
|--------|----------|-----------|
| eu-central-1 | Frankfurt | Opus 4.6, Sonnet 4.6, Haiku 4.5 |
| eu-central-2 | Vienna | Full model range |
| eu-west-1 | Ireland | Full model range |
| eu-west-3 | Paris | Full model range |

**Google Vertex AI** offers 10 EU regions including Belgium, Frankfurt, Netherlands, Zurich, and Paris.

### Data Processing Agreement

Anthropic's DPA is **automatically incorporated** into the Commercial Terms of Service.

- EU Standard Contractual Clauses (SCCs) included: Module Two and Module Three
- UK International Data Transfer Addendum included
- Swiss Data Protection Act addendum included
- Sub-processor notice: 15 days advance, 10-day customer objection window
- Anthropic commits to delete or return data within 30 days of termination

DPA: https://www.anthropic.com/legal/data-processing-addendum

### Data Subject Rights

For commercial products (Team, Enterprise, API): **Customer = Data Controller**, **Anthropic = Data Processor**. Anthropic forwards DSARs to the customer organization. Organizations must implement their own DSAR process.

### Compliance Certifications

| Certification | Status |
|---------------|--------|
| SOC 2 Type II | Completed |
| ISO 27001:2022 | Certified |
| ISO/IEC 42001:2023 | Certified (AI Management) |
| HIPAA | BAA available |
| FedRAMP High | Met (Vertex AI) |

Anthropic signed the **EU GPAI Code of Practice** (July 2025). Full EU AI Act enforcement begins August 2, 2026.

Reports available at the [Anthropic Trust Portal](https://trust.anthropic.com/).

---

## Operations and Monitoring

### Monitoring Stack

| Tool | Purpose | Setup |
|------|---------|-------|
| OpenTelemetry | Metrics, events, traces | Configure exporters in settings |
| Usage API | Token tracking (5-min freshness) | `/v1/organizations/usage_report/messages` |
| Cost API | Daily cost tracking | `/v1/organizations/cost_report` |
| Partner integrations | CloudZero, Datadog, Grafana, Honeycomb, Vantage | Supported natively |

### Update Management

Native installs auto-update in the background. Two release channels:

- **`latest`** (default): immediate updates
- **`stable`**: ~1 week delay for enterprise stability

Configure: `{"autoUpdatesChannel": "stable"}` in settings.json. Disable auto-updates: `{"env": {"DISABLE_AUTOUPDATER": "1"}}`.

Allowlist `storage.googleapis.com` for the auto-updater.

### Cost Management

- **Spend caps**: organizational and individual user levels (Enterprise)
- **Multi-team allocation**: `OTEL_RESOURCE_ATTRIBUTES` for department/cost-center segmentation
- **Usage filtering**: by API key, workspace, model for chargeback

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `SELF_SIGNED_CERT_IN_CHAIN` | Set `NODE_EXTRA_CA_CERTS` to your corporate CA bundle path |
| NTLM/Kerberos proxy auth fails | Use an LLM Gateway; basic auth works via `HTTPS_PROXY` |
| Auto-updater blocked by firewall | Allowlist `storage.googleapis.com` and `downloads.claude.ai` |
| General installation issues | Run `claude doctor` |
| Check active settings sources | Run `/status` inside Claude Code |

---

## See Also

- [Getting Started](getting-started.md) — workspace and plugin setup
- [Ecosystem Overview](ecosystem-overview.md) — how the 13 plugins fit together
- [cogni-workspace plugin guide](plugin-guide/cogni-workspace.md) — workspace initialization details
