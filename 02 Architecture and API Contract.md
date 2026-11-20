# 02 — Architecture, Data Model, and API Contract

## High-level design

```text
+---------------------------+                +-------------------------------+
| iPad SwiftUI/AVKit app     |   HTTPS API    | Python FastAPI                |
| - local SQLite catalog    |<-------------->| - device authentication       |
| - selection state         |                | - catalog/version manifests   |
| - Keychain app credentials|                | - signed media URL issuance  |
| - URLSession bg download  |                | - admin roles / audit events  |
| - persistent MP4s         |                +---------------+---------------+
+-------------+-------------+                                |
              | signed HTTPS media download                  |
              +----------------+--------------------+        v
                               | S3-compatible      |  PostgreSQL
                               v                   |
                     Object storage <--------------+ (media object keys,
                     immutable video versions         not raw MP4s in DB)
                               ^
                               | admin direct upload
                     +---------+----------+
                     | React admin portal |
                     +--------------------+
```

## Stack defaults and rationale
- **iPad:** SwiftUI; AVKit/AVPlayer; Foundation background `URLSession`; SQLite with explicit migrations; file protection appropriate for offline use; Keychain for device credentials. Native UI and local files eliminate Safari/app-server dependencies during playback.
- **Backend:** FastAPI, Pydantic API schemas, PostgreSQL, Alembic migrations, structured logging; S3-compatible storage with immutable object keys and presigned download URLs; storage provider selectable by configuration (evaluate Cloudflare R2 and AWS S3 during deployment).
- **Admin:** React/Vite + TypeScript, accessible forms, upload status and version history, authenticated admin sessions with MFA via selected identity provider (or a documented alternative).
- **Local developer stack:** Docker Compose running API, DB and development object storage/emulator; synthetic seed MP4s and local-only credentials.
- **CI:** Python pytest + static checks; admin unit/Playwright tests; Swift XCTest and `xcodebuild` on hosted macOS.

## Versioning and catalog contract
Use **immutable versions** for each video, never overwrite a currently live binary object. Server `video_id` identifies the title; `version_id` identifies a particular published file. Version manifest includes:

```json
{
  "video_id": "uuid",
  "version_id": "uuid",
  "revision": 4,
  "title": "Valve Installation Reference",
  "description": "Brief field reference",
  "category_ids": ["uuid"],
  "tags": ["valves"],
  "duration_seconds": 286,
  "bytes": 167772160,
  "mime_type": "video/mp4",
  "video_codec": "h264",
  "audio_codec": "aac",
  "width": 1920,
  "height": 1080,
  "sha256": "64-character-lowercase-hex-digest",
  "published_at": "2026-11-17T14:00:00Z",
  "thumbnail_url": "optional time-limited URL",
  "available": true
}
```

**Contract notes:** The above is illustrative shape, not a live video or valid digest. Time-limited download URLs should be obtained separately, not embedded permanently in the catalog. Playback of local files uses no URL signing. Catalog responses should support ETag/version cursors and pagination if library grows, but initial scale is tiny.

## Primary relational entities
- `categories(id, name, sort_order, archived_at)`.
- `videos(id, title, description, status[draft|published|retired], created_at, updated_at, current_version_id)`.
- `video_categories(video_id, category_id)` and `video_tags(video_id, tag)`.
- `video_versions(id, video_id, revision, object_key, sha256, byte_length, duration_seconds, mime, codecs, dimensions, published_at, created_by, validation_status)`.
- `app_devices(id, display_label, device_public_id, enrolled_at, last_seen_at, revoked_at, token_version, device_group)`.
- `enrollment_tokens(id, token_hash, expires_at, used_at, created_by)` — one-use, short-lived tokens only.
- `admin_users(id, identity_provider_subject, role, active, last_login)`.
- `audit_events(id, timestamp, actor_type, actor_id, action, target, metadata_redacted)`.
- Optional `device_selection_backup(device_id, video_id, selected, updated_at)` for restoring user selections; local SQLite remains source of immediate offline truth.

## REST API outline (first version)
Publicly exposed API endpoints MUST require HTTPS, rate limiting, input validation and correct authorization; examples show path shapes, not production-ready security definitions.

### Device-facing
- `POST /v1/devices/enroll` — exchange admin-approved one-time code for revocable device credentials; prevent reuse and bind to a server-generated device identity.
- `POST /v1/devices/token/refresh` — rotate refresh token; store securely in Keychain; handle lost/revoked token gracefully, but never block pre-downloaded video playback.
- `GET /v1/catalog?cursor=...` — device-scoped published catalog and versions; ETag or revision watermark.
- `GET /v1/categories` — published taxonomy.
- `POST /v1/videos/{video_id}/versions/{version_id}/download` — confirm device permission and return short-lived HTTPS media URL, expected hash, length and version; avoid long-lived embedded signed URLs.
- `POST /v1/devices/self/sync-report` — optional minimal operational telemetry (download status, not video-watch history); redact sensitive data.

