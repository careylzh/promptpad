# Ralph Progress Log

This file tracks progress across iterations. Agents update this file
after each iteration and it's included in prompts for context.

## Codebase Patterns (Study These First)

- Keep the SwiftUI macOS executable target (`PromptPad`) thin and place reusable, testable constants or editor logic in the `PromptPadCore` library target so `swift test` can validate behavior without launching UI.
- Define editor state and persistence contracts in `PromptPadCore`; let the app target choose the concrete platform storage location and keep SwiftUI/AppKit editor rendering in app-target views.
- Resolve platform-specific storage roots in the app target, then use `PromptPadCore` helpers for deterministic document URLs and file persistence behavior that can be unit tested.
- Expose editor command state such as selection through small `PromptPadCore` value types, then keep AppKit bridge synchronization in the app target via SwiftUI bindings.

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

## 2026-05-15 - US-002
- Implemented reusable editor state in `PromptEditorModel`, isolated in the `PromptPadCore` library target.
- Added `EditorPersistence` and `FileEditorPersistence` so text loading/saving lives in a reusable model/service layer instead of the macOS window shell.
- Split macOS-specific editor rendering into `PromptEditorView`, leaving `PromptPadApp` responsible for window setup and wiring the concrete persistence store.
- Added core tests for missing-file loads, file save/load round trips, and model persistence behavior.
- Verified `swift build` passes.
- Verified tests pass with `env CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache swift test --disable-sandbox`; plain `swift test` is still blocked in this execution sandbox by SwiftPM/Clang cache permission errors before test compilation.
- Files changed: `Sources/PromptPad/PromptPadApp.swift`, `Sources/PromptPad/PromptEditorView.swift`, `Sources/PromptPadCore/EditorPersistence.swift`, `Sources/PromptPadCore/PromptEditorModel.swift`, `Tests/PromptPadCoreTests/EditorPersistenceTests.swift`, `.ralph-tui/progress.md`.
- **Learnings:**
  - Patterns discovered: keep reusable editor state and persistence protocols in `PromptPadCore`, then inject a concrete file-backed store from the app shell.
  - Gotchas encountered: avoid overlapping throwing and non-throwing initializer call shapes in Swift when default arguments make them ambiguous at call sites.
---

## 2026-05-15 - US-003
- Implemented single-document Application Support persistence wiring for the editor window.
- Added `PromptPadDocumentStore` in `PromptPadCore` to define the app document path while letting the app target resolve the user Application Support directory.
- Removed the temporary-directory fallback so the app does not silently store the prompt outside Application Support.
- Added tests for the Application Support document URL contract and creation of missing persistence directories during saves.
- Verified `swift build` passes.
- Verified tests pass with `env CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache swift test --disable-sandbox`; `env CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache swift test` executes the tests successfully but exits nonzero here because SwiftPM's manifest sandbox reports `sandbox-exec: sandbox_apply: Operation not permitted`.
- Files changed: `Sources/PromptPad/PromptPadApp.swift`, `Sources/PromptPadCore/EditorPersistence.swift`, `Tests/PromptPadCoreTests/EditorPersistenceTests.swift`, `.ralph-tui/progress.md`.
- **Learnings:**
  - Patterns discovered: app-target storage resolution plus core URL/persistence helpers keeps platform details thin while preserving unit coverage for the single-document path and directory creation behavior.
  - Gotchas encountered: avoid falling back to temporary storage for a user document because it can satisfy local writes while violating the explicit Application Support persistence contract.
---

## 2026-05-15 - US-004
- Replaced the SwiftUI `TextEditor` implementation with an `NSTextView` bridge hosted inside SwiftUI.
- Configured the editor for raw plaintext editing, undo, no rich text or graphics imports, disabled automatic Markdown-corrupting substitutions, readable serif typography, padded minimal chrome, and initial first-responder focus.
- Added reusable `EditorSelection` state to `PromptPadCore` and synchronized it from the AppKit text view so editor commands can access the current selection.
- Added unit coverage for editor selection state and clamping behavior.
- Verified `swift build` passes.
- Verified tests pass with `env CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache swift test --disable-sandbox`; plain `swift test` remains blocked in this execution sandbox by SwiftPM/Clang cache permissions before test compilation.
- Files changed: `Sources/PromptPad/PromptEditorView.swift`, `Sources/PromptPad/PromptPadApp.swift`, `Sources/PromptPadCore/EditorSelection.swift`, `Sources/PromptPadCore/PromptEditorModel.swift`, `Tests/PromptPadCoreTests/EditorPersistenceTests.swift`, `.ralph-tui/progress.md`.
- **Learnings:**
  - Patterns discovered: expose selection as a small core value type and let the AppKit bridge map `NSTextView.selectedRange()` into the model through bindings.
  - Gotchas encountered: Swift 6 requires immutable shared core value types used in static constants to conform to `Sendable`, and AppKit sizing constants sometimes need explicit `CGFloat` qualification.
---
