# PromptPad

PromptPad is a minimal macOS Markdown prompt editor built with SwiftUI and a small `PromptPadCore` library for testable editor behavior.

## Requirements

- macOS 14 or newer
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

## Package DMG

Build a release executable, stage `PromptPad.app`, and create `dist/PromptPad.dmg`:

```sh
./scripts/package-dmg.sh
```

The packaging script must be run on macOS because it uses the system `hdiutil` tool to create the disk image. It first attempts a compressed UDZO disk image and falls back to a hybrid HFS image if the local environment cannot create compressed images. The DMG contains `PromptPad.app` and an `/Applications` shortcut.

The script defaults `CLANG_MODULE_CACHE_PATH` to `.build/module-cache` and uses SwiftPM's `--disable-sandbox` flag for its internal release build so packaging does not depend on write access to user-level Swift or Clang caches.
