# 04 — Objective Verification and Release Acceptance

## Testing philosophy
The app must pass tests based on independently observable behavior, not claims by an agent. Since the developer uses Windows, split automation into Windows/Linux tests and macOS CI tests; complete release gates on **real iPad hardware**.

## Test layers
1. **Python tests (Windows/Linux):** API contracts, permissions, PostgreSQL migrations, upload validation, catalog version semantics, signed URL issuance, revocation, bad data.
2. **Web tests (Windows/Linux):** React unit tests and Playwright for admin authentication, uploading, rejecting incompatible files, publishing revision updates, retaining history, revocation.
3. **Swift pure-unit tests (hosted macOS):** state machine, SQLite migrations, local catalog selection, hashing, temporary path promotion, storage reservation calculation.
4. **iOS simulator integration tests (hosted macOS):** UI tests, native player opening fixture MP4, local catalog after simulated offline API, sync readiness, app relaunch after pending tasks where simulator supports it.
5. **Real managed iPad acceptance (human / authorized tester):** airplane-mode native playback, app force-quit/relaunch, low-space behavior on a 32 GB device, supervised installation, and background-task limitations.

## Canonical synthetic test videos
Codex should generate original non-customer fixtures (for example using FFmpeg test patterns and synthetic sound): a 5–10-second MP4 H.264/AAC, a 10-second changed-content revision with different SHA-256, an invalid file, a deliberately truncated file and a version with deliberately wrong advertised checksum. Do not put All Fab training material or customer IP in tests.

## Mandatory acceptance matrix

| ID | Test | Expected outcome | Automated / on-device |
|---|---|---|---|
| A01 | Install fresh app, initially online | Can complete device pairing and fetch catalog without Apple Account | integrated + device |
| A02 | Select one MP4, finish download | Verified bytes/hash, `Ready Offline` shown, file in app-private persistent storage | Swift integration + device |
| A03 | Disconnect all internet and relaunch | Cached catalog/search and local playback work; no authentication blocker | simulator + device **required** |
| A04 | Scrub/play/pause/rotate offline | Native AVKit playback, no request for remote media | device required |
| A05 | Select three videos, download two | Readiness correctly reports `2 of 3 ready`, identifies pending item | unit + UI |
| A06 | Lose network in middle of transfer | No false `Ready`; recover/retry after reconnect; no corrupted active file | fault injection + device |
| A07 | Publish revision B while revision A downloaded | A remains playable during B fetch; B takes over only after verified promotion | Swift + API + device |
| A08 | New B transfer corrupted/sha mismatch | Reject B, remove only staged bytes, A still playable and recorded | automated |
| A09 | Kill app during update / hard reset scenario | On relaunch, active valid file remains; staging reconciled without data loss | simulator + device |
| A10 | 32 GB iPad, insufficient free space | Download refused safely with clear message; no deletion of existing videos | unit + physical 32 GB |
| A11 | Remove downloaded video | Deletes local MP4, keeps online catalog listing; re-download works | automated + device |
| A12 | Catalog endpoint unavailable | Cached offline catalog/player works, sync shows error without destructive cleanup | automated + device |
| A13 | Unauthenticated download signing request | Server returns 401/403, no private URL/media disclosed | API |
| A14 | Revoked device attempts refresh/catalog/signing | Denied online; previously downloaded files behave per documented offline policy | API + device |
| A15 | Reuse expired/used pairing token | Denied; no impersonation or enrollment duplication | API |
| A16 | Upload malicious/malformed media | Server rejects publish, retains prior version, emits safe admin error | API + E2E |
| A17 | Expired signed URL mid-sync | Retry obtains new URL when connected; previous verified offline copy remains | integration |
| A18 | Force quit after initiating background transfer | No promise of continuation; app accurately resumes or retries at next foreground launch | device required |
| A19 | Admin tries media action with lower privilege | Authorization denied and audit logged, not merely button hidden | API |
| A20 | Release via supervised, accountless iPad | Managed app installs and runs without per-user Apple Account; MDM admin confirms license assignment | actual Mosyle pilot |

## Contract test examples
- Publishing revision must not mutate old object key/hash or invalidate previous active local version.
- One device cannot enumerate another device's refresh token or issue signing URLs outside authorization.
- Catalog pagination/version cursor stable and idempotent; unchanged catalog does not re-download media.
- Upload validation compares content-derived length/hash/format; does not trust browser metadata.
- Admin retiring a video does not claim instant purge from devices offline for weeks.
- No `Ready Offline` state exists when local file is absent, truncated or fails integrity validation.

## Fault-injection harness requirements
Include a local test proxy/emulator or API stub capable of: 200/206/401/403/404/409/429/500 responses; disconnect after N bytes; slow network; chunk stalls; signed URL expiration; hash mismatch; content length mismatch; server outage; duplicate/out-of-order catalog revisions; interrupted upload. Cover both initial download and update; log transitions in structured traces excluding credentials.

## Coverage/gates
- Target >=80% statement/branch coverage for critical backend sync/auth and pure Swift state logic **where tooling makes it measurable**, with all explicitly enumerated acceptance paths tested; percentages alone aren't a release gate.
- Every iOS PR must produce an actual Xcode build result from macOS CI. Test failures block merge.
- No production release with critical/high unresolved security findings, known downloaded-file corruption, or offline playback failure.
- Do not mark physical-device-only tests passed using simulator output. Track `NOT RUN — requires physical device` until completed.

## Manual pilot checklist
On one actual supervised iPad: confirm install, enrollment, selected download, wifi removal, airplane-mode full native playback and seeking, app cold-start offline, local search, next-day update with old version retained during download, storage free margin, app update preserving files, and eventual revoke/remove behavior. Repeat the storage-sensitive subset on one 32 GB device. Record model, iPadOS version, app version, fixture video hashes and outcomes; omit device serial numbers from public logs.
