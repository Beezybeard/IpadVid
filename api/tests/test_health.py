from fastapi.testclient import TestClient

from allfab_api.main import app


def test_healthz_reports_process_liveness() -> None:
    with TestClient(app) as client:
        response = client.get("/healthz")

    assert response.status_code == 200
    assert response.headers["content-type"] == "application/json"
    assert response.json() == {
        "service": "all-fab-video-library-api",
        "status": "ok",
    }
