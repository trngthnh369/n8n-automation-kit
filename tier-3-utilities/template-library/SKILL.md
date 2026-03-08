---
name: template-library
tier: 3
category: utility
version: 1.0.0
description: Community template search, evaluation, and adaptation. Maintains local pattern library.
triggers:
  - "template"
  - "example workflow"
  - "reference"
  - "find template"
requires:
  - n8n-mcp
related:
  - "[[architect]]"
  - "[[builder]]"
---

# 📚 Template Library

Search, evaluate, and adapt community templates for faster workflow construction.

## Template Discovery

### Search by Keywords

```
search_templates("slack notification", rows: 10)
→ Returns: list of templates with id, name, description
```

### Search by Use Case

```
search_templates("webhook to google sheets")
search_templates("scheduled email report")
search_templates("AI chatbot telegram")
```

## Template Evaluation Checklist

Before using a template, evaluate:

| Check              | Criteria                                                            |
| ------------------ | ------------------------------------------------------------------- |
| **Node versions**  | Are typeVersions current? Old templates may use deprecated versions |
| **Credentials**    | What credential types are needed? Do we have them?                  |
| **Complexity**     | How many nodes? Can we simplify?                                    |
| **Error handling** | Does it have error handlers? (Most templates don't — add them)      |
| **Timezone**       | Does it handle timezone? (Usually not — add Asia/Ho_Chi_Minh)       |

## Template Adaptation Workflow

```
1. search_templates("keyword") → find candidate
2. get_template(templateId) → get nodes, connections
3. EVALUATE against checklist above
4. ADAPT:
   a. Update typeVersions to latest
   b. Add error handling (continueErrorOutput + error funnel)
   c. Add timezone settings
   d. Replace credentials with local ones
   e. Rename nodes to semantic naming convention
   f. Adjust positions for visual topology
5. Pass adapted JSON to [[builder]] for final construction
```

## Built-in Pattern Recipes

Quick-start patterns for common use cases (no template search needed):

### Recipe: Webhook → Process → Respond

```json
{
  "trigger": "webhook",
  "flow": [
    "Webhook",
    "Code (validate)",
    "Code (transform)",
    "Respond to Webhook"
  ],
  "use_when": "External service sends data to n8n"
}
```

### Recipe: Schedule → Fetch → Process → Report

```json
{
  "trigger": "schedule",
  "flow": [
    "Schedule Trigger",
    "HTTP Request (fetch)",
    "Code (process)",
    "Google Sheets (write)"
  ],
  "use_when": "Periodic data collection and reporting"
}
```

### Recipe: Webhook → AI Agent → Respond

```json
{
  "trigger": "webhook",
  "flow": ["Webhook", "AI Agent (OpenAI + tools)", "Respond to Webhook"],
  "use_when": "AI-powered API endpoint"
}
```

### Recipe: Main Orchestrator → Sub-Workers

```json
{
  "trigger": "schedule|webhook",
  "flow": [
    "Trigger",
    "Code (prepare)",
    "SplitInBatches",
    "Execute Workflow (sub)",
    "Merge",
    "Report"
  ],
  "use_when": "Processing >50 items or complex multi-domain logic"
}
```
