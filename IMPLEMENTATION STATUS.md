# Implementation Status

**Updated:** 2026-11-20

**Current phase:** Phase 1 — catalog and versioned server; Phase 2 iPad shell implementation

**Current milestone:** Enrollment and Keychain session startup, refresh rotation, and authenticated identity validation authored; this slice is pending macOS CI verification

## Milestone acceptance

- [x] Repository has explicit `api`, `admin`, `ios`, `infra`, `tests`, `docs`, and CI boundaries.
- [x] API package installs and builds in an isolated Python 3.12 environment on Windows.
- [x] `GET /healthz` is process-only and never invokes dependency probes.
- [x] `GET /readyz` returns HTTP 200 only when PostgreSQL and object storage are ready.
- [x] Dependency failure, timeout, and exception paths return a redacted HTTP 503 response.
- [x] FastAPI-generated OpenAPI documents the same typed 200 and 503 response contract.
- [x] A pinned, loopback-only PostgreSQL and S3-emulator Compose model validates without production credentials.
- [x] Runtime and development dependencies are hash-locked and vulnerability-audited.
- [x] Live Compose API, PostgreSQL and object storage start healthy; `/readyz` returns HTTP 200 when dependencies are ready and redacted HTTP 503 during the PostgreSQL outage test.
- [x] Versioned SQL migrations create catalog entities and safe synthetic category metadata; migration rerun is idempotent against live PostgreSQL.
- [x] Device enrollment contract, one-use/expiry, hashed credential storage, refresh rotation/replay rejection, revocation, and concurrent duplicate handling are verified against isolated PostgreSQL and the live local stack.

## Work completed

- Read the complete handoff and initialized a Git repository on branch `main`.
- Added the approved iPad foundation: an iPadOS 17+ SwiftUI shell, pinned XcodeGen project definition, unsigned simulator CI workflow, and Swift Testing/XCTest targets. Added an enrollment form and typed device client for enrollment, refresh-token rotation, and authenticated `/v1/devices/self` validation. Credentials persist in Keychain; startup refreshes expired access tokens, rejects revoked/identity-mismatched sessions, and preserves local library access when server validation is unavailable. Added unit tests for enrollment, invalid input/code, persistence failure, refresh rotation, revocation, and offline restore. This new session-restoration slice is pending macOS CI verification.
- Docker Desktop's Linux engine is available in the current environment. Built and ran the API with Docker Compose alongside PostgreSQL and LocalStack; the earlier note that the WSL2 engine could not start is superseded by this live verification.
- Confirmed Python 3.12.1, Node 26.13.1, npm 11.20.0, and FFmpeg/FFprobe are available.
- Added repository boundaries, onboarding documentation, Phase 0/1 plan, initial threat model, and ADRs for repository boundaries and readiness semantics.
- Implemented the FastAPI application factory, typed operational schemas, injected readiness service, PostgreSQL `SELECT 1` probe, and authenticated S3 `HeadBucket` probe without import-time network connections.
- Added exact-tag Compose services for `postgres:18.7-alpine3.23` and `localstack/localstack:4.11.1`, a PostgreSQL 18-correct parent data-volume mount, an idempotent S3 bucket initializer, named volumes, health checks, and loopback-only port publishing.
- Added a multi-stage, non-root API Docker image using the hash-locked runtime dependency file, a Docker build context exclusion list, and a Compose API service gated on healthy PostgreSQL and object storage.
- Added a transactional numbered-migration runner, command-line migration entrypoint, and initial catalog schema for categories, videos, immutable video versions, category/tag associations, constraints, and synthetic categories. The container applies migrations before starting Uvicorn.
- Implemented and verified device enrollment: migration `002_device_enrollment.sql`, opaque hashed one-use codes/tokens, PostgreSQL enrollment/refresh/authentication/revocation adapter, `/v1/devices/enroll`, `/v1/devices/token/refresh`, and authenticated `/v1/devices/self`. A local CLI can issue and revoke credentials; there is no unauthenticated administrative issuance endpoint. Migration runners serialize through a transaction-scoped PostgreSQL advisory lock.
- Added public local-development configuration examples; real `.env` files, signing material, media, and secrets remain ignored.
- Added hash-locked runtime and development dependency files and repeatable build, type, lint, test, and audit commands.

