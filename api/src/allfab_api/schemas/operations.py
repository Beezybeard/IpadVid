"""Schemas for process liveness and dependency readiness."""

from typing import Literal

from pydantic import BaseModel

SERVICE_NAME = "all-fab-video-library-api"
DependencyStatus = Literal["ready", "unavailable"]


class HealthResponse(BaseModel):
    """Stable process-liveness response."""

    service: Literal["all-fab-video-library-api"]
    status: Literal["ok"]


class DependencyReadiness(BaseModel):
    """Readiness state for each required external dependency."""

    database: DependencyStatus
    object_storage: DependencyStatus


class ReadinessResponse(BaseModel):
    """Dependency readiness response used for both HTTP 200 and 503."""

    service: Literal["all-fab-video-library-api"]
    status: Literal["ready", "not_ready"]
    dependencies: DependencyReadiness
