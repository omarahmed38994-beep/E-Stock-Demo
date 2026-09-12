from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.database.models import User, Product
from app.security import get_current_user
from app.services import analytics_service as an
from app.services.forecasting_service import forecast_product_demand

router = APIRouter(prefix="/products", tags=["Products"])


@router.get("")
def list_products(
    search: Optional[str] = None,
    category_id: Optional[int] = None,
    status: Optional[str] = None,
    page: int = 1,
    page_size: int = 30,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    q = db.query(Product)
    if search:
        q = q.filter(Product.name.ilike(f"%{search}%"))
    if category_id:
        q = q.filter(Product.category_id == category_id)
    if status:
        q = q.filter(Product.status == status)
    total = q.count()
    items = q.order_by(Product.name).offset((page - 1) * page_size).limit(page_size).all()

    result = []
    for p in items:
        cat_name = db.execute(text("SELECT name FROM categories WHERE id=:cid"), {"cid": p.category_id}).scalar()
        total_stock = db.execute(text("SELECT COALESCE(SUM(quantity),0) FROM inventory WHERE product_id=:pid"),
                                  {"pid": p.id}).scalar()
        result.append({
            "id": p.id, "sku": p.sku, "barcode": p.barcode, "name": p.name, "category": cat_name,
            "purchase_price": p.purchase_price, "selling_price": p.selling_price,
            "profit_per_unit": round(p.selling_price - p.purchase_price, 2),
            "minimum_stock": p.minimum_stock, "reorder_level": p.reorder_level,
            "status": p.status, "total_stock": int(total_stock or 0),
        })
    return {"total": total, "page": page, "page_size": page_size, "items": result}


@router.get("/{product_id}")
def product_detail(product_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    p = db.query(Product).filter(Product.id == product_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Product not found")
    cat_name = db.execute(text("SELECT name FROM categories WHERE id=:cid"), {"cid": p.category_id}).scalar()

    branch_stock = db.execute(text("""
        SELECT b.name, i.quantity FROM inventory i JOIN branches b ON b.id = i.branch_id
        WHERE i.product_id = :pid ORDER BY i.quantity DESC
    """), {"pid": product_id}).fetchall()

    now = datetime.utcnow()
    trend_df_start = now - timedelta(days=90)
    sales_trend = db.execute(text("""
        SELECT date(s.created_at) as d, SUM(si.quantity) as qty, SUM(si.total) as revenue
        FROM sale_items si JOIN sales s ON s.id = si.sale_id
        WHERE si.product_id = :pid AND s.created_at >= :start
        GROUP BY date(s.created_at) ORDER BY d
    """), {"pid": product_id, "start": trend_df_start}).fetchall()

    total_stock = sum(r[1] for r in branch_stock)
    velocity_30 = db.execute(text("""
        SELECT COALESCE(SUM(si.quantity),0) FROM sale_items si JOIN sales s ON s.id=si.sale_id
        WHERE si.product_id = :pid AND s.created_at >= :start
    """), {"pid": product_id, "start": now - timedelta(days=30)}).scalar()
    daily_velocity = round((velocity_30 or 0) / 30, 2)
    stockout_days = round(total_stock / daily_velocity, 1) if daily_velocity > 0 else None

    forecast = forecast_product_demand(db, product_id, days_ahead=7)

    return {
        "id": p.id, "sku": p.sku, "barcode": p.barcode, "name": p.name, "description": p.description,
        "category": cat_name, "selling_price": p.selling_price, "purchase_price": p.purchase_price,
        "profit_per_unit": round(p.selling_price - p.purchase_price, 2),
        "current_stock": int(total_stock), "minimum_stock": p.minimum_stock, "reorder_level": p.reorder_level,
        "branch_distribution": [{"branch": r[0], "quantity": r[1]} for r in branch_stock],
        "sales_trend": [{"date": r[0], "quantity": r[1], "revenue": round(r[2], 2)} for r in sales_trend],
        "sales_velocity_per_day": daily_velocity,
        "estimated_days_until_stockout": stockout_days,
        "forecast": forecast,
    }
