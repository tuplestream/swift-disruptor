/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Atomics
import Foundation
import _Volatile

public protocol Sequenced {
    var bufferSize: Int32 { get }
    var remainingCapacity: Int64 { get }
    func hasAvailableCapacity(required: Int) -> Bool
    func next() -> Int64
    func next(_ n: Int32) -> Int64
    func publish(_ sequence: Int64)
    func publish(low: Int64, high: Int64)
}

public protocol Cursored {
    var cursor: Int64 { get }
}

public protocol Sequencer: Sequenced, Cursored {
    func claim(sequence: Int64)
    func isAvailable(sequence: Int64) -> Bool
    func getHighestPublishedSequence(lowerBound: Int64, availableSequence: Int64) -> Int64
    func newBarrier(sequencesToTrack: [Sequence]) -> SequenceBarrier
    func addGatingSequences(sequences: [Sequence])
}

protocol SequencerImpl: Sequencer, CustomStringConvertible {

    var internalCursor: Sequence { get }
    var waitStrategy: WaitStrategy { get }

    func newBarrier(sequencesToTrack: [Sequence]) -> SequenceBarrier
}

struct SequenceNode {
    let sequence: Sequence
    let next: UnsafeMutablePointer<SequenceNode>?
}

extension SequencerImpl {

    func next() -> Int64 {
        return next(1)
    }

    var cursor: Int64 {
        get {
            return internalCursor.value
        }
    }

    var description: String {
        get {
            "Sequencer(cursorValue=\(cursor))"
        }
    }

    func newBarrier(sequencesToTrack: [Sequence] = []) -> SequenceBarrier {
        return ProcessingSequenceBarrier(sequencer: self, waitStrategy: waitStrategy, cursorSequence: internalCursor, dependentSequences: sequencesToTrack)
    }

    internal func sleepNanos() {
        Thread.sleep(forTimeInterval: 0.0000000001)
    }
}

final class MultiProducerSequencer: SequencerImpl {

    static let initialCursorValue: Int64 = -1

    internal private(set) var internalCursor: Sequence = Sequence(initialValue: MultiProducerSequencer.initialCursorValue)
    private let gatingSequenceCache: Sequence = Sequence(initialValue: MultiProducerSequencer.initialCursorValue)
    private var availableBuffer: [Int32]
    private let indexMask: Int32
    private let indexShift: Int32
    private let gatingSequences: ManagedAtomic<UnsafeMutablePointer<SequenceNode?>>
    internal let waitStrategy: WaitStrategy

    public private(set) var bufferSize: Int32

    public init(bufferSize: Int32, waitStrategy: WaitStrategy) {
        let headNodePtr = UnsafeMutablePointer<SequenceNode?>.allocate(capacity: 1)
        headNodePtr.initialize(to: nil)
        self.gatingSequences = ManagedAtomic(headNodePtr)
        self.bufferSize = bufferSize
        self.availableBuffer = Array(repeating: -1, count: Int(bufferSize))
        self.indexMask = bufferSize - 1
        self.indexShift = Int32(log2(Double(bufferSize)))
        self.waitStrategy = waitStrategy
    }

    func addGatingSequences(sequences: [Sequence]) {
        if sequences.isEmpty {
            return
        }

        // TODO just added 1st element for unit testing

        var result: (exchanged: Bool, original: UnsafeMutablePointer<SequenceNode?>)

        repeat {
            let currentHead = gatingSequences.load(ordering: .sequentiallyConsistent)
            let newHead: SequenceNode
            if let existing = currentHead.pointee {
                let nextPtr = UnsafeMutablePointer<SequenceNode>.allocate(capacity: 1)
                nextPtr.initialize(to: existing)
                newHead = SequenceNode(sequence: sequences[0], next: nextPtr)
            } else {
                newHead = SequenceNode(sequence: sequences[0], next: nil)
            }
            let newHeadPtr = UnsafeMutablePointer<SequenceNode?>.allocate(capacity: 1)
            newHeadPtr.initialize(to: newHead)

            result = gatingSequences.compareExchange(expected: currentHead, desired: newHeadPtr, ordering: .sequentiallyConsistent)
        } while !result.exchanged
    }

    var remainingCapacity: Int64 {
        get {
            let consumed = SequenceUtils.getMinimumSequence(holder: gatingSequences, minimum: cursor)
            return Int64(bufferSize) - (cursor - consumed)
        }
    }

    func claim(sequence: Int64) {
        internalCursor.value = sequence
    }

    func isAvailable(sequence: Int64) -> Bool {
        let index = calculateIndex(sequence)
        let flag = calculateAvailabilityFlag(sequence)
        let bufferAddress = UnsafeMutablePointer<Int32>(mutating: availableBuffer).advanced(by: Int(index))
        return volatile_load_int(UnsafeMutableRawPointer(bufferAddress)) == flag
    }

    func getHighestPublishedSequence(lowerBound: Int64, availableSequence: Int64) -> Int64 {
        var sequence = lowerBound
        while sequence <= availableSequence {
            if !isAvailable(sequence: sequence) {
                return sequence - 1
            }
            sequence += 1
        }
        return availableSequence
    }

    public func hasAvailableCapacity(required: Int) -> Bool {
        return hasAvailableCapacity(required: required, cursorValue: internalCursor.value)
    }

