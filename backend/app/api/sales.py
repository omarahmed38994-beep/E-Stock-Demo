from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.database.models import User
from app.security import get_current_user, scoped_branch_ids
from app.services import analytics_service as an

router = APIRouter(prefix="/sales", tags=["Sales"])


def _resolve_period(period: str, start: Optional[str], end: Optional[str]):
    now = datetime.utcnow()
    if start and end:
        return datetime.fromisoformat(start), datetime.fromisoformat(end)
    mapping = {
        "today": timedelta(days=1), "7d": timedelta(days=7), "30d": timedelta(days=30),
        "90d": timedelta(days=90), "12m": timedelta(days=365),
    }
    delta = mapping.get(period, timedelta(days=30))
    return now - delta, now


@router.get("")
def list_sales(
    branch_id: Optional[int] = None, page: int = 1, page_size: int = 25,
    db: Session = Depends(get_db), user: User = Depends(get_current_user),
):
    scoped = scoped_branch_ids(user, db)
    q = "SELECT id, branch_id, invoice_number, total_amount, profit, payment_method, created_at FROM sales WHERE 1=1"
    params = {}
    if branch_id:
        q += " AND branch_id = :bid"
        params["bid"] = branch_id
    elif scoped:
        q += " AND branch_id IN (" + ",".join(map(str, scoped)) + ")"
    q += " ORDER BY created_at DESC LIMIT :limit OFFSET :offset"
    params["limit"] = page_size
    params["offset"] = (page - 1) * page_size
    rows = db.execute(text(q), params).fetchall()
    return {
        "page": page, "page_size": page_size,
        "items": [{"id": r[0], "branch_id": r[1], "invoice_number": r[2], "total_amount": r[3],
                    "profit": r[4], "payment_method": r[5], "created_at": r[6]} for r in rows],
    }


@router.get("/summary")
def sales_summary(
    period: str = "30d", branch_id: Optional[int] = None,
    db: Session = Depends(get_db), user: User = Depends(get_current_user),
):
    scoped = scoped_branch_ids(user, db)
    branch_ids = [branch_id] if branch_id else scoped
    start, end = _resolve_period(period, None, None)
    return an.sales_analytics(db, start, end, branch_ids)
