---
name: kpi-automation
tier: 4
category: domain
version: 1.0.0
description: KPI scoring and management automation — Base Goal API, merge barrier, SSOT strategy.
triggers:
  - "KPI"
  - "goal scoring"
  - "performance review"
  - "employee evaluation"
  - "OKR"
requires:
  - builder
  - n8n-mcp
recommends:
  - google-sheets
related:
  - "[[architect]]"
---

# 📈 KPI Automation

Production patterns for automating KPI lifecycle: Propose → Score → Publish via Base Goal API.

## Architecture: Multi-Workflow Orchestration

```
KPI Lifecycle:
├── KPI Proposer (quarterly)
│   ├── Fetch history from SSOT Sheet
│   ├── AI generates KPI suggestions per employee
│   ├── Human review (Google Sheets)
│   └── Approved KPIs → Publisher
├── KPI Scorer (monthly/weekly)
│   ├── Fetch active goals from Base Goal API
│   ├── Calculate synthetic scores
│   ├── AI evaluation per goal
│   └── Write scores to Sheets
└── KPI Publisher (after approval)
    ├── Read approved KPIs from Sheets
    ├── Create goals via Base Goal API
    └── Log results
```

## Key Patterns

### 1. Global SSOT Strategy

Use the **KPI Summary Sheet** (historical aggregation) as the canonical user list:

```
❌ Don't: Use live API for user list (misses ~34% of participants)
✅ Do: Use Summary Sheet (47 rows, complete history) → cross-reference with live API
```

### 2. Merge Barrier Synchronization

When a workflow has multiple data sources that must converge before processing:

```
Branch A: Fetch from API ─────┐
                              ├─→ Merge node → Process combined data
Branch B: Fetch from Sheets ──┘
```

**Critical**: Both branches MUST complete before merge. Use `Wait` node or ensure both branches have guaranteed output.

### 3. Synthetic Scoring (Progress Proxy)

Base Goal API returns `score: 0` for archived goals. Derive scores from:

```javascript
// OKR: Weighted average of child Key Results
const okrScore =
  keyResults.reduce((sum, kr) => sum + kr.progress * kr.weight, 0) /
  totalWeight;

// KPI: Ratio of latest checkin to target
const kpiScore = (latestCheckin / targetValue) * 100;
```

### 4. SplitInBatches Loop (Batch=1)

For sub-workflows that process ONE item at a time:

```
Main: SplitInBatches(batchSize=1) → Execute Sub-Workflow → Loop
Sub:  Receive single item → Process → Return result
```

### 5. Privacy Resolution

API may hide goal names. Resolve from children:

```javascript
const goalName =
  goal.name !== "Private"
    ? goal.name
    : goal.key_results?.[0]?.name || goal.checkins?.[0]?.note || "Unknown";
```

### 6. ±20% Growth Cap

When AI proposes new KPI targets:

```
new_target = clamp(
  ai_suggested_target,
  previous_target * 0.8,   // min: -20%
  previous_target * 1.2    // max: +20%
)
```

## Base Goal API Reference

### Fetch Cycles

```
GET /api/v2/cycle/list
Headers: Authorization: Bearer {token}
```

### Fetch Full Cycle Data

```
GET /api/v2/cycle/get.full?cycle_id={id}
Returns: teams → users → goals → key_results/checkins
```

### Create Goal

```
POST /api/v2/goal/create
Body: { cycle_id, team_id, user_id, name, target, weight }
```

### Pagination for KRs

```
GET /api/v2/cycle/krs?cycle_id={id}&page={page}&limit=100
```

## Credentials Required

- Base Goal API token (httpHeaderAuth)
- `googleSheetsOAuth2Api` — SSOT sheets
- `openAiApi` — AI evaluation and proposal generation
