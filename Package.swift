// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProcBridge",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ProcBridge",
            targets: ["ProcBridge"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Kitura/BlueSocket.git", .upToNextMajor(from: "2.0.4")),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .upToNextMajor(from: "5.0.2")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ProcBridge",
            dependencies: [
                .product(name: "Socket", package: "BlueSocket"),
                "SwiftyJSON",
            ]
        ),
        .testTarget(
            name: "ProcBridgeTests",
            dependencies: ["ProcBridge"]),
    ]
)
