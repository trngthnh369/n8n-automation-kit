---
name: order-fulfillment
tier: 4
category: domain
version: 1.0.0
description: Order & fulfillment automation — multi-channel order sync, shipping, invoicing, inventory update.
triggers:
  - "order"
  - "fulfillment"
  - "đơn hàng"
  - "shipping"
  - "invoice"
  - "xuất kho"
  - "KiotViet"
  - "Sapo"
requires:
  - builder
  - n8n-mcp
recommends:
  - inventory
  - messaging
  - google-sheets
related:
  - "[[architect]]"
  - "[[inventory]]"
---

# 📋 Order & Fulfillment Automation

Multi-channel order processing, shipping management, and invoicing patterns.

## Architecture: Order Lifecycle

```
Order Sources:
├── Shopee (webhook/poll)
├── Lazada (webhook/poll)
├── TikTok Shop (webhook/poll)
├── Website/Haravan (webhook)
├── Zalo/Facebook (manual → CRM)
└── POS/KiotViet (webhook/poll)
    ↓
Order Processing:
├── Normalize order format (cross-platform)
├── Validate (stock check, address, payment)
├── Assign to warehouse
├── Create pick/pack list
    ↓
Fulfillment:
├── Generate shipping label (GHN/GHTK/Viettel Post)
├── Update tracking number to marketplace
├── Deduct inventory (KiotViet/Sapo)
├── Track delivery status (poll carrier API)
    ↓
Post-Fulfillment:
├── Confirm delivery → trigger invoice
├── Handle returns/refunds
├── Update revenue report
└── Notify customer (review request)
```

## Key Patterns

### 1. Multi-Channel Order Normalization

```javascript
function normalizeOrder(source, rawOrder) {
  switch (source) {
    case "shopee":
      return {
        order_id: rawOrder.ordersn,
        customer: rawOrder.buyer_user.user_name,
        phone: rawOrder.buyer_user.phone,
        address: rawOrder.recipient_address.full_address,
        items: rawOrder.item_list.map((i) => ({
          sku: i.model_sku || i.item_sku,
          name: i.item_name,
          qty: i.model_quantity_purchased,
          price: i.model_discounted_price / 100000, // Shopee cent
        })),
        total: rawOrder.total_amount / 100000,
        status: mapStatus(source, rawOrder.order_status),
      };
    case "lazada":
      return {
        /* similar mapping */
      };
    case "tiktok":
      return {
        /* similar mapping */
      };
  }
}
```

### 2. Marketplace Price Unit Conversion

**Critical** — each platform has different price units:

| Platform | Unit             | Convert to VND   |
| -------- | ---------------- | ---------------- |
| Shopee   | Cents (×100,000) | `price / 100000` |
| Lazada   | VND (direct)     | `price`          |
| TikTok   | Cents (×100)     | `price / 100`    |
| Haravan  | VND (direct)     | `price`          |

### 3. Shipping Label Generation

```
GHN (Giao Hàng Nhanh):
  POST https://online-gateway.ghn.vn/shiip/public-api/v2/shipping-order/create
  Headers: Token: {api_key}, ShopId: {shop_id}
  Body: { to_name, to_phone, to_address, to_ward_code, items[], weight, payment_type_id }

GHTK:
  POST https://services.giaohangtietkiem.vn/services/shipment/order
  Headers: Token: {api_key}
  Body: { products[], order: { pick_address, deliver_address } }
```

### 4. Inventory Deduction on Order

```
Order confirmed → For each item:
  GET current stock (KiotViet/Sapo API)
  IF stock >= ordered_qty → deduct
  IF stock < ordered_qty → flag alert, partial fulfillment or backorder
  Update stock level in system
```

### 5. Delivery Tracking Loop

```
Schedule Trigger (every 2h)
→ Fetch orders with status "SHIPPED"
→ For each: query carrier API for delivery status
→ IF "DELIVERED" → update order status → trigger invoice → notify customer
→ IF "RETURNED" → flag for refund processing
→ IF "FAILED DELIVERY" → notify customer service + reschedule
```

### 6. Return/Refund Handling

```
Return request webhook
→ Validate return reason + timeframe (7 days policy)
→ IF approved → generate return shipping label
→ Track return shipment
→ On receipt → inspect → process refund (full/partial)
→ Restock item (if condition OK)
→ Update accounting
```

## Integration APIs

| System       | Purpose         | API         |
| ------------ | --------------- | ----------- |
| KiotViet     | POS + Inventory | REST API v1 |
| Sapo         | POS + Inventory | REST API    |
| GHN          | Shipping        | REST API v2 |
| GHTK         | Shipping        | REST API    |
| Viettel Post | Shipping        | REST API    |

## Credentials Required

- Marketplace APIs (Shopee/Lazada/TikTok Partner tokens)
- `kiotVietApi` — POS integration
- Shipping carrier API keys (GHN/GHTK/Viettel Post)
- `googleSheetsOAuth2Api` — order tracking sheets
