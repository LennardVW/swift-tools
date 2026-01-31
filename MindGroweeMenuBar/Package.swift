// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Compatible with macOS Tahoe (15.0+)

import PackageDescription

let package = Package(
    name: "MindGroweeMenuBar",
    platforms: [
        .macOS(.v15) // Tahoe
    ],
    products: [
        .executable(
            name: "MindGroweeMenuBar",
            targets: ["MindGroweeMenuBar"]
        ),
    ],
    dependencies: [
        // No external dependencies - using native SwiftUI & AppKit
    ],
    targets: [
        .executableTarget(
            name: "MindGroweeMenuBar",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "MindGroweeMenuBarTests",
            dependencies: ["MindGroweeMenuBar"]
        ),
    ]
)
