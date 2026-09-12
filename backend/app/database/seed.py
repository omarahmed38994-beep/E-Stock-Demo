"""
StockVision demo data seeder.

Generates a realistic 12-month operating history for a fictional retail
company ("Moda Retail Group") with 7 branches, 300+ products across 10
categories, thousands of sales, purchases, transfers, notifications and
activity logs.

Business patterns are baked in ON PURPOSE so that the analytics/alerts/
forecasting layers built on top of this data have something real to find:
  - fast movers vs slow movers vs dead stock
  - a branch trending up (Mansoura) and a branch trending down (Alexandria)
  - low stock / critical stock / overstock situations
  - products nearing expiry
  - one clear sales anomaly (spike) in the last 2 weeks
  - a pending transfer request

Run with:  python -m app.database.seed   (from backend/)
"""
import random
import sys
from datetime import datetime, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from faker import Faker
from passlib.hash import bcrypt
from sqlalchemy import text

from app.database.connection import Base, engine, SessionLocal
from app.database.models import (
    Company, Branch, User, Category, Product, Inventory, Customer, Supplier,
    Sale, SaleItem, Purchase, PurchaseItem, Transfer, TransferItem,
    Notification, ActivityLog, DailyMetric,
)

fake = Faker()
random.seed(42)
Faker.seed(42)

TODAY = datetime.utcnow().replace(hour=18, minute=0, second=0, microsecond=0)
HISTORY_DAYS = 365  # 12 months of history

CATEGORY_NAMES = [
    "Men's Apparel", "Women's Apparel", "Kids' Wear", "Footwear",
    "Bags & Accessories", "Winter Wear", "Sportswear", "Formal Wear",
    "Undergarments & Basics", "Home Textiles",
]

BRAND_WORDS = [
    "Aegis", "Nile", "Sahara", "Cairene", "Oasis", "Delta", "Marina",
    "Horizon", "Corniche", "Palm", "Meridian", "Lumen", "Atlas", "Verona",
    "Solstice", "Amber", "Cobalt", "Ivory", "Terra", "Nova",
]

PRODUCT_TEMPLATES = {
    "Men's Apparel": ["Slim Fit Shirt", "Cotton Polo", "Chino Trousers", "Denim Jacket", "Crew Neck Sweater", "Linen Shirt", "Cargo Pants", "Bomber Jacket"],
    "Women's Apparel": ["Wrap Dress", "Silk Blouse", "High-Waist Jeans", "Pleated Skirt", "Knit Cardigan", "Maxi Dress", "Tailored Blazer", "Culottes"],
    "Kids' Wear": ["Graphic T-Shirt", "Denim Overalls", "School Uniform Set", "Hooded Jacket", "Jogger Pants", "Printed Dress"],
    "Footwear": ["Running Sneakers", "Leather Loafers", "Ankle Boots", "Canvas Shoes", "Sandals", "Formal Oxfords"],
    "Bags & Accessories": ["Leather Tote", "Crossbody Bag", "Canvas Backpack", "Wool Scarf", "Leather Belt", "Sunglasses"],
    "Winter Wear": ["Puffer Jacket", "Wool Coat", "Fleece Hoodie", "Thermal Base Layer", "Knit Beanie", "Padded Vest"],
    "Sportswear": ["Performance Leggings", "Training Tee", "Track Jacket", "Compression Shorts", "Running Shorts", "Sports Bra"],
    "Formal Wear": ["Tailored Suit Jacket", "Formal Trousers", "Dress Shirt", "Silk Tie", "Waistcoat", "Evening Gown"],
    "Undergarments & Basics": ["Cotton Basic Tee", "Boxer Briefs 3-Pack", "Seamless Bralette", "Thermal Socks 5-Pack", "Undershirt Pack"],
    "Home Textiles": ["Cotton Bedsheet Set", "Bath Towel Set", "Throw Blanket", "Cushion Cover Set", "Table Runner"],
}

