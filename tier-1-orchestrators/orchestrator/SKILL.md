---
name: n8n-orchestrator
tier: 1
category: orchestrator
version: 1.0.0
description: Routes user requests to correct workflow hubs. Manages end-to-end PRD-to-Workflow pipeline.
auto_load: true
triggers:
  - "build workflow"
  - "create automation"
  - "automate"
  - "n8n workflow"
  - "PRD to workflow"
  - "tạo workflow"
requires: []
recommends:
  - google-workspace
related:
  - "[[architect]]"
  - "[[builder]]"
  - "[[debugger]]"
  - "[[deployer]]"
---

# 🎯 n8n Orchestrator

The brain of the n8n Automation Kit. Routes every user request to the correct skill hub and manages the end-to-end automation pipeline.

## ⚡ MCP-FIRST / JS-FALLBACK (đọc trước khi làm bất cứ gì)

### Ưu tiên 1: MCP Tools (mặc định)

> **LUÔN ưu tiên MCP tools** (`create_workflow`, `execute_workflow`, `update_workflow`, `get_execution_data`, v.v.)
> MCP tools nhanh hơn 3-5x, tự xử lý auth, và hỗ trợ Self-Healing Loop.

### Ưu tiên 2: JS/Python Code (fallback)

> Chỉ dùng custom code khi:
>
> 1. MCP tools **không available** trong tool list (server chưa cấu hình)
> 2. Cần **batch operations phức tạp** mà MCP tools không hỗ trợ (vd: migrate 50 workflows)
> 3. Cần **custom data transformation** trước khi deploy

### Logic chọn mode

```
IF MCP tools available (search: "create_workflow", "list_workflows"):
  → MODE = MCP
  → Dùng MCP tools cho toàn bộ lifecycle
  → Self-Healing Loop hoạt động đầy đủ

ELSE:
  → MODE = JS-FALLBACK
  → Cần user cung cấp: N8N_URL + N8N_API_KEY
  → Viết code gọi n8n REST API
  → ⚠️ Không có execute_workflow (n8n API không hỗ trợ)
  → ⚠️ Self-Healing Loop bị giới hạn (chỉ deploy, không tự test)
  → Khuyến nghị user cài n8n-custom-mcp để unlock full automation
```

## Intent Detection & Routing

When a user request arrives, classify intent and route:

| Intent Pattern                 | Route To                                         | Example                                        |
| ------------------------------ | ------------------------------------------------ | ---------------------------------------------- |
| "Build/Create/Tạo workflow..." | `[[architect]]` → `[[builder]]` → `[[deployer]]` | "Build a Shopee scraper workflow"              |
| "Debug/Fix/Sửa workflow..."    | `[[debugger]]`                                   | "Debug workflow XYZ — HTTP node fails"         |
| "Deploy/Activate workflow..."  | `[[deployer]]`                                   | "Deploy and activate workflow ABC"             |
| "Read PRD/requirements..."     | `[[google-workspace]]` → `[[architect]]`         | "Read PRD from Google Docs and build workflow" |
| "Find template for..."         | `[[template-library]]` → `[[builder]]`           | "Find a Slack notification template"           |

### Domain Detection

If the request mentions a domain, load the domain skill:

