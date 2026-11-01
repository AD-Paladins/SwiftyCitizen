// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftyCitizenCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13),
    ],
    products: [
        .library(name: "SwiftyCitizenCore", targets: ["SwiftyCitizenCore"]),
    ],
    targets: [
        .target(
            name: "SwiftyCitizenCore",
            path: "Sources/SwiftyCitizenCore"
        ),
        .testTarget(
            name: "SwiftyCitizenCoreTests",
            dependencies: ["SwiftyCitizenCore"],
            path: "Tests/SwiftyCitizenCoreTests"
        ),
    ]
)
