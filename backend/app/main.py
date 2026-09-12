"""
StockVision Backend — FastAPI application entrypoint.

Run locally with:
    python -m uvicorn app.main:app --reload

Swagger docs available at http://127.0.0.1:8000/docs
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.config import settings
from app.api import (
    auth, dashboard, branches, products, sales, inventory, purchases,
    analytics, alerts, activity, transfers, assistant, forecast, search, export,
)

app = FastAPI(
    title="StockVision API",
    description="Smart mobile business intelligence & operations platform — backend API.",
    version="1.0.0",
)

# CORS: open for the local demo so the Flutter app (any device/emulator on
# the LAN) can reach the API without configuration friction.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# --- Centralized, friendly error handling (no raw stack traces to clients) ---
@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(status_code=exc.status_code, content={"error": True, "detail": exc.detail})


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc):
    return JSONResponse(status_code=422, content={"error": True, "detail": "Invalid request data", "errors": exc.errors()})


@app.exception_handler(Exception)
async def unhandled_exception_handler(request, exc):
    return JSONResponse(status_code=500, content={"error": True, "detail": "An unexpected server error occurred."})


app.include_router(auth.router)
app.include_router(dashboard.router)
app.include_router(branches.router)
app.include_router(products.router)
app.include_router(sales.router)
app.include_router(inventory.router)
app.include_router(purchases.router)
app.include_router(analytics.router)
app.include_router(alerts.router)
app.include_router(activity.router)
app.include_router(transfers.router)
app.include_router(assistant.router)
app.include_router(forecast.router)
app.include_router(search.router)
app.include_router(export.router)


@app.get("/", tags=["Health"])
def root():
    return {
        "product": "StockVision API",
        "status": "running",
        "environment": settings.app_env,
        "data_source_mode": settings.data_source_mode,
        "docs": "/docs",
    }


@app.get("/health", tags=["Health"])
def health():
    return {"status": "ok"}