    private func hasAvailableCapacity(required: Int, cursorValue: Int64) -> Bool {
        let wrapPoint = (cursorValue + Int64(required)) - Int64(bufferSize)
        let cachedGatingSequence = gatingSequenceCache.value

        if wrapPoint > cachedGatingSequence || cachedGatingSequence > cursorValue {
            let minSequence = SequenceUtils.getMinimumSequence(holder: gatingSequences, minimum: cursorValue)

            if wrapPoint > minSequence {
                return false
            }
        }
        return true
    }

    func next(_ n: Int32) -> Int64 {
        precondition(n > 0 && n <= bufferSize, "n must be > 0 and <= bufferSize")

        var current: Int64 = internalCursor.value
        var next: Int64 = current + Int64(n)

        while true {
            current = internalCursor.value
            next = current + Int64(n)

            let wrapPoint = next - Int64(bufferSize)
            let cachedGatingSequence = gatingSequenceCache.value

            if wrapPoint > cachedGatingSequence || cachedGatingSequence > current {
                let gatingSequence = SequenceUtils.getMinimumSequence(holder: gatingSequences, minimum: current)

                if wrapPoint > gatingSequence {
                    sleepNanos()
                    continue
                }

                gatingSequenceCache.value = gatingSequence
            } else if internalCursor.compareAndSet(expected: current, newValue: next) {
                break
            }
        }
        return next
    }

    func publish(_ sequence: Int64) {
        setAvailable(sequence: sequence)
        waitStrategy.signalAllWhenBlocking()
    }

    func publish(low: Int64, high: Int64) {
        var l = low
        while l <= high {
            setAvailable(sequence: l)
            l += 1
        }
        waitStrategy.signalAllWhenBlocking()
    }

    private func setAvailable(sequence: Int64) {
        setAvailableBufferValue(index: calculateIndex(sequence), flag: calculateAvailabilityFlag(sequence))
    }

    private func setAvailableBufferValue(index: Int32, flag: Int32) {
        let bufferAddress = UnsafeMutablePointer<Int32>(mutating: availableBuffer).advanced(by: Int(index))
        volatile_store_int(UnsafeMutableRawPointer(bufferAddress), Int32(flag))
    }

    private func calculateIndex(_ sequence: Int64) -> Int32 {
        return Int32(sequence) & indexMask
    }

    private func calculateAvailabilityFlag(_ sequence: Int64) -> Int32 {
        return Int32(sequence).bigEndian >> indexShift
    }
}

final class SingleProducerSequencer: SequencerImpl, CustomStringConvertible {

    private var nextValue: Int64 = -1
    private var cachedValue: Int64 = -1

    internal let waitStrategy: WaitStrategy
    internal let internalCursor: Sequence

    private let gatingSequences: ManagedAtomic<UnsafeMutablePointer<SequenceNode?>>

    let bufferSize: Int32

    init(bufferSize: Int32, waitStrategy: WaitStrategy) {
        self.bufferSize = bufferSize
        self.waitStrategy = waitStrategy
        self.internalCursor = Sequence(initialValue: -1)
        let rawPtr = UnsafeMutablePointer<SequenceNode?>.allocate(capacity: 1)
        rawPtr.initialize(to: nil)
        self.gatingSequences = ManagedAtomic(rawPtr)
    }

    func addGatingSequences(sequences: [Sequence]) {

    }

    func claim(sequence: Int64) {
        self.nextValue = sequence
    }

    func isAvailable(sequence: Int64) -> Bool {
        return sequence <= internalCursor.value
    }

    func getHighestPublishedSequence(lowerBound: Int64, availableSequence: Int64) -> Int64 {
        return availableSequence
    }

    var remainingCapacity: Int64 {
        get {
            let nxt = self.nextValue
            let consumed = SequenceUtils.getMinimumSequence(holder: gatingSequences, minimum: nxt)
            let produced = nxt
            return Int64(bufferSize) - (produced - consumed)
        }
    }

    func hasAvailableCapacity(required: Int) -> Bool {
        let nxt = self.nextValue
        let wrapPoint = (nxt + Int64(required)) - Int64(bufferSize)
        let cachedGatingSequence = self.cachedValue

        if wrapPoint > cachedGatingSequence || cachedGatingSequence > nxt {
            // if doStore {
            //     internalCursor.setVolatile(nxt)
            // }
            let minSequence = SequenceUtils.getMinimumSequence(holder: gatingSequences, minimum: nxt)
            self.cachedValue = minSequence

            if wrapPoint > minSequence {
                return false
            }
        }
        return true
    }

    func next(_ n: Int32) -> Int64 {
        precondition(n > 0 && n <= bufferSize, "n must be > 0 and <= bufferSize")

        let nextValue = self.nextValue

        let nextSequence = nextValue + Int64(n)
        let wrapPoint = nextSequence - Int64(bufferSize)
        let cachedGatingSequence = self.cachedValue

        if wrapPoint > cachedGatingSequence || cachedGatingSequence > nextValue {
            internalCursor.setVolatile(nextValue)

            var minSequence: Int64
            repeat {
                sleepNanos()
                minSequence = SequenceUtils.getMinimumSequence(sequences: [], minimum: nextValue)
            } while wrapPoint > minSequence

            self.cachedValue = minSequence
        }

        self.nextValue = nextSequence

        return nextSequence
    }

    func publish(_ sequence: Int64) {
        internalCursor.value = sequence
        waitStrategy.signalAllWhenBlocking()
    }

    func publish(low: Int64, high: Int64) {
        publish(high)
    }
}
