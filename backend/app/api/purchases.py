from typing import Optional
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.database.models import User
from app.security import get_current_user, scoped_branch_ids

router = APIRouter(prefix="/purchases", tags=["Purchases"])


@router.get("")
def list_purchases(
    branch_id: Optional[int] = None, page: int = 1, page_size: int = 25,
    db: Session = Depends(get_db), user: User = Depends(get_current_user),
):
    scoped = scoped_branch_ids(user, db)
    q = """SELECT p.id, p.branch_id, b.name, s.name, p.invoice_number, p.total_amount, p.created_at
           FROM purchases p JOIN branches b ON b.id=p.branch_id JOIN suppliers s ON s.id=p.supplier_id
           WHERE 1=1"""
    params = {}
    if branch_id:
        q += " AND p.branch_id = :bid"
        params["bid"] = branch_id
    elif scoped:
        q += " AND p.branch_id IN (" + ",".join(map(str, scoped)) + ")"
    q += " ORDER BY p.created_at DESC LIMIT :limit OFFSET :offset"
    params["limit"] = page_size
    params["offset"] = (page - 1) * page_size
    rows = db.execute(text(q), params).fetchall()
    return {
        "page": page, "page_size": page_size,
        "items": [{"id": r[0], "branch_id": r[1], "branch_name": r[2], "supplier_name": r[3],
                    "invoice_number": r[4], "total_amount": r[5], "created_at": r[6]} for r in rows],
    }
