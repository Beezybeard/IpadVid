import asyncio
from typing import Any

import pytest

from allfab_api.config import Settings
from allfab_api.infrastructure import probes
from allfab_api.infrastructure.probes import (
    DependencyNotConfiguredError,
    ObjectStorageProbe,
    PostgresProbe,
    create_default_readiness_service,
)


def configured_settings() -> Settings:
    return Settings.model_validate(
        {
            "database_url": "postgresql://allfab:database-secret@example.invalid/allfab",
            "object_storage_endpoint": "http://127.0.0.1:4566",
            "object_storage_access_key": "access-secret",
            "object_storage_secret_key": "storage-secret",
            "object_storage_bucket": "allfab-video-library-dev",
            "object_storage_region": "us-east-1",
            "dependency_timeout_seconds": 1,
        }
    )


def test_settings_repr_redacts_credentials() -> None:
    representation = repr(configured_settings())

    assert "database-secret" not in representation
    assert "access-secret" not in representation
    assert "storage-secret" not in representation


def test_unconfigured_default_service_reports_both_dependencies_unavailable() -> None:
    result = asyncio.run(create_default_readiness_service(Settings.model_construct()).check())

    assert result.status == "not_ready"
    assert result.dependencies.model_dump() == {
        "database": "unavailable",
        "object_storage": "unavailable",
    }


def test_postgres_probe_connects_executes_and_closes(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    settings = configured_settings()
    observed: dict[str, Any] = {}

    class FakeConnection:
        async def execute(self, query: str) -> None:
            observed["query"] = query

        async def close(self, *, timeout: float) -> None:
            observed["close_timeout"] = timeout

    async def fake_connect(*, dsn: str, timeout: float) -> FakeConnection:
        observed["dsn"] = dsn
        observed["connect_timeout"] = timeout
        return FakeConnection()

    monkeypatch.setattr(probes.asyncpg, "connect", fake_connect)

    asyncio.run(
        PostgresProbe(
            database_url=settings.database_url,
            timeout_seconds=settings.dependency_timeout_seconds,
        )()
    )

    assert observed == {
        "dsn": "postgresql://allfab:database-secret@example.invalid/allfab",
        "connect_timeout": 1,
        "query": "SELECT 1",
        "close_timeout": 1,
    }


def test_postgres_probe_rejects_missing_configuration() -> None:
    with pytest.raises(DependencyNotConfiguredError, match="database is not configured"):
        asyncio.run(PostgresProbe(database_url=None, timeout_seconds=1)())


def test_object_storage_probe_uses_authenticated_head_bucket_and_closes(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    settings = configured_settings()
    observed: dict[str, Any] = {}

    class FakeClient:
        def head_bucket(self, *, Bucket: str) -> None:  # noqa: N803 - boto3 API name
            observed["bucket"] = Bucket

        def close(self) -> None:
            observed["closed"] = True

    def fake_client(service_name: str, **kwargs: Any) -> FakeClient:
        observed["service_name"] = service_name
        observed["client_kwargs"] = kwargs
        return FakeClient()

    monkeypatch.setattr(probes.boto3, "client", fake_client)
    probe = ObjectStorageProbe(
        endpoint=settings.object_storage_endpoint,
        access_key=settings.object_storage_access_key,
        secret_key=settings.object_storage_secret_key,
        bucket=settings.object_storage_bucket,
        region=settings.object_storage_region,
        timeout_seconds=settings.dependency_timeout_seconds,
    )

    asyncio.run(probe())

    client_kwargs = observed["client_kwargs"]
    assert observed["service_name"] == "s3"
    assert observed["bucket"] == "allfab-video-library-dev"
    assert observed["closed"] is True
    assert client_kwargs["endpoint_url"] == "http://127.0.0.1:4566/"
    assert client_kwargs["aws_access_key_id"] == "access-secret"
    assert client_kwargs["aws_secret_access_key"] == "storage-secret"
    assert client_kwargs["region_name"] == "us-east-1"
    assert client_kwargs["config"].connect_timeout == 1
    assert client_kwargs["config"].read_timeout == 1


def test_object_storage_probe_rejects_missing_configuration() -> None:
    probe = ObjectStorageProbe(
        endpoint=None,
        access_key=None,
        secret_key=None,
        bucket=None,
        region="us-east-1",
        timeout_seconds=1,
    )

    with pytest.raises(
        DependencyNotConfiguredError,
        match="object storage is not configured",
    ):
        asyncio.run(probe())
