// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WayneNetwork",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "WayneNetwork",
            targets: ["WayneNetwork"]),
    ],
    targets: [
        .target(
            name: "WayneNetwork",
            dependencies: []),
        .testTarget(
            name: "WayneNetworkTests",
            dependencies: ["WayneNetwork"]),
    ]
)

