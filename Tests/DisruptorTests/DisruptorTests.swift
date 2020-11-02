/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import XCTest
@testable import Disruptor

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

    func translateTo(_ event: StubEvent, sequence: Int64, input: Int) {
        event.i = input
    }
}

class StubEventHandler: EventHandler {
    typealias Event = StubEvent

    func onEvent(_ event: StubEvent, sequence: Int64, endOfBatch: Bool) {
        print("\(event) / seq: \(sequence)")
    }
}

final class DisruptorTests: XCTestCase {

    func overallTest() {

    }
}
