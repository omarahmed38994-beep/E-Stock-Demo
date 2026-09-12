import io
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
import pandas as pd

from app.database.connection import get_db
from app.database.models import User
from app.security import get_current_user, scoped_branch_ids
from app.services.analytics_service import _sale_items_df

router = APIRouter(prefix="/export", tags=["Export"])


@router.get("/sales-csv")
def export_sales_csv(period_days: int = 30, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    branch_ids = scoped_branch_ids(user, db)
    end = datetime.utcnow()
    start = end - timedelta(days=period_days)
    df = _sale_items_df(db, start, end, branch_ids)
    if df.empty:
        df = pd.DataFrame(columns=["sale_id", "product_name", "quantity", "unit_price", "total", "created_at"])
    else:
        df = df[["sale_id", "product_name", "quantity", "unit_price", "total", "created_at"]]

    stream = io.StringIO()
    df.to_csv(stream, index=False)
    stream.seek(0)
    return StreamingResponse(
        iter([stream.getvalue()]), media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=sales_export_{period_days}d.csv"},
    )
