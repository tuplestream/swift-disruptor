// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-disruptor",
    products: [
        .library(
            name: "Disruptor",
            targets: ["Disruptor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-atomics.git",from: "0.0.1"),
    ],
    targets: [
        .target(name: "_Volatile", dependencies: []),
        .target(
            name: "Disruptor",
            dependencies: [.target(name: "_Volatile"),
                           .product(name: "Atomics", package: "swift-atomics")]),
        .testTarget(
            name: "DisruptorTests",
            dependencies: [
                .target(name: "Disruptor"),
                .product(name: "Atomics", package: "swift-atomics"),
            ]),
    ]
)
