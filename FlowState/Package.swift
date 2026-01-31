// swift-tools-version:6.0
// FlowState - AI-powered flow state detection for macOS
// Detects when you're in flow and optimizes your environment

import PackageDescription

let package = Package(
    name: "FlowState",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "flowstate", targets: ["FlowState"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "FlowState",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
