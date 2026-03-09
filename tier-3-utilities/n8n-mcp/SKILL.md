---
name: n8n-mcp-tools
tier: 3
category: utility
version: 2.0.0
description: Reference for 24 MCP tools + Self-Healing Automation Loop. Core utility used by all hubs.
triggers:
  - "MCP tool"
  - "n8n API"
  - "list workflows"
  - "execute workflow"
  - "self-healing"
requires: []
related:
  - "[[builder]]"
  - "[[debugger]]"
  - "[[deployer]]"
  - "[[credential-manager]]"
---

# ⚡ n8n MCP Tools Reference

24 tools for full n8n lifecycle management. MCP server v2.1.0 at `localhost:3000/mcp`.

## Workflow Management (7 tools)

| Tool                 | Purpose                                   | Key Params                       |
| -------------------- | ----------------------------------------- | -------------------------------- |
| `list_workflows`     | List workflows                            | `active?`, `limit?`, `tags?`     |
| `get_workflow`       | Get workflow details (nodes, connections) | `id`                             |
| `create_workflow`    | Create new workflow                       | `name`, `nodes?`, `connections?` |
| `update_workflow`    | Update existing workflow                  | `id`, `nodes?`, `connections?`   |
| `delete_workflow`    | Delete workflow                           | `id`                             |
| `activate_workflow`  | Toggle active state                       | `id`, `active`                   |
| `duplicate_workflow` | Clone workflow                            | `id`, `name?`                    |

## Execution & Testing (2 tools)

| Tool               | Purpose                         | Key Params                                       |
| ------------------ | ------------------------------- | ------------------------------------------------ |
| `execute_workflow` | Run workflow by ID (via Runner) | `id`, `inputData?`                               |
| `trigger_webhook`  | Call webhook endpoint           | `webhook_path`, `method?`, `body?`, `test_mode?` |

**Important**: `execute_workflow` uses Runner Workflow. If 404 → reactivate Runner first.

## Debugging & Monitoring (4 tools)

| Tool                 | Purpose                                            | Key Params                         |
| -------------------- | -------------------------------------------------- | ---------------------------------- |
| `list_executions`    | List recent executions                             | `status?`, `limit?`, `workflowId?` |
| `get_execution`      | Execution metadata                                 | `id`                               |
| `get_execution_data` | **Node-level execution data** — primary debug tool | `id`, `nodeName?`, `maxItems?`     |
| `list_node_types`    | List available node types                          | `search?`                          |

## Community Templates (2 tools)

| Tool               | Purpose                    | Key Params                     |
| ------------------ | -------------------------- | ------------------------------ |
| `search_templates` | Search n8n.io templates    | `search`, `category?`, `rows?` |
| `get_template`     | Get template workflow JSON | `id`                           |

## Credentials (3 tools)

| Tool                    | Purpose               | Key Params             |
| ----------------------- | --------------------- | ---------------------- |
| `get_credential_schema` | Find credential types | `credentialTypeName`   |
| `create_credential`     | Create new credential | `name`, `type`, `data` |
| `delete_credential`     | Delete credential     | `id`                   |

## Node Discovery (1 tool)

| Tool                    | Purpose                              | Key Params |
| ----------------------- | ------------------------------------ | ---------- |
| `get_node_type_details` | Node type details with real examples | `nodeType` |

## Tag Management (5 tools)

| Tool           | Purpose                 | Key Params               |
| -------------- | ----------------------- | ------------------------ |
| `list_tags`    | List all tags           | —                        |
| `create_tag`   | Create tag              | `name`                   |
| `update_tag`   | Rename tag              | `id`, `name`             |
| `delete_tag`   | Delete tag              | `id`                     |
| `tag_workflow` | Assign tags to workflow | `workflowId`, `tagIds[]` |

**⚠️ `tag_workflow` REPLACES all tags** — fetch existing tags first!

---

## ⭐ Self-Healing Automation Loop (QUAN TRỌNG NHẤT)

Vòng lặp chính cho phép AI Agent **tự động deploy, test, debug, và fix** workflow cho đến khi chạy đúng.

### Cơ chế `execute_workflow`

`execute_workflow` **KHÔNG gọi** n8n Public API (vì API không hỗ trợ). Thay vào đó:

```
Agent gọi execute_workflow(workflowId)
  → MCP server gọi POST /webhook/mcp-run-workflow với body { workflowId }
    → [MCP] Workflow Runner nhận webhook
      → Execute Workflow node chạy workflow target
        → Respond to Webhook trả kết quả về Agent
```

**Runner phải luôn active.** Nếu bị tắt → `execute_workflow` trả 404.
Cách tự fix: `activate_workflow("<RUNNER_ID>", active: true)` → thử lại.

### Quy trình 6 Bước: Deploy → Execute → Check → Fix → Verify

