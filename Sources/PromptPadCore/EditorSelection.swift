import Foundation

public struct EditorSelection: Equatable, Sendable {
    public let location: Int
    public let length: Int

    public static let zero = EditorSelection(location: 0, length: 0)

    public init(location: Int, length: Int) {
        self.location = max(0, location)
        self.length = max(0, length)
    }
}
