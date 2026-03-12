---
name: n8n-builder
tier: 2
category: hub
version: 2.0.0
description: Constructs production-grade n8n workflow JSON with dual-output error handling, error funnel, credential assignment, and resilience patterns.
triggers:
  - "build nodes"
  - "create JSON"
  - "construct workflow"
  - "add node"
  - "create nodes"
requires:
  - n8n-mcp
recommends:
  - credential-manager
  - google-workspace
related:
  - "[[architect]]"
  - "[[debugger]]"
  - "[[deployer]]"
---

# 🔨 n8n Builder

Constructs production-ready n8n workflow JSON from the `[[architect]]`'s SSOT design. Applies Builder v5 standards.

> ⚡ **MCP-FIRST**: Sau khi xây dựng workflow JSON, **ưu tiên dùng `create_workflow()` / `update_workflow()`** từ MCP tools.
> **Fallback**: Nếu MCP không available → viết script gọi n8n REST API (`POST /api/v1/workflows`) với `N8N_URL` + `N8N_API_KEY` từ user.
> Kiểm tra node type → `get_node_type_details()` (MCP) hoặc `GET /api/v1/node-types` (fallback).

## ⭐ Production Workflow Topology (BẮT BUỘC)

> **KHÔNG BAO GIỜ** build workflow thành 1 pipeline thẳng đơn giản.
> **MỌI workflow** phải có: dual-output trên risky nodes + error funnel + error logger.

### Topology chuẩn

```
Trigger ──→ Process A ──┬──→ Process B ──┬──→ Process C ──→ Final Output
                        │                │
                   [error out]      [error out]
                        │                │
                        └───────┬────────┘
                                ↓
                      Error Normalizer ──→ Log Error to Sheet
```

### Cách triển khai trên mỗi risky node

**Risky nodes** = HTTP Request, Code, AI/LLM, Database query, API calls — bất kỳ node nào có thể fail.

1. **Thêm `"onError": "continueErrorOutput"`** vào node
2. **Main output (index 0)** → nối sang node kế tiếp (success path)
3. **Error output (index 1)** → nối sang Error Normalizer (error path)

```json
{
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "name": "Fetch_API_Data",
  "position": [500, 300],
  "onError": "continueErrorOutput",
  "parameters": {
    "method": "GET",
    "url": "https://api.example.com/data",
    "options": {
      "timeout": 30000
    }
  },
  "credentials": {
    "httpHeaderAuth": {
      "id": "<CREDENTIAL_ID>",
      "name": "<CREDENTIAL_NAME>"
    }
  }
}
```

### Error Normalizer Node (bắt buộc trong mọi workflow)

```json
{
  "type": "n8n-nodes-base.code",
  "typeVersion": 2,
  "name": "Error_Normalizer",
  "position": [1200, 800],
  "parameters": {
    "jsCode": "const { DateTime } = require('luxon');\nconst items = $input.all();\nreturn items.map(item => ({\n  json: {\n    source_node: item.json.$prevNode?.name || 'Unknown',\n    error_message: item.json.message || item.json.error || JSON.stringify(item.json),\n    timestamp: DateTime.now().setZone('Asia/Ho_Chi_Minh').toISO(),\n    severity: 'error',\n    workflow_id: $workflow.id,\n    workflow_name: $workflow.name\n  }\n}));"
  }
}
```

### Error Logger Node (ghi log ra Google Sheets)

```json
{
  "type": "n8n-nodes-base.googleSheets",
  "typeVersion": 4.5,
  "name": "Log_Error_to_Sheet",
  "position": [1550, 800],
  "parameters": {
    "operation": "append",
    "documentId": {
      "mode": "id",
      "value": "={{ $json.log_sheet_id || 'DEFAULT_SHEET_ID' }}"
    },
    "sheetName": {
      "mode": "name",
      "value": "Error_Logs"
    },
    "columns": {
      "mappingMode": "autoMapInputData"
    },
    "options": {
      "cellFormat": "USER_ENTERED"
    }
  },
  "credentials": {
    "googleSheetsOAuth2Api": {
      "id": "<CREDENTIAL_ID>",
      "name": "<CREDENTIAL_NAME>"
    }
  }
}
```

### Connections cho Dual-Output + Error Funnel

