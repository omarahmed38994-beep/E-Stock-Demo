from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.database.models import User, Branch
from app.security import get_current_user, scoped_branch_ids
from app.services import analytics_service as an

router = APIRouter(prefix="/branches", tags=["Branches"])


@router.get("")
def list_branches(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    branch_ids = scoped_branch_ids(user, db)
    start = datetime.utcnow() - timedelta(days=30)
    end = datetime.utcnow()
    return an.branch_performance(db, start, end, branch_ids)


@router.get("/compare")
def compare_branches(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    start = datetime.utcnow() - timedelta(days=30)
    end = datetime.utcnow()
    perf = an.branch_performance(db, start, end, None)
    avg_sales = sum(b["sales"] for b in perf) / len(perf) if perf else 0
    for b in perf:
        b["vs_company_average_pct"] = round(((b["sales"] - avg_sales) / avg_sales * 100), 1) if avg_sales else 0
    return {"company_average_sales": round(avg_sales, 2), "branches": perf}


@router.get("/{branch_id}")
def branch_detail(branch_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    scoped = scoped_branch_ids(user, db)
    if scoped and branch_id not in scoped:
        raise HTTPException(status_code=403, detail="You do not have access to this branch")

    branch = db.query(Branch).filter(Branch.id == branch_id).first()
    if not branch:
        raise HTTPException(status_code=404, detail="Branch not found")

    now = datetime.utcnow()
    daily_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    month_start = now - timedelta(days=30)

    daily_sales = an.sales_analytics(db, daily_start, now, [branch_id])
    monthly = an.sales_analytics(db, month_start, now, [branch_id])
    profit = an.profit_analytics(db, month_start, now, [branch_id])
    intel = an.inventory_intelligence(db, [branch_id])

    recent_activity = db.execute(text("""
        SELECT action, description, created_at FROM activity_logs
        WHERE branch_id = :bid ORDER BY created_at DESC LIMIT 10
    """), {"bid": branch_id}).fetchall()

    recent_sales = db.execute(text("""
        SELECT invoice_number, total_amount, profit, payment_method, created_at
        FROM sales WHERE branch_id = :bid ORDER BY created_at DESC LIMIT 10
    """), {"bid": branch_id}).fetchall()

    comparison = an.branch_performance(db, month_start, now, None)
    avg_sales = sum(b["sales"] for b in comparison) / len(comparison) if comparison else 0

    return {
        "branch": {"id": branch.id, "name": branch.name, "code": branch.code, "type": branch.type,
                    "address": branch.address, "manager_name": branch.manager_name, "status": branch.status},
        "daily_sales": daily_sales,
        "monthly_sales": monthly,
        "profit": profit,
        "inventory": intel["summary"],
        "low_stock_products": [i for i in intel["items"] if i["status"] in ("Low Stock", "Critical")][:10],
        "top_products": monthly["best_selling"][:5],
        "recent_activity": [{"action": r[0], "description": r[1], "timestamp": r[2]} for r in recent_activity],
        "recent_transactions": [{"invoice": r[0], "amount": r[1], "profit": r[2], "payment_method": r[3], "timestamp": r[4]} for r in recent_sales],
        "vs_company_average_pct": round(((monthly["revenue"] - avg_sales) / avg_sales * 100), 1) if avg_sales else 0,
    }
