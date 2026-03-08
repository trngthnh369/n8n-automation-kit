---
name: n8n-mcp-tools
tier: 3
category: utility
version: 1.0.0
description: Reference for 24 MCP tools to manage n8n workflow lifecycle. Core utility used by all hubs.
triggers:
  - "MCP tool"
  - "n8n API"
  - "list workflows"
  - "execute workflow"
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

**Important**: `execute_workflow` uses Runner Workflow (ID: `yl69fJwZ0BASjDmB`). If 404 → reactivate Runner first.

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

## Usage Patterns

### Discovery → Build

```
get_node_type_details("httpRequest") → learn params
create_workflow(name, nodes, connections) → deploy
```

### Debug → Fix → Verify

```
list_executions(workflowId, limit: 1) → execId
get_execution_data(execId) → find failing node
get_workflow(workflowId) → get current JSON
update_workflow(workflowId, fixedNodes) → apply fix
execute_workflow(workflowId) → re-test
```

### Template → Customize

```
search_templates("slack notification") → templateId
get_template(templateId) → nodes, connections
create_workflow("My Slack Bot", nodes, connections) → customize
```
