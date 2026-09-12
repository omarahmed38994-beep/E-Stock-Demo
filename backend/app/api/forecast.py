from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.database.models import User
from app.security import get_current_user
from app.services.forecasting_service import forecast_product_demand, detect_anomalies, generate_recommendations

router = APIRouter(tags=["Forecasting & Recommendations"])


@router.get("/forecast/{product_id}")
def forecast(product_id: int, days: int = 7, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return forecast_product_demand(db, product_id, days_ahead=days)


@router.get("/anomalies")
def anomalies(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return detect_anomalies(db)


@router.get("/recommendations")
def recommendations(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return generate_recommendations(db)
