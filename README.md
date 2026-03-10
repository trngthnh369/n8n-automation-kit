# n8n Automation Kit 🚀

**Comprehensive 4-tier skill kit for fully automated n8n workflow building.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![npm](https://img.shields.io/npm/v/n8n-automation-kit.svg)](https://www.npmjs.com/package/n8n-automation-kit)
[![n8n](https://img.shields.io/badge/n8n-compatible-green.svg)](https://n8n.io)

Build, deploy, debug, and fix n8n workflows **autonomously** using AI agents. Supports Antigravity, Claude Code, Gemini CLI, and Cursor.

## ✨ Features

- **4-Tier Skill Graph**: Orchestrators → Hubs → Utilities → Domain Skills
- **Self-Healing Loop**: Auto deploy → test → fix → retry (up to 3x)
- **MCP-First / JS-Fallback**: Uses MCP tools when available, REST API fallback when not
- **5 Domain Skills**: Facebook Ads, Inventory, Content Gen, KPI, Google Sheets
- **Context Optimized**: MOC navigation reduces token usage by 60-80%
- **Agent-Agnostic**: Works with any AI agent that reads `.md` skill files

## 📋 Prerequisites

### Required

- **n8n instance** running (self-hosted or cloud)
- **AI agent**: Antigravity, Claude Code, Gemini CLI, or Cursor

### Recommended (for full automation)

- **n8n-custom-mcp server** — enables 24 MCP tools including `execute_workflow`, `get_execution_data`, and the full Self-Healing Loop

> ⚠️ **Without MCP server**: Kit still works in JS-Fallback mode (agent writes code to call n8n REST API), but the Self-Healing Loop and `execute_workflow` are **not available**.

## 🔧 Setup

### Step 1: Install the Kit

```bash
# Option A: npm
npm install n8n-automation-kit

# Option B: Git clone
git clone https://github.com/trngthnh369/n8n-automation-kit.git
```

### Step 2: Copy skills to your project

```bash
# Windows (PowerShell)
.\setup\install.ps1 -Agent antigravity

# macOS/Linux
./setup/install.sh --agent antigravity
```

Supported agents: `antigravity`, `claude-code`, `gemini-cli`, `cursor`

### Step 3: Setup MCP Server (Recommended)

This step enables the full Self-Healing Loop and all 24 MCP tools.

```bash
# Windows (PowerShell)
.\setup\setup-mcp.ps1

# macOS/Linux
./setup/setup-mcp.sh
```

The script will:

1. Clone and build [n8n-custom-mcp](https://github.com/czlonkowski/n8n-mcp)
2. Ask for your n8n URL and API key
3. Generate the MCP config for your agent

**Manual setup**: See [MCP Setup Guide](setup/SETUP-MCP.md) for details.

## 🏗️ Architecture

```
_moc.md (Entry Point)
    │
    ├── Tier 1: Orchestrator (auto-loaded)
    │   └── Routes requests → detects intent → manages pipeline
    │
    ├── Tier 2: Workflow Hubs (on demand)
    │   ├── Architect — design SSOT
    │   ├── Builder — construct JSON
    │   ├── Debugger — execute & fix (Self-Healing Loop)
    │   └── Deployer — deploy & verify
    │
    ├── Tier 3: Utilities (on demand)
    │   ├── n8n-mcp — 24 MCP tools reference
    │   ├── Google Workspace — Sheets/Drive/Gmail
    │   ├── Credential Manager
    │   └── Template Library
    │
    └── Tier 4: Domains (by project type)
        ├── Facebook Ads
        ├── Inventory
        ├── Content Gen
        ├── KPI Automation
        └── Google Sheets
```

### Hybrid Mode (MCP-First / JS-Fallback)

```
IF MCP tools available → Full automation (Self-Healing Loop)
ELSE → JS-Fallback (deploy-only, no auto-test)
```

## 🎯 Usage

Just tell your AI agent what you need:

- _"Build a workflow that scrapes Shopee products and saves to Google Sheets"_
- _"Create a Facebook Ads campaign optimizer with daily scheduling"_
- _"Debug workflow ID abc123 — it's failing at the HTTP node"_

The kit's orchestrator will automatically route to the right skills.

## 📝 License

MIT License — see [LICENSE](LICENSE) file.

## 👤 Author

**Turti** (Nguyễn Trường Thịnh) — [GitHub](https://github.com/trngthnh369)
