---
name: google-workspace
tier: 3
category: utility
version: 2.0.0
description: Google Sheets node patterns — Service Account setup, tạo tab, tạo headers, read/write/append. Gmail, Drive, Calendar.
triggers:
  - "google docs"
  - "google sheets"
  - "read spreadsheet"
  - "google calendar"
  - "gws"
  - "read PRD"
  - "service account"
requires: []
related:
  - "[[credential-manager]]"
  - "[[orchestrator]]"
---

# 📊 Google Workspace for n8n

Patterns cho Google Sheets, Gmail, Drive, Calendar **trong n8n workflows**.

## ⭐ Google Sheets + Service Account (Quan trọng nhất)

### Setup Service Account trên n8n

1. Google Cloud Console → tạo Service Account → download JSON key
2. n8n → Credentials → Add → Google API (Service Account)
3. Upload JSON key file
4. **Share spreadsheet** với email service account (editor)
5. Credential type in n8n: `googleApi`

### Tạo Tab mới (Add Sheet)

```json
{
  "type": "n8n-nodes-base.googleSheets",
  "typeVersion": 4.5,
  "name": "Create Log Tab",
  "position": [500, 300],
  "parameters": {
    "operation": "create",
    "documentId": {
      "mode": "id",
      "value": "={{ $json.spreadsheetId }}"
    },
    "sheetName": "={{ $json.tabName || 'Logs' }}"
  },
  "credentials": {
    "googleSheetsOAuth2Api": {
      "id": "<CREDENTIAL_ID>",
      "name": "<CREDENTIAL_NAME>"
    }
  }
}
```

### Tạo Headers (Write Row 1)

```json
{
  "type": "n8n-nodes-base.googleSheets",
  "typeVersion": 4.5,
  "name": "Write Headers",
  "position": [850, 300],
  "parameters": {
    "operation": "update",
    "documentId": {
      "mode": "id",
      "value": "={{ $json.spreadsheetId }}"
    },
    "sheetName": {
      "mode": "name",
      "value": "Logs"
    },
    "columns": {
      "mappingMode": "defineBelow",
      "value": {
        "timestamp": "Timestamp",
        "action": "Action",
        "status": "Status",
        "details": "Details",
        "error": "Error"
      }
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

### Append Data (Thêm dòng)

```json
{
  "type": "n8n-nodes-base.googleSheets",
  "typeVersion": 4.5,
  "name": "Log to Sheet",
  "position": [1200, 300],
  "parameters": {
    "operation": "append",
    "documentId": {
      "mode": "id",
      "value": "SPREADSHEET_ID"
    },
    "sheetName": {
      "mode": "name",
      "value": "Logs"
    },
    "columns": {
      "mappingMode": "autoMapInputData",
      "matchingColumns": []
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

### Read Data

```json
{
  "type": "n8n-nodes-base.googleSheets",
  "typeVersion": 4.5,
  "name": "Read Config",
  "position": [500, 300],
  "parameters": {
    "operation": "read",
    "documentId": {
      "mode": "id",
      "value": "SPREADSHEET_ID"
    },
    "sheetName": {
      "mode": "name",
      "value": "Config"
    },
    "options": {}
  },
  "credentials": {
    "googleSheetsOAuth2Api": {
      "id": "<CREDENTIAL_ID>",
      "name": "<CREDENTIAL_NAME>"
    }
  }
}
```

## Gmail Node

```json
{
  "type": "n8n-nodes-base.gmail",
  "typeVersion": 2.1,
  "name": "Send Report Email",
  "parameters": {
    "sendTo": "={{ $json.email }}",
    "subject": "Daily Report {{ $now.format('dd/MM/yyyy') }}",
    "emailType": "html",
    "message": "={{ $json.htmlReport }}",
    "options": {}
  },
  "credentials": {
    "gmailOAuth2": {
      "id": "<CREDENTIAL_ID>",
      "name": "<CREDENTIAL_NAME>"
    }
  }
}
```

## Google Drive Node

```json
{
  "type": "n8n-nodes-base.googleDrive",
  "typeVersion": 3,
  "name": "Upload Report",
  "parameters": {
    "operation": "upload",
    "name": "={{ $json.filename }}",
    "folderId": "FOLDER_ID",
    "inputDataFieldName": "data"
  },
  "credentials": {
    "googleDriveOAuth2Api": {
      "id": "<CREDENTIAL_ID>",
      "name": "<CREDENTIAL_NAME>"
    }
  }
}
```

## ⚠️ Common Mistakes

| Mistake | Fix |
|---|---|
| Quên share Sheet với service account email | Phải add email SA làm Editor |
| Dùng `sheetName: "gid=0"` | Dùng `sheetName: "Sheet1"` (tên tab, không phải GID) |
| Thiếu credential trong node JSON | PHẢI có block `"credentials": { ... }` |
| Dùng `mode: "list"` trong documentId | Dùng `mode: "id"` khi biết trước ID |
| Quên `cellFormat: "USER_ENTERED"` | Dates/numbers sẽ không parse đúng |

## GWS CLI (Alternative — cho agent trực tiếp, không qua n8n)

```bash
gws auth login --service-account /path/to/key.json
gws sheets spreadsheets.values get --spreadsheet-id <id> --range "Sheet1!A1:Z100" --format json
gws sheets spreadsheets.values append --spreadsheet-id <id> --range "Sheet1!A1" --values '[["new","row"]]'
```
