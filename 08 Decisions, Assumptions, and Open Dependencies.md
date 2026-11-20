# 08 — Decision Log, Assumptions, and Outstanding Dependencies

## Confirmed by All Fab user

| Decision | Value | Status |
| --- | --- | --- |
| Fleet | Seven company iPads; grow slowly to ~25 | Confirmed |
| Management | Supervised/managed by Mosyle; staff devices have no Apple Account signed in | Confirmed by management screen |
| Mosyle admin access | Requester does not have it | Confirmed |
| Developer workstation | Windows-only | Confirmed |
| Local storage diversity | Some 32 GB; foremen 256 GB | Confirmed |
| Video duration | Most <=5 min, longest around 10 min | Confirmed |
| Default source | 1080p video | Confirmed |
| Offline need | Native inside-app playback of files downloaded on iPad | Confirmed |
| Selection pattern | A few videos per person at a time; selective sync | Confirmed |
| Quality selector | Unnecessary, exclude | Confirmed |
| Earlier YouTube attempt | Abandoned; not the media source | Confirmed |
| ECC | Already installed | Confirmed |

## Defaults selected for implementation, NOT yet company-approved policy

| Topic | Working default | What to do if a decision is needed |
|---|---|---|
| Employee authentication | App/device-specific enrollment; no per-employee login | Build as configurable identity boundary; explain approval required |
| Administrator rights | Authorized admins only for upload/publish; editor/publisher/device admin roles available | Ask company security owner when setting access |
| Hosting | Cloud storage + small API + PostgreSQL | Abstract object-storage API and infrastructure config; choose provider at deployment |
| Video export | Files remain private within app; no Files export | Respect company policy |
| Download sync | Per-video manual selection; automatically check for updates for selected items when app is open and opportunistically background | Add category subscriptions only as optional post-MVP enhancement |
| Required/mandatory videos | Not in MVP | Need admin policy for forced sync and storage precedence |
| Local file lifetime | No expiration; user removes manually | Document policy limitations; do not silently expire content |
| Admin source identity | Existing company IdP if available with MFA, else secure managed login | Confirm identity provider before production |
| Video validation | Single H.264/AAC MP4 rendition, typically 1080p, no transcode | Reject incompatible uploads with actionable errors |
| Free space safety reserve | 2 GB initial floor, configurable; must separately allow staging bytes | Tune after 32 GB pilot, don't overpromise exact OS behavior |
| Download over cellular | Wi-Fi only by default | Allow company policy override |
| Version retirement | Keep prior verified local copy while update pending | Server retention and forced-removal policy need approval |

## Company/admin prerequisites before production, not before development
- All Fab-authorized Apple Developer Program membership and ownership of signing credentials.
- Apple Business organization identity/Custom Apps distribution access, approved developer association and app license assignment.
- Mosyle administrator to confirm MDM settings, app distribution permissions and pilot installation.
- Backend/cloud host selection, approved budget, domain/subdomain, TLS setup and admin identity provider.
- Company-owned MP4 source files and permission to distribute internally.
- Named content administrator and backup operator.
- Device/app security retention requirements, e.g., use of passcodes, lost-device policy and whether forced purge is ever needed.

## Engineering questions Codex may decide within project (record ADRs)
- Exact iPadOS deployment minimum compatible with the oldest All Fab iPad (learn from actual model/iPadOS; do not assume availability of APIs on all devices).
- SQLite wrapper or pure C API; choose maintainable Swift package compatible with hosted builds.
- Hosted PostgreSQL and S3-compatible object storage provider after cost comparison.
- Correct concurrency/download queue size for device bandwidth/space; start with conservative limit.
- Exact free-space API and protection class for app file usage.
- Repo structure details and dependency versions.

## Avoid premature blockers
Do NOT stop backend/app architecture work merely because requester lacks a Mac, Mosyle access or Apple Developer credentials. Clearly mark activities requiring organizational credentials and build/test what can be validated without them. Conversely do NOT pretend an unsigned simulator build or a local web mock is the final signed company app.

## Sources checked for platform constraints
- Apple background URLSession documentation: https://developer.apple.com/documentation/foundation/downloading-files-in-the-background
- Background session force-quit semantics: https://developer.apple.com/documentation/foundation/urlsessionconfiguration/background%28withidentifier:%29
- Apple Custom App distribution and review: https://support.apple.com/guide/deployment/distribute-custom-apps-dep0113f6e18/web
- Apple managed device-based app distribution: https://support.apple.com/guide/deployment/dep7cef2e0ea/web
- Codex AGENTS.md: https://learn.chatgpt.com/docs/agent-configuration/agents-md
- ECC upstream: https://github.com/affaan-m/ECC
