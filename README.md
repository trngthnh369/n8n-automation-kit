# n8n Automation Kit 🚀

**Comprehensive 4-tier skill kit for fully automated n8n workflow building.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![n8n](https://img.shields.io/badge/n8n-compatible-green.svg)](https://n8n.io)

Build, deploy, debug, and fix n8n workflows **autonomously** using AI agents. Supports Antigravity, Claude Code, Gemini CLI, and Cursor.

## ✨ Features

- **4-Tier Skill Graph**: Orchestrators → Hubs → Utilities → Domain Skills
- **Self-Healing Loop**: Auto deploy → test → fix → retry (up to 3x)
- **5 Domain Skills**: Facebook Ads, Inventory, Content Gen, KPI, Google Sheets
- **Context Optimized**: MOC navigation reduces token usage by 60-80%
- **Agent-Agnostic**: Works with any AI agent that reads `.md` skill files

## 📦 Quick Install

### Antigravity / Gemini CLI

```bash
git clone https://github.com/khoahrv/n8n-automation-kit.git
cd n8n-automation-kit
# Windows
.\setup\install.ps1 -Agent antigravity
# macOS/Linux
./setup/install.sh --agent antigravity
```

### Claude Code

```bash
git clone https://github.com/khoahrv/n8n-automation-kit.git
cd n8n-automation-kit
.\setup\install.ps1 -Agent claude
```

### Manual

Copy the entire `n8n-automation-kit/` folder into your project's `.agents/skills/` directory.

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
    │   ├── Debugger — execute & fix
    │   └── Deployer — deploy & verify
    │
    ├── Tier 3: Utilities (on demand)
    │   ├── n8n-mcp — 24 MCP tools
    │   ├── Google Workspace — gws CLI
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

## 🎯 Usage

Just tell your AI agent what you need:

- _"Build a workflow that scrapes Shopee products and saves to Google Sheets"_
- _"Create a Facebook Ads campaign optimizer with daily scheduling"_
- _"Debug workflow ID abc123 — it's failing at the HTTP node"_

The kit's orchestrator will automatically route to the right skills.

## 📋 Prerequisites

- [n8n-custom-mcp](https://github.com/czlonkowski/n8n-mcp) server running
- n8n instance accessible
- AI agent (Antigravity, Claude Code, Gemini CLI, or Cursor)

## 📝 License

MIT License — see [LICENSE](LICENSE) file.
