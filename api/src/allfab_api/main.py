"""FastAPI application entry point."""

from fastapi import FastAPI

from allfab_api.config import get_settings
from allfab_api.infrastructure.probes import create_default_readiness_service
from allfab_api.routers.operations import router as operations_router
from allfab_api.services.readiness import ReadinessService


def create_app(*, readiness_service: ReadinessService | None = None) -> FastAPI:
    """Create the API without opening external connections at import time."""

    application = FastAPI(
        title="All Fab Video Library API",
        version="0.1.0",
    )
    application.state.readiness_service = readiness_service or create_default_readiness_service(
        get_settings()
    )
    application.include_router(operations_router)

    return application


app = create_app()
