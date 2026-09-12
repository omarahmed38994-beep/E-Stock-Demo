"""
StockVision relational data model.

These models represent the demo SQLite schema. In a real e-Stock/SQL Server
deployment, an equivalent set of tables (or views mapped onto e-Stock's own
schema) would back these same models, which is why field names are kept
generic and business-oriented rather than SQLite-specific.
"""
from datetime import datetime
from sqlalchemy import (
    Column, Integer, String, Float, Boolean, ForeignKey, DateTime, Text
)
from sqlalchemy.orm import relationship
from app.database.connection import Base


class Company(Base):
    __tablename__ = "companies"
    id = Column(Integer, primary_key=True)
    name = Column(String(200), nullable=False)
    industry = Column(String(100))
    phone = Column(String(50))
    address = Column(String(300))
    created_at = Column(DateTime, default=datetime.utcnow)

    branches = relationship("Branch", back_populates="company")
    users = relationship("User", back_populates="company")
    products = relationship("Product", back_populates="company")


class Branch(Base):
    __tablename__ = "branches"
    id = Column(Integer, primary_key=True)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False)
    name = Column(String(150), nullable=False)
    code = Column(String(20), unique=True, nullable=False)
    type = Column(String(20), default="Branch")  # Main | Branch
    address = Column(String(300))
    manager_name = Column(String(150))
    status = Column(String(20), default="Active")
    created_at = Column(DateTime, default=datetime.utcnow)

    company = relationship("Company", back_populates="branches")
    inventory = relationship("Inventory", back_populates="branch")


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False)
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True)
    name = Column(String(150), nullable=False)
    email = Column(String(150), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False)
    status = Column(String(20), default="Active")
    last_login = Column(DateTime, nullable=True)

    company = relationship("Company", back_populates="users")
    branch = relationship("Branch")


class Category(Base):
    __tablename__ = "categories"
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False, unique=True)


class Product(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key=True)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    sku = Column(String(50), unique=True, nullable=False)
    barcode = Column(String(50))
    name = Column(String(200), nullable=False)
    description = Column(Text)
    purchase_price = Column(Float, nullable=False)
    selling_price = Column(Float, nullable=False)
    minimum_stock = Column(Integer, default=10)
    reorder_level = Column(Integer, default=20)
    status = Column(String(20), default="Active")
    expiry_tracking = Column(Boolean, default=False)

    company = relationship("Company", back_populates="products")
    category = relationship("Category")


class Inventory(Base):
    __tablename__ = "inventory"
    id = Column(Integer, primary_key=True)
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity = Column(Integer, default=0)
    reserved_quantity = Column(Integer, default=0)
    expiry_date = Column(DateTime, nullable=True)
    last_updated = Column(DateTime, default=datetime.utcnow)

    branch = relationship("Branch", back_populates="inventory")
    product = relationship("Product")


class Customer(Base):
    __tablename__ = "customers"
    id = Column(Integer, primary_key=True)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False)
    name = Column(String(150), nullable=False)
    phone = Column(String(50))
    email = Column(String(150))
    type = Column(String(20), default="Retail")  # Retail | Wholesale


class Supplier(Base):
    __tablename__ = "suppliers"
    id = Column(Integer, primary_key=True)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False)
    name = Column(String(150), nullable=False)
    phone = Column(String(50))
    email = Column(String(150))


class Sale(Base):
    __tablename__ = "sales"
    id = Column(Integer, primary_key=True)
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=False)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=True)
    invoice_number = Column(String(50), unique=True, nullable=False)
    total_amount = Column(Float, default=0)
    total_cost = Column(Float, default=0)
    profit = Column(Float, default=0)
    payment_method = Column(String(30), default="Cash")
    created_at = Column(DateTime, default=datetime.utcnow)

    branch = relationship("Branch")
    customer = relationship("Customer")
    items = relationship("SaleItem", back_populates="sale")


class SaleItem(Base):
    __tablename__ = "sale_items"
    id = Column(Integer, primary_key=True)
    sale_id = Column(Integer, ForeignKey("sales.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity = Column(Integer, nullable=False)
    unit_price = Column(Float, nullable=False)
    unit_cost = Column(Float, nullable=False)
    total = Column(Float, nullable=False)

    sale = relationship("Sale", back_populates="items")
    product = relationship("Product")


class Purchase(Base):
    __tablename__ = "purchases"
    id = Column(Integer, primary_key=True)
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=False)
    supplier_id = Column(Integer, ForeignKey("suppliers.id"), nullable=False)
    invoice_number = Column(String(50), unique=True, nullable=False)
    total_amount = Column(Float, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

    branch = relationship("Branch")
    supplier = relationship("Supplier")
    items = relationship("PurchaseItem", back_populates="purchase")


class PurchaseItem(Base):
    __tablename__ = "purchase_items"
    id = Column(Integer, primary_key=True)
    purchase_id = Column(Integer, ForeignKey("purchases.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity = Column(Integer, nullable=False)
    unit_cost = Column(Float, nullable=False)
    total = Column(Float, nullable=False)

    purchase = relationship("Purchase", back_populates="items")
    product = relationship("Product")


class Transfer(Base):
    __tablename__ = "transfers"
    id = Column(Integer, primary_key=True)
    from_branch_id = Column(Integer, ForeignKey("branches.id"), nullable=False)
    to_branch_id = Column(Integer, ForeignKey("branches.id"), nullable=False)
    status = Column(String(20), default="Pending")  # Pending | Approved | Rejected | Completed
    requested_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    approved_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    completed_at = Column(DateTime, nullable=True)

    from_branch = relationship("Branch", foreign_keys=[from_branch_id])
    to_branch = relationship("Branch", foreign_keys=[to_branch_id])
    items = relationship("TransferItem", back_populates="transfer")


class TransferItem(Base):
    __tablename__ = "transfer_items"
    id = Column(Integer, primary_key=True)
    transfer_id = Column(Integer, ForeignKey("transfers.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity = Column(Integer, nullable=False)

    transfer = relationship("Transfer", back_populates="items")
    product = relationship("Product")


class Notification(Base):
    __tablename__ = "notifications"
    id = Column(Integer, primary_key=True)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False)
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True)
    type = Column(String(40), nullable=False)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    severity = Column(String(20), default="info")  # critical | warning | info
    related_entity_type = Column(String(40), nullable=True)
    related_entity_id = Column(Integer, nullable=True)
    recommended_action = Column(String(300), nullable=True)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class ActivityLog(Base):
    __tablename__ = "activity_logs"
    id = Column(Integer, primary_key=True)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True)
    action = Column(String(100), nullable=False)
    entity_type = Column(String(50), nullable=True)
    entity_id = Column(Integer, nullable=True)
    description = Column(String(300), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class DailyMetric(Base):
    """Pre-aggregated per-branch daily metrics for fast dashboard loading."""
    __tablename__ = "daily_metrics"
    id = Column(Integer, primary_key=True)
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=False)
    date = Column(DateTime, nullable=False)
    total_sales = Column(Float, default=0)
    total_profit = Column(Float, default=0)
    orders_count = Column(Integer, default=0)
