/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Atomics
import Foundation
import _Volatile

protocol Sequenced {
    var bufferSize: Int { get }
    var remainingCapacity: UInt64 { get }
    func hasAvailableCapacity(required: Int) -> Bool
    func next() -> UInt64
    func next(_ n: Int) -> UInt64
    func publish(_ sequence: UInt64)
    func publish(low: UInt64, high: UInt64)
}

protocol Cursored {
    var cursor: UInt64 { get }
}

protocol Sequencer: Sequenced, Cursored {
    func claim(sequence: UInt64)
    func isAvailable(sequence: UInt64) -> Bool
    func getHighestPublishedSequence(lowerBound: UInt64, availableSequence: UInt64) -> UInt64
}

final class SequenceUtils {

    static func getMinimumSequence(sequences: [Sequence], minimum: UInt64) -> UInt64 {
        var currentMin = minimum
        for sequence in sequences {
            currentMin = min(sequence.value, currentMin)
        }
        return currentMin
    }
}

final class MultiProducerSequencer: Sequencer {

    private static let initialCursorValue = -1
    private static let scale = MemoryLayout<Int>.size

    private let internalCursor: Sequence = Sequence()
    private let gatingSequenceCache: Sequence = Sequence()
    private var availableBuffer: [Int]
    private let indexMask: Int
    private let indexShift: Int
    private let waitStrategy: WaitStrategy
    private var gatingSequences: [Sequence]

    public init(bufferSize: Int, waitStrategy: WaitStrategy) {
        self.bufferSize = bufferSize
        self.availableBuffer = Array(repeating: 0, count: bufferSize)
        self.indexMask = bufferSize - 1
        self.indexShift = Int(log2(Double(bufferSize)))
        self.waitStrategy = waitStrategy
        self.gatingSequences = [Sequence()]
    }

    func claim(sequence: UInt64) {
        internalCursor.value = sequence
    }

    func isAvailable(sequence: UInt64) -> Bool {
        let index = calculateIndex(sequence)
        let flag = calculateAvailabilityFlag(sequence)
        let bufferAddress = UnsafeMutablePointer<Int>(mutating: availableBuffer).advanced(by: index)
        return volatile_load_int(UnsafeMutableRawPointer(bufferAddress)) == flag
    }

    func getHighestPublishedSequence(lowerBound: UInt64, availableSequence: UInt64) -> UInt64 {
        var sequence = lowerBound
        while sequence <= availableSequence {
            if !isAvailable(sequence: sequence) {
                return sequence - 1
            }
            sequence += 1
        }
        return availableSequence
    }

    var bufferSize: Int

    var remainingCapacity: UInt64 = 0

    public func hasAvailableCapacity(required: Int) -> Bool {
        return hasAvailableCapacity(gatingSequences: self.gatingSequences, required: required, cursorValue: internalCursor.value)
    }

    private func hasAvailableCapacity(gatingSequences: [Sequence], required: Int, cursorValue: UInt64) -> Bool {
        let wrapPoint = (cursorValue + UInt64(required)) - UInt64(bufferSize)
        let cachedGatingSequence = gatingSequenceCache.value

        if wrapPoint > cachedGatingSequence || cachedGatingSequence > cursorValue {
            let minSequence = SequenceUtils.getMinimumSequence(sequences: gatingSequences, minimum: cursorValue)

            if wrapPoint > minSequence {
                return false
            }
        }
        return true
    }

    func next() -> UInt64 {
        return next(1)
    }

    func next(_ n: Int) -> UInt64 {
        precondition(n > 0 && n < bufferSize, "n must be > 0 and < bufferSize")

        var current: UInt64 = internalCursor.value
        var next: UInt64 = current + UInt64(n)

        while true {
            current = internalCursor.value
            next = current + UInt64(n)

            let wrapPoint = next - UInt64(bufferSize)
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

    private func setAvailableBufferValue(index: Int, flag: Int) {

    }

    func publish(_ sequence: UInt64) {
        setAvailable(sequence: sequence)
        waitStrategy.signalAllWhenBlocking()
    }

    func publish(low: UInt64, high: UInt64) {
        var l = low
        while l <= high {
            setAvailable(sequence: l)
            l += 1
        }
        waitStrategy.signalAllWhenBlocking()
    }

    var cursor: UInt64 = 0

    private func setAvailable(sequence: UInt64) {
        setAvailableBufferValue(index: calculateIndex(sequence), flag: calculateAvailabilityFlag(sequence))
    }

    private func calculateIndex(_ sequence: UInt64) -> Int {
        return Int(sequence) & indexMask
    }

    private func calculateAvailabilityFlag(_ sequence: UInt64) -> Int {
        return Int(sequence).bigEndian >> indexShift
    }
}
