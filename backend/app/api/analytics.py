from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.database.models import User
from app.security import get_current_user, scoped_branch_ids
from app.services import analytics_service as an

router = APIRouter(prefix="/analytics", tags=["Analytics"])

PERIOD_MAP = {
    "today": timedelta(days=1), "7d": timedelta(days=7), "30d": timedelta(days=30),
    "90d": timedelta(days=90), "12m": timedelta(days=365),
}


def _period(period: str, start: Optional[str], end: Optional[str]):
    if start and end:
        return datetime.fromisoformat(start), datetime.fromisoformat(end)
    now = datetime.utcnow()
    return now - PERIOD_MAP.get(period, timedelta(days=30)), now


@router.get("/sales")
def sales_analytics(
    period: str = "30d", branch_id: Optional[int] = None, category_id: Optional[int] = None,
    product_id: Optional[int] = None, start: Optional[str] = None, end: Optional[str] = None,
    db: Session = Depends(get_db), user: User = Depends(get_current_user),
):
    scoped = scoped_branch_ids(user, db)
    branch_ids = [branch_id] if branch_id else scoped
    s, e = _period(period, start, end)
    return an.sales_analytics(db, s, e, branch_ids, category_id, product_id)


@router.get("/profit")
def profit_analytics(
    period: str = "30d", branch_id: Optional[int] = None,
    start: Optional[str] = None, end: Optional[str] = None,
    db: Session = Depends(get_db), user: User = Depends(get_current_user),
):
    scoped = scoped_branch_ids(user, db)
    branch_ids = [branch_id] if branch_id else scoped
    s, e = _period(period, start, end)
    return an.profit_analytics(db, s, e, branch_ids)


@router.get("/branches")
def branches_analytics(
    period: str = "30d", start: Optional[str] = None, end: Optional[str] = None,
    db: Session = Depends(get_db), user: User = Depends(get_current_user),
):
    s, e = _period(period, start, end)
    return an.branch_performance(db, s, e, scoped_branch_ids(user, db))


@router.get("/products")
def products_analytics(
    period: str = "30d", branch_id: Optional[int] = None,
    start: Optional[str] = None, end: Optional[str] = None,
    db: Session = Depends(get_db), user: User = Depends(get_current_user),
):
    scoped = scoped_branch_ids(user, db)
    branch_ids = [branch_id] if branch_id else scoped
    s, e = _period(period, start, end)
    result = an.sales_analytics(db, s, e, branch_ids)
    return {"best_selling": result["best_selling"], "worst_selling": result["worst_selling"]}
