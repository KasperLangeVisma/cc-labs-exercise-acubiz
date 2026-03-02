# API Reference

**Base URL:** `http://localhost:8001`
**Interactive docs:** `http://localhost:8001/docs` (Swagger UI)

## Filtering

Most endpoints accept optional query parameters for filtering. The filtering behavior is:

- Omitted or `all` — no filtering applied
- `warehouse` — exact match (e.g., `San Francisco`, `London`, `Tokyo`)
- `category` — case-insensitive match (e.g., `Circuit Boards`, `Sensors`, `Actuators`, `Controllers`)
- `status` — case-insensitive match (e.g., `Delivered`, `Shipped`, `Processing`, `Backordered`)
- `month` — substring match on `order_date`. Accepts:
  - Direct month: `2025-01`, `2025-02`, ... `2025-12`
  - Quarter: `Q1-2025` (maps to `2025-01`, `2025-02`, `2025-03`), etc.

## Endpoints

### Root

```
GET /
```
Returns API name and version.

---

### Inventory

```
GET /api/inventory
```
List all inventory items.

| Param      | Type   | Description              |
|------------|--------|--------------------------|
| `warehouse`| string | Filter by warehouse name |
| `category` | string | Filter by category       |

**Response:** `InventoryItem[]`

```json
{
  "id": "1",
  "sku": "PCB-001",
  "name": "Single Layer PCB Assembly",
  "category": "Circuit Boards",
  "warehouse": "San Francisco",
  "quantity_on_hand": 450,
  "reorder_point": 200,
  "unit_cost": 24.99,
  "location": "Warehouse A-12",
  "last_updated": "2025-09-30T10:30:00"
}
```

```
GET /api/inventory/{item_id}
```
Get a single inventory item by ID. Returns 404 if not found.

---

### Orders

```
GET /api/orders
```
List all orders.

| Param      | Type   | Description                  |
|------------|--------|------------------------------|
| `warehouse`| string | Filter by warehouse          |
| `category` | string | Filter by category           |
| `status`   | string | Filter by order status       |
| `month`    | string | Filter by month or quarter   |

**Response:** `Order[]`

```json
{
  "id": "1",
  "order_number": "ORD-2025-0001",
  "customer": "MegaCorp Industries",
  "items": [{ "sku": "SPR-602", "name": "Compression Spring", "quantity": 981, "unit_price": 89.5 }],
  "status": "Delivered",
  "order_date": "2025-01-08T10:19:00",
  "expected_delivery": "2025-01-21T10:19:00",
  "total_value": 87799.5,
  "actual_delivery": "2025-01-20T10:19:00",
  "warehouse": "Tokyo",
  "category": "Sensors"
}
```

```
GET /api/orders/{order_id}
```
Get a single order by ID. Returns 404 if not found.

---

### Demand Forecasts

```
GET /api/demand
```
List all demand forecasts. No filters.

**Response:** `DemandForecast[]`

```json
{
  "id": "1",
  "item_sku": "PCB-001",
  "item_name": "Single Layer PCB Assembly",
  "current_demand": 320,
  "forecasted_demand": 380,
  "trend": "increasing",
  "period": "Q4-2025"
}
```

---

### Backlog

```
GET /api/backlog
```
List all backlog items. Each item includes a computed `has_purchase_order` flag indicating whether a purchase order exists for it. No filters.

**Response:** `BacklogItem[]`

```json
{
  "id": "1",
  "order_id": "ORD-2025-0042",
  "item_sku": "PCB-001",
  "item_name": "Single Layer PCB Assembly",
  "quantity_needed": 150,
  "quantity_available": 50,
  "days_delayed": 5,
  "priority": "high",
  "has_purchase_order": false
}
```

---

### Dashboard

```
GET /api/dashboard/summary
```
Get aggregated summary statistics.

| Param      | Type   | Description                |
|------------|--------|----------------------------|
| `warehouse`| string | Filter by warehouse        |
| `category` | string | Filter by category         |
| `status`   | string | Filter by order status     |
| `month`    | string | Filter by month or quarter |

**Response:**

```json
{
  "total_inventory_value": 1234567.89,
  "low_stock_items": 3,
  "pending_orders": 12,
  "total_backlog_items": 8,
  "total_orders_value": 987654.32
}
```

`low_stock_items` counts items where `quantity_on_hand <= reorder_point`.
`pending_orders` counts orders with status `Processing` or `Backordered`.

---

### Spending

```
GET /api/spending/summary
```
Returns spending summary statistics (total spend, budget, etc.).

```
GET /api/spending/monthly
```
Returns monthly spending breakdown.

```
GET /api/spending/categories
```
Returns spending grouped by category.

```
GET /api/spending/transactions
```
Returns list of recent transactions.

None of the spending endpoints accept filters.

---

### Reports

```
GET /api/reports/quarterly
```
Returns quarterly performance metrics computed from order data. Each quarter includes:

```json
{
  "quarter": "Q1-2025",
  "total_orders": 25,
  "total_revenue": 125000.00,
  "delivered_orders": 20,
  "avg_order_value": 5000.00,
  "fulfillment_rate": 80.0
}
```

```
GET /api/reports/monthly-trends
```
Returns month-over-month trends computed from order data:

```json
{
  "month": "2025-01",
  "order_count": 10,
  "revenue": 50000.00,
  "delivered_count": 8
}
```

---

### Tasks

```
GET  /api/tasks          # List tasks
POST /api/tasks          # Create a task
DELETE /api/tasks/{id}   # Delete a task
PATCH  /api/tasks/{id}   # Toggle task status
```

---

### Purchase Orders

```
POST /api/purchase-orders
```
Create a purchase order.

**Request body:**

```json
{
  "backlog_item_id": "1",
  "supplier_name": "Acme Corp",
  "quantity": 100,
  "unit_cost": 25.00,
  "expected_delivery_date": "2025-11-15",
  "notes": "Urgent order"
}
```

```
GET /api/purchase-orders/{backlog_item_id}
```
Get the purchase order for a specific backlog item.
