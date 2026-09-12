"""
Central application configuration.

Loaded once from environment variables / .env file. Every other module
should import `settings` from here rather than reading os.environ directly,
so that configuration stays centralized and swappable (e.g. when moving
from the demo SQLite database to a real SQL Server / e-Stock database).
"""
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent.parent  # backend/


class Settings(BaseSettings):
    app_name: str = "StockVision"
    app_env: str = "demo"
    debug: bool = True

    jwt_secret_key: str = "change-this-super-secret-key-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 1440

    database_url: str = "sqlite:///../data/stockvision.db"
    data_source_mode: str = "demo"  # "demo" | "estock"

    model_config = SettingsConfigDict(
        env_file=str(BASE_DIR / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
