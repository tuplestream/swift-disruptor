import Foundation
import CAtomics

class Sequence {

    fileprivate var ptr: AtomicUInt64

    init(value: UInt64 = 0) {
        self.ptr = AtomicUInt64()
        CAtomicsInitialize(&ptr, value)
    }

    func get() -> UInt64 {
        return CAtomicsLoad(&ptr, .relaxed)
    }

    func set(_ value: UInt64) {
        CAtomicsStore(&ptr, value, .sequential)
    }

    func setVolatile(_ value: UInt64) {
        CAtomicsStore(&ptr, value, .relaxed)
    }

}
