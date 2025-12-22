// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Layover",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "LayoverKit",
            type: .static,
            targets: ["LayoverKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LayoverKit",
            dependencies: [],
            path: "Sources",
            exclude: ["LayoverApp.swift"],
            resources: [.process("../Resources")]
        ),
        .testTarget(
            name: "LayoverTests",
            dependencies: ["LayoverKit"],
            path: "Tests"
        ),
    ]
)
