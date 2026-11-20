"""Dependency readiness orchestration."""

import asyncio
from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from typing import Literal

from allfab_api.schemas.operations import (
    SERVICE_NAME,
    DependencyReadiness,
    DependencyStatus,
    ReadinessResponse,
)

Probe = Callable[[], Awaitable[None]]


@dataclass(frozen=True, slots=True)
class ReadinessService:
    """Run dependency checks concurrently and return a redacted result."""

    database_probe: Probe
    object_storage_probe: Probe
    timeout_seconds: float

    async def check(self) -> ReadinessResponse:
        database, object_storage = await asyncio.gather(
            self._check_probe(self.database_probe),
            self._check_probe(self.object_storage_probe),
        )
        overall_status: Literal["ready", "not_ready"] = (
            "ready" if database == object_storage == "ready" else "not_ready"
        )
        return ReadinessResponse(
            service=SERVICE_NAME,
            status=overall_status,
            dependencies=DependencyReadiness(
                database=database,
                object_storage=object_storage,
            ),
        )

    async def _check_probe(self, probe: Probe) -> DependencyStatus:
        try:
            await asyncio.wait_for(probe(), timeout=self.timeout_seconds)
        except Exception:
            return "unavailable"
        return "ready"
