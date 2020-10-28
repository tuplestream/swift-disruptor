public protocol EventFactory {
    associatedtype Event
    func newInstance() -> Event
}

public protocol EventHandler {
    associatedtype Event
    func onEvent(_ event: Event, sequence: UInt64, endOfBatch: Bool)
}
