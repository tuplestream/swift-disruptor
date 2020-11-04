/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import XCTest
@testable import Disruptor

class SequenceBarrierTests: XCTestCase {

    private var ringBuffer: RingBuffer<StubEvent,StubEventFactory>!
    private var translator: StubEventTranslator!

    override func setUp() {
        ringBuffer = RingBuffer<StubEvent, StubEventFactory>.createMultiProducer(factory: StubEventFactory(), bufferSize: 64)
        ringBuffer.addGatingSequences(sequences: NoOpEventProcessor(ringBuffer).sequence)
        translator = StubEventTranslator()
    }

    func testShouldWaitForWorkCompleteWhereCompleteWorkThresholdIsAhead() {
        let expectedNumberMessages = 10
        let expectedWorkSequence = 9
        fillRingBuffer(expectedNumberMessages)

        let s1 = Sequence(initialValue: Int64(expectedNumberMessages))
        let s2 = Sequence(initialValue: Int64(expectedWorkSequence))
        let s3 = Sequence(initialValue: Int64(expectedNumberMessages))

        let barrier = ringBuffer.newBarrier(sequencesToTrack: s1, s2, s3)

        let completedWorkSequence = try! barrier.waitFor(sequence: Int64(expectedWorkSequence))
        XCTAssertTrue(completedWorkSequence >= expectedWorkSequence)
    }

    func testShouldWaitForWorkCompleteWhereAllWorkersAreBlockedOnRingBuffer() {
        let expectedNumberMessages = 10
        fillRingBuffer(expectedNumberMessages)

        var workers = Array<DummyEventProcessor>()
        for _ in 0..<3 {
            let ep = DummyEventProcessor()
            ep.setSequence(Int64(expectedNumberMessages) - 1)
            workers.append(ep)
        }

        let sequenceBarrier = ringBuffer.newBarrier(sequencesToTrack: SequenceUtils.getSequencesFor(processors: workers))

        let runnable = DispatchWorkItem {
            let sequence = self.ringBuffer.next()
            let event = self.ringBuffer.get(sequence: sequence)
            event.i = Int(sequence)
            self.ringBuffer.publish(sequence)

            for worker in workers {
                worker.setSequence(sequence)
            }
        }

        DispatchQueue(label: "barrierTest").async(execute: runnable)

        let expectedWorkSequence = Int64(expectedNumberMessages)
        let completedWorkSequence = try! sequenceBarrier.waitFor(sequence: Int64(expectedNumberMessages))

        XCTAssertGreaterThanOrEqual(completedWorkSequence, expectedWorkSequence)
    }

    func testShouldInterruptDuringBusySpin() {
        let expectedNumberMessages = 10
        fillRingBuffer(expectedNumberMessages)
    }



    private func fillRingBuffer(_ expectedNumberMessages: Int) {
        for i in 0..<expectedNumberMessages {
            let sequence = ringBuffer.next()
            let event = ringBuffer.get(sequence: sequence)
            event.i = i
            ringBuffer.publish(sequence)
        }
    }
}
