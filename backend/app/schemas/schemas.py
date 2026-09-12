"""
Pydantic schemas for request/response validation.
Kept in one file for a demo project of this size; split further if it grows.
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr


# ---------- Auth ----------
class LoginRequest(BaseModel):
    email: str
    password: str


class UserOut(BaseModel):
    id: int
    name: str
    email: str
    role: str
    branch_id: Optional[int] = None
    company_id: int

    class Config:
        from_attributes = True


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


# ---------- Branches ----------
class BranchOut(BaseModel):
    id: int
    name: str
    code: str
    type: str
    address: Optional[str] = None
    manager_name: Optional[str] = None
    status: str

    class Config:
        from_attributes = True


class BranchPerformanceOut(BaseModel):
    id: int
    name: str
    code: str
    type: str
    status: str
    sales: float
    profit: float
    orders: int
    growth_pct: float
    inventory_value: float
    low_stock_count: int


# ---------- Products ----------
class ProductOut(BaseModel):
    id: int
    sku: str
    barcode: Optional[str] = None
    name: str
    category: str
    purchase_price: float
    selling_price: float
    minimum_stock: int
    reorder_level: int
    status: str

    class Config:
        from_attributes = True


# ---------- Alerts ----------
class AlertOut(BaseModel):
    id: int
    type: str
    title: str
    message: str
    severity: str
    is_read: bool
    related_entity_type: Optional[str] = None
    related_entity_id: Optional[int] = None
    recommended_action: Optional[str] = None
    branch_id: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True


# ---------- Activity ----------
class ActivityOut(BaseModel):
    id: int
    action: str
    entity_type: Optional[str] = None
    description: str
    branch_id: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True


# ---------- Transfers ----------
class TransferItemIn(BaseModel):
    product_id: int
    quantity: int


class TransferCreate(BaseModel):
    from_branch_id: int
    to_branch_id: int
    items: List[TransferItemIn]


class TransferOut(BaseModel):
    id: int
    from_branch_id: int
    to_branch_id: int
    status: str
    created_at: datetime
    completed_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ---------- Assistant ----------
class AssistantQuery(BaseModel):
    question: str


class AssistantResponse(BaseModel):
    answer: str
    intent: str
    data: Optional[dict] = None
