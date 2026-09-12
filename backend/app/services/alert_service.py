"""
Smart Alert Engine.

Alerts are computed live from current data (not just read from the seeded
notifications table). Each call to /alerts recomputes rule-based alerts and
persists any NEW ones as Notification rows (deduplicated by a simple key),
so the notification center stays in sync with the real state of the
business.
"""
from datetime import datetime, timedelta
from typing import Optional
import pandas as pd
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database.models import Notification
from app.services.analytics_service import _sales_df, _sale_items_df, branch_performance


def _upsert_alert(db: Session, company_id: int, branch_id: Optional[int], type_: str, title: str,
                   message: str, severity: str, related_entity_type: str = None,
                   related_entity_id: int = None, recommended_action: str = None):
    """Avoid spamming duplicate alerts: skip if an identical unread alert
    with the same title was created in the last 12 hours."""
    existing = db.query(Notification).filter(
        Notification.title == title,
        Notification.created_at >= datetime.utcnow() - timedelta(hours=12),
    ).first()
    if existing:
        return existing
    n = Notification(
        company_id=company_id, branch_id=branch_id, type=type_, title=title, message=message,
        severity=severity, related_entity_type=related_entity_type, related_entity_id=related_entity_id,
        recommended_action=recommended_action, is_read=False, created_at=datetime.utcnow(),
    )
    db.add(n)
    db.commit()
    return n


def generate_alerts(db: Session, company_id: int = 1) -> list:
    now = datetime.utcnow()
    generated = []

    # --- Low stock / critical stock ---
    rows = db.execute(text("""
        SELECT i.branch_id, b.name as branch_name, p.id as product_id, p.name as product_name,
               i.quantity, p.minimum_stock
        FROM inventory i
        JOIN products p ON p.id = i.product_id
        JOIN branches b ON b.id = i.branch_id
        WHERE i.quantity <= p.minimum_stock
        ORDER BY i.quantity ASC
        LIMIT 25
    """)).fetchall()
    for branch_id, branch_name, product_id, product_name, qty, min_stock in rows:
        if qty <= 0:
            title = f"{product_name} is out of stock — {branch_name}"
            severity = "critical"
            msg = f"{product_name} is out of stock in {branch_name}."
        else:
            title = f"{product_name} is below minimum stock — {branch_name}"
            severity = "warning"
            msg = f"{product_name} is below minimum stock in {branch_name} ({qty} left, minimum {min_stock})."
        generated.append(_upsert_alert(
            db, company_id, branch_id, "low_stock", title, msg, severity,
            "product", product_id, "Reorder or transfer stock from a well-stocked branch.",
        ))

    # --- Sales velocity -> stockout risk (critical stock) ---
    window_start = now - timedelta(days=14)
    items_df = _sale_items_df(db, window_start, now)
    if not items_df.empty:
        vel = items_df.groupby(["branch_id", "product_id"])["quantity"].sum() / 14.0
        inv = pd.read_sql(text("""
            SELECT i.branch_id, i.product_id, i.quantity, p.name, b.name as branch_name
            FROM inventory i JOIN products p ON p.id=i.product_id JOIN branches b ON b.id=i.branch_id
        """), db.bind)
        for _, r in inv.iterrows():
            v = float(vel.get((r["branch_id"], r["product_id"]), 0))
            if v > 0.5 and r["quantity"] > 0:
                days_left = r["quantity"] / v
                if days_left <= 3:
                    generated.append(_upsert_alert(
                        db, company_id, int(r["branch_id"]), "critical_stock",
                        f"{r['name']} may run out in {int(days_left)} days — {r['branch_name']}",
                        f"{r['name']} in {r['branch_name']} is projected to stock out in about {int(days_left)} days at current sales pace.",
                        "critical", "product", int(r["product_id"]),
                        "Reorder now or transfer stock from another branch.",
                    ))

    # --- Sales drop / spike per branch (this week vs last week) ---
    week_start = now - timedelta(days=7)
    prev_week_start = week_start - timedelta(days=7)
    cur = _sales_df(db, week_start, now)
    prev = _sales_df(db, prev_week_start, week_start)
    branches = pd.read_sql(text("SELECT id, name FROM branches"), db.bind)
    for _, b in branches.iterrows():
        cur_sum = float(cur[cur["branch_id"] == b["id"]]["total_amount"].sum()) if not cur.empty else 0
        prev_sum = float(prev[prev["branch_id"] == b["id"]]["total_amount"].sum()) if not prev.empty else 0
        if prev_sum > 0:
            change = (cur_sum - prev_sum) / prev_sum * 100
            if change <= -15:
                generated.append(_upsert_alert(
                    db, company_id, int(b["id"]), "sales_drop",
                    f"Sales drop detected — {b['name']}",
                    f"Sales in {b['name']} decreased {abs(round(change))}% compared with the previous 7 days.",
                    "critical" if change <= -25 else "warning", "branch", int(b["id"]),
                    f"Review {b['name']}'s pricing, staffing, and local promotions.",
                ))
            elif change >= 40:
                generated.append(_upsert_alert(
                    db, company_id, int(b["id"]), "sales_spike",
                    f"Sales spike detected — {b['name']}",
                    f"Sales in {b['name']} increased {round(change)}% compared with the previous 7 days.",
                    "info", "branch", int(b["id"]),
                    "Consider replenishing top sellers to sustain the spike.",
                ))

    # --- Expiring products ---
    expiring = db.execute(text("""
        SELECT COUNT(*), MIN(expiry_date) FROM inventory
        WHERE expiry_date IS NOT NULL AND expiry_date <= :cutoff AND expiry_date >= :now
    """), {"cutoff": now + timedelta(days=30), "now": now}).fetchone()
    if expiring and expiring[0] and expiring[0] > 0:
        generated.append(_upsert_alert(
            db, company_id, None, "expiry",
            "Products approaching expiry",
            f"{expiring[0]} products across branches will expire within 30 days.",
            "warning", "inventory", None,
            "Plan clearance pricing or prioritize distribution of expiring stock.",
        ))

    # --- Overstock ---
    overstock_rows = db.execute(text("""
        SELECT i.branch_id, b.name, p.id, p.name, i.quantity, p.reorder_level
        FROM inventory i JOIN products p ON p.id=i.product_id JOIN branches b ON b.id=i.branch_id
        WHERE i.quantity >= p.reorder_level * 4
        LIMIT 10
    """)).fetchall()
    for branch_id, branch_name, product_id, product_name, qty, reorder in overstock_rows:
        generated.append(_upsert_alert(
            db, company_id, branch_id, "overstock",
            f"{product_name} overstocked — {branch_name}",
            f"{product_name} has significantly higher inventory ({qty} units) than expected demand in {branch_name}.",
            "info", "product", product_id,
            "Consider a promotion or reducing future purchase quantities.",
        ))

    # --- Pending transfers ---
    pending = db.execute(text("SELECT id, from_branch_id, to_branch_id FROM transfers WHERE status='Pending'")).fetchall()
    for tid, from_id, to_id in pending:
        bnames = dict(branches.values)
        generated.append(_upsert_alert(
            db, company_id, to_id, "transfer_required",
            f"Transfer awaiting approval — #{tid}",
            f"A stock transfer from {bnames.get(from_id)} to {bnames.get(to_id)} is pending approval.",
            "warning", "transfer", tid,
            "Review and approve or reject the pending transfer.",
        ))

    return [g for g in generated if g is not None]
