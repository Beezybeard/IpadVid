# 01 — Product and User Experience Specification

## Product mission
Allow All Fab field personnel to confidently take a small, selected set of training/reference videos to an industrial site where internet service may be unavailable. An employee must be able to start the app, search previously downloaded metadata and play a saved video **without network connectivity**.

## Roles
- **Field employee (managed iPad):** browse catalog online, select/unselect downloads, play local videos, inspect download readiness, remove local downloads, start/check sync.
- **All Fab video administrator (web dashboard):** upload/validate/publish/unpublish content, categorize, update versions, review device enrollments/revoke an app device, inspect minimal operational status.
- **Authorized company Apple Business/Mosyle administrator:** install/update signed app through MDM; a separate actor not assumed to be the same person as video admin.

## iPad screens
### 1. Library
- Offline-first launch; cached metadata and **Downloaded** section appear instantly.
- Clearly display state `Offline`, `Connected`, `Checking`, `Downloading`, `Needs attention`; distinguish reachability from actually-completed downloads.
- Search all cached titles/tags; when online, refresh available catalog and mark online-only entries appropriately.
- Default filters: `Downloaded`, `All Videos`, `Categories`, `Updates`.
- Each card shows thumbnail, title, duration, approximate size, category, version/updated marker and one state action.
- Do not show a working Play affordance for an online-only video when offline; communicate that a download is required.

### 2. Video details
- Title, description, category, duration, last updated, approximate size and clear `Download for offline use`/`Remove download` control.
- Play locally whenever verified local bytes exist, irrespective of a network error or pending update.
- Display download progress in bytes/percent where available; cancel and retry controls.
- Indicate when a newer version is pending, but keep the current verified one playable.

### 3. Native player
- Use AVPlayerViewController/AVKit with native full-screen playback, seek, pause/resume, orientation controls and system captions if provided.
- Player consumes local file URLs for offline copies, never a remote URL when the employee selects an offline copy.
- Optionally allow online preview while connected as a later enhancement; it must never masquerade as downloaded/offline-ready.
- Playback does not require a webview, Safari, an Apple Account or a server round trip.

### 4. Downloads and readiness
- List selected items with states: `Not Downloaded`, `Queued`, `Downloading`, `Verifying`, `Ready Offline`, `Update Pending`, `Error/Retry`, `Insufficient Space`.
- Display selected count, number ready offline, bytes used, estimated bytes required, device free space and remaining free-space reserve.
- `Sync Before Leaving`: foreground flow that refreshes catalog and relevant versions, queues selected missing/outdated files, tracks active progress, and ends with a **readiness summary** (`3 of 3 ready` or explicit exceptions). A stale but verified video can be counted as playable with `update pending`, not falsely described as current.
- `Remove Download`: delete only that device's local copy after confirmation; maintain central catalog entry so it can be downloaded later. Removing a currently playing file should defer deletion until playback stops or safely closes.

### 5. Settings
- Wi-Fi-only downloads default ON (user can allow cellular if the hardware and company policy allow).
- Optional notifications for failed downloads, app/device disconnection or pending updates; never require notifications for use.
- App storage used, current device free space and safety reserve; no manual quality selector.
- Device enrollment/status summary, app version and diagnostics export (redacted, no secrets or customer content).

## Critical flows
**A. First launch:** install -> administrator-approved one-time device enrollment/pairing -> catalog fetched -> empty offline downloads -> employee selects 2–5 videos -> downloads verified -> ready. Enrollment must NOT require an Apple Account. First enrollment requires connectivity and an administrator-approved trust step; subsequent offline launches do not.

**B. Offline jobsite:** open app in airplane mode -> local titles/thumbnails/search -> tap ready video -> native playback and scrubbing -> app handles no-network state without modal blocking.

**C. Upload update:** admin publishes revision B of existing training video -> existing revision A stays playable on subscribed iPad -> app fetches B as a separate staged object -> verifies complete length+SHA-256 -> local pointer switch -> removes A after safe handover. If transfer fails, A remains usable.

**D. Storage-constrained iPad:** employee requests a video while device space is low -> calculate temporary bytes and reserve -> show clear insufficient-space error and suggestions -> do not delete other user downloads; allow retry after storage is freed.

**E. Device no longer needed:** video admin revokes application identity/server access; Mosyle admin can separately remove app and local data as permitted by MDM. Revocation cannot instantly reach a fully offline device—document that limitation.

## Defaults / deliberately deferred
- Per-video selection is the only required download mechanism in MVP. Optional subscribe-to-category behavior may be implemented in a future phase, not a blocker.
- No auto-cleaning employee-selected video files. Admin-required content/retention policy is a later opt-in module and needs explicit company sign-off.
- Online streaming preview is optional; offline downloads and playback take priority.
- No employee accounts or passwords on field devices in MVP; use device-specific enrollment/credentials. Admins require authenticated, authorized accounts.
- No YouTube integration; source is All Fab-owned original MP4 assets.

## UX acceptance conditions
- At-a-glance readiness visible to a foreman before driving to site.
- No ambiguity between `selected`, `downloading`, and `ready offline`.
- No false “synced” message while pending/corrupt/stale files exist.
- Single app binary scales from 32 GB to 256 GB iPads with no capacity-specific builds.
- Entire UI navigable offline for content previously catalogued/cached, with useful empty states for first-run/no downloads.
