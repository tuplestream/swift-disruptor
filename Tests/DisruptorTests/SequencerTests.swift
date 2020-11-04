/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import XCTest
@testable import Disruptor

class DummyWaitStrategy: WaitStrategy {

    var signalAllWhenBlockingCalls = 0

    func waitFor(sequence: Int64, cursor: Sequence, dependentSequence: Sequence, barrier: SequenceBarrier) throws -> Int64 {
        return 0
    }

    func signalAllWhenBlocking() {
        signalAllWhenBlockingCalls += 1
    }
}

final class SequencerTests: XCTestCase {

    static let bufferSize: Int32 = 16

    var sequencer: MultiProducerSequencer!
    var gatingSequence: Sequence!

    override func setUp() {
        sequencer = MultiProducerSequencer(bufferSize: SequencerTests.bufferSize, waitStrategy: BlockingWaitStrategy())
        gatingSequence = Sequence()
    }

    func testShouldStartWithInitialValue() {
        XCTAssertEqual(0, sequencer.next())
    }

    func testShouldBatchClaim() {
        XCTAssertEqual(3, sequencer.next(4))
    }

    func testShouldIndicateHasAvailableCapacity() {
        sequencer.addGatingSequences(sequences: [gatingSequence])

        XCTAssertTrue(sequencer.hasAvailableCapacity(required: 1))
        XCTAssertTrue(sequencer.hasAvailableCapacity(required: SequencerTests.bufferSize))
        XCTAssertFalse(sequencer.hasAvailableCapacity(required: SequencerTests.bufferSize + 1))

        sequencer.publish(sequencer.next())

        XCTAssertTrue(sequencer.hasAvailableCapacity(required: SequencerTests.bufferSize - 1))
        XCTAssertFalse(sequencer.hasAvailableCapacity(required: SequencerTests.bufferSize))
    }

    func testShouldIndicateNoAvailableCapacity() {
        sequencer.addGatingSequences(sequences: [gatingSequence])

        let sequence = sequencer.next(SequencerTests.bufferSize)
        sequencer.publish(low: sequence - (Int64(SequencerTests.bufferSize) - 1), high: sequence)

        XCTAssertFalse(sequencer.hasAvailableCapacity(required: 1))
    }

    func testShouldHoldUpPublisherWhenBufferIsFull() {
        
    }

    func testShouldNotBeAvailableUntilPublished() {
        let next = sequencer.next(6)

        for i: Int64 in 0...5 {
            XCTAssertFalse(sequencer.isAvailable(sequence: i))
        }

        sequencer.publish(low: next - (6 - 1), high: next)

        for i: Int64 in 0...5 {
            XCTAssertTrue(sequencer.isAvailable(sequence: i))
        }

        XCTAssertFalse(sequencer.isAvailable(sequence: 6))
    }

    func testShouldNotifyWaitStrategyOnPublish() {
        let dummyWaitStrategy = DummyWaitStrategy()
        let sequencer = MultiProducerSequencer(bufferSize: SequencerTests.bufferSize, waitStrategy: dummyWaitStrategy)

        sequencer.publish(sequencer.next())

        XCTAssertEqual(1, dummyWaitStrategy.signalAllWhenBlockingCalls)
    }

    func testShouldNotifyWaitStrategyOnPublishBatch() {
        let dummyWaitStrategy = DummyWaitStrategy()
        let sequencer = MultiProducerSequencer(bufferSize: SequencerTests.bufferSize, waitStrategy: dummyWaitStrategy)

        let next = sequencer.next(4)
        sequencer.publish(low: next - (4 - 1), high: next)

        XCTAssertEqual(1, dummyWaitStrategy.signalAllWhenBlockingCalls)
    }

    func testShouldWaitOnPublication() {
        let barrier = sequencer.newBarrier()

        let next = sequencer.next(10)
        let lo = next - (10 - 1)
        let mid = next - 5

        for l in lo..<mid {
            sequencer.publish(l)
        }

        XCTAssertEqual(mid - 1, try! barrier.waitFor(sequence: -1))
    }

    func testShouldTryNext() {
        // TODO
    }

    func testShouldClaimSpecificSequence() {
        let sequence: Int64 = 14

        sequencer.claim(sequence: sequence)
        sequencer.publish(sequence)
        XCTAssertEqual(sequencer.next(), sequence + 1)
    }

}

class MultiProducerSequencerTests: XCTestCase {

    func testShouldOnlyAllowMessagesToBeAvailableIfSpecificallyPublished() {
        let publisher = MultiProducerSequencer(bufferSize: 1024, waitStrategy: BlockingWaitStrategy())

        publisher.publish(3)
        publisher.publish(5)

        XCTAssertFalse(publisher.isAvailable(sequence: 0))
        XCTAssertFalse(publisher.isAvailable(sequence: 1))
        XCTAssertFalse(publisher.isAvailable(sequence: 2))
        XCTAssertTrue(publisher.isAvailable(sequence: 3))
        XCTAssertFalse(publisher.isAvailable(sequence: 4))
        XCTAssertTrue(publisher.isAvailable(sequence: 5))
        XCTAssertFalse(publisher.isAvailable(sequence: 6))
    }
}
