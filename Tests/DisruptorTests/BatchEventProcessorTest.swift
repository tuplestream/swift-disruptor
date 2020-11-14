/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import XCTest
@testable import Disruptor
import Atomics

class BatchEventProcessorTests: XCTestCase {

    private var ringBuffer: RingBuffer<StubEvent>!
    private var sequenceBarrier: SequenceBarrier!

    override func setUp() {
        ringBuffer = RingBuffer<StubEvent>.createMultiProducer(factory: StubEventFactory(), bufferSize: 16)
        sequenceBarrier = ringBuffer.newBarrier(sequencesToTrack: [])
    }
}
