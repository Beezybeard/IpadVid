# Implementation Status

**Updated:** 2026-11-20

**Current phase:** Phase 0 — repository and feasibility gates

**Current milestone:** Local dependencies and dependency-aware readiness — implementation complete; live container validation blocked by Windows servicing policy/state

## Milestone acceptance

- [x] Repository has explicit `api`, `admin`, `ios`, `infra`, `tests`, `docs`, and CI boundaries.
- [x] API package installs and builds in an isolated Python 3.12 environment on Windows.
- [x] `GET /healthz` is process-only and never invokes dependency probes.
- [x] `GET /readyz` returns HTTP 200 only when PostgreSQL and object storage are ready.
- [x] Dependency failure, timeout, and exception paths return a redacted HTTP 503 response.
- [x] FastAPI-generated OpenAPI documents the same typed 200 and 503 response contract.
- [x] A pinned, loopback-only PostgreSQL and S3-emulator Compose model validates without production credentials.
- [x] Runtime and development dependencies are hash-locked and vulnerability-audited.
- [ ] Live containers start healthy and make `/readyz` return HTTP 200 — **BLOCKED: WSL2 and Docker Desktop are installed, but Windows has not deployed the Virtual Machine Platform compute-host payload because a servicing transaction remains pending and local policy disables Windows Update.**

## Work completed

- Read the complete handoff and initialized a Git repository on branch `main`.
- Installed missing Git, Docker CLI 29.10.0, and Docker Compose 5.7.2 through Scoop. On 2026-11-20, installed WSL 3.0.5 with WSL2 as the default and Docker Desktop 4.99.0. Two full Windows restarts completed. Elevated DISM commands enabled both required optional features, but Windows did not deploy or register the Hyper-V Host Compute Service (`vmcompute`) payload, so Docker Desktop cannot start its WSL2 engine.
- Confirmed Python 3.12.1, Node 26.13.1, npm 11.20.0, and FFmpeg/FFprobe are available.
- Added repository boundaries, onboarding documentation, Phase 0/1 plan, initial threat model, and ADRs for repository boundaries and readiness semantics.
- Implemented the FastAPI application factory, typed operational schemas, injected readiness service, PostgreSQL `SELECT 1` probe, and authenticated S3 `HeadBucket` probe without import-time network connections.
- Added exact-tag Compose services for `postgres:18.7-alpine3.23` and `localstack/localstack:4.11.1`, a PostgreSQL 18-correct parent data-volume mount, an idempotent S3 bucket initializer, named volumes, health checks, and loopback-only port publishing.
- Added public local-development configuration examples; real `.env` files, signing material, media, and secrets remain ignored.
- Added hash-locked runtime and development dependency files and repeatable build, type, lint, test, and audit commands.

## TDD and contract evidence

- Original liveness test failed before implementation with `ModuleNotFoundError: No module named 'allfab_api.main'`, then passed.
- Readiness tests failed before implementation with `ModuleNotFoundError: No module named 'allfab_api.services'`, then passed.
- FastAPI-generated `/openapi.json` is the authoritative HTTP boundary artifact. Tests assert the `ReadinessResponse` schema for HTTP 200 and 503 and verify actual serialized happy/failure responses.

## Verification evidence

