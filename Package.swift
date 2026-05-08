// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LayoutEngine",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "LayoutEngine",
            targets: ["LayoutEngine"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LayoutEngine",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "LayoutEngineTests",
            dependencies: ["LayoutEngine"],
            path: "Tests"
        )
    ]
)
