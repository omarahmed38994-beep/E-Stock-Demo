"""
Forecasting & anomaly detection service.

Uses lightweight, fast, explainable models (linear regression on recent
daily sales, and z-score based anomaly detection) rather than a heavy
external ML/LLM API — appropriate for a local demo and fast enough to run
on every request.
"""
from datetime import datetime, timedelta
import numpy as np
import pandas as pd
from sqlalchemy import text
from sqlalchemy.orm import Session
from sklearn.linear_model import LinearRegression


def forecast_product_demand(db: Session, product_id: int, days_ahead: int = 7) -> dict:
    now = datetime.utcnow()
    history_start = now - timedelta(days=90)

    df = pd.read_sql(text("""
        SELECT date(s.created_at) as d, SUM(si.quantity) as qty
        FROM sale_items si JOIN sales s ON s.id = si.sale_id
        WHERE si.product_id = :pid AND s.created_at >= :start
        GROUP BY date(s.created_at)
        ORDER BY d
    """), db.bind, params={"pid": product_id, "start": history_start})

    product = db.execute(text(
        "SELECT name, minimum_stock, reorder_level FROM products WHERE id = :pid"
    ), {"pid": product_id}).mappings().fetchone()
    if product is None:
        return {"error": "Product not found"}

    current_stock = db.execute(text(
        "SELECT COALESCE(SUM(quantity),0) FROM inventory WHERE product_id = :pid"
    ), {"pid": product_id}).scalar() or 0

    if df.empty or len(df) < 5:
        # Not enough history -> fall back to simple average-based estimate
        avg_daily = float(df["qty"].mean()) if not df.empty else 0.0
        forecast_7 = round(avg_daily * 7)
        forecast_30 = round(avg_daily * 30)
        stockout_days = round(current_stock / avg_daily) if avg_daily > 0 else None
        method = "average (insufficient history for regression)"
    else:
        # Build a complete daily series (fill missing days with 0 sales)
        full_range = pd.date_range(df["d"].min(), now.date(), freq="D")
        series = pd.Series(0, index=full_range.date)
        for _, r in df.iterrows():
            series[pd.to_datetime(r["d"]).date()] = r["qty"]

        X = np.arange(len(series)).reshape(-1, 1)
        y = series.values.astype(float)
        model = LinearRegression()
        model.fit(X, y)

        future_idx = np.arange(len(series), len(series) + days_ahead).reshape(-1, 1)
        preds = model.predict(future_idx)
        preds = np.clip(preds, 0, None)
        forecast_days = round(float(preds.sum()))

        future_idx_30 = np.arange(len(series), len(series) + 30).reshape(-1, 1)
        preds_30 = np.clip(model.predict(future_idx_30), 0, None)
        forecast_30 = round(float(preds_30.sum()))

        forecast_7 = forecast_days if days_ahead == 7 else round(float(np.clip(
            model.predict(np.arange(len(series), len(series) + 7).reshape(-1, 1)), 0, None).sum()))

        avg_daily = max(float(np.mean(preds)), 0.01)
        stockout_days = round(current_stock / avg_daily) if avg_daily > 0 else None
        method = "linear regression on 90-day daily sales"

    recommended_reorder = max(0, forecast_30 - current_stock) if forecast_30 else 0

    return {
        "product_id": product_id,
        "product_name": product["name"],
        "current_stock": int(current_stock),
        "forecast_7_day_demand": int(forecast_7),
        "forecast_30_day_demand": int(forecast_30),
        "estimated_stockout_days": stockout_days,
        "recommended_reorder_qty": int(recommended_reorder),
        "method": method,
    }


def detect_anomalies(db: Session, lookback_days: int = 30, z_threshold: float = 2.2) -> list:
    """Detects unusual daily sales spikes/drops per branch using z-scores
    over the trailing window."""
    now = datetime.utcnow()
    start = now - timedelta(days=lookback_days)

    df = pd.read_sql(text("""
        SELECT branch_id, date(created_at) as d, SUM(total_amount) as total
        FROM sales WHERE created_at >= :start
        GROUP BY branch_id, date(created_at)
    """), db.bind, params={"start": start})

    branches = dict(pd.read_sql(text("SELECT id, name FROM branches"), db.bind).values)
    anomalies = []
    if df.empty:
        return anomalies

    for branch_id, g in df.groupby("branch_id"):
        g = g.sort_values("d")
        if len(g) < 7:
            continue
        mean = g["total"].mean()
        std = g["total"].std() or 1
        last_val = g["total"].iloc[-1]
        z = (last_val - mean) / std
        if abs(z) >= z_threshold:
            direction = "spike" if z > 0 else "drop"
            anomalies.append({
                "branch_id": int(branch_id),
                "branch_name": branches.get(branch_id, "Unknown"),
                "date": str(g["d"].iloc[-1]),
                "value": round(float(last_val), 2),
                "average": round(float(mean), 2),
                "z_score": round(float(z), 2),
                "direction": direction,
                "message": f"Unusual sales {direction} detected in {branches.get(branch_id, 'branch')} "
                           f"(EGP {round(last_val):,} vs a {round(mean):,} average).",
            })
    return anomalies