- `python -m build`: **passed**, source distribution and wheel produced locally; artifacts are ignored.
- `python -m pyright`: **passed**, 0 errors and 0 warnings.
- `python -m ruff check .`: **passed**.
- `python -m ruff format --check .`: **passed**.
- `python -m pytest`: **15 passed**, 118/118 measured statements covered (100%).
- `python -m pip check`: **passed**, no broken requirements.
- `python -m pip_audit`: **passed**, no known vulnerabilities in the environment; the unpublished local package was correctly skipped.
- `python -m pip_audit -r requirements.lock` and `requirements-dev.lock`: **passed**, no known vulnerabilities.
- Hash-locked development install dry run: **passed**.
- Live host Uvicorn smoke test without configured dependencies: `/healthz` **HTTP 200**; `/readyz` **HTTP 503** with both dependency states `unavailable` and no exception details.
- `docker compose --env-file infra/.env.example -f infra/compose.yaml config --quiet`: **passed** without a daemon; rendered configuration confirms the PostgreSQL volume target is `/var/lib/postgresql` as required by the version 18 image layout.
- `docker manifest inspect` for both pinned images: **passed**.
- Git Bash syntax check for `infra/localstack/init/10-create-bucket.sh`: **passed**.
- Secret-pattern scan: **0 matches**; unignored real `.env` files: **0**.
- Free disk during ECC delivery check: approximately **1,092 GB**.
- Post-reboot platform diagnostics: physical Alienware m18 R2; `HypervisorPresent: True`; virtualization-based security running; both `VirtualMachinePlatform` and `Microsoft-Windows-Subsystem-Linux` report **Enabled**; Docker Desktop still reports the platform unavailable because `C:\Windows\System32\vmcompute.exe` and the `vmcompute` service are absent.
- Windows component-store scan: **passed**, no corruption detected. The correct `vmcompute.exe` payload exists in WinSxS, but CBS logged that the feature transaction was pended and not committed. SFC could not run because Windows reports a repair transaction pending.

## ECC roles used

- `ecc:contract-first` — OpenAPI ownership, explicit 200/503 behavior, and provider response verification.
- `ecc:docker-patterns` — exact image tags, loopback exposure, named volumes, health checks, development-only credentials, and Compose validation.
- `ecc:fastapi-patterns` — typed response models, thin routes, service injection, settings, and testable external adapters.
- `ecc:security-review` — credential handling, input/config validation, redacted errors, dependency audit, and secret scan.
- `ecc:verification-loop` and `ecc:delivery-gate` — build, type, lint, coverage, security, diff, and target-environment separation.

No critical or high security finding remains in this slice. The checked-in credentials are explicitly public emulator/development values and must never be reused outside the loopback-only local stack.

## Xcode / physical-device evidence

- Xcode build: **NOT RUN — no Xcode project exists yet; Windows cannot provide this evidence.**
- Physical iPad acceptance: **NOT RUN — requires a provisioned physical device in later phases.**

## Known limitations and dependencies

- Windows reports `HypervisorPresent: True`, confirming firmware virtualization is active. WSL 3.0.5 and Docker Desktop 4.99.0 are installed, the owner is an active member of `docker-users`, and Docker onboarding is complete. The remaining failure is Windows servicing, not firmware, Docker authentication, or repository code.
- Local Windows policy sets `DisableWindowsUpdateAccess=1`, `NoAutoUpdate=1`, `UseWUServer=1`, disables the `wuauserv` service, and points WSUS at two non-resolving placeholder hostnames. The computer is not domain- or Azure AD-joined but is workplace-joined. Changing those policies requires explicit owner/company authorization.
- Docker Desktop is proprietary software. Any first-launch subscription terms must be reviewed and accepted only by an authorized owner/company representative.
- Container startup, persisted-volume behavior, live PostgreSQL/S3 probes, and dependency outage transitions remain target checks, not inferred passes.
- GitHub remote/private repository and hosted macOS runner are not configured.
- No Git author name or email is configured, so no identity was invented and no commit was created.
- Apple Developer, Apple Business, and Mosyle access remain later organizational dependencies.

## Restart-safe next step

After the owner or authorized company administrator resolves the Windows Update policy:

1. Restore a valid Windows Update source/service configuration, complete the pending CBS transaction, and run SFC successfully. Do not silently override an intentional organizational policy.
2. Verify that `vmcompute` is installed, `wsl --status` succeeds, and `docker version` reports a Linux server engine.
3. Run Compose with `up -d --wait` using `infra/.env.example` copied to `infra/.env`.
4. Copy the same example to `api/.env`, start Uvicorn, and verify `/readyz` returns HTTP 200.
5. Stop PostgreSQL and object storage separately; verify `/readyz` returns redacted HTTP 503 while `/healthz` remains HTTP 200.
6. Restart services and confirm data/bucket persistence, then stop with `docker compose down` without deleting volumes.
7. Record the live evidence and begin the migration/seed-data milestone only after these checks pass.
