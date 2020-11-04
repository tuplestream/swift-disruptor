/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Atomics
import Foundation
import _Volatile

final class SequenceUtils {

    static func getMinimumSequence(sequences: [Sequence]) -> Int64 {
        return getMinimumSequence(sequences: sequences, minimum: Int64.max)
    }

    static func getMinimumSequence(holder: ManagedAtomic<UnsafeMutablePointer<SequenceArrayNode>>, minimum: Int64) -> Int64 {
        var currentMin = minimum
        for sequence in holder.load(ordering: .sequentiallyConsistent).pointee.sequences {
            currentMin = min(currentMin, sequence.value)
        }
        return currentMin
    }

    static func getMinimumSequence(sequences: [Sequence], minimum: Int64) -> Int64 {
        var currentMin = minimum
        for sequence in sequences {
            currentMin = min(sequence.value, currentMin)
        }
        return currentMin
    }

    static func getSequencesFor(processors: [EventProcessor]) -> [Sequence] {
        return processors.map { ep in
            return ep.sequence
        }
    }
}

public class Sequence: CustomStringConvertible {

    private let counter: ManagedAtomic<Int64>

    init(initialValue: Int64 = -1) {
        self.counter = ManagedAtomic<Int64>(initialValue)
    }

    var value: Int64 {
        get {
            return counter.load(ordering: .sequentiallyConsistent)
        }

        set(newValue) {
            counter.store(newValue, ordering: .sequentiallyConsistent)
        }
    }

    func incrementAndGet() -> Int64 {
        return addAndGet(1)
    }

    func compareAndSet(expected: Int64, newValue: Int64) -> Bool {
        return counter.compareExchange(expected: expected, desired: newValue, ordering: .sequentiallyConsistent).exchanged
    }

    internal func setVolatile(_ n: Int64) {
        counter.store(n, ordering: .relaxed)
    }

    func addAndGet(_ increment: Int64) -> Int64 {
        var currentValue: Int64
        var newValue: Int64 = 0
        var exchanged = false
        while !exchanged {
            currentValue = value
            newValue = currentValue + increment
            exchanged = compareAndSet(expected: currentValue, newValue: newValue)
        }
        return newValue
    }

    public var description: String {
        get {
            return "Sequence(cursor=\(value))"
        }
    }
}

final class SequenceHolder: AtomicReference {

    let sequences: [Sequence]

    init(_ sequences: [Sequence]) {
        self.sequences = sequences
    }

    var sequenceCount: Int {
        get {
            return sequences.count
        }
    }
}

final class SequenceGroup: Sequence {

    private let sequences: ManagedAtomic<SequenceHolder>

    init(sequences: [Sequence] = []) {
        self.sequences = ManagedAtomic<SequenceHolder>(SequenceHolder(sequences))
    }

    var size: Int {
        get {
            return sequenceArray.count
        }
    }

    private var sequenceArray: [Sequence] {
        get {
            return sequences.load(ordering: .sequentiallyConsistent).sequences
        }
    }

    override var value: Int64 {
        get {
            return SequenceUtils.getMinimumSequence(sequences: sequenceArray)
        }
        set(newValue) {
            for sequence in sequenceArray {
                sequence.value = newValue
            }
        }
    }

    // Add a Sequence into this aggregate. This should only be used during initialisation.
    // Use addWhileRunning() after if necessary.
    func add(_ sequence: Sequence) {
        var current: SequenceHolder
        var updated: SequenceHolder

        repeat {
            current = sequences.load(ordering: .sequentiallyConsistent)
            var updatedList = current.sequences
            updatedList.append(sequence)
            updated = SequenceHolder(updatedList)
        } while !sequences.compareExchange(expected: current, desired: updated, ordering: .sequentiallyConsistent).exchanged
    }

    func remove(_ sequence: Sequence) -> Bool {
        var current: SequenceHolder
        var updated: SequenceHolder
        var didRemove = false

        repeat {
            current = sequences.load(ordering: .sequentiallyConsistent)
            var updatedList = current.sequences
            updatedList.removeAll { seq in
                if seq === sequence {
                    didRemove = true
                    return true
                }
                return false
            }
            updated = SequenceHolder(updatedList)
        } while !sequences.compareExchange(expected: current, desired: updated, ordering: .sequentiallyConsistent).exchanged

        return didRemove
    }
}

class FixedSequenceGroup: Sequence {

    private let sequences: [Sequence]

    init(_ sequences: [Sequence]) {
        self.sequences = sequences
    }

    override var value: Int64 {
        get {
            return SequenceUtils.getMinimumSequence(sequences: sequences)
        }
        set(newValue) {
            precondition(false, "set not supported on FixedSequenceGroup")
        }
    }
}