## TDD and contract evidence

- Original liveness test failed before implementation with `ModuleNotFoundError: No module named 'allfab_api.main'`, then passed.
- Readiness tests failed before implementation with `ModuleNotFoundError: No module named 'allfab_api.services'`, then passed.
- FastAPI-generated `/openapi.json` is the authoritative HTTP boundary artifact. Tests assert the `ReadinessResponse` schema for HTTP 200 and 503 and verify actual serialized happy/failure responses.
- Enrollment RED evidence was one failing migration assertion, one Ruff import-order failure, and 13 Pyright errors. The corrected tree passes the same migration test, Ruff, and Pyright; real PostgreSQL tests cover concurrent migrators, duplicate code redemption, refresh replay, hash-only persistence, expiry, authentication, and revocation.

## Verification evidence

- `python -m build`: **passed**, source distribution and wheel produced locally; artifacts are ignored.
- `python -m pyright`: **passed**, 0 errors and 0 warnings.
- `python -m ruff check .`: **passed**.
- `python -m ruff format --check .`: **passed**.
- Current combined `python -m pytest` with an isolated PostgreSQL test database: **29 passed**, **86% measured statement coverage**. Without `ALLFAB_TEST_DATABASE_URL`, the deterministic unit suite reports **26 passed, 3 skipped**.
- `python -m pip check`: **passed**, no broken requirements.
- `python -m pip_audit`: **passed**, no known vulnerabilities in the environment; the unpublished local package was correctly skipped.
- `python -m pip_audit -r requirements.lock` and `requirements-dev.lock`: **passed**, no known vulnerabilities.
- Hash-locked development install dry run: **passed**.
- Live host Uvicorn smoke test without configured dependencies: `/healthz` **HTTP 200**; `/readyz` **HTTP 503** with both dependency states `unavailable` and no exception details.
- `docker compose --env-file infra/.env.example -f infra/compose.yaml config --quiet`: **passed**; rendered configuration confirms the PostgreSQL volume target is `/var/lib/postgresql` as required by the version 18 image layout.
- `docker compose --env-file infra/.env.example -f infra/compose.yaml up -d --build --pull always --wait`: **passed** after building the API image; API, PostgreSQL and LocalStack all reported healthy.
- Historical pre-enrollment evidence remains **18 tests passed** with **89% coverage**; it has been superseded by the current combined enrollment result above.
- Live database migration verification now records `001_catalog` and `002_device_enrollment`; the enrollment tables exist and migration reruns are serialized/idempotent.
- Live enrollment smoke flow: issue code through the local CLI, enroll **HTTP 200**, authenticate **HTTP 200**, rotate refresh **HTTP 200**, refresh replay **HTTP 401**, code reuse **HTTP 401**, revoke, then access/refresh both **HTTP 401**. Stored device-token values were all 64-character hashes; raw credentials were not printed in verification output.
- Live Compose endpoint checks: `/healthz` **HTTP 200** and `/readyz` **HTTP 200** with PostgreSQL and object storage ready.
- PostgreSQL outage injection: `/healthz` stayed **HTTP 200**; `/readyz` returned redacted **HTTP 503** with PostgreSQL unavailable and object storage ready. After PostgreSQL restart, `/readyz` returned **HTTP 200** and both dependencies reported ready.
- `docker manifest inspect` for both pinned images: **passed**.
- Git Bash syntax check for `infra/localstack/init/10-create-bucket.sh`: **passed**.
- Secret-pattern scan: **0 matches**; unignored real `.env` files: **0**.
- Free disk during ECC delivery check: approximately **1,092 GB**.
- The API's pre-existing Windows `.venv` references a Python installation that is no longer present. Containerized Python 3.12 provided a clean environment for the passing test suite and live dependency checks.
- iPad host-side validation for earlier enrollment slice: `Info.plist` parses as XML; `ios/project.yml` parses as YAML using the running API container's Python; `git diff --check` passes. The prior macOS CI run for commit `076de5f` passed XcodeGen project generation, simulator build, unit tests, and UI tests. The newer session-restoration slice is not yet verified; this Windows host has no Swift/Xcode toolchain.

