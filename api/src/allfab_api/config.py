"""Environment-backed API configuration."""

from functools import lru_cache

from pydantic import AnyHttpUrl, Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime settings; sensitive values remain redacted in representations."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        env_prefix="ALLFAB_",
        extra="ignore",
    )

    database_url: SecretStr | None = None
    object_storage_endpoint: AnyHttpUrl | None = None
    object_storage_access_key: SecretStr | None = None
    object_storage_secret_key: SecretStr | None = None
    object_storage_bucket: str | None = Field(default=None, min_length=3, max_length=63)
    object_storage_region: str = "us-east-1"
    dependency_timeout_seconds: int = Field(default=2, ge=1, le=30)


@lru_cache
def get_settings() -> Settings:
    """Load settings once per process without opening external connections."""

    return Settings()
