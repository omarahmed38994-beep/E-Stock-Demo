"""
Analytics service.

All dashboard/branch/inventory/profit numbers are computed here from the
actual database contents (via pandas), never hardcoded. This is the single
place that turns raw transactional rows into business metrics, so the API
layer stays thin and the mobile app never has to compute business logic
itself.
"""
from datetime import datetime, timedelta
from typing import Optional
import pandas as pd
from sqlalchemy import text
from sqlalchemy.orm import Session


def _sales_df(db: Session, start: datetime, end: datetime, branch_ids: Optional[list] = None) -> pd.DataFrame:
    query = """
        SELECT s.id, s.branch_id, s.total_amount, s.total_cost, s.profit,
               s.payment_method, s.created_at
        FROM sales s
        WHERE s.created_at >= :start AND s.created_at < :end
    """
    params = {"start": start, "end": end}
    if branch_ids:
        query += " AND s.branch_id IN :branch_ids"
    df = pd.read_sql(text(query), db.bind, params=params) if not branch_ids else \
        pd.read_sql(text(query.replace(":branch_ids", "(" + ",".join(map(str, branch_ids)) + ")")), db.bind, params=params)
    if not df.empty:
        df["created_at"] = pd.to_datetime(df["created_at"])
    return df


def _sale_items_df(db: Session, start: datetime, end: datetime, branch_ids: Optional[list] = None) -> pd.DataFrame:
    query = """
        SELECT si.id, si.sale_id, si.product_id, si.quantity, si.unit_price,
               si.unit_cost, si.total, s.branch_id, s.created_at,
               p.name as product_name, p.category_id, c.name as category_name
        FROM sale_items si
        JOIN sales s ON s.id = si.sale_id
        JOIN products p ON p.id = si.product_id
        JOIN categories c ON c.id = p.category_id
        WHERE s.created_at >= :start AND s.created_at < :end
    """
    params = {"start": start, "end": end}
    if branch_ids:
        query = query.replace("WHERE s.created_at", "WHERE s.branch_id IN (" + ",".join(map(str, branch_ids)) + ") AND s.created_at")
    df = pd.read_sql(text(query), db.bind, params=params)
    if not df.empty:
        df["created_at"] = pd.to_datetime(df["created_at"])
    return df


def growth_pct(current: float, previous: float) -> float:
    if previous == 0:
        return 100.0 if current > 0 else 0.0
    return round((current - previous) / previous * 100, 1)


def dashboard_overview(db: Session, now: datetime, branch_ids: Optional[list] = None) -> dict:
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = today_start + timedelta(days=1)
    yesterday_start = today_start - timedelta(days=1)

    today_df = _sales_df(db, today_start, today_end, branch_ids)
    yesterday_df = _sales_df(db, yesterday_start, today_start, branch_ids)

    today_sales = float(today_df["total_amount"].sum()) if not today_df.empty else 0.0
    today_profit = float(today_df["profit"].sum()) if not today_df.empty else 0.0
    today_orders = int(len(today_df))
    yesterday_sales = float(yesterday_df["total_amount"].sum()) if not yesterday_df.empty else 0.0

    # Active branches
    bq = "SELECT COUNT(*) FROM branches WHERE status = 'Active'"
    if branch_ids:
        bq += " AND id IN (" + ",".join(map(str, branch_ids)) + ")"
    active_branches = db.execute(text(bq)).scalar()

    low_stock = inventory_status_counts(db, branch_ids)
    expiring = expiring_products_count(db, branch_ids, days=30)
    pending_transfers = db.execute(text(
        "SELECT COUNT(*) FROM transfers WHERE status = 'Pending'"
    )).scalar()
    unread_notifications = db.execute(text(
        "SELECT COUNT(*) FROM notifications WHERE is_read = 0"
    )).scalar()

    # 30-day trend for charts
    trend_start = today_start - timedelta(days=29)
    trend_df = _sales_df(db, trend_start, today_end, branch_ids)
    if not trend_df.empty:
        trend_df["date"] = trend_df["created_at"].dt.date
        daily = trend_df.groupby("date").agg(sales=("total_amount", "sum"), profit=("profit", "sum")).reset_index()
        daily = daily.sort_values("date")
        sales_trend = [{"date": str(r.date), "value": round(r.sales, 2)} for r in daily.itertuples()]
        profit_trend = [{"date": str(r.date), "value": round(r.profit, 2)} for r in daily.itertuples()]
    else:
        sales_trend, profit_trend = [], []

    # Top products (last 30 days)
    items_df = _sale_items_df(db, trend_start, today_end, branch_ids)
    if not items_df.empty:
        top = items_df.groupby("product_name").agg(revenue=("total", "sum"), qty=("quantity", "sum")) \
            .sort_values("revenue", ascending=False).head(5).reset_index()
        top_products = [{"name": r.product_name, "revenue": round(r.revenue, 2), "quantity": int(r.qty)} for r in top.itertuples()]
    else:
        top_products = []

    # Branch performance snapshot
    branch_perf = branch_performance(db, trend_start, today_end, branch_ids)

    return {
        "today_sales": round(today_sales, 2),
        "today_profit": round(today_profit, 2),
        "today_orders": today_orders,
        "sales_growth_vs_yesterday": growth_pct(today_sales, yesterday_sales),
        "active_branches": active_branches,
        "low_stock_items": low_stock["low"] + low_stock["critical"],
        "expiring_soon": expiring,
        "pending_transfers": pending_transfers,
        "unread_notifications": unread_notifications,
        "sales_trend_30d": sales_trend,
        "profit_trend_30d": profit_trend,
        "top_products_30d": top_products,
        "branch_performance": branch_perf,
    }


