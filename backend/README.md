# StockVision Backend

FastAPI backend for the StockVision demo. See the top-level
[`README.md`](../README.md) for the full product overview and
[`docs/api.md`](../docs/api.md) for the endpoint reference.

## Quick start

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python -m app.database.seed      # generates data/stockvision.db
python -m uvicorn app.main:app --reload
```

Visit `http://127.0.0.1:8000/docs` for interactive Swagger docs.

## Project layout

```
backend/
├── app/
│   ├── main.py           FastAPI app, middleware, error handlers, router registration
│   ├── config.py         Centralized settings (pydantic-settings, reads .env)
│   ├── security.py       Password hashing, JWT, role-based access dependencies
│   ├── database/
│   │   ├── connection.py Engine/session — the only place a DB connection is opened
│   │   ├── models.py     SQLAlchemy ORM models (full schema)
│   │   └── seed.py       Demo data generator (run this before first launch)
│   ├── api/               One router module per resource (thin — no business logic)
│   ├── services/          All business logic: analytics, alerts, forecasting, assistant
│   └── schemas/           Pydantic request/response schemas
└── tests/
    └── test_api.py        End-to-end API tests (pytest)
```

## Re-seeding the database

The seeder is destructive by design (drops and recreates all tables) so the
demo story stays consistent:

```bash
python -m app.database.seed
```

## Running tests

```bash
pytest tests/test_api.py -v
```

Tests assume the database has already been seeded and hit the app directly
via `fastapi.testclient.TestClient` (no separate server process needed).

## Switching to a real database

Change `DATABASE_URL` in `.env`, e.g.:

```
DATABASE_URL=mssql+pyodbc://user:pass@host/db?driver=ODBC+Driver+17+for+SQL+Server
DATABASE_URL=postgresql+psycopg2://user:pass@host:5432/dbname
DATABASE_URL=mysql+pymysql://user:pass@host:3306/dbname
```

No other code changes are required for read-oriented analytics — see
[`docs/architecture.md`](../docs/architecture.md) for the full migration
plan when moving to a real e-Stock database.
