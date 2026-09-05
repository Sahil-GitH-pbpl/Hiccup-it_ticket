from pathlib import Path
import os
from urllib.parse import quote_plus
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str | None = Field(default=None, validation_alias="ASSET_DATABASE_URL")
    asset_db_host: str = Field(default="127.0.0.1", validation_alias="ASSET_DB_HOST")
    asset_db_port: int = Field(default=3306, validation_alias="ASSET_DB_PORT")
    asset_db_user: str = Field(default="root", validation_alias="ASSET_DB_USER")
    asset_db_password: str = Field(default="", validation_alias="ASSET_DB_PASSWORD")
    asset_db_name: str = Field(default="asset_management", validation_alias="ASSET_DB_NAME")
    secret_key: str = Field(default="development-only-change-me", validation_alias="ASSET_SECRET_KEY")
    upload_dir: str = Field(default="./asset_uploads", validation_alias="ASSET_UPLOAD_DIR")
    cors_origins: str = "https://localhost:4676,https://labmate.bhasinpathlabs.com:4676"
    public_base_url: str = Field(default="https://labmate.bhasinpathlabs.com:4666/assets", validation_alias="ASSET_PUBLIC_BASE_URL")
    asset_base_path: str = Field(default="/assets", validation_alias="ASSET_BASE_PATH")
    whatsapp_mode: str = "mock"
    model_config = SettingsConfigDict(
        env_file=str(Path(__file__).resolve().parents[2] / ".env"), extra="ignore"
    )

    @property
    def resolved_database_url(self) -> str:
        if self.database_url:
            return self.database_url
        host = os.getenv("ASSET_DB_HOST") or os.getenv("DB_HOST") or self.asset_db_host
        port = os.getenv("ASSET_DB_PORT") or os.getenv("DB_PORT") or self.asset_db_port
        user = quote_plus(os.getenv("ASSET_DB_USER") or os.getenv("DB_USER") or self.asset_db_user)
        raw_password = os.getenv("ASSET_DB_PASSWORD")
        if raw_password is None:
            raw_password = os.getenv("DB_PASSWORD", self.asset_db_password)
        password = f":{quote_plus(raw_password)}" if raw_password else ""
        database = os.getenv("ASSET_DB_NAME") or self.asset_db_name
        return (
            f"mysql+pymysql://{user}{password}@"
            f"{host}:{port}/{database}"
        )


settings = Settings()
Path(settings.upload_dir).mkdir(parents=True, exist_ok=True)
