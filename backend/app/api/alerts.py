from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.database.models import User, Notification
from app.security import get_current_user
from app.services.alert_service import generate_alerts
from app.schemas.schemas import AlertOut

router = APIRouter(prefix="/alerts", tags=["Alerts"])


@router.get("", response_model=List[AlertOut])
def list_alerts(
    severity: Optional[str] = None, is_read: Optional[bool] = None,
    db: Session = Depends(get_db), user: User = Depends(get_current_user),
):
    generate_alerts(db, user.company_id)  # refresh with any newly-triggered alerts
    q = db.query(Notification).filter(Notification.company_id == user.company_id)
    if severity:
        q = q.filter(Notification.severity == severity)
    if is_read is not None:
        q = q.filter(Notification.is_read == is_read)
    items = q.order_by(Notification.created_at.desc()).limit(100).all()
    return items


@router.patch("/{alert_id}/read")
def mark_read(alert_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    n = db.query(Notification).filter(Notification.id == alert_id).first()
    if not n:
        raise HTTPException(status_code=404, detail="Alert not found")
    n.is_read = True
    db.commit()
    return {"status": "ok", "id": alert_id}