| Domain Keywords                                                 | Load Skill              |
| --------------------------------------------------------------- | ----------------------- |
| "facebook ads", "campaign", "ad set", "META"                    | `[[facebook-ads]]`      |
| "inventory", "shopee", "lazada", "tiktok", "haravan", "product" | `[[inventory]]`         |
| "content", "article", "SEO", "media", "TVC", "video"            | `[[content-gen]]`       |
| "KPI", "goal", "score", "evaluation", "performance"             | `[[kpi-automation]]`    |
| "google sheets", "spreadsheet", "GID"                           | `[[google-sheets]]`     |
| "CRM", "sales", "lead", "customer", "pipeline", "deal"          | `[[crm-sales]]`         |
| "Zalo", "Telegram", "Slack", "email", "notification", "chatbot" | `[[messaging]]`         |
| "ETL", "data sync", "import", "export", "database", "CSV"       | `[[data-pipeline]]`     |
| "order", "fulfillment", "shipping", "đơn hàng", "xuất kho"      | `[[order-fulfillment]]` |
| "social media", "post", "instagram", "engagement"               | `[[social-media]]`      |
| "finance", "accounting", "invoice", "revenue", "expense"        | `[[finance]]`           |
| "server", "monitoring", "CI/CD", "DevOps", "backup"             | `[[it-ops]]`            |
| "support", "ticket", "helpdesk", "complaint", "khiếu nại"       | `[[customer-support]]`  |

---

## PRD-to-Workflow Pipeline

The end-to-end automated pipeline for creating workflows from requirements:

```
PHASE 1: INTAKE
├── Receive user request (text or PRD link)
├── IF PRD link → load [[google-workspace]] → read document
├── Classify intent → detect domain
└── Load relevant domain skill

PHASE 2: DESIGN
├── Load [[architect]]
├── Analyze requirements → identify integrations needed
├── Design SSOT (Single Source of Truth document):
│   ├── Workflow name & purpose
│   ├── Trigger type (webhook/schedule/manual)
│   ├── Node list with dependencies
│   ├── Data flow between nodes
│   ├── Error handling strategy
│   └── Sub-workflow split plan (if >7 nodes per concern)
├── Check [[template-library]] for similar patterns
└── Output: Architecture Blueprint

PHASE 3: BUILD
├── Load [[builder]]
├── Load [[credential-manager]] if new credentials needed
├── Construct nodes[] with correct typeVersion, parameters, position
├── Construct connections{} mapping
├── Apply localization (timezone: Asia/Ho_Chi_Minh)
├── Apply resilience patterns (continueErrorOutput, error funnel)
└── Output: Complete workflow JSON

PHASE 4: DEPLOY
├── Load [[deployer]]
├── Check for duplicates: list_workflows(name)
├── create_workflow(name, nodes, connections)
├── activate_workflow(id, true)
├── tag_workflow(id, tags)
└── Output: Deployed workflow ID

PHASE 5: VERIFY
├── Load [[debugger]]
├── execute_workflow(id)
├── list_executions(workflowId, limit: 1)
├── get_execution_data(executionId)
├── IF all nodes success → ✅ DONE
├── IF errors found:
│   ├── Analyze error (node name, message, data sample)
│   ├── Route to [[builder]] for fix
│   ├── update_workflow(id, fixedNodes, fixedConnections)
│   └── Re-execute (max 3 retries)
└── Output: Verification report

PHASE 6: REPORT
├── Summarize: workflow ID, name, status, nodes count
├── IF [[google-workspace]] available → write report to Sheets/Docs
└── Notify user with results
```

---

## Orchestration Rules

### DO

- **Always detect domain** before routing — domain skills contain critical patterns
- **Always check duplicates** before creating new workflows
- **Load skills lazily** — only load what the current task needs
- **Follow the pipeline order**: Design → Build → Deploy → Verify
- **Track retry count** — max 3 fix attempts before escalating to user

### DON'T

- **Don't skip the architect phase** — unplanned workflows have 3x more errors
- **Don't load all domain skills at once** — context overload kills reasoning
- **Don't modify production workflows directly** — use `duplicate_workflow` first
- **Don't retry more than 3 times** — escalate with diagnostic details

### Escalation Protocol

After 3 failed fix attempts, report to user:

```
❌ Workflow [name] could not be auto-fixed after 3 attempts.

Failing node: [node_name]
Error: [error_message]
Attempts:
  1. [what was tried]
  2. [what was tried]
  3. [what was tried]

Suggested next steps:
  - [manual investigation suggestions]
  - [credential or permission issues]
  - [API documentation to check]
```
