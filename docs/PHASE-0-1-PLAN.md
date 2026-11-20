# Phase 0 and Phase 1 Task Plan

This plan decomposes the handoff into bounded, independently testable increments. A later increment cannot be reported complete using only planned tests.

## Phase 0 — repository and feasibility

1. **Repository foundation and API liveness**
   - Establish service boundaries, local setup documentation, isolated Python packaging, and a dependency-free `/healthz` contract.
   - Gate: install and test commands pass on Windows.
2. **Local service dependencies**
   - Add PostgreSQL and S3-compatible development storage through Docker Compose, secret-free examples, health checks, and documented startup/teardown.
   - Gate: clean startup exposes healthy local dependencies without production credentials.
3. **API readiness and seed fixture**
   - Add configuration, database migration baseline, a dependency-aware `/readyz`, and synthetic seed metadata.
   - Gate: liveness remains healthy during dependency failure; readiness reports the failure accurately.
4. **Synthetic media fixtures and validation probe**
   - Generate original short H.264/AAC test videos and invalid/truncated/hash-mismatch variants without company content.
   - Gate: hashes and media properties are reproducible and documented.
5. **CI and feasibility records**
   - Add backend checks, secret scanning, dependency review, architecture/threat records, and a macOS workflow placeholder that becomes mandatory only when an Xcode project exists.
   - Gate: implemented lanes run successfully; unavailable Apple/company evidence stays explicitly `NOT RUN`.

## Phase 1 — catalog and versioned server

1. Relational schema and migrations for categories, videos, immutable versions, app devices, one-use enrollment tokens, admin identities, and audit events.
2. One-use device enrollment and revocable/rotatable device credentials, with hashed enrollment tokens and Keychain-compatible response semantics.
3. Published catalog with stable cursor/ETag behavior and immutable version manifests.
4. Media upload finalization that derives length, SHA-256, codec, duration, and dimensions server-side before publication.
5. Authorized, short-lived download URL issuance that verifies device, video/version relationship, publication state, and permission.
6. Publish, retire, and rollback semantics that never mutate an earlier version object.
7. Contract and failure tests for unauthorized access, token reuse/expiry, malformed media, stale revisions, storage failures, and audit events.

## Decisions intentionally deferred

- Production cloud provider, domain, budget, and administrative identity provider.
- Oldest supported iPadOS version, pending actual fleet inventory.
- Apple signing, private Custom App submission, and Mosyle assignment.
- Forced local deletion, mandatory downloads, and category subscriptions.
