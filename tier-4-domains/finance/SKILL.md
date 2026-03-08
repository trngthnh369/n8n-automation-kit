---
name: finance
tier: 4
category: domain
version: 1.0.0
description: Finance & accounting automation — reconciliation, invoicing, expense tracking, financial reports.
triggers:
  - "finance"
  - "accounting"
  - "invoice"
  - "hóa đơn"
  - "revenue"
  - "expense"
  - "reconciliation"
  - "đối soát"
requires:
  - builder
  - n8n-mcp
recommends:
  - google-sheets
  - data-pipeline
related:
  - "[[order-fulfillment]]"
  - "[[data-pipeline]]"
---

# 💰 Finance & Accounting Automation

Revenue reconciliation, automated invoicing, expense tracking, and financial reporting.

## Architecture: Financial Data Pipeline

```
Data Sources:
├── Bank transactions (API/CSV import)
├── POS sales (KiotViet/Sapo API)
├── Ecommerce revenue (Shopee/Lazada/TikTok)
├── Manual entries (Google Sheets)
    ↓
Processing:
├── Transaction categorization (rules + AI)
├── Revenue reconciliation (bank ↔ POS ↔ ecommerce)
├── Invoice generation
├── Expense approval workflow
    ↓
Reporting:
├── Daily revenue summary
├── Monthly P&L report
├── Cash flow forecast
└── Tax reporting prep
```

## Key Patterns

### 1. Revenue Reconciliation

```
Schedule Trigger (daily, 8AM)
→ Fetch bank transactions (yesterday)
→ Fetch POS sales (yesterday)
→ Fetch marketplace payouts (yesterday)
→ Code node: Match transactions
    For each bank_txn:
      Find matching POS sale (by amount ± 1%)
      Find matching marketplace payout (by reference)
      IF matched → status: "RECONCILED"
      IF unmatched → status: "PENDING_REVIEW"
→ Write reconciliation report to Sheets
→ IF unmatched > threshold → alert via [[messaging]]
```

### 2. Transaction Categorization

```javascript
function categorize(transaction) {
  const desc = transaction.description.toLowerCase();
  const rules = [
    { pattern: /luong|salary/i, category: "Lương" },
    { pattern: /dien|electric/i, category: "Điện" },
    { pattern: /nuoc|water/i, category: "Nước" },
    { pattern: /thue|rent/i, category: "Thuê mặt bằng" },
    { pattern: /quang cao|ads/i, category: "Marketing" },
    { pattern: /van chuyen|shipping/i, category: "Vận chuyển" },
  ];
  const match = rules.find((r) => r.pattern.test(desc));
  return match ? match.category : "Chưa phân loại";
}
// For uncategorized: send to AI for smart categorization
```

### 3. Auto Invoice Generation

```
Order completed trigger
→ Fetch order details
→ Generate invoice data:
  { invoice_no, date, customer, items[], subtotal, tax, total }
→ Create invoice document (Google Docs template / PDF)
→ Send to customer via email
→ Log in accounting sheet
```

### 4. Expense Approval Workflow

```
Employee submits expense (Form/Sheet)
→ Validate: receipt attached? within budget?
→ IF amount < 1M VND → auto-approve
→ IF amount >= 1M → notify manager via Slack/Zalo
  → Manager replies "approve"/"reject"
  → Update expense status
  → IF approved → schedule reimbursement
```

### 5. Monthly P&L Report

```
Schedule Trigger (1st of month, 9AM)
→ Aggregate last month:
  Revenue:
    POS sales total
    Online sales total (per marketplace)
    Other income
  Expenses:
    COGS (cost of goods sold)
    Operating expenses (rent, salary, utilities)
    Marketing spend
    Shipping costs
  Calculate:
    Gross profit = Revenue - COGS
    Operating profit = Gross profit - Operating expenses
    Net profit = Operating profit - Tax
→ Write P&L to Sheets
→ Send summary to management via email
```

### 6. Cash Flow Monitoring

```javascript
const today = DateTime.now().setZone("Asia/Ho_Chi_Minh");
// Expected inflow
const expectedInflow = pendingOrders.reduce((sum, o) => sum + o.total, 0);
// Expected outflow
const expectedOutflow = upcomingExpenses.reduce((sum, e) => sum + e.amount, 0);
// Net position
const netCashFlow = currentBalance + expectedInflow - expectedOutflow;

if (netCashFlow < MINIMUM_THRESHOLD) {
  // Alert: cash flow warning
}
```

## Vietnamese Tax & Invoicing

### VAT Invoice (Hóa đơn GTGT)

- Standard VAT rate: 8% (reduced) or 10% (standard)
- E-invoice required for B2B (Nghị định 123/2020)
- Invoice series: format `1C25T` (year-based)

### Common Integration: e-Invoice providers

- VNPT e-Invoice API
- Viettel sinvoice API
- BKAV e-Hoadon API

## Credentials Required

- Bank API credentials (varies by bank, many use CSV import)
- `kiotVietApi` — POS sales data
- Marketplace APIs — revenue data
- `googleSheetsOAuth2Api` — financial reports
- e-Invoice provider API (if applicable)
