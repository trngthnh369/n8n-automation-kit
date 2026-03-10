# MCP Server Setup Guide

## What is n8n-custom-mcp?

The n8n-custom-mcp server provides **24 MCP tools** that enable AI agents to manage n8n workflows programmatically. This is the core infrastructure that powers the **Self-Healing Loop** — the kit's ability to auto-deploy, test, debug, and fix workflows.

## Without MCP Server

| Feature                       | Available?                           |
| ----------------------------- | ------------------------------------ |
| Skill instructions (SKILL.md) | ✅ Yes                               |
| Build workflow JSON           | ✅ Yes                               |
| Deploy via REST API (JS code) | ✅ Yes (fallback)                    |
| Execute workflow              | ❌ No (n8n API doesn't support this) |
| Get execution data (per-node) | ⚠️ Limited                           |
| Self-Healing Loop             | ❌ No                                |
| Full automation               | ❌ No                                |

## With MCP Server

| Feature                       | Available?                             |
| ----------------------------- | -------------------------------------- |
| Everything above              | ✅ Yes                                 |
| Execute workflow              | ✅ Yes (via Runner Workflow)           |
| Get execution data (per-node) | ✅ Yes                                 |
| Self-Healing Loop             | ✅ Yes (execute → check → fix → retry) |
| Full automation               | ✅ Yes                                 |

## Prerequisites

- **Node.js** >= 18.x ([download](https://nodejs.org))
- **Git** ([download](https://git-scm.com))
- **n8n instance** running with API enabled
- **n8n API key** (from n8n → Settings → API → Add API Key)

## Automatic Setup

```bash
# Windows
.\setup\setup-mcp.ps1

# macOS/Linux
./setup/setup-mcp.sh

# With parameters (non-interactive)
.\setup\setup-mcp.ps1 -N8nUrl "https://your-n8n.example.com" -N8nApiKey "your-key"
./setup/setup-mcp.sh "https://your-n8n.example.com" "your-key"
```

## Manual Setup

### 1. Clone and build

```bash
git clone https://github.com/czlonkowski/n8n-mcp.git n8n-custom-mcp
cd n8n-custom-mcp
npm install
npm run build
```

### 2. Configure

Create `.env` in the mcp directory:

```env
N8N_BASE_URL=https://your-n8n.example.com
N8N_API_KEY=your-api-key-here
PORT=3000
```

### 3. Add to agent MCP config

**Antigravity** (`.gemini/settings.json`):

```json
{
  "mcpServers": {
    "n8n": {
      "command": "node",
      "args": ["/path/to/n8n-custom-mcp/dist/index.js"],
      "env": {
        "N8N_BASE_URL": "https://your-n8n.example.com",
        "N8N_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

**Claude Code** (`.claude/mcp.json`):

```json
{
  "mcpServers": {
    "n8n": {
      "command": "node",
      "args": ["/path/to/n8n-custom-mcp/dist/index.js"],
      "env": {
        "N8N_BASE_URL": "https://your-n8n.example.com",
        "N8N_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

**Cursor** (`.cursor/mcp.json`): Same format as Claude Code.

### 4. Setup Runner Workflow (Required for execute_workflow)

The `execute_workflow` tool requires a **Runner Workflow** in your n8n instance:

1. Import the Runner Workflow (available in `setup/runner-workflow.json` if included)
2. Or create manually: Webhook → Execute Workflow → Respond to Webhook
3. Activate it — **must always be active**
4. Note the workflow ID — your MCP server needs this

### 5. Verify

Ask your AI agent:

```
"List all active workflows"
```

If it responds using `list_workflows` MCP tool → ✅ Setup complete!
If it writes JavaScript code → ❌ MCP not configured, check steps above.

## Troubleshooting

| Problem                                    | Solution                                                  |
| ------------------------------------------ | --------------------------------------------------------- |
| Agent writes JS instead of using MCP tools | MCP server not in agent config — check step 3             |
| `execute_workflow` returns 404             | Runner Workflow is inactive — activate it in n8n          |
| Agent can't find MCP tools                 | Restart your AI agent after config change                 |
| Connection refused                         | MCP server not running — `cd n8n-custom-mcp && npm start` |
