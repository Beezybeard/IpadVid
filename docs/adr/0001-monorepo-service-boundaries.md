# ADR 0001: Monorepo with explicit service boundaries

- **Status:** Accepted
- **Date:** 2026-11-17

## Context

The product combines a native iPad application, a web administration portal, an HTTP API, relational storage, object storage, cross-system fixtures, and platform-specific CI. The team is small and needs coordinated API-contract changes without conflating runtime responsibilities.

## Decision

Use one private Git repository with top-level `ios`, `api`, `admin`, `infra`, `tests`, and `docs` boundaries. Each application owns its dependencies and tests. Cross-system contract fixtures live under `tests`. CI uses separate server, admin, and iOS lanes.

The API liveness endpoint is process-only. Dependency health belongs in a separate readiness endpoint so an unavailable database cannot hide whether the API process itself is running.

## Consequences

- Contract changes can be reviewed atomically across clients and server.
- Each runtime remains independently buildable and deployable.
- The repository requires careful CI path filters and cannot treat one language's tooling as proof for another.
- Windows can validate server/admin work, but iOS completion always requires a real macOS Xcode result.
