"""Readiness probes for PostgreSQL and S3-compatible object storage."""

import asyncio
from dataclasses import dataclass

import asyncpg
import boto3
from botocore.config import Config
from pydantic import AnyHttpUrl, SecretStr

from allfab_api.config import Settings
from allfab_api.services.readiness import ReadinessService


class DependencyNotConfiguredError(RuntimeError):
    """Raised internally when a required dependency setting is absent."""


@dataclass(frozen=True, slots=True)
class PostgresProbe:
    """Open a short-lived PostgreSQL connection and execute a trivial query."""

    database_url: SecretStr | None
    timeout_seconds: int

    async def __call__(self) -> None:
        if self.database_url is None:
            raise DependencyNotConfiguredError("database is not configured")

        connection = await asyncpg.connect(
            dsn=self.database_url.get_secret_value(),
            timeout=self.timeout_seconds,
        )
        try:
            await asyncio.wait_for(
                connection.execute("SELECT 1"),
                timeout=self.timeout_seconds,
            )
        finally:
            await connection.close(timeout=self.timeout_seconds)


@dataclass(frozen=True, slots=True)
class ObjectStorageProbe:
    """Verify authenticated access to the configured S3 bucket."""

    endpoint: AnyHttpUrl | None
    access_key: SecretStr | None
    secret_key: SecretStr | None
    bucket: str | None
    region: str
    timeout_seconds: int

    async def __call__(self) -> None:
        if (
            self.endpoint is None
            or self.access_key is None
            or self.secret_key is None
            or self.bucket is None
        ):
            raise DependencyNotConfiguredError("object storage is not configured")

        await asyncio.to_thread(self._head_bucket)

    def _head_bucket(self) -> None:
        client = boto3.client(
            "s3",
            endpoint_url=str(self.endpoint),
            aws_access_key_id=self.access_key.get_secret_value() if self.access_key else None,
            aws_secret_access_key=self.secret_key.get_secret_value() if self.secret_key else None,
            region_name=self.region,
            config=Config(
                connect_timeout=self.timeout_seconds,
                read_timeout=self.timeout_seconds,
                retries={"max_attempts": 0},
                signature_version="s3v4",
            ),
        )
        try:
            client.head_bucket(Bucket=self.bucket)
        finally:
            client.close()


def create_default_readiness_service(settings: Settings) -> ReadinessService:
    """Construct dependency adapters without contacting external services."""

    return ReadinessService(
        database_probe=PostgresProbe(
            database_url=settings.database_url,
            timeout_seconds=settings.dependency_timeout_seconds,
        ),
        object_storage_probe=ObjectStorageProbe(
            endpoint=settings.object_storage_endpoint,
            access_key=settings.object_storage_access_key,
            secret_key=settings.object_storage_secret_key,
            bucket=settings.object_storage_bucket,
            region=settings.object_storage_region,
            timeout_seconds=settings.dependency_timeout_seconds,
        ),
        timeout_seconds=settings.dependency_timeout_seconds,
    )
