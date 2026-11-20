# 05 — Phased Codex Implementation Plan

**Approach:** One small, testable vertical slice at a time, each concluded by regression tests, peer-style ECC review where available, and a recorded status. Avoid building backend, admin and iPad in one monolithic pass.

## Phase 0 — Repository and feasibility gates
**Build:** Private git repository; `/ios`, `/api`, `/admin`, `/tests`, `/infra`, `/docs`, `.github/workflows`; `README.md`; `.gitignore`; `AGENTS.md` from this handoff; `IMPLEMENTATION STATUS.md` and architectural decision records. Check installed Codex + ECC integration without reinstalling ECC. Create secret-free local demo video fixtures.

**Verify:** Repo boots developer environment on Windows; backend health check and seed data reachable; initial security threat model; hosted macOS runner available; no false claims about Apple signing access. Record open admin dependencies.

**ECC:** Planner/architect at outset; reviewer on initial architecture.

**Exit:** local developer onboarding works without production credentials. CI skeleton is green for what is actually implemented; iOS compilation gate configured once an Xcode project exists.

## Phase 1 — Catalog + versioned server
**Build:** PostgreSQL schema/migrations; categories; video and immutable version metadata; service-side media validation using ffprobe/hash; safe authorizations; synthetic seed data; published catalog endpoint; device enrollment with one-use token mechanism; signed download URLs; audit log.

**Verify:** API contract tests cover lifecycle, bad tokens, unauthorized downloads, publishing/retirement, immutable versions, invalid media, stale version queries, and responses from outage simulation.

**ECC:** TDD workflow throughout; security review on pairing/tokens/download signing; reviewer at merge.

**Exit:** A test client can enroll, list the catalog, request a permitted file, verify its SHA-256, and observe revision changes.

## Phase 2 — Bare-minimum native iPad proof
**Build:** Actual compilable SwiftUI Xcode project; local SQLite; cached catalog; small video details screen; `Download` action; private persistent file storage; AVKit local player; no connectivity requirement after successful download.

**Verify:** Hosted macOS CI builds; unit tests + simulator integration confirm first verified download then offline local playback with synthetic MP4. Use a real device as soon as provisioning allows, but continue independent development without pretending that provisioning exists.

**ECC:** Architect reviews file lifecycle first; TDD for state machine; reviewer after CI results.

**Exit:** A proof that can download one video and play it with API disabled, using a real local file URL.

## Phase 3 — Resilient selective-sync engine
**Build:** Persistent download jobs; background URLSession; app lifecycle reconnection; SHA-256/length verification; atomic update switch; rollback/restart; retry/cancel; free-space reservation; `Sync Before Leaving` readiness summary; multiple selected videos; network error UX.

**Verify:** Fault injection for interruptions, bad hash, low storage, expired URL, app restart during update, old-version protection; macOS CI and physical-device tests assigned distinct statuses.

**ECC:** TDD + verification-loop for each failing scenario; security review on filesystem/credentials.

**Exit:** All automated update-and-recovery acceptance tests pass and the physical device acceptance sheet shows either pass or explicit pending dependencies.

## Phase 4 — Administration portal
**Build:** Admin authentication/authorization; upload/validate/reject flow; category/tag editing; metadata; version history; publish/retire/restore policy; enrollment code creation and device revocation; minimal usage-free operational diagnostics.

**Verify:** Playwright and API tests cover admin happy/failure paths, permission enforcement, invalid media, revision propagation, and audit trails. Non-admin users cannot call privileged endpoints.

**ECC:** Planner/UX review where useful, e2e-testing, security-review, code-reviewer.

**Exit:** All routine content management can occur from a normal authorized Windows browser; no server shell access required.

## Phase 5 — Integrated reliability + operational hardening
**Build:** Key rotation; secure secrets/configuration; HTTPS deployments; DB/object backup and restore runbooks; health/metrics (no watch-history tracking); safe rollback; performance and storage constraints; app startup migration and recovery.

**Verify:** Whole-system integration tests, concurrency checks, penetration-style auth tests, app update preserving content, no private information in logs, upload and object-store failure recovery, operational DR drill.

**ECC:** Architect + security reviewer + verification-loop.

**Exit:** documented release checklist with no critical/high unresolved issues, reproducible hosted build and repair path.

## Phase 6 — Company iPad pilot and rollout
**Build:** With permission, obtain Apple Developer team access and company Apple Business Custom App account assignment; sign/review app; Mosyle admin installs to one managed iPad; confirm test plan; install on other six.

**Verify:** No personal Apple Account on iPad; native offline launch/playback, storage, updates, app version updates and removal; test specifically on one 32 GB device and one larger foreman device.

**ECC:** Final independent reviewer and security readiness check; project owner and MDM administrator sign off.

**Exit:** Seven supervised production iPads receive signed private app through authorized company process and have documented support ownership.

## Backlog beyond initial release (only after MVP is proven)
- Optional category subscriptions with auto-queue for newly published category content.
- Admin-assigned mandatory offline training set with explicit device/group targeting and space constraints.
- Advanced multilingual metadata/captions.
- Device-specific storage soft limits if usage patterns justify them.
- Cloud-backed recovery of selections, if necessary.

## Development evidence
For every phase, Codex updates `IMPLEMENTATION STATUS.md` with issue/phase, changed files, test commands/results, hosted build link, ECC role used or unavailable, blockers, regressions and next bounded milestone. Never record an acceptance test as `passed` if only a test plan was written.