def business_overview(db: Session, now: datetime) -> dict:
    """Company-wide executive overview (Owner / GM)."""
    period_end = now
    period_start = now - timedelta(days=30)
    prev_start = period_start - timedelta(days=30)

    cur = _sales_df(db, period_start, period_end)
    prev = _sales_df(db, prev_start, period_start)

    total_revenue = float(cur["total_amount"].sum()) if not cur.empty else 0.0
    total_profit = float(cur["profit"].sum()) if not cur.empty else 0.0
    prev_revenue = float(prev["total_amount"].sum()) if not prev.empty else 0.0
    margin = round((total_profit / total_revenue * 100), 1) if total_revenue else 0.0

    perf = branch_performance(db, period_start, period_end, None)
    best_branch = max(perf, key=lambda b: b["sales"]) if perf else None
    worst_branch = min(perf, key=lambda b: b["growth_pct"]) if perf else None

    items_df = _sale_items_df(db, period_start, period_end)
    if not items_df.empty:
        by_product = items_df.groupby("product_name")["total"].sum().sort_values(ascending=False)
        best_product = by_product.index[0]
        slowest_product = by_product.index[-1]
    else:
        best_product = slowest_product = None

    low_stock = inventory_status_counts(db, None)
    expiring = expiring_products_count(db, None, days=30)
    pending_transfers = db.execute(text("SELECT COUNT(*) FROM transfers WHERE status='Pending'")).scalar()

    return {
        "total_revenue": round(total_revenue, 2),
        "total_profit": round(total_profit, 2),
        "profit_margin_pct": margin,
        "sales_growth_pct": growth_pct(total_revenue, prev_revenue),
        "best_branch": best_branch["name"] if best_branch else None,
        "worst_branch": worst_branch["name"] if worst_branch else None,
        "best_product": best_product,
        "slowest_product": slowest_product,
        "low_stock_count": low_stock["low"] + low_stock["critical"],
        "expiring_products": expiring,
        "pending_transfers": pending_transfers,
    }


def branch_performance(db: Session, start: datetime, end: datetime, branch_ids: Optional[list]) -> list:
    prev_len = (end - start).days or 1
    prev_start = start - timedelta(days=prev_len)

    cur = _sales_df(db, start, end, branch_ids)
    prev = _sales_df(db, prev_start, start, branch_ids)

    bq = "SELECT id, name, code, type, status FROM branches"
    if branch_ids:
        bq += " WHERE id IN (" + ",".join(map(str, branch_ids)) + ")"
    branches = pd.read_sql(text(bq), db.bind)

    results = []
    for _, b in branches.iterrows():
        cur_b = cur[cur["branch_id"] == b["id"]] if not cur.empty else cur
        prev_b = prev[prev["branch_id"] == b["id"]] if not prev.empty else prev
        sales = float(cur_b["total_amount"].sum()) if len(cur_b) else 0.0
        profit = float(cur_b["profit"].sum()) if len(cur_b) else 0.0
        orders = int(len(cur_b))
        prev_sales = float(prev_b["total_amount"].sum()) if len(prev_b) else 0.0

        inv_value = db.execute(text(
            "SELECT COALESCE(SUM(i.quantity * p.purchase_price),0) FROM inventory i "
            "JOIN products p ON p.id = i.product_id WHERE i.branch_id = :bid"
        ), {"bid": int(b["id"])}).scalar()
        low_stock_count = db.execute(text(
            "SELECT COUNT(*) FROM inventory i JOIN products p ON p.id = i.product_id "
            "WHERE i.branch_id = :bid AND i.quantity <= p.minimum_stock"
        ), {"bid": int(b["id"])}).scalar()

        results.append({
            "id": int(b["id"]), "name": b["name"], "code": b["code"], "type": b["type"], "status": b["status"],
            "sales": round(sales, 2), "profit": round(profit, 2), "orders": orders,
            "growth_pct": growth_pct(sales, prev_sales),
            "inventory_value": round(float(inv_value or 0), 2),
            "low_stock_count": int(low_stock_count or 0),
        })
    return sorted(results, key=lambda r: r["sales"], reverse=True)


