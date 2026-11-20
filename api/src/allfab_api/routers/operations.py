"""Process liveness and dependency readiness routes."""

from typing import Annotated

from fastapi import APIRouter, Depends, Request, status
from fastapi.responses import JSONResponse

from allfab_api.schemas.operations import HealthResponse, ReadinessResponse
from allfab_api.services.readiness import ReadinessService

router = APIRouter(tags=["operations"])


def get_readiness_service(request: Request) -> ReadinessService:
    """Resolve the application-scoped readiness service."""

    return request.app.state.readiness_service


ReadinessServiceDependency = Annotated[ReadinessService, Depends(get_readiness_service)]


@router.get(
    "/healthz",
    response_model=HealthResponse,
    summary="Report API process liveness",
)
def healthz() -> HealthResponse:
    return HealthResponse(service="all-fab-video-library-api", status="ok")


@router.get(
    "/readyz",
    response_model=ReadinessResponse,
    responses={
        status.HTTP_503_SERVICE_UNAVAILABLE: {
            "description": "One or more required dependencies are unavailable",
            "model": ReadinessResponse,
        }
    },
    summary="Report required dependency readiness",
)
async def readyz(
    readiness_service: ReadinessServiceDependency,
) -> ReadinessResponse | JSONResponse:
    readiness = await readiness_service.check()
    if readiness.status == "not_ready":
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content=readiness.model_dump(mode="json"),
        )
    return readiness
