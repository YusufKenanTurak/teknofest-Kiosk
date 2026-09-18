from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

_BACKEND_ROOT = Path(__file__).resolve().parents[1]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(_BACKEND_ROOT / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    pg_host: str = Field(default="10.6.228.154", alias="PG_HOST")
    pg_port: int = Field(default=5432, alias="PG_PORT")
    pg_database: str = Field(default="teknofestKiosk", alias="PG_DATABASE")
    pg_user: str = Field(default="appuser", alias="PG_USER")
    pg_password: str = Field(default="", alias="PG_PASSWORD")
    pg_sslmode: str = Field(default="prefer", alias="PG_SSLMODE")
    app_env: str = Field(default="test", alias="APP_ENV")
    application_version: str = Field(default="1.0.0", alias="APP_VERSION")
    pool_size: int = Field(default=8, alias="PG_POOL_SIZE")

    @property
    def dsn(self) -> str:
        return (
            f"postgresql://{self.pg_user}:{self.pg_password}"
            f"@{self.pg_host}:{self.pg_port}/{self.pg_database}"
            f"?sslmode={self.pg_sslmode}"
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()
