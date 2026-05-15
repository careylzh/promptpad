# PRD: PromptPad macOS App

## Overview
PromptPad is a native macOS desktop app for persistent prompt-writing. It provides one calm, minimal, distraction-free editor window with autosaved local text, Markdown-friendly plaintext editing, optional preview, import/export, and `.dmg` packaging.

The app should feel like a quieter, more beautiful Notepad: one document, one window, no tabs, no sidebar, no file tree, and no unnecessary chrome.

## Goals
- Provide a single persistent prompt-writing surface that restores automatically on launch.
- Preserve user text locally with continuous autosave.
- Support raw Markdown authoring without corrupting Markdown syntax.
- Provide an optional Markdown preview mode for common Markdown syntax.
- Implement reliable `Cmd+B` Markdown bold wrapping using text selection.
- Allow importing and exporting `.md` and `.txt` files.
- Package the app as an installable macOS `.dmg`.
- Keep the editor core modular enough to reuse in a future iOS version.
- Keep dependencies minimal and prefer native Swift, SwiftUI, and AppKit where needed.

## Quality Gates
These commands must pass for every user story:
- `swift build` - Build the Swift package.
- `swift test` - Run the test suite.

For packaging-related stories, the `.dmg` packaging script must also run successfully on macOS.

## User Stories

### US-001: Create Native App Shell
**Description:** As a prompt writer, I want PromptPad to open directly into one clean editor window so that I can start writing without navigating files, tabs, or sidebars.

**Acceptance Criteria:**
- [ ] App name is `PromptPad`.
- [ ] App launches to exactly one primary editor window.
- [ ] No sidebar, file tree, tab bar, document browser, or multi-document UI is present.
- [ ] Window uses SwiftUI as the app entry point.
- [ ] UI uses a light background, muted grey text, spacious padding, and minimal chrome.
- [ ] Editor text uses a soft serif font stack such as Georgia, Charter, New York, or Times-like fallback.
- [ ] Text size is large enough for comfortable long-form prompt writing.

### US-002: Implement Reusable Editor Core
**Description:** As a developer, I want the editor state and persistence logic separated from macOS-specific UI so that the core can later be reused for an iOS version.

**Acceptance Criteria:**
- [ ] Text state management is isolated from the macOS window shell.
- [ ] Persistence logic is implemented in a reusable service or model layer.
- [ ] macOS-specific AppKit bridging is kept separate from core editor logic.
- [ ] Core editor logic can be tested without launching the macOS UI.
- [ ] Code organization clearly separates app shell, editor model, persistence, and platform-specific editor view.

### US-003: Persist Single Local Document
**Description:** As a prompt writer, I want my writing to automatically persist locally so that quitting and reopening the app restores my last prompt.

**Acceptance Criteria:**
- [ ] App stores the single document as a local file in Application Support.
- [ ] On first launch, the editor opens with empty text if no saved document exists.
- [ ] On subsequent launches, the editor loads the last saved text automatically.
- [ ] Text autosaves continuously after edits.
- [ ] Quitting and reopening the app preserves typed content.
- [ ] No cloud sync or remote storage is used.
- [ ] Persistence handles missing Application Support directories by creating them.

### US-004: Build NSTextView-Based Editor
**Description:** As a prompt writer, I want a plaintext-first editor with reliable text selection so that Markdown editing and keyboard commands work predictably.

**Acceptance Criteria:**
- [ ] Editor is implemented with an `NSTextView` bridge inside SwiftUI.
- [ ] User can type and edit raw plaintext normally.
- [ ] Common Markdown syntax can be typed without automatic corruption or unwanted formatting.
- [ ] Selection state is accessible for editor commands.
- [ ] Editor supports large readable serif text.
- [ ] Editor respects the minimal visual design with no unnecessary toolbar.
- [ ] Editor remains focused and usable when the app launches.

### US-005: Implement Cmd+B Markdown Bold
**Description:** As a prompt writer, I want `Cmd+B` to insert Markdown bold syntax so that I can quickly format prompt text.

**Acceptance Criteria:**
- [ ] Pressing `Cmd+B` with selected text replaces the selection with `**selected text**`.
- [ ] Pressing `Cmd+B` with no selection inserts `****`.
- [ ] When inserting `****` with no selection, the cursor is placed between the two pairs of asterisks.
- [ ] Existing surrounding text is preserved.
- [ ] The command works inside the main editor without requiring toolbar interaction.
- [ ] The updated text is included in autosave behavior.

### US-006: Add Optional Markdown Preview Mode
**Description:** As a prompt writer, I want an optional preview mode so that I can inspect common Markdown formatting when needed while keeping editing plaintext-first.

**Acceptance Criteria:**
- [ ] App provides a minimal way to switch between edit mode and preview mode.
- [ ] Edit mode remains the default launch mode.
- [ ] Preview renders common Markdown syntax including headings, bold, italic, code blocks, and bullet lists.
- [ ] Preview mode does not modify the underlying raw Markdown text.
- [ ] Switching back to edit mode restores the editable raw Markdown content.
- [ ] Preview UI follows the same calm serif visual style.
- [ ] No full toolbar is introduced unless required for the preview toggle.

### US-007: Export Text as Markdown or Plain Text
**Description:** As a prompt writer, I want to export my current prompt as `.md` or `.txt` so that I can reuse it outside PromptPad.

