---
name: data-pipeline
tier: 4
category: domain
version: 1.0.0
description: Data pipeline & ETL patterns — multi-source ingestion, transformation, cross-system sync.
triggers:
  - "data pipeline"
  - "ETL"
  - "data sync"
  - "import"
  - "export"
  - "database"
  - "migration"
  - "CSV"
requires:
  - builder
  - n8n-mcp
recommends:
  - google-sheets
related:
  - "[[architect]]"
---

# 🔄 Data Pipeline & ETL

Patterns for multi-source data ingestion, transformation, and cross-system synchronization.

## Architecture: Extract-Transform-Load

```
EXTRACT (Sources):
├── APIs (REST/GraphQL) → HTTP Request node
├── Databases (MySQL/Postgres/MongoDB) → DB nodes
├── Files (CSV/Excel/JSON) → Read Binary File + Spreadsheet node
├── Google Sheets → Sheets node
├── Webhooks → real-time push
└── Web scraping → HTTP + Code (parse HTML)
    ↓
TRANSFORM:
├── Clean: Remove nulls, trim whitespace, normalize encoding
├── Map: Rename fields, type conversion
├── Enrich: Lookup additional data from secondary source
├── Aggregate: Group-by, sum, count, pivot
├── Validate: Check constraints, flag anomalies
├── Deduplicate: Match by key, merge records
    ↓
LOAD (Destinations):
├── Database (INSERT/UPSERT)
├── Google Sheets (Append/Update)
├── API (POST/PUT)
├── File export (CSV/Excel/JSON)
└── Data warehouse (BigQuery/Snowflake)
```

## Key Patterns

### 1. Paginated API Extraction

```javascript
// Offset-based pagination
let page = 0;
let allItems = [];
let hasMore = true;
while (hasMore) {
  const resp = await $helpers.httpRequest({
    url: `https://api.example.com/items?offset=${page * 100}&limit=100`,
  });
  allItems = allItems.concat(resp.data);
  hasMore = resp.data.length === 100;
  page++;
}
return allItems.map((item) => ({ json: item }));
```

### 2. Cursor-Based Pagination

```javascript
let cursor = null;
let allItems = [];
do {
  const url = cursor
    ? `https://api.example.com/items?cursor=${cursor}`
    : "https://api.example.com/items";
  const resp = await $helpers.httpRequest({ url });
  allItems = allItems.concat(resp.items);
  cursor = resp.next_cursor || null;
} while (cursor);
return allItems.map((item) => ({ json: item }));
```

### 3. CSV/Excel Import Pipeline

```
Read Binary File → Spreadsheet node (parse)
→ Code node (clean & validate):
    - Skip header rows
    - Trim whitespace
    - Parse dates (handle VN format: DD/MM/YYYY)
    - Convert numeric strings to numbers
    - Flag invalid rows
→ SplitInBatches → Upsert to DB/Sheets
```

### 4. Cross-System Sync (Bidirectional)

```
Schedule Trigger (every 15min)
→ Fetch records from System A (modified_after: last_sync)
→ Fetch records from System B (modified_after: last_sync)
→ Diff: find new/updated/deleted in each
→ Sync A→B: create/update records
→ Sync B→A: create/update records
→ Update last_sync timestamp
→ Log sync results
```

### 5. Data Validation Framework

```javascript
function validate(record) {
  const errors = [];
  if (!record.email || !record.email.includes("@"))
    errors.push("Invalid email");
  if (!record.phone || record.phone.length < 9) errors.push("Invalid phone");
  if (record.amount && isNaN(record.amount)) errors.push("Amount not numeric");
  return {
    ...record,
    is_valid: errors.length === 0,
    validation_errors: errors.join("; "),
  };
}
```

### 6. Incremental Load (Delta)

```
Last run timestamp stored in Sheets/DB
→ Fetch only records WHERE updated_at > last_run
→ Process delta records
→ Update last_run timestamp
```

**Advantage**: 100x faster than full reload for large datasets.

### 7. Error Quarantine

```
Valid records → main pipeline → load to destination
Invalid records → quarantine sheet/table → manual review
→ Daily email: "X records need attention"
```

## Database Patterns

### MySQL/Postgres Upsert

```sql
INSERT INTO products (sku, name, price, stock)
VALUES ($1, $2, $3, $4)
ON CONFLICT (sku)
DO UPDATE SET name=$2, price=$3, stock=$4, updated_at=NOW()
```

### Batch Insert (Performance)

```
Collect 100 records in Code node → single INSERT with VALUES list
→ 1 API call vs 100 individual inserts
```

## Credentials Required

- `mysqlApi` / `postgres` — database connections
- `mongoDb` — MongoDB connection
- `googleSheetsOAuth2Api` — Sheets source/destination
- Various API credentials for source systems
