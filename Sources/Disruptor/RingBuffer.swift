/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation

public protocol DataProvider {
    associatedtype Event
    func get(sequence: Int64) -> Event
}

public final class RingBuffer<E>: Cursored, Sequenced, EventSink, DataProvider {
    public typealias Event = E

    public let bufferSize: Int32
    public private(set) var remainingCapacity: Int64

    private let indexMask: Int64
    // TODO pad entry list like the Java impl (https://github.com/tuplestream/swift-disruptor/issues/3)
    private let entries: [E]
    private let sequencer: Sequencer

    init<F: EventFactory>(_ factory: F, sequencer: Sequencer) where F.Event == E {
        precondition(sequencer.bufferSize > 1, "bufferSize must not be less than 1")
        precondition(sequencer.bufferSize.nonzeroBitCount == 1, "bufferSize must be a power of 2")

        bufferSize = Int32(sequencer.bufferSize)
        remainingCapacity = 0
        self.indexMask = Int64(bufferSize) - 1
        var tmpArray: [E] = Array()
        for _ in 0..<bufferSize {
            tmpArray.append(factory.newInstance())
        }
        self.entries = tmpArray
        self.sequencer = sequencer
    }

    public static func createMultiProducer<F: EventFactory>(factory: F, bufferSize: Int32, waitStrategy: WaitStrategy = SleepingWaitStrategy()) -> RingBuffer<E> where F.Event == E {
        let sequencer = MultiProducerSequencer(bufferSize: bufferSize, waitStrategy: waitStrategy)
        return RingBuffer<E>(factory, sequencer: sequencer)
    }

    public static func createSingleProducer<F: EventFactory>(factory: F, bufferSize: Int32, waitStrategy: WaitStrategy = SleepingWaitStrategy()) -> RingBuffer<E> where F.Event == E {
        let sequencer = SingleProducerSequencer(bufferSize: bufferSize, waitStrategy: waitStrategy)
        return RingBuffer<E>(factory, sequencer: sequencer)
    }

    func newBarrier(sequencesToTrack: Sequence...) -> SequenceBarrier {
        return sequencer.newBarrier(sequencesToTrack: sequencesToTrack)
    }

    func newBarrier(sequencesToTrack: [Sequence]) -> SequenceBarrier {
        return sequencer.newBarrier(sequencesToTrack: sequencesToTrack)
    }

    func addGatingSequences(sequences: Sequence...) {
        sequencer.addGatingSequences(sequences: sequences)
    }

    func removeGatingSequence(_ sequence: Sequence) -> Bool {
        return sequencer.removeGatingSequence(sequence)
    }

    public func hasAvailableCapacity(required: Int32) -> Bool {
        return sequencer.hasAvailableCapacity(required: required)
    }

    public func next() -> Int64 {
        return sequencer.next()
    }

    public func next(_ n: Int32) -> Int64 {
        return sequencer.next(n)
    }

    public func tryNext() throws -> Int64 {
        return try sequencer.tryNext()
    }

    public func tryNext(_ n: Int32) throws -> Int64 {
        return try sequencer.tryNext(n)
    }

    public func get(sequence: Int64) -> E {
        return entries[Int(sequence & indexMask)]
    }

    public func publish(_ sequence: Int64) {
        sequencer.publish(sequence)
    }

    public func publish(low: Int64, high: Int64) {
        sequencer.publish(low: low, high: high)
    }

    public func publishEvent<T: EventTranslator>(translator: T, input: T.Input) where T.Event == E {
        publishEvents(translator: translator, input: [input])
    }

    public func publishEvents<T: EventTranslator>(translator: T, input: [T.Input]) where T.Event == E {
        precondition(input.count <= bufferSize, "The ring buffer cannot accommodate \(input.count) entries, it only has space for \(bufferSize)")

        let finalSequence = sequencer.next(Int32(input.count))
        let initialSequence = finalSequence - Int64(input.count - 1)

        defer { sequencer.publish(low: initialSequence, high: finalSequence) }

        var sequence = initialSequence
        for object in input {
            let nextSequence = sequence + 1
            var eventAtSequence = get(sequence: sequence)
            translator.translateTo(&eventAtSequence, sequence: nextSequence, input: object)
            sequence = nextSequence
        }
    }

    public func tryPublishEvent<T: EventTranslator>(translator: T, input: T.Input) -> Bool where T.Event == E {
        do {
            let sequence = try sequencer.tryNext()
            var element = get(sequence: sequence)
            defer { sequencer.publish(sequence) }
            translator.translateTo(&element, sequence: sequence, input: input)
            return false
        } catch {
            return false
        }
    }

    public var cursor: Int64 {
        get {
            return sequencer.cursor
        }
    }

    public var minimumGatingSequence: Int64 {
        get {
            return sequencer.minimumSequence
        }
    }
}
