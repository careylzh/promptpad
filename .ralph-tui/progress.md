# Ralph Progress Log

This file tracks progress across iterations. Agents update this file
after each iteration and it's included in prompts for context.

## Codebase Patterns (Study These First)

- Keep the SwiftUI macOS executable target (`PromptPad`) thin and place reusable, testable constants or editor logic in the `PromptPadCore` library target so `swift test` can validate behavior without launching UI.

---

## 2026-05-15 - US-001
- Implemented the initial `PromptPad` Swift package with a SwiftUI macOS app entry point.
- Added a single primary editor window using `Window`, removed the New command, and avoided sidebars, file trees, tabs, document browser UI, and multi-document scaffolding.
- Styled the editor with a light background, muted grey text, spacious padding, hidden title bar chrome, and large Georgia serif text with documented soft-serif fallbacks.
- Added a small testable `PromptPadCore` style contract and an XCTest.
- Verified `swift build` passes.
- Verified tests pass with `env CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache swift test --disable-sandbox`; plain `swift test` is blocked in this execution sandbox by SwiftPM/Clang cache and `sandbox-exec` permission errors before test compilation.
- Files changed: `Package.swift`, `Sources/PromptPad/PromptPadApp.swift`, `Sources/PromptPadCore/PromptPadStyle.swift`, `Tests/PromptPadCoreTests/PromptPadStyleTests.swift`, `.ralph-tui/progress.md`.
- **Learnings:**
  - Patterns discovered: a thin SwiftUI executable plus `PromptPadCore` library keeps UI shell constants and future editor logic directly testable.
  - Gotchas encountered: this sandbox blocks SwiftPM's default manifest/test sandbox/cache behavior; `swift build` succeeds normally, while tests need the module cache redirected and SwiftPM package sandbox disabled here.
---
