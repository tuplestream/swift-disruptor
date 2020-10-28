import XCTest
@testable import Disruptor

final class DisruptorTests: XCTestCase {

    class MyEvent: CustomStringConvertible {
        var value: Int = 0

        var description: String {
            get {
                return "value: \(value)"
            }
        }
    }

    class MyEventFactory: EventFactory {
        typealias Event = MyEvent

        func newInstance() -> DisruptorTests.MyEvent {
            return MyEvent()
        }
    }

    class MyEventHandler: EventHandler {
        typealias Event = MyEvent

        func onEvent(_ event: DisruptorTests.MyEvent, sequence: UInt64, endOfBatch: Bool) {
            print("\(event) / seq: \(sequence)")
        }
    }

    func overallTest() {

    }
}
