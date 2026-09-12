"""
Basic backend test suite.

Run with:  cd backend && ./.venv/bin/pytest -v
Assumes the database has already been seeded (python -m app.database.seed).
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


@pytest.fixture(scope="module")
def token():
    resp = client.post("/auth/login", json={"email": "owner@stockvision.demo", "password": "demo123"})
    assert resp.status_code == 200
    return resp.json()["access_token"]


@pytest.fixture(scope="module")
def auth_headers(token):
    return {"Authorization": f"Bearer {token}"}


def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


def test_login_success():
    resp = client.post("/auth/login", json={"email": "owner@stockvision.demo", "password": "demo123"})
    assert resp.status_code == 200
    body = resp.json()
    assert "access_token" in body
    assert body["user"]["role"] == "Owner"


def test_login_failure():
    resp = client.post("/auth/login", json={"email": "owner@stockvision.demo", "password": "wrongpass"})
    assert resp.status_code == 401


def test_dashboard_overview(auth_headers):
    resp = client.get("/dashboard/overview", headers=auth_headers)
    assert resp.status_code == 200
    body = resp.json()
    for key in ("today_sales", "today_profit", "active_branches", "attention_required"):
        assert key in body


def test_business_overview(auth_headers):
    resp = client.get("/dashboard/business-overview", headers=auth_headers)
    assert resp.status_code == 200
    assert "total_revenue" in resp.json()


def test_branches_list(auth_headers):
    resp = client.get("/branches", headers=auth_headers)
    assert resp.status_code == 200
    branches = resp.json()
    assert len(branches) == 7
    assert any(b["name"] == "Alexandria Branch" for b in branches)


def test_branch_detail(auth_headers):
    resp = client.get("/branches/3", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["branch"]["name"] == "Alexandria Branch"


def test_inventory_overview(auth_headers):
    resp = client.get("/inventory", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["summary"]["total_skus"] > 0


def test_inventory_low_stock(auth_headers):
    resp = client.get("/inventory/low-stock", headers=auth_headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_analytics_sales(auth_headers):
    resp = client.get("/analytics/sales?period=30d", headers=auth_headers)
    assert resp.status_code == 200
    assert "revenue" in resp.json()


def test_analytics_profit(auth_headers):
    resp = client.get("/analytics/profit?period=30d", headers=auth_headers)
    assert resp.status_code == 200
    assert "gross_profit" in resp.json()


def test_alerts(auth_headers):
    resp = client.get("/alerts", headers=auth_headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_activity(auth_headers):
    resp = client.get("/activity", headers=auth_headers)
    assert resp.status_code == 200
    assert "items" in resp.json()


def test_assistant_best_branch(auth_headers):
    resp = client.post("/assistant/query", json={"question": "Which branch is performing best?"}, headers=auth_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["intent"] == "best_branch"
    assert len(body["answer"]) > 0


def test_assistant_low_stock(auth_headers):
    resp = client.post("/assistant/query", json={"question": "What products are low in stock?"}, headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["intent"] == "low_stock"


def test_forecast(auth_headers):
    resp = client.get("/forecast/1", headers=auth_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert "forecast_7_day_demand" in body


def test_recommendations(auth_headers):
    resp = client.get("/recommendations", headers=auth_headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_unauthorized_access():
    resp = client.get("/dashboard/overview")
    assert resp.status_code == 401


def test_branch_manager_role_scope():
    resp = client.post("/auth/login", json={"email": "branch@stockvision.demo", "password": "demo123"})
    token = resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    branches_resp = client.get("/branches", headers=headers)
    assert branches_resp.status_code == 200
    # Branch Manager should only see their own branch
    assert len(branches_resp.json()) == 1
    assert branches_resp.json()[0]["name"] == "Alexandria Branch"
