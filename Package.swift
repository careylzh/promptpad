// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PromptPad",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(name: "PromptPad", targets: ["PromptPad"]),
        .library(name: "PromptPadCore", targets: ["PromptPadCore"])
    ],
    targets: [
        .executableTarget(
            name: "PromptPad",
            dependencies: ["PromptPadCore"]
        ),
        .target(name: "PromptPadCore"),
        .testTarget(
            name: "PromptPadCoreTests",
            dependencies: ["PromptPadCore"]
        )
    ]
)
