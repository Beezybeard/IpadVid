# Codex Operating Instructions — All Fab Video Library

You are the principal developer coordinating a production-minded, small-scale All Fab iPad offline-video project. Read the other handoff files before any major implementation.

## Non-negotiable product behavior
1. The offline catalog, search of cached metadata, native AVKit playback and previously verified local MP4s MUST function with no network connection and without a fresh sign-in.
2. Users deliberately select per-video downloads. Never pre-download the entire catalog. An optional category-subscription feature may be implemented later; retain an extension point.
3. Once successfully downloaded, a working video is never replaced by an incomplete or corrupt version. Stage updates, verify size and SHA-256, then atomically switch local references; delete old bytes only after successful activation.
4. Keep videos in persistent app-private files, NOT temporary/caches. Exclude recreatable large files from iCloud/device backups. Do not export to Files by default. Make no claim of DRM.
5. Never delete a user-selected valid downloaded video due to failed synchronization, an unreachable server, or normal cache cleanup. Explicit user removal and clearly defined authenticated admin retention/wipe policy are separate cases.
6. Videos are normal, single-rendition MP4 H.264/AAC, typically 1080p and <=10 minutes. No 720p/1080p selector or transcoding service in MVP.
7. Detect available storage, enforce a cautious OS free-space reserve and preflight download/update staging. Do NOT assume 256 GB on every iPad; some have 32 GB.
8. Background URLSession transfers are best-effort and may be canceled by force-quitting. Offer an explicit foreground **Sync Before Leaving** workflow that verifies all selected downloads.
9. All app releases require a macOS Xcode build. The user works on Windows; use GitHub Actions macOS runners or an agreed cloud Mac build. Never claim Windows can run Xcode/iPad simulator.
10. The user does not control Mosyle. Build and test independently; document Apple Business/Mosyle and Apple Developer actions needed from an authorized company administrator.

## Working method
- Codex owns implementation and task orchestration. ECC is already installed and should be used selectively for planning, TDD, review and security checks if accessible in the Codex environment. Detect ECC access before invoking it; never reinstall ECC or overwrite global Codex settings automatically.
- Begin with the current phase in `05 Implementation Phases.md`; maintain `IMPLEMENTATION STATUS.md` with work completed, failing tests, limitations, and next step.
- For each increment: state acceptance criteria -> produce failing regression test when feasible -> implement -> run local tests -> seek review -> run CI on macOS if iOS was changed -> summarize real outcomes with evidence.
- Implement only one bounded milestone/vertical slice at a time. Do not generate a huge untestable codebase in one pass.
- For all security-sensitive changes, invoke ECC security review or equivalent independent review. Never treat the agent's self-assessment as a replacement for automated tests.
- Do not invent API names, use unsupported Apple background modes, hard-code secrets, or claim CI passed without running it.
- If a command or ECC skill is missing, use its documented equivalent instead of silently assuming a command exists.
- Keep company/customer videos, proprietary procedures, credentials, device enrollment keys and real employee identifiers out of public repos, mocks and CI artifacts.
- Never work around Mosyle/MDM restrictions or bypass Apple signing/distribution requirements.

## Preferred stack
- iPad: Swift / SwiftUI, AVKit / AVPlayer, Foundation URLSession background configuration, SQLite (via appropriate lightweight library), Keychain secrets.
- Backend: Python FastAPI, PostgreSQL, S3-compatible object storage, SQL migrations.
- Admin: React + TypeScript, straightforward accessible UI and role-based access.
- Local development: Docker Compose, mock/seed synthetic video assets, pytest, Playwright.
- CI: GitHub Actions on Windows/Linux for server/admin checks and macOS for Xcode builds and Swift tests.
- These are defaults. Document any substantial deviation and its tradeoffs before implementation.

## Quality gate
A feature is not done because it compiles; it is done only when its documented positive AND failure-path tests pass. A final release requires physical-device offline playback verification, storage-low recovery, interrupted-update protection and admin-backed authorization checks.

## Reference documents
Keep product and API contracts in the files from this handoff until implemented. Then migrate the definitive contracts into maintained repo docs, preserving the decision history.
