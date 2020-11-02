/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation

public final class RingBuffer<E>: Cursored, Sequenced {

    public let bufferSize: Int32
    public private(set) var remainingCapacity: Int64

    private let indexMask: Int64
    private let entries: [E]

    init(_ factory: () -> E, sequencer: Sequencer) {
        precondition(sequencer.bufferSize > 1, "bufferSize must not be less than 1")
        precondition(sequencer.bufferSize.nonzeroBitCount == 1, "bufferSize must be a power of 2")

        bufferSize = Int32(sequencer.bufferSize)
        remainingCapacity = 0
        self.indexMask = Int64(bufferSize) - 1
        self.entries = Array(repeating: factory(), count: Int(bufferSize))
    }

//    public static func createMultiProducer(factory: () -> E, bufferSize: Int) -> RingBuffer<E> {
//        let sequencer = MultiProducerSequencer(bufferSize: bufferSize, waitStrategy: SleepingWaitStrategy())
//        return RingBuffer<E>(factory, sequencer: sequencer)
//    }

    func hasAvailableCapacity(required: Int) -> Bool {
        return true
    }

    func next() -> Int64 {
        return 0
    }

    func next(_ n: Int32) -> Int64 {
        return 0
    }

    func publish(_ sequence: Int64) {

    }

    func publish(low: Int64, high: Int64) {

    }


//    private let sequencer: Sequencer

    var cursor: Int64 {
        get {
//            return sequencer.cursor
            return 0
        }
    }


}
