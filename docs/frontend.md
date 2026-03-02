# Frontend Guide

The frontend is a Vue 3 single-page application built with Vite. It runs on port 3000 and communicates with the FastAPI backend on port 8001.

## Project Structure

```
client/src/
├── main.js                # App entry — creates Vue app, registers router
├── App.vue                # Root component — sidebar navigation, modals, layout
├── api.js                 # Centralized Axios API client
├── views/                 # Page-level route components
│   ├── Dashboard.vue      # KPI cards, charts, summary metrics
│   ├── Inventory.vue      # Inventory item list with warehouse/category filters
│   ├── Orders.vue         # Order list with status/month filtering
│   ├── Demand.vue         # Demand forecast table with trend indicators
│   ├── Spending.vue       # Spending analytics: summary, monthly, by category
│   ├── Reports.vue        # Quarterly performance and monthly trends
│   └── Backlog.vue        # Backlog items, purchase order creation
├── components/            # Reusable UI components
│   ├── FilterBar.vue      # Shared filter controls (period, location, category, status)
│   ├── LanguageSwitcher.vue  # English/Japanese toggle
│   ├── ProfileMenu.vue    # User avatar dropdown
│   ├── TasksModal.vue     # Task list modal
│   ├── ProfileDetailsModal.vue
│   ├── BacklogDetailModal.vue
│   ├── CostDetailModal.vue
│   ├── InventoryDetailModal.vue
│   └── ProductDetailModal.vue
├── composables/           # Shared reactive logic (singleton pattern)
│   ├── useFilters.js      # Global filter state
│   ├── useAuth.js         # Mock user data and auth state
│   └── useI18n.js         # Internationalization
├── locales/               # Translation dictionaries
│   ├── en.js              # English translations
│   └── ja.js              # Japanese translations
└── utils/
    └── currency.js        # Currency formatting helpers
```

## Composables

### useFilters

**File:** `client/src/composables/useFilters.js`

Manages the 4 global filter dimensions as module-level `ref()` values (singleton pattern — all components share the same state).

```js
const { selectedPeriod, selectedLocation, selectedCategory, selectedStatus,
        hasActiveFilters, resetFilters, getCurrentFilters } = useFilters()
```

- `getCurrentFilters()` returns an object ready for API calls: `{ warehouse, category, status, month }`
- `hasActiveFilters` is a computed boolean
- `resetFilters()` sets all filters back to `'all'`

### useAuth

**File:** `client/src/composables/useAuth.js`

Provides mock user data. The user's name, job title, department, and task list change based on the current locale (English or Japanese).

```js
const { currentUser, isAuthenticated, logout, getInitials } = useAuth()
```

- `currentUser` is a computed ref that reacts to locale changes
- `logout()` is a placeholder (shows an alert)

### useI18n

**File:** `client/src/composables/useI18n.js`

Provides translation and locale management.

```js
const { t, setLocale, currentLocale, currentCurrency,
        translateProductName, translateCustomerName, translateWarehouse } = useI18n()
```

- `t('nav.dashboard')` looks up a dot-separated key in the current locale's translations. Falls back to English, then returns the key itself.
- `t('greeting', { name: 'John' })` supports `{placeholder}` substitution.
- `setLocale('ja')` switches locale and persists to `localStorage`.
- `currentCurrency` is computed: `'USD'` for English, `'JPY'` for Japanese.
- `translateProductName`, `translateCustomerName`, `translateWarehouse` handle data-level translations.

## API Client

**File:** `client/src/api.js`

All backend communication goes through this module. It exports a single `api` object with async methods:

| Method                              | Endpoint                          | Filters          |
|-------------------------------------|-----------------------------------|------------------|
| `getInventory(filters)`             | `GET /api/inventory`              | warehouse, category |
| `getInventoryItem(id)`              | `GET /api/inventory/{id}`         | —                |
| `getOrders(filters)`                | `GET /api/orders`                 | warehouse, category, status, month |
| `getOrder(id)`                      | `GET /api/orders/{id}`            | —                |
| `getDemandForecasts()`              | `GET /api/demand`                 | —                |
| `getBacklog()`                      | `GET /api/backlog`                | —                |
| `getDashboardSummary(filters)`      | `GET /api/dashboard/summary`      | all 4 filters    |
| `getSpendingSummary()`              | `GET /api/spending/summary`       | —                |
| `getMonthlySpending()`              | `GET /api/spending/monthly`       | —                |
| `getCategorySpending()`             | `GET /api/spending/categories`    | —                |
| `getTransactions()`                 | `GET /api/spending/transactions`  | —                |
| `getTasks()`                        | `GET /api/tasks`                  | —                |
| `createTask(data)`                  | `POST /api/tasks`                 | —                |
| `deleteTask(id)`                    | `DELETE /api/tasks/{id}`          | —                |
| `toggleTask(id)`                    | `PATCH /api/tasks/{id}`           | —                |
| `createPurchaseOrder(data)`         | `POST /api/purchase-orders`       | —                |
| `getPurchaseOrderByBacklogItem(id)` | `GET /api/purchase-orders/{id}`   | —                |

Filter parameters with value `'all'` are excluded from the request.

## Component Patterns

### Data loading

Every view follows the same pattern:

```js
const data = ref([])
const loading = ref(false)

const loadData = async () => {
  try {
    loading.value = true
    data.value = await api.getData(getCurrentFilters())
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
}

onMounted(() => loadData())
```

Views typically watch filter changes and reload data when filters change.

### Template states

```vue
<div v-if="loading">Loading...</div>
<div v-else-if="error">{{ error }}</div>
<div v-else><!-- render data --></div>
```

### Charts

Charts are built with custom SVG elements and CSS. No charting library is used. Chart data is derived via `computed()` properties.

## Styling

- Scoped `<style scoped>` per component
- CSS Grid for page layouts
- Color palette: slate/gray tones (`#0f172a`, `#64748b`, `#e2e8f0`)
- Status colors: green (delivered), blue (shipped), yellow (processing), red (backordered)
- No CSS framework — all custom styles
- No emojis in the UI
