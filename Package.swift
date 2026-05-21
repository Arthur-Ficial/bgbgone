// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "bgbgone",
    platforms: [.macOS(.v26)],
    targets: [
        // Pure-logic library — no Vision/CoreImage deps. Testable in isolation.
        .target(
            name: "BgBgOneCore",
            dependencies: [],
            path: "Sources/Core"
        ),
        // Main executable — depends on BgBgOneCore + Apple frameworks.
        .executableTarget(
            name: "bgbgone",
            dependencies: [
                "BgBgOneCore",
            ],
            path: "Sources",
            exclude: ["Core"]
        ),
        // Pure-Swift test runner — no XCTest/Testing dependency.
        .executableTarget(
            name: "bgbgone-tests",
            dependencies: ["BgBgOneCore"],
            path: "Tests/bgbgoneTests"
        ),
    ]
)
