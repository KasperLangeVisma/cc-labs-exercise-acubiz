# Development & Testing Guide

## Prerequisites

- **Python 3.11+**
- **Node.js** (with npm)
- **uv** — Python package manager ([install guide](https://docs.astral.sh/uv/getting-started/installation/))

## Setup & Startup

### Quick start (macOS/Linux)

```bash
./scripts/start.sh
# Starts both backend (port 8001) and frontend (port 3000)

./scripts/stop.sh
# Stops both servers
```

### Manual startup (all platforms)

Run each in a separate terminal:

**Backend:**
```bash
cd server
uv venv && uv sync        # First time only
uv run python main.py     # Starts on http://localhost:8001
```

**Frontend:**
```bash
cd client
npm install                # First time only
npm run dev                # Starts on http://localhost:3000
```

### URLs

| Service          | URL                          |
|------------------|------------------------------|
| Frontend         | http://localhost:3000         |
| Backend API      | http://localhost:8001         |
| Swagger UI (API) | http://localhost:8001/docs    |

## Testing

### Running tests

All tests are in the `tests/` directory and use pytest with FastAPI's `TestClient`.

```bash
cd tests
uv run pytest -v                          # Run all tests (verbose)
uv run pytest backend/test_inventory.py   # Run a specific file
uv run pytest --cov                       # Run with coverage report
```

### Test structure

```
tests/
├── pytest.ini                   # Pytest configuration
└── backend/
    ├── conftest.py              # Shared fixtures (TestClient, sample data)
    ├── test_inventory.py        # 10 tests — inventory CRUD and filtering
    ├── test_orders.py           # 15 tests — order filtering by status, month, category
    ├── test_dashboard.py        # 13 tests — summary calculations, filter combos
    └── test_misc_endpoints.py   # 13 tests — demand, backlog, spending, transactions
```

**Total: 51 tests**

### Key fixtures (conftest.py)

- `client` — a `TestClient` instance wrapping the FastAPI app
- `sample_inventory_item` — a sample inventory dict for assertions
- `sample_order` — a sample order dict for assertions

### Writing new tests

```python
def test_new_endpoint(client):
    response = client.get("/api/new-endpoint?param=value")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0
```

Place new test files in `tests/backend/` and name them `test_*.py`.

## Production Build

```bash
cd client
npm run build    # Output: client/dist/
npm run preview  # Preview the production build locally
```

## Mock Data

All data lives in `server/data/*.json`. To regenerate it:

```bash
cd server
uv run python generate_data.py
```

After changing JSON data:
1. Restart the backend server (data is loaded at startup)
2. Update Pydantic models in `server/main.py` if the structure changed
3. Update or add tests as needed

## Common Pitfalls

### Frontend
- **v-for keys:** Always use unique IDs (`item.id`, `item.sku`), never array indices
- **Date validation:** Always validate dates before calling `.getMonth()` on a `Date` object
- **Ref access:** Use `.value` in `<script>`, but not in `<template>` (auto-unwrapped)
- **Filter watching:** When filters change, views need to reload data from the API

### Backend
- **Pydantic models:** Must be updated when JSON data structure changes
- **Don't mutate data:** Filter on copies of the data lists, don't modify the originals
- **Filter parameter naming:** Keep `warehouse`, `category`, `status`, `month` consistent across endpoints
- **Inventory has no month filter:** Inventory items don't have a time dimension

### General
- **Revenue goals:** The dashboard uses $800K/month for a single warehouse and $9.6M YTD for all warehouses
- **CORS:** Currently allows all origins — restrict for production
- **No auth:** Authentication is mocked — the app is not production-ready without real auth
- **No persistence:** Data changes don't survive a server restart
