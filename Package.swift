// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StatusFlow",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "StatusFlow", targets: ["StatusFlow"])
    ],
    targets: [
        .executableTarget(
            name: "StatusFlow",
            path: "Sources/StatusFlow"
        )
    ]
)
