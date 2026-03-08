---
name: inventory-automation
tier: 4
category: domain
version: 1.0.0
description: Ecommerce inventory automation — multi-platform scanning, batch processing, scatter-gather consolidation.
triggers:
  - "inventory"
  - "ecommerce"
  - "shopee"
  - "lazada"
  - "tiktok shop"
  - "haravan"
  - "product scan"
  - "stock"
requires:
  - builder
  - n8n-mcp
recommends:
  - google-sheets
related:
  - "[[architect]]"
  - "[[credential-manager]]"
---

# 📦 Ecommerce Inventory Automation

Production patterns for multi-platform product scanning, stock monitoring, and automated replenishment.

## Architecture: Parallel Monolithic + Primary Controller

```
Schedule Trigger
├── Read product list from Google Sheets (SSOT)
├── Parallel API branches:
│   ├── Haravan Admin API → stock + visibility
│   ├── Shopee Partner API v2 → stock + price
│   ├── Lazada Open Platform → stock + price
│   └── TikTok Seller API → stock + price
├── Primary Controller (Code node) → consolidate via $() references
├── AI Semantic Auditor (optional) → verify attributes
└── Write results back to Google Sheets
```

## Key Patterns

### 1. Batch-Accumulate & Flush (v8.2)

For large catalogs (500+ products), process in batches to avoid memory issues:

```
SplitInBatches (batch=50) → Process batch → Accumulate results in Code node → Loop
After all batches → Flush accumulated results to Sheets
```

### 2. Scatter-Gather Consolidation

Instead of complex Merge node chains, use Code-based consolidation:

```javascript
// Primary Controller node — consolidate parallel branch results
const haravan = $("Haravan_Lookup").all();
const shopee = $("Shopee_Lookup").all();
const lazada = $("Lazada_Lookup").all();
const tiktok = $("TikTok_Lookup").all();

return products.map((p) => ({
  json: {
    sku: p.json.sku,
    haravan_stock:
      haravan.find((h) => h.json.sku === p.json.sku)?.json.stock ?? "N/A",
    shopee_stock:
      shopee.find((s) => s.json.sku === p.json.sku)?.json.stock ?? "N/A",
    // ... consolidate all platforms
  },
}));
```

### 3. Primary Controller Pattern (v7.2)

Eliminates race conditions from parallel branches:

- ONE controlling branch runs the consolidation Code node
- Other branches just execute and output data
- Controller uses `$('NodeName')` references to read their output
- Disabled platforms don't hang the workflow

### 4. API-First Discovery Strategy

Always prefer API over web scraping:

| Platform | API            | Pagination       | Rate Limit |
| -------- | -------------- | ---------------- | ---------- |
| Haravan  | Admin REST API | Limit=50, cursor | 2 req/sec  |
| Shopee   | Partner v2     | offset/limit     | 10 req/sec |
| Lazada   | Open Platform  | page/page_size   | 10 req/min |
| TikTok   | Seller API     | cursor           | 10 req/sec |

### 5. Haravan Pagination Cap

Haravan caps `limit` at 50. MUST loop:

```javascript
let page = 1;
let allProducts = [];
do {
  const resp = await fetch(`/admin/products.json?limit=50&page=${page}`);
  allProducts = allProducts.concat(resp.products);
  page++;
} while (resp.products.length === 50);
```

### 6. AI Semantic Auditing (Optional)

Use GPT-4o-mini to verify product attributes against source-of-truth spreadsheet:

```
Prompt: "Compare this product's online listing against the official data.
Online: {name, price, color, size}
Official: {name, price, color, size}
Report any mismatches."
```

## Replenishment Pipeline

```
KiotViet MySQL (sales velocity) → Calculate reorder quantity per size
→ Generate purchase order (Word template)
→ Send for approval
→ Update tracking sheet
```

### Reorder Formula

```
reorder_qty = target_stock - current_stock
target_stock = avg_daily_sales × lead_time_days × safety_factor
```

## Credentials Required

- `haravan` — Admin API key + shop URL
- `shopeeApi` — Partner ID + Secret + Shop ID
- `lazadaApi` — App Key + Secret + Access Token
- `tiktokApi` — App Key + Secret + Shop ID
- `mysqlApi` — KiotViet database connection
