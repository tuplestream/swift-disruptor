/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Atomics

class Sequence: CustomStringConvertible {

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

    var description: String {
        get {
            return "\(counter.load(ordering: .relaxed))"
        }
    }
}

final class SequenceGroup: Sequence {


}

class FixedSequenceGroup: Sequence {

    init(sequences: [Sequence]) {
        // TODO
    }
}
