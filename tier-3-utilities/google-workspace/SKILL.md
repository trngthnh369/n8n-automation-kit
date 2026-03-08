---
name: google-workspace
tier: 3
category: utility
version: 1.0.0
description: Google Workspace CLI (gws) integration for reading/writing Docs, Sheets, Calendar, Drive, Gmail.
triggers:
  - "google docs"
  - "google sheets"
  - "read spreadsheet"
  - "google calendar"
  - "gws"
  - "read PRD"
requires: []
related:
  - "[[google-sheets]]"
  - "[[orchestrator]]"
---

# 📊 Google Workspace CLI Integration

Use the `gws` CLI to interact with Google Workspace services from AI agents.

## Installation

```bash
npm install -g @googleworkspace/cli
```

## Authentication

```bash
# First-time setup
gws auth login

# Service account (server/CI)
gws auth login --service-account /path/to/key.json
```

## Key Services

### Gmail

```bash
# List messages
gws gmail messages list --max-results 10 --format json

# Read message
gws gmail messages get --id <messageId> --format json

# Send message
gws gmail messages send --to "user@example.com" --subject "Subject" --body "Body"
```

### Google Drive

```bash
# List files
gws drive files list --query "name contains 'PRD'" --format json

# Download file
gws drive files get --file-id <fileId> --format json

# Upload file
gws drive files create --name "report.pdf" --parent <folderId> --file /path/to/file
```

### Google Docs

```bash
# Read document content
gws docs documents get --document-id <docId> --format json

# Update document
gws docs documents batchUpdate --document-id <docId> --requests '[...]'
```

### Google Sheets

```bash
# Read range
gws sheets spreadsheets.values get --spreadsheet-id <id> --range "Sheet1!A1:Z100" --format json

# Write range
gws sheets spreadsheets.values update --spreadsheet-id <id> --range "Sheet1!A1" --values '[["a","b"],["c","d"]]'

# Append rows
gws sheets spreadsheets.values append --spreadsheet-id <id> --range "Sheet1!A1" --values '[["new","row"]]'
```

### Google Calendar

```bash
# List events
gws calendar events list --calendar-id primary --time-min "2025-01-01T00:00:00Z" --format json

# Create event
gws calendar events insert --calendar-id primary --summary "Deploy workflow" --start "2025-01-15T09:00:00+07:00" --end "2025-01-15T10:00:00+07:00"
```

## Usage in n8n Automation Kit

### Reading PRD for Workflow Design

```
1. User provides Google Docs link
2. gws docs documents get --document-id <id> → extract content
3. Parse requirements → pass to [[architect]]
```

### Writing Deployment Reports

```
1. After [[deployer]] completes deployment
2. gws sheets spreadsheets.values append → add row with:
   - Workflow ID, name, status, nodes count, timestamp
```

### Scheduling Workflow Reviews

```
1. After successful deployment
2. gws calendar events insert → create review event
```

## MCP Integration

`gws` supports MCP protocol natively. If configured as an MCP server, tools are available directly to agents without CLI calls.

```json
{
  "mcpServers": {
    "google-workspace": {
      "command": "gws",
      "args": ["mcp", "serve"]
    }
  }
}
```
