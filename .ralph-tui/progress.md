# Ralph Progress Log

This file tracks progress across iterations. Agents update this file
after each iteration and it's included in prompts for context.

## Codebase Patterns (Study These First)

- Keep the SwiftUI macOS executable target (`PromptPad`) thin and place reusable, testable constants or editor logic in the `PromptPadCore` library target so `swift test` can validate behavior without launching UI.
- Define editor state and persistence contracts in `PromptPadCore`; let the app target choose the concrete platform storage location and keep SwiftUI/AppKit editor rendering in app-target views.
- Resolve platform-specific storage roots in the app target, then use `PromptPadCore` helpers for deterministic document URLs and file persistence behavior that can be unit tested.
- Expose editor command state such as selection through small `PromptPadCore` value types, then keep AppKit bridge synchronization in the app target via SwiftUI bindings.
- Implement editor text transformations as small `PromptPadCore` command helpers that return updated text and selection, then let the AppKit bridge invoke them from focused editor key events.
- Keep editor presentation mode state in `PromptPadCore`, while app-target SwiftUI views decide how to render each mode.
- Keep export format contracts and exact text writing helpers in `PromptPadCore`, while the app target owns native macOS save-panel presentation and selected destination URLs.
- Keep import format contracts and exact text reading/replacement helpers in `PromptPadCore`, while the app target owns native macOS open-panel presentation and destructive-replace confirmation.

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

## 2026-05-15 - US-005
- Implemented Cmd+B Markdown bold behavior in the main AppKit-backed editor.
- Added a reusable `MarkdownBoldEdit` core helper and `PromptEditorModel.applyMarkdownBold()` so selected text becomes `**selected text**`, empty selections insert `****`, and the cursor lands between the marker pairs.
- Wired a focused `NSTextView` subclass to intercept Cmd+B and update the same text binding used by autosave.
- Added unit coverage for selected text wrapping, empty-selection insertion/cursor placement, and model text-state mutation.
- Verified `swift build` passes.
- Verified tests pass with `env CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache swift test --disable-sandbox`; plain `env CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache swift test` ran all tests successfully but exited nonzero because this sandbox reports `sandbox-exec: sandbox_apply: Operation not permitted` while validating the manifest.
- Files changed: `Sources/PromptPad/PromptEditorView.swift`, `Sources/PromptPadCore/PromptEditorModel.swift`, `Tests/PromptPadCoreTests/EditorPersistenceTests.swift`, `.ralph-tui/progress.md`.
- **Learnings:**
  - Patterns discovered: core command helpers should return both updated text and updated selection so keyboard shortcuts remain deterministic and unit testable without launching the macOS UI.
  - Gotchas encountered: `NSTextView` selections are UTF-16 `NSRange` values, so core text transformations need to translate selection offsets through `String.Index(utf16Offset:in:)`.
---

## 2026-05-15 - US-006
- Added optional edit/preview display mode state to `PromptEditorModel`, with edit mode as the default launch state.
- Added a compact segmented mode switch in the editor window without introducing a full toolbar.
- Added a Markdown preview view that renders the current raw Markdown through Swift `AttributedString` Markdown parsing for headings, emphasis, code, and lists while leaving the raw editor text unchanged.
- Added core tests proving default edit mode and that switching display modes does not mutate the Markdown text.
- Verified `swift build` passes.
- Verified tests pass with `env CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache swift test --disable-sandbox`; plain `swift test` is still blocked in this execution sandbox by Clang module-cache permissions before package manifest compilation.
- Files changed: `Sources/PromptPad/PromptPadApp.swift`, `Sources/PromptPadCore/PromptEditorModel.swift`, `Tests/PromptPadCoreTests/EditorPersistenceTests.swift`, `.ralph-tui/progress.md`.
- **Learnings:**
  - Patterns discovered: keep display-mode state in core for testability, and keep platform-specific Markdown rendering in the SwiftUI app target.
  - Gotchas encountered: plain `swift test` can fail before compiling tests when the sandbox cannot write `~/.cache/clang/ModuleCache`; redirecting `CLANG_MODULE_CACHE_PATH` inside `.build` preserves verification in this environment.
---

## 2026-05-15 - US-007
- Implemented export of the current editor text as Markdown (`.md`) or plain text (`.txt`) through a native macOS `NSSavePanel`.
- Added reusable `PromptExportFormat` and `PromptTextExport` core helpers, plus `PromptEditorModel.exportText(to:)`, so exact text export is unit-testable without launching UI.
- Kept export separate from the local persistent document path and existing single-document autosave flow.
- Added tests for export filenames/extensions, exact exported contents, and export not invoking the persistent save path.
- Verified `swift build` passes.
- Verified tests pass with `env CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache swift test --disable-sandbox`; plain `swift test` remains blocked in this execution sandbox before manifest compilation because Clang cannot write `~/.cache/clang/ModuleCache`.
- Files changed: `Sources/PromptPad/PromptPadApp.swift`, `Sources/PromptPadCore/PromptEditorModel.swift`, `Tests/PromptPadCoreTests/EditorPersistenceTests.swift`, `.ralph-tui/progress.md`.
- **Learnings:**
  - Patterns discovered: keep export format contracts and exact text writing helpers in core, with the app target responsible for native save-panel presentation and user-selected destination URLs.
  - Gotchas encountered: `UTType.markdown` is not available in this SDK, so extension-based `UTType(filenameExtension:)` lookup is more portable for save-panel type filtering.
---

## 2026-05-15 - US-008
- Implemented import of Markdown (`.md`) and plain text (`.txt`) files through a native macOS `NSOpenPanel`.
- Added replacement confirmation before importing over existing non-empty editor text.
- Added reusable `PromptImportFormat`, `PromptTextImport`, and `PromptEditorModel.importText(from:)` core helpers so imported text replaces the single persistent prompt document and is unit-testable.
- Kept import in the existing single editor window without tabs, sidebars, or multi-document state.
- Added tests for supported import extensions and for Markdown/plain-text imports persisting the replacement document.
- Verified `swift build` passes.
- Verified tests pass with `env CLANG_MODULE_CACHE_PATH=$PWD/.build/module-cache swift test --disable-sandbox`; plain `swift test` is still blocked in this sandbox before manifest compilation because Clang cannot write `~/.cache/clang/ModuleCache`.
- Files changed: `Sources/PromptPad/PromptPadApp.swift`, `Sources/PromptPadCore/PromptEditorModel.swift`, `Tests/PromptPadCoreTests/EditorPersistenceTests.swift`, `.ralph-tui/progress.md`.
- **Learnings:**
  - Patterns discovered: import mirrors export cleanly when file-type contracts and exact text reading/replacement live in core, while AppKit owns open-panel selection and destructive-replace confirmation.
  - Gotchas encountered: plain `swift test` remains environment-blocked by the user-level Clang module cache, so the repository-local module-cache workaround is still needed here to execute tests.
---
