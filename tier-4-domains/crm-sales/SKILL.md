---
name: crm-sales
tier: 4
category: domain
version: 1.0.0
description: CRM & Sales automation — lead capture, nurture sequences, pipeline management, multi-channel sync.
triggers:
  - "CRM"
  - "sales"
  - "lead"
  - "customer"
  - "pipeline"
  - "HubSpot"
  - "deal"
  - "contact"
requires:
  - builder
  - n8n-mcp
recommends:
  - messaging
  - google-sheets
related:
  - "[[architect]]"
  - "[[messaging]]"
  - "[[credential-manager]]"
---

# 💼 CRM & Sales Automation

Production patterns for automated lead management, sales pipeline, and customer lifecycle.

## Architecture: Lead Lifecycle Pipeline

```
Lead Sources:
├── Facebook Lead Ads (webhook)
├── Zalo OA messages (webhook)
├── Website form (webhook)
├── Manual import (Google Sheets)
    ↓
Lead Processing:
├── Deduplicate (phone/email match)
├── Enrich (lookup existing customer data)
├── Score (rules-based or AI)
├── Assign to sales rep (round-robin or territory)
    ↓
Nurture:
├── Auto-send welcome message (Zalo/Email)
├── Schedule follow-up sequence
├── Track engagement (open/reply)
    ↓
Pipeline:
├── Move stages: New → Contacted → Qualified → Proposal → Won/Lost
├── Alert on stage change
├── Auto-create tasks for sales rep
    ↓
Close & Post-Sale:
├── Create order in ERP
├── Send confirmation
├── Schedule onboarding
└── Add to retention loop
```

## Key Patterns

### 1. Multi-Channel Lead Capture

```
Facebook Lead Ads webhook → extract fields (name, phone, email)
Zalo OA webhook → extract from message text
Website form → parse POST body
    ↓ ALL converge to:
Normalize Code node → { name, phone, email, source, raw_data }
```

### 2. Deduplication Strategy

```javascript
// Match by phone number (normalize VN format)
function normalizePhone(phone) {
  let p = phone.replace(/[^0-9]/g, "");
  if (p.startsWith("84")) p = "0" + p.slice(2);
  if (p.startsWith("+84")) p = "0" + p.slice(3);
  return p;
}
// Search existing contacts in CRM/Sheet
// IF found → update existing
// IF not found → create new
```

### 3. Lead Scoring Rules

```javascript
let score = 0;
if (lead.source === "facebook_lead_ad") score += 30;
if (lead.phone) score += 20;
if (lead.email) score += 10;
if (lead.message && lead.message.length > 50) score += 15;
if (lead.product_interest) score += 25;
// Hot: 70+, Warm: 40-69, Cold: <40
```

### 4. Round-Robin Assignment

```javascript
const salesReps = ["Rep A", "Rep B", "Rep C"];
const lastAssigned = parseInt($("Get Counter").first().json.value || "0");
const nextRep = salesReps[(lastAssigned + 1) % salesReps.length];
// Update counter in Sheets/DB
```

### 5. Follow-Up Sequence

```
Day 0: Welcome message (immediate)
Day 1: Product info (scheduled)
Day 3: Check-in "Anh/chị cần tư vấn thêm không?"
Day 7: Special offer (if no response)
Day 14: Final follow-up
```

Implement via: Schedule Trigger → check lead.created_at → send appropriate message

### 6. Pipeline Stage Automation

```
Stage change webhook/poll →
  IF "New" → auto-assign + welcome msg
  IF "Qualified" → create proposal template
  IF "Proposal Sent" → schedule follow-up after 3 days
  IF "Won" → create order + notify fulfillment
  IF "Lost" → add to re-engagement list after 30 days
```

## CRM Integration Patterns

### HubSpot

```
Contacts: POST /crm/v3/objects/contacts
Deals: POST /crm/v3/objects/deals
Notes: POST /crm/v3/objects/notes
Pipeline: GET /crm/v3/pipelines/deals
```

### Custom CRM (Google Sheets)

```
Contacts Sheet: Name, Phone, Email, Source, Score, Assigned, Stage, Last Contact
Pipeline Sheet: Deal ID, Contact, Value, Stage, Created, Updated, Notes
Activities Sheet: Date, Contact, Type (Call/Message/Email), Notes, Rep
```

## Credentials Required

- `hubSpotApi` or custom CRM API key
- `googleSheetsOAuth2Api` — for Sheets-based CRM
- Messaging credentials (see [[messaging]] skill)
