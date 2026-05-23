// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "bgbgone",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        // Pure-logic library — no Vision/CoreImage deps. Testable in isolation.
        .target(
            name: "BgBgOneCore",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/Core"
        ),
        // Main executable — depends on BgBgOneCore + Apple frameworks.
        .executableTarget(
            name: "bgbgone",
            dependencies: [
                "BgBgOneCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources",
            exclude: ["Core"]
        ),
        // Pure-Swift test runner — no XCTest/Testing dependency.
        .executableTarget(
            name: "bgbgone-tests",
            dependencies: [
                "BgBgOneCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Tests/bgbgoneTests"
        ),
    ]
)
