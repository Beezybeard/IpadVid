# All Fab Video Library — Codex Development Handoff

**Prepared:** 17 November 2026
**Intended reader:** OpenAI Codex running on Windows, with an existing Everything Claude Code (ECC) installation.
**Status:** Implementation-ready requirements and architecture handoff; **this package is not a compiled app or working backend**.

## Goal
Build a **native iPad app** for seven existing All Fab, Inc. supervised iPads (expanding gradually toward ~25) that lets employees discover company-hosted training videos, **select specific videos to download**, and play verified local copies **natively and completely offline**. Build a small secure web admin portal and sync backend. Keep employees' Apple Accounts unnecessary. Ultimately distribute privately using Apple Business and the existing **Mosyle** MDM, with company administrator assistance.

## Facts confirmed with the requester
- Seven company-owned iPads, supervised and managed by All Fab via **Mosyle**; no Apple Account signed in on each iPad.
- User does **not** have Mosyle administrator access; obtain deployment help later, **not** before coding.
- Development machine(s) are **Windows only**; use a hosted macOS runner for Apple compilation and simulator tests.
- Some iPads have **32 GB**, foreman iPads have **256 GB**.
- Videos are typically **five minutes or less**, at most roughly **ten minutes**, with standard **1080p** source quality.
- Most users need **only a few videos at a time**, so **per-video selective sync** is the default.
- No multiple video quality options, streaming quality variants, or transcoding pipeline in MVP.
- An earlier YouTube playlist/Web Clip was abandoned and is **not** the media source or product baseline.
- ECC is **already installed**; DO NOT reinstall/duplicate its hooks, skills, or config.

## Read in this order
1. `AGENTS.md` — persistent constraints for Codex.
2. `01 Product and User Experience.md` — what the app must do.
3. `02 Architecture and API Contract.md` — design, offline sync state machine, backend, schema, security.
4. `03 Codex and ECC Responsibilities.md` — role ownership and when to invoke ECC.
5. `04 Verification and Acceptance Tests.md` — objective tests and physical-device sign-off.
6. `05 Implementation Phases.md` — staged work with completion criteria.
7. `06 Windows Build and Apple Deployment.md` — macOS CI and later Mosyle release.
8. `07 Security and Operational Policies.md` — security/storage/device lifecycle.
9. `08 Decisions, Assumptions, and Open Dependencies.md` — don't silently invent company policy.
10. `09 Codex Kickoff Prompt.md` — first prompt to paste into Codex.

## Project deliverables expected from Codex (not present yet)
- `/ios` SwiftUI iPad application: browse/catalog, video detail, download manager, native offline player, local search, sync status, settings.
- `/api` FastAPI backend: device enrollment, catalog, media version manifests, signed download authorization, admin CRUD, audit events.
- `/admin` React + TypeScript browser management portal.
- `/infra` local Docker Compose setup, environment templates, deployment documentation.
- `/tests` fixtures, contract tests, failure injection, automated backend and admin UI tests.
- `/.github/workflows` macOS iOS build/tests and backend/admin continuous integration.
- Installation, operations, release, recovery and diagnostic instructions.

## MVP non-goals
- YouTube downloads or playlist integrations; video transcoding/quality selection; user analytics/employee tracking; complex enterprise identity management; automatic bulk synchronization of all videos; DRM or promises of copy-proof storage; an MDM replacement; guaranteed scheduled background updates; in-app editing/recording of video.

## Foundational operating rule
**Codex implements; ECC organizes/reviews; tests prove behavior; GitHub Actions compiles on macOS; the company MDM administrator performs device distribution.** Don't blur these responsibilities.
