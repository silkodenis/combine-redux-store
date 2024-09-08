// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CombineStore",
    platforms: [
            .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
        ],
    products: [
        .library(
            name: "CombineStore",
            targets: ["CombineStore"]),
    ],
    targets: [
        .target(
            name: "CombineStore"),
        .testTarget(
            name: "CombineStoreTests",
            dependencies: ["CombineStore"]),
    ]
)
