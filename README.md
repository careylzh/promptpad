# PromptPad

PromptPad is a minimal macOS and iOS Markdown prompt editor built with SwiftUI and a small `PromptPadCore` library for testable editor behavior.

## Requirements

- macOS 14 or newer
- iOS 17 or newer for the iOS app experience
- Xcode or the Xcode Command Line Tools, including `swift`
- `hdiutil` for DMG packaging, which is included with macOS

## Build

```sh
swift build
```

For a release build:

```sh
swift build -c release
```

To compile the iOS app path from SwiftPM:

```sh
swift build --sdk "$(xcrun --sdk iphoneos --show-sdk-path)" --triple arm64-apple-ios17.0
```

## Test

```sh
swift test
```

If a local sandbox blocks SwiftPM from writing to the default Clang module cache, use a repository-local cache:

```sh
env CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache swift test --disable-sandbox
```

## Run

```sh
swift run PromptPad
```

## Build Unsigned App

Build a release executable and generate `dist/PromptPad.app` without a paid
Developer ID certificate:

```sh
./scripts/build-app.sh
```

Set `CONFIGURATION=debug` to generate a debug app bundle instead.

The script applies the ad-hoc signature required to launch arm64 executables on
macOS. This is a local signature only; the app is not Developer ID signed or
notarized for public distribution.

## Package DMG

Build a release executable, stage `PromptPad.app`, and create `dist/PromptPad.dmg`:

```sh
./scripts/package-dmg.sh
```

The packaging script must be run on macOS because it uses the system `hdiutil` tool to create the disk image. It first attempts a compressed UDZO disk image and falls back to a hybrid HFS image if the local environment cannot create compressed images. The DMG contains `PromptPad.app` and an `/Applications` shortcut.

The script defaults `CLANG_MODULE_CACHE_PATH` to `.build/module-cache` and uses SwiftPM's `--disable-sandbox` flag for its internal release build so packaging does not depend on write access to user-level Swift or Clang caches.
