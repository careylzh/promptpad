promptpad: 
- [x] query how is persistence implemented now. Done: documented current local UTF-8 file storage, restore, autosave, import, and error-handling behavior.
- [x] double empty line in edit mode = line dash across the app in preview. Done: two blank lines render a divider; `swift test` passed.
- [x] support table syntax in preview. Done: pipe tables render as native grids; `swift test` passed.
- [x] add README.txt documenting steps to install this app, and local UTF-8 file persistence, launch restore, atomic autosave/import behavior, protocol-based architecture, and current synchronous un-debounced silent-error limitation. Done: installation and persistence behavior documented.
- [x] write a shell script to build and generate an unsigned .app. Done: `scripts/build-app.sh` produced a launchable ad-hoc-signed `dist/PromptPad.app` without a Developer ID certificate.
- [x] in the preview, add a line spacing before and after the line. Done: preview dividers now have explicit vertical padding.
- [x] single-line spacings should be reflected in the preview section. (i.e. when user presses enter it's effectively a new line, reflected as an empty line spacing in the preview.) Done: single blank lines render as explicit preview spacers.
* [ ] markdown syntax visualisation in preview
    * [x] bold. Done: strong emphasis renders in Preview and is covered by a semantic renderer test.
    * [x] italic. Done: emphasis renders in Preview and is covered by a semantic renderer test.
    * [x] bold and italic combined. Done: combined strong emphasis is covered by a semantic renderer test.
    * [x] strikethrough. Done: strikethrough renders in Preview and is covered by a semantic renderer test.
    * [x] headings (levels 1–6). Done: headings render as explicit blocks with descending type sizes and parser coverage.
    * [x] inline code. Done: inline code renders in Preview and is covered by a semantic renderer test.
    * [x] fenced code blocks, including optional language identifiers. Done: fenced code renders in a monospaced panel with optional language labels and preserves blank lines.
    * [x] blockquotes. Done: contiguous quote lines render with a quote rail and italic content; parser coverage added.
    * [x] unordered lists. Done: unordered rows render with bullet markers and parser coverage.
    * [ ] ordered lists
    * [ ] nested lists
    * [ ] task lists with checked and unchecked items
    * [ ] links (`[label](https://example.com)`)
    * [ ] images (`![alt text](https://example.com/image.png)`)
    * [ ] automatic links (`<https://example.com>`)
    * [ ] horizontal rules (`---`, `***`, or `___`)
    * [ ] escaped Markdown characters
    * [ ] hard line breaks
* [ ] add image icon to app
