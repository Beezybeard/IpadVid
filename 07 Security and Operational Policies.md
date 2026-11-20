# 07 — Security, Offline Access, and Operational Guardrails

## Device identity without employee Apple Accounts
Supervision and an MDM profile are **not** by themselves application authentication. An All Fab administrator must enroll/pair each app/device using an approved one-use, short-lived enrollment token (e.g. displayed QR/code) or a future approved Mosyle managed-app configuration. No staff Apple Account sign-in is needed. Issue a unique revocable device credential; store tokens in iOS Keychain; never embed an administrator API key in the app. Rotate refresh tokens and protect API endpoints.

If the app is installed but no token is available (new install, keychain reset), it may show cached offline videos if already present and appropriate according to app local state, but must not silently authenticate or access protected server resources.

## Video administrator security
Require modern admin sign-in (OIDC SSO + MFA if All Fab has an identity provider; otherwise select a similarly secure managed identity provider). Enforce authorization server-side, not through hidden buttons. Separate `video_editor`, `video_publisher`, and `device_admin` privileges as needed; smallest initial deployment can assign all three to one or two named, authorized administrators. Log publish/revoke/device-enroll administrative actions and notify on suspicious failures.

## Media protection and policy limits
Use HTTPS and restricted private object storage; presigned URLs expire; no public bucket/listing. Files are stored in iOS app-private persistent storage and not offered for export. iOS file protection and MDM passcode requirements strengthen at-rest protection. **This is not DRM:** users with sufficient device privileges may still capture or recover content, and offline files cannot be remotely revoked while a device is disconnected. A remote server revocation takes effect upon reconnection; MDM can separately remove app/data when device checks in and permits it.

## Offline safety and file retention
- No time-based offline expiration in MVP; a verified local file remains playable while app data remains installed and policy permits.
- Reauthentication is NOT required just to play already downloaded videos when the network is unavailable.
- The app must never remove ready downloads because it cannot reach the catalog, a signed URL expires or an update fails.
- `Retire` removes video from future server catalog; do not silently issue an immediate device deletion policy. If All Fab later requires forced deletion, design it as a separate explicitly approved feature, describing why offline devices cannot comply until reconnect.
- User-initiated `Remove Download` is local and reversible by re-downloading while online.
- App uninstall, managed app removal or device wipe can delete videos. Backup iCloud exclusion is intentional for re-downloadable company content; inform users that reinstalls may require downloads again.

## Observability and privacy
- Log request IDs, non-sensitive device identifiers (random pseudonymous IDs), version IDs, errors and file hashes, but do not log enrollment codes, signed URLs, authorization headers, personal identities beyond approved admin audit records, or full private MP4 metadata unnecessarily.
- No per-user video watch-tracking or engagement telemetry by default.
- App diagnostics export must redact credentials, signed URLs and filenames containing customer confidential details.
- Send application crash telemetry only if All Fab approves a privacy policy and provider.

## Cloud operations
- Separate dev, staging and production credentials/buckets/databases.
- Use automatic database backups, tested restore procedures, and versioned immutable media objects.
- Configure budget/cost alerts and request limits; do not deploy an expensive transcoding pipeline.
- Restrict admin portal, prevent dangerous upload types, validate content/codec/hash, limit object size, virus scan if required by company policy.
- Set up monitoring for API health, upload validation failures, object-store availability, DB backup jobs and unauthorized access attempts.
- Treat signed-media URLs as bearer credentials: short TTLs and redaction from analytics/logs.

## Threat/failure checklist
- Lost or stolen iPad: MDM compliance/remote-wipe operator, revoke app device identity, acknowledge offline revocation delay.
- Insider with admin browser: RBAC/MFA, audit trail and soft publish/rollback.
- Unauthorized device request: authenticated device token, per-device permission check and rate limiting.
- Malicious uploaded file: media validation, file size cap, content sniffing and server-side hash.
- Partial/interrupted download: staged path, verification, atomic switch and no overwrite of old file.
- Insufficient disk: no destructive cleanup, preflight reservation and clear warning.
- Background sync delayed/force-quit: explicit foreground readiness check.
- Unexpected server costs: private object storage, budget alerts, no heavy processing.
