---
name: credential-manager
tier: 3
category: utility
version: 2.0.0
description: Credential discovery, assignment, and lifecycle. MUST discover existing credentials before building nodes.
triggers:
  - "credential"
  - "authentication"
  - "API key"
  - "OAuth"
  - "service account"
requires:
  - n8n-mcp
related:
  - "[[builder]]"
  - "[[google-workspace]]"
---

# 🔑 Credential Manager

Manages credential lifecycle: **discover existing → assign to nodes → create if missing**.

## ⭐ Credential Assignment Protocol (BẮT BUỘC)

> **TRƯỚC KHI build bất kỳ node nào cần auth**, PHẢI chạy protocol này.
> Không bao giờ để node thiếu credential hoặc tự tạo mới khi đã có sẵn.

```
BƯỚC 1: DISCOVER
├── get_credential_schema(credentialTypeName) → xem có credential nào tồn tại
├── Hoặc: Xem danh sách credentials trong n8n UI
└── Ghi nhận: { id, name, type } của mỗi credential có sẵn

BƯỚC 2: MATCH
├── Với mỗi node cần auth → tìm credential phù hợp từ BƯỚC 1
├── Match theo: credentialType + mục đích sử dụng
└── Ưu tiên: Service Account > OAuth > API Key

BƯỚC 3: ASSIGN
├── Gắn credential vào node JSON:
│   "credentials": {
│     "<credentialType>": {
│       "id": "<credentialId>",
│       "name": "<credentialName>"
│     }
│   }
└── ⚠️ PHẢI có cả "id" VÀ "name" — thiếu 1 trong 2 sẽ lỗi

BƯỚC 4: VERIFY / CREATE
├── Nếu không tìm thấy credential phù hợp:
│   ├── Hỏi user: "Bạn có credential cho [service] không?"
│   ├── Nếu có → hướng dẫn tạo qua n8n UI
│   └── Nếu cần tạo programmatically → create_credential()
└── KHÔNG BAO GIỜ hardcode API key vào node parameters
```

## Common Credential Mappings

### Google Workspace Nodes

| Node Type | Credential Type | Ghi chú |
|---|---|---|
| `n8n-nodes-base.googleSheets` | `googleSheetsOAuth2Api` hoặc `googleApi` | Service Account dùng `googleApi` |
| `n8n-nodes-base.googleDrive` | `googleDriveOAuth2Api` hoặc `googleApi` | |
| `n8n-nodes-base.gmail` | `gmailOAuth2` | |
| `n8n-nodes-base.googleDocs` | `googleDocsOAuth2Api` | |
| `n8n-nodes-base.googleCalendar` | `googleCalendarOAuth2Api` | |

### AI & API Nodes

| Node Type | Credential Type |
|---|---|
| `n8n-nodes-base.openAi` | `openAiApi` |
| `@n8n/n8n-nodes-langchain.lmOpenAi` | `openAiApi` |
| `n8n-nodes-base.httpRequest` | `httpHeaderAuth` / `httpBasicAuth` / `oAuth2Api` |

### Messaging & Social

| Node Type | Credential Type |
|---|---|
| `n8n-nodes-base.telegram` | `telegramApi` |
| `n8n-nodes-base.slack` | `slackApi` |
| `n8n-nodes-base.facebookGraphApi` | `facebookGraphApi` |

### Database

| Node Type | Credential Type |
|---|---|
| `n8n-nodes-base.postgres` | `postgres` |
| `n8n-nodes-base.mySql` | `mySql` |
| `n8n-nodes-base.mongoDb` | `mongoDb` |

## Node JSON với Credential (Template)

```json
{
  "type": "n8n-nodes-base.googleSheets",
  "typeVersion": 4.5,
  "name": "Read Sheet Data",
  "position": [500, 300],
  "parameters": {
    "operation": "read",
    "documentId": { "value": "SPREADSHEET_ID" },
    "sheetName": { "value": "Sheet1" }
  },
  "credentials": {
    "googleSheetsOAuth2Api": {
      "id": "abc123",
      "name": "Google_ServiceAccount"
    }
  }
}
```

## Service Account vs OAuth2

| | Service Account | OAuth2 |
|---|---|---|
| **Khi nào dùng** | Server-to-server, automation | User-interactive apps |
| **Ưu điểm** | Không cần refresh, ổn định | Truy cập user data |
| **Setup trên n8n** | Import JSON key file → credential | Browser consent flow |
| **Credential type** | `googleApi` | `googleSheetsOAuth2Api` |
| **Phải share Sheet** | ✅ Share với email service account | Không cần |

> **Luôn ưu tiên Service Account** cho automation workflows — ổn định hơn, không bị token hết hạn.

## Safety Rules

- **NEVER delete credentials** — active workflows will break
- **NEVER log credential values** in execution data
- **ALWAYS use n8n credential system** — never hardcode keys in parameters
- **ALWAYS include both `id` AND `name`** in credential reference
- **Prefer Service Accounts** over personal OAuth tokens for production
