import XCTest
@testable import PromptPadCore

final class PromptPadStyleTests: XCTestCase {
    func testStyleMatchesNativeAppShellRequirements() {
        XCTAssertEqual(PromptPadStyle.appName, "PromptPad")
        XCTAssertEqual(PromptPadStyle.editorFontName, "Georgia")
        XCTAssertTrue(PromptPadStyle.editorFontFallbacks.contains("Charter"))
        XCTAssertTrue(PromptPadStyle.editorFontFallbacks.contains("New York"))
        XCTAssertGreaterThanOrEqual(PromptPadStyle.editorFontSize, 20)
        XCTAssertGreaterThanOrEqual(PromptPadStyle.editorPadding, 32)
    }
}
