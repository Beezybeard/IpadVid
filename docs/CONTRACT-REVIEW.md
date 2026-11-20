# Initial Contract Review

## Product contract

The system serves a small fleet of supervised company iPads. A field employee selects a few company-owned H.264/AAC MP4s, downloads them into app-private persistent storage, verifies byte length and SHA-256, and later searches and plays them through AVKit with no network or fresh authentication. Updates are immutable new versions: download to staging, verify, atomically activate, and only then retire old local bytes. A failed update, server outage, expired signed URL, low storage, or normal cleanup must never remove the last valid user-selected copy.

The backend owns device enrollment, published catalog/version manifests, authorization, short-lived media URLs, admin actions, and audit records. PostgreSQL stores metadata; private S3-compatible storage holds immutable media. The React admin portal supports validated upload/publish/version/device operations. Production distribution is a separate Apple Business/Custom App/Mosyle responsibility performed by authorized company administrators.

## Engineering contract

Work proceeds in bounded, test-first increments. Windows is valid for API/admin development; only macOS Xcode evidence counts for iOS compilation, and only physical iPads count for device-only acceptance. ECC is used when callable; otherwise its documented architecture, TDD, review, and security checklists are followed and the limitation is recorded. Synthetic media and credentials are required in development and CI.

## Contradiction review

No blocking contradiction was found. The documents consistently prioritize selective offline use, immutable versions, last-good-copy preservation, native playback, staged verification, accountless managed distribution, and honest platform-specific test evidence.

The following ambiguities are tracked rather than silently decided:

1. `Remove Download` clearly deletes local bytes, but the state machine permits either retaining or clearing the selection. The UI contract should separate **Remove local copy** from **Stop selecting for offline use** if both behaviors are needed.
2. A retired server video must not be silently purged from an offline device. The working safety interpretation is that a downloaded verified copy remains visible/playable locally, while re-download availability and eventual policy require an explicit product decision.
3. Admin identity provider, hosting provider, oldest supported iPadOS, forced-deletion policy, and server retention duration are intentionally unresolved company/deployment decisions, not contradictions or early development blockers.
