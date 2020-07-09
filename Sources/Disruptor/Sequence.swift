import CAtomics

class Sequence {

    private var value = UnsafeMutablePointer<AtomicUInt64>.allocate(capacity: 1)

    init(initialValue: UInt64 = 0) {
        CAtomicsInitialize(self.value, 0)
    }

    func get() -> UInt64 {
        return CAtomicsLoad(value, .relaxed)
    }

    func set(_ value: UInt64) {
    }

    func setVolatile(_ value: UInt64) {
    }

}
