// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Meine",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MeineCore", targets: ["MeineCore"])
    ],
    targets: [
        .target(name: "MeineCore", path: "Sources/MeineCore"),
        .testTarget(
            name: "MeineCoreTests",
            dependencies: ["MeineCore"],
            path: "Tests/MeineCoreTests"
        )
    ]
)
