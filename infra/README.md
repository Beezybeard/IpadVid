# Local infrastructure

The local stack provides PostgreSQL and an S3-compatible LocalStack emulator. Both ports bind only to Windows loopback, persistent data uses named volumes, and the example credentials are deliberately public development values that must never be reused outside this stack.

## Prerequisites

- Docker Desktop using Linux containers through WSL2, or an equivalent Linux container engine.
- Windows firmware virtualization enabled.
- Docker Compose v2 or newer.

## Start and verify

From the repository root:

```powershell
Copy-Item .\infra\.env.example .\infra\.env
docker compose --env-file .\infra\.env -f .\infra\compose.yaml config --quiet
docker compose --env-file .\infra\.env -f .\infra\compose.yaml up -d --wait
docker compose --env-file .\infra\.env -f .\infra\compose.yaml ps
```

Configure the host-run API from the same values:

```powershell
Copy-Item .\infra\.env.example .\api\.env
Set-Location .\api
.\.venv\Scripts\python.exe -m uvicorn allfab_api.main:app --reload
```

- `GET /healthz` reports API process liveness and never calls external services.
- `GET /readyz` returns HTTP 200 only when PostgreSQL accepts `SELECT 1` and the configured S3 bucket accepts an authenticated `HeadBucket`; otherwise it returns a redacted HTTP 503 response.

Stop containers without deleting persisted development data:

```powershell
docker compose --env-file .\infra\.env -f .\infra\compose.yaml down
```

Do not add `--volumes` unless intentionally deleting the local database and object-store data.
