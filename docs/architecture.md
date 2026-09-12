# StockVision — Architecture

## Overview

StockVision is a **smart mobile business intelligence & operations layer**
that sits on top of an existing retail/ERP system (in production, e-Stock).
It does not replace the ERP — it reads its data and turns it into decisions
a business owner can act on from their phone.

```
┌─────────────────────┐
│   Flutter Mobile     │   Material 3, Riverpod state management
│        App           │
└──────────┬───────────┘
           │ REST (JSON over HTTPS/HTTP)
           ▼
┌─────────────────────┐
│   FastAPI Backend    │   Auth, RBAC, request validation, error handling
└──────────┬───────────┘
           │
   ┌───────┼────────────────┐
   │       │                │
   ▼       ▼                ▼
SQL Layer  Analytics     AI Engine
(SQLAlchemy) (pandas/    (Assistant, Alerts,
             NumPy)       Forecasting, scikit-learn)
   │       │                │
   └───────┼────────────────┘
           ▼
   Local SQL Database (SQLite, demo)
```

## Backend layers

| Layer | Location | Responsibility |
|---|---|---|
| API | `backend/app/api/*.py` | Thin FastAPI routers: validate input, call services, return schemas. No business logic here. |
| Services | `backend/app/services/*.py` | All business logic: analytics, alerts, forecasting, recommendations, the AI assistant. |
| Database | `backend/app/database/*.py` | SQLAlchemy models, the connection/session layer, and the seeder. |
| Schemas | `backend/app/schemas/schemas.py` | Pydantic request/response validation. |
| Security | `backend/app/security.py` | Password hashing, JWT issuing/verification, role-based access dependencies. |

This separation means: the mobile app never computes business logic itself
(it only renders what the API returns), and the API never talks to the
database directly (it always goes through `services/`).

## Data source abstraction (important for production)

The **only** place that knows how to open a database connection is
`backend/app/database/connection.py`. Every service and API module imports
`get_db()` from there. Nothing in `services/` or `api/` writes
SQLite-specific SQL — analytics queries use plain SQL/pandas that runs
identically on PostgreSQL, MySQL, or SQL Server.

```
Data Source Interface (connection.py)
        │
        ├── Demo SQLite Adapter        (DATABASE_URL=sqlite:///...)
        │
        └── Real SQL Server Adapter    (DATABASE_URL=mssql+pyodbc://...)
```

To move from the demo to a real e-Stock database, you would:
1. Change `DATABASE_URL` in `.env` to point at the real SQL Server / e-Stock
   database (or a read replica / reporting database — recommended for
   safety).
2. If e-Stock's schema differs from `database/models.py`, either adjust the
   models to match e-Stock's tables, or create SQL views in e-Stock's
   database that project its schema into the shape StockVision expects
   (the "adapter" approach — keeps StockVision's analytics code untouched).
3. Remove `database/seed.py` from the startup flow (it's demo-only).
4. Set `DATA_SOURCE_MODE=estock` in `.env` for clarity/telemetry.

No Flutter code changes are needed — the mobile app only ever talks to the
FastAPI backend over REST, never directly to a database.

## Why not connect Flutter directly to SQL Server?

Two reasons, both non-negotiable in a real deployment:
- **Security**: database credentials must never be shipped inside a mobile
  app binary. The backend is the only thing that holds credentials.
- **Business logic reuse**: analytics, alerts, and forecasting logic lives
  once, on the server, so web dashboards, other mobile platforms, or
  integrations can reuse the same intelligence layer.

```
e-Stock  →  SQL Server  →  Secure Connector / StockVision Backend  →  Flutter
```

## AI Business Assistant design

The "Ask your business" assistant is **not** a raw LLM-to-SQL pipeline. It
is a deterministic, safe query engine:

1. **Intent detection** — regex/keyword matching against the question
   (`services/assistant_service.py::detect_intent`).
2. **Entity extraction** — branch names and time periods mentioned in the
   question are extracted with simple pattern matching.
3. **Mapped to a predefined analytics query** — each intent maps to a
   specific, parameterized function in `analytics_service.py` or
   `forecasting_service.py`. No user input is ever concatenated into SQL.
4. **Execution** against real data.
5. **Natural-language composition** of the answer from the real numbers
   returned by step 4.

This keeps the assistant fast, free (no external LLM API costs), safe (no
arbitrary SQL execution), and fully explainable.

## Forecasting & anomaly detection

- **Demand forecasting** (`forecasting_service.py::forecast_product_demand`)
  fits a `scikit-learn` `LinearRegression` on up to 90 days of daily sales
  per product, then projects 7/30-day demand. Falls back to a simple
  average when there isn't enough history.
- **Anomaly detection** (`detect_anomalies`) computes a z-score of each
  branch's most recent day of sales against its trailing 30-day mean/std,
  flagging spikes or drops beyond a threshold.
- **Recommendations** (`generate_recommendations`) is rule-based: it looks
  for products trending toward stockout, branches that are short on a
  product while another branch has surplus of the same product (transfer
  suggestions), and slow-moving overstocked items (purchasing-reduction
  suggestions).

## Alert engine

`services/alert_service.py` recomputes alerts from live data every time
`/alerts` or `/dashboard/overview` is called: low/critical stock, stockout
risk (from sales velocity), branch sales drops/spikes (week-over-week),
expiring inventory, overstock, and pending transfers. New alerts are
persisted as `Notification` rows; duplicate alerts (same title within 12
hours) are suppressed so the notification center doesn't spam the user.

## Mobile app architecture

```
lib/
├── core/         API client (Dio + auth interceptor), local storage, constants
├── models/       Plain Dart data classes (User, Branch, Alert, Product, InventoryItem)
├── services/     One class per backend resource — the ONLY place that calls the API
├── providers/    Riverpod StateNotifiers/FutureProviders — app state
├── screens/      One file per screen — UI only, no direct HTTP calls
├── widgets/      Shared, reusable UI components (KPI cards, charts, chips, skeletons)
└── theme/        Colors and ThemeData (light + dark)
```

Screens never call `Dio`/HTTP directly — they read from `providers/`, which
call `services/`, which call `core/api_client.dart`. This keeps loading/
error/empty states consistent everywhere and makes the app trivial to
extend (add a new screen by adding a service method + a provider + a
screen).

## Role-based access control

Enforced on **both** the backend and the UI:
- **Backend**: `security.py::scoped_branch_ids()` restricts a Branch
  Manager's queries to their own branch at the SQL level — they cannot see
  another branch's data even if they inspect the API directly.
- **Mobile app**: `AppUser` (models/user.dart) exposes role-based getters
  (`canSeeAllBranches`, `canApproveTransfers`, `canSeeFinancials`,
  `canSeeActivityAudit`) used to hide navigation entries and actions the
  current role shouldn't see.
