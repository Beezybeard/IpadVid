# All Fab Video Library — iPad client

This directory contains the reproducible source definition for the native iPad app. Slice 1 is an intentionally small shell: it presents an enrollment-required state and an offline-library empty state while the enrollment, catalog, download, and playback behavior is built in later verified slices.

## Current evidence

- Authored on Windows: **yes**.
- XcodeGen project generation: **NOT RUN locally — XcodeGen is executed by macOS CI**.
- Xcode build and Swift tests: **NOT RUN — requires the macOS CI workflow**.
- Simulator UI tests: **NOT RUN — requires the macOS CI workflow**.
- Physical iPad tests and signing: **NOT RUN — later authorized device phase**.

Do not interpret the presence of Swift files as a successful Apple-platform build. The `.github/workflows/ios-ci.yml` workflow is the first compilation authority once a private GitHub remote is connected.

## Toolchain contract

- Xcode 26.6 on the GitHub `macos-26` runner.
- XcodeGen 2.48.0, downloaded from its release and verified by SHA-256 in CI.
- iPadOS 17.0 provisional deployment minimum, pending inventory of the oldest managed company iPad.
- Swift 6 language mode, strict concurrency, MainActor-default app isolation.
- Unsigned simulator builds only; release signing is deliberately absent.

The temporary bundle identifier is `com.example.allfabvideolibrary.dev`. It is not an All Fab production identity and must be replaced only after an authorized Apple administrator supplies the approved identifier.

## Generate and test on macOS

From the repository root after installing the pinned XcodeGen version:

```sh
cd ios
xcodegen generate --spec project.yml
xcodebuild -project AllFabVideoLibrary.xcodeproj -list
```

Discover an available iPad simulator with `xcrun simctl list devices available`, then run:

```sh
xcodebuild \
  -project AllFabVideoLibrary.xcodeproj \
  -scheme AllFabVideoLibrary \
  -destination 'platform=iOS Simulator,id=<discovered-udid>' \
  -derivedDataPath ../build/ios/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  test
```

Never substitute a guessed simulator name or report these commands as passing without their actual output.
