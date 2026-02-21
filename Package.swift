// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Coordinator",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Coordinator",
            type: .static,
            targets: ["Coordinator"]
        )
    ],
    targets: [
        .target(
            name: "Coordinator",
            path: "Sources/Coordinator",
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        )
    ]
)
