# swift-disruptor

[![CircleCI](https://img.shields.io/circleci/build/github/tuplestream/swift-disruptor)](https://app.circleci.com/pipelines/github/tuplestream/swift-disruptor)
[![Gitter](https://badges.gitter.im/tuplestream/oss.svg)](https://gitter.im/tuplestream/oss?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

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

Although you can create and manipulate ring buffer and sequencers directly, it's easier in most cases to work with the higher level Disruptor & Translator components for publishing and handling messages:

```swift
// 1) Import the Disruptor module
import Disruptor

// 2) Declare a message type we want to pass, and a factory for its
// pre-allocation in the ring buffer
final class LongEvent {
    var value: Int64 = 0
}

class LongEventFactory: EventFactory {
    typealias Event = LongEvent

    func newInstance() -> LongEvent {
        return LongEvent()
    }
}

// 3) Implement an EventHandler to be run from a consuming thread:
final class LongEventHandler: EventHandler {
    typealias Event = LongEvent

    func onEvent(_ event: LongEvent, sequence: Int64, endOfBatch: Bool) {
        print("🚀 \(event.value)")
    }
}
```

Since the `LongEvent` objects are allocated only once when we create the disruptor, we need a way of passing new values from producers. For this we need to implement an `EventTranslator`:

```swift
// 4) Our translator assigns newly produced long values to a claimed LongEvent from the ring buffer
class LongEventTranslator: EventTranslator {
    typealias Event = LongEvent
    typealias Input = Int64

    func translateTo(_ event: inout LongEvent, sequence: Int64, input: Int64) {
        event.value = input
    }
}
```

Finally we need to wire it all together- let's instantiate a disruptor (the ring buffer can be sized up pretty bit, but it should fit inside L3 cache and it _must_ be a power of 2):

```swift
// 5) Instantiate a Disruptor 
let disruptor = Disruptor<LongEvent>(eventFactory: LongEventFactory(), ringBufferSize: 512, producerType: .single)

// let's just add a single consumer:
disruptor.handleEventsWith(eventHandlers: [LongEventHandler()])

// start the consumers
disruptor.start()

// publish an event
disruptor.publishEvent(LongEventTranslator(), input: 1)
```

## Contributing

Have a look at the [list of issues](https://github.com/tuplestream/swift-disruptor/issues). Bug reports (including perceived performance issues) are much appreciated.

#### Building

This package uses the [Swift Atomics](https://github.com/apple/swift-atomics) library and needs double-word atomic support explicitly enabled on Linux. For example:

`swift test -Xcc -mcx16 -Xswiftc -DENABLE_DOUBLEWIDE_ATOMICS`

#### Benchmarks

Benchmarks are pretty unstable right now- there's a separate target with an executable which you can invoke:

`swift run -c release`

Currently there's a single producer/single consumer scenario (with no batching) with both disruptor and GCD. Most disruptor implementations diverge more markedly from queues in multi producer/consumer environments so reproducing this and finding bottlenecks is a priority.