### Admin-facing
- `POST /v1/admin/uploads` — initiate upload, return restricted upload target and object key.
- `POST /v1/admin/uploads/{id}/finalize` — verify actual uploaded byte count/hash + ffprobe codec/duration/dimensions, mark validated or rejected; no publish before validation.
- `POST /v1/admin/videos`, `PATCH /v1/admin/videos/{id}` — metadata CRUD with auditing.
- `POST /v1/admin/videos/{id}/versions/{id}/publish` — atomically set `current_version_id` after validation; keep earlier binary available until retired by retention policy.
- `POST /v1/admin/videos/{id}/retire` — remove from new catalog; no claim of immediate deletion on offline iPads.
- `POST /v1/admin/enrollment-codes` — create short-lived, single-use device pairing code.
- `GET /v1/admin/devices`, `POST /v1/admin/devices/{id}/revoke` — minimal management; distinguish server revocation from Mosyle MDM.

**Security expectation:** Use authorization scopes for all admin and device routes; never trust client-supplied `device_id` alone for authentication. Validate video version belongs to requested video and is published/permitted before signing its download.

## iPad local storage schema
- `local_videos(video_id, cached_metadata_json, catalog_revision, last_seen_at)`.
- `download_selections(video_id, selected_at, wifi_only_override?)`.
- `local_versions(video_id, version_id, relative_path, sha256, byte_length, verified_at, status)`; exactly one active verified version per video, optional staged candidate.
- `download_jobs(job_id, video_id, target_version_id, state, bytes_expected, bytes_received, attempt, last_error, background_session_task_id?, updated_at)`.
- `local_settings(key, value)`.
- Schema migrates without deleting local MP4s; user selections persist across app updates.

## Sync state machine

```text
NOT_SELECTED --select--> SELECTED_NOT_READY --queue--> QUEUED
QUEUED --start--> DOWNLOADING --complete--> VERIFYING --valid--> READY
DOWNLOADING --pause/failure--> RETRY_PENDING --retry--> QUEUED
VERIFYING --bad hash/size--> RETRY_PENDING (delete staged bytes only)
READY --new revision published--> UPDATE_PENDING (old verified video playable)
UPDATE_PENDING --> UPDATE_DOWNLOADING --> VERIFYING_NEW
VERIFYING_NEW --valid--> ATOMIC_SWITCH --> READY (new version)
VERIFYING_NEW --failed/storage low--> UPDATE_PENDING (old still playable)
READY/UPDATE_PENDING --user remove--> SELECTED_NOT_READY or NOT_SELECTED
```

Persist job state transactionally. Reconcile app startup from database records, filesystem and `URLSession.getAllTasks` without deleting active files. Avoid using network access as a prerequisite for local catalog/player launch.

## Storage/reservation algorithm
For a proposed download or replacement, use the OS-provided relevant storage-availability API where applicable and require enough space for:
`expected_new_file_bytes + staging/metadata allowance + minimum_free_reserve`.
A simple MVP default minimum reserve is **2 GB**, adjustable after physical 32 GB tests; always respect OS-reported availability and explicit download-size reservations. Updates may temporarily require old + new version simultaneously. If insufficient, keep current video and show an actionable message. Never evict unrelated selected videos without explicit permission. Do not equate advertised iPad capacity with free space.

## Download implementation details
- Use background-configured `URLSession` with stable identifier and AppDelegate background event handling for downloads that continue after suspension.
- For signed URLs, account for expiration before starting, use an appropriate expiry window and handle 401/403 with a new signed URL on subsequent foreground sync; don't assume paused transfers always resume from prior bytes.
- URLSession moves completed content to a temporary destination; move to a permanent staging path promptly, verify SHA-256 + file size, and atomically commit DB/file activation. Write crash-recovery logic; validate file existence before showing Ready Offline.
- Store MP4s in `Application Support/Offline Videos` under application-private persistent data, excluded from backup where appropriate; don't use `Caches` or `tmp` for verified content.
- For in-flight playback, hold a reference to the current file until its player releases it; remove superseded version afterwards.
- Untrusted server metadata is data, not executable instructions. Filenames are derived from UUIDs and fixed extensions, not unsanitized titles.
- A user force-quit can cancel iOS background transfers. Background refresh is never a guaranteed timer. Make foreground sync predictable and visible.

## Media management
- Accept **one** normal H.264/AAC MP4 rendition per video, typically 1920x1080. Validate format and <=10-minute policy with configurable tolerance; reject unsupported or malformed files with a clear admin error; do not silently transcode in MVP.
- Upload directly to object storage through bounded, presigned upload credentials. Validate metadata and hash server-side before publication. Upload limits are configurable, not hard-coded to assumptions about bitrate.
- Store immutable object keys (`videos/<video_id>/versions/<version_id>.mp4`) and retain at least one prior published revision for rollback, subject to administrator-set policy.
