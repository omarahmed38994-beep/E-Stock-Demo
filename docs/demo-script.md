# StockVision — Demo Script (5–10 minutes)

**Company:** Moda Retail Group — a fashion & apparel retailer with 7
branches (1 main warehouse + 6 stores) across Egypt. The demo database has
12 months of realistic sales history with a story already built in.

**Login:** `owner@stockvision.demo` / `demo123`

---

## Step 1 — Login (30 sec)
Log in as the Owner. Point out this is the same app a Branch Manager or
Accountant would use — they'd just see a scoped-down version of it.

## Step 2 — Dashboard (1–2 min)
Land on the Dashboard. Call out, in this order:
1. **Attention Required** at the top — this is the single most important
   idea in the product: *"Here is what you need to know right now"* rather
   than making the owner dig through reports.
2. The KPI grid — today's sales, profit, orders, active branches, low
   stock, expiring, pending transfers.
3. Scroll to the sales/profit trend charts and branch performance bars.

## Step 3 — Business Overview (30 sec)
Tap "View details" under Business Overview. Show revenue, profit, margin,
growth, and — importantly — **Best Branch** vs **Worst Branch**, computed
live from the data, not hardcoded.

## Step 4 — Branches → Alexandria (1–2 min)
Go to the Branches tab, open **Alexandria Branch**. This branch is
intentionally seeded to be declining. Show:
- Sales trend visibly down vs. company average
- Low-stock products list
- Recent activity for this branch

Then open **Branch Comparison** to show Alexandria against the rest of the
company visually.

## Step 5 — Alerts (1 min)
Go to the Alerts tab (Notification Center). Point out:
- A **critical** "Sales drop detected — Alexandria Branch" alert
- Low stock / critical stock alerts
- An expiry warning
- A pending transfer awaiting approval

Tap a notification to show it can be marked as read.

## Step 6 — Inventory → a low-stock product (1–2 min)
Go to Inventory, filter by "Low Stock" or "Critical". Open one product.
Show:
- Current stock across branches
- Sales velocity and estimated days until stockout
- The ML-based demand forecast (7-day / 30-day expected demand)
- The reorder recommendation generated from that forecast

## Step 7 — Recommendations (1 min)
Open Recommendations (via More → Recommendations). Show the mix of:
- **Reorder** recommendations (products trending toward stockout)
- **Transfer** recommendations (e.g. move stock from Main Warehouse to a
  branch running low on the same product — this is the pending transfer
  seeded in the story)
- **Reduce purchasing** recommendations for slow-moving overstocked items

If a pending transfer exists, go to More → Stock Transfers and **approve
it** live — show the status flip to Completed and inventory update.

## Step 8 — Activity Timeline (30 sec)
Open More → Activity Timeline (Owner/GM/Auditor only). Scroll through the
audit trail: who did what, when, in which branch.

## Step 9 — AI Assistant (2 min)
Open "Ask your business" (top-right icon on the dashboard, or via More).
Ask, in order:
1. *"Which branch needs attention?"*
2. *"Which products may run out soon?"*
3. *"What are my top-selling products?"*
4. *"Why did sales decrease this week?"*
5. *"Show me the most profitable categories."*

Emphasize: every answer is generated from real seeded data through a safe,
deterministic query engine — not a black-box LLM guessing.

## Step 10 — Close with business value (1 min)
Wrap up with the core pitch:

> "A business owner can monitor their entire company — every branch,
> every product, every warning sign — from their phone, without manually
> opening reports or checking each branch's system individually.
> StockVision doesn't replace your existing system — it sits on top of it
> and tells you what matters."

---

## Optional extras if there's time
- Toggle Dark Mode (More → Preferences).
- Log out and log back in as `branch@stockvision.demo` (Alexandria Branch
  Manager) to show role-based access — branches list is now scoped to
  just Alexandria, and Activity/Export are hidden from the menu.
- Show the Swagger docs at `http://127.0.0.1:8000/docs` to demonstrate the
  backend is a real, documented, testable API — not a mockup.