def generate_recommendations(db: Session) -> list:
    """
    Recommendation engine: turns detected conditions (stockout risk,
    imbalance between branches, dead/overstocked items) into concrete
    suggested actions.
    """
    now = datetime.utcnow()
    recs = []

    # 1. Reorder recommendations for products trending toward stockout
    window_start = now - timedelta(days=14)
    vel_df = pd.read_sql(text("""
        SELECT si.product_id, p.name, SUM(si.quantity) as qty
        FROM sale_items si JOIN sales s ON s.id = si.sale_id JOIN products p ON p.id = si.product_id
        WHERE s.created_at >= :start GROUP BY si.product_id
    """), db.bind, params={"start": window_start})
    vel_df["daily_velocity"] = vel_df["qty"] / 14.0

    stock_df = pd.read_sql(text("""
        SELECT product_id, SUM(quantity) as stock FROM inventory GROUP BY product_id
    """), db.bind)
    merged = vel_df.merge(stock_df, on="product_id", how="left").fillna({"stock": 0})
    merged = merged[merged["daily_velocity"] > 0.3]
    merged["days_left"] = merged["stock"] / merged["daily_velocity"]
    urgent = merged[merged["days_left"] <= 5].sort_values("days_left").head(6)
    for _, r in urgent.iterrows():
        recs.append({
            "type": "reorder",
            "priority": "high" if r["days_left"] <= 2 else "medium",
            "title": f"Reorder {r['name']}",
            "description": f"Consider reordering {r['name']} within the next {max(1, int(r['days_left']))} days "
                            f"based on current sales velocity (~{round(r['daily_velocity'],1)} units/day).",
        })

    # 2. Transfer recommendations: branch short on a product while another
    #    branch (often the main warehouse) has surplus of the same product.
    inv_df = pd.read_sql(text("""
        SELECT i.branch_id, b.name as branch_name, i.product_id, p.name as product_name,
               i.quantity, p.minimum_stock, b.type
        FROM inventory i JOIN products p ON p.id = i.product_id JOIN branches b ON b.id = i.branch_id
    """), db.bind)
    short = inv_df[inv_df["quantity"] <= inv_df["minimum_stock"]]
    surplus = inv_df[inv_df["quantity"] >= inv_df["minimum_stock"] * 5]
    count = 0
    for _, s in short.iterrows():
        if count >= 4:
            break
        candidates = surplus[surplus["product_id"] == s["product_id"]]
        candidates = candidates[candidates["branch_id"] != s["branch_id"]]
        if not candidates.empty:
            donor = candidates.sort_values("quantity", ascending=False).iloc[0]
            transfer_qty = min(int(donor["quantity"] * 0.3), 60)
            if transfer_qty < 5:
                continue
            recs.append({
                "type": "transfer",
                "priority": "high",
                "title": f"Transfer {s['product_name']} to {s['branch_name']}",
                "description": f"Transfer {transfer_qty} units of {s['product_name']} from {donor['branch_name']} "
                                f"to {s['branch_name']}, which is running low.",
            })
            count += 1

    # 3. Slow-moving / overstocked reduction recommendations
    slow = inv_df.merge(vel_df[["product_id", "daily_velocity"]], on="product_id", how="left").fillna({"daily_velocity": 0})
    slow = slow[(slow["quantity"] >= slow["minimum_stock"] * 4) & (slow["daily_velocity"] < 0.2)]
    for _, r in slow.drop_duplicates("product_id").head(4).iterrows():
        recs.append({
            "type": "reduce_purchasing",
            "priority": "low",
            "title": f"Slow down purchasing for {r['product_name']}",
            "description": f"{r['product_name']} is slow moving with high stock in {r['branch_name']}. "
                            f"Consider a promotion or reducing future purchase orders.",
        })

    return recs
