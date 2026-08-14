// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "SuperAgeCore",
    platforms: [
        .macOS(.v13),
        .iOS(.v15),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "SuperAgeCore",
            targets: ["SuperAgeCore"]
        )
    ],
    targets: [
        .target(
            name: "SuperAgeCore"
        ),
        .testTarget(
            name: "SuperAgeCoreTests",
            dependencies: ["SuperAgeCore"],
            resources: [
                .process("Fixtures")
            ]
        )
    ]
)
