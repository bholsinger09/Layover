// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Layover",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "Layover",
            targets: ["Layover"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Layover",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "LayoverTests",
            dependencies: ["Layover"],
            path: "Tests"
        ),
    ]
)
