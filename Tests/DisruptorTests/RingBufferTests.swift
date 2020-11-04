/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import XCTest
@testable import Disruptor

class RingBufferTests: XCTestCase {

    private var ringBuffer: RingBuffer<StubEvent,StubEventFactory>!
    private var sequenceBarrier: SequenceBarrier!
    private var translator: StubEventTranslator!

    override func setUp() {
        ringBuffer = RingBuffer<StubEvent, StubEventFactory>.createMultiProducer(factory: StubEventFactory(), bufferSize: 32)
        ringBuffer.addGatingSequences(sequences: NoOpEventProcessor(ringBuffer).sequence)
        sequenceBarrier = ringBuffer.newBarrier()
        translator = StubEventTranslator()
    }

    func testShouldClaimAndGet() {
        XCTAssertEqual(MultiProducerSequencer.initialCursorValue, ringBuffer.cursor)

        let expectedEvent = StubEvent(2701)

        ringBuffer.publishEvent(translator: translator, input: expectedEvent.i)

        let sequence = try! sequenceBarrier.waitFor(sequence: 0)
        XCTAssertEqual(0, sequence)

        let event = ringBuffer.get(sequence: 0)
        XCTAssertEqual(expectedEvent.i, event.i)
        XCTAssertEqual(0, ringBuffer.cursor)
    }

    func testShouldClaimAndGetInSeparateThread() {
        // TODO
    }

    func testShouldClaimAndGetMultipleMessages() {
        for i in 0..<ringBuffer.bufferSize {
            ringBuffer.publishEvent(translator: translator, input: Int(i))
        }

        let expectedSequence = Int64(ringBuffer.bufferSize - 1)
        let available = try! sequenceBarrier.waitFor(sequence: expectedSequence)
        XCTAssertEqual(expectedSequence, available)

        for i in 0..<ringBuffer.bufferSize {
            XCTAssertEqual(Int(i), ringBuffer.get(sequence: Int64(i)).i)
        }
    }

    func testShouldWrap() {
        let offset: Int32 = 1000
//        for i in 0..<ringBuffer.bufferSize + offset {
//            ringBuffer.publishEvent(translator: translator, input: Int(i))
//        }

//        print("NXT: \(ringBuffer.next())")
//
//        let expectedSequence = Int64(ringBuffer.bufferSize + offset - 1)
//        let availableSequence = try! sequenceBarrier.waitFor(sequence: expectedSequence)
//        XCTAssertEqual(expectedSequence, availableSequence)
    }
}
