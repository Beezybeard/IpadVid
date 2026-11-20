import asyncio
from collections.abc import Awaitable, Callable

import pytest
from fastapi.testclient import TestClient

from allfab_api.main import create_app
from allfab_api.services.readiness import ReadinessService

Probe = Callable[[], Awaitable[None]]


async def ready_probe() -> None:
    return None


def failing_probe(message: str) -> Probe:
    async def probe() -> None:
        raise RuntimeError(message)

    return probe


def make_client(
    *,
    database_probe: Probe = ready_probe,
    object_storage_probe: Probe = ready_probe,
    timeout_seconds: float = 0.1,
) -> TestClient:
    readiness_service = ReadinessService(
        database_probe=database_probe,
        object_storage_probe=object_storage_probe,
        timeout_seconds=timeout_seconds,
    )
    return TestClient(create_app(readiness_service=readiness_service))


def test_readyz_reports_all_dependencies_ready() -> None:
    with make_client() as client:
        response = client.get("/readyz")

    assert response.status_code == 200
    assert response.json() == {
        "service": "all-fab-video-library-api",
        "status": "ready",
        "dependencies": {
            "database": "ready",
            "object_storage": "ready",
        },
    }


@pytest.mark.parametrize(
    ("database_probe", "object_storage_probe", "expected_dependencies"),
    [
        (
            failing_probe("database unavailable"),
            ready_probe,
            {"database": "unavailable", "object_storage": "ready"},
        ),
        (
            ready_probe,
            failing_probe("object storage unavailable"),
            {"database": "ready", "object_storage": "unavailable"},
        ),
        (
            failing_probe("database unavailable"),
            failing_probe("object storage unavailable"),
            {"database": "unavailable", "object_storage": "unavailable"},
        ),
    ],
)
def test_readyz_returns_503_when_any_dependency_is_unavailable(
    database_probe: Probe,
    object_storage_probe: Probe,
    expected_dependencies: dict[str, str],
) -> None:
    with make_client(
        database_probe=database_probe,
        object_storage_probe=object_storage_probe,
    ) as client:
        response = client.get("/readyz")

    assert response.status_code == 503
    assert response.json() == {
        "service": "all-fab-video-library-api",
        "status": "not_ready",
        "dependencies": expected_dependencies,
    }


def test_readyz_treats_a_probe_timeout_as_unavailable() -> None:
    async def slow_probe() -> None:
        await asyncio.sleep(0.05)

    with make_client(database_probe=slow_probe, timeout_seconds=0.001) as client:
        response = client.get("/readyz")

    assert response.status_code == 503
    assert response.json()["dependencies"] == {
        "database": "unavailable",
        "object_storage": "ready",
    }


def test_readyz_does_not_expose_dependency_exception_details() -> None:
    secret = "postgresql://admin:do-not-leak@example.invalid/allfab"

    with make_client(database_probe=failing_probe(secret)) as client:
        response = client.get("/readyz")

    assert response.status_code == 503
    assert secret not in response.text
    assert "do-not-leak" not in response.text


def test_healthz_does_not_call_dependency_probes() -> None:
    calls = {"database": 0, "object_storage": 0}

    async def database_probe() -> None:
        calls["database"] += 1
        raise AssertionError("healthz must not call the database probe")

    async def object_storage_probe() -> None:
        calls["object_storage"] += 1
        raise AssertionError("healthz must not call the object-storage probe")

    with make_client(
        database_probe=database_probe,
        object_storage_probe=object_storage_probe,
    ) as client:
        response = client.get("/healthz")

    assert response.status_code == 200
    assert calls == {"database": 0, "object_storage": 0}


def test_openapi_documents_ready_and_not_ready_responses() -> None:
    schema = create_app(
        readiness_service=ReadinessService(
            database_probe=ready_probe,
            object_storage_probe=ready_probe,
            timeout_seconds=0.1,
        )
    ).openapi()

    operation = schema["paths"]["/readyz"]["get"]
    assert operation["responses"]["200"]["content"]["application/json"]["schema"] == {
        "$ref": "#/components/schemas/ReadinessResponse"
    }
    assert operation["responses"]["503"]["content"]["application/json"]["schema"] == {
        "$ref": "#/components/schemas/ReadinessResponse"
    }

    readiness_schema = schema["components"]["schemas"]["ReadinessResponse"]
    assert set(readiness_schema["required"]) == {"service", "status", "dependencies"}
    assert readiness_schema["properties"]["status"]["enum"] == ["ready", "not_ready"]
