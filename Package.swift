// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CombineReduxStore",
    platforms: [
            .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
        ],
    products: [
        .library(
            name: "CombineReduxStore",
            targets: ["CombineReduxStore"]),
    ],
    targets: [
        .target(
            name: "CombineReduxStore"),
        .testTarget(
            name: "CombineReduxStoreTests",
            dependencies: ["CombineReduxStore"]),
    ]
)
