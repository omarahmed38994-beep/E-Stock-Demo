from typing import Optional
from datetime import datetime
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.database.models import User
from app.security import get_current_user, scoped_branch_ids

router = APIRouter(prefix="/activity", tags=["Activity"])


@router.get("")
def list_activity(
    branch_id: Optional[int] = None, user_id: Optional[int] = None,
    entity_type: Optional[str] = None, date: Optional[str] = None,
    page: int = 1, page_size: int = 40,
    db: Session = Depends(get_db), user: User = Depends(get_current_user),
):
    scoped = scoped_branch_ids(user, db)
    q = """SELECT a.id, a.action, a.entity_type, a.entity_id, a.description, a.branch_id,
                  b.name as branch_name, a.created_at
           FROM activity_logs a LEFT JOIN branches b ON b.id = a.branch_id
           WHERE a.company_id = :cid"""
    params = {"cid": user.company_id}
    if branch_id:
        q += " AND a.branch_id = :bid"
        params["bid"] = branch_id
    elif scoped:
        q += " AND a.branch_id IN (" + ",".join(map(str, scoped)) + ")"
    if user_id:
        q += " AND a.user_id = :uid"
        params["uid"] = user_id
    if entity_type:
        q += " AND a.entity_type = :etype"
        params["etype"] = entity_type
    if date:
        q += " AND date(a.created_at) = :d"
        params["d"] = date
    q += " ORDER BY a.created_at DESC LIMIT :limit OFFSET :offset"
    params["limit"] = page_size
    params["offset"] = (page - 1) * page_size
    rows = db.execute(text(q), params).fetchall()
    return {
        "page": page, "page_size": page_size,
        "items": [{"id": r[0], "action": r[1], "entity_type": r[2], "entity_id": r[3],
                    "description": r[4], "branch_id": r[5], "branch_name": r[6], "created_at": r[7]} for r in rows],
    }
