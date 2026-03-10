---
name: n8n-builder
tier: 2
category: hub
version: 1.0.0
description: Constructs n8n workflow JSON from SSOT design. Applies Builder v5 standards with resilience patterns.
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
related:
  - "[[architect]]"
  - "[[debugger]]"
  - "[[deployer]]"
---

# 🔨 n8n Builder

Constructs production-ready n8n workflow JSON from the `[[architect]]`'s SSOT design. Applies Builder v5 standards.

> ⛔ **MCP-FIRST**: Sau khi xây dựng workflow JSON, **PHẢI dùng `create_workflow()` hoặc `update_workflow()`** từ MCP tools để deploy.
> **KHÔNG BAO GIỜ** viết script JS/Python gọi `fetch()` / `axios` tới n8n API.
> Nếu cần kiểm tra node type → dùng `get_node_type_details()`. Nếu cần xem workflow hiện có → dùng `get_workflow()`.

## Node JSON Structure

Every node requires this structure:

```json
{
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "name": "Fetch Products",
  "position": [500, 300],
  "parameters": {
    "method": "GET",
    "url": "https://api.example.com/products"
  },
  "onError": "continueErrorOutput"
}
```

### Required Fields

| Field         | Rule                                                                              |
| ------------- | --------------------------------------------------------------------------------- |
| `type`        | Full qualified: `n8n-nodes-base.[name]` — Use `get_node_type_details()` if unsure |
| `typeVersion` | **Must match** available version. Use `get_node_type_details()` to verify         |
| `name`        | Unique, descriptive: `[System]_[Module]_[Action]`                                 |
| `position`    | X-axis +350px per node. Error lane at Y +500px                                    |
| `parameters`  | Operation-specific. Only include required fields                                  |

## Connections Structure

```json
{
  "Source Node Name": {
    "main": [[{ "node": "Next Node Name", "type": "main", "index": 0 }]]
  }
}
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

### Error Output (Split-Path Resilience)

```json
{
  "Risky Node": {
    "main": [
      [{ "node": "Next Success Node", "type": "main", "index": 0 }],
      [{ "node": "Error Normalizer", "type": "main", "index": 0 }]
    ]
  }
}
```

## Visual Topology Rules

```
X-axis: +350px between sequential nodes
Y-axis: Same row for main flow
Error funnel: Y +500px (side-car lane)
Sub-workflow calls: Y +250px (parallel lane)
```

## Builder v5 Construction Checklist

Before outputting JSON, verify:

- [ ] **All risky nodes** (HTTP, API, AI) have `"onError": "continueErrorOutput"`
- [ ] **Error funnel** exists: all error outputs → single Universal Error Normalizer
- [ ] **Workflow settings** include `"timezone": "Asia/Ho_Chi_Minh"`
- [ ] **Node names** follow `[System]_[Module]_[Action]` pattern
- [ ] **Expressions** use correct syntax: `{{ $json.field }}` not `{{ json.field }}`
- [ ] **Code nodes** return `[{ json: { ... } }]` format
- [ ] **Webhook data** accessed via `$json.body.field`
- [ ] **Credentials** referenced by name, not hardcoded tokens
- [ ] **Position** values don't overlap (min 350px X gap)

## Code Node Patterns

### Standard Return Format (MUST)

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

### Error Normalizer Template

```javascript
const error = $input.first().json;
return [
  {
    json: {
      source: $prevNode.name,
      error: error.message || JSON.stringify(error),
      timestamp: DateTime.now().setZone("Asia/Ho_Chi_Minh").toISO(),
      severity: "error",
    },
  },
];
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

1. **Before building**: `get_node_type_details(nodeType)` — verify type, version, parameters
2. **During build**: Construct JSON following patterns above
3. **After build**: Hand off to `[[deployer]]` for deployment
4. **If credentials needed**: Route to `[[credential-manager]]` first
