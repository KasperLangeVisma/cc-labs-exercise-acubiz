# Backend Guide

The backend is a Python FastAPI application that serves a REST API on port 8001. It uses in-memory mock data loaded from JSON files — there is no database.

## Project Structure

```
server/
├── main.py            # FastAPI app: endpoints, Pydantic models, filtering logic
├── mock_data.py       # Loads JSON files into module-level variables
├── generate_data.py   # Script to regenerate sample data
├── pyproject.toml     # Dependencies (FastAPI, Uvicorn, Pydantic)
├── uv.lock            # Dependency lock file
├── .venv/             # Virtual environment (created by uv)
└── data/              # JSON mock data
    ├── inventory.json
    ├── orders.json
    ├── demand_forecasts.json
    ├── backlog_items.json
    ├── purchase_orders.json
    ├── spending.json       # Contains spending_summary, monthly_spending, category_spending
    └── transactions.json
```

## Application Entry Point

**File:** `server/main.py`

The entire API is defined in a single file:

1. **Pydantic models** — `InventoryItem`, `Order`, `DemandForecast`, `BacklogItem`, `PurchaseOrder`, `CreatePurchaseOrderRequest`
2. **Filtering functions** — `apply_filters()`, `filter_by_month()`
3. **CORS middleware** — allows all origins (development only)
4. **Route handlers** — all `/api/*` endpoints

Start the server:

```bash
cd server
uv run python main.py
# Runs on http://localhost:8001
# Swagger UI at http://localhost:8001/docs
```

## Pydantic Models

All API responses are validated against these models:

| Model                       | Key Fields                                                          |
|-----------------------------|---------------------------------------------------------------------|
| `InventoryItem`             | id, sku, name, category, warehouse, quantity_on_hand, reorder_point, unit_cost, location, last_updated |
| `Order`                     | id, order_number, customer, items (list of dicts), status, order_date, expected_delivery, total_value, actual_delivery?, warehouse?, category? |
| `DemandForecast`            | id, item_sku, item_name, current_demand, forecasted_demand, trend, period |
| `BacklogItem`               | id, order_id, item_sku, item_name, quantity_needed, quantity_available, days_delayed, priority, has_purchase_order? |
| `PurchaseOrder`             | id, backlog_item_id, supplier_name, quantity, unit_cost, expected_delivery_date, status, created_date, notes? |
| `CreatePurchaseOrderRequest`| backlog_item_id, supplier_name, quantity, unit_cost, expected_delivery_date, notes? |

## Mock Data System

**File:** `server/mock_data.py`

At import time, this module loads all JSON files from `server/data/` and exports them as module-level variables:

```python
inventory_items = load_json_file('inventory.json')       # list of dicts
orders = load_json_file('orders.json')                   # list of dicts
demand_forecasts = load_json_file('demand_forecasts.json')
backlog_items = load_json_file('backlog_items.json')
purchase_orders = load_json_file('purchase_orders.json')

spending_data = load_json_file('spending.json')
spending_summary = spending_data['spending_summary']      # dict
monthly_spending = spending_data['monthly_spending']      # list
category_spending = spending_data['category_spending']    # list

recent_transactions = load_json_file('transactions.json') # list
```

Data is loaded once at startup and lives in memory for the server's lifetime. Changes to JSON files require a server restart.

To regenerate sample data, run `uv run python generate_data.py`.

## Filtering Logic

### apply_filters(items, warehouse, category, status)

Filters a list of dicts by warehouse (exact match), category (case-insensitive), and status (case-insensitive). Parameters that are `None` or `'all'` are skipped.

### filter_by_month(items, month)

Filters by the `order_date` field. Supports:

- **Direct month match:** `2025-01` — checks if the string appears in `order_date`
- **Quarter match:** `Q1-2025` — maps to `['2025-01', '2025-02', '2025-03']` via `QUARTER_MAP` and checks if any month string appears in `order_date`

The quarter mapping:

```python
QUARTER_MAP = {
    'Q1-2025': ['2025-01', '2025-02', '2025-03'],
    'Q2-2025': ['2025-04', '2025-05', '2025-06'],
    'Q3-2025': ['2025-07', '2025-08', '2025-09'],
    'Q4-2025': ['2025-10', '2025-11', '2025-12']
}
```

## CORS Configuration

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],       # All origins (dev only)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

For production, restrict `allow_origins` to specific domains.

## Adding a New Endpoint

1. **Define a Pydantic model** (if the response shape is new):

```python
class NewItem(BaseModel):
    id: str
    name: str
    value: float
```

2. **Add mock data** — either add a new JSON file in `server/data/` and load it in `mock_data.py`, or compute from existing data.

3. **Create the route handler:**

```python
@app.get("/api/new-items", response_model=List[NewItem])
def get_new_items(
    warehouse: Optional[str] = None,
    category: Optional[str] = None
):
    """Get new items with optional filtering."""
    return apply_filters(new_items_data, warehouse, category)
```

4. **Write tests** in `tests/backend/`.

5. **Update the frontend** `api.js` to add a corresponding client method.

## Dependencies

From `server/pyproject.toml`:

```
Runtime:      fastapi>=0.110.0, uvicorn>=0.24.0, pydantic>=2.5.0
Dev/Test:     pytest>=8.0.0, pytest-asyncio>=0.23.0, httpx>=0.27.0, pytest-cov>=4.1.0
Python:       >=3.11
```

Package management uses [uv](https://docs.astral.sh/uv/):

```bash
uv venv          # Create virtual environment
uv sync          # Install dependencies
uv run <command> # Run within the venv
```
