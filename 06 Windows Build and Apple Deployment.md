# 06 — Windows Development, macOS CI, and Mosyle Distribution

## Windows-only developer environment
Install/use on Windows: Git, current Python supported by dependencies, Node.js, Docker Desktop or equivalent container engine, VS Code/IDE, and Codex. ECC is already installed; do not reinstall it. Work normally on Windows for backend and admin. Swift source can be authored/reviewed on Windows, but an iPadOS binary requires Xcode on macOS.

## Hosted Xcode builds
Use GitHub Actions hosted macOS runners to compile the iOS project and run XCTest, including simulator tests where available. Avoid assuming a specific macOS/Xcode image version for years; pin an Xcode version after checking runner support, then periodically update intentionally.

Suggested separate CI lanes:

1. **server-ci** (Ubuntu or Windows): lint/typecheck + PostgreSQL test DB + pytest + fault-injection tests.
2. **admin-ci** (Ubuntu or Windows): `npm ci`, TypeScript compilation, unit tests, Playwright including an authenticated local API fixture.
3. **ios-ci** (hosted macOS): install agreed Xcode toolchain, `xcodebuild -list` and `-showdestinations`, build/test on chosen iPad simulator destination, publish `.xcresult` and build log. Start this lane when Xcode project and tests exist; require its success before merging iOS changes.
4. **release-ios** (hosted macOS, protected branch and environment): code signing only after Apple Developer permissions, signing assets and provisioning are safely configured; output signed distributable for approved Apple distribution path.

A prototype `xcodebuild` invocation (Codex must replace workspace/project/scheme/OS destination with inspected actual values):

```bash
xcodebuild -project "ios/AllFabVideoLibrary.xcodeproj" \
  -scheme "AllFabVideoLibrary" \
  -destination 'platform=iOS Simulator,name=iPad (A16)' \
  -derivedDataPath build/DerivedData \
  build test CODE_SIGNING_ALLOWED=NO
```

**Do not commit this command unmodified as CI** unless actual scheme and simulator exist on the selected runner. Prefer discovered simulator destination ID / eligible generic destination. For unsigned simulator build, code signing is disabled; later physical device/release builds require correct signing.

## Apple account prerequisites — not a reason to block coding
- Authorized All Fab representative decides who owns the Apple Developer Program membership and controls the signing identity.
- Obtain All Fab's Apple Business organization identifier and confirm Custom Apps / Apps & Books licensing when ready.
- Determine which admin controls Mosyle, its Apple Business connection, its app license assignment capability and device groups.
- Developer prepares app ID/bundle ID, display name, privacy details, support contact and App Store Connect metadata needed for **private Custom App distribution**.
- Apple's Custom Apps still undergo Apple review, including updates; plan deployment accordingly.
- Device-based managed licenses enable app installation with no Apple Account signed in on employees' devices when appropriately assigned by management.
- No proprietary or customer videos need to be bundled inside the app package. The company server serves content independently of app releases.

## Pilot rollout
1. Use a company-approved, provisioned test path for one designated supervised iPad, without weakening MDM or bypassing company control.
2. Sign and submit authorized private Custom App, or use a compliant approved developer/ad hoc testing route during validation only.
3. Mosyle admin assigns the organization-scoped custom app license to a pilot iPad, then deploys it.
4. Validate offline full launch/AVKit playback, 2–5 selected video downloads, update verification, low-space response and app update preserving local downloads.
5. Confirm device/server revocation semantics; MDM uninstall/wipe policy is owned by administrator.
6. Deploy to remaining six after pilot signoff.

## What Codex must not do
- Claim that GitHub Actions alone provides an Apple Developer identity or authorizes distribution.
- Present a raw `.ipa` file as universally installable on supervised iPads without approved signing/provisioning.
- Attempt to remove, override or weaken the Mosyle profile.
- Request passwords or long-lived signing private keys in an ordinary chat prompt or in git. Use authorized secret storage/protected CI environments.
- Require a Mac purchase; cloud macOS runners are enough for compilation, although physical iPad tests remain necessary.

## Useful official sources (as of November 2026)
- GitHub-hosted macOS runners: https://docs.github.com/en/actions/reference/runners/github-hosted-runners
- Apple Custom Apps distribution: https://support.apple.com/guide/deployment/distribute-custom-apps-dep0113f6e18/web
- Apple managed device-based distribution: https://support.apple.com/guide/deployment/dep7cef2e0ea/web
- Background URLSession: https://developer.apple.com/documentation/foundation/downloading-files-in-the-background
- Background session force-quit behavior: https://developer.apple.com/documentation/foundation/urlsessionconfiguration/background%28withidentifier:%29
