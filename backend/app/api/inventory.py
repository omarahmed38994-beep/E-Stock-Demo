from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.database.models import User
from app.security import get_current_user, scoped_branch_ids
from app.services import analytics_service as an

router = APIRouter(prefix="/inventory", tags=["Inventory"])


@router.get("")
def inventory_overview(
    branch_id: Optional[int] = None, category_id: Optional[int] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db), user: User = Depends(get_current_user),
):
    scoped = scoped_branch_ids(user, db)
    branch_ids = [branch_id] if branch_id else scoped
    intel = an.inventory_intelligence(db, branch_ids)
    items = intel["items"]
    if status:
        items = [i for i in items if i["status"].lower().replace(" ", "_") == status.lower().replace(" ", "_")]
    return {"summary": intel["summary"], "items": items[:200]}


@router.get("/low-stock")
def low_stock(branch_id: Optional[int] = None, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    scoped = scoped_branch_ids(user, db)
    branch_ids = [branch_id] if branch_id else scoped
    intel = an.inventory_intelligence(db, branch_ids)
    return [i for i in intel["items"] if i["status"] in ("Low Stock", "Critical")]


@router.get("/expiring")
def expiring(branch_id: Optional[int] = None, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    scoped = scoped_branch_ids(user, db)
    branch_ids = [branch_id] if branch_id else scoped
    intel = an.inventory_intelligence(db, branch_ids)
    return [i for i in intel["items"] if i["status"] == "Expiring"]


@router.get("/overstock")
def overstock(branch_id: Optional[int] = None, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    scoped = scoped_branch_ids(user, db)
    branch_ids = [branch_id] if branch_id else scoped
    intel = an.inventory_intelligence(db, branch_ids)
    return [i for i in intel["items"] if i["status"] == "Overstock"]