def inventory_status_counts(db: Session, branch_ids: Optional[list]) -> dict:
    where = "1=1"
    if branch_ids:
        where += " AND i.branch_id IN (" + ",".join(map(str, branch_ids)) + ")"
    rows = db.execute(text(f"""
        SELECT i.quantity, p.minimum_stock, p.reorder_level
        FROM inventory i JOIN products p ON p.id = i.product_id
        WHERE {where}
    """)).fetchall()
    counts = {"healthy": 0, "low": 0, "critical": 0, "overstock": 0}
    for qty, min_stock, reorder in rows:
        if qty <= 0:
            counts["critical"] += 1
        elif qty <= min_stock:
            counts["low"] += 1
        elif qty >= reorder * 4:
            counts["overstock"] += 1
        else:
            counts["healthy"] += 1
    return counts


def expiring_products_count(db: Session, branch_ids: Optional[list], days: int = 30) -> int:
    where = "expiry_date IS NOT NULL AND expiry_date <= :cutoff AND expiry_date >= :now"
    if branch_ids:
        where += " AND branch_id IN (" + ",".join(map(str, branch_ids)) + ")"
    cutoff = datetime.utcnow() + timedelta(days=days)
    return db.execute(text(f"SELECT COUNT(*) FROM inventory WHERE {where}"),
                       {"cutoff": cutoff, "now": datetime.utcnow()}).scalar() or 0


def sales_analytics(db: Session, start: datetime, end: datetime, branch_ids: Optional[list],
                     category_id: Optional[int] = None, product_id: Optional[int] = None) -> dict:
    df = _sale_items_df(db, start, end, branch_ids)
    if category_id:
        df = df[df["category_id"] == category_id]
    if product_id:
        df = df[df["product_id"] == product_id]

    if df.empty:
        return {"revenue": 0, "orders": 0, "avg_order_value": 0, "units_sold": 0,
                "best_selling": [], "worst_selling": [], "daily_trend": []}

    revenue = float(df["total"].sum())
    units = int(df["quantity"].sum())
    orders = int(df["sale_id"].nunique())
    aov = round(revenue / orders, 2) if orders else 0

    by_product = df.groupby("product_name").agg(revenue=("total", "sum"), qty=("quantity", "sum")).reset_index()
    best = by_product.sort_values("revenue", ascending=False).head(10)
    worst = by_product.sort_values("revenue", ascending=True).head(10)

    df["date"] = df["created_at"].dt.date
    daily = df.groupby("date")["total"].sum().reset_index().sort_values("date")

    return {
        "revenue": round(revenue, 2),
        "orders": orders,
        "avg_order_value": aov,
        "units_sold": units,
        "best_selling": [{"name": r.product_name, "revenue": round(r.revenue, 2), "qty": int(r.qty)} for r in best.itertuples()],
        "worst_selling": [{"name": r.product_name, "revenue": round(r.revenue, 2), "qty": int(r.qty)} for r in worst.itertuples()],
        "daily_trend": [{"date": str(r.date), "value": round(r.total, 2)} for r in daily.itertuples()],
    }


