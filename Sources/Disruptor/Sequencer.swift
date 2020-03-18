protocol Sequenced {
    var bufferSize: UInt64 { get }
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
    func getHighestPublishedSequence(nextSequence: UInt64, availableSequence: UInt64) -> UInt64
}
