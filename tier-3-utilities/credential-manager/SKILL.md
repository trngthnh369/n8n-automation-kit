---
name: credential-manager
tier: 3
category: utility
version: 1.0.0
description: Credential lifecycle management. Discovers, creates, and maps credentials to n8n nodes.
triggers:
  - "credential"
  - "authentication"
  - "API key"
  - "OAuth"
requires:
  - n8n-mcp
related:
  - "[[builder]]"
---

# 🔑 Credential Manager

Manages the credential lifecycle for n8n workflows: discover existing, create new, and map to nodes.

## Credential Discovery

Before creating new credentials, always check what exists:

```
1. get_credential_schema(credentialTypeName) → see available types
2. Match node type to credential type
```

## Common Credential Mappings

| Node Type                           | Credential Type                                  | Schema Key              |
| ----------------------------------- | ------------------------------------------------ | ----------------------- |
| `n8n-nodes-base.httpRequest`        | `httpHeaderAuth` / `httpBasicAuth` / `oAuth2Api` | varies                  |
| `n8n-nodes-base.googleSheets`       | `googleSheetsOAuth2Api` / `googleApi`            | `googleSheetsOAuth2Api` |
| `n8n-nodes-base.slack`              | `slackApi` / `slackOAuth2Api`                    | `slackApi`              |
| `n8n-nodes-base.telegram`           | `telegramApi`                                    | `telegramApi`           |
| `n8n-nodes-base.openAi`             | `openAiApi`                                      | `openAiApi`             |
| `n8n-nodes-base.facebookGraphApi`   | `facebookGraphApi`                               | `facebookGraphApi`      |
| `n8n-nodes-base.postgres`           | `postgres`                                       | `postgres`              |
| `n8n-nodes-base.mysql`              | `mysqlApi`                                       | `mysqlApi`              |
| `n8n-nodes-base.mySql`              | `mySql`                                          | `mySql`                 |
| `@n8n/n8n-nodes-langchain.lmOpenAi` | `openAiApi`                                      | `openAiApi`             |

## Creating Credentials

```
create_credential({
  name: "My Google Sheets",
  type: "googleSheetsOAuth2Api",
  data: {
    clientId: "...",
    clientSecret: "...",
    oauthTokenData: { ... }
  }
})
```

**⚠️ NEVER ask user for credentials in plaintext** — guide them to create via n8n UI if OAuth is needed.

## Referencing Credentials in Nodes

When building nodes, reference credentials by name:

```json
{
  "type": "n8n-nodes-base.googleSheets",
  "parameters": { ... },
  "credentials": {
    "googleSheetsOAuth2Api": {
      "id": "credentialId",
      "name": "My Google Sheets"
    }
  }
}
```

## Credential Naming Convention

`[Service]_[Account/Purpose]` — Examples:

- `Google_ServiceAccount`
- `Slack_MainWorkspace`
- `OpenAI_GPT4`
- `Facebook_AdsManager`

## Safety Rules

- **NEVER delete credentials** without user confirmation — active workflows will break
- **NEVER log credential values** in execution data or error reports
- **ALWAYS use the n8n credential system** — never hardcode API keys in node parameters
- **Prefer service accounts** over personal OAuth tokens for production workflows
