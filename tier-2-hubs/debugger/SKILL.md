---
name: n8n-debugger
tier: 2
category: hub
version: 2.0.0
description: End-to-end Self-Healing Loop — execute, analyze logs, classify errors, fix, and re-verify automatically.
triggers:
  - "debug workflow"
  - "fix error"
  - "workflow failed"
  - "execution error"
  - "check logs"
  - "sửa lỗi"
requires:
  - n8n-mcp
related:
  - "[[builder]]"
  - "[[deployer]]"
---

# 🐛 n8n Debugger

End-to-end Self-Healing Loop: execute, analyze execution logs, classify errors, route fixes to `[[builder]]`, and re-verify automatically.

> ⛔ **MCP-FIRST**: Debug loop **PHẢI** dùng MCP tools:
> `execute_workflow()`, `list_executions()`, `get_execution_data()`, `get_workflow()`, `update_workflow()`.
> **KHÔNG BAO GIỜ** viết script gọi n8n API trực tiếp hoặc dùng `curl`/`fetch()` để test workflow.

## ⭐ Self-Healing Loop Protocol

This is the **core loop** that makes the Agent fully autonomous. After `[[deployer]]` deploys a workflow, the Debugger takes over:

```
┌────────────────────────────────────────────────────┐
│                 SELF-HEALING LOOP                   │
│                                                    │
│  EXECUTE ──→ CHECK LOGS ──→ ANALYZE ──→ FIX       │
│     ↑                                    │         │
│     └────────────── RE-EXECUTE ──────────┘         │
│                  (max 3 iterations)                │
└────────────────────────────────────────────────────┘
```

### Step 1: EXECUTE

```
execute_workflow(workflowId)
├── 200 + success → Step 2 (verify all nodes)
├── 404 → Runner down:
│   └── activate_workflow("<RUNNER_ID>", true) → wait 2s → retry
└── 500 → workflow error → Step 2
```

### Step 2: CHECK LOGS (Forensics)

```
list_executions(workflowId: id, limit: 1) → executionId
get_execution_data(executionId) → per-node status
│
FOR each node in execution data:
├── IF executionStatus: "success" → ✅ pass
├── IF executionStatus: "error" → record:
│   ├── nodeName
│   ├── nodeType
│   ├── error.message
│   └── inputData sample (first item)
└── IF no execution data → node was not reached (connection issue)
│
Output: Error Report
```

### Step 3: ROOT CAUSE ANALYSIS

Classify error by type → map to fix strategy:

| Error Pattern                             | Type               | Fix Strategy                                     |
| ----------------------------------------- | ------------------ | ------------------------------------------------ |
| `"Unknown node type"`                     | TYPE_NOT_FOUND     | `get_node_type_details()` → fix `node.type`      |
| `"Cannot read property 'x' of undefined"` | EXPRESSION_ERROR   | Check `$json` paths from previous node output    |
| `401 Unauthorized` / `403 Forbidden`      | AUTH_ERROR         | Check credential ID → `[[credential-manager]]`   |
| `404 Not Found`                           | ENDPOINT_NOT_FOUND | Verify URL/endpoint                              |
| `"No input data"` / `"Cannot find input"` | CONNECTION_ERROR   | Fix `connections{}` object                       |
| `"NodeOperationError"`                    | PARAM_ERROR        | Check operation-specific required fields         |
| `$input.first() is null`                  | EMPTY_INPUT        | Add null check or conditional                    |
| `"Workflow could not be activated"`       | TRIGGER_ERROR      | Check trigger node parameters (path, cron, etc.) |
| `TIMEOUT`                                 | TIMEOUT            | Add retry/timeout settings to HTTP node          |
| Code node syntax error                    | CODE_ERROR         | Fix JavaScript syntax in Code node               |

### Step 4: FIX & RE-DEPLOY (max 3 iterations)

```
ITERATION n (n = 1..3):
├── get_workflow(workflowId) → current JSON
├── Route fix instructions to [[builder]]
├── [[builder]] applies targeted fix → updated nodes/connections
├── update_workflow(workflowId, { nodes, connections })
├── Log: "Iteration n: Fixed [nodeName] - [error type] - [what changed]"
└── Go back to Step 1
```

### Step 5: ESCALATE or FINALIZE

```
IF all nodes pass after fix:
├── ✅ SUCCESS
├── tag_workflow(workflowId, tagIds)
└── Report to user: workflow ID, name, test results

IF 3 iterations failed:
├── ❌ ESCALATE TO USER
├── Report:
│   ├── Which node is still failing
│   ├── Error message
│   ├── What was tried in each iteration
│   └── Suggested next steps (e.g., need manual credential, API permission)
└── DO NOT retry further
```

---

## Data Flow Tracing

When a downstream node fails, trace data backwards:

```
1. Get failed node's inputData (from get_execution_data)
2. Get previous node's outputData
3. Compare: is the expected field/key present?
4. IF missing → fix upstream node's output mapping
5. IF present but wrong type → add type conversion
6. IF empty array → check filter/condition upstream
```

## Execution Data Analysis

### Per-Node Status Check

```
For each node in get_execution_data(execId):
  - executionStatus: "success" | "error" | "waiting"
  - startTime, executionTime → performance profiling
  - data.main[0] → output items (verify data shape)
  - error → error object if failed
```

### Output Verification Checklist

After a successful execution, verify data quality:

- [ ] All expected nodes executed (no skipped nodes)
- [ ] Output data has expected fields and format
- [ ] No empty arrays where data was expected
- [ ] Numeric values are within expected range
- [ ] Date/time values are in correct timezone
- [ ] API responses contain expected status codes

---

## Common Error Patterns & Fixes

### Expression Errors (Most Common)

```
Error: "Cannot read property 'name' of undefined"
└── Cause: $json.data.name but previous node outputs $json.result.name
└── Fix: get_execution_data → inspect actual output shape → update expression
```

### Connection Mismatches

```
Error: "No input data" on Node B
└── Cause: Node A not connected to Node B in connections{}
└── Fix: Add {"Node A": {"main": [[{"node": "Node B", "type": "main", "index": 0}]]}}
```

### Credential Issues

```
Error: 401/403 from API call
└── Cause: Wrong credential ID or expired token
└── Fix: get_credential_schema → verify type → check with [[credential-manager]]
```

---

## Self-Healing Rules

- **Max 3 retry attempts** per workflow
- **Each attempt** must try a **different fix** (don't repeat same fix)
- **Track what was tried** — log each iteration's fix for escalation report
- **If same error persists** after fix → likely external issue (API down, permissions)
- After 3 failures → **escalate to user** with full diagnostic report
- **ALWAYS** use `get_execution_data` after execute — never assume success from status code alone
