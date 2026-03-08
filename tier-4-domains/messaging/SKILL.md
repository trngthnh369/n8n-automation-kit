---
name: messaging
tier: 4
category: domain
version: 1.0.0
description: Multi-channel messaging — Zalo OA, Telegram, Slack, Email, SMS with chatbot and broadcast patterns.
triggers:
  - "Zalo"
  - "Telegram"
  - "Slack"
  - "email"
  - "SMS"
  - "notification"
  - "chatbot"
  - "broadcast"
  - "thông báo"
requires:
  - builder
  - n8n-mcp
related:
  - "[[crm-sales]]"
  - "[[credential-manager]]"
---

# 💬 Messaging & Notifications

Multi-channel messaging patterns for alerts, chatbots, and broadcast campaigns.

## Architecture: Unified Messaging Hub

```
Trigger Sources:
├── Workflow events (order, error, KPI change)
├── Schedule (daily reports, reminders)
├── Webhook (external system alerts)
├── User request (broadcast command)
    ↓
Message Router:
├── Determine channel(s): Zalo, Telegram, Slack, Email, SMS
├── Determine recipients: individual, group, broadcast list
├── Format message per channel
    ↓
Channel Adapters:
├── Zalo OA API → send/receive
├── Telegram Bot API → send/receive
├── Slack API → post to channel/DM
├── SMTP/SendGrid → email
└── SMS Gateway → text message
```

## Key Patterns

### 1. Multi-Channel Dispatch

Send same message to multiple channels:

```javascript
const channels = notification.channels; // ["zalo", "telegram", "slack"]
const results = [];
for (const ch of channels) {
  results.push({
    json: {
      channel: ch,
      recipient: notification.recipients[ch],
      message: formatForChannel(ch, notification.content),
    },
  });
}
return results;
// → SplitInBatches → Switch node (by channel) → respective API nodes
```

### 2. Zalo OA Integration

```
Send message:
  POST https://openapi.zalo.me/v3.0/oa/message/cs
  Headers: access_token: {token}
  Body: { recipient: { user_id }, message: { text } }

Receive webhook:
  POST /webhook/zalo → parse event_name:
    "user_send_text" → chatbot logic
    "follow" → welcome message
    "unfollow" → update CRM
```

**Zalo Gotchas:**

- Messages must be within **48h window** of last user interaction (OA policy)
- Broadcast requires **ZNS templates** (pre-approved by Zalo)
- Token refresh needed every **90 days**

### 3. Telegram Bot Patterns

```
Send message:
  POST https://api.telegram.org/bot{token}/sendMessage
  Body: { chat_id, text, parse_mode: "HTML" }

Rich messages:
  sendPhoto, sendDocument, sendMediaGroup

Inline keyboards:
  reply_markup: { inline_keyboard: [[{text, callback_data}]] }
```

### 4. Slack Notification Patterns

```
Simple: POST to webhook_url with { text, channel }

Rich (Block Kit):
  blocks: [
    { type: "header", text: { type: "plain_text", text: "🚨 Alert" } },
    { type: "section", text: { type: "mrkdwn", text: "Details..." } },
    { type: "actions", elements: [{ type: "button", text: "View", url }] }
  ]
```

### 5. Email Templates

```
HTML email with dynamic data:
  Subject: "[System] {event_type} — {summary}"
  Body: HTML template with {variables} replaced

Batch email (SendGrid):
  POST /v3/mail/send with personalizations[] for bulk
```

### 6. AI Chatbot Pattern

```
Webhook (receive message)
→ Check conversation context (memory/DB)
→ AI Agent node (OpenAI with tools)
  → Tools: search_products, check_order_status, FAQ lookup
→ Format response for channel
→ Send reply
→ Store conversation history
```

### 7. Broadcast Campaign

```
Read recipient list from Sheets
→ SplitInBatches (batch=10)
→ Rate-limited send (Wait 1s between batches)
→ Log delivery status
→ Summary report after all sent
```

## Message Formatting Per Channel

| Element    | Zalo              | Telegram        | Slack         | Email      |
| ---------- | ----------------- | --------------- | ------------- | ---------- |
| Bold       | N/A               | `*bold*`        | `*bold*`      | `<b>`      |
| Link       | `<a>` in template | `[text](url)`   | `<url\|text>` | `<a href>` |
| Line break | `\n`              | `\n`            | `\n`          | `<br>`     |
| Image      | attachment        | sendPhoto       | image block   | `<img>`    |
| Button     | ZNS template      | inline_keyboard | actions block | link       |

## Credentials Required

- `zaloApi` — Zalo OA access token (httpHeaderAuth)
- `telegramApi` — Bot token
- `slackApi` — Bot or webhook token
- `sendGridApi` or SMTP credentials — for email
- SMS gateway API key (if needed)
