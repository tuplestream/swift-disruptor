import Atomics

class Sequence: CustomStringConvertible {

    private let counter: ManagedAtomic<UInt64>

    init(initialValue: UInt64 = 0) {
        self.counter = ManagedAtomic<UInt64>(initialValue)
    }

    var value: UInt64 {
        get {
            return counter.load(ordering: .sequentiallyConsistent)
        }

        set(newValue) {
            counter.store(newValue, ordering: .sequentiallyConsistent)
        }
    }

    func incrementAndGet() -> UInt64 {
        return addAndGet(1)
    }

    func addAndGet(_ increment: UInt64) -> UInt64 {
        var currentValue: UInt64
        var newValue: UInt64 = 0
        var exchanged = false
        while !exchanged {
            currentValue = value
            newValue = currentValue + increment
            let result = counter.compareExchange(expected: currentValue, desired: newValue, ordering: .sequentiallyConsistent)
            exchanged = result.exchanged
        }
        return newValue
    }

    var description: String {
        get {
            return "\(counter.load(ordering: .relaxed))"
        }
    }
}
