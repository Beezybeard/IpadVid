# Initial Threat Model

## Protected assets

- Company-owned training MP4s and their immutable version metadata.
- Device refresh credentials, one-use enrollment tokens, admin sessions, and signed media URLs.
- Publishing authority, device revocation authority, and audit history.
- A device's last verified offline copy and the integrity state that marks it playable.

## Trust boundaries

1. Managed iPad application to public HTTPS API.
2. API to PostgreSQL and private object storage.
3. Authorized admin browser to admin API and restricted upload target.
4. GitHub Actions to protected deployment/signing environments.
5. Server revocation to an intermittently connected device; offline enforcement is inherently delayed.

## Initial threats and required controls

| Threat | Required control / test direction |
| --- | --- |
| Reused or guessed enrollment token | Short TTL, high entropy, hashed storage, atomic one-use consumption, rate limiting, reuse/expiry tests |
| Device impersonation | Unique revocable credential, refresh rotation, server-side device binding, no client-supplied ID as authentication |
| Unauthorized media URL | Scope checks, published video/version relationship validation, short URL TTL, no URL logging, 401/403 tests |
| Malicious or malformed upload | Bounded upload, content sniffing, ffprobe-derived metadata, server-computed hash/length, no publication before validation |
| Corrupt or partial device download | Staging path, expected length and SHA-256 verification, atomic activation, preserve previous verified version |
| Low-space update destroys working copy | Reserve calculation includes staging plus minimum free space; no unrelated automatic eviction |
| Secret leakage | Environment/protected secret stores, redacted structured logs, ignored local env/signing files, synthetic fixtures only |
| Privilege escalation in admin UI | Server-side role enforcement and audit events; UI hiding is not authorization |
| Lost iPad remains offline | Document revocation delay; MDM removal/wipe when connected; do not claim DRM or instant purge |

## Review checkpoints

Revisit this model before device enrollment, download signing, direct uploads, local credential storage, and release configuration. Critical or high findings block production release.
