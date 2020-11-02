/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Atomics
import Foundation
import _Volatile

protocol Sequenced {
    var bufferSize: Int32 { get }
    var remainingCapacity: Int64 { get }
    func hasAvailableCapacity(required: Int) -> Bool
    func next() -> Int64
    func next(_ n: Int32) -> Int64
    func publish(_ sequence: Int64)
    func publish(low: Int64, high: Int64)
}

protocol Cursored {
    var cursor: Int64 { get }
}

protocol Sequencer: Sequenced, Cursored {
    func claim(sequence: Int64)
    func isAvailable(sequence: Int64) -> Bool
    func getHighestPublishedSequence(lowerBound: Int64, availableSequence: Int64) -> Int64
    func newBarrier(sequencesToTrack: [Sequence]) -> SequenceBarrier
    func addGatingSequences(gatingSequences: [Sequence])
}

final class MultiProducerSequencer: Sequencer {

    private static let initialCursorValue: Int64 = -1
    private static let scale = MemoryLayout<Int>.size

    private let internalCursor: Sequence = Sequence(initialValue: MultiProducerSequencer.initialCursorValue)
    private let gatingSequenceCache: Sequence = Sequence(initialValue: MultiProducerSequencer.initialCursorValue)
    private var availableBuffer: [Int32]
    private let indexMask: Int32
    private let indexShift: Int32
    private let waitStrategy: WaitStrategy
    private var gatingSequences: [Sequence]

    public private(set) var bufferSize: Int32

    public init(bufferSize: Int32, waitStrategy: WaitStrategy) {
        self.bufferSize = bufferSize
        self.availableBuffer = Array(repeating: -1, count: Int(bufferSize))
        self.indexMask = bufferSize - 1
        self.indexShift = Int32(log2(Double(bufferSize)))
        self.waitStrategy = waitStrategy
        self.gatingSequences = [Sequence()]
    }

    var cursor: Int64 {
        get {
            return internalCursor.value
        }
    }

    var remainingCapacity: Int64 {
        get {
            let consumed = SequenceUtils.getMinimumSequence(sequences: gatingSequences, minimum: cursor)
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
        return hasAvailableCapacity(gatingSequences: self.gatingSequences, required: required, cursorValue: internalCursor.value)
    }

    private func hasAvailableCapacity(gatingSequences: [Sequence], required: Int, cursorValue: Int64) -> Bool {
        let wrapPoint = (cursorValue + Int64(required)) - Int64(bufferSize)
        let cachedGatingSequence = gatingSequenceCache.value

        if wrapPoint > cachedGatingSequence || cachedGatingSequence > cursorValue {
            let minSequence = SequenceUtils.getMinimumSequence(sequences: gatingSequences, minimum: cursorValue)

            if wrapPoint > minSequence {
                return false
            }
        }
        return true
    }

    func newBarrier(sequencesToTrack: [Sequence] = []) -> SequenceBarrier {
        return ProcessingSequenceBarrier(sequencer: self, waitStrategy: waitStrategy, cursorSequence: internalCursor, dependentSequences: sequencesToTrack)
    }

    func addGatingSequences(gatingSequences: [Sequence]) {
        
    }

    func next() -> Int64 {
        return next(1)
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
                let gatingSequence = SequenceUtils.getMinimumSequence(sequences: gatingSequences, minimum: current)

                if wrapPoint > gatingSequence {
                    Thread.sleep(forTimeInterval: 0.0000000001)
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
