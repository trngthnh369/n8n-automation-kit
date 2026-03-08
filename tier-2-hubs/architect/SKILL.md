---
name: n8n-architect
tier: 2
category: hub
version: 1.0.0
description: Analyzes requirements and designs SSOT architecture. Splits workflows into orchestrator + sub-workers.
triggers:
  - "design workflow"
  - "architecture"
  - "SSOT"
  - "split modules"
  - "plan workflow"
requires:
  - orchestrator
recommends:
  - template-library
related:
  - "[[builder]]"
  - "[[deployer]]"
---

# 📋 n8n Architect

Designs workflow architecture from requirements. Outputs a structured SSOT (Single Source of Truth) document that `[[builder]]` uses to construct the actual JSON.

## SSOT Document Format

Every workflow design starts with an SSOT:

```markdown
# SSOT: [Workflow Name]

## Purpose

[One sentence describing what this workflow does]

## Trigger

- Type: webhook | schedule | manual | executeWorkflowTrigger
- Config: [path/cron/etc]

## Nodes (ordered by execution)

1. [NodeName] — [n8n-nodes-base.type] — [purpose]
2. [NodeName] — [n8n-nodes-base.type] — [purpose]
   ...

## Connections

NodeA → NodeB → NodeC
NodeC → [IF] → NodeD (true) | NodeE (false)

## Error Strategy

- Global: continueErrorOutput on risky nodes
- Error funnel → Universal Error Normalizer

## Sub-Workflow Split

- IF any concern has >7 nodes → extract to sub-workflow
- Main orchestrator calls sub-workflows via executeWorkflow

## Credentials Required

- [ServiceName]: [credentialType] — [existing/needs-creation]

## Localization

- Timezone: Asia/Ho_Chi_Minh
- Date format: Luxon DateTime with setZone
```

## Architecture Decision Rules

### When to Split into Sub-Workflows

| Condition                                                       | Action                                              |
| --------------------------------------------------------------- | --------------------------------------------------- |
| Workflow has >15 nodes total                                    | MUST split into orchestrator + sub-workers          |
| A logic block handles a specific domain (e.g., "Scrape Shopee") | Extract to sub-workflow                             |
| Same logic reused across multiple workflows                     | Extract to shared sub-workflow                      |
| Need parallel processing per item                               | Use SplitInBatches → Execute Sub-Workflow per batch |

### Sub-Workflow Communication

```
Main Orchestrator:
  Execute Workflow node → calls sub-workflow by ID

Sub-Worker:
  Execute Workflow Trigger → receives data
  ... processing nodes ...
  Last node output → returned to main orchestrator
```

## Pattern Selection Guide

Use `[[template-library]]` to find reference patterns, then apply:

| Use Case              | Pattern              | Structure                                                     |
| --------------------- | -------------------- | ------------------------------------------------------------- |
| API webhook handler   | Webhook Processing   | `Webhook → Validate → Transform → Action → Response`          |
| Third-party API calls | HTTP API Integration | `Trigger → HTTP Request → Transform → Action → Error Handler` |
| Periodic batch jobs   | Scheduled Processing | `Schedule → Fetch → SplitInBatches → Process → Loop`          |
| AI-powered processing | AI Agent             | `Trigger → AI Agent (Model + Tools + Memory) → Output`        |
| Database operations   | DB Pattern           | `Trigger → Query → Transform → Write → Verify`                |

## Five Pillars of Construction (Builder v5)

The SSOT should account for these pillars (enforced by `[[builder]]`):

1. **Modular Strategy**: >7 nodes per concern → sub-workflow
2. **Split-Path Resilience**: Every risky node → `onError: "continueErrorOutput"` → error funnel
3. **Localization**: `timezone: "Asia/Ho_Chi_Minh"` + Luxon in Code nodes
4. **Semantic Naming**: `[System]_[Module]_[Action]` pattern
5. **Side-Car Error Logging**: Errors → separate diagnostic sink
