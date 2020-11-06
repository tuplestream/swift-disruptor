# swift-disruptor

[![CircleCI](https://img.shields.io/circleci/build/github/tuplestream/swift-disruptor)](https://app.circleci.com/pipelines/github/tuplestream/swift-disruptor)
[![Gitter](https://badges.gitter.im/tuplestream/community.svg)](https://gitter.im/tuplestream/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

Disruptor is an (almost) pure-Swift implementation of the inter-thread messaging library & concurrent design pattern of the same name. It aims to reach feature parity with the [reference implementation by LMAX](https://github.com/LMAX-Exchange/disruptor).

## Getting started

#### Adding the package

Swift Disruptor uses [SwiftPM](https://swift.org/package-manager/) as its build tool. Add the package in the usual way, first with a new `dependencies` clause:

```swift
dependencies: [
    .package(url: "https://github.com/tuplestream/swift-disruptor.git", from: "0.10.0")
]
```
then add the `Disruptor` module to your target dependencies:

```swift
dependencies: [.product(name: "Disruptor", package: "swift-disruptor"),]
```

#### Integrating in your code

```swift
// 1) Import the Disruptor module
import Disruptor

// 2) TODO
```
