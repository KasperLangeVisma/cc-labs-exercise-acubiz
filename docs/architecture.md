# System Architecture

## Overview

The Factory Inventory Management System is a full-stack web application for tracking factory inventory, orders, demand forecasts, and spending analytics. It uses a Vue 3 single-page application frontend backed by a Python FastAPI REST API.

All data is stored as JSON files and loaded into memory at server startup — there is no database.

## Tech Stack

| Layer    | Technology                        | Port |
|----------|-----------------------------------|------|
| Frontend | Vue 3 + Composition API + Vite    | 3000 |
| Backend  | Python FastAPI + Uvicorn          | 8001 |
| Data     | JSON files (in-memory at runtime) | —    |

**Frontend dependencies:** Vue 3, Vue Router 4, Axios, Vite 5
**Backend dependencies:** FastAPI, Uvicorn, Pydantic 2

## Directory Structure

```
cc-labs-exercise-acubiz/
├── client/                        # Vue 3 frontend
│   ├── src/
│   │   ├── main.js                # App entry point
│   │   ├── App.vue                # Root component (navigation, layout)
│   │   ├── api.js                 # Centralized API client (Axios)
│   │   ├── views/                 # Page-level components
│   │   │   ├── Dashboard.vue
│   │   │   ├── Inventory.vue
│   │   │   ├── Orders.vue
│   │   │   ├── Demand.vue
│   │   │   ├── Spending.vue
│   │   │   ├── Reports.vue
│   │   │   └── Backlog.vue
│   │   ├── components/            # Reusable UI components
│   │   │   ├── FilterBar.vue
│   │   │   ├── LanguageSwitcher.vue
│   │   │   ├── ProfileMenu.vue
│   │   │   └── *Modal.vue         # Detail modals
│   │   ├── composables/           # Shared reactive logic
│   │   │   ├── useFilters.js
│   │   │   ├── useAuth.js
│   │   │   └── useI18n.js
│   │   ├── locales/               # Translation files (en, ja)
│   │   └── utils/
│   │       └── currency.js
│   ├── index.html
│   ├── vite.config.js
│   └── package.json
│
├── server/                        # FastAPI backend
│   ├── main.py                    # API endpoints, models, filtering
│   ├── mock_data.py               # JSON data loader
│   ├── generate_data.py           # Data regeneration script
│   ├── pyproject.toml             # Python dependencies
│   └── data/                      # JSON mock data files
│       ├── inventory.json
│       ├── orders.json
│       ├── demand_forecasts.json
│       ├── backlog_items.json
│       ├── purchase_orders.json
│       ├── spending.json
│       └── transactions.json
│
├── tests/                         # pytest test suite (51 tests)
│   ├── pytest.ini
│   └── backend/
│       ├── conftest.py
│       ├── test_inventory.py
│       ├── test_orders.py
│       ├── test_dashboard.py
│       └── test_misc_endpoints.py
│
├── scripts/                       # Startup/stop scripts (macOS/Linux)
│   ├── start.sh
│   └── stop.sh
│
├── docs/                          # Documentation
├── README.md
└── CLAUDE.md
```

## Data Flow

```
┌─────────────────────────────────────────────────────────┐
│  Browser                                                │
│                                                         │
│  Vue Components (Dashboard, Inventory, Orders, ...)     │
│       │ emit filter changes          ▲ reactive render  │
│       ▼                              │                  │
│  FilterBar / useFilters composable   │                  │
│       │ getCurrentFilters()          │                  │
│       ▼                              │                  │
│  api.js (Axios)                      │                  │
│       │ HTTP GET + query params      │ JSON response    │
└───────┼──────────────────────────────┼──────────────────┘
        │                              │
        ▼                              │
┌─────────────────────────────────────────────────────────┐
│  FastAPI Backend (port 8001)                            │
│                                                         │
│  Route handler                                          │
│       │ parse query params                              │
│       ▼                                                 │
│  apply_filters() / filter_by_month()                    │
│       │ filter in-memory data                           │
│       ▼                                                 │
│  Pydantic model validation → JSON response              │
│                                                         │
│  Data source: JSON files loaded at startup              │
│  (server/data/*.json → mock_data.py)                    │
└─────────────────────────────────────────────────────────┘
```

## Filter System

The application uses a 4-dimension filter system shared across all views:

| Filter   | UI Label    | API Param   | Values                                  |
|----------|-------------|-------------|-----------------------------------------|
| Period   | Time Period | `month`     | `all`, `Q1-2025`..`Q4-2025`, `2025-01`..`2025-12` |
| Location | Warehouse   | `warehouse` | `all`, `San Francisco`, `London`, `Tokyo` |
| Category | Category    | `category`  | `all`, `Circuit Boards`, `Sensors`, `Actuators`, `Controllers` |
| Status   | Status      | `status`    | `all`, `Delivered`, `Shipped`, `Processing`, `Backordered` |

- Filters are managed by the `useFilters` composable (singleton pattern — shared across all components)
- The `FilterBar` component provides the UI controls
- `getCurrentFilters()` builds the query parameter object for API calls
- Backend skips filtering when a parameter is `None` or `'all'`
- Category matching is case-insensitive; warehouse matching is exact

## Key Patterns

**Composables (shared state):** Module-level `ref()` declarations act as singletons. Any component calling `useFilters()` gets the same reactive state.

**API client:** All HTTP calls go through `client/src/api.js`, which wraps Axios and handles query parameter construction.

**Pydantic validation:** Every API response is validated against a Pydantic `BaseModel`, ensuring consistent response shapes.

**In-memory filtering:** Data is loaded once from JSON files at startup. All filtering happens in Python list comprehensions — no database queries.

**Internationalization:** The `useI18n` composable provides `t(key)` translation, product/customer/warehouse name translation, and automatic currency switching (USD for English, JPY for Japanese). Locale is persisted in `localStorage`.