```json
{
  "Trigger": {
    "main": [[{ "node": "Fetch_API_Data", "type": "main", "index": 0 }]]
  },
  "Fetch_API_Data": {
    "main": [
      [{ "node": "Process_Data", "type": "main", "index": 0 }],
      [{ "node": "Error_Normalizer", "type": "main", "index": 0 }]
    ]
  },
  "Process_Data": {
    "main": [
      [{ "node": "Write_to_Sheet", "type": "main", "index": 0 }],
      [{ "node": "Error_Normalizer", "type": "main", "index": 0 }]
    ]
  },
  "Error_Normalizer": {
    "main": [[{ "node": "Log_Error_to_Sheet", "type": "main", "index": 0 }]]
  }
}
```

## Node JSON Structure

Every node requires:

```json
{
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "name": "Descriptive_Name",
  "position": [500, 300],
  "onError": "continueErrorOutput",
  "parameters": { ... },
  "credentials": {
    "<credentialType>": {
      "id": "<id>",
      "name": "<name>"
    }
  }
}
```

### Required Fields

| Field | Rule |
|---|---|
| `type` | Full qualified: `n8n-nodes-base.[name]` — dùng `get_node_type_details()` nếu không chắc |
| `typeVersion` | **Phải đúng version**. Dùng `get_node_type_details()` để verify |
| `name` | Unique, descriptive. Pattern: `[Action]_[Target]` hoặc `[System]_[Module]_[Action]` |
| `position` | X +350px mỗi node. Error lane ở Y +500px |
| `onError` | `"continueErrorOutput"` cho mọi risky node |
| `credentials` | **BẮT BUỘC** nếu node cần auth — dùng `[[credential-manager]]` protocol |

## Connections Structure

### Single Output
```json
{ "Source": { "main": [[{ "node": "Target", "type": "main", "index": 0 }]] } }
```

### Multi-Output (IF/Switch)
```json
{
  "IF Node": {
    "main": [
      [{ "node": "True Branch", "type": "main", "index": 0 }],
      [{ "node": "False Branch", "type": "main", "index": 0 }]
    ]
  }
}
```

### Dual-Output (Success + Error) — MỌI risky node
```json
{
  "Risky Node": {
    "main": [
      [{ "node": "Next Success Node", "type": "main", "index": 0 }],
      [{ "node": "Error_Normalizer", "type": "main", "index": 0 }]
    ]
  }
}
```

## Visual Topology Rules

```
X-axis: +350px between sequential nodes
Y-axis: Same row for main success flow
Error lane: Y +500px (side-car lane, all error outputs funnel here)
Sub-workflow calls: Y +250px (parallel lane)
```

## Builder v5 Construction Checklist

Before outputting JSON, verify ALL items:

- [ ] **Credential Protocol** — chạy `[[credential-manager]]` discovery, gắn credential cho mọi node cần auth
- [ ] **Dual-output** — mọi risky node có `"onError": "continueErrorOutput"`
- [ ] **Error funnel** — tất cả error outputs → Error Normalizer → Log to Sheet
- [ ] **Workflow settings** include `"timezone": "Asia/Ho_Chi_Minh"`
- [ ] **Node names** descriptive, unique, dùng underscore
- [ ] **Expressions** đúng syntax: `{{ $json.field }}` không phải `{{ json.field }}`
- [ ] **Code nodes** return `[{ json: { ... } }]` format
- [ ] **Webhook data** truy cập qua `$json.body.field`
- [ ] **Position** không overlap (min 350px X gap)
- [ ] **All credentials** có cả `id` VÀ `name`

## Code Node Patterns

### Standard Return (MUST)
```javascript
// ✅ Correct
return $input.all().map((item) => ({
  json: { ...item.json, processed: true },
}));

// ❌ Wrong — will fail
return { processed: true };
```

### Timestamp with Timezone
```javascript
const { DateTime } = require("luxon");
const now = DateTime.now().setZone("Asia/Ho_Chi_Minh").toISO();
```

## Workflow Settings Template

```json
{
  "name": "Workflow Name",
  "nodes": [...],
  "connections": {...},
  "settings": {
    "timezone": "Asia/Ho_Chi_Minh",
    "saveManualExecutions": true,
    "callerPolicy": "workflowsFromSameOwner",
    "errorWorkflow": ""
  }
}
```

## Tool Usage During Build

1. **FIRST**: `[[credential-manager]]` → discover & assign credentials
2. **Before node**: `get_node_type_details(nodeType)` → verify type, version, parameters
3. **Build**: Construct JSON with dual-output + error funnel topology
4. **Deploy**: Hand off to `[[deployer]]` via `create_workflow()`