**Acceptance Criteria:**
- [ ] User can export the current editor text as `.md`.
- [ ] User can export the current editor text as `.txt`.
- [ ] Export uses a native macOS save panel.
- [ ] Exported file contents exactly match the editor text.
- [ ] Export does not change the local persistent document path.
- [ ] Export does not introduce multi-document behavior.

### US-008: Import Markdown or Plain Text
**Description:** As a prompt writer, I want to import a `.md` or `.txt` file so that I can replace my single persistent prompt document with existing text.

**Acceptance Criteria:**
- [ ] User can import `.md` files.
- [ ] User can import `.txt` files.
- [ ] Import uses a native macOS open panel.
- [ ] Import replaces the current single persistent document.
- [ ] App asks for confirmation before replacing existing non-empty text.
- [ ] Imported text appears in the editor after confirmation.
- [ ] Imported text becomes the autosaved persistent document.
- [ ] Import does not create tabs, sidebars, or multiple documents.

### US-009: Add Build, Run, and DMG Packaging Scripts
**Description:** As a developer, I want clear terminal commands and packaging scripts so that PromptPad can be built, run, and distributed as a `.dmg`.

**Acceptance Criteria:**
- [ ] Repository includes clear terminal instructions for building the app.
- [ ] Repository includes clear terminal instructions for running the app.
- [ ] Repository includes a script that packages the macOS app into a `.dmg`.
- [ ] Packaging script produces a `.dmg` artifact on macOS.
- [ ] Packaging script documents any required macOS tools.
- [ ] `.dmg` output includes the built PromptPad app.
- [ ] Instructions include `swift build`, `swift test`, and the package command.

### US-010: Add Focused Tests
**Description:** As a developer, I want tests around reusable editor behavior so that persistence and Markdown commands remain reliable.

**Acceptance Criteria:**
- [ ] Tests cover loading empty text when no local document exists.
- [ ] Tests cover saving and reloading persisted text.
- [ ] Tests cover `Cmd+B` behavior with selected text.
- [ ] Tests cover `Cmd+B` behavior with no selected text.
- [ ] Tests cover import replacement logic at the model/service level where practical.
- [ ] Tests avoid requiring the full macOS UI where logic can be tested directly.

## Functional Requirements
- FR-1: The system must launch as a native macOS SwiftUI app named `PromptPad`.
- FR-2: The system must display one primary editor window only.
- FR-3: The system must not include tabs, sidebars, file trees, or multi-document workflows.
- FR-4: The system must store the persistent document as a local file in Application Support.
- FR-5: The system must automatically load the saved local document on launch.
- FR-6: The system must autosave text continuously after edits.
- FR-7: The system must allow raw Markdown syntax to be typed directly.
- FR-8: The system must support an optional Markdown preview mode.
- FR-9: The preview mode must render headings, bold, italic, code blocks, and bullet lists.
- FR-10: The system must use an `NSTextView` bridge for reliable selection and keyboard command handling.
- FR-11: Pressing `Cmd+B` with selected text must wrap the selected text in double asterisks.
- FR-12: Pressing `Cmd+B` without selected text must insert `****` and place the cursor between the asterisk pairs.
- FR-13: The system must export the current editor text as `.md`.
- FR-14: The system must export the current editor text as `.txt`.
- FR-15: The system must import `.md` and `.txt` files.
- FR-16: Importing must replace the single persistent document after confirmation.
- FR-17: The system must include documented terminal commands for build, run, test, and package.
- FR-18: The system must include a macOS packaging script that creates a `.dmg`.
- FR-19: The codebase must keep reusable editor logic separate from macOS-specific UI code.

## Non-Goals
- No cloud sync.
- No iCloud integration.
- No file tree.
- No sidebar.
- No tabs.
- No multi-document editing.
- No rich text editing as the primary model.
- No database storage.
- No collaboration features.
- No plugin system.
- No full Markdown WYSIWYG editor.
- No iOS app implementation in v1.
- No complex theme system beyond the initial calm light visual style.

## Technical Considerations
- Use Swift and SwiftUI for the app shell.
- Use AppKit `NSTextView` through a SwiftUI bridge for selection-aware editing and `Cmd+B`.
- Store the persistent text file under Application Support, likely in an app-specific directory such as `Application Support/PromptPad/`.
- Keep persistence behind a small protocol or service so tests can use a temporary directory.
- Keep editor transformations such as Markdown bold wrapping in a platform-neutral model/helper.
- Prefer native APIs and avoid third-party dependencies unless required.
- Markdown preview can use native parsing/rendering if available, or a minimal dependency only if justified.
- Packaging should be scriptable from terminal on macOS and documented in the repository.

## Success Metrics
- A user can launch PromptPad and begin writing within one clean editor window.
- Text typed into the editor persists after quitting and reopening the app.
- `Cmd+B` produces correct Markdown bold syntax with and without selected text.
- Raw Markdown remains editable as plaintext.
- Markdown preview renders the required common syntax without modifying source text.
- User can export the prompt as `.md`.
- User can import `.md` or `.txt` and replace the single persistent document after confirmation.
- A developer can run documented build, test, and package commands successfully.
- The packaging script produces a usable `.dmg` on macOS.

## Open Questions
- Should the preview toggle be exposed through a minimal menu item, keyboard shortcut, compact inline control, or all of these?
- Should the app use a custom bundle identifier, and if so what should it be?
- Should the `.dmg` include a stylized background and Applications shortcut, or stay minimal for v1?