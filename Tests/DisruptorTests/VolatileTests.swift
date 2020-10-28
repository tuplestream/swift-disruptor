import XCTest
@testable import Disruptor
@testable import _Volatile

final class VolatileTests: XCTestCase {

    func testVolatileLoadStore() {
        let numbers = [1,2,3]
        let pointerToSecondInt = UnsafeMutablePointer<Int>.init(mutating: numbers).advanced(by: 1)
        let i = volatile_load_int(UnsafeMutableRawPointer(pointerToSecondInt))
        XCTAssertEqual(2, i)
        volatile_store_int(pointerToSecondInt, 1337)
        let j = volatile_load_int(UnsafeMutableRawPointer(pointerToSecondInt))
        XCTAssertEqual(1337, j)
    }
}