```
BƯỚC 1: CHUẨN BỊ
├── list_workflows() → kiểm tra workflow đã tồn tại chưa, tránh duplicate
├── get_node_type_details("nodeType") → tham khảo cấu hình thực tế nếu cần
└── Xây dựng nodes[] và connections{} cho workflow

BƯỚC 2: DEPLOY
├── create_workflow(name, nodes, connections) → workflowId
└── activate_workflow(workflowId, active: true)

BƯỚC 3: EXECUTE
└── execute_workflow(workflowId)
    ├── Nếu response có "success: true" → BƯỚC 4
    ├── Nếu 404 → Runner bị tắt:
    │   activate_workflow("<RUNNER_ID>", true) → thử lại
    └── Nếu 500 → workflow lỗi → BƯỚC 4

BƯỚC 4: CHECK RESULT
├── list_executions(workflowId: workflowId, limit: 1) → lấy executionId
├── get_execution_data(executionId) → xem status từng node
│
├── IF tất cả nodes có "executionStatus": "success"
│   └── ✅ ĐÃ ĐÚNG → BƯỚC 6
│
└── IF có node lỗi (error != null hoặc executionStatus: "error")
    └── Ghi nhận nodeName, error message, outputSample → BƯỚC 5

BƯỚC 5: FIX & RE-DEPLOY (tối đa 3 lần)
├── get_workflow(workflowId) → lấy workflow JSON hiện tại
├── Phân tích lỗi và fix:
│   ├── "Node type not found" → sửa node.type (dùng get_node_type_details)
│   ├── "Cannot read property" → sửa expression trong parameters
│   ├── HTTP 401/403 → credential sai (dùng get_credential_schema)
│   ├── HTTP 404 → URL endpoint sai
│   └── "Cannot find input" → sửa connections
├── update_workflow(workflowId, { nodes: fixedNodes, connections: fixedConnections })
└── Quay lại BƯỚC 3

BƯỚC 6: FINALIZE
├── tag_workflow(workflowId, tagIds) → gán tags phù hợp
└── Thông báo user: workflow ID, tên, kết quả test
```

### Giới hạn retry

**Tối đa 3 lần** fix & retry. Nếu sau 3 lần vẫn lỗi → dừng lại và báo user:

- Node nào lỗi và error message
- Đã thử fix gì qua mỗi iteration
- Đề xuất hướng xử lý tiếp (vd: cần tạo credential, cần quyền API...)

---

## Other Patterns

### Pattern: Clone & Modify (an toàn cho production)

```
1. list_workflows(tags: "Production") → tìm workflow gốc
2. duplicate_workflow(sourceId, "V2 - Enhanced") → newId (inactive)
3. get_workflow(newId) → lấy structure
4. Sửa nodes/connections → update_workflow(newId, updates)
5. activate_workflow(newId, true) → execute_workflow(newId)
6. get_execution_data(executionId) → verify
```

### Pattern: Template Import

```
1. search_templates("slack notification")
2. get_template(templateId) → nodes, connections
3. create_workflow("My Slack Bot", nodes, connections)
4. activate_workflow(newId, true) → execute_workflow(newId)
```

### Pattern: Debug Failed Execution

```
1. list_executions(status: "error", limit: 5) → tìm execution lỗi
2. get_execution_data(executionId) → node nào lỗi + error
3. get_node_type_details("nodeType") → xem config đúng
4. get_workflow(workflowId) → lấy workflow, fix, update_workflow
5. execute_workflow(workflowId) → test lại
```

---

## Important Rules

### DO

- **Luôn dùng `get_execution_data`** sau khi execute để verify kết quả
- **Dùng `list_workflows`** trước khi tạo mới — tránh duplicate
- **Dùng `get_node_type_details`** khi không chắc về cấu hình node
- **Dùng `duplicate_workflow`** thay vì sửa trực tiếp workflow production
- **Tag workflow** sau khi tạo xong bằng `tag_workflow`
- **Tự kích hoạt lại Runner** nếu `execute_workflow` trả 404

### DON'T

- **Không sửa trực tiếp** workflow đang active trong production — clone trước
- **Không `delete_workflow`** mà không hỏi user trước
- **Không `delete_credential`** — workflows đang dùng sẽ break
- **`tag_workflow` thay thế** toàn bộ tags — lấy tags hiện tại trước khi gán mới
- **Không retry quá 3 lần** — báo user nếu không fix được

---

## n8n Node JSON Structure

Khi tạo workflow, mỗi node cần structure sau:

```json
{
  "type": "n8n-nodes-base.webhook",
  "typeVersion": 2,
  "name": "My Webhook",
  "position": [250, 300],
  "parameters": {
    "path": "my-endpoint",
    "httpMethod": "POST",
    "responseMode": "responseNode"
  }
}
```

Connections format:

```json
{
  "My Webhook": {
    "main": [[{ "node": "Next Node", "type": "main", "index": 0 }]]
  }
}
```

**Tip**: Dùng `get_node_type_details("webhook")` để xem cấu hình thực tế từ workflows hiện có.
