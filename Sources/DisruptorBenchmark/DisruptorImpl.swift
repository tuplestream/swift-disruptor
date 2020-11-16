/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/

import Atomics
import Disruptor
import Foundation

final class LongEvent {
    var value: Int64 = 0
}

class LongEventFactory: EventFactory {
    typealias Event = LongEvent

    func newInstance() -> LongEvent {
        return LongEvent()
    }
}

final class LongEventHandler: EventHandler {
    typealias Event = LongEvent

    var internalCounter: Int64 = 0

    func onEvent(_ event: LongEvent, sequence: Int64, endOfBatch: Bool) {
        internalCounter += 1
    }
}

class LongEventTranslator: EventTranslator {
    typealias Event = LongEvent
    typealias Input = Int64

    func translateTo(_ event: inout LongEvent, sequence: Int64, input: Int64) {
        event.value = input
    }
}

class DisruptorBenchmark: Benchmark {

    let name = "Disruptor"

    private let disruptor: Disruptor<LongEvent>
    private let handler: LongEventHandler

    init() {
        disruptor = Disruptor<LongEvent>(eventFactory: LongEventFactory(), ringBufferSize: 512, producerType: .single)
        handler = LongEventHandler()
        disruptor.handleEventsWith(eventHandlers: [handler])
    }

    func benchmarkRun() {
        let _ = disruptor.start()

        let translator = LongEventTranslator()
        let iterations = 10240000

        for _ in 0..<iterations {
            disruptor.publishEvent(translator, input: 1)
        }

//        print("submitted")

        while handler.internalCounter < iterations {
            Thread.sleep(forTimeInterval: 0.001)
        }
//        print("done: \(handler.internalCounter)")
    }
}
