# ADR 0002: Local dependencies and readiness semantics

- **Status:** Accepted
- **Date:** 2026-11-17

## Context

The API requires PostgreSQL and private S3-compatible object storage, but process liveness must remain distinguishable from dependency availability. Local development needs reproducible, non-production services and must not depend on company credentials. The Windows workstation initially has no Linux container runtime because firmware virtualization is disabled and WSL2 is absent.

## Decision

- `GET /healthz` is process-only and returns HTTP 200 without opening network connections.
- `GET /readyz` concurrently probes PostgreSQL with `SELECT 1` and object storage with authenticated `HeadBucket`. It returns HTTP 200 only when both are ready; otherwise it returns HTTP 503 with dependency names and coarse `ready`/`unavailable` states. Exception text, URLs, and credentials are never serialized.
- FastAPI-generated `/openapi.json` is the authoritative HTTP contract. Tests verify the 200 and 503 response schema and serialized behavior before future clients generate types from it.
- Local PostgreSQL uses the pinned `postgres:18.7-alpine3.23` image and mounts its named volume at the PostgreSQL 18 parent data path, `/var/lib/postgresql`. Local S3 behavior uses the pinned `localstack/localstack:4.11.1` image with only the S3 service enabled and an idempotent bucket initializer. Production storage remains provider-configurable and is not constrained to LocalStack.
- Service ports bind only to `127.0.0.1`. Named volumes persist local data. Checked-in credentials are explicitly public development values, never production secrets.

## Consequences

- An orchestrator or operator can tell a live-but-degraded API from a dead process.
- Automated tests can inject probes without requiring containers, while live integration still requires a working Linux container engine.
- Boto3 and asyncpg are direct API dependencies for the initial probes; later database work may consolidate PostgreSQL access behind the selected migration/ORM layer.
- Compose syntax and image manifests can be checked before virtualization is enabled, but successful container startup and live dependency readiness must remain `NOT RUN` until WSL2/Docker is operational.