## ECC roles used

- `ecc:contract-first` — OpenAPI ownership, explicit 200/503 behavior, and provider response verification.
- `ecc:docker-patterns` — exact image tags, loopback exposure, named volumes, health checks, development-only credentials, and Compose validation.
- `ecc:fastapi-patterns` — typed response models, thin routes, service injection, settings, and testable external adapters.
- `ecc:security-review` — credential handling, input/config validation, redacted errors, dependency audit, and secret scan.
- `ecc:verification-loop` and `ecc:delivery-gate` — build, type, lint, coverage, security, diff, and target-environment separation.
- `ecc:orch-build-mvp`, `ecc:swiftui-patterns`, `ecc:swift-concurrency-6-2`, `ecc:swift-actor-persistence`, and `ecc:swift-protocol-di-testing` — approved vertical-slice plan and the initial native-app architecture boundary.

No critical or high security finding remains in this slice. The checked-in credentials are explicitly public emulator/development values and must never be reused outside the loopback-only local stack.

## Xcode / physical-device evidence

- XcodeGen project generation: **NOT RUN — the source specification exists, but XcodeGen is intentionally executed by macOS CI.**
- Xcode build and Swift tests: **NOT RUN — Xcode is unavailable on Windows; `.github/workflows/ios-ci.yml` must run on its pinned macOS/Xcode image before this evidence exists.**
- Simulator UI tests: **NOT RUN — the test target is authored but has not run.**
- Physical iPad acceptance: **NOT RUN — requires a provisioned physical device in later phases.**

## Known limitations and dependencies

- The containerized API and local dependencies now pass live readiness and outage-recovery checks. The Windows host `.venv` is stale; use the documented container workflow or recreate the virtual environment from the hash-locked requirements if host-run development is needed.
- Docker Desktop is proprietary software. Any first-launch subscription terms must be reviewed and accepted only by an authorized owner/company representative.
- Live container startup, live PostgreSQL/S3 probes, and PostgreSQL outage/recovery transitions are verified. Long-term persisted-volume survival across destructive/recreate scenarios and object-storage outage injection remain unverified.
- GitHub remote/private repository and hosted macOS runner are not configured.
- The user supplied repository-local Git author identity. The baseline and iPad scaffold commits exist; the repaired enrollment changes remain uncommitted pending review and the next commit gate.
- Enrollment and refresh endpoints do not yet have application-level rate limiting. Keep the local stack loopback-only; production exposure requires an approved HTTPS ingress/gateway rate-limit policy or an explicitly designed shared limiter.
- Apple Developer, Apple Business, and Mosyle access remain later organizational dependencies.

## Codex handoff — immediate next actions

The app has a typed enrollment API, Keychain-backed credentials, and now an authored session restoration/refresh/identity check slice. The prior iOS CI passed on commit `076de5f`; the current local changes require a new CI run before treating session restoration as verified. The catalog API is not implemented yet, so do not build catalog UI against a fabricated endpoint. The configured API URL defaults to loopback for local development; physical-device access requires an approved reachable HTTPS endpoint and must not be enabled through a broad insecure transport exception. Next after CI passes: implement the authenticated catalog contract/backend first, then add the iOS typed catalog client and tests.

The enrollment backend prerequisite is verified locally. Keep code issuance local-CLI-only pending an approved administrator authentication design; do not add an unauthenticated issuance route. Before production exposure, resolve rate limiting and HTTPS deployment policy. The next bounded app task is the typed iOS enrollment client and Keychain-backed session boundary, but XcodeGen generation, compilation, unit tests, and UI tests still require the unconfigured macOS CI runner. The catalog endpoint, upload validation, signed media authorization, verified download, and AVKit playback remain unimplemented.
