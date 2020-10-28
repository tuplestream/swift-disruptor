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
    func getHighestPublishedSequence(nextSequence: UInt64, availableSequence: UInt64) -> UInt64
}

//final class MultiProducerSequencer: Sequencer {
//
//    private let internalCursor: Sequence
//
//    public init(bufferSize: Int) {
//        self.bufferSize = bufferSize
//        self.internalCursor = Sequence()
//    }
//
//    func claim(sequence: UInt64) {
//        internalCursor.value = sequence
//    }
//
//    func isAvailable(sequence: UInt64) -> Bool {
//        <#code#>
//    }
//
//    func getHighestPublishedSequence(nextSequence: UInt64, availableSequence: UInt64) -> UInt64 {
//        <#code#>
//    }
//
//    var bufferSize: Int
//
//    var remainingCapacity: UInt64
//
//    func hasAvailableCapacity(required: Int) -> Bool {
//        <#code#>
//    }
//
//    func next() -> UInt64 {
//        <#code#>
//    }
//
//    func next(_ n: Int) -> UInt64 {
//        <#code#>
//    }
//
//    func publish(_ sequence: UInt64) {
//        <#code#>
//    }
//
//    func publish(low: UInt64, high: UInt64) {
//        <#code#>
//    }
//
//    var cursor: UInt64
//
//    
//}
