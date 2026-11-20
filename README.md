# All Fab Video Library

All Fab Video Library is an offline-first training-video system for company-managed iPads. Employees will select individual company videos, download and verify them, and play persistent local copies through the native Apple player without a network connection or fresh sign-in.

This repository is at the beginning of Phase 0. The numbered handoff documents and `AGENTS.md` remain the product and engineering contract until their requirements are migrated into maintained project documentation.

## Repository layout

- `api/` — FastAPI service and service tests.
- `admin/` — React/TypeScript administration portal (not started).
- `ios/` — SwiftUI/AVKit iPad application (not started).
- `infra/` — local and hosted infrastructure configuration.
- `tests/` — cross-system fixtures and fault-injection assets.
- `docs/` — architectural decisions, threat model, and operating documentation.
- `.github/workflows/` — CI definitions, including a future real macOS Xcode lane.

## Current executable slices

The Phase 0 API exposes dependency-free process liveness and dependency-aware readiness. PostgreSQL and local S3-compatible storage are defined under `infra/`; no production credential is required or permitted.

```powershell
cd api
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install --require-hashes -r requirements-dev.lock
.\.venv\Scripts\python.exe -m pip install --no-deps -e .
.\.venv\Scripts\python.exe -m pytest
.\.venv\Scripts\python.exe -m uvicorn allfab_api.main:app --reload
```

See `infra/README.md` for the local PostgreSQL and S3-emulator commands. A working Linux container engine is required for live dependency verification.

No customer video, credential, device identifier, signing asset, or production configuration belongs in this repository.
