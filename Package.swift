// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AiMessage",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "AiMessage",
            targets: ["AiMessage"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AiMessage",
            dependencies: [],
            path: "Sources"
        ),
    ]
)