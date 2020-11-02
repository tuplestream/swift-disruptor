/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation

public final class RingBuffer<E, F: EventFactory>: Cursored, Sequenced where F.Event == E {
    public typealias Event = E

    public let bufferSize: Int32
    public private(set) var remainingCapacity: Int64

    private let indexMask: Int64
    private let entries: [E]
    private let sequencer: Sequencer

    init(_ factory: F, sequencer: Sequencer) {
        precondition(sequencer.bufferSize > 1, "bufferSize must not be less than 1")
        precondition(sequencer.bufferSize.nonzeroBitCount == 1, "bufferSize must be a power of 2")

        bufferSize = Int32(sequencer.bufferSize)
        remainingCapacity = 0
        self.indexMask = Int64(bufferSize) - 1
        self.entries = Array(repeating: factory.newInstance(), count: Int(bufferSize))
        self.sequencer = sequencer
    }

    public static func createMultiProducer<F: EventFactory>(factory: F, bufferSize: Int32) -> RingBuffer<E, F> where F.Event == E {
        let sequencer = MultiProducerSequencer(bufferSize: bufferSize, waitStrategy: BlockingWaitStrategy())
        return RingBuffer<E,F>(factory, sequencer: sequencer)
    }

    func hasAvailableCapacity(required: Int) -> Bool {
        return true
    }

    func next() -> Int64 {
        return 0
    }

    func next(_ n: Int32) -> Int64 {
        return 0
    }

//    func get(sequence: Int64) -> E {
//        
//    }

    func publish(_ sequence: Int64) {

    }

    func publish(low: Int64, high: Int64) {

    }

//    public func publishEvent<T: EventTranslator>(translator: T, input: T.Input) where T.Event == E {
//        let sequence = sequencer.next()
////        entries.withUnsafeBytes { bp in
////            bp.baseAddress?.advanced(by: <#T##Int#>)
////        }
////        translator.translateTo(, sequence: sequence, input: input)
//    }

    var cursor: Int64 {
        get {
            return sequencer.cursor
        }
    }
}
