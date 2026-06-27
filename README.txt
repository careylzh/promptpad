PromptPad
=========

Installation
------------

PromptPad requires macOS 14 or newer. To install a packaged build, open
PromptPad.dmg and drag PromptPad.app onto the Applications shortcut. Then launch
PromptPad from Applications. If macOS warns that the app came from an unidentified
developer, control-click the app, choose Open, and confirm Open.

To build the installable disk image from source, install Xcode or the Xcode
Command Line Tools, then run:

  ./scripts/package-dmg.sh

The generated installer is dist/PromptPad.dmg. For development without installing,
run the app directly with:

  swift run PromptPad

Persistence
-----------

PromptPad stores one local UTF-8 text file. It does not use a database, cloud
storage, or synchronization service. The document is stored at:

  ~/Library/Application Support/PromptPad/prompt.txt

On launch, PromptPad loads this file automatically. If it does not exist, the
editor starts empty. Every change to editor.text triggers an immediate atomic
write. Importing Markdown or plain text replaces this persistent document;
exporting does not change its location.

EditorPersistence defines the load and save interface used by PromptEditorModel.
FileEditorPersistence implements local file storage, while tests can use an
in-memory implementation without depending on the file system.

Current limitation
------------------

Autosave is synchronous and un-debounced, so each text change writes immediately.
Autosave errors are discarded with try? and are not shown to the user. The
implementation is in Sources/PromptPad/PromptPadApp.swift and
Sources/PromptPadCore/EditorPersistence.swift.
