// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Disruptor",
    products: [
        .library(
            name: "Disruptor",
            targets: ["Disruptor"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Disruptor",
            dependencies: []),
        .testTarget(
            name: "DisruptorTests",
            dependencies: ["Disruptor"]),
    ]
)
