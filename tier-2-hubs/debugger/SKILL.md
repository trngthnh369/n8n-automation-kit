---
name: n8n-debugger
tier: 2
category: hub
version: 1.0.0
description: Executes workflows, analyzes execution data, identifies root causes, routes fixes to builder.
triggers:
  - "debug workflow"
  - "fix error"
  - "workflow failed"
  - "execution error"
  - "sửa lỗi"
requires:
  - n8n-mcp
related:
  - "[[builder]]"
  - "[[deployer]]"
---

# 🐛 n8n Debugger

Executes workflows, performs forensic analysis on execution data, and routes fixes to `[[builder]]`.

## Debug Protocol

```
STEP 1: EXECUTE
└── execute_workflow(workflowId)
    ├── 404 → Runner down → activate_workflow("yl69fJwZ0BASjDmB", true) → retry
    ├── 500 → Workflow error → STEP 2
    └── 200 + success → STEP 2 (verify all nodes)

STEP 2: FORENSICS
├── list_executions(workflowId: id, limit: 1) → executionId
├── get_execution_data(executionId) → per-node status
│
├── FOR each node in execution:
│   ├── IF executionStatus: "success" → ✅ pass
│   ├── IF executionStatus: "error" → record:
│   │   ├── nodeName
│   │   ├── nodeType
│   │   ├── error.message
│   │   └── inputData sample (first item)
│   └── IF no execution data → node was not reached (connection issue)
│
└── Output: Error Report

STEP 3: ROOT CAUSE ANALYSIS
├── Classify error type:
│   ├── TYPE_NOT_FOUND → wrong node type → get_node_type_details()
│   ├── EXPRESSION_ERROR → bad {{ }} syntax → check $json paths
│   ├── AUTH_ERROR (401/403) → credential issue → [[credential-manager]]
│   ├── NOT_FOUND (404) → wrong URL/endpoint
│   ├── CONNECTION_ERROR → node not connected or wrong input mapping
│   ├── CODE_ERROR → JavaScript syntax/runtime error in Code node
│   └── TIMEOUT → API too slow → add retry/timeout settings
│
└── Output: Fix Instructions

STEP 4: FIX & RETRY (max 3x)
├── get_workflow(workflowId) → current workflow JSON
├── Route fix instructions to [[builder]]
├── [[builder]] applies fix → creates updated nodes/connections
├── update_workflow(workflowId, { nodes, connections })
└── Go back to STEP 1
```

## Common Error Patterns

| Error                                     | Cause                          | Fix                                                |
| ----------------------------------------- | ------------------------------ | -------------------------------------------------- |
| `"Unknown node type"`                     | Wrong `type` string            | Use `get_node_type_details()` to find correct type |
| `"Cannot read property 'x' of undefined"` | Bad expression/data path       | Check `$json` structure from previous node output  |
| `"NodeOperationError"`                    | Wrong parameters for operation | Check operation-specific required fields           |
| `401 Unauthorized`                        | Missing/wrong credential       | Check credential ID and permissions                |
| `"No input data"/"Cannot find input"`     | Node not connected             | Fix connections{} object                           |
| `"Workflow could not be activated"`       | Invalid trigger configuration  | Check trigger node parameters                      |
| `$input.first() is null`                  | Empty input from previous node | Add null check or conditional                      |

## Execution Data Analysis Patterns

### Check All Node Statuses

```
For each node in get_execution_data(execId):
  - status: "success" | "error" | "waiting"
  - startTime, executionTime
  - data.main[0] → output items
  - error → error object if failed
```

### Data Flow Tracing

When a downstream node fails, trace data backwards:

1. Get failed node's **inputData**
2. Check previous node's **outputData**
3. Compare: is the expected field present?
4. If missing → fix upstream node's output mapping

## Self-Healing Rules

- **Max 3 retry attempts** per workflow
- **Each attempt** must try a **different fix** (don't repeat same fix)
- **Track what was tried** in each iteration for escalation report
- **If same error persists** after fix → likely external issue (API down, permissions)
- After 3 failures → **escalate to user** with full diagnostic
