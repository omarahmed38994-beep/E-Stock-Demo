from datetime import datetime
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.database.models import User
from app.security import get_current_user, scoped_branch_ids
from app.services import analytics_service as an
from app.services.alert_service import generate_alerts

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/overview")
def overview(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    branch_ids = scoped_branch_ids(user, db)
    data = an.dashboard_overview(db, datetime.utcnow(), branch_ids)

    # "Attention Required" section — the most important open alerts
    alerts = generate_alerts(db, user.company_id)
    priority_order = {"critical": 0, "warning": 1, "info": 2}
    top_alerts = sorted(alerts, key=lambda a: priority_order.get(a.severity, 3))[:5]
    data["attention_required"] = [
        {"severity": a.severity, "title": a.title, "message": a.message, "recommended_action": a.recommended_action}
        for a in top_alerts
    ]
    return data


@router.get("/business-overview")
def business_overview(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return an.business_overview(db, datetime.utcnow())
