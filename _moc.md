---
name: n8n Automation Kit
version: 1.0.0
type: map-of-content
description: Entry point for the n8n Automation Kit skill graph. Read this file FIRST to navigate available skills.
---

# 🗺️ n8n Automation Kit — Map of Content

> **How to use**: Read this MOC first. Follow `[[wikilinks]]` to load only the skills you need. Each skill has YAML frontmatter with `triggers`, `requires`, and `related` fields.

---

## 🎯 Tier 1: Orchestrators _(Auto-loaded)_

| Skill            | Purpose                                                                | Path                                         |
| ---------------- | ---------------------------------------------------------------------- | -------------------------------------------- |
| [[orchestrator]] | Route user requests to correct hubs. Manages PRD-to-Workflow pipeline. | `tier-1-orchestrators/orchestrator/SKILL.md` |

**When activated**: Every session. This is the brain that decides which skills to invoke.

---

## 📋 Tier 2: Workflow Hubs _(Load on demand)_

| Skill         | Purpose                                                         | Path                             |
| ------------- | --------------------------------------------------------------- | -------------------------------- |
| [[architect]] | Analyze requirements → design SSOT → split into modules         | `tier-2-hubs/architect/SKILL.md` |
| [[builder]]   | Construct nodes[], connections{}, apply patterns (Builder v5)   | `tier-2-hubs/builder/SKILL.md`   |
| [[debugger]]  | Execute → forensics → analyze errors → route to builder for fix | `tier-2-hubs/debugger/SKILL.md`  |
| [[deployer]]  | Deploy, activate, tag, verify, finalize                         | `tier-2-hubs/deployer/SKILL.md`  |

**Typical flow**: `orchestrator` → `architect` → `builder` → `deployer` → `debugger` (if errors) → `builder` (fix) → `deployer` (re-verify)

---

## 🛠️ Tier 3: Utilities _(Load on demand)_

| Skill                  | Purpose                                                          | Path                                           |
| ---------------------- | ---------------------------------------------------------------- | ---------------------------------------------- |
| [[n8n-mcp]]            | 24 MCP tools: CRUD, execute, debug, templates, credentials, tags | `tier-3-utilities/n8n-mcp/SKILL.md`            |
| [[google-workspace]]   | `gws` CLI: read/write Docs, Sheets, Calendar, Drive, Gmail       | `tier-3-utilities/google-workspace/SKILL.md`   |
| [[credential-manager]] | Credential lifecycle: discover, create, map to nodes             | `tier-3-utilities/credential-manager/SKILL.md` |
| [[template-library]]   | Community template search, adapt, and local pattern library      | `tier-3-utilities/template-library/SKILL.md`   |

---

## 🏢 Tier 4: Domain Skills _(Load by project type)_

| Skill                 | Domain                    | Key Patterns                                                       | Path                                        |
| --------------------- | ------------------------- | ------------------------------------------------------------------ | ------------------------------------------- |
| [[facebook-ads]]      | Facebook Ads Automation   | Cascade pause, adaptive branching, API resilience, timezone offset | `tier-4-domains/facebook-ads/SKILL.md`      |
| [[inventory]]         | Ecommerce Inventory       | Batch-accumulate, scatter-gather, marketplace APIs                 | `tier-4-domains/inventory/SKILL.md`         |
| [[content-gen]]       | AI Content Generation     | Request-queue-worker, multi-modal media, prompt engineering        | `tier-4-domains/content-gen/SKILL.md`       |
| [[kpi-automation]]    | KPI Scoring & Management  | Merge barrier, SSOT strategy, Base Goal API                        | `tier-4-domains/kpi-automation/SKILL.md`    |
| [[google-sheets]]     | Google Sheets Expert      | GID patterns, pivot ops, batch updates, cross-sheet refs           | `tier-4-domains/google-sheets/SKILL.md`     |
| [[crm-sales]]         | CRM & Sales               | Lead capture, nurture sequences, pipeline, round-robin             | `tier-4-domains/crm-sales/SKILL.md`         |
| [[messaging]]         | Messaging & Notifications | Zalo OA, Telegram, Slack, Email, chatbot, broadcast                | `tier-4-domains/messaging/SKILL.md`         |
| [[data-pipeline]]     | Data Pipeline & ETL       | Paginated extraction, transformation, cross-system sync            | `tier-4-domains/data-pipeline/SKILL.md`     |
| [[order-fulfillment]] | Order & Fulfillment       | Multi-channel orders, shipping, invoicing, returns                 | `tier-4-domains/order-fulfillment/SKILL.md` |
| [[social-media]]      | Social Media Management   | Auto-posting, engagement tracking, content calendar                | `tier-4-domains/social-media/SKILL.md`      |
| [[finance]]           | Finance & Accounting      | Reconciliation, invoicing, expense tracking, P&L                   | `tier-4-domains/finance/SKILL.md`           |
| [[it-ops]]            | IT Operations             | Health checks, CI/CD, backup verification, incident response       | `tier-4-domains/it-ops/SKILL.md`            |
| [[customer-support]]  | Customer Support          | Ticket routing, AI draft responses, SLA tracking                   | `tier-4-domains/customer-support/SKILL.md`  |

---

## 🔗 Cross-Reference Quick Map

```
User Request
    ↓
[orchestrator] → detects intent + domain
    ↓
[architect] → designs SSOT
    ├─→ [template-library] (reference patterns)
    └─→ [domain-skill] (domain expertise)
    ↓
[builder] → constructs JSON
    ├─→ [n8n-mcp] (node discovery, validation)
    ├─→ [credential-manager] (auth setup)
    └─→ [google-sheets] (if sheets integration needed)
    ↓
[deployer] → deploys & activates
    ↓
[debugger] → executes & verifies
    ├─→ SUCCESS → done ✅
    └─→ FAIL → [builder] fix → [deployer] re-deploy → [debugger] re-verify (max 3x)
```
