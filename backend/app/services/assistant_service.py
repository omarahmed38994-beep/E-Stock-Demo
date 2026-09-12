"""
AI Business Assistant ("Ask your business").

This is a deterministic, safe natural-language query engine — NOT a raw
LLM/SQL executor. The flow is:
  1. detect_intent()  — keyword/pattern based intent classification
  2. extract entities  — branch names, product names, time ranges mentioned
  3. map intent -> a predefined, parameterized analytics query
  4. execute the query against real data
  5. compose a natural-language answer from the real numbers

No arbitrary SQL is ever built from user input.
"""
import re
from datetime import datetime, timedelta
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.services import analytics_service as an
from app.services import forecasting_service as fc


def _find_branch(db: Session, question: str):
    branches = db.execute(text("SELECT id, name FROM branches")).fetchall()
    q = question.lower()
    for bid, name in branches:
        # match on distinguishing part of the branch name, e.g. "alexandria"
        key = name.lower().replace(" branch", "").replace(" warehouse", "").strip()
        if key and key in q:
            return bid, name
    return None, None


def _period_from_question(question: str):
    q = question.lower()
    now = datetime.utcnow()
    if "today" in q:
        return now.replace(hour=0, minute=0, second=0, microsecond=0), now, "today"
    if "week" in q:
        return now - timedelta(days=7), now, "the last 7 days"
    if "quarter" in q:
        return now - timedelta(days=90), now, "the last 90 days"
    if "year" in q or "ytd" in q:
        return now - timedelta(days=365), now, "the last 12 months"
    if "month" in q:
        return now - timedelta(days=30), now, "this month"
    return now - timedelta(days=30), now, "the last 30 days"


INTENT_PATTERNS = [
    ("best_branch", [r"best branch", r"which branch.*(perform|best|top)", r"top branch"]),
    ("worst_branch", [r"worst branch", r"underperform", r"needs? attention", r"which branch.*(worst|attention|struggl)"]),
    ("branch_sales", [r"sales for .* branch", r"how (is|are) .* (branch|doing)", r"show sales"]),
    ("top_products", [r"top \d* ?products", r"best.sell", r"top.sell"]),
    ("low_stock", [r"low (in )?stock", r"running (out|low)", r"out of stock"]),
    ("stockout_risk", [r"run out soon", r"may run out", r"stockout", r"about to run out"]),
    ("sales_decline_reason", [r"why did sales (decrease|drop|fall)", r"why.*sales.*down"]),
    ("profitable_categories", [r"profitable categor", r"most profitable"]),
    ("company_overview", [r"how.*(business|company).*doing", r"overview", r"summary"]),
    ("expiring", [r"expir"]),
]


def detect_intent(question: str) -> str:
    q = question.lower()
    for intent, patterns in INTENT_PATTERNS:
        for p in patterns:
            if re.search(p, q):
                return intent
    return "unknown"