BRANCH_DEFS = [
    dict(name="Main Warehouse", code="MW-01", type="Main", city="Damanhour", trend="stable", base_daily_orders=55),
    dict(name="Damanhour Branch", code="DAM-02", type="Branch", city="Damanhour", trend="stable", base_daily_orders=38),
    dict(name="Alexandria Branch", code="ALX-03", type="Branch", city="Alexandria", trend="declining", base_daily_orders=44),
    dict(name="Mansoura Branch", code="MNS-04", type="Branch", city="Mansoura", trend="growing", base_daily_orders=30),
    dict(name="Cairo Branch", code="CAI-05", type="Branch", city="Cairo", trend="stable", base_daily_orders=50),
    dict(name="Tanta Branch", code="TAN-06", type="Branch", city="Tanta", trend="stable", base_daily_orders=26),
    dict(name="Kafr El Sheikh Branch", code="KFS-07", type="Branch", city="Kafr El Sheikh", trend="stable", base_daily_orders=20),
]

PAYMENT_METHODS = ["Cash", "Card", "Mobile Wallet", "Installment"]


def reset_db():
    print("Dropping and recreating all tables...")
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


def seed():
    reset_db()
    db = SessionLocal()

    # ---------------------------------------------------------------
    # Company
    # ---------------------------------------------------------------
    print("Creating company...")
    company = Company(
        name="Moda Retail Group",
        industry="Fashion & Apparel Retail",
        phone="+20 45 123 4567",
        address="12 El Tahrir St, Damanhour, Beheira, Egypt",
        created_at=TODAY - timedelta(days=HISTORY_DAYS + 400),
    )
    db.add(company)
    db.flush()

    # ---------------------------------------------------------------
    # Branches
    # ---------------------------------------------------------------
    print("Creating branches...")
    branches = []
    for b in BRANCH_DEFS:
        branch = Branch(
            company_id=company.id,
            name=b["name"],
            code=b["code"],
            type=b["type"],
            address=f"{fake.street_address()}, {b['city']}, Egypt",
            manager_name=fake.name(),
            status="Active",
            created_at=TODAY - timedelta(days=HISTORY_DAYS + 300),
        )
        branch._trend = b["trend"]
        branch._base_daily_orders = b["base_daily_orders"]
        branches.append(branch)
        db.add(branch)
    db.flush()

    main_branch = branches[0]

    # ---------------------------------------------------------------
    # Users (roles)
    # ---------------------------------------------------------------
    print("Creating users...")
    pw_hash = bcrypt.hash("demo123")
    demo_users = [
        User(company_id=company.id, branch_id=None, name="Omar Hassan (Owner)",
             email="owner@stockvision.demo", password_hash=pw_hash, role="Owner", status="Active"),
        User(company_id=company.id, branch_id=None, name="Laila Mostafa (GM)",
             email="manager@stockvision.demo", password_hash=pw_hash, role="General Manager", status="Active"),
        User(company_id=company.id, branch_id=branches[2].id, name="Karim Adel (Alexandria BM)",
             email="branch@stockvision.demo", password_hash=pw_hash, role="Branch Manager", status="Active"),
        User(company_id=company.id, branch_id=None, name="Nourhan Sami",
             email="inventory@stockvision.demo", password_hash=pw_hash, role="Inventory Manager", status="Active"),
        User(company_id=company.id, branch_id=None, name="Yara Fathy",
             email="accountant@stockvision.demo", password_hash=pw_hash, role="Accountant", status="Active"),
        User(company_id=company.id, branch_id=None, name="Tarek Nabil",
             email="auditor@stockvision.demo", password_hash=pw_hash, role="Auditor", status="Active"),
    ]
    for u in demo_users:
        db.add(u)
    db.flush()

    # A pool of extra staff users used to attribute activity logs realistically
    staff_users = list(demo_users)
    for branch in branches:
        for _ in range(2):
            u = User(
                company_id=company.id, branch_id=branch.id, name=fake.name(),
                email=fake.unique.email(), password_hash=pw_hash,
                role=random.choice(["Branch Manager", "Inventory Manager"]),
                status="Active",
            )
            db.add(u)
            staff_users.append(u)
    db.flush()

    # ---------------------------------------------------------------
    # Categories
    # ---------------------------------------------------------------
    print("Creating categories...")
    categories = {}
    for name in CATEGORY_NAMES:
        c = Category(name=name)
        db.add(c)
        categories[name] = c
    db.flush()

    # ---------------------------------------------------------------
    # Products (300+) with behavior tags used later to drive realistic sales
    # ---------------------------------------------------------------
    print("Creating products...")
    products = []
    used_names = set()
    for cat_name in CATEGORY_NAMES:
        templates = PRODUCT_TEMPLATES[cat_name]
        for i in range(31):  # 10 categories * 31 ~= 310 products
            base = random.choice(templates)
            brand = random.choice(BRAND_WORDS)
            name = f"{brand} {base}"
            suffix = 1
            unique_name = name
            while unique_name in used_names:
                suffix += 1
                unique_name = f"{name} {suffix}"
            used_names.add(unique_name)

            purchase_price = round(random.uniform(60, 900), 2)
            margin = random.uniform(0.35, 0.9)
            selling_price = round(purchase_price * (1 + margin), 2)

            # Behavior tag drives sales velocity later
            roll = random.random()
            if roll < 0.15:
                behavior = "fast"
            elif roll < 0.35:
                behavior = "slow"
            elif roll < 0.42:
                behavior = "dead"
            elif roll < 0.50:
                behavior = "declining"
            elif roll < 0.58:
                behavior = "rising"
            else:
                behavior = "normal"

            expiry_tracking = cat_name in ("Undergarments & Basics", "Home Textiles") and random.random() < 0.3

            p = Product(
                company_id=company.id,
                category_id=categories[cat_name].id,
                sku=f"SKU-{cat_name[:3].upper()}-{1000+i}-{brand[:2].upper()}",
                barcode=fake.ean13(),
                name=unique_name,
                description=f"{unique_name} — {cat_name} collection, premium quality fabric.",
                purchase_price=purchase_price,
                selling_price=selling_price,
                minimum_stock=random.choice([10, 15, 20, 25]),
                reorder_level=random.choice([25, 35, 50]),
                status="Active",
                expiry_tracking=expiry_tracking,
            )
            p._behavior = behavior
            products.append(p)
            db.add(p)
    db.flush()
    print(f"  -> {len(products)} products created")

    # ---------------------------------------------------------------
    # Customers & Suppliers
    # ---------------------------------------------------------------
    print("Creating customers and suppliers...")
    customers = []
    for _ in range(55):
        c = Customer(
            company_id=company.id, name=fake.name(), phone=fake.phone_number(),
            email=fake.unique.email(), type=random.choice(["Retail", "Retail", "Retail", "Wholesale"]),
        )
        customers.append(c)
        db.add(c)

    suppliers = []
    for _ in range(22):
        s = Supplier(
            company_id=company.id, name=f"{fake.company()} Textiles",
            phone=fake.phone_number(), email=fake.unique.company_email(),
        )
        suppliers.append(s)
        db.add(s)
    db.flush()

    # ---------------------------------------------------------------
    # Inventory (per branch/product) — seeded with intentional stock states
    # ---------------------------------------------------------------
    print("Creating inventory...")
    inventory_map = {}  # (branch_id, product_id) -> Inventory
    for branch in branches:
        for p in products:
            # Not every product lives in every branch (main warehouse has all)
            if branch.type != "Main" and random.random() < 0.12:
                continue

            behavior = p._behavior
            if behavior == "dead":
                qty = random.randint(0, 5)
            elif behavior == "slow":
                qty = random.randint(5, 20)
            elif behavior == "fast":
                qty = random.randint(3, 30)  # depleted often by sales
            else:
                qty = random.randint(15, 120)

            # Force some explicit low-stock / overstock scenarios
            r = random.random()
            if r < 0.08:
                qty = random.randint(0, max(1, p.minimum_stock - 2))  # critical/low
            elif r < 0.14:
                qty = p.reorder_level * random.randint(4, 8)  # overstock

            expiry_date = None
            if p.expiry_tracking:
                # Some expiring soon, most not
                if random.random() < 0.35:
                    expiry_date = TODAY + timedelta(days=random.randint(3, 30))
                else:
                    expiry_date = TODAY + timedelta(days=random.randint(60, 400))

            inv = Inventory(
                branch_id=branch.id, product_id=p.id, quantity=qty,
                reserved_quantity=random.randint(0, min(3, qty)),
                expiry_date=expiry_date,
                last_updated=TODAY - timedelta(days=random.randint(0, 5)),
            )
            db.add(inv)
            inventory_map[(branch.id, p.id)] = inv
    db.flush()

    # ---------------------------------------------------------------
    # Historical Sales (12 months) — with branch trend + product behavior
    # ---------------------------------------------------------------
    print("Generating 12 months of sales history (this takes a moment)...")
    invoice_counter = 100000
    sale_rows, sale_item_rows = [], []

    # weekday seasonality: Fri/Sat busier (Egypt weekend), plus a Ramadan-like
    # seasonal bump mid-history and a December bump near the end
    def day_factor(d: datetime, days_ago: int, trend: str):
        weekday_mult = 1.35 if d.weekday() in (4, 5) else 1.0  # Fri=4, Sat=5
        # gentle month-of-year seasonality wave
        seasonal = 1.0 + 0.15 * random.random() * (1 if d.month in (11, 12, 1) else 0)
        if trend == "growing":
            trend_mult = 1.0 + (HISTORY_DAYS - days_ago) / HISTORY_DAYS * 0.55
        elif trend == "declining":
            # was fine 12 months ago, has been sliding down, sharper in last 60 days
            trend_mult = 1.15 - (HISTORY_DAYS - days_ago) / HISTORY_DAYS * 0.45
            if days_ago < 60:
                trend_mult -= 0.18
        else:
            trend_mult = 1.0
        return max(0.25, weekday_mult * seasonal * trend_mult)

    branch_products = {}
    for branch in branches:
        branch_products[branch.id] = [p for p in products if (branch.id, p.id) in inventory_map]

    for days_ago in range(HISTORY_DAYS, -1, -1):
        d = TODAY - timedelta(days=days_ago)
        for branch in branches:
            trend = branch._trend
            factor = day_factor(d, days_ago, trend)
            n_orders = max(1, int(random.gauss(branch._base_daily_orders * factor, branch._base_daily_orders * 0.15)))

            # Sales-spike anomaly: Cairo branch, specific product, last 10 days
            spike_day = days_ago < 10 and branch.name == "Cairo Branch"

            for _ in range(n_orders):
                invoice_counter += 1
                cust = random.choice(customers) if random.random() < 0.7 else None
                avail_products = branch_products[branch.id]
                if not avail_products:
                    continue

                n_items = random.choice([1, 1, 1, 2, 2, 3])
                chosen = []
                weights = []
                for p in random.sample(avail_products, min(len(avail_products), 25)):
                    behavior = p._behavior
                    w = {"fast": 6, "rising": 4, "normal": 2, "slow": 0.6, "declining": 0.8, "dead": 0.05}[behavior]
                    if spike_day and "Sneakers" in p.name:
                        w *= 8  # anomaly driver
                    chosen.append(p)
                    weights.append(w)
                if not chosen:
                    continue
                items = random.choices(chosen, weights=weights, k=min(n_items, len(chosen)))

                sale_time = d.replace(
                    hour=random.randint(9, 21), minute=random.randint(0, 59), second=random.randint(0, 59)
                )
                total_amount = 0.0
                total_cost = 0.0
                item_dicts = []
                for p in set(items):
                    qty = random.randint(1, 3)
                    unit_price = p.selling_price * random.uniform(0.95, 1.0)  # occasional small discount
                    unit_cost = p.purchase_price
                    line_total = round(unit_price * qty, 2)
                    total_amount += line_total
                    total_cost += unit_cost * qty
                    item_dicts.append(dict(product_id=p.id, quantity=qty,
                                            unit_price=round(unit_price, 2),
                                            unit_cost=round(unit_cost, 2),
                                            total=line_total))

                if not item_dicts:
                    continue

                sale = Sale(
                    branch_id=branch.id,
                    customer_id=cust.id if cust else None,
                    invoice_number=f"INV-{invoice_counter}",
                    total_amount=round(total_amount, 2),
                    total_cost=round(total_cost, 2),
                    profit=round(total_amount - total_cost, 2),
                    payment_method=random.choice(PAYMENT_METHODS),
                    created_at=sale_time,
                )
                db.add(sale)
                db.flush()
                for it in item_dicts:
                    db.add(SaleItem(sale_id=sale.id, **it))

        if days_ago % 60 == 0:
            db.commit()
            print(f"  ...{HISTORY_DAYS - days_ago}/{HISTORY_DAYS} days generated")

    db.commit()
    print("  -> sales history complete")

    # ---------------------------------------------------------------
    # Purchases (restocking history, last 6 months)
    # ---------------------------------------------------------------
    print("Generating purchase history...")
    purchase_counter = 500000
    for days_ago in range(180, -1, -7):  # weekly restock cycles
        d = TODAY - timedelta(days=days_ago)
        for branch in branches:
            if random.random() < 0.6:
                continue  # not every branch restocks every week
            supplier = random.choice(suppliers)
            purchase_counter += 1
            n_items = random.randint(3, 10)
            avail_products = branch_products.get(branch.id, products)
            chosen = random.sample(avail_products, min(n_items, len(avail_products)))
            total = 0.0
            item_dicts = []
            for p in chosen:
                qty = random.randint(10, 60)
                unit_cost = round(p.purchase_price * random.uniform(0.95, 1.05), 2)
                line_total = round(unit_cost * qty, 2)
                total += line_total
                item_dicts.append(dict(product_id=p.id, quantity=qty, unit_cost=unit_cost, total=line_total))
            purchase = Purchase(
                branch_id=branch.id, supplier_id=supplier.id,
                invoice_number=f"PO-{purchase_counter}",
                total_amount=round(total, 2),
                created_at=d.replace(hour=random.randint(8, 16)),
            )
            db.add(purchase)
            db.flush()
            for it in item_dicts:
                db.add(PurchaseItem(purchase_id=purchase.id, **it))
    db.commit()
    print("  -> purchase history complete")

    # ---------------------------------------------------------------
    # Transfers (a few completed + one pending "story" transfer)
    # ---------------------------------------------------------------
    print("Generating stock transfers...")
    alexandria = next(b for b in branches if b.name == "Alexandria Branch")
    mansoura = next(b for b in branches if b.name == "Mansoura Branch")

    for i in range(14):
        from_b = main_branch
        to_b = random.choice([b for b in branches if b.id != main_branch.id])
        status = random.choice(["Completed", "Completed", "Completed", "Rejected"])
        created = TODAY - timedelta(days=random.randint(5, 150))
        transfer = Transfer(
            from_branch_id=from_b.id, to_branch_id=to_b.id, status=status,
            requested_by=random.choice(staff_users).id,
            approved_by=random.choice(demo_users).id if status == "Completed" else None,
            created_at=created,
            completed_at=created + timedelta(hours=random.randint(4, 48)) if status == "Completed" else None,
        )
        db.add(transfer)
        db.flush()
        for p in random.sample(products, random.randint(1, 3)):
            db.add(TransferItem(transfer_id=transfer.id, product_id=p.id, quantity=random.randint(10, 40)))

    # The "story" pending transfer used in the demo script: Main Warehouse ->
    # Mansoura Branch, for a fast-moving product Mansoura is short on.
    fast_products = [p for p in products if p._behavior == "fast"]
    story_product = fast_products[0] if fast_products else products[0]
    pending_transfer = Transfer(
        from_branch_id=main_branch.id, to_branch_id=mansoura.id, status="Pending",
        requested_by=staff_users[3].id, approved_by=None,
        created_at=TODAY - timedelta(hours=6), completed_at=None,
    )
    db.add(pending_transfer)
    db.flush()
    db.add(TransferItem(transfer_id=pending_transfer.id, product_id=story_product.id, quantity=45))
    db.commit()
    print("  -> transfers complete")

    # ---------------------------------------------------------------
    # Notifications (seed a handful of realistic ones; more are generated
    # live by the alert engine on each dashboard/alerts request)
    # ---------------------------------------------------------------
    print("Seeding notifications...")
    seed_notifications = [
        Notification(company_id=company.id, branch_id=alexandria.id, type="sales_drop",
                     title="Sales drop detected — Alexandria Branch",
                     message="Sales in Alexandria Branch decreased compared with the previous period.",
                     severity="critical", related_entity_type="branch", related_entity_id=alexandria.id,
                     recommended_action="Review Alexandria Branch performance and promotions.",
                     created_at=TODAY - timedelta(hours=3)),
        Notification(company_id=company.id, branch_id=mansoura.id, type="transfer_pending",
                     title="Transfer awaiting approval",
                     message=f"A transfer of {story_product.name} to Mansoura Branch is pending approval.",
                     severity="warning", related_entity_type="transfer", related_entity_id=pending_transfer.id,
                     recommended_action="Review and approve the pending transfer.",
                     created_at=TODAY - timedelta(hours=6)),
        Notification(company_id=company.id, branch_id=None, type="expiry",
                     title="Products approaching expiry",
                     message="Several products across branches will expire within 30 days.",
                     severity="warning", related_entity_type="inventory", related_entity_id=None,
                     recommended_action="Review expiring inventory and plan clearance sales.",
                     created_at=TODAY - timedelta(hours=10)),
    ]
    for n in seed_notifications:
        db.add(n)
    db.commit()

    # ---------------------------------------------------------------
    # Activity logs (90 days of realistic audit trail)
    # ---------------------------------------------------------------
    print("Generating activity logs...")
    actions = [
        ("created a sale invoice", "sale"),
        ("created a purchase invoice", "purchase"),
        ("requested a stock transfer", "transfer"),
        ("approved a stock transfer", "transfer"),
        ("updated product stock", "inventory"),
        ("changed a product price", "product"),
        ("added a new customer", "customer"),
        ("marked a notification as read", "notification"),
        ("logged in", "session"),
        ("updated branch details", "branch"),
    ]
    for days_ago in range(90, -1, -1):
        d = TODAY - timedelta(days=days_ago)
        for _ in range(random.randint(15, 35)):
            user = random.choice(staff_users)
            action, entity_type = random.choice(actions)
            branch = random.choice(branches)
            db.add(ActivityLog(
                company_id=company.id, user_id=user.id, branch_id=branch.id,
                action=action, entity_type=entity_type,
                entity_id=random.randint(1, 500),
                description=f"{user.name} {action} in {branch.name}",
                created_at=d.replace(hour=random.randint(8, 21), minute=random.randint(0, 59)),
            ))
    db.commit()
    print("  -> activity logs complete")

    # ---------------------------------------------------------------
    # Daily metrics (pre-aggregated for fast dashboard reads)
    # ---------------------------------------------------------------
    print("Building daily metrics aggregation...")
    result = db.execute(text("""
        SELECT branch_id, date(created_at) as d, SUM(total_amount), SUM(profit), COUNT(*)
        FROM sales GROUP BY branch_id, date(created_at)
    """)).fetchall()
    for row in result:
        branch_id, d, total_sales, total_profit, orders = row
        db.add(DailyMetric(
            branch_id=branch_id, date=datetime.strptime(d, "%Y-%m-%d"),
            total_sales=total_sales or 0, total_profit=total_profit or 0, orders_count=orders or 0,
        ))
    db.commit()
    print("  -> daily metrics complete")

    # ---------------------------------------------------------------
    # Summary
    # ---------------------------------------------------------------
    n_sales = db.execute(text("SELECT COUNT(*) FROM sales")).scalar()
    n_items = db.execute(text("SELECT COUNT(*) FROM sale_items")).scalar()
    n_purch = db.execute(text("SELECT COUNT(*) FROM purchases")).scalar()
    n_activity = db.execute(text("SELECT COUNT(*) FROM activity_logs")).scalar()

    print("\n=== SEED COMPLETE ===")
    print(f"Company:        Moda Retail Group")
    print(f"Branches:       {len(branches)}")
    print(f"Users:          {len(staff_users)}")
    print(f"Products:       {len(products)}")
    print(f"Customers:      {len(customers)}")
    print(f"Suppliers:      {len(suppliers)}")
    print(f"Sales:          {n_sales}")
    print(f"Sale items:     {n_items}")
    print(f"Purchases:      {n_purch}")
    print(f"Activity logs:  {n_activity}")
    print("\nCreating performance indexes...")
    for stmt in [
        "CREATE INDEX IF NOT EXISTS ix_sales_branch_date ON sales(branch_id, created_at)",
        "CREATE INDEX IF NOT EXISTS ix_sales_created ON sales(created_at)",
        "CREATE INDEX IF NOT EXISTS ix_saleitems_product ON sale_items(product_id)",
        "CREATE INDEX IF NOT EXISTS ix_saleitems_sale ON sale_items(sale_id)",
        "CREATE INDEX IF NOT EXISTS ix_inventory_branch ON inventory(branch_id)",
        "CREATE INDEX IF NOT EXISTS ix_inventory_product ON inventory(product_id)",
        "CREATE INDEX IF NOT EXISTS ix_activity_created ON activity_logs(created_at)",
    ]:
        db.execute(text(stmt))
    db.commit()

    print("\nDemo logins (password: demo123):")
    print("  owner@stockvision.demo        (Owner)")
    print("  manager@stockvision.demo      (General Manager)")
    print("  branch@stockvision.demo       (Branch Manager - Alexandria)")
    print("  inventory@stockvision.demo    (Inventory Manager)")
    print("  accountant@stockvision.demo   (Accountant)")
    print("  auditor@stockvision.demo      (Auditor)")

    db.close()


if __name__ == "__main__":
    seed()
