// swift-tools-version:6.0
// ContextClip - Clipboard with context awareness
// Knows WHERE you copied from, not just WHAT

import PackageDescription

let package = Package(
    name: "ContextClip",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "contextclip", targets: ["ContextClip"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ContextClip",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
