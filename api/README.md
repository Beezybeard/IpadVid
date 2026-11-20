# All Fab Video Library API

This package provides the FastAPI backend for the All Fab Video Library. The current Phase 0 surface contains two operational endpoints:

- `GET /healthz` — process liveness only; never contacts external dependencies.
- `GET /readyz` — HTTP 200 only when PostgreSQL and the configured S3-compatible bucket are reachable; otherwise a redacted HTTP 503 response.

## Windows setup

From this directory:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install --require-hashes -r requirements-dev.lock
.\.venv\Scripts\python.exe -m pip install --no-deps -e .
```

Copy the public local-development configuration after starting the services documented in `../infra/README.md`:

```powershell
Copy-Item ..\infra\.env.example .\.env
.\.venv\Scripts\python.exe -m uvicorn allfab_api.main:app --reload
```

## Verification

```powershell
.\.venv\Scripts\python.exe -m build
.\.venv\Scripts\python.exe -m pyright
.\.venv\Scripts\python.exe -m ruff check .
.\.venv\Scripts\python.exe -m ruff format --check .
.\.venv\Scripts\python.exe -m pytest
.\.venv\Scripts\python.exe -m pip_audit
```

Use `pyproject.toml` as the dependency source and regenerate both lock files after an intentional dependency change:

```powershell
.\.venv\Scripts\python.exe -m piptools compile --strip-extras --generate-hashes --allow-unsafe --output-file requirements.lock pyproject.toml
.\.venv\Scripts\python.exe -m piptools compile --strip-extras --generate-hashes --allow-unsafe --extra dev --output-file requirements-dev.lock pyproject.toml
```
