// swift-tools-version:6.0
// macOS Tahoe (15.0+) compatible CLI tool

import PackageDescription

let package = Package(
    name: "DevCLI",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "devcli",
            targets: ["DevCLI"]
        ),
    ],
    dependencies: [
        // Pure Swift - no dependencies needed
    ],
    targets: [
        .executableTarget(
            name: "DevCLI",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "DevCLITests",
            dependencies: ["DevCLI"]
        ),
    ]
)
