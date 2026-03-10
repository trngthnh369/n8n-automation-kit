---
name: n8n-deployer
tier: 2
category: hub
version: 1.0.0
description: Deploys, activates, tags, and finalizes workflows. Handles production safety.
triggers:
  - "deploy workflow"
  - "activate"
  - "go live"
  - "publish workflow"
requires:
  - n8n-mcp
related:
  - "[[builder]]"
  - "[[debugger]]"
---

# 🚀 n8n Deployer

Handles deployment lifecycle: create, activate, tag, and production safety.

> ⚡ **MCP-FIRST**: Ưu tiên MCP tools: `create_workflow()`, `activate_workflow()`, `tag_workflow()`, `duplicate_workflow()`.
> **Fallback**: Nếu MCP không available → gọi n8n REST API trực tiếp (`POST /api/v1/workflows`, `PATCH /api/v1/workflows/:id`).
> ⚠️ Fallback mode không hỗ trợ `execute_workflow` — chỉ deploy được, không tự test.

## Deployment Protocol

```
STEP 1: PRE-DEPLOY CHECK
├── list_workflows() → check for duplicate names
├── IF duplicate found:
│   ├── Ask user: update existing or create new?
│   └── Or use duplicate_workflow() for safe clone
└── Verify workflow JSON is complete (nodes, connections, settings)

STEP 2: DEPLOY
├── create_workflow(name, nodes, connections, settings)
│   └── Returns: { id: workflowId }
└── Record workflowId for subsequent operations

STEP 3: ACTIVATE
├── activate_workflow(workflowId, active: true)
├── IF activation fails → check trigger node configuration
│   ├── Webhook: verify path is unique
│   ├── Schedule: verify cron expression
│   └── Execute Workflow Trigger: no activation needed (called by parent)
└── Verify activation status

STEP 4: TAG
├── list_tags() → find existing tags or create new ones
├── Tag taxonomy:
│   ├── Environment: "Production", "Staging", "Draft"
│   ├── Domain: "Facebook-Ads", "Inventory", "Content", "KPI"
│   ├── Type: "Main", "Sub-Worker", "Utility"
│   └── Status: "Active", "Deprecated"
├── tag_workflow(workflowId, [tagIds])
└── ⚠️ WARNING: tag_workflow REPLACES all tags — fetch existing tags first!

STEP 5: VERIFY
└── Hand off to [[debugger]] for execution verification
```

## Production Safety Rules

### When Modifying Production Workflows

```
1. NEVER edit active production workflows directly
2. ALWAYS use: duplicate_workflow(productionId, "V2 - [change description]")
3. Test the copy thoroughly via [[debugger]]
4. Only after verification:
   - activate_workflow(newVersion, true)
   - activate_workflow(oldVersion, false)
5. Keep old version for rollback (don't delete for 7 days)
```

### Deployment Checklist

Before handoff to `[[debugger]]` for verification:

- [ ] Workflow deployed with correct name
- [ ] Activation status correct (active for triggers, inactive for sub-workers that are manually called)
- [ ] Tags applied (environment + domain + type)
- [ ] No duplicate workflows with same name
- [ ] Settings include timezone and error workflow reference

### Sub-Workflow Deployment Order

When deploying a system with sub-workflows:

```
1. Deploy sub-workers FIRST (they need IDs before main can reference them)
2. Deploy main orchestrator LAST (references sub-worker IDs)
3. Activate sub-workers
4. Activate main orchestrator
5. Test end-to-end via main orchestrator
```

## Runner Workflow Dependency

The `execute_workflow` tool depends on a **Runner Workflow** deployed on your n8n instance.

> Runner Workflow ID is configured during MCP setup. See `setup/SETUP-MCP.md` for details.

If `execute_workflow` returns **404**:

```
activate_workflow("<RUNNER_WORKFLOW_ID>", active: true)
→ Wait 2 seconds
→ Retry execute_workflow
```

The Runner must ALWAYS be active for the self-healing loop to function.
