---
name: facebook-ads
tier: 4
category: domain
version: 1.0.0
description: Facebook Ads automation patterns — cascade pause, adaptive branching, API resilience, polling optimization.
triggers:
  - "facebook ads"
  - "fb ads"
  - "campaign"
  - "ad set"
  - "META API"
  - "quảng cáo"
requires:
  - builder
  - n8n-mcp
recommends:
  - google-sheets
related:
  - "[[architect]]"
  - "[[credential-manager]]"
---

# 📱 Facebook Ads Automation

Production-tested patterns for automating Facebook/Meta Ads via n8n.

## Architecture: Multi-BM Sub-Workflow

```
Main Orchestrator (Schedule/Webhook trigger)
├── Sub: Ad Creator (per page/BM)
│   ├── Fetch latest posts (Graph API)
│   ├── Deduplicate via System-of-Record query
│   ├── Create Campaign → Ad Set → Ad
│   └── Log to Google Sheets
├── Sub: Ad Optimizer (daily schedule)
│   ├── Fetch active campaigns
│   ├── Calculate CPR (Cost Per Result)
│   ├── Apply budget rules (increase/maintain/pause)
│   └── Execute cascade pause if needed
└── Sub: Monthly Shutdown (end of month)
    ├── Identify expired campaigns
    └── Cascade pause all
```

## Key Patterns

### 1. Multi-Level Cascade Pause

When pausing a campaign, MUST also pause all children:

```
Pause Campaign → List Ad Sets → Pause each Ad Set → List Ads → Pause each Ad
```

**Why**: Facebook does NOT auto-pause children. Leaving ad sets active wastes budget.

### 2. Adaptive Strategic Branching

Route ad creation based on post content:

```
Post has product URL? → Conversion campaign (WEBSITE_CONVERSIONS)
Post is video? → Video views campaign (VIDEO_VIEWS)
Post is image? → Engagement campaign (POST_ENGAGEMENT)
Post is livestream? → SKIP (safety filter)
Post has empty message? → SKIP
```

### 3. API Resilience — Structural Pattern

Facebook API calls in n8n Code nodes cannot use `fetch()` (sandbox restriction). Use the **Structural API Pattern**:

```
HTTP Request node (not Code node) → handles actual API call
Code node before → builds URL/body
Code node after → parses response
```

### 4. TimeZone Offset Mitigation

Facebook API uses UTC. Vietnam is UTC+7. Date comparisons MUST offset:

```javascript
const { DateTime } = require("luxon");
const todayVN = DateTime.now().setZone("Asia/Ho_Chi_Minh").startOf("day");
const fbTimestamp = DateTime.fromISO(item.created_time).setZone(
  "Asia/Ho_Chi_Minh",
);
```

### 5. Per-Page Budget Cap

Limit daily spend per fanpage (e.g., 2M VND):

```
Total active campaigns for page × budget per campaign < 2,000,000
IF exceeds → skip creating new campaign
```

### 6. Multi-Page Polling (vs Webhook)

For high-volume multi-page setups, **polling** is more reliable than webhooks:

```
Schedule Trigger (every 30min) → For each page → Fetch posts since last run → Process
```

## Meta Marketing API Reference (v24.0)

### Campaign Creation

```
POST /{ad_account_id}/campaigns
Body: { name, objective, status, special_ad_categories }
```

### Ad Set Creation

```
POST /{campaign_id}/adsets
Body: { name, daily_budget, targeting, billing_event, optimization_goal }
```

### Ad Creative

```
POST /{ad_account_id}/adcreatives
Body: { name, object_story_id OR object_story_spec }
```

### Deduplication Query

```
GET /{ad_account_id}/ads?filtering=[{"field":"effective_object_story_id","operator":"CONTAIN","value":"POST_ID"}]
```

## Credential Required

- `facebookGraphApi` — Long-lived page access token with `ads_management` permission
