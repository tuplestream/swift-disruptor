/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import XCTest
@testable import Disruptor
import Atomics

class StubEvent: CustomStringConvertible {
    var i: Int

    init(_ i: Int = 0) {
        self.i = i
    }

    var description: String {
        get {
            return "value: \(i)"
        }
    }
}

class StubEventFactory: EventFactory {
    typealias Event = StubEvent

    func newInstance() -> StubEvent {
        return StubEvent()
    }
}

class StubEventTranslator: EventTranslator {
    typealias Event = StubEvent
    typealias Input = Int

    func translateTo(_ event: inout StubEvent, sequence: Int64, input: Int) {
        event.i = input
    }
}

class StubEventHandler: EventHandler {
    typealias Event = StubEvent

    func onEvent(_ event: StubEvent, sequence: Int64, endOfBatch: Bool) {
        print("\(event) / seq: \(sequence)")
    }
}

class DummyEventProcessor: EventProcessor {

    public private(set) var sequence: Sequence
    private let running = ManagedAtomic<Bool>(false)

    init(_ sequence: Sequence = Sequence(initialValue: -1)) {
        self.sequence = sequence
    }

    func run() {
        precondition(running.compareExchange(expected: false, desired: true, ordering: .acquiringAndReleasing).exchanged,
                     "already running")
    }

    func setSequence(_ value: Int64) {
        sequence.value = value
    }

    func halt() {
        running.store(false, ordering: .relaxed)
    }

    var isRunning: Bool {
        get {
            return running.load(ordering: .relaxed)
        }
    }

}

final class DisruptorTests: XCTestCase {

    func overallTest() {

    }
}
