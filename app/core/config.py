from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Internal Staff System Hiccup Module"
    db_host: str = Field("localhost", env="DB_HOST")
    db_port: int = Field(3306, env="DB_PORT")
    db_user: str = Field("root", env="DB_USER")
    db_password: str = Field("", env="DB_PASSWORD")
    db_name: str = Field("hiccup_ticket", env="DB_NAME")
    jwt_secret: str = Field("supersecret", env="JWT_SECRET")
    jwt_algo: str = Field("HS256", env="JWT_ALGO")
    whatsapp_api_url: str = Field(
        "http://10.1.1.181:3004/api/messages/send", env="WHATSAPP_API_URL"
    )
    whatsapp_api_token: str = Field(
        "61e3f2cd978650537d9223e7", env="WHATSAPP_API_TOKEN"
    )
    whatsapp_account_id: int = Field(1, env="WHATSAPP_ACCOUNT_ID")
    management_group_numbers: str = Field("120363141953100908@g.us", env="MANAGEMENT_GROUP_NUMBERS")
    internal_service_token: str = Field("internal-token", env="INTERNAL_SERVICE_TOKEN")
    frontend_base_url: str = Field(
        "http://10.1.1.53:8015", env="FRONTEND_BASE_URL"
    )
    whatsapp_response_base_url: str = Field(
        "http://10.1.1.53:8015", env="WHATSAPP_RESPONSE_BASE_URL"
    )
    external_whatsapp_response_base_url: str = Field(
        "https://labmate.bhasinpathlabs.com:4666", env="EXTERNAL_WHATSAPP_RESPONSE_BASE_URL"
    )
    timezone: str = Field("Asia/Kolkata", env="TIMEZONE")
    response_reminder_minutes: int = Field(20 * 60, env="RESPONSE_REMINDER_MINUTES")
    response_overdue_minutes: int = Field(24 * 60, env="RESPONSE_OVERDUE_MINUTES")
    response_escalate_minutes: int = Field(60 * 60, env="RESPONSE_ESCALATE_MINUTES")
    # response_reminder_minutes: int = Field(2, env="RESPONSE_REMINDER_MINUTES")
    # response_overdue_minutes: int = Field(3, env="RESPONSE_OVERDUE_MINUTES")
    # response_escalate_minutes: int = Field(4, env="RESPONSE_ESCALATE_MINUTES")
    session_secret: str = Field("change-this-session-secret", env="SESSION_SECRET")
    enable_infra_reminder: bool = Field(True, env="ENABLE_INFRA_REMINDER")
    infra_pick_sla_start: str = Field("11:00", env="INFRA_PICK_SLA_START")
    infra_pick_sla_end: str = Field("17:00", env="INFRA_PICK_SLA_END")
    infra_sla_holidays: str = Field("", env="INFRA_SLA_HOLIDAYS")
    local_reload: bool = Field(False, env="LOCAL_RELOAD")
    redis_url: str = Field("redis://redis:6379/0", env="REDIS_URL")
    redis_enabled: bool = Field(False, env="REDIS_ENABLED")
    cache_default_ttl_seconds: int = Field(300, env="CACHE_DEFAULT_TTL_SECONDS")
    scheduler_lock_ttl_seconds: int = Field(55 * 60, env="SCHEDULER_LOCK_TTL_SECONDS")

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=False,
        extra="ignore",
    )


@lru_cache()
def get_settings() -> Settings:
    return Settings()
