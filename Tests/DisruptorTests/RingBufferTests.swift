/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import XCTest
@testable import Disruptor

class RingBufferTests: XCTestCase {

    private var ringBuffer: RingBuffer<StubEvent,StubEventFactory>!

    override func setUp() {
        ringBuffer = RingBuffer<StubEvent, StubEventFactory>.createMultiProducer(factory: StubEventFactory(), bufferSize: 32)
    }

    func testShouldClaimAndGet() {
        XCTAssertEqual(MultiProducerSequencer.initialCursorValue, ringBuffer.cursor)

        let expectedEvent = StubEvent(2701)
    }
}
