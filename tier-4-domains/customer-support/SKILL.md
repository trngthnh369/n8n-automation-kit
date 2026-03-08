---
name: customer-support
tier: 4
category: domain
version: 1.0.0
description: Customer support automation — ticket routing, AI draft responses, SLA tracking, escalation.
triggers:
  - "support"
  - "ticket"
  - "helpdesk"
  - "customer service"
  - "hỗ trợ"
  - "khiếu nại"
  - "complaint"
requires:
  - builder
  - n8n-mcp
recommends:
  - messaging
  - crm-sales
related:
  - "[[messaging]]"
  - "[[crm-sales]]"
---

# 🎧 Customer Support Automation

Ticket management, AI-assisted responses, SLA tracking, and escalation workflows.

## Architecture: Support Pipeline

```
Ticket Sources:
├── Email (IMAP/webhook)
├── Zalo OA messages
├── Facebook Messenger
├── Website chat widget (webhook)
├── Phone (manual entry)
└── Internal report
    ↓
Intake & Routing:
├── Create ticket record
├── Auto-categorize (AI or rules)
├── Priority assignment
├── Route to correct team/agent
├── Set SLA timer
    ↓
Resolution:
├── AI draft response → human review → send
├── Knowledge base search
├── Escalation (if complex or SLA at risk)
    ↓
Post-Resolution:
├── Customer satisfaction survey
├── Knowledge base update (if new issue type)
├── Analytics & reporting
```

## Key Patterns

### 1. Multi-Channel Intake Normalization

```javascript
function normalizeTicket(source, raw) {
  return {
    ticket_id: `TK-${Date.now()}`,
    source: source,
    customer_name: raw.name || raw.from || "Unknown",
    customer_contact: raw.email || raw.phone || raw.user_id,
    subject: raw.subject || raw.message?.substring(0, 100) || "No subject",
    message: raw.body || raw.message || raw.text,
    attachments: raw.attachments || [],
    received_at: new Date().toISOString(),
    status: "NEW",
    priority: "NORMAL",
    assigned_to: null,
    sla_deadline: null,
  };
}
```

### 2. AI Auto-Categorization

```
Prompt:
"Categorize this customer support ticket into one of these categories:
- ORDER: order status, tracking, delivery issues
- PRODUCT: product quality, defect, exchange, return
- BILLING: payment, refund, invoice
- TECHNICAL: website error, app bug, account access
- GENERAL: information request, feedback, other

Ticket: {message}

Respond with ONLY the category name and a confidence score (0-100)."
```

### 3. Priority Assignment Rules

```javascript
function assignPriority(ticket) {
  // URGENT: VIP customer, order > 5M VND, repeat complaint
  if (ticket.customer_tier === "VIP") return "URGENT";
  if (ticket.order_value > 5000000) return "URGENT";
  if (ticket.repeat_count > 2) return "URGENT";

  // HIGH: refund/return, negative sentiment
  if (["BILLING", "PRODUCT"].includes(ticket.category)) return "HIGH";
  if (ticket.sentiment === "NEGATIVE") return "HIGH";

  // NORMAL: everything else
  return "NORMAL";
}
```

### 4. SLA Timer & Escalation

```
SLA by Priority:
  URGENT: First response 1h, Resolution 4h
  HIGH:   First response 2h, Resolution 8h
  NORMAL: First response 4h, Resolution 24h

Schedule Trigger (every 15min):
→ Fetch open tickets
→ For each ticket:
  → Calculate time_elapsed = now - received_at
  → IF time_elapsed > first_response_sla AND status === 'NEW':
    → Escalate: notify team lead
    → Flag: "SLA BREACH - First Response"
  → IF time_elapsed > resolution_sla AND status !== 'RESOLVED':
    → Escalate: notify manager
    → Flag: "SLA BREACH - Resolution"
```

### 5. AI Draft Response

```
Prompt:
"You are a customer support agent for [Brand].
Tone: Professional, empathetic, solution-oriented.
Language: Vietnamese.

Customer ticket:
Category: {category}
Message: {message}
Order info: {order_details}

Draft a helpful response. Include:
1. Acknowledge the issue
2. Provide solution or next steps
3. Set expectations for timeline
4. Close with care

If you need more information, ask specific questions."

→ AI generates draft
→ Support agent reviews + edits
→ Send via original channel
→ Update ticket status to "RESPONDED"
```

### 6. Knowledge Base Integration

```
When resolving a ticket:
→ Search existing KB articles (by category + keywords)
→ IF matching article found → include in response
→ IF new issue type resolved:
  → AI generates KB article from ticket + resolution
  → Save to KB (Notion/Docs/internal wiki)
  → Flag for editorial review
```

### 7. CSAT (Customer Satisfaction) Survey

```
After ticket resolved (wait 24h):
→ Send survey via same channel:
  "Bạn đánh giá trải nghiệm hỗ trợ: ⭐⭐⭐⭐⭐"
  (1-5 stars or thumbs up/down)
→ Record response
→ IF score <= 2 → flag for manager review
→ Monthly: aggregate CSAT report
```

## Metrics & Reporting

| Metric                   | Calculation                              | Target         |
| ------------------------ | ---------------------------------------- | -------------- |
| First Response Time      | avg(first_response_at - received_at)     | < 2h           |
| Resolution Time          | avg(resolved_at - received_at)           | < 12h          |
| SLA Compliance           | tickets_within_sla / total_tickets × 100 | > 95%          |
| CSAT Score               | avg(satisfaction_rating)                 | > 4.0/5        |
| First Contact Resolution | resolved_first_response / total × 100    | > 60%          |
| Ticket Volume            | count per day/week                       | trend tracking |

## Credentials Required

- Email: IMAP + SMTP credentials
- [[messaging]] credentials (Zalo, Telegram, etc.)
- `openAiApi` — AI categorization + draft responses
- `googleSheetsOAuth2Api` — ticket tracking
- Knowledge base API (Notion/Confluence if applicable)