def answer_question(db: Session, question: str) -> dict:
    intent = detect_intent(question)
    branch_id, branch_name = _find_branch(db, question)
    start, end, period_label = _period_from_question(question)

    if intent == "best_branch":
        perf = an.branch_performance(db, start, end, None)
        if not perf:
            return _no_data(intent)
        top = perf[0]
        answer = (f"{top['name']} is your best-performing branch over {period_label}, with EGP "
                  f"{top['sales']:,.0f} in sales and {top['growth_pct']:+.1f}% growth vs the previous period.")
        return {"answer": answer, "intent": intent, "data": {"branches": perf[:5]}}

    if intent == "worst_branch":
        perf = an.branch_performance(db, start, end, None)
        if not perf:
            return _no_data(intent)
        worst = min(perf, key=lambda b: b["growth_pct"])
        low_stock_note = f" and {worst['low_stock_count']} products are low in stock" if worst['low_stock_count'] else ""
        answer = (f"{worst['name']} requires attention: sales changed {worst['growth_pct']:+.1f}% vs the previous "
                  f"period{low_stock_note}.")
        return {"answer": answer, "intent": intent, "data": {"branch": worst}}

    if intent == "branch_sales":
        branch_ids = [branch_id] if branch_id else None
        result = an.sales_analytics(db, start, end, branch_ids)
        scope = branch_name if branch_name else "the company"
        answer = (f"{scope} generated EGP {result['revenue']:,.0f} in sales over {period_label}, "
                  f"across {result['orders']} orders (avg order value EGP {result['avg_order_value']:,.0f}).")
        return {"answer": answer, "intent": intent, "data": result}

    if intent == "top_products":
        m = re.search(r"top (\d+)", question.lower())
        n = int(m.group(1)) if m else 5
        result = an.sales_analytics(db, start, end, None)
        top = result["best_selling"][:n]
        if not top:
            return _no_data(intent)
        names = ", ".join(f"{t['name']} (EGP {t['revenue']:,.0f})" for t in top[:5])
        answer = f"Your top {len(top)} products over {period_label} are: {names}."
        return {"answer": answer, "intent": intent, "data": {"top_products": top}}

    if intent == "low_stock":
        branch_ids = [branch_id] if branch_id else None
        intel = an.inventory_intelligence(db, branch_ids)
        low_items = [i for i in intel["items"] if i["status"] in ("Low Stock", "Critical")][:8]
        if not low_items:
            return {"answer": "No products are currently low in stock. Inventory levels look healthy.",
                     "intent": intent, "data": {"items": []}}
        names = ", ".join(f"{i['product']} at {i['branch']} ({i['quantity']} left)" for i in low_items[:5])
        answer = f"{len(low_items)} product/branch combinations are low in stock, including: {names}."
        return {"answer": answer, "intent": intent, "data": {"items": low_items}}

    if intent == "stockout_risk":
        branch_ids = [branch_id] if branch_id else None
        intel = an.inventory_intelligence(db, branch_ids)
        at_risk = [i for i in intel["items"] if i["days_of_stock_left"] is not None and i["days_of_stock_left"] <= 7]
        at_risk = sorted(at_risk, key=lambda i: i["days_of_stock_left"])[:6]
        if not at_risk:
            return {"answer": "No products are projected to run out within the next week.",
                     "intent": intent, "data": {"items": []}}
        names = ", ".join(f"{i['product']} at {i['branch']} (~{i['days_of_stock_left']:.0f} days)" for i in at_risk)
        answer = f"These products may run out soon: {names}."
        return {"answer": answer, "intent": intent, "data": {"items": at_risk}}

    if intent == "sales_decline_reason":
        perf = an.branch_performance(db, start, end, [branch_id] if branch_id else None)
        anomalies = fc.detect_anomalies(db)
        drops = [a for a in anomalies if a["direction"] == "drop"]
        declining = sorted(perf, key=lambda b: b["growth_pct"])[:2]
        parts = []
        for b in declining:
            if b["growth_pct"] < 0:
                parts.append(f"{b['name']} is down {abs(b['growth_pct']):.1f}%")
        drop_note = ""
        if drops:
            drop_note = f" Unusual drops were also detected in: {', '.join(d['branch_name'] for d in drops)}."
        if parts:
            answer = f"Sales changes over {period_label}: {', '.join(parts)}.{drop_note} Check inventory levels and local promotions for these branches."
        else:
            answer = f"No significant sales decline was detected over {period_label} across branches.{drop_note}"
        return {"answer": answer, "intent": intent, "data": {"branch_performance": perf, "anomalies": drops}}

    if intent == "profitable_categories":
        result = an.profit_analytics(db, start, end, None)
        cats = result["by_category"][:5]
        if not cats:
            return _no_data(intent)
        names = ", ".join(f"{c['category']} (EGP {c['profit']:,.0f})" for c in cats)
        answer = f"Your most profitable categories over {period_label} are: {names}."
        return {"answer": answer, "intent": intent, "data": {"by_category": cats}}

    if intent == "company_overview":
        overview = an.business_overview(db, datetime.utcnow())
        answer = (f"Over the last 30 days, revenue was EGP {overview['total_revenue']:,.0f} with "
                  f"EGP {overview['total_profit']:,.0f} profit ({overview['profit_margin_pct']}% margin), "
                  f"{overview['sales_growth_pct']:+.1f}% vs the prior period. Best branch: {overview['best_branch']}. "
                  f"{overview['low_stock_count']} items are low in stock and {overview['expiring_products']} are expiring soon.")
        return {"answer": answer, "intent": intent, "data": overview}

    if intent == "expiring":
        count = an.expiring_products_count(db, [branch_id] if branch_id else None, days=30)
        answer = f"{count} products{' at ' + branch_name if branch_name else ''} will expire within the next 30 days."
        return {"answer": answer, "intent": intent, "data": {"expiring_count": count}}

    return {
        "answer": "I can answer questions about branch performance, sales, low stock, products that may run "
                  "out soon, profitability, and expiring inventory. Try asking things like \"Which branch needs "
                  "attention?\" or \"What are my top-selling products?\"",
        "intent": "unknown",
        "data": None,
    }


def _no_data(intent: str) -> dict:
    return {"answer": "There isn't enough data yet to answer that.", "intent": intent, "data": None}