def profit_analytics(db: Session, start: datetime, end: datetime, branch_ids: Optional[list]) -> dict:
    df = _sale_items_df(db, start, end, branch_ids)
    if df.empty:
        return {"revenue": 0, "cost": 0, "gross_profit": 0, "margin_pct": 0,
                "by_branch": [], "by_category": [], "top_products": [], "lowest_margin_products": []}

    df["cost_total"] = df["unit_cost"] * df["quantity"]
    df["profit"] = df["total"] - df["cost_total"]
    revenue = float(df["total"].sum())
    cost = float(df["cost_total"].sum())
    profit = revenue - cost
    margin = round(profit / revenue * 100, 1) if revenue else 0

    by_branch = df.groupby("branch_id")["profit"].sum().reset_index()
    bmap = dict(pd.read_sql(text("SELECT id, name FROM branches"), db.bind).values)
    by_branch_out = [{"branch": bmap.get(int(r.branch_id), "Unknown"), "profit": round(r.profit, 2)}
                      for r in by_branch.itertuples()]

    by_category = df.groupby("category_name")["profit"].sum().reset_index().sort_values("profit", ascending=False)
    by_category_out = [{"category": r.category_name, "profit": round(r.profit, 2)} for r in by_category.itertuples()]

    by_product = df.groupby("product_name").agg(revenue=("total", "sum"), profit=("profit", "sum")).reset_index()
    by_product["margin_pct"] = (by_product["profit"] / by_product["revenue"] * 100).round(1)
    top_products = by_product.sort_values("profit", ascending=False).head(10)
    lowest_margin = by_product[by_product["revenue"] > 0].sort_values("margin_pct", ascending=True).head(10)

    return {
        "revenue": round(revenue, 2),
        "cost": round(cost, 2),
        "gross_profit": round(profit, 2),
        "margin_pct": margin,
        "by_branch": sorted(by_branch_out, key=lambda x: -x["profit"]),
        "by_category": by_category_out,
        "top_products": [{"name": r.product_name, "profit": round(r.profit, 2), "margin_pct": r.margin_pct} for r in top_products.itertuples()],
        "lowest_margin_products": [{"name": r.product_name, "profit": round(r.profit, 2), "margin_pct": r.margin_pct} for r in lowest_margin.itertuples()],
    }


def inventory_intelligence(db: Session, branch_ids: Optional[list]) -> dict:
    """Classifies every branch/product inventory row using sales velocity."""
    now = datetime.utcnow()
    window_start = now - timedelta(days=30)

    items_df = _sale_items_df(db, window_start, now, branch_ids)
    velocity = items_df.groupby("product_id")["quantity"].sum() / 30.0 if not items_df.empty else pd.Series(dtype=float)

    where = "1=1"
    if branch_ids:
        where += " AND i.branch_id IN (" + ",".join(map(str, branch_ids)) + ")"
    inv = pd.read_sql(text(f"""
        SELECT i.id, i.branch_id, i.product_id, i.quantity, i.expiry_date,
               p.name, p.minimum_stock, p.reorder_level, p.purchase_price, p.selling_price,
               b.name as branch_name
        FROM inventory i
        JOIN products p ON p.id = i.product_id
        JOIN branches b ON b.id = i.branch_id
        WHERE {where}
    """), db.bind)

    classified = []
    for _, r in inv.iterrows():
        v = float(velocity.get(r["product_id"], 0))
        days_left = (r["quantity"] / v) if v > 0 else None
        if r["quantity"] <= 0:
            status = "Critical"
        elif r["quantity"] <= r["minimum_stock"]:
            status = "Low Stock"
        elif r["expiry_date"] and pd.notna(r["expiry_date"]) and pd.Timestamp(r["expiry_date"]) <= pd.Timestamp(now + timedelta(days=30)):
            status = "Expiring"
        elif r["quantity"] >= r["reorder_level"] * 4 and v < 0.3:
            status = "Overstock"
        elif v == 0 and r["quantity"] > 0:
            status = "Dead Stock" if r["quantity"] > r["minimum_stock"] else "Low Stock"
        elif v >= 1.5:
            status = "Fast Moving"
        elif v > 0:
            status = "Slow Moving"
        else:
            status = "Healthy"

        classified.append({
            "inventory_id": int(r["id"]), "branch": r["branch_name"], "product": r["name"],
            "quantity": int(r["quantity"]), "daily_velocity": round(v, 2),
            "days_of_stock_left": round(days_left, 1) if days_left else None,
            "status": status,
            "inventory_value": round(float(r["quantity"] * r["purchase_price"]), 2),
        })

    summary = {
        "total_skus": int(inv["product_id"].nunique()) if not inv.empty else 0,
        "total_units": int(inv["quantity"].sum()) if not inv.empty else 0,
        "inventory_value": round(float((inv["quantity"] * inv["purchase_price"]).sum()), 2) if not inv.empty else 0,
        "low_stock": sum(1 for c in classified if c["status"] in ("Low Stock", "Critical")),
        "overstock": sum(1 for c in classified if c["status"] == "Overstock"),
        "expiring": sum(1 for c in classified if c["status"] == "Expiring"),
        "dead_stock": sum(1 for c in classified if c["status"] == "Dead Stock"),
        "fast_moving": sum(1 for c in classified if c["status"] == "Fast Moving"),
    }
    return {"summary": summary, "items": classified}
