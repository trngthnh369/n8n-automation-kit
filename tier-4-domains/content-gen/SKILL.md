---
name: content-gen
tier: 4
category: domain
version: 1.0.0
description: AI content generation pipelines — SEO articles, media production, multi-modal assets.
triggers:
  - "content generation"
  - "SEO article"
  - "AI content"
  - "media generation"
  - "TVC"
  - "video generation"
  - "blog post"
requires:
  - builder
  - n8n-mcp
recommends:
  - google-sheets
  - google-workspace
related:
  - "[[architect]]"
---

# ✍️ AI Content Generation

Production patterns for automated content creation: SEO articles, videos, images, product reviews.

## Architecture: Request-Queue-Worker

```
Request Layer (Input)
├── Google Sheets (keywords/product IDs)
├── Webhook (on-demand)
└── Schedule (batch)
    ↓
Queue Layer (Buffer)
├── Status locking (WIP flag)
├── Deduplication check
└── Priority ordering
    ↓
Worker Layer (Process)
├── AI Generation (OpenAI/Gemini)
├── Media Generation (Google Veo/Nano)
├── Post-processing (formatting, metadata)
└── Publication (Haravan/Blog/Drive)
```

## Key Patterns

### 1. Request-Queue-Worker Decoupling

Separate ingestion from processing to prevent overload:

```
Sheets input → Mark row "WIP" → Process → Mark row "DONE" → Next row
```

**Critical**: Status locking prevents duplicate runs in parallel environments.

### 2. Batch-Safe Assemblers

When processing batches, prevent **First-Item Poisoning** (all items get first item's data):

```javascript
// ✅ Correct: Map each item independently
return $input.all().map((item) => ({
  json: {
    product_id: item.json.product_id, // Each item's OWN data
    content: item.json.generated_text,
  },
}));

// ❌ Wrong: Using $input.first() in a loop
const first = $input.first().json; // All items get same data!
```

### 3. Context Passthrough Integrity

Metadata (product_id, request_id) MUST survive all transformations:

```
Input: { product_id: "A1", keyword: "shoes" }
  → AI Generation: { product_id: "A1", article: "..." }  ← ID preserved!
  → Publication: { product_id: "A1", url: "..." }         ← ID still there!
```

### 4. Multi-Modal Configuration Pattern

Single config controls multiple content types:

```json
{
  "content_type": "seo_article | tvc_prompt | product_review | social_post",
  "ai_model": "gpt-4o | gemini-3-pro",
  "output_format": "html | markdown | json",
  "target_platform": "haravan | wordpress | google_docs"
}
```

### 5. Prompt Engineering for Brand DNA

```
System: You are a content writer for [Brand].
Maintain these brand elements:
- Tone: [luxury/casual/professional]
- Keywords: [brand-specific terms]
- Style: [French elegance/Sporty/Corporate]

User: Write a [content_type] about [topic].
Include: [specific requirements from config]
```

## Content Type Recipes

### SEO Article Pipeline

```
Keyword research (Sheets) → Generate outline (AI) → Generate article (AI)
→ Format HTML → Upload to Haravan Blog API → Log URL to Sheets
```

### Media Generation Pipeline

```
Product data (Sheets) → Generate TVC prompt (AI) → Generate image (Nano)
→ Generate video (Veo) → Upload to Google Drive → Log asset URLs
```

### Product Review Pipeline

```
Product specs (API/Sheets) → Generate review text (AI) → Generate product images (Nano)
→ Compose final review (HTML) → Publish → Log
```

## Credentials Required

- `openAiApi` — GPT-4o for text generation
- `googleApi` — Gemini/Nano/Veo for media generation
- `haravan` — Blog API for publication (if Haravan)
- `googleSheetsOAuth2Api` — Input/output tracking
