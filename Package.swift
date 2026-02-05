// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "XcodeDeck",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "xcodedeck", targets: ["XcodeDeck"]),
        .library(name: "XcodeDeckCore", targets: ["XcodeDeckCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "XcodeDeck",
            dependencies: ["XcodeDeckCore"]
        ),
        .target(
            name: "XcodeDeckCore",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "XcodeDeckTests",
            dependencies: ["XcodeDeckCore"]
        ),
    ]
)
