from fastapi import APIRouter, Depends, Query
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.database.models import User
from app.security import get_current_user

router = APIRouter(prefix="/search", tags=["Search"])


@router.get("")
def global_search(q: str = Query(min_length=1), db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    like = f"%{q}%"
    products = db.execute(text("SELECT id, name, sku FROM products WHERE name LIKE :q OR sku LIKE :q LIMIT 10"),
                           {"q": like}).fetchall()
    branches = db.execute(text("SELECT id, name, code FROM branches WHERE name LIKE :q LIMIT 10"),
                           {"q": like}).fetchall()
    customers = db.execute(text("SELECT id, name, phone FROM customers WHERE name LIKE :q LIMIT 10"),
                            {"q": like}).fetchall()
    suppliers = db.execute(text("SELECT id, name FROM suppliers WHERE name LIKE :q LIMIT 10"),
                            {"q": like}).fetchall()
    return {
        "products": [{"id": r[0], "name": r[1], "sku": r[2]} for r in products],
        "branches": [{"id": r[0], "name": r[1], "code": r[2]} for r in branches],
        "customers": [{"id": r[0], "name": r[1], "phone": r[2]} for r in customers],
        "suppliers": [{"id": r[0], "name": r[1]} for r in suppliers],
    }
