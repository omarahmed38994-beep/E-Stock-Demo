# StockVision — API Reference

Base URL (local demo): `http://127.0.0.1:8000`
Interactive Swagger UI: `http://127.0.0.1:8000/docs`
OpenAPI schema: `http://127.0.0.1:8000/openapi.json`

All endpoints except `/`, `/health`, and `/auth/login` require a bearer
token:

```
Authorization: Bearer <access_token>
```

## Authentication

### `POST /auth/login`
Request:
```json
{ "email": "owner@stockvision.demo", "password": "demo123" }
```
Response:
```json
{
  "access_token": "eyJ...",
  "token_type": "bearer",
  "user": { "id": 1, "name": "Omar Hassan (Owner)", "email": "owner@stockvision.demo", "role": "Owner", "branch_id": null, "company_id": 1 }
}
```

### `GET /auth/me`
Returns the currently authenticated user.

## Dashboard

- `GET /dashboard/overview` — today's sales/profit/orders, 30-day trends, branch performance snapshot, and the **Attention Required** list.
- `GET /dashboard/business-overview` — company-wide executive summary (revenue, profit, margin, best/worst branch & product).

## Branches

- `GET /branches` — performance summary for every branch the current user can see (role-scoped).
- `GET /branches/compare` — all branches vs. company average, for the comparison screen.
- `GET /branches/{id}` — full branch detail: daily/monthly sales, profit, inventory, low-stock products, top products, recent activity, recent transactions.

## Products

- `GET /products?search=&category_id=&status=&page=&page_size=` — paginated product list.
- `GET /products/{id}` — full detail: pricing, branch stock distribution, 90-day sales trend, sales velocity, stockout estimate, and a live demand forecast.

## Sales

- `GET /sales?branch_id=&page=&page_size=` — raw sales list.
- `GET /sales/summary?period=&branch_id=` — aggregated summary (`period` one of `today`, `7d`, `30d`, `90d`, `12m`).

## Inventory

- `GET /inventory?branch_id=&category_id=&status=` — full inventory intelligence (every branch/product row classified as Healthy / Low Stock / Critical / Overstock / Expiring / Fast Moving / Slow Moving / Dead Stock).
- `GET /inventory/low-stock`
- `GET /inventory/expiring`
- `GET /inventory/overstock`

## Purchases

- `GET /purchases?branch_id=&page=&page_size=` — purchase order history.

## Analytics

- `GET /analytics/sales?period=&branch_id=&category_id=&product_id=`
- `GET /analytics/profit?period=&branch_id=`
- `GET /analytics/branches?period=`
- `GET /analytics/products?period=&branch_id=`

`period` accepts `today`, `7d`, `30d`, `90d`, `12m`, or pass explicit
`start`/`end` ISO-8601 timestamps.

## Alerts

- `GET /alerts?severity=&is_read=` — recomputes and returns current alerts (critical/warning/info).
- `PATCH /alerts/{id}/read` — mark an alert as read.

## Activity

- `GET /activity?branch_id=&user_id=&entity_type=&date=&page=` — audit trail / activity timeline.

## Transfers

- `GET /transfers?status=` — list transfers (Pending/Completed/Rejected).
- `POST /transfers` — create a transfer request.
  ```json
  { "from_branch_id": 1, "to_branch_id": 4, "items": [{"product_id": 12, "quantity": 40}] }
  ```
- `PATCH /transfers/{id}/approve` — approves and simulates stock movement between branches (updates inventory, logs activity, creates a notification).
- `PATCH /transfers/{id}/reject`

## AI Assistant

- `POST /assistant/query`
  ```json
  { "question": "Which branch needs attention?" }
  ```
  Response:
  ```json
  { "answer": "...", "intent": "worst_branch", "data": { ... } }
  ```

## Forecasting & Recommendations

- `GET /forecast/{product_id}?days=7` — ML-based demand forecast for a product.
- `GET /anomalies` — statistically detected sales spikes/drops per branch.
- `GET /recommendations` — generated reorder/transfer/reduce-purchasing recommendations.

## Search

- `GET /search?q=` — global search across products, branches, customers, suppliers.

## Export

- `GET /export/sales-csv?period_days=30` — downloads a CSV of sale line items for the period.

## Error format

All errors return a consistent JSON body and never leak stack traces:
```json
{ "error": true, "detail": "Human-readable message" }
```
Validation errors additionally include an `errors` array with field-level details.
