/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation

public final class RingBuffer<E>: Cursored, Sequenced {

    public let bufferSize: Int
    public private(set) var remainingCapacity: UInt64

    private let indexMask: UInt64
    private let entries: [E]

    init(_ factory: () -> E, sequencer: Sequencer) {
        precondition(sequencer.bufferSize > 1, "bufferSize must not be less than 1")
        precondition(sequencer.bufferSize.nonzeroBitCount == 1, "bufferSize must be a power of 2")

        bufferSize = sequencer.bufferSize
        remainingCapacity = 0
        self.indexMask = UInt64(bufferSize) - 1
        self.entries = Array(repeating: factory(), count: bufferSize)
    }

//    public static func createMultiProducer(factory: () -> E, bufferSize: Int) -> RingBuffer<E> {
//        let sequencer = MultiProducerSequencer(bufferSize: bufferSize, waitStrategy: SleepingWaitStrategy())
//        return RingBuffer<E>(factory, sequencer: sequencer)
//    }

    func hasAvailableCapacity(required: Int) -> Bool {
        return true
    }

    func next() -> UInt64 {
        return 0
    }

    func next(_ n: Int) -> UInt64 {
        return 0
    }

    func publish(_ sequence: UInt64) {

    }

    func publish(low: UInt64, high: UInt64) {

    }


//    private let sequencer: Sequencer

    var cursor: UInt64 {
        get {
//            return sequencer.cursor
            return 0
        }
    }


}
